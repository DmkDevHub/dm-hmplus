"""QH 코드 값 변경 4단계: TQHA_CKLST, TQHA_CKLST_ITM 코드 값 QS -> QH (vplus 쓰기, JH 접속 안 함)
- 02_generate/20_data_update.sql 의 UPDATE 2문만 한 트랜잭션으로 실행한다.
- 사전 확인: 두 테이블 모두 지금 QS 행 수가 기대값(118, 395)과 같고, QH 행이 0인지.
- 바뀐 행 수가 기대값과 다르거나 오류가 나면 전체 롤백.
사용: $env:DB_PASSWORD='...'; python -I run_step4.py
"""
import os, re, sys, datetime
import oracledb

HERE = os.path.dirname(os.path.abspath(__file__))
GEN = os.path.join(HERE, "..", "02_generate")
LOG = open(os.path.join(HERE, "step4.log"), "a", encoding="utf-8")
def log(m):
    l = f"[{datetime.datetime.now():%Y-%m-%d %H:%M:%S}] {m}"; print(l); LOG.write(l + "\n"); LOG.flush()

lines = open(os.path.join(GEN, "20_data_update.sql"), encoding="utf-8").read().split("\n")
stmts, expect = [], []
for i, l in enumerate(lines):
    m = re.match(r"-- 기대 행 수: (\d+)$", l)
    if m: expect.append(int(m.group(1))); stmts.append(lines[i + 1].rstrip().rstrip(";"))
tables = [re.match(r"UPDATE (TQHA_CKLST(?:_ITM)?) SET ", s).group(1) for s in stmts]
if tables != ["TQHA_CKLST", "TQHA_CKLST_ITM"] or expect != [118, 395]: sys.exit(f"SQL 파일 확인 실패 {tables} {expect}")

con = oracledb.connect(user="VPLUS202611A", password=os.environ["DB_PASSWORD"], dsn="192.168.1.25:1521/ORCLU")
con.autocommit = False; c = con.cursor()
log("=== 4단계 시작: 데이터 코드 값 QS -> QH ===")
for t, e in zip(tables, expect):
    total, qs, qh = c.execute(f"""SELECT COUNT(*), SUM(CASE WHEN COM_CD LIKE 'QS%' AND HO_CHK_DIV_CD2 LIKE 'QS%' THEN 1 ELSE 0 END),
                                         SUM(CASE WHEN COM_CD LIKE 'QH%' OR HO_CHK_DIV_CD2 LIKE 'QH%' THEN 1 ELSE 0 END) FROM {t}""").fetchone()
    if (total, qs, qh) != (e, e, 0):
        log(f"중단: {t} 상태가 예상과 다름 전체 {total}, QS {qs}, QH {qh} (기대 {e}, {e}, 0)"); sys.exit(1)
log("사전 확인 OK: TQHA_CKLST 118행, TQHA_CKLST_ITM 395행 모두 QS, QH 0행")
try:
    for t, s, e in zip(tables, stmts, expect):
        c.execute(s)
        if c.rowcount != e:
            con.rollback(); log(f"중단: {t} 바뀐 행 {c.rowcount} != {e} -> 전체 롤백"); sys.exit(2)
        log(f"{t}: {c.rowcount}행 UPDATE")
except oracledb.DatabaseError as ex:
    con.rollback(); log(f"중단: 오류 -> 전체 롤백 {ex}"); sys.exit(3)
for t, e in zip(tables, expect):
    left = c.execute(f"SELECT COUNT(*) FROM {t} WHERE COM_CD LIKE 'QS%' OR HO_CHK_DIV_CD2 LIKE 'QS%'").fetchone()[0]
    if left: con.rollback(); log(f"중단: {t}에 QS가 {left}행 남음 -> 전체 롤백"); sys.exit(4)
con.commit()
log("커밋 완료")
log("=== 4단계 종료 ===")
