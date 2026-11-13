"""1단계 기준선 저장 - SELECT만 수행. 범위(QH 이관): 테이블은 TQS*/TQH*, 그 밖의 객체는 이름에 QS 또는 QH 포함, TEST로 시작하는 객체 제외"""
import csv, json, os, sys, datetime
import oracledb
OUT = sys.argv[1]; os.makedirs(OUT, exist_ok=True)
DSN = "192.168.1.25:1521/ORCLU"
now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def dump(cur, sql, fname, binds=None):
    cur.execute(sql, binds or {})
    cols = [d[0] for d in cur.description]; rows = cur.fetchall()
    with open(os.path.join(OUT, fname), "w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f); w.writerow(cols); w.writerows(rows)
    return rows

def counts(con, tables):
    cur = con.cursor(); res = []
    for t in tables:
        cur.execute(f'SELECT COUNT(*) FROM "{t}"'); res.append((t, cur.fetchone()[0]))
    return res

summary = {"captured_at": now}
# ---- VPLUS ----
with oracledb.connect(user="VPLUS202611A", password=os.environ["DB_PASSWORD"], dsn=DSN) as con:
    cur = con.cursor()
    objs = dump(cur, """SELECT object_name, object_type, status,
                 TO_CHAR(created,'YYYY-MM-DD HH24:MI:SS') created,
                 TO_CHAR(last_ddl_time,'YYYY-MM-DD HH24:MI:SS') last_ddl_time
               FROM user_objects WHERE (object_name LIKE '%QS%' OR object_name LIKE '%QH%') AND SUBSTR(object_name,1,4)<>'TEST' ORDER BY object_type, object_name""", "vplus_objects.csv")
    cons_ = dump(cur, """SELECT table_name, constraint_name, constraint_type, status, r_constraint_name
               FROM user_constraints WHERE SUBSTR(table_name,1,3) IN ('TQS','TQH') ORDER BY table_name, constraint_name""", "vplus_constraints.csv")
    srch = dump(cur, """SELECT name, type, COUNT(*) line_cnt, SUM(ORA_HASH(text)) src_hash
               FROM user_source WHERE (name LIKE '%QS%' OR name LIKE '%QH%') AND SUBSTR(name,1,4)<>'TEST' GROUP BY name, type ORDER BY type, name""", "vplus_source_hash.csv")
    cur.execute("SELECT table_name FROM user_tables WHERE SUBSTR(table_name,1,3) IN ('TQS','TQH') AND temporary='N' AND nested='NO' AND dropped='NO' AND (iot_type IS NULL OR iot_type='IOT') AND table_name NOT IN (SELECT table_name FROM user_external_tables) ORDER BY 1")
    tabs = [r[0] for r in cur]
    rc = counts(con, tabs)
    with open(os.path.join(OUT, "vplus_table_counts.csv"), "w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f); w.writerow(["TABLE_NAME", "ROW_COUNT"]); w.writerows(rc)
    cur.execute("SELECT default_tablespace FROM user_users"); dts = cur.fetchone()[0]
    from collections import Counter
    summary["VPLUS"] = {"objects": len(objs), "by_type": dict(Counter(o[1] for o in objs)),
        "invalid": sum(1 for o in objs if o[2] != "VALID"), "constraints": len(cons_),
        "source_units": len(srch), "tables_counted": len(rc), "total_rows": sum(c for _, c in rc),
        "default_tablespace": dts,
        "existing_TQSB_TQSC": sorted(o[0] for o in objs if o[1] == "TABLE" and o[0].startswith(("TQSB_", "TQSC_"))),
        "existing_QH": sorted(f"{o[1]} {o[0]}" for o in objs if "QH" in o[0])}
# ---- JH ----
with oracledb.connect(user="JH202610", password=os.environ["DB_PASSWORD"], dsn=DSN) as con:
    cur = con.cursor()
    jobjs = dump(cur, """SELECT object_name, object_type, status,
                 TO_CHAR(last_ddl_time,'YYYY-MM-DD HH24:MI:SS') last_ddl_time
               FROM user_objects WHERE object_name LIKE '%QS%' AND SUBSTR(object_name,1,4)<>'TEST' ORDER BY object_type, object_name""", "jh_qs_objects.csv")
    cur.execute("SELECT table_name FROM user_tables WHERE SUBSTR(table_name,1,5) IN ('TQSA_','TQSB_') ORDER BY 1")
    jt = [r[0] for r in cur]
    jc = counts(con, jt)
    with open(os.path.join(OUT, "jh_tqs_table_counts.csv"), "w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f); w.writerow(["TABLE_NAME", "ROW_COUNT"]); w.writerows(jc)
    summary["JH"] = {"qs_objects": len(jobjs), "by_type": dict(Counter(o[1] for o in jobjs)),
        "invalid_qs": sorted(f"{o[1]} {o[0]}" for o in jobjs if o[2] != "VALID"),
        "tqs_tables": len(jt), "tqs_total_rows": sum(c for _, c in jc), "counts": dict(jc)}
json.dump(summary, open(os.path.join(OUT, "baseline_summary.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
s = dict(summary); s["JH"] = {k: v for k, v in summary["JH"].items() if k != "counts"}
print(json.dumps(s, ensure_ascii=False, indent=1))
