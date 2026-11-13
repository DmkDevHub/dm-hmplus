"""QH 3단계: vplus에 테이블 생성, 14개 테이블 데이터 복사, FK, 코멘트, 검증
- JH: SELECT만 한다.
- vplus: 02_generate의 SQL(CREATE TABLE/INDEX, ALTER TABLE ADD CONSTRAINT, COMMENT)과 새 테이블에 대한 INSERT만 한다.
- 오류가 나면 즉시 멈춘다(자동 되돌리기 없음, 99_rollback.sql로 수동 되돌리기).
사용: python -I run_step3.py
"""
import csv, json, os, re, sys, datetime
import oracledb

HERE = os.path.dirname(os.path.abspath(__file__))
GEN = os.path.join(HERE, "..", "02_generate")
DSN = "192.168.1.25:1521/ORCLU"
oracledb.defaults.fetch_lobs = False
LOG = open(os.path.join(HERE, "step3.log"), "a", encoding="utf-8")

def log(msg):
    line = f"[{datetime.datetime.now():%Y-%m-%d %H:%M:%S}] {msg}"
    print(line); LOG.write(line + "\n"); LOG.flush()

def body(fname):
    txt = open(os.path.join(GEN, fname), encoding="utf-8").read()
    return "\n".join(l for l in txt.split("\n") if not l.startswith("--"))

def split_semicolon(txt):
    return [s.strip() for s in re.split(r";[ \t]*(?:\n|$)", txt) if s.strip()]

mapping = list(csv.DictReader(open(os.path.join(GEN, "mapping.csv"), encoding="utf-8-sig")))
tmap = {r["JH_NAME"]: r["VPLUS_NAME"] for r in mapping if r["KIND"] == "TABLE"}
cmap = {r["JH_NAME"]: r["VPLUS_NAME"] for r in mapping if r["KIND"] in ("PK", "FK")}
data_tables = [r["JH_TABLE"] for r in csv.DictReader(open(os.path.join(GEN, "20_data_tables.csv"), encoding="utf-8-sig"))]

jh = oracledb.connect(user="JH202610", password=os.environ["DB_PASSWORD"], dsn=DSN); jc = jh.cursor()
vp = oracledb.connect(user="VPLUS202611A", password=os.environ["DB_PASSWORD"], dsn=DSN); vc = vp.cursor()
vp.autocommit = False
log("=== 3단계 시작 ===")

# 0) 사전 확인: 새 이름이 vplus에 없어야 한다
new_names = set(tmap.values()) | set(cmap.values())
exist = {r[0] for r in vc.execute("SELECT object_name FROM user_objects")} | {r[0] for r in vc.execute("SELECT constraint_name FROM user_constraints")}
clash = sorted(new_names & exist)
if clash:
    log(f"중단: vplus에 이미 있는 이름 {clash}"); sys.exit(1)
log(f"사전 확인 OK: 새 이름 {len(new_names)}개 모두 vplus에 없음")

def run(stmts, label):
    for i, s in enumerate(stmts, 1):
        if re.match(r"\s*(DROP|TRUNCATE|DELETE|UPDATE|CREATE\s+OR\s+REPLACE)", s, re.I):
            log(f"중단: 허용하지 않는 문장 {s[:80]}"); sys.exit(1)
        try:
            vc.execute(s)
        except oracledb.DatabaseError as e:
            log(f"중단: {label} {i}번째 문장 오류: {e}\n{s[:500]}"); sys.exit(1)
    log(f"{label}: {len(stmts)}개 문장 실행 완료")

# 1) 테이블 108개 (PK·NOT NULL·DEFAULT 포함, FK 제외)
run(split_semicolon(body("10_tables.sql")), "테이블 생성")

# 2) 데이터 복사 (14개만)
copied = {}
for t in data_tables:
    nt = tmap[t]
    cols = [r[0] for r in jc.execute("SELECT column_name FROM user_tab_columns WHERE table_name=:t ORDER BY column_id", t=t)]
    clist = ", ".join(f'"{c}"' for c in cols)
    ins = f'INSERT INTO "{nt}" ({clist}) VALUES (' + ", ".join(f":{i+1}" for i in range(len(cols))) + ")"
    jc.execute(f'SELECT {clist} FROM "{t}"')
    n = 0
    try:
        while True:
            rows = jc.fetchmany(2000)
            if not rows: break
            vc.executemany(ins, rows); n += len(rows)
        vp.commit()
    except oracledb.DatabaseError as e:
        vp.rollback(); log(f"중단: {t} -> {nt} 데이터 복사 오류(이 테이블은 롤백): {e}"); sys.exit(1)
    copied[nt] = n
    log(f"데이터 복사 {t} -> {nt}: {n}건 커밋")

# 3) FK 31개
run(split_semicolon(body("30_fk.sql")), "FK 생성")

# 4) 코멘트
ctxt = body("40_comments.sql").strip()
cstmts = [s.strip().rstrip(";") for s in re.split(r"\n(?=COMMENT ON )", ctxt) if s.strip()]
run(cstmts, "코멘트")

# 5) 검증
res = {"copied": copied}
def cnt(c, t): return c.execute(f'SELECT COUNT(*) FROM "{t}"').fetchone()[0]
data_chk, zero_bad = [], []
for t, nt in tmap.items():
    if t in data_tables:
        cols = [r[0] for r in jc.execute("SELECT column_name FROM user_tab_columns WHERE table_name=:t ORDER BY column_id", t=t)]
        clist = ", ".join(f'"{c}"' for c in cols)
        a = sorted(map(tuple, jc.execute(f'SELECT {clist} FROM "{t}"').fetchall()), key=repr)
        b = sorted(map(tuple, vc.execute(f'SELECT {clist} FROM "{nt}"').fetchall()), key=repr)
        data_chk.append([t, nt, len(a), len(b), a == b])
    else:
        n = cnt(vc, nt)
        if n: zero_bad.append([nt, n])
res["data"] = data_chk; res["nonzero_structure_only"] = zero_bad

colq = """SELECT table_name, column_id, column_name, data_type, data_length, data_precision, data_scale, nullable, char_used, data_default
            FROM user_tab_columns WHERE table_name IN ({}) ORDER BY table_name, column_id"""
def cols(c, names):
    out = {}
    for i in range(0, len(names), 500):
        part = names[i:i+500]
        q = colq.format(",".join(f"'{x}'" for x in part))
        for r in c.execute(q):
            out.setdefault(r[0], []).append(tuple((x.strip() if isinstance(x, str) else x) for x in r[1:]))
    return out
jcols, vcols = cols(jc, list(tmap)), cols(vc, list(tmap.values()))
res["column_diff"] = [t for t in tmap if jcols.get(t) != vcols.get(tmap[t])]

vcons = vc.execute(f"""SELECT constraint_name, constraint_type, status, validated FROM user_constraints
                        WHERE table_name IN ({",".join(f"'{x}'" for x in tmap.values())}) AND constraint_type IN ('P','R')""").fetchall()
res["pk_count"] = sum(1 for r in vcons if r[1] == "P")
res["fk_count"] = sum(1 for r in vcons if r[1] == "R")
res["cons_not_enabled_validated"] = [r[0] for r in vcons if r[2] != "ENABLED" or r[3] != "VALIDATED"]
res["cons_name_mismatch"] = sorted(set(cmap.values()) ^ {r[0] for r in vcons})
jtc = jc.execute("SELECT COUNT(*) FROM user_tab_comments WHERE SUBSTR(table_name,1,5) IN ('TQSA_','TQSB_') AND comments IS NOT NULL").fetchone()[0]
jcc = jc.execute("SELECT COUNT(*) FROM user_col_comments WHERE SUBSTR(table_name,1,5) IN ('TQSA_','TQSB_') AND comments IS NOT NULL").fetchone()[0]
vtc = vc.execute("SELECT COUNT(*) FROM user_tab_comments WHERE SUBSTR(table_name,1,5) IN ('TQHA_','TQHB_') AND table_name IN (SELECT table_name FROM user_tables) AND comments IS NOT NULL AND table_name IN ({})".format(",".join(f"'{x}'" for x in tmap.values()))).fetchone()[0]
vcc = vc.execute("SELECT COUNT(*) FROM user_col_comments WHERE comments IS NOT NULL AND table_name IN ({})".format(",".join(f"'{x}'" for x in tmap.values()))).fetchone()[0]
res["comments"] = {"jh_table": jtc, "vplus_table": vtc, "jh_column": jcc, "vplus_column": vcc}
res["new_tables_in_vplus"] = vc.execute("SELECT COUNT(*) FROM user_tables WHERE table_name IN ({})".format(",".join(f"'{x}'" for x in tmap.values()))).fetchone()[0]
json.dump(res, open(os.path.join(HERE, "step3_result.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1, default=str)
ok = (res["new_tables_in_vplus"] == 108 and all(x[4] for x in data_chk) and len(data_chk) == 14 and not zero_bad
      and not res["column_diff"] and res["pk_count"] == 95 and res["fk_count"] == 31
      and not res["cons_not_enabled_validated"] and not res["cons_name_mismatch"] and jtc == vtc and jcc == vcc)
log(f"검증: {'모두 OK' if ok else '확인 필요'} -> step3_result.json")
log("=== 3단계 종료 ===")
