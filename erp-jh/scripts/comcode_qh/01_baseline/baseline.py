"""공통코드(QS→QH) 1단계: 기준선 저장 (조회 전용)
- vplus TCOA_COMCODE: 전체 행 수, 전체 행의 키별 해시(기존 행 변경 확인용), QS/QH로 시작하는 행 전체
- JH TCOA_COMCODE: HRNK_CD LIKE 'QS%' 행 전체(복사 원본)
사용: $env:DB_PASSWORD='...'; python -I baseline.py <출력 폴더>
"""
import csv, hashlib, json, os, sys, datetime
import oracledb

OUT = sys.argv[1]; os.makedirs(OUT, exist_ok=True)
DSN = "192.168.1.25:1521/ORCLU"
NOW = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def conn(u): return oracledb.connect(user=u, password=os.environ["DB_PASSWORD"], dsn=DSN).cursor()
def save(fname, cur, sql):
    cur.execute(sql); cols = [d[0] for d in cur.description]; rows = cur.fetchall()
    with open(os.path.join(OUT, fname), "w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f); w.writerow(cols); w.writerows(rows)
    return cols, rows

v, j = conn("VPLUS202611A"), conn("JH202610")
cols = [r[0] for r in v.execute("SELECT column_name FROM user_tab_columns WHERE table_name='TCOA_COMCODE' ORDER BY column_id")]
sel = ", ".join(cols)

# vplus 전체 행 해시
v.execute(f"SELECT {sel} FROM TCOA_COMCODE ORDER BY COM_CD, HRNK_CD")
hrows = []
for r in v:
    h = hashlib.sha1(json.dumps([None if x is None else str(x) for x in r], ensure_ascii=False).encode("utf-8")).hexdigest()
    hrows.append((r[0], r[1], h))
with open(os.path.join(OUT, "vplus_comcode_hash.csv"), "w", newline="", encoding="utf-8-sig") as f:
    w = csv.writer(f); w.writerow(["COM_CD", "HRNK_CD", "ROW_HASH"]); w.writerows(hrows)

_, vq = save("vplus_comcode_qs_qh.csv", v, f"""SELECT {sel} FROM TCOA_COMCODE
    WHERE SUBSTR(COM_CD,1,2) IN ('QS','QH') OR SUBSTR(HRNK_CD,1,2) IN ('QS','QH') ORDER BY HRNK_CD, COM_CD""")
_, jq = save("jh_comcode_qs.csv", j, f"SELECT {sel} FROM TCOA_COMCODE WHERE HRNK_CD LIKE 'QS%' ORDER BY HRNK_CD, COM_CD")

s = {"captured_at": NOW,
     "vplus": {"total_rows": len(hrows),
               "hrnk_qs_rows": sum(1 for r in hrows if r[1].startswith("QS")),
               "hrnk_qh_rows": sum(1 for r in hrows if r[1].startswith("QH")),
               "com_or_hrnk_qs_qh_rows": len(vq),
               "qh_rows": [list(r[:3]) for r in vq if r[0].startswith("QH") or r[1].startswith("QH")]},
     "jh": {"total_rows": j.execute("SELECT COUNT(*) FROM TCOA_COMCODE").fetchone()[0], "hrnk_qs_rows": len(jq)}}
json.dump(s, open(os.path.join(OUT, "baseline_summary.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1, default=str)
print(json.dumps(s, ensure_ascii=False, indent=1, default=str))
