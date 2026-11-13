"""QH 5단계: vplus에 함수 12개 -> 프로시저 275개 생성, 새 객체만 재컴파일, 오류 수집
- JH: 접속하지 않는다. vplus: 02_generate/60_functions.sql, 70_procedures.sql의 CREATE와
  새로 만든 객체에 대한 ALTER ... COMPILE만 실행한다. 소스는 고치지 않는다.
사용: python -I run_step5.py
"""
import csv, json, os, re, sys, datetime
import oracledb

HERE = os.path.dirname(os.path.abspath(__file__))
GEN = os.path.join(HERE, "..", "02_generate")
DSN = "192.168.1.25:1521/ORCLU"
LOG = open(os.path.join(HERE, "step5.log"), "a", encoding="utf-8")
def log(m):
    l = f"[{datetime.datetime.now():%Y-%m-%d %H:%M:%S}] {m}"; print(l); LOG.write(l + "\n"); LOG.flush()

def blocks(fname, kind):
    out = []
    for b in re.split(r"\n/\n", open(os.path.join(GEN, fname), encoding="utf-8").read()):
        m = re.search(r"^-- (\S+) -> (\S+)\n", b, re.M)
        if not m: continue
        code = b[m.end():].strip()
        if not re.match(r"CREATE\s+" + kind + r'\s+"?' + re.escape(m.group(2)) + r'\b', code, re.I):
            sys.exit(f"unexpected block {m.group(2)}")
        if re.match(r"CREATE\s+OR\s+REPLACE", code, re.I): sys.exit("CREATE OR REPLACE found")
        out.append((kind, m.group(1), m.group(2), code))
    return out

funcs = blocks("60_functions.sql", "FUNCTION")
procs = blocks("70_procedures.sql", "PROCEDURE")
assert len(funcs) == 12 and len(procs) == 275, (len(funcs), len(procs))
allobj = funcs + procs
names = [n for _, _, n, _ in allobj]

vp = oracledb.connect(user="VPLUS202611A", password=os.environ["DB_PASSWORD"], dsn=DSN); vc = vp.cursor()
log("=== 5단계 시작 ===")
exist = {r[0] for r in vc.execute("SELECT object_name FROM user_objects")}
clash = sorted(set(names) & exist)
if clash: log(f"중단: 이미 있는 이름 {clash}"); sys.exit(1)
log(f"사전 확인 OK: 새 이름 {len(names)}개 모두 vplus에 없음")

warn = []
for kind, old, new, code in allobj:
    try:
        vc.execute(code)
        if getattr(vc, "warning", None): warn.append(new)
    except oracledb.DatabaseError as e:
        err = e.args[0]
        if getattr(err, "code", None) == 24344:   # 생성은 됐지만 컴파일 오류
            warn.append(new)
        else:
            log(f"중단: {kind} {new} 생성 오류 {e}"); sys.exit(1)
log(f"생성 완료: 함수 {len(funcs)}, 프로시저 {len(procs)} (생성 시 컴파일 경고 {len(warn)}개)")

def status():
    q = "SELECT object_name, object_type, status FROM user_objects WHERE object_type IN ('FUNCTION','PROCEDURE') AND object_name IN ({})"
    out = {}
    for i in range(0, len(names), 500):
        for n, t, s in vc.execute(q.format(",".join(f"'{x}'" for x in names[i:i+500]))): out[n] = (t, s)
    return out

st = status()
inv = [n for n, (t, s) in st.items() if s != "VALID"]
log(f"생성 직후 INVALID {len(inv)}개")
rnd = 0
while inv:
    rnd += 1
    for n in inv:
        t = st[n][0]
        try: vc.execute(f'ALTER {t} "{n}" COMPILE')
        except oracledb.DatabaseError as e:
            if getattr(e.args[0], "code", None) != 24344: log(f"재컴파일 {n} 오류 {e}")
    st = status()
    new_inv = [n for n, (t, s) in st.items() if s != "VALID"]
    log(f"재컴파일 {rnd}회차: INVALID {len(inv)} -> {len(new_inv)}")
    if len(new_inv) >= len(inv): inv = new_inv; break
    inv = new_inv

errs = {}
if inv:
    q = "SELECT name, type, line, position, text FROM user_errors WHERE name IN ({}) ORDER BY name, sequence"
    for n, t, line, pos, text in vc.execute(q.format(",".join(f"'{x}'" for x in inv))):
        errs.setdefault(n, []).append({"type": t, "line": line, "pos": pos, "text": text.strip()})
res = {"created": {"FUNCTION": len(funcs), "PROCEDURE": len(procs)}, "missing": sorted(set(names) - set(st)),
       "valid": sum(1 for v in st.values() if v[1] == "VALID"), "invalid": sorted(inv), "errors": errs,
       "src_map": {new: old for _, old, new, _ in allobj}}
json.dump(res, open(os.path.join(HERE, "step5_result.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
log(f"결과: 생성 {len(st)}개, VALID {res['valid']}, INVALID {len(inv)} {inv}")
log("=== 5단계 종료 ===")
