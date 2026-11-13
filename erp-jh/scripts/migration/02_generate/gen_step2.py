"""2단계: 매핑표와 SQL 생성 (조회 전용 - JH/vplus 모두 SELECT, DBMS_METADATA만 사용)
사용: python -I gen_step2.py <출력 폴더>
"""
import csv, os, re, sys, datetime
from collections import Counter, defaultdict
import oracledb

OUT = sys.argv[1]; os.makedirs(OUT, exist_ok=True)
DSN = "192.168.1.25:1521/ORCLU"
oracledb.defaults.fetch_lobs = False
NOW = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

DATA_TABLES = ["TQSA_CKLST", "TQSA_CKLST_ITM", "TQSA_CTP", "TQSA_CTPUNT_CHKITM", "TQSA_DEEDU_CD",
               "TQSA_DISASTER_CD", "TQSA_DISASTER_DIV", "TQSA_EDU_CD", "TQSA_MSDS_CD", "TQSA_AREC_CD",
               "TQSA_SAFE_PERM_CD", "TQSA_SAFE_PERM_CPLN", "TQSB_CTPUNT_CHKITM", "TQSA_CTPUNT"]
EXCLUDE_EXPLICIT = {"PQSZ_DATA_CLEAR_W": "사용자 결정 3: 데이터 삭제 프로시저 제외"}
EXPECT_SAME_NAME_COPY = {"FQSZ_GET_CORP_NM", "FQSZ_SAFT_DEFC_IF", "PQSZ_IMPORT_EMPS_S", "QSSITEOBJ01", "QSSITETAB01"}

def rule(n):  # TQSA->TQSB, TQSB->TQSC 동시 치환 (이름 안의 접두어)
    return re.sub(r"TQS[AB]", lambda m: "TQSB" if m.group(0) == "TQSA" else "TQSC", n)

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
pk_of = {t: cn for t, cn, ty, _, _ in cons if ty == "P"}
tab_of_cons = {cn: t for t, cn, _, _, _ in cons}
code = Q(jc, """SELECT object_name, object_type FROM user_objects
                 WHERE object_name LIKE '%QS%' AND object_type IN ('PROCEDURE','FUNCTION','TYPE') ORDER BY object_type, object_name""")
v_names = {r[0] for r in Q(vc, "SELECT object_name FROM user_objects")} | {r[0] for r in Q(vc, "SELECT constraint_name FROM user_constraints")}
v_objs = {r[0] for r in Q(vc, "SELECT object_name FROM user_objects")}

# ---------------- 매핑표 ----------------
mapping = []   # kind, jh, vplus, action, note
tmap = {t: rule(t) for t in tables}
for t in tables:
    mapping.append(["TABLE", t, tmap[t], "CREATE", "데이터 복사" if t in DATA_TABLES else "구조만"])
cmap = {}
for t, cn, ty, rcn, _ in sorted(cons, key=lambda x: (x[2], x[1])):
    if ty == "P":
        new = "PK_" + tmap[t]
        note = "PK와 PK 인덱스" + ("" if new == rule(cn) else f" (규칙대로면 {rule(cn)}, 1-2장 정리)")
        mapping.append(["PK", cn, new, "CREATE", note])
    else:
        new = f"FK_{tmap[tab_of_cons[rcn]]}_TO_{tmap[t]}"
        note = f"{tmap[tab_of_cons[rcn]]} -> {tmap[t]}" + ("" if new == rule(cn) else f" (규칙대로면 {rule(cn)}, 1-3장 정리)")
        mapping.append(["FK", cn, new, "CREATE", note])
    cmap[cn] = new

omap, copy_code, excluded = {}, [], []
for n, ty in code:
    if "ZTEST" in n:
        excluded.append([ty, n, "", "EXCLUDE", "사용자 결정 2: ZTEST 관련 제외"]); continue
    if n in EXCLUDE_EXPLICIT:
        excluded.append([ty, n, "", "EXCLUDE", EXCLUDE_EXPLICIT[n]]); continue
    m = re.match(r"^(PQSA|PQSB|FQSA)_", n)
    if m:
        new = {"PQSA": "PQSB", "PQSB": "PQSC", "FQSA": "FQSB"}[m.group(1)] + n[4:]
        omap[n] = new; copy_code.append((n, ty, new))
        mapping.append([ty, n, new, "CREATE", "이름 규칙 적용"])
    elif n in v_objs:
        excluded.append([ty, n, n, "EXCLUDE", "vplus에 같은 이름이 있음(vplus 것을 그대로 사용)"])
    else:
        omap[n] = n; copy_code.append((n, ty, n))
        mapping.append([ty, n, n, "CREATE", "이름 그대로, vplus에 없음"])
mapping += excluded

# 소스 치환에 쓰는 이름 매핑 = 테이블 + 복사하는 코드 객체
SRC_MAP = {**tmap, **omap}
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
for n, ty, new in copy_code:
    body = "".join(src[(n, ty)])
    hits = Counter()
    def sub(m):
        k = m.group(1).upper(); hits[f"{k}->{SRC_MAP[k]}"] += 1; return SRC_MAP[k]
    nb = pat.sub(sub, body)
    if not re.match(r"\s*(PROCEDURE|FUNCTION|TYPE)\s+\"?" + re.escape(new) + r"\b", nb, re.I):
        raise SystemExit(f"header check failed: {n}")
    # 남은 QS 이름 토큰 중 새 이름이 아닌 것
    resid = {}
    zz = zones(nb)
    found = defaultdict(set)
    for mm in re.finditer(r"(?<![A-Za-z0-9_$#])[A-Za-z]QS[A-Za-z]_[A-Za-z0-9_$#]+", nb):
        found[mm.group(0).upper()].add(ZN[zz[mm.start()]])
    ctes = {x.upper() for x in re.findall(r"(?:\bWITH|,)\s+([A-Za-z0-9_$#]+)\s+AS\s*\(", nb, re.I)}
    for tok, where in found.items():
        if tok in known_new: continue
        where = "/".join(sorted(where))
        if tok in ctes: why = "WITH 절 이름(객체 아님)"
        elif where.startswith("주석") and "코드" not in where: why = "주석 안의 이름(실행과 무관)"
        elif tok in v_objs: why = "vplus 기존 객체(제외 객체 포함)를 그대로 사용"
        elif tok in jh_objs: why = "JH에 있으나 이관 대상 아님"
        else: why = "JH·vplus 어디에도 없는 이름(주석·문자열 등)"
        if re.match(r"(TQSA|PQSA|FQSA)_", tok) or why != "vplus 기존 객체(제외 객체 포함)를 그대로 사용":
            resid[tok] = f"{why} [{where}]"
    for k, v in resid.items(): residual_all[(k, v)] += 1
    report.append((ty, n, new, len(src[(n, ty)]), hits, resid))
    code_sql[ty].append(f"-- {n} -> {new}\nCREATE " + nb.rstrip() + "\n/\n")

# 의존 순서: TYPE은 OBJ 다음 TAB
code_sql["TYPE"].sort(key=lambda s: 0 if "QSSITEOBJ01" in s.split("\n")[0] else 1)

def write(name, header, parts):
    with open(os.path.join(OUT, name), "w", encoding="utf-8", newline="\n") as f:
        f.write(f"-- {header}\n-- 생성: {NOW} (2단계, 검토용 - 아직 실행하지 않음)\n-- 대상 스키마: VPLUS202611A\n\n")
        f.write("\n".join(parts))

write("10_tables.sql", f"테이블 {len(tables)}개 (PK·NOT NULL·DEFAULT 포함, FK 제외)", tab_sql)
write("30_fk.sql", f"FK {len(fk_sql)}개", fk_sql)
write("40_comments.sql", f"코멘트 (테이블 {cmt_cnt['table']}, 컬럼 {cmt_cnt['column']})", cmt_sql)
write("50_types.sql", f"TYPE {len(code_sql['TYPE'])}개", code_sql["TYPE"])
write("60_functions.sql", f"함수 {len(code_sql['FUNCTION'])}개", code_sql["FUNCTION"])
write("70_procedures.sql", f"프로시저 {len(code_sql['PROCEDURE'])}개", code_sql["PROCEDURE"])

# 데이터 복사 대상
jcnt = {t: jc.execute(f'SELECT COUNT(*) FROM "{t}"').fetchone()[0] for t in DATA_TABLES}
with open(os.path.join(OUT, "20_data_tables.csv"), "w", newline="", encoding="utf-8-sig") as f:
    w = csv.writer(f); w.writerow(["JH_TABLE", "VPLUS_TABLE", "JH_ROWS"])
    for t in DATA_TABLES: w.writerow([t, tmap[t], jcnt[t]])

# ---------------- 되돌리기 ----------------
rb = ["-- 이번에 만든 객체만 지운다. vplus 기존 객체는 포함하지 않는다.\n"]
for ty in ("PROCEDURE", "FUNCTION"):
    for n, t2, new in reversed(copy_code):
        if t2 == ty: rb.append(f'DROP {ty} "{new}";')
rb += ['DROP TYPE "QSSITETAB01";', 'DROP TYPE "QSSITEOBJ01";']
rb += [f'DROP TABLE "{tmap[t]}" CASCADE CONSTRAINTS PURGE;' for t in reversed(tables)]
write("99_rollback.sql", "되돌리기 (생성 역순)", ["\n".join(rb) + "\n"])

# ---------------- 검증 ----------------
all_sql = "".join(open(os.path.join(OUT, f), encoding="utf-8").read() for f in os.listdir(OUT) if f.endswith(".sql") and f != "99_rollback.sql")
new_names = list(tmap.values()) + list(cmap.values()) + [x[2] for x in copy_code]
checks = {
    "테이블 수": (len(tables), 108),
    "PK 수": (sum(1 for c in cons if c[2] == "P"), 95),
    "FK 수": (len(fk_sql), 31),
    "TYPE 수": (len(code_sql["TYPE"]), 2),
    "함수 수": (len(code_sql["FUNCTION"]), 12),
    "프로시저 수": (len(code_sql["PROCEDURE"]), 275),
    "이름 그대로 복사 대상": (sorted(n for n, _, new in copy_code if n == new), sorted(EXPECT_SAME_NAME_COPY)),
    "새 이름 중복": (len(new_names) - len(set(new_names)), 0),
    "vplus 기존 이름과 충돌": (sorted(n for n in new_names if n in v_names), []),
    "'CREATE OR REPLACE' 사용": (len(re.findall(r"CREATE\s+OR\s+REPLACE", all_sql, re.I)), 0),
    "'JH202610' 포함": (all_sql.upper().count("JH202610"), 0),
    "TABLESPACE/STORAGE 절": (len(re.findall(r"\b(TABLESPACE|STORAGE\s*\()", all_sql, re.I)), 0),
    "DDL 안 TQSA_/PK_TQSA 등 원본 이름 잔존(10/30)": (len(re.findall(r'"(?:PK_|FK_)?TQSA_', "".join(tab_sql + fk_sql))) - 0, 0),
}
# 10/30에서 TQSA_ 잔존 검사는 새 이름(TQSB_로 바뀐 TQSA 계열 아님)만 남아야 하므로 원본 키 기준으로 재검사
ddl_names = set(re.findall(r'"([A-Z0-9_$#]*QS[A-Z0-9_$#]*)"', "".join(tab_sql + fk_sql)))
newset = set(tmap.values()) | set(cmap.values())
checks["DDL 안 QS 이름이 모두 새 이름인지(10/30)"] = (sorted(ddl_names - newset), [])
del checks["DDL 안 TQSA_/PK_TQSA 등 원본 이름 잔존(10/30)"]
checks["문장 종류(10_tables)"] = (dict(stmt_cnt), "CREATE TABLE 108, CREATE UNIQUE 95, ALTER TABLE 95")

with open(os.path.join(OUT, "80_replace_report.md"), "w", encoding="utf-8") as f:
    f.write(f"# 2단계 치환 검증 리포트\n\n> 생성: {NOW} · 조회 전용으로 생성했다. vplus에는 아무것도 실행하지 않았다.\n\n")
    f.write("## 1. 자동 검사\n\n| 검사 | 결과 | 기대 | 판정 |\n|---|---|---|---|\n")
    for k, (a, b) in checks.items():
        ok = "참고" if k.startswith("문장 종류") else ("OK" if a == b else "**확인 필요**")
        f.write(f"| {k} | {a} | {b} | {ok} |\n")
    f.write("\n## 2. 원본 이름이 남은 토큰 (치환하지 않은 것과 사유)\n\n")
    f.write("`TQSA_`/`PQSA_`/`FQSA_`로 시작하거나, JH에만 있고 이관 대상이 아닌 QS 이름이 바꾼 소스에 남은 경우다.\n\n")
    if residual_all:
        f.write("| 이름 | 사유 | 나오는 객체 수 |\n|---|---|---:|\n")
        for (k, v), c in sorted(residual_all.items()): f.write(f"| `{k}` | {v} | {c} |\n")
    else:
        f.write("없음\n")
    f.write("\n## 3. 객체별 치환 내역\n\n| 종류 | JH | vplus | 줄 수 | 바꾼 이름(횟수) | 남은 이름 |\n|---|---|---|---:|---|---|\n")
    for ty, n, new, ln, hits, resid in report:
        h = ", ".join(f"`{k}`({v})" for k, v in sorted(hits.items()))
        r = ", ".join(f"`{k}`" for k in sorted(resid)) or "-"
        f.write(f"| {ty} | `{n}` | `{new}` | {ln} | {h} | {r} |\n")

for k, (a, b) in checks.items():
    print(("OK  " if a == b else "CHK ") + k, a if a != b else "")
print("residual", dict(residual_all))
print("files", sorted(os.listdir(OUT)))
