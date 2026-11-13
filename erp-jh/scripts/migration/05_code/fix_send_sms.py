"""5단계 보완(B안, 사용자 승인 2026-11-13): PQSB_SEND_SMS_Q만 다시 만든다.
- 이번 이관에서 새로 만든 객체이고 INVALID인 경우에만 DROP 후 수정된 소스로 CREATE 한다.
- 수정 내용: A.WORK_CORP_CD -> A.CORP_CD (vplus THRA_BASEINFO에 WORK_CORP_CD 컬럼 없음)
"""
import os, re, sys, datetime
import oracledb

HERE = os.path.dirname(os.path.abspath(__file__))
GEN = os.path.join(HERE, "..", "02_generate")
NAME = "PQSB_SEND_SMS_Q"
LOG = open(os.path.join(HERE, "step5.log"), "a", encoding="utf-8")
def log(m):
    l = f"[{datetime.datetime.now():%Y-%m-%d %H:%M:%S}] {m}"; print(l); LOG.write(l + "\n"); LOG.flush()

code = None
for b in re.split(r"\n/\n", open(os.path.join(GEN, "70_procedures.sql"), encoding="utf-8").read()):
    m = re.search(r"^-- (\S+) -> (\S+)\n", b, re.M)
    if m and m.group(2) == NAME: code = b[m.end():].strip()
if not code or "= A.WORK_CORP_CD" in code or "C.CORP_CD = A.CORP_CD" not in code or not code.startswith(f'CREATE PROCEDURE "{NAME}"'):
    sys.exit("수정된 소스를 찾지 못함")

vc = oracledb.connect(user="VPLUS202611A", password=os.environ["DB_PASSWORD"], dsn="192.168.1.25:1521/ORCLU").cursor()
log(f"=== 5단계 보완(B안): {NAME} 다시 만들기 ===")
row = vc.execute("SELECT status, TO_CHAR(created,'YYYY-MM-DD HH24:MI:SS') FROM user_objects WHERE object_name=:n AND object_type='PROCEDURE'", n=NAME).fetchone()
if not row or row[0] != "INVALID" or not row[1].startswith("2026-11-13"):
    log(f"중단: 예상한 상태가 아님 {row}"); sys.exit(1)
log(f"확인: {NAME} 상태 {row[0]}, 생성 {row[1]} (이번 이관에서 만든 객체)")
vc.execute(f'DROP PROCEDURE "{NAME}"'); log(f"DROP PROCEDURE {NAME}")
try:
    vc.execute(code)
except oracledb.DatabaseError as e:
    if getattr(e.args[0], "code", None) != 24344: log(f"중단: 생성 오류 {e}"); sys.exit(1)
st = vc.execute("SELECT status FROM user_objects WHERE object_name=:n", n=NAME).fetchone()[0]
errs = vc.execute("SELECT line, text FROM user_errors WHERE name=:n ORDER BY sequence", n=NAME).fetchall()
log(f"CREATE PROCEDURE {NAME}: 상태 {st}, 오류 {len(errs)}건 {errs}")
inv = vc.execute("""SELECT COUNT(*) FROM user_objects WHERE object_type IN ('FUNCTION','PROCEDURE') AND status<>'VALID'
                     AND (object_name LIKE 'PQSB\\_%' ESCAPE '\\' OR object_name LIKE 'PQSC\\_%' ESCAPE '\\' OR object_name LIKE 'FQSB\\_%' ESCAPE '\\'
                          OR object_name IN ('FQSZ_GET_CORP_NM','FQSZ_SAFT_DEFC_IF','PQSZ_IMPORT_EMPS_S'))""").fetchone()[0]
log(f"새로 만든 함수·프로시저 중 INVALID: {inv}개")
log("=== 보완 종료 ===")
