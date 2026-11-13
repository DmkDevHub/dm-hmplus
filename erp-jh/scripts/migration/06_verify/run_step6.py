"""6단계: 최종 검증 (조회 전용 - JH/vplus 모두 SELECT만)
사용: python -I run_step6.py
"""
import csv, json, os, re, subprocess, sys, datetime
from collections import Counter
import oracledb

HERE = os.path.dirname(os.path.abspath(__file__))
MIG = os.path.join(HERE, "..")
GEN = os.path.join(MIG, "02_generate")
BASE = os.path.join(MIG, "01_baseline")
DSN = "192.168.1.25:1521/ORCLU"
oracledb.defaults.fetch_lobs = False
NOW = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

mapping = list(csv.DictReader(open(os.path.join(GEN, "mapping.csv"), encoding="utf-8-sig")))
create = [r for r in mapping if r["ACTION"] == "CREATE"]
tmap = {r["JH_NAME"]: r["VPLUS_NAME"] for r in create if r["KIND"] == "TABLE"}
exp = Counter(r["KIND"] for r in create)
new_names = {r["VPLUS_NAME"] for r in create}
data_tables = [r["JH_TABLE"] for r in csv.DictReader(open(os.path.join(GEN, "20_data_tables.csv"), encoding="utf-8-sig"))]

jc = oracledb.connect(user="JH202610", password=os.environ["DB_PASSWORD"], dsn=DSN).cursor()
vc = oracledb.connect(user="VPLUS202611A", password=os.environ["DB_PASSWORD"], dsn=DSN).cursor()
inlist = lambda xs: ",".join(f"'{x}'" for x in xs)
R, checks = {}, []
def chk(name, actual, expected, ok=None):
    ok = (actual == expected) if ok is None else ok
    checks.append([name, actual, expected, "OK" if ok else "확인 필요"])

# 1) 새 객체 수와 상태
names = sorted(new_names)
objs = []
for i in range(0, len(names), 500):
    objs += vc.execute(f"SELECT object_name, object_type, status FROM user_objects WHERE object_name IN ({inlist(names[i:i+500])}) AND object_type IN ('TABLE','TYPE','FUNCTION','PROCEDURE')").fetchall()
cnt = Counter(t for _, t, _ in objs)
for k, label in (("TABLE", "테이블"), ("TYPE", "TYPE"), ("FUNCTION", "함수"), ("PROCEDURE", "프로시저")):
    chk(f"새 {label} 수", cnt.get(k, 0), exp[k])
inv = sorted(n for n, t, s in objs if s != "VALID")
chk("새 객체 중 INVALID", inv, [])
pkn = [r["VPLUS_NAME"] for r in create if r["KIND"] == "PK"]
idx = vc.execute(f"SELECT index_name, status FROM user_indexes WHERE index_name IN ({inlist(pkn)})").fetchall()
chk("PK 인덱스 수 / UNUSABLE", (len(idx), [n for n, s in idx if s != "VALID"]), (exp["PK"], []))
cons = vc.execute(f"SELECT constraint_name, constraint_type, status, validated FROM user_constraints WHERE constraint_type IN ('P','R') AND table_name IN ({inlist(tmap.values())})").fetchall()
chk("PK 수", sum(1 for c in cons if c[1] == "P"), exp["PK"])
chk("FK 수", sum(1 for c in cons if c[1] == "R"), exp["FK"])
chk("PK·FK 이름이 매핑표와 같음", sorted({c[0] for c in cons} ^ {r["VPLUS_NAME"] for r in create if r["KIND"] in ("PK", "FK")}), [])
chk("ENABLED·VALIDATED 아닌 제약조건", [c[0] for c in cons if c[2] != "ENABLED" or c[3] != "VALIDATED"], [])
errs = vc.execute(f"SELECT COUNT(*) FROM user_errors WHERE name IN ({inlist([n for n,t,_ in objs if t != 'TABLE'])})").fetchone()[0]
chk("새 객체 컴파일 오류(USER_ERRORS)", errs, 0)

# 2) vplus 소스 = 생성 SQL
gen_src = {}
for f in ("50_types.sql", "60_functions.sql", "70_procedures.sql"):
    for b in re.split(r"\n/\n", open(os.path.join(GEN, f), encoding="utf-8").read()):
        m = re.search(r"^-- (\S+) -> (\S+)\n", b, re.M)
        if m: gen_src[m.group(2)] = re.sub(r"^CREATE\s+", "", b[m.end():].strip())
norm = lambda s: re.sub(r"\s+", " ", s).strip()
diff = []
for n, gsrc in gen_src.items():
    vs = "".join(r[0] for r in vc.execute("SELECT text FROM user_source WHERE name=:n ORDER BY type, line", n=n))
    if norm(vs) != norm(gsrc): diff.append(n)
chk("vplus 소스가 생성 SQL과 같음(공백 무시)", (len(gen_src), diff), (exp["TYPE"] + exp["FUNCTION"] + exp["PROCEDURE"], []))

# 3) 데이터
d_bad, z_bad = [], []
for t, nt in tmap.items():
    v = vc.execute(f'SELECT COUNT(*) FROM "{nt}"').fetchone()[0]
    if t in data_tables:
        j = jc.execute(f'SELECT COUNT(*) FROM "{t}"').fetchone()[0]
        if j != v: d_bad.append([t, nt, j, v])
    elif v: z_bad.append([nt, v])
chk("데이터 복사 14개 건수 = JH", d_bad, [])
chk("구조만 만든 94개 건수 = 0", z_bad, [])
R["data_rows_total"] = sum(vc.execute(f'SELECT COUNT(*) FROM "{tmap[t]}"').fetchone()[0] for t in data_tables)

# 4) 0장 원칙: 1단계 기준선과 비교
after = os.path.join(HERE, "after_baseline")
subprocess.run([sys.executable, "-I", os.path.join(BASE, "baseline.py"), after], check=True, capture_output=True,
               env={**os.environ, "PYTHONIOENCODING": "utf-8"})
base_cmp = {}
for f, key in (("vplus_objects.csv", ("OBJECT_NAME", "OBJECT_TYPE")), ("vplus_constraints.csv", ("CONSTRAINT_NAME",)),
               ("vplus_source_hash.csv", ("NAME", "TYPE")), ("vplus_table_counts.csv", ("TABLE_NAME",))):
    b = {tuple(r[k] for k in key): r for r in csv.DictReader(open(os.path.join(BASE, f), encoding="utf-8-sig"))}
    a = {tuple(r[k] for k in key): r for r in csv.DictReader(open(os.path.join(after, f), encoding="utf-8-sig"))}
    added = [k for k in a if k not in b]
    base_cmp[f] = {"baseline": len(b), "changed": [list(k) for k in b if k in a and a[k] != b[k]],
                   "removed": [list(k) for k in b if k not in a], "added": len(added),
                   "added_not_ours": [list(k) for k in added if k[0] not in new_names and (a[k].get("TABLE_NAME") or k[0]) not in new_names]}
    chk(f"기준선 비교 {f}: 바뀜/사라짐/우리 것이 아닌 추가",
        (len(base_cmp[f]["changed"]), len(base_cmp[f]["removed"]), len(base_cmp[f]["added_not_ours"])), (0, 0, 0))
R["baseline_compare"] = base_cmp
binv = sorted(r["OBJECT_NAME"] for r in csv.DictReader(open(os.path.join(BASE, "vplus_objects.csv"), encoding="utf-8-sig")) if r["STATUS"] != "VALID")
ainv = sorted(r["OBJECT_NAME"] for r in csv.DictReader(open(os.path.join(after, "vplus_objects.csv"), encoding="utf-8-sig")) if r["STATUS"] != "VALID")
chk("INVALID 목록(기준선 범위)", ainv, binv)

R["checks"] = checks
json.dump(R, open(os.path.join(HERE, "step6_result.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1, default=str)
with open(os.path.join(HERE, "step6_result.md"), "w", encoding="utf-8") as f:
    f.write(f"# 6단계 최종 검증 결과\n\n> 검증 시각: {NOW} · 조회 전용\n\n| 검사 | 결과 | 기대 | 판정 |\n|---|---|---|---|\n")
    for c in checks: f.write(f"| {c[0]} | {c[1]} | {c[2]} | {c[3]} |\n")
    f.write(f"\n데이터 복사 14개 테이블 합계: {R['data_rows_total']}건\n")
for c in checks: print(c[3], "|", c[0], "|", c[1])
print("ALL OK" if all(c[3] == "OK" for c in checks) else "CHECK NEEDED")
