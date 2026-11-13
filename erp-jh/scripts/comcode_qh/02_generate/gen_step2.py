"""공통코드(QS→QH) 2단계: 매핑표·INSERT·되돌리기 SQL 생성 (조회 전용)
규칙(QS_COMCODE_COPY_PLAN.md 3장): HRNK_CD/COM_CD 맨 앞의 QS -> QH, 나머지 컬럼은 JH 값 그대로
상위코드 바로잡기: QS0600101/QS0601 -> QH0600101/QH06001 (결정 1, JH 상위코드 입력 오류)
사용: $env:DB_PASSWORD='...'; python -I gen_step2.py <출력 폴더>
"""
import csv, datetime, decimal, os, re, sys
import oracledb

OUT = sys.argv[1]; os.makedirs(OUT, exist_ok=True)
DSN = "192.168.1.25:1521/ORCLU"
NOW = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
EXCLUDE = {}
PARENT_FIX = {("QS0600101", "QS0601"): ("QH0600101", "QH06001", "결정 1: 상위코드 QS0601은 없는 코드(QS06001 입력 오류)라 QH06001로 바로잡음")}
KEYCOLS = ("COM_CD", "HRNK_CD")

def conn(u): return oracledb.connect(user=u, password=os.environ["DB_PASSWORD"], dsn=DSN).cursor()
v, j = conn("VPLUS202611A"), conn("JH202610")
meta = v.execute("SELECT column_name, data_type FROM user_tab_columns WHERE table_name='TCOA_COMCODE' ORDER BY column_id").fetchall()
jmeta = j.execute("SELECT column_name, data_type FROM user_tab_columns WHERE table_name='TCOA_COMCODE' ORDER BY column_id").fetchall()
if meta != jmeta: sys.exit("JH와 vplus의 TCOA_COMCODE 컬럼이 다름")
cols = [c for c, _ in meta]; types = dict(meta)
rows = j.execute(f"SELECT {', '.join(cols)} FROM TCOA_COMCODE WHERE HRNK_CD LIKE 'QS%' ORDER BY HRNK_CD, COM_CD").fetchall()
conv = lambda s: "QH" + s[2:] if s.startswith("QS") else s

vkeys = {tuple(r) for r in v.execute("SELECT COM_CD, HRNK_CD FROM TCOA_COMCODE")}
vcodes = {c for c, _ in vkeys}

def lit(val, typ):
    if val is None: return "NULL"
    if typ == "DATE": return f"TO_DATE('{val:%Y-%m-%d %H:%M:%S}','YYYY-MM-DD HH24:MI:SS')"
    if typ == "NUMBER":
        if not isinstance(val, (int, float, decimal.Decimal)): sys.exit(f"숫자가 아님 {val}")
        return repr(val) if isinstance(val, int) else format(decimal.Decimal(str(val)), "f")
    return "'" + str(val).replace("'", "''") + "'"

mapping, ins, rb, ins_keys = [], [], [], []
for r in rows:
    k = (r[0], r[1]); nk = (conv(r[0]), conv(r[1])); note = ""
    if k in EXCLUDE:
        mapping.append([*k, *nk, "EXCLUDE", EXCLUDE[k]]); continue
    if k in PARENT_FIX:
        nk = PARENT_FIX[k][:2]; note = PARENT_FIX[k][2]
    mapping.append([*k, *nk, "INSERT", note])
    vals = list(r); vals[0], vals[1] = nk
    ins.append(f"INSERT INTO TCOA_COMCODE ({', '.join(cols)}) VALUES ({', '.join(lit(x, types[c]) for c, x in zip(cols, vals))});")
    rb.append(f"DELETE FROM TCOA_COMCODE WHERE COM_CD = '{nk[0]}' AND HRNK_CD = '{nk[1]}';")
    ins_keys.append(nk)

with open(os.path.join(OUT, "mapping.csv"), "w", newline="", encoding="utf-8-sig") as f:
    w = csv.writer(f); w.writerow(["JH_COM_CD", "JH_HRNK_CD", "VPLUS_COM_CD", "VPLUS_HRNK_CD", "ACTION", "NOTE"]); w.writerows(mapping)
hdr = f"-- 생성: {NOW} (공통코드 2단계, 검토용 - 아직 실행하지 않음)\n-- 대상: VPLUS202611A.TCOA_COMCODE\n"
with open(os.path.join(OUT, "10_insert.sql"), "w", encoding="utf-8", newline="\n") as f:
    f.write(f"-- 공통코드 INSERT {len(ins)}행 (JH HRNK_CD LIKE 'QS%' -> QH, 덮어쓰지 않음: INSERT만 사용)\n" + hdr + "\n")
    f.write("\n".join(ins) + "\n")
with open(os.path.join(OUT, "99_rollback.sql"), "w", encoding="utf-8", newline="\n") as f:
    f.write(f"-- 되돌리기: 이번에 넣은 키 {len(rb)}개만 지운다. 기존 행은 포함하지 않는다.\n" + hdr + "\n")
    f.write("\n".join(rb) + "\nCOMMIT;\n")

# ---------------- 검사 ----------------
txt = open(os.path.join(OUT, "10_insert.sql"), encoding="utf-8").read()
stmts = [s for s in txt.split("\n") if s and not s.startswith("--")]
parents_missing = sorted({h for _, h in ins_keys if h not in vcodes and h not in {c for c, _ in ins_keys}})
multi_line_vals = [(r[0], r[1], c) for r in rows for c, x in zip(cols, r) if isinstance(x, str) and ("\n" in x or "\r" in x)]
checks = [
    ("JH 원본 행 수", len(rows), 1032),
    ("INSERT 문 수", len(stmts), 1032),
    ("INSERT 대상 키 수(중복 제거)", len(set(ins_keys)), 1032),
    ("제외 행", [m[:2] for m in mapping if m[4] == "EXCLUDE"], []),
    ("상위코드를 바로잡은 행", [m[:4] for m in mapping if m[5].startswith("결정 1")], [["QS0600101", "QS0601", "QH0600101", "QH06001"]]),
    ("vplus에 이미 있는 키(있으면 3단계에서 오류로 멈춤)", sorted(set(ins_keys) & vkeys), []),
    ("상위코드가 없는 키", parents_missing, []),
    ("바꾼 키에 남은 QS 접두어", sorted(k for k in ins_keys if k[0].startswith("QS") or k[1].startswith("QS")), []),
    ("HRNK_CD가 QH로 시작하지 않는 키", sorted(k for k in ins_keys if not k[1].startswith("QH")), []),
    ("INSERT 말고 다른 문장(MERGE/UPDATE/DELETE 등)", [s[:40] for s in stmts if not s.startswith("INSERT INTO TCOA_COMCODE (")], []),
    ("가장 긴 키 길이(컬럼 20자)", max(len(x) for k in ins_keys for x in k) <= 20, True),
    ("줄바꿈이 들어간 값(한 줄 한 문장 가정 확인)", multi_line_vals, []),
    ("되돌리기 DELETE 수", len(rb), 1032),
]
with open(os.path.join(OUT, "80_check_report.md"), "w", encoding="utf-8") as f:
    f.write(f"# 공통코드 2단계 검사 리포트\n\n> 생성: {NOW} · 조회 전용. vplus에는 아무것도 실행하지 않았다.\n\n")
    f.write("| 검사 | 결과 | 기대 | 판정 |\n|---|---|---|---|\n")
    for n, a, b in checks: f.write(f"| {n} | {a} | {b} | {'OK' if a == b else '**확인 필요**'} |\n")
    f.write(f"\n- 키 변환: `COM_CD`가 QS로 시작하는 행 {sum(1 for m in mapping if m[4]=='INSERT' and m[0].startswith('QS'))}개, 그대로인 행 {sum(1 for m in mapping if m[4]=='INSERT' and not m[0].startswith('QS'))}개\n")
    f.write(f"- 최상위(`HRNK_CD='QH'`)에 붙는 코드 그룹: {sum(1 for k in ins_keys if k[1]=='QH')}개\n")
for n, a, b in checks: print("OK " if a == b else "CHK", n, "" if a == b else a)
