"""35_db_check.log의 NG 상세 (읽기 전용). usage: DB_PASSWORD=... python -I check_db2.py
- 인자별 위치·이름·IN/OUT·DEFAULT 여부
- 매퍼 인자 수 < DB 인자 수일 때, 남는 인자가 모두 뒤쪽 DEFAULT인지
- 없는 객체는 ALL_OBJECTS / 동의어에서 찾는다
- 비교용: B 기존 QS 매퍼가 같은 이름의 QS 프로시저를 몇 개 인자로 부르는지
"""
import os, re, sys
import oracledb
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import copy_qh_ptn as c

DSN = "192.168.1.25:1521/ORCLU"
_, results = c.build()
calls = {}
for _, d, _, new in results:
    if d.endswith(".xml"):
        for m in re.finditer(r"CALL\s+([A-Z0-9_]+)\s*\((.*?)\)\s*\}", new, re.S | re.I):
            calls.setdefault(m.group(1).upper(), []).append((len(re.findall(r"#\{", m.group(2))), d))
# B 기존 QS 매퍼
bq = {}
for r, _, fs in os.walk(os.path.join(c.B, "resources", "sqlmap", "mybatis", "qs")):
    for f in fs:
        t = open(os.path.join(r, f), encoding="utf-8", errors="replace").read()
        for m in re.finditer(r"CALL\s+([A-Z0-9_]+)\s*\((.*?)\)\s*\}", t, re.S | re.I):
            bq.setdefault(m.group(1).upper(), set()).add(len(re.findall(r"#\{", m.group(2))))
L = []
with oracledb.connect(user="VPLUS202611A", password=os.environ["DB_PASSWORD"], dsn=DSN) as con:
    cur = con.cursor()
    def args(name, owner=None):
        q = """SELECT POSITION, ARGUMENT_NAME, IN_OUT, DEFAULTED FROM ALL_ARGUMENTS
               WHERE OBJECT_NAME = :1 AND PACKAGE_NAME IS NULL AND DATA_LEVEL = 0 AND ARGUMENT_NAME IS NOT NULL"""
        p = [name]
        if owner: q += " AND OWNER = :2"; p.append(owner)
        else: q += " AND OWNER = USER"
        cur.execute(q + " ORDER BY POSITION", p); return cur.fetchall()
    for name in sorted(calls):
        a = args(name)
        ns = sorted({n for n, _ in calls[name]})
        if not a:
            cur.execute("SELECT OWNER, OBJECT_TYPE, STATUS FROM ALL_OBJECTS WHERE OBJECT_NAME = :1", [name]); objs = cur.fetchall()
            cur.execute("SELECT OWNER, TABLE_OWNER, TABLE_NAME FROM ALL_SYNONYMS WHERE SYNONYM_NAME = :1", [name]); syn = cur.fetchall()
            L.append(f"[MISSING] {name}: mapper={ns} all_objects={objs} synonyms={syn}")
            continue
        cur.execute("SELECT STATUS FROM USER_OBJECTS WHERE OBJECT_NAME = :1", [name]); status = cur.fetchone()[0]
        total = len(a); nodef = sum(1 for x in a if x[3] != "Y")
        verdict = []
        for n in ns:
            if n == total: verdict.append(f"{n}=OK")
            elif n < total and all(x[3] == "Y" for x in a[n:]): verdict.append(f"{n}=OK(뒤 {total-n}개 DEFAULT)")
            else: verdict.append(f"{n}=NG")
        if status != "VALID" or any("NG" in v for v in verdict):
            src = name.replace("PQHA_", "PQSA_").replace("PQHB_", "PQSB_")
            L.append(f"[{'NG' if any('NG' in v for v in verdict) else 'CHK'}] {name} status={status} db_args={total} (DEFAULT 아님 {nodef}) mapper={verdict}  B기존QS매퍼({src})={sorted(bq.get(src, []))}")
            L.append("      " + ", ".join(f"{x[0]}:{x[1]}{'(D)' if x[3]=='Y' else ''}{'' if x[2]=='IN' else '/'+x[2]}" for x in a))
            if status != "VALID":
                cur.execute("SELECT LINE, POSITION, TEXT FROM USER_ERRORS WHERE NAME = :1 ORDER BY SEQUENCE FETCH FIRST 3 ROWS ONLY", [name])
                for e in cur.fetchall(): L.append(f"      ERR line {e[0]}: {e[2].strip()[:150]}")
open(os.path.join(c.HERE, "36_db_check_detail.log"), "w", encoding="utf-8").write("\n".join(L) + "\n")
print("\n".join(L))
