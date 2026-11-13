"""결정 2(사용자 지시 2026-11-13): 이관 때 만든 TYPE QSSITETAB01 -> QSSITEOBJ01 삭제
사용: $env:DB_PASSWORD='...'; python -I drop_qs_types.py
"""
import os, sys, datetime
import oracledb
HERE = os.path.dirname(os.path.abspath(__file__))
LOG = open(os.path.join(HERE, "rollback.log"), "a", encoding="utf-8")
def log(m):
    l = f"[{datetime.datetime.now():%Y-%m-%d %H:%M:%S}] {m}"; print(l); LOG.write(l + "\n"); LOG.flush()
c = oracledb.connect(user="VPLUS202611A", password=os.environ["DB_PASSWORD"], dsn="192.168.1.25:1521/ORCLU").cursor()
log("=== QS TYPE 삭제 시작 (결정 2) ===")
rows = dict((n, cr) for n, cr in c.execute("SELECT object_name, TO_CHAR(created,'YYYY-MM-DD HH24:MI') FROM user_objects WHERE object_type='TYPE' AND object_name IN ('QSSITEOBJ01','QSSITETAB01')"))
if set(rows) != {"QSSITEOBJ01", "QSSITETAB01"} or not all("2026-11-13 12:40" <= v <= "2026-11-13 13:10" for v in rows.values()):
    log(f"중단: 예상한 상태가 아님 {rows}"); sys.exit(1)
deps = c.execute("""SELECT name, type, referenced_name FROM user_dependencies
                     WHERE referenced_name IN ('QSSITEOBJ01','QSSITETAB01')
                       AND NOT (name='QSSITETAB01' AND referenced_name='QSSITEOBJ01')""").fetchall()
cols = c.execute("SELECT table_name, column_name FROM user_tab_columns WHERE data_type IN ('QSSITEOBJ01','QSSITETAB01')").fetchall()
if deps or cols:
    log(f"중단: 참조하는 객체 있음 {deps} {cols}"); sys.exit(1)
log(f"사전 확인 OK: 생성 {rows}, 참조 객체 없음")
for n in ("QSSITETAB01", "QSSITEOBJ01"):
    c.execute(f'DROP TYPE "{n}"'); log(f"DROP TYPE {n}")
left = c.execute("SELECT COUNT(*) FROM user_objects WHERE object_name IN ('QSSITEOBJ01','QSSITETAB01')").fetchone()[0]
log(f"남은 QS TYPE {left}개")
log("=== QS TYPE 삭제 종료 ===")
