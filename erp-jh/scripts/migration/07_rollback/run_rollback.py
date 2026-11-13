"""되돌리기(사용자 지시 2026-11-13): 프로시저·함수·테이블만 지운다. TYPE은 남긴다.
- 02_generate/99_rollback.sql의 DROP PROCEDURE/FUNCTION/TABLE 문만 실행한다.
- 대상마다 매핑표의 새 객체인지, 이번 작업(2026-11-13 12:40~13:10)에 만들어졌는지 확인한 뒤 지운다.
사용: $env:DB_PASSWORD='...'; python -I run_rollback.py
"""
import csv, os, re, sys, datetime
import oracledb

HERE = os.path.dirname(os.path.abspath(__file__))
GEN = os.path.join(HERE, "..", "02_generate")
LOG = open(os.path.join(HERE, "rollback.log"), "a", encoding="utf-8")
def log(m):
    l = f"[{datetime.datetime.now():%Y-%m-%d %H:%M:%S}] {m}"; print(l); LOG.write(l + "\n"); LOG.flush()

KINDS = ("PROCEDURE", "FUNCTION", "TABLE")
stmts = [(t, n, s.strip()) for s, t, n in re.findall(r'^(DROP (PROCEDURE|FUNCTION|TYPE|TABLE) "([^"]+)".*?);\s*$',
         open(os.path.join(GEN, "99_rollback.sql"), encoding="utf-8").read(), re.M) if t in KINDS]
new = {r["VPLUS_NAME"] for r in csv.DictReader(open(os.path.join(GEN, "mapping.csv"), encoding="utf-8-sig")) if r["ACTION"] == "CREATE"}
if [n for _, n, _ in stmts if n not in new]: sys.exit("매핑표 밖 대상이 있음")

vc = oracledb.connect(user="VPLUS202611A", password=os.environ["DB_PASSWORD"], dsn="192.168.1.25:1521/ORCLU").cursor()
log(f"=== 되돌리기 시작: 프로시저·함수·테이블 {len(stmts)}개 (TYPE 제외) ===")
cr = {}
names = [n for _, n, _ in stmts]
for i in range(0, len(names), 500):
    q = "SELECT object_name, object_type, TO_CHAR(created,'YYYY-MM-DD HH24:MI') FROM user_objects WHERE object_type IN ('PROCEDURE','FUNCTION','TABLE') AND object_name IN ({})"
    for n, t, c in vc.execute(q.format(",".join(f"'{x}'" for x in names[i:i+500]))): cr[(t, n)] = c
bad = [(t, n, cr.get((t, n))) for t, n, _ in stmts if not ("2026-11-13 12:40" <= (cr.get((t, n)) or "") <= "2026-11-13 13:10")]
if bad: log(f"중단: 이번 작업에서 만든 객체가 아니거나 없음 {bad[:10]}"); sys.exit(1)
log("사전 확인 OK: 모든 대상이 이번 작업에서 만든 객체")

done = {k: 0 for k in KINDS}
for t, n, s in stmts:
    try:
        vc.execute(s)
    except oracledb.DatabaseError as e:
        log(f"중단: {s} 오류 {e} (지금까지 {done})"); sys.exit(1)
    done[t] += 1
log(f"삭제 완료: {done}")
left = vc.execute("SELECT COUNT(*) FROM user_objects WHERE object_type IN ('PROCEDURE','FUNCTION','TABLE') AND object_name IN ({})".format(
    ",".join(f"'{x}'" for x in names[:999]))).fetchone()[0]
left += vc.execute("SELECT COUNT(*) FROM user_objects WHERE object_type IN ('PROCEDURE','FUNCTION','TABLE') AND object_name IN ({})".format(
    ",".join(f"'{x}'" for x in names[999:] or ["-"]))).fetchone()[0]
types = vc.execute("SELECT object_name, status FROM user_objects WHERE object_name IN ('QSSITEOBJ01','QSSITETAB01')").fetchall()
log(f"남은 대상 {left}개, 유지한 TYPE {types}")
log("=== 되돌리기 종료 ===")
