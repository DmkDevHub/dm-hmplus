"""QH 코드 값 변경 2단계: 변경 SQL 생성 (조회 전용, JH 접속 안 함)
입력(읽기만): migration_qh/02_generate/60_functions.sql, 70_procedures.sql, mapping.csv
             qh_code_literal/01_baseline/orig_sources.sql, data_*.csv
규칙(QH_CODE_LITERAL_ROADMAP.md 1장) - 코드 영역의 문자열 리터럴만 본다. 주석·식별자는 건드리지 않는다.
  A: 리터럴 값 전체가 QS 공통코드(47종)이면 QS -> QH
  B: 오류 메시지 리터럴 안의 코드 표기(QS005, QS026, QS035, QS09002, QSZ03, QSZ0310) QS -> QH
  C: USR_KND = 'QS' -> 'QH'
  그 밖에 QS가 들어간 리터럴이 있으면 오류로 멈춘다.
사용: $env:DB_PASSWORD='...'; python -I gen_step2.py
"""
import csv, os, re, sys, datetime
from collections import Counter, defaultdict
import oracledb

HERE = os.path.dirname(os.path.abspath(__file__))
QHGEN = os.path.join(HERE, "..", "..", "migration_qh", "02_generate")
BASE = os.path.join(HERE, "..", "01_baseline")
NOW = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
MSG_TOKENS = {"QS005", "QS026", "QS035", "QS09002", "QSZ03", "QSZ0310"}
EXPECT = {"objects": 93, "A": 218, "A_kinds": 47, "B": 25, "B_kinds": 7, "C": 3, "TQHA_CKLST": 118, "TQHA_CKLST_ITM": 395}

v = oracledb.connect(user="VPLUS202611A", password=os.environ["DB_PASSWORD"], dsn="192.168.1.25:1521/ORCLU").cursor()
comcodes = {r[0] for r in v.execute("SELECT COM_CD FROM TCOA_COMCODE")} | {r[0] for r in v.execute("SELECT DISTINCT HRNK_CD FROM TCOA_COMCODE")}
qh_names = {r["VPLUS_NAME"] for r in csv.DictReader(open(os.path.join(QHGEN, "mapping.csv"), encoding="utf-8-sig")) if r["ACTION"] == "CREATE"}

def blocks(fname):
    out = []
    for b in re.split(r"\n/\n", open(os.path.join(QHGEN, fname), encoding="utf-8").read()):
        m = re.search(r"^-- (\S+) -> (\S+)\n", b, re.M)
        if m: out.append((m.group(2), b[m.end():].strip()))   # (vplus 이름, "CREATE ..." 전체)
    return out
src = dict(blocks("60_functions.sql") + blocks("70_procedures.sql"))

def zones(b):   # 글자마다 code / line / block / str / strq(따옴표)
    out = []; i = 0; n = len(b); m = "code"
    while i < n:
        c = b[i]; t = b[i:i + 2]
        if m == "code":
            if t == "--": m = "line"
            elif t == "/*": m = "block"
            elif c == "'": m = "str"; out.append("strq"); i += 1; continue
        elif m == "line" and c == "\n": m = "code"
        elif m == "block" and t == "*/": out += ["block", "block"]; i += 2; m = "code"; continue
        elif m == "str" and c == "'":
            if b[i + 1:i + 2] == "'": out += ["str", "str"]; i += 2; continue
            out.append("strq"); i += 1; m = "code"; continue
        out.append(m); i += 1
    return out

def literals(b):   # 코드 영역의 문자열 리터럴 (시작, 끝, 내용)
    z = zones(b)
    for mm in re.finditer(r"'((?:[^']|'')*)'", b):
        if z[mm.start()] == "strq": yield mm.start(), mm.end(), mm.group(1)

# 1) A의 코드 종류: 리터럴 값 전체가 QS 코드인 것
a_kinds = sorted({s for b in src.values() for _, _, s in literals(b) if re.fullmatch(r"QS[0-9A-Z]+", s) and s != "QS"})
missing_qh = [s for s in a_kinds + sorted(MSG_TOKENS) if "QH" + s[2:] not in comcodes]

# 2) 변환
new_src, cnt, kinds, unexpected, changes = {}, Counter(), defaultdict(set), [], defaultdict(list)
for name, body in src.items():
    out = []; last = 0
    for s0, s1, s in literals(body):
        if "QS" not in s.upper(): continue
        line = body[:s0].count("\n") + 1
        pre = body[max(0, s0 - 40):s0]
        if s in a_kinds:
            ns = "QH" + s[2:]; cnt["A"] += 1; kinds["A"].add(s)
        elif s == "QS" and re.search(r"USR_KND\s*=\s*$", pre):
            ns = "QH"; cnt["C"] += 1
        elif re.search(r"(?<![0-9A-Z])QS[0-9A-Z]+", s) and all(t in MSG_TOKENS for t in re.findall(r"(?<![0-9A-Z])QS[0-9A-Z]+", s)):
            ns = re.sub(r"(?<![0-9A-Z])QS(?=[0-9A-Z]+)", "QH", s); cnt["B"] += 1; kinds["B"].add(s)
        else:
            unexpected.append((name, line, s)); continue
        out.append(body[last:s0]); out.append("'" + ns + "'"); last = s1
        changes[name].append((line, s, ns))
    if changes.get(name):
        out.append(body[last:]); new_src[name] = "".join(out)
if unexpected: sys.exit(f"규칙에 없는 QS 문자열: {unexpected[:10]}")

# 3) 파일 쓰기
os.makedirs(HERE, exist_ok=True)
hdr = f"-- 생성: {NOW} (QH 코드 값 변경 2단계, 검토용 - 아직 실행하지 않음)\n-- 대상 스키마: VPLUS202611A\n"
with open(os.path.join(HERE, "10_recreate.sql"), "w", encoding="utf-8", newline="\n") as f:
    f.write(f"-- QH 프로시저 {len(new_src)}개 다시 만들기 (DROP -> CREATE)\n" + hdr + "\n")
    for n in sorted(new_src):
        ty = re.match(r"CREATE\s+(PROCEDURE|FUNCTION)", new_src[n]).group(1)
        f.write(f"-- {n}\nDROP {ty} \"{n}\";\n{new_src[n].rstrip()}\n/\n\n")
orig = {}
for b in re.split(r"\n/\n", open(os.path.join(BASE, "orig_sources.sql"), encoding="utf-8").read()):
    m = re.search(r"^-- (\S+) \((\w+), \w+\)\n", b, re.M)
    if m: orig[m.group(1)] = (m.group(2), b[m.end():].strip())
with open(os.path.join(HERE, "99_rollback_objects.sql"), "w", encoding="utf-8", newline="\n") as f:
    f.write(f"-- 되돌리기: {len(new_src)}개를 1단계에서 저장한 원래 소스로 다시 만든다\n" + hdr + "\n")
    for n in sorted(new_src):
        ty, body = orig[n]
        f.write(f"-- {n}\nDROP {ty} \"{n}\";\n{body.rstrip()}\n/\n\n")

data_sql = {
    "TQHA_CKLST": "UPDATE TQHA_CKLST SET COM_CD = 'QH' || SUBSTR(COM_CD, 3), HO_CHK_DIV_CD2 = 'QH' || SUBSTR(HO_CHK_DIV_CD2, 3) WHERE COM_CD LIKE 'QS%' AND HO_CHK_DIV_CD2 LIKE 'QS%'",
    "TQHA_CKLST_ITM": "UPDATE TQHA_CKLST_ITM SET COM_CD = 'QH' || SUBSTR(COM_CD, 3), HO_CHK_DIV_CD2 = 'QH' || SUBSTR(HO_CHK_DIV_CD2, 3) WHERE COM_CD LIKE 'QS%' AND HO_CHK_DIV_CD2 LIKE 'QS%'"}
with open(os.path.join(HERE, "20_data_update.sql"), "w", encoding="utf-8", newline="\n") as f:
    f.write("-- TQHA_CKLST, TQHA_CKLST_ITM 코드 값 QS -> QH (한 트랜잭션, 행 수가 다르면 롤백)\n" + hdr + "\n")
    for t, s in data_sql.items(): f.write(f"-- 기대 행 수: {EXPECT[t]}\n{s};\n")
with open(os.path.join(HERE, "98_rollback_data.sql"), "w", encoding="utf-8", newline="\n") as f:
    f.write("-- 되돌리기: 코드 값 QH -> QS\n" + hdr + "\n")
    for t in data_sql:
        f.write(f"UPDATE {t} SET COM_CD = 'QS' || SUBSTR(COM_CD, 3), HO_CHK_DIV_CD2 = 'QS' || SUBSTR(HO_CHK_DIV_CD2, 3) WHERE COM_CD LIKE 'QH%' AND HO_CHK_DIV_CD2 LIKE 'QH%';\n")
    f.write("COMMIT;\n")

# 4) 검사
strip_lit = lambda b: re.sub(r"'(?:[^']|'')*'", "''", b)
def strip_code_lits(b):
    z = zones(b); out = []; last = 0
    for s0, s1, _ in literals(b): out.append(b[last:s0]); out.append("''"); last = s1
    out.append(b[last:]); return "".join(out)
other_diff = [n for n in new_src if strip_code_lits(new_src[n]) != strip_code_lits(src[n])]
left_qs = [(n, s) for n, b in new_src.items() for _, _, s in literals(b) if "QS" in s.upper()]
bad_codes = sorted({ns for n in changes for _, s, ns in changes[n] if re.fullmatch(r"QH[0-9A-Z]+", ns) and ns != "QH" and ns not in comcodes})
data_chk = {}
for t, keycols in (("TQHA_CKLST", ["COM_CD", "HO_CHK_DIV_CD2", "HO_CHK_DIV_CD"]), ("TQHA_CKLST_ITM", ["COM_CD", "HO_CHK_DIV_CD2", "HO_CHK_DIV_CD", "HO_CHK_ITM_CD"])):
    rows = list(csv.DictReader(open(os.path.join(BASE, f"data_{t}.csv"), encoding="utf-8-sig")))
    conv = lambda x: "QH" + x[2:] if x.startswith("QS") else x
    newkeys = [tuple(conv(r[c]) if c in ("COM_CD", "HO_CHK_DIV_CD2") else r[c] for c in keycols) for r in rows]
    data_chk[t] = {"rows": len(rows), "dup_new_keys": len(newkeys) - len(set(newkeys)),
                   "clash_with_old": len(set(newkeys) & {tuple(r[c] for c in keycols) for r in rows}),
                   "codes_missing": sorted({conv(r[c]) for r in rows for c in ("COM_CD", "HO_CHK_DIV_CD2") if conv(r[c]) not in comcodes}),
                   "not_qs": sum(1 for r in rows if not (r["COM_CD"].startswith("QS") and r["HO_CHK_DIV_CD2"].startswith("QS")))}
rec = open(os.path.join(HERE, "10_recreate.sql"), encoding="utf-8").read()
drops = re.findall(r'^DROP (PROCEDURE|FUNCTION) "([^"]+)";', rec, re.M)
checks = [
    ("바뀐 객체 수", len(new_src), EXPECT["objects"]),
    ("바뀐 객체가 모두 QH 매핑표의 새 객체(PQH*/FQH*)", sorted(n for n in new_src if n not in qh_names or not n.startswith(("PQH", "FQH"))), []),
    ("A 공통코드 값: 곳 / 종류", (cnt["A"], len(kinds["A"])), (EXPECT["A"], EXPECT["A_kinds"])),
    ("B 오류 메시지: 곳 / 문구 종류", (cnt["B"], len(kinds["B"])), (EXPECT["B"], EXPECT["B_kinds"])),
    ("C USR_KND = 'QS': 곳", cnt["C"], EXPECT["C"]),
    ("A·B 코드의 QH 공통코드가 없는 것", missing_qh, []),
    ("바꾼 코드 값 중 공통코드에 없는 것", bad_codes, []),
    ("문자열 말고 바뀐 곳이 있는 객체(주석·식별자·로직 그대로인지)", other_diff, []),
    ("바꾼 소스의 코드 영역에 남은 QS 문자열", left_qs[:5], []),
    ("규칙에 없는 QS 문자열", unexpected, []),
    ("'CREATE OR REPLACE'", len(re.findall(r"CREATE\s+OR\s+REPLACE", rec, re.I)), 0),
    ("DROP 대상이 바뀐 객체와 같음", sorted(n for _, n in drops) == sorted(new_src), True),
    ("되돌리기 원본이 모두 있음", sorted(n for n in new_src if n not in orig), []),
    ("데이터 TQHA_CKLST", data_chk["TQHA_CKLST"], {"rows": 118, "dup_new_keys": 0, "clash_with_old": 0, "codes_missing": [], "not_qs": 0}),
    ("데이터 TQHA_CKLST_ITM", data_chk["TQHA_CKLST_ITM"], {"rows": 395, "dup_new_keys": 0, "clash_with_old": 0, "codes_missing": [], "not_qs": 0}),
]
deps = [r[0] for r in v.execute("SELECT DISTINCT name FROM user_dependencies WHERE referenced_name IN ({}) AND name NOT IN ({})".format(
    ",".join(f"'{n}'" for n in new_src), ",".join(f"'{n}'" for n in new_src)))]
with open(os.path.join(HERE, "recompile_dependents.txt"), "w", encoding="utf-8") as f: f.write("\n".join(sorted(deps)) + "\n")

with open(os.path.join(HERE, "80_diff_report.md"), "w", encoding="utf-8") as f:
    f.write(f"# QH 코드 값 변경 2단계 리포트\n\n> 생성: {NOW} · 조회 전용. vplus에는 아무것도 실행하지 않았다.\n\n## 1. 자동 검사\n\n| 검사 | 결과 | 기대 | 판정 |\n|---|---|---|---|\n")
    for n, a, b in checks: f.write(f"| {n} | {a} | {b} | {'OK' if a == b else '**확인 필요**'} |\n")
    f.write(f"\n다시 컴파일할 호출 객체(소스는 그대로): {', '.join('`'+d+'`' for d in sorted(deps)) or '없음'}\n")
    f.write(f"\n## 2. 객체별 변경 내역 ({len(new_src)}개)\n\n줄 번호는 `CREATE` 줄을 1로 센 것이다.\n")
    for n in sorted(new_src):
        f.write(f"\n### {n} ({len(changes[n])}곳)\n\n| 줄 | 바꾸기 전 | 바꾼 뒤 |\n|---:|---|---|\n")
        for line, s, ns in changes[n]: f.write(f"| {line} | `'{s}'` | `'{ns}'` |\n")
for n, a, b in checks: print("OK " if a == b else "CHK", n, "" if a == b else a)
print("deps", deps)
