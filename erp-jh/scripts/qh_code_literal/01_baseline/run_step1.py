"""QH 코드 값 변경 1단계: 기준선 저장 (조회 전용, JH 접속 안 함)
- QH 기준선(migration_qh/01_baseline/baseline.py)을 이 폴더에 다시 저장
- TQHA_CKLST, TQHA_CKLST_ITM 전체 값
- QH 코드 객체(PQH*/FQH*/QHSITE*) 289개의 vplus 현재 소스 -> orig_sources.sql (되돌리기 원본)
- vplus 현재 소스가 migration_qh/02_generate 생성 SQL과 같은지 확인
사용: $env:DB_PASSWORD='...'; python -I run_step1.py
"""
import csv, json, os, re, subprocess, sys, datetime
import oracledb

HERE = os.path.dirname(os.path.abspath(__file__))
SCR = os.path.join(HERE, "..", "..")
QHGEN = os.path.join(SCR, "migration_qh", "02_generate")
NOW = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

# 1) QH 기준선
r = subprocess.run([sys.executable, "-I", os.path.join(SCR, "migration_qh", "01_baseline", "baseline.py"), HERE],
                   capture_output=True, env={**os.environ, "PYTHONIOENCODING": "utf-8"})
if r.returncode: sys.exit("기준선 저장 실패: " + r.stderr.decode("utf-8", "replace"))

v = oracledb.connect(user="VPLUS202611A", password=os.environ["DB_PASSWORD"], dsn="192.168.1.25:1521/ORCLU").cursor()

# 2) 데이터 2개 테이블 전체 값
data = {}
for t in ("TQHA_CKLST", "TQHA_CKLST_ITM"):
    v.execute(f'SELECT * FROM "{t}" ORDER BY 1, 2, 3' + (", 4" if t.endswith("ITM") else ""))
    cols = [d[0] for d in v.description]; rows = v.fetchall()
    with open(os.path.join(HERE, f"data_{t}.csv"), "w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f); w.writerow(cols); w.writerows(rows)
    data[t] = {"rows": len(rows),
               "COM_CD_QS": sum(1 for x in rows if str(x[cols.index("COM_CD")]).startswith("QS")),
               "HO_CHK_DIV_CD2_QS": sum(1 for x in rows if str(x[cols.index("HO_CHK_DIV_CD2")]).startswith("QS"))}

# 3) QH 코드 객체 현재 소스
objs = v.execute("""SELECT object_name, object_type, status FROM user_objects
                     WHERE object_type IN ('PROCEDURE','FUNCTION','TYPE')
                       AND (object_name LIKE 'PQH%' OR object_name LIKE 'FQH%' OR object_name LIKE 'QHSITE%')
                     ORDER BY object_type, object_name""").fetchall()
src = {}
with open(os.path.join(HERE, "orig_sources.sql"), "w", encoding="utf-8", newline="\n") as f:
    f.write(f"-- QH 코드 객체 {len(objs)}개의 변경 전 vplus 소스 (저장: {NOW}). 되돌리기 원본.\n\n")
    for n, ty, st in objs:
        s = "".join(x[0] for x in v.execute("SELECT text FROM user_source WHERE name=:n AND type=:t ORDER BY line", n=n, t=ty))
        src[n] = s
        f.write(f"-- {n} ({ty}, {st})\nCREATE {s.rstrip()}\n/\n\n")

# 4) 생성 SQL과 비교
gen = {}
for fn in ("50_types.sql", "60_functions.sql", "70_procedures.sql"):
    for b in re.split(r"\n/\n", open(os.path.join(QHGEN, fn), encoding="utf-8").read()):
        m = re.search(r"^-- (\S+) -> (\S+)\n", b, re.M)
        if m: gen[m.group(2)] = re.sub(r"^CREATE\s+", "", b[m.end():].strip())
norm = lambda s: re.sub(r"\s+", " ", s).strip()
diff = sorted(n for n in src if n not in gen or norm(src[n]) != norm(gen[n]))
summary = {"captured_at": NOW, "data": data, "objects": len(objs),
           "objects_invalid": [n for n, _, st in objs if st != "VALID"],
           "source_equals_generated_sql": not diff, "source_diff": diff, "generated_not_in_vplus": sorted(set(gen) - set(src))}
json.dump(summary, open(os.path.join(HERE, "step1_summary.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(json.dumps(summary, ensure_ascii=False, indent=1))
