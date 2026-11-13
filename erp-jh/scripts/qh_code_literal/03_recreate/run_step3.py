"""QH 코드 값 변경 3단계: QH 프로시저 93개 다시 만들기 (vplus 쓰기, JH 접속 안 함)
- 02_generate/10_recreate.sql 의 DROP -> CREATE 만 실행한다. 대상은 QH 매핑표의 새 객체(PQH*/FQH*)뿐이다.
- CREATE가 실패하면 그 객체를 99_rollback_objects.sql(원래 소스)로 바로 다시 만들고 멈춘다.
- 다시 만든 객체와 호출 객체(recompile_dependents.txt) 중 INVALID인 것만 다시 컴파일한다.
사용: $env:DB_PASSWORD='...'; python -I run_step3.py
"""
import csv, json, os, re, sys, datetime
import oracledb

HERE = os.path.dirname(os.path.abspath(__file__))
GEN = os.path.join(HERE, "..", "02_generate")
QHMAP = os.path.join(HERE, "..", "..", "migration_qh", "02_generate", "mapping.csv")
LOG = open(os.path.join(HERE, "step3.log"), "a", encoding="utf-8")
def log(m):
    l = f"[{datetime.datetime.now():%Y-%m-%d %H:%M:%S}] {m}"; print(l); LOG.write(l + "\n"); LOG.flush()

def parse(fname):
    out = []
    for b in re.split(r"\n/\n", open(os.path.join(GEN, fname), encoding="utf-8").read()):
        m = re.search(r'^-- (\S+)\nDROP (PROCEDURE|FUNCTION) "([^"]+)";\n', b, re.M)
        if not m: continue
        if m.group(1) != m.group(3): sys.exit(f"이름 불일치 {m.group(1)}")
        create = b[m.end():].strip()
        if not re.match(r'CREATE\s+' + m.group(2) + r'\s+"?' + re.escape(m.group(1)) + r'\b', create): sys.exit(f"CREATE 확인 실패 {m.group(1)}")
        if re.match(r"CREATE\s+OR\s+REPLACE", create, re.I): sys.exit("CREATE OR REPLACE 발견")
        out.append((m.group(1), m.group(2), create))
    return out
new = parse("10_recreate.sql"); old = {n: c for n, _, c in parse("99_rollback_objects.sql")}
qh = {r["VPLUS_NAME"] for r in csv.DictReader(open(QHMAP, encoding="utf-8-sig")) if r["ACTION"] == "CREATE"}
deps = [l.strip() for l in open(os.path.join(GEN, "recompile_dependents.txt"), encoding="utf-8") if l.strip()]
names = [n for n, _, _ in new]
if len(new) != 93 or set(names) != set(old): sys.exit(f"대상 확인 실패 {len(new)} / {len(old)}")
if [n for n in names + deps if n not in qh or not n.startswith(("PQH", "FQH"))]: sys.exit("QH 새 객체가 아닌 대상이 있음")

con = oracledb.connect(user="VPLUS202611A", password=os.environ["DB_PASSWORD"], dsn="192.168.1.25:1521/ORCLU"); c = con.cursor()
log(f"=== 3단계 시작: QH 프로시저 {len(new)}개 다시 만들기 ===")
inl = lambda xs: ",".join(f"'{x}'" for x in xs)
st = dict(c.execute(f"SELECT object_name, status FROM user_objects WHERE object_type IN ('PROCEDURE','FUNCTION') AND object_name IN ({inl(names)})").fetchall())
if len(st) != len(names) or any(s != "VALID" for s in st.values()):
    log(f"중단: 대상이 없거나 VALID가 아님 {[(n, st.get(n)) for n in names if st.get(n) != 'VALID'][:10]}"); sys.exit(1)
log("사전 확인 OK: 93개 모두 있음, 모두 VALID, 모두 QH 새 객체")

def create(sql):
    try: c.execute(sql)
    except oracledb.DatabaseError as e:
        if getattr(e.args[0], "code", None) != 24344: raise
done = 0
for n, ty, sql in new:
    c.execute(f'DROP {ty} "{n}"')
    try:
        create(sql); done += 1
    except oracledb.DatabaseError as e:
        log(f"오류: {n} CREATE 실패 {e} -> 원래 소스로 복구")
        try: create(old[n]); log(f"{n} 원래 소스로 복구함")
        except oracledb.DatabaseError as e2: log(f"복구도 실패 {n}: {e2}")
        log(f"중단 (지금까지 {done}개 다시 만듦)"); sys.exit(2)
log(f"DROP -> CREATE 완료: {done}개")

targets = names + deps
def invalid():
    return [r[0] for r in c.execute(f"SELECT object_name FROM user_objects WHERE object_type IN ('PROCEDURE','FUNCTION') AND status <> 'VALID' AND object_name IN ({inl(targets)})")]
inv = invalid(); log(f"생성 직후 INVALID {len(inv)}개 {inv[:10]}")
rnd = 0
while inv:
    rnd += 1
    for n in inv:
        ty = c.execute("SELECT object_type FROM user_objects WHERE object_name=:n AND object_type IN ('PROCEDURE','FUNCTION')", n=n).fetchone()[0]
        try: c.execute(f'ALTER {ty} "{n}" COMPILE')
        except oracledb.DatabaseError as e:
            if getattr(e.args[0], "code", None) != 24344: log(f"재컴파일 {n} 오류 {e}")
    new_inv = invalid(); log(f"재컴파일 {rnd}회차: INVALID {len(inv)} -> {len(new_inv)}")
    if len(new_inv) >= len(inv): inv = new_inv; break
    inv = new_inv
errs = {}
if inv:
    for n, line, text in c.execute(f"SELECT name, line, text FROM user_errors WHERE name IN ({inl(inv)}) ORDER BY name, sequence"):
        errs.setdefault(n, []).append([line, text.strip()])
json.dump({"recreated": done, "invalid": inv, "errors": errs, "dependents": deps}, open(os.path.join(HERE, "step3_result.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
log(f"결과: 다시 만든 객체 {done}개, 호출 객체 {len(deps)}개 포함 INVALID {len(inv)}개 {inv}")
log("=== 3단계 종료 ===")
