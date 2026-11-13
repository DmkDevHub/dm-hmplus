"""QH 코드 값 변경 5단계: 검증 (조회 전용, vplus만 접속, JH 접속 안 함, 프로시저 실행 안 함)
1) 다시 만든 93개 + 호출 객체 2개: VALID, USER_ERRORS 0
2) vplus 소스 == 02_generate/10_recreate.sql 소스
3) 바뀐 소스의 코드 영역 문자열에 QS 0곳 (주석 제외)
4) 데이터: 513행 코드 값 QH, 다른 컬럼은 1단계 값과 같음, 바뀐 코드가 공통코드에 있음
5) 0장 원칙: 1단계 기준선(01_baseline/*.csv)과 비교해 대상 밖 변경 0건, 객체 수·테이블 건수 동일
사용: $env:DB_PASSWORD='...'; python -I run_step5.py
"""
import csv, io, json, os, re, sys, datetime
import oracledb

HERE = os.path.dirname(os.path.abspath(__file__))
GEN = os.path.join(HERE, "..", "02_generate")
BASE = os.path.join(HERE, "..", "01_baseline")
LOG = open(os.path.join(HERE, "step5.log"), "a", encoding="utf-8")
def log(m):
    l = f"[{datetime.datetime.now():%Y-%m-%d %H:%M:%S}] {m}"; print(l); LOG.write(l + "\n"); LOG.flush()

def zones(b):   # gen_step2.py 와 같은 파서 (글자마다 code / line / block / str / strq)
    out = []; i = 0; n = len(b); m = "code"
    while i < n:
        c = b[i]; t = b[i:i + 2]
        if m == "code":
            if t == "--": m = "line"
            elif t == "/*": m = "block"
            elif c == "'": m = "str"; out.append("strq"); i += 1; continue
        elif m == "line" and c == "\n": m = "code"
        elif m == "block" and t == "*/": out += ["block", "block"]; i += 2; m = "code"; continue
        elif m == "str" and c == "'":
            if b[i + 1:i + 2] == "'": out += ["str", "str"]; i += 2; continue
            out.append("strq"); i += 1; m = "code"; continue
        out.append(m); i += 1
    return out
def literals(b):
    z = zones(b)
    for mm in re.finditer(r"'((?:[^']|'')*)'", b):
        if z[mm.start()] == "strq": yield mm.start(), mm.group(1)

def read_csv(fn): return list(csv.DictReader(open(os.path.join(BASE, fn), encoding="utf-8-sig")))
def as_csv_rows(cur, sql):   # 1단계와 같은 방식(csv.writer)으로 문자열화
    cur.execute(sql); cols = [d[0] for d in cur.description]; buf = io.StringIO()
    w = csv.writer(buf); w.writerow(cols); w.writerows(cur.fetchall()); buf.seek(0)
    return list(csv.DictReader(buf))

# 기대 대상
rec = {}
for b in re.split(r"\n/\n", open(os.path.join(GEN, "10_recreate.sql"), encoding="utf-8").read()):
    m = re.search(r'^-- (\S+)\nDROP (PROCEDURE|FUNCTION) "([^"]+)";\n', b, re.M)
    if m: rec[m.group(1)] = (m.group(2), re.sub(r"^CREATE\s+", "", b[m.end():].strip()))
deps = [l.strip() for l in open(os.path.join(GEN, "recompile_dependents.txt"), encoding="utf-8") if l.strip()]
names = sorted(rec); targets = set(names) | set(deps)
inl = lambda xs: ",".join(f"'{x}'" for x in xs)

con = oracledb.connect(user="VPLUS202611A", password=os.environ["DB_PASSWORD"], dsn="192.168.1.25:1521/ORCLU"); c = con.cursor()
log(f"=== 5단계 시작: 검증 (대상 {len(names)}개 + 호출 객체 {len(deps)}개) ===")
R = {}

# 1) 상태
st = dict(c.execute(f"SELECT object_name, status FROM user_objects WHERE object_type IN ('PROCEDURE','FUNCTION') AND object_name IN ({inl(targets)})").fetchall())
err = c.execute(f"SELECT COUNT(*) FROM user_errors WHERE name IN ({inl(targets)})").fetchone()[0]
R["1_status"] = {"found": len(st), "expected": len(targets), "not_valid": sorted(n for n in targets if st.get(n) != "VALID"), "user_errors": err}
R["1_status"]["ok"] = len(st) == len(targets) and not R["1_status"]["not_valid"] and err == 0

# 2) 소스 일치
cur_src = {}
for n in names:
    cur_src[n] = "".join(x[0] for x in c.execute("SELECT text FROM user_source WHERE name=:n AND type=:t ORDER BY line", n=n, t=rec[n][0]))
exact = [n for n in names if cur_src[n].rstrip() != rec[n][1].rstrip()]
norm = lambda s: re.sub(r"\s+", " ", s).strip()
ws_only = [n for n in exact if norm(cur_src[n]) == norm(rec[n][1])]
R["2_source"] = {"compared": len(names), "diff": [n for n in exact if n not in ws_only], "whitespace_only_diff": ws_only}
R["2_source"]["ok"] = not R["2_source"]["diff"]

# 3) 코드 영역 QS 문자열
left = [(n, cur_src[n][:p].count("\n") + 1, s) for n in names for p, s in literals(cur_src[n]) if "QS" in s.upper()]
qh_lits = sum(1 for n in names for _, s in literals(cur_src[n]) if re.search(r"(?<![0-9A-Z])QH[0-9A-Z]*", s))
R["3_qs_literals"] = {"left": left[:20], "left_count": len(left), "qh_literal_count": qh_lits, "ok": not left}

# 4) 데이터
comcodes = {r[0] for r in c.execute("SELECT COM_CD FROM TCOA_COMCODE")} | {r[0] for r in c.execute("SELECT DISTINCT HRNK_CD FROM TCOA_COMCODE")}
conv = lambda x: "QH" + x[2:] if x.startswith("QS") else x
R["4_data"] = {}
for t, keys in (("TQHA_CKLST", ["COM_CD", "HO_CHK_DIV_CD2", "HO_CHK_DIV_CD"]), ("TQHA_CKLST_ITM", ["COM_CD", "HO_CHK_DIV_CD2", "HO_CHK_DIV_CD", "HO_CHK_ITM_CD"])):
    old = read_csv(f"data_{t}.csv"); now = as_csv_rows(c, f'SELECT * FROM "{t}"')
    exp = {tuple(conv(r[k]) if k in ("COM_CD", "HO_CHK_DIV_CD2") else r[k] for k in keys): r for r in old}
    got = {tuple(r[k] for k in keys): r for r in now}
    col_diff = []
    for k, o in exp.items():
        g = got.get(k)
        if g is None: continue
        for col in o:
            want = conv(o[col]) if col in ("COM_CD", "HO_CHK_DIV_CD2") else o[col]
            if g.get(col) != want: col_diff.append((k, col, o[col], g.get(col)))
    d = {"rows_before": len(old), "rows_now": len(now),
         "missing_keys": len(set(exp) - set(got)), "extra_keys": len(set(got) - set(exp)),
         "not_qh": sum(1 for r in now if not (r["COM_CD"].startswith("QH") and r["HO_CHK_DIV_CD2"].startswith("QH"))),
         "other_column_diff": col_diff[:20], "other_column_diff_count": len(col_diff),
         "codes_missing_in_comcode": sorted({r[k] for r in now for k in ("COM_CD", "HO_CHK_DIV_CD2") if r[k] not in comcodes})}
    d["ok"] = d["rows_before"] == d["rows_now"] and not (d["missing_keys"] or d["extra_keys"] or d["not_qh"] or d["other_column_diff_count"] or d["codes_missing_in_comcode"])
    R["4_data"][t] = d

# 5) 기준선 비교 (1단계 baseline.py 와 같은 조회, vplus만)
def by(rows, *ks): return {tuple(r[k] for k in ks): r for r in rows}
o_old = by(read_csv("vplus_objects.csv"), "OBJECT_NAME", "OBJECT_TYPE")
o_now = by(as_csv_rows(c, """SELECT object_name, object_type, status, TO_CHAR(created,'YYYY-MM-DD HH24:MI:SS') created,
             TO_CHAR(last_ddl_time,'YYYY-MM-DD HH24:MI:SS') last_ddl_time FROM user_objects
             WHERE (object_name LIKE '%QS%' OR object_name LIKE '%QH%') AND SUBSTR(object_name,1,4)<>'TEST'"""), "OBJECT_NAME", "OBJECT_TYPE")
obj_changed = sorted(k for k in set(o_old) & set(o_now) if o_old[k] != o_now[k])
s_old = by(read_csv("vplus_source_hash.csv"), "NAME", "TYPE")
s_now = by(as_csv_rows(c, """SELECT name, type, COUNT(*) line_cnt, SUM(ORA_HASH(text)) src_hash FROM user_source
             WHERE (name LIKE '%QS%' OR name LIKE '%QH%') AND SUBSTR(name,1,4)<>'TEST' GROUP BY name, type"""), "NAME", "TYPE")
src_changed = sorted(k for k in set(s_old) & set(s_now) if s_old[k] != s_now[k])
k_old = by(read_csv("vplus_constraints.csv"), "TABLE_NAME", "CONSTRAINT_NAME")
k_now = by(as_csv_rows(c, """SELECT table_name, constraint_name, constraint_type, status, r_constraint_name
             FROM user_constraints WHERE SUBSTR(table_name,1,3) IN ('TQS','TQH')"""), "TABLE_NAME", "CONSTRAINT_NAME")
t_old = {r["TABLE_NAME"]: r["ROW_COUNT"] for r in read_csv("vplus_table_counts.csv")}
t_now = {t: str(c.execute(f'SELECT COUNT(*) FROM "{t}"').fetchone()[0]) for t in t_old}
cnt_tabs = [r[0] for r in c.execute("SELECT table_name FROM user_tables WHERE SUBSTR(table_name,1,3) IN ('TQS','TQH') AND temporary='N' AND nested='NO' AND dropped='NO'")]
outside = lambda ks: [k for k in ks if k[0] not in targets]
R["5_baseline"] = {
    "objects": {"before": len(o_old), "now": len(o_now), "added": sorted(set(o_now) - set(o_old)), "removed": sorted(set(o_old) - set(o_now)),
                "changed": len(obj_changed), "changed_outside_targets": outside(obj_changed),
                "targets_not_changed": sorted(set(targets) - {k[0] for k in obj_changed})},
    "source": {"before": len(s_old), "now": len(s_now), "added": sorted(set(s_now) - set(s_old)), "removed": sorted(set(s_old) - set(s_now)),
               "changed": len(src_changed), "changed_outside_93": [k for k in src_changed if k[0] not in rec],
               "93_not_changed": sorted(set(names) - {k[0] for k in src_changed})},
    "constraints": {"before": len(k_old), "now": len(k_now), "diff": sorted(k for k in set(k_old) | set(k_now) if k_old.get(k) != k_now.get(k))},
    "table_counts": {"tables": len(t_old), "tables_now": len(cnt_tabs), "diff": sorted((t, t_old[t], t_now[t]) for t in t_old if t_old[t] != t_now[t])}}
b = R["5_baseline"]
b["ok"] = (not b["objects"]["added"] and not b["objects"]["removed"] and not b["objects"]["changed_outside_targets"]
           and not b["source"]["added"] and not b["source"]["removed"] and not b["source"]["changed_outside_93"] and not b["source"]["93_not_changed"]
           and not b["constraints"]["diff"] and not b["table_counts"]["diff"] and b["table_counts"]["tables"] == b["table_counts"]["tables_now"])

ok = R["1_status"]["ok"] and R["2_source"]["ok"] and R["3_qs_literals"]["ok"] and all(d["ok"] for d in R["4_data"].values()) and b["ok"]
R["all_ok"] = ok; R["checked_at"] = f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S}"
json.dump(R, open(os.path.join(HERE, "step5_result.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1, default=str)
for k in ("1_status", "2_source", "3_qs_literals", "5_baseline"): log(f"{k}: {'OK' if R[k]['ok'] else 'NG'}")
for t, d in R["4_data"].items(): log(f"4_data {t}: {'OK' if d['ok'] else 'NG'} ({d['rows_now']}행)")
log(f"전체: {'OK' if ok else 'NG'}")
log("=== 5단계 종료 ===")
print(json.dumps(R, ensure_ascii=False, indent=1, default=str))
