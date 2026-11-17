"""9장 미확인 1·2 조회 (vplus DB 읽기 전용). usage: DB_PASSWORD=... python -I check_db.py
- 새 매퍼가 CALL 하는 프로시저의 인자 개수 vs vplus DB(ALL_ARGUMENTS)
- 매핑표에 없는 객체 3개의 존재 여부
"""
import os, re, sys
import oracledb
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import copy_qh_ptn as c

DSN = "192.168.1.25:1521/ORCLU"
_, results = c.build()
calls = {}
for _, d, _, new in results:
    if not d.endswith(".xml"): continue
    for m in re.finditer(r"CALL\s+([A-Z0-9_]+)\s*\((.*?)\)\s*\}", new, re.S | re.I):
        name = m.group(1).upper()
        n = len(re.findall(r"#\{", m.group(2)))
        calls.setdefault(name, set()).add((n, d))
lines = []
with oracledb.connect(user="VPLUS202611A", password=os.environ["DB_PASSWORD"], dsn=DSN) as con:
    cur = con.cursor()
    names = sorted(calls)
    binds = ",".join(f":{i+1}" for i in range(len(names)))
    cur.execute(f"""SELECT OBJECT_NAME, COUNT(ARGUMENT_NAME) FROM USER_ARGUMENTS
                    WHERE PACKAGE_NAME IS NULL AND DATA_LEVEL = 0 AND OBJECT_NAME IN ({binds}) GROUP BY OBJECT_NAME""", names)
    db = dict(cur.fetchall())
    cur.execute(f"SELECT OBJECT_NAME, OBJECT_TYPE, STATUS FROM USER_OBJECTS WHERE OBJECT_NAME IN ({binds})", names)
    st = {r[0]: (r[1], r[2]) for r in cur.fetchall()}
    ng = 0
    for nme in names:
        for n, d in sorted(calls[nme]):
            dbn = db.get(nme); s = st.get(nme, ("MISSING", ""))
            ok = dbn == n and s[1] == "VALID"
            ng += not ok
            lines.append(f"[{'OK' if ok else 'NG'}] {nme:32} mapper={n:3} db={dbn} {s[0]} {s[1]}  {d}")
    lines.append(f"procedures: {len(names)}, NG: {ng}")
    um = ["PQSC_NCR_AB_S", "PQSC_NCR_REP_S", "TQSC_NCR_REP", "VQSZ_TRADE", "VQSZ_SITEINFO"]
    cur.execute(f"SELECT OBJECT_NAME, OBJECT_TYPE, STATUS FROM USER_OBJECTS WHERE OBJECT_NAME IN ({','.join(f':{i+1}' for i in range(len(um)))})", um)
    found = {r[0]: r[1:] for r in cur.fetchall()}
    for u in um:
        lines.append(f"[unmapped] {u}: {found.get(u, 'NOT FOUND in VPLUS202611A')}")
open(os.path.join(c.HERE, "35_db_check.log"), "w", encoding="utf-8").write("\n".join(lines) + "\n")
print("\n".join(lines))
