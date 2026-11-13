"""QH 4단계: vplus에 TYPE 2개 생성 (QHSITEOBJ01 -> QHSITETAB01), JH 원본 QSSITEOBJ01/QSSITETAB01과 정의 비교
- JH: SELECT만 한다. vplus: 02_generate/50_types.sql의 CREATE TYPE만 실행한다.
사용: python -I run_step4.py
"""
import json, os, re, sys, datetime
import oracledb

HERE = os.path.dirname(os.path.abspath(__file__))
GEN = os.path.join(HERE, "..", "02_generate")
DSN = "192.168.1.25:1521/ORCLU"
LOG = open(os.path.join(HERE, "step4.log"), "a", encoding="utf-8")
def log(m):
    l = f"[{datetime.datetime.now():%Y-%m-%d %H:%M:%S}] {m}"; print(l); LOG.write(l + "\n"); LOG.flush()

blocks = []
for b in re.split(r"\n/\n", open(os.path.join(GEN, "50_types.sql"), encoding="utf-8").read()):
    lines = b.split("\n")
    name = next((re.match(r"-- (\S+) -> (\S+)", l).group(2) for l in lines if re.match(r"-- \S+ -> \S+", l)), None)
    code = "\n".join(l for l in lines if not re.match(r"-- ", l)).strip()
    if name and code:
        if not re.match(r'CREATE\s+TYPE\s+"?' + name + r'\b', code): sys.exit(f"unexpected block {name}")
        blocks.append((name, code))
assert [n for n, _ in blocks] == ["QHSITEOBJ01", "QHSITETAB01"], blocks

jh = oracledb.connect(user="JH202610", password=os.environ["DB_PASSWORD"], dsn=DSN); jc = jh.cursor()
vp = oracledb.connect(user="VPLUS202611A", password=os.environ["DB_PASSWORD"], dsn=DSN); vc = vp.cursor()
log("=== 4단계 시작 ===")
exist = [r[0] for r in vc.execute("SELECT object_name FROM user_objects WHERE object_name IN ('QHSITEOBJ01','QHSITETAB01')")]
if exist: log(f"중단: 이미 있음 {exist}"); sys.exit(1)
for name, code in blocks:
    try:
        vc.execute(code)
    except oracledb.DatabaseError as e:
        log(f"중단: {name} 생성 오류 {e}"); sys.exit(1)
    log(f"TYPE {name} 생성")

QMAP = {"QSSITEOBJ01": "QHSITEOBJ01", "QSSITETAB01": "QHSITETAB01"}
def info(c, names):
    out = {}
    for n in names:
        out[QMAP.get(n, n)] = {
            "status": c.execute("SELECT status FROM user_objects WHERE object_name=:n AND object_type='TYPE'", n=n).fetchone(),
            "type": c.execute("SELECT typecode, attributes, methods FROM user_types WHERE type_name=:n", n=n).fetchone(),
            "attrs": c.execute("SELECT attr_no, attr_name, attr_type_name, length, precision, scale FROM user_type_attrs WHERE type_name=:n ORDER BY attr_no", n=n).fetchall(),
            "coll": c.execute("SELECT coll_type, upper_bound, elem_type_name FROM user_coll_types WHERE type_name=:n", n=n).fetchone(),
            "errors": c.execute("SELECT COUNT(*) FROM user_errors WHERE name=:n", n=n).fetchone()[0],
        }
    return out
j, v = info(jc, QMAP.keys()), info(vc, QMAP.values())
for n in j:   # JH 컬렉션의 원소 TYPE 이름을 QH 이름으로 바꿔 비교
    if j[n]["coll"]: j[n]["coll"] = tuple(QMAP.get(x, x) for x in j[n]["coll"])
res = {n: {"vplus_status": v[n]["status"][0] if v[n]["status"] else None, "errors": v[n]["errors"],
           "same_as_jh": {k: j[n][k] == v[n][k] for k in ("type", "attrs", "coll")}} for n in j}
json.dump(res, open(os.path.join(HERE, "step4_result.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
ok = all(r["vplus_status"] == "VALID" and r["errors"] == 0 and all(r["same_as_jh"].values()) for r in res.values())
log(f"검증: {'모두 OK' if ok else '확인 필요'} {res}")
log("=== 4단계 종료 ===")
