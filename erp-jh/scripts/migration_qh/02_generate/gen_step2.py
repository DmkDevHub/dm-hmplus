"""QH 2단계: 매핑표와 SQL 생성 (조회 전용 - JH/vplus 모두 SELECT, DBMS_METADATA만 사용)
이름 규칙(QH_MIGRATION_ROADMAP.md 1장): QSA -> QHA, QSB -> QHB (테이블·프로시저·함수),
                                       FQSZ -> FQHZ, PQSZ -> PQHZ, QSSITE -> QHSITE
소스 수정 1건(승인됨): PQHA_SEND_SMS_Q 의 C.CORP_CD = A.WORK_CORP_CD -> A.CORP_CD
사용: $env:DB_PASSWORD='...'; python -I gen_step2.py <출력 폴더>
"""
import csv, os, re, sys, datetime
from collections import Counter, defaultdict
import oracledb

OUT = sys.argv[1]; os.makedirs(OUT, exist_ok=True)
HERE = os.path.dirname(os.path.abspath(__file__))
DSN = "192.168.1.25:1521/ORCLU"
oracledb.defaults.fetch_lobs = False
NOW = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

DATA_TABLES = ["TQSA_CKLST", "TQSA_CKLST_ITM", "TQSA_CTP", "TQSA_CTPUNT_CHKITM", "TQSA_DEEDU_CD",
               "TQSA_DISASTER_CD", "TQSA_DISASTER_DIV", "TQSA_EDU_CD", "TQSA_MSDS_CD", "TQSA_AREC_CD",
               "TQSA_SAFE_PERM_CD", "TQSA_SAFE_PERM_CPLN", "TQSB_CTPUNT_CHKITM", "TQSA_CTPUNT"]
EXCLUDE_EXPLICIT = {"PQSZ_DATA_CLEAR_W": "결정 3: 데이터 삭제 프로시저 제외"}
EXPECT_OTHER_COPY = {"FQSZ_GET_CORP_NM": "FQHZ_GET_CORP_NM", "FQSZ_SAFT_DEFC_IF": "FQHZ_SAFT_DEFC_IF",
                     "PQSZ_IMPORT_EMPS_S": "PQHZ_IMPORT_EMPS_S", "QSSITEOBJ01": "QHSITEOBJ01", "QSSITETAB01": "QHSITETAB01"}
# 승인된 소스 수정 (결정 9, B안)
SOURCE_FIX = {"PQSA_SEND_SMS_Q": [("LEFT OUTER JOIN THRZ_DEPT C ON C.CORP_CD = A.WORK_CORP_CD",
                                   "LEFT OUTER JOIN THRZ_DEPT C ON C.CORP_CD = A.CORP_CD  -- [이관 수정 2026-11-13] JH: A.WORK_CORP_CD (vplus THRA_BASEINFO에 컬럼 없음)")]}

def trule(n):   # 테이블·제약조건 이름 안의 TQSA->TQHA, TQSB->TQHB (동시 치환)
    return re.sub(r"TQS([AB])", lambda m: "TQH" + m.group(1), n)
def crule(n):   # 코드 객체 이름
    m = re.match(r"^(PQS|FQS)([AB])_", n)
    if m: return m.group(1)[0] + "QH" + m.group(2) + n[4:]
    return EXPECT_OTHER_COPY.get(n)

jh = oracledb.connect(user="JH202610", password=os.environ["DB_PASSWORD"], dsn=DSN); jc = jh.cursor()
vp = oracledb.connect(user="VPLUS202611A", password=os.environ["DB_PASSWORD"], dsn=DSN); vc = vp.cursor()
Q = lambda c, s, **b: c.execute(s, b).fetchall()

# ---------------- 대상 수집 (JH) ----------------
tables = [r[0] for r in Q(jc, "SELECT table_name FROM user_tables WHERE SUBSTR(table_name,1,5) IN ('TQSA_','TQSB_') ORDER BY 1")]
cons = Q(jc, """SELECT table_name, constraint_name, constraint_type, r_constraint_name, delete_rule
                  FROM user_constraints WHERE SUBSTR(table_name,1,5) IN ('TQSA_','TQSB_') AND constraint_type IN ('P','R')""")
ccols = defaultdict(list)
for cn, col, pos in Q(jc, "SELECT constraint_name, column_name, position FROM user_cons_columns WHERE SUBSTR(table_name,1,5) IN ('TQSA_','TQSB_') ORDER BY constraint_name, position"):
    ccols[cn].append(col)
tab_of_cons = {cn: t for t, cn, _, _, _ in cons}
code = Q(jc, """SELECT object_name, object_type FROM user_objects
                 WHERE object_name LIKE '%QS%' AND object_type IN ('PROCEDURE','FUNCTION','TYPE') ORDER BY object_type, object_name""")
v_objs = {r[0] for r in Q(vc, "SELECT object_name FROM user_objects")}
v_names = v_objs | {r[0] for r in Q(vc, "SELECT constraint_name FROM user_constraints")}

# ---------------- 매핑표 ----------------
mapping = []   # kind, jh, vplus, action, note
tmap = {t: trule(t) for t in tables}
for t in tables:
    mapping.append(["TABLE", t, tmap[t], "CREATE", "데이터 복사" if t in DATA_TABLES else "구조만"])
cmap = {}
for t, cn, ty, rcn, _ in sorted(cons, key=lambda x: (x[2], x[1])):
    if ty == "P":
        new = "PK_" + tmap[t]
        note = "PK와 PK 인덱스" + ("" if new == trule(cn) else f" (규칙대로면 {trule(cn)}, 1-2장 정리)")
        mapping.append(["PK", cn, new, "CREATE", note])
    else:
        new = f"FK_{tmap[tab_of_cons[rcn]]}_TO_{tmap[t]}"
        note = f"{tmap[tab_of_cons[rcn]]} -> {tmap[t]}" + ("" if new == trule(cn) else f" (규칙대로면 {trule(cn)}, 1-2장 정리)")
        mapping.append(["FK", cn, new, "CREATE", note])
    cmap[cn] = new

omap, copy_code, excluded = {}, [], []
for n, ty in code:
    if "ZTEST" in n:
        excluded.append([ty, n, "", "EXCLUDE", "결정 2: ZTEST 관련 제외"]); continue
    if n in EXCLUDE_EXPLICIT:
        excluded.append([ty, n, "", "EXCLUDE", EXCLUDE_EXPLICIT[n]]); continue
    if re.match(r"^(PQS|FQS)[AB]_", n):
        new = crule(n); note = "이름 규칙 적용"
    elif n in v_objs:
        excluded.append([ty, n, n, "EXCLUDE", "vplus에 같은 이름이 있음(vplus 것을 그대로 사용)"]); continue
    else:
        new = crule(n); note = "QS -> QH (결정 7)"
        if not new: sys.exit(f"규칙에 없는 복사 대상: {n}")
    omap[n] = new; copy_code.append((n, ty, new))
    mapping.append([ty, n, new, "CREATE", note])
mapping += excluded

SRC_MAP = {**tmap, **omap}          # 소스 치환 = 테이블 + 복사하는 코드 객체
pat = re.compile(r"(?<![A-Za-z0-9_$#])(" + "|".join(sorted(map(re.escape, SRC_MAP), key=len, reverse=True)) + r")(?![A-Za-z0-9_$#])", re.I)
DDL_MAP = {**tmap, **cmap}
qpat = re.compile(r'"(' + "|".join(sorted(map(re.escape, DDL_MAP), key=len, reverse=True)) + r')"')

with open(os.path.join(OUT, "mapping.csv"), "w", newline="", encoding="utf-8-sig") as f:
    w = csv.writer(f); w.writerow(["KIND", "JH_NAME", "VPLUS_NAME", "ACTION", "NOTE"]); w.writerows(mapping)

# ---------------- 테이블 DDL ----------------
jc.execute("""BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SEGMENT_ATTRIBUTES',FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'STORAGE',FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'TABLESPACE',FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'REF_CONSTRAINTS',FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'CONSTRAINTS',TRUE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR',TRUE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'EMIT_SCHEMA',FALSE);
END;""")
tab_sql, stmt_cnt = [], Counter()
for t in tables:
    ddl = jc.execute("SELECT DBMS_METADATA.GET_DDL('TABLE', :t) FROM dual", t=t).fetchone()[0]
    ddl = ddl.replace('"JH202610".', "")
    ddl = qpat.sub(lambda m: '"' + DDL_MAP[m.group(1)] + '"', ddl)
    stmts = [s.strip() for s in re.split(r";\s*(?:\n|$)", ddl) if s.strip()]
    for s in stmts:
        stmt_cnt[s.split()[0] + " " + s.split()[1]] += 1
    tab_sql.append(f"-- {t} -> {tmap[t]}\n" + "".join(s + ";\n" for s in stmts))

# ---------------- FK ----------------
fk_sql = []
for t, cn, ty, rcn, drule in sorted(cons, key=lambda x: cmap[x[1]]):
    if ty != "R": continue
    child, parent = tmap[t], tmap[tab_of_cons[rcn]]
    od = " ON DELETE CASCADE" if drule == "CASCADE" else (" ON DELETE SET NULL" if drule == "SET NULL" else "")
    fk_sql.append(f'-- {cn}\nALTER TABLE "{child}" ADD CONSTRAINT "{cmap[cn]}" FOREIGN KEY ('
                  + ", ".join(f'"{c}"' for c in ccols[cn]) + f') REFERENCES "{parent}" ('
                  + ", ".join(f'"{c}"' for c in ccols[rcn]) + f"){od} ENABLE;\n")

# ---------------- 코멘트 ----------------
esc = lambda s: s.replace("'", "''")
cmt_sql, cmt_cnt = [], Counter()
for t, c in Q(jc, "SELECT table_name, comments FROM user_tab_comments WHERE SUBSTR(table_name,1,5) IN ('TQSA_','TQSB_') AND comments IS NOT NULL ORDER BY 1"):
    cmt_sql.append(f"COMMENT ON TABLE \"{tmap[t]}\" IS '{esc(c)}';\n"); cmt_cnt["table"] += 1
for t, col, c in Q(jc, "SELECT table_name, column_name, comments FROM user_col_comments WHERE SUBSTR(table_name,1,5) IN ('TQSA_','TQSB_') AND comments IS NOT NULL ORDER BY 1, 2"):
    cmt_sql.append(f"COMMENT ON COLUMN \"{tmap[t]}\".\"{col}\" IS '{esc(c)}';\n"); cmt_cnt["column"] += 1

# ---------------- PL/SQL 소스 ----------------
src = defaultdict(list)
for n, ty, line, text in Q(jc, """SELECT name, type, line, text FROM user_source
                                    WHERE type IN ('PROCEDURE','FUNCTION','TYPE') AND name LIKE '%QS%' ORDER BY name, type, line"""):
    src[(n, ty)].append(text)
report, code_sql = [], {"TYPE": [], "FUNCTION": [], "PROCEDURE": []}
known_new = set(SRC_MAP.values())
jh_objs = {r[0] for r in Q(jc, "SELECT object_name FROM user_objects")}
residual_all = Counter()
fix_done = Counter()
orig_tok_total = repl_total = 0
def zones(body):
    out=[];i=0;n=len(body);mode='code'
    while i<n:
        c=body[i];two=body[i:i+2]
        if mode=='code':
            if two=='--': mode='line'
            elif two=='/*': mode='block'
            elif c=="'": mode='str'
        elif mode=='line' and c=='\n': mode='code'
        elif mode=='block' and two=='*/': out+=['block','block'];i+=2;mode='code';continue
        elif mode=='str' and c=="'":
            if body[i+1:i+2]=="'": out+=['str','str'];i+=2;continue
            out.append('str');i+=1;mode='code';continue
        out.append(mode);i+=1
    return out
ZN={'line':'주석(--)','block':'주석(/* */)','str':'문자열','code':'코드'}
TOK = r"(?<![A-Za-z0-9_$#])[A-Za-z]Q[SH][A-Za-z]_[A-Za-z0-9_$#]+|(?<![A-Za-z0-9_$#])Q[SH]SITE[A-Za-z0-9_$#]+"
for n, ty, new in copy_code:
    body = "".join(src[(n, ty)])
    orig_tok_total += sum(1 for _ in pat.finditer(body))
    hits = Counter()
    def sub(m):
        k = m.group(1).upper(); hits[f"{k}->{SRC_MAP[k]}"] += 1; return SRC_MAP[k]
    nb = pat.sub(sub, body)
    repl_total += sum(hits.values())
    for old, fixed in SOURCE_FIX.get(n, []):
        if nb.count(old) != 1: sys.exit(f"소스 수정 위치를 찾지 못함: {n}")
        nb = nb.replace(old, fixed); fix_done[n] += 1
    if not re.match(r"\s*(PROCEDURE|FUNCTION|TYPE)\s+\"?" + re.escape(new) + r"\b", nb, re.I):
        sys.exit(f"header check failed: {n}")
    resid = {}
    zz = zones(nb)
    found = defaultdict(set)
    for mm in re.finditer(TOK, nb):
        found[mm.group(0).upper()].add(ZN[zz[mm.start()]])
    ctes = {x.upper() for x in re.findall(r"(?:\bWITH|,)\s+([A-Za-z0-9_$#]+)\s+AS\s*\(", nb, re.I)}
    for tok, where in found.items():
        if tok in known_new: continue
        where = "/".join(sorted(where))
        if tok in ctes: why = "WITH 절 이름(객체 아님)"
        elif where.startswith("주석") and "코드" not in where: why = "주석 안의 이름(실행과 무관)"
        elif tok in v_objs: why = "vplus 기존 객체를 그대로 사용"
        elif tok in jh_objs: why = "JH에 있으나 이관 대상 아님"
        else: why = "JH·vplus 어디에도 없는 이름"
        resid[tok] = f"{why} [{where}]"
    for k, v in resid.items(): residual_all[(k, v)] += 1
    report.append((ty, n, new, len(src[(n, ty)]), hits, resid, nb))
    code_sql[ty].append(f"-- {n} -> {new}\nCREATE " + nb.rstrip() + "\n/\n")

code_sql["TYPE"].sort(key=lambda s: 0 if "QHSITEOBJ01" in s.split("\n")[0] else 1)   # OBJ 다음 TAB

def write(name, header, parts):
    with open(os.path.join(OUT, name), "w", encoding="utf-8", newline="\n") as f:
        f.write(f"-- {header}\n-- 생성: {NOW} (QH 2단계, 검토용 - 아직 실행하지 않음)\n-- 대상 스키마: VPLUS202611A\n\n")
        f.write("\n".join(parts))

write("10_tables.sql", f"테이블 {len(tables)}개 (PK·NOT NULL·DEFAULT 포함, FK 제외)", tab_sql)
write("30_fk.sql", f"FK {len(fk_sql)}개", fk_sql)
write("40_comments.sql", f"코멘트 (테이블 {cmt_cnt['table']}, 컬럼 {cmt_cnt['column']})", cmt_sql)
write("50_types.sql", f"TYPE {len(code_sql['TYPE'])}개", code_sql["TYPE"])
write("60_functions.sql", f"함수 {len(code_sql['FUNCTION'])}개", code_sql["FUNCTION"])
write("70_procedures.sql", f"프로시저 {len(code_sql['PROCEDURE'])}개", code_sql["PROCEDURE"])

jcnt = {t: jc.execute(f'SELECT COUNT(*) FROM "{t}"').fetchone()[0] for t in DATA_TABLES}
with open(os.path.join(OUT, "20_data_tables.csv"), "w", newline="", encoding="utf-8-sig") as f:
    w = csv.writer(f); w.writerow(["JH_TABLE", "VPLUS_TABLE", "JH_ROWS"])
    for t in DATA_TABLES: w.writerow([t, tmap[t], jcnt[t]])

# ---------------- 되돌리기 ----------------
rb = ["-- 이번에 만든 객체만 지운다. vplus 기존 객체는 포함하지 않는다.\n"]
for ty in ("PROCEDURE", "FUNCTION"):
    for n, t2, new in reversed(copy_code):
        if t2 == ty: rb.append(f'DROP {ty} "{new}";')
rb += ['DROP TYPE "QHSITETAB01";', 'DROP TYPE "QHSITEOBJ01";']
rb += [f'DROP TABLE "{tmap[t]}" CASCADE CONSTRAINTS PURGE;' for t in reversed(tables)]
write("99_rollback.sql", "되돌리기 (생성 역순)", ["\n".join(rb) + "\n"])

# ---------------- 검증 ----------------
all_sql = "".join(open(os.path.join(OUT, f), encoding="utf-8").read() for f in os.listdir(OUT) if f.endswith(".sql") and f != "99_rollback.sql")
new_names = list(tmap.values()) + list(cmap.values()) + [x[2] for x in copy_code]
newset = set(tmap.values()) | set(cmap.values())
ddl_txt = "".join(tab_sql + fk_sql)
code_txt = "".join(r[6] for r in report)
# 1차(QS) 이름 중 JH 원본도 vplus 기존도 아닌 것 = 섞이면 안 되는 이름
first = {r["VPLUS_NAME"] for r in csv.DictReader(open(os.path.join(HERE, "..", "..", "migration", "02_generate", "mapping.csv"), encoding="utf-8-sig")) if r["ACTION"] == "CREATE"}
first_only = first - jh_objs - v_objs - set(cmap)
code_tokens = Counter(t.upper() for t in re.findall(r"[A-Za-z0-9_$#]+", code_txt))
ddl_tokens = set(re.findall(r'"([A-Z0-9_$#]+)"', ddl_txt))
checks = {
    "테이블 수": (len(tables), 108),
    "PK 수": (sum(1 for c in cons if c[2] == "P"), 95),
    "FK 수": (len(fk_sql), 31),
    "TYPE 수": (len(code_sql["TYPE"]), 2),
    "함수 수": (len(code_sql["FUNCTION"]), 12),
    "프로시저 수": (len(code_sql["PROCEDURE"]), 275),
    "QS→QH로 바꾸는 그 밖의 복사 대상(결정 7)": (sorted((n, new) for n, _, new in copy_code if n in EXPECT_OTHER_COPY), sorted(EXPECT_OTHER_COPY.items())),
    "새 이름 중복": (len(new_names) - len(set(new_names)), 0),
    "vplus 기존 이름과 충돌": (sorted(n for n in new_names if n in v_names), []),
    "'CREATE OR REPLACE' 사용": (len(re.findall(r"CREATE\s+OR\s+REPLACE", all_sql, re.I)), 0),
    "'JH202610' 포함": (all_sql.upper().count("JH202610"), 0),
    "TABLESPACE/STORAGE 절": (len(re.findall(r"\b(TABLESPACE|STORAGE\s*\()", all_sql, re.I)), 0),
    "DDL(10/30) 안 QS 이름": (sorted(x for x in ddl_tokens if "QS" in x), []),
    "DDL(10/30) 안 QH 이름이 모두 매핑표의 새 이름": (sorted(x for x in ddl_tokens if "QH" in x and x not in newset), []),
    "소스에 남은 바꿔야 할 JH 이름(코드 기준, 주석 제외)": (sorted(k for (k, v), _ in residual_all.items() if k in SRC_MAP and "[코드" in v), []),
    "소스에 섞인 1차(QS) 이름": (sorted(t for t in code_tokens if t in first_only), []),
    "원본 이름 수 = 바꾼 이름 수": (orig_tok_total, repl_total),
    "소스 수정(SEND_SMS_Q) 적용": (dict(fix_done), {"PQSA_SEND_SMS_Q": 1}),
}
checks["문장 종류(10_tables)"] = (dict(stmt_cnt), "CREATE TABLE 108, CREATE UNIQUE 95, ALTER TABLE 95")

with open(os.path.join(OUT, "80_replace_report.md"), "w", encoding="utf-8") as f:
    f.write(f"# QH 2단계 치환 검증 리포트\n\n> 생성: {NOW} · 조회 전용으로 생성했다. vplus에는 아무것도 실행하지 않았다.\n\n")
    f.write(f"원본 소스의 이름 {orig_tok_total}곳을 바꿨다(테이블 {len(tmap)}개, 코드 객체 {len(omap)}개 매핑).\n\n")
    f.write("## 1. 자동 검사\n\n| 검사 | 결과 | 기대 | 판정 |\n|---|---|---|---|\n")
    for k, (a, b) in checks.items():
        ok = "참고" if k.startswith("문장 종류") else ("OK" if a == b else "**확인 필요**")
        f.write(f"| {k} | {a} | {b} | {ok} |\n")
    f.write("\n## 2. 소스에 남은 QS 이름과 사유\n\n바꾼 소스에 남은 QS 계열 이름 전체다(새 QH 이름 제외).\n\n")
    if residual_all:
        f.write("| 이름 | 사유 [위치] | 나오는 객체 수 |\n|---|---|---:|\n")
        for (k, v), c in sorted(residual_all.items()): f.write(f"| `{k}` | {v} | {c} |\n")
    else:
        f.write("없음\n")
    f.write("\n## 3. 소스 수정\n\n- `PQHA_SEND_SMS_Q`(JH `PQSA_SEND_SMS_Q`): `C.CORP_CD = A.WORK_CORP_CD` → `C.CORP_CD = A.CORP_CD` (결정 9, B안)\n")
    f.write("\n## 4. 객체별 치환 내역\n\n| 종류 | JH | vplus | 줄 수 | 바꾼 이름(횟수) | 남은 이름 |\n|---|---|---|---:|---|---|\n")
    for ty, n, new, ln, hits, resid, _ in report:
        h = ", ".join(f"`{k}`({v})" for k, v in sorted(hits.items()))
        r = ", ".join(f"`{k}`" for k in sorted(resid)) or "-"
        f.write(f"| {ty} | `{n}` | `{new}` | {ln} | {h} | {r} |\n")

for k, (a, b) in checks.items():
    print(("OK  " if a == b else "CHK ") + k, "" if a == b else a)
print("residual", len(residual_all))
print("files", sorted(os.listdir(OUT)))
