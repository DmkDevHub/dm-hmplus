"""공통코드(QS→QH) 3단계: vplus TCOA_COMCODE에 INSERT (덮어쓰지 않음)
- 실행 전 키 중복 검사: 1건이라도 있으면 오류로 멈춘다(INSERT 하지 않음).
- 02_generate/10_insert.sql의 INSERT만 한 트랜잭션으로 실행한다. 오류가 나면 전체 롤백.
- JH에는 접속하지 않는다.
사용: $env:DB_PASSWORD='...'; python -I run_step3.py
"""
import csv, os, re, sys, datetime
import oracledb

HERE = os.path.dirname(os.path.abspath(__file__))
GEN = os.path.join(HERE, "..", "02_generate")
LOG = open(os.path.join(HERE, "step3.log"), "a", encoding="utf-8")
def log(m):
    l = f"[{datetime.datetime.now():%Y-%m-%d %H:%M:%S}] {m}"; print(l); LOG.write(l + "\n"); LOG.flush()

keys = [(r["VPLUS_COM_CD"], r["VPLUS_HRNK_CD"]) for r in csv.DictReader(open(os.path.join(GEN, "mapping.csv"), encoding="utf-8-sig")) if r["ACTION"] == "INSERT"]
stmts = [l.rstrip().rstrip(";") for l in open(os.path.join(GEN, "10_insert.sql"), encoding="utf-8") if l.startswith("INSERT INTO TCOA_COMCODE (")]
other = [l for l in open(os.path.join(GEN, "10_insert.sql"), encoding="utf-8") if l.strip() and not l.startswith("--") and not l.startswith("INSERT INTO TCOA_COMCODE (")]
if other or len(stmts) != len(keys) or len(set(keys)) != len(keys): sys.exit(f"SQL 파일 확인 실패: other={len(other)} stmts={len(stmts)} keys={len(keys)}")
stmt_keys = [tuple(re.search(r"VALUES \('([^']*)', '([^']*)'", s).groups()) for s in stmts]
if stmt_keys != keys: sys.exit("INSERT 문의 키가 매핑표와 다름")

con = oracledb.connect(user="VPLUS202611A", password=os.environ["DB_PASSWORD"], dsn="192.168.1.25:1521/ORCLU")
con.autocommit = False
c = con.cursor()
log(f"=== 공통코드 3단계 시작: INSERT {len(stmts)}행 ===")
before = c.execute("SELECT COUNT(*) FROM TCOA_COMCODE").fetchone()[0]
exist = {tuple(r) for r in c.execute("SELECT COM_CD, HRNK_CD FROM TCOA_COMCODE")}
dup = sorted(set(keys) & exist)
if dup:
    log(f"오류: vplus에 같은 키가 {len(dup)}건 있음. 덮어쓰지 않고 멈춤. {dup[:20]}"); sys.exit(2)
log(f"사전 확인 OK: 넣을 키 {len(keys)}개 모두 vplus에 없음 (현재 {before}행)")

done = 0
try:
    for s, k in zip(stmts, keys):
        c.execute(s); done += 1
except oracledb.DatabaseError as e:
    con.rollback()
    log(f"오류: {done + 1}번째 INSERT {k} 실패 -> 전체 롤백. {e}"); sys.exit(3)
after_tx = c.execute("SELECT COUNT(*) FROM TCOA_COMCODE").fetchone()[0]
if after_tx != before + len(stmts):
    con.rollback(); log(f"오류: 행 수 불일치 {before} + {len(stmts)} != {after_tx} -> 전체 롤백"); sys.exit(4)
con.commit()
log(f"INSERT {done}행 커밋. 행 수 {before} -> {after_tx}")
log("=== 공통코드 3단계 종료 ===")
