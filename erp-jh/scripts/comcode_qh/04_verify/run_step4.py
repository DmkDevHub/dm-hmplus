"""공통코드(QS→QH) 4단계: 검증 (조회 전용)
사용: $env:DB_PASSWORD='...'; python -I run_step4.py
"""
import csv, hashlib, json, os, datetime
import oracledb

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.join(HERE, "..", "01_baseline"); GEN = os.path.join(HERE, "..", "02_generate")
DSN = "192.168.1.25:1521/ORCLU"; NOW = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
def conn(u): return oracledb.connect(user=u, password=os.environ["DB_PASSWORD"], dsn=DSN).cursor()
v, j = conn("VPLUS202611A"), conn("JH202610")
cols = [r[0] for r in v.execute("SELECT column_name FROM user_tab_columns WHERE table_name='TCOA_COMCODE' ORDER BY column_id")]
sel = ", ".join(cols)
mp = [r for r in csv.DictReader(open(os.path.join(GEN, "mapping.csv"), encoding="utf-8-sig")) if r["ACTION"] == "INSERT"]
new_keys = {(r["VPLUS_COM_CD"], r["VPLUS_HRNK_CD"]) for r in mp}
checks = []
def chk(n, a, b): checks.append([n, a, b, "OK" if a == b else "확인 필요"])

# 1) 넣은 행 = JH 값(키만 변환)
J = {(r[0], r[1]): r for r in j.execute(f"SELECT {sel} FROM TCOA_COMCODE WHERE HRNK_CD LIKE 'QS%'")}
V = {(r[0], r[1]): r for r in v.execute(f"SELECT {sel} FROM TCOA_COMCODE")}
missing, diff = [], []
for r in mp:
    nk = (r["VPLUS_COM_CD"], r["VPLUS_HRNK_CD"]); src = J[(r["JH_COM_CD"], r["JH_HRNK_CD"])]
    if nk not in V: missing.append(nk); continue
    if list(V[nk][2:]) != list(src[2:]): diff.append(nk)
chk("넣은 행이 vplus에 있음(1,032)", (len(mp) - len(missing), missing[:5]), (1032, []))
chk("넣은 행의 키 말고 33개 컬럼이 JH와 같음", diff[:5], [])

# 2) 행 수
base = json.load(open(os.path.join(BASE, "baseline_summary.json"), encoding="utf-8"))
chk("전체 행 수 = 기준선 + 1,032", len(V), base["vplus"]["total_rows"] + 1032)

# 3) 기존 행 변경 없음 (기준선 해시 비교)
bh = {(r["COM_CD"], r["HRNK_CD"]): r["ROW_HASH"] for r in csv.DictReader(open(os.path.join(BASE, "vplus_comcode_hash.csv"), encoding="utf-8-sig"))}
h = lambda r: hashlib.sha1(json.dumps([None if x is None else str(x) for x in r], ensure_ascii=False).encode("utf-8")).hexdigest()
changed = [k for k in bh if k in V and h(V[k]) != bh[k]]
removed = [k for k in bh if k not in V]
added_other = [k for k in V if k not in bh and k not in new_keys]
chk("기존 행 바뀜 / 사라짐 / 이번 것이 아닌 추가", (len(changed), len(removed), len(added_other)), (0, 0, 0))
chk("기존 QS 행(HRNK_CD QS%) 수", sum(1 for k in V if k[1].startswith("QS")), base["vplus"]["hrnk_qs_rows"])

# 4) 트리 연결
codes = {k[0] for k in V}
chk("QH 행 중 상위코드가 없는 것", sorted({k[1] for k in V if k[1].startswith("QH") and k[1] not in codes}), [])
chk("최상위 QH 아래 코드 그룹 수", sum(1 for k in V if k[1] == "QH"), 86)
chk("바로잡은 행 QH0600101의 상위코드", sorted(k[1] for k in V if k[0] == "QH0600101"), ["QH06001"])

json.dump({"checked_at": NOW, "checks": checks}, open(os.path.join(HERE, "step4_result.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1, default=str)
with open(os.path.join(HERE, "step4_result.md"), "w", encoding="utf-8") as f:
    f.write(f"# 공통코드 4단계 검증 결과\n\n> 검증 시각: {NOW} · 조회 전용\n\n| 검사 | 결과 | 기대 | 판정 |\n|---|---|---|---|\n")
    for c in checks: f.write(f"| {c[0]} | {c[1]} | {c[2]} | {c[3]} |\n")
for c in checks: print(c[3], "|", c[0], "|", c[1])
print("ALL OK" if all(c[3] == "OK" for c in checks) else "CHECK NEEDED")
