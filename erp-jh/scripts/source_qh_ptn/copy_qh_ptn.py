"""JH_PTN qs -> VPLUS202611B qh 복사·변환 (docs/QH_PTN_SOURCE_COPY_PLAN.md)

usage:
  python -I copy_qh_ptn.py precheck   # 1단계
  python -I copy_qh_ptn.py map        # 2단계
  python -I copy_qh_ptn.py preview    # 3단계 (파일을 쓰지 않음)
  python -I copy_qh_ptn.py apply      # 5단계 (새 파일 72개 + 공통 파일 4개 줄 추가)
  python -I copy_qh_ptn.py verify     # 6단계 (파일 검증)
JH_PTN은 읽기만 한다. 인코딩(UTF-8)과 줄바꿈(CRLF)은 바이트 단위로 보존한다.
"""
import csv, difflib, os, re, subprocess, sys
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))          # d:/workspace/vplus
J = os.path.join(ROOT, "JH_PTN", "src", "main")
BREPO = os.path.join(ROOT, "VPLUS202611B")
B = os.path.join(BREPO, "ptn", "src", "main")
DBMAP = os.path.join(ROOT, "dm-hmplus", "erp-jh", "scripts", "migration_qh", "02_generate", "mapping.csv")
CODEMAP = os.path.join(ROOT, "dm-hmplus", "erp-jh", "scripts", "comcode_qh", "02_generate", "mapping.csv")

DIR_MAP = [  # (원본 상대 디렉토리, 대상 상대 디렉토리)
    ("java/com/jh/partner/qs/qsa", "java/com/hs/partner/qh/qha"),
    ("java/com/jh/partner/qs/qsb", "java/com/hs/partner/qh/qhb"),
    ("java/com/jh/partner/qs/qsc", "java/com/hs/partner/qh/qhc"),
    ("java/com/jh/partner/qs/qsz", "java/com/hs/partner/qh/qhz"),
    ("resources/sqlmap/mybatis/qs/qsa", "resources/sqlmap/mybatis/qh/qha"),
    ("resources/sqlmap/mybatis/qs/qsb", "resources/sqlmap/mybatis/qh/qhb"),
    ("resources/sqlmap/mybatis/qs/qsc", "resources/sqlmap/mybatis/qh/qhc"),
    ("resources/sqlmap/mybatis/qs/qsz", "resources/sqlmap/mybatis/qh/qhz"),
    ("webapp/WEB-INF/jsp/qs/qsa", "webapp/WEB-INF/jsp/qh/qha"),
    ("webapp/WEB-INF/jsp/qs/qsb", "webapp/WEB-INF/jsp/qh/qhb"),
    ("webapp/WEB-INF/jsp/qs/qsc", "webapp/WEB-INF/jsp/qh/qhc"),
    ("webapp/WEB-INF/jsp/qs/qsz", "webapp/WEB-INF/jsp/qh/qhz"),
]
EXTRA_MAP = [
    ("webapp/resources/js/module/qs.lib.js", "webapp/resources/js/module/qh.lib.js"),
    ("webapp/WEB-INF/jsp/include/navQS.jsp", "webapp/WEB-INF/jsp/include/navQH.jsp"),
    ("resources/sqlmap/mybatis/co/codefind/QsCodeFind.xml", "resources/sqlmap/mybatis/co/codefind/QhCodeFind.xml"),
    ("resources/sqlmap/mybatis/co/selectbox/QsSelectBind.xml", "resources/sqlmap/mybatis/co/selectbox/QhSelectBind.xml"),
]
PKG_MAP = [("com.jh.partner.qs.qsa", "com.hs.partner.qh.qha"), ("com.jh.partner.qs.qsb", "com.hs.partner.qh.qhb"),
           ("com.jh.partner.qs.qsc", "com.hs.partner.qh.qhc"), ("com.jh.partner.qs.qsz", "com.hs.partner.qh.qhz"),
           ("com.jh.partner.", "com.hs.partner.")]
ITEM_MAP = {"QS_CHRC_VAL": "QH_CHRC_VAL", "QS_CTPUNT": "QH_CTPUNT", "QS_CTP_CD": "QH_CTP_CD",
            "QS_DEPT_H_CD_AUTH": "QH_DEPT_H_CD_AUTH"}
SQLID_MAP = {"get_QS_CodeFindList_Proc": "get_QH_CodeFindList_Proc", "get_QS_CodeFindList": "get_QH_CodeFindList",
             "get_QS_SelectBindList": "get_QH_SelectBindList"}

# 공통 파일 줄 추가: (파일, 기준 줄 정규식, 추가 줄 생성 함수) — 기준 줄 바로 아래(블록 끝)에 넣는다
def _repo_line(line):            # QS 선언 줄을 복사해 QH로
    return line.replace(b"get_QS_", b"get_QH_")
COMMON = [
    ("java/com/hs/partner/co/comcode/rps/FindCodeRepository.java",
     [rb"^\s*List<Map<String,Object>> get_QS_CodeFindList\(", rb"^\s*List<Map<String,Object>> get_QS_CodeFindList_Proc\(",
      rb"^\s*List<Map<String,Object>> get_QS_SelectBindList\("], "repo"),
    ("webapp/WEB-INF/jsp/include/scriptInclude.jsp", [rb'src="/resources/js/module/qs\.lib\.js'], "script"),
    ("webapp/resources/js/app.createcodefinder.js", [rb'^\s*case "QS":\s*$'], "case"),
    ("webapp/WEB-INF/jsp/index.jsp", [rb"sysTp eq 'QS'.*navQS\.jsp"], "nav"),
]


def rel(p, base): return os.path.relpath(p, base).replace("\\", "/")
def out(path, lines):
    with open(path, "w", encoding="utf-8", newline="\n") as f: f.write("\n".join(lines) + "\n")


def file_pairs():
    pairs = []
    for s, d in DIR_MAP:
        for r, _, fs in os.walk(os.path.join(J, s)):
            for f in sorted(fs):
                sp = os.path.join(r, f)
                sub = rel(sp, os.path.join(J, s))
                pairs.append((f"{s}/{sub}", f"{d}/{sub}"))
    pairs += EXTRA_MAP
    return pairs


def class_map():
    m = {}
    for s, _ in DIR_MAP:
        if not s.startswith("java/"): continue
        for r, _, fs in os.walk(os.path.join(J, s)):
            for f in fs:
                if f.endswith(".java"):
                    c = f[:-5]
                    m[c] = "Qh" + c[2:] if c.startswith("Qs") else "Qh" + c
    return m


def load_maps():
    db = {}
    for r in csv.DictReader(open(DBMAP, encoding="utf-8-sig")):
        db[r["JH_NAME"]] = (r["ACTION"], r["VPLUS_NAME"])
    qh = set()
    for r in csv.DictReader(open(CODEMAP, encoding="utf-8-sig")):
        qh.add(r["VPLUS_COM_CD"]); qh.add(r["VPLUS_HRNK_CD"])
    return db, qh


def wb(names):  # 단어 경계 정규식, 긴 이름부터
    return re.compile(r"(?<![A-Za-z0-9_])(" + "|".join(map(re.escape, sorted(names, key=len, reverse=True))) + r")(?![A-Za-z0-9_])")


class Converter:
    def __init__(self):
        self.cls = class_map()
        self.db, self.qh = load_maps()
        self.db_create = {k: v[1] for k, v in self.db.items() if v[0] == "CREATE" and k != v[1]}
        self.re_cls = wb(self.cls)
        self.re_db = wb(self.db_create)
        self.re_item = wb(ITEM_MAP)
        self.re_sqlid = wb(SQLID_MAP)
        self.counts = Counter()
        self.notmapped = defaultdict(set)
        self.code_keep = Counter()

    def conv(self, text, relpath):
        c = self.counts
        def sub(rule, pattern, repl, t, flags=0):
            n_t, n = re.subn(pattern, repl, t, flags=flags); c[rule] += n; return n_t
        # 5-1 패키지
        for a, b in PKG_MAP:
            n = text.count(a); c["5-1 package"] += n; text = text.replace(a, b)
        # 5-2 클래스
        text, n = self.re_cls.subn(lambda m: self.cls[m.group(1)], text); c["5-2 class"] += n
        # 5-3 URL / 뷰 / 메뉴
        text = sub("5-3 url", r"([\"'])/qs([abcz])(?![A-Za-z0-9_])", r"\1/qh\2", text)
        text = sub("5-3 view", r"(?<![A-Za-z0-9_])qs/qs([abcz])(?![A-Za-z0-9_])", r"qh/qh\1", text)
        text = sub("5-3 nav", r"(href=['\"])qs([abcz])/", r"\1qh\2/", text)
        text = sub("5-3 relpath", r"([\"'])qs([abcz])/", r"\1qh\2/", text)   # setActiveMenu("qsa/…") 등 메뉴 링크와 짝
        # 5-4 DB 객체
        text, n = self.re_db.subn(lambda m: self.db_create[m.group(1)], text); c["5-4 db"] += n
        for m in re.finditer(r"(?<![A-Za-z0-9_])[A-Z]?[A-Z]QS[A-Z]?_[A-Z0-9_]+(?![A-Za-z0-9_])", text):
            self.notmapped[m.group(0)].add(relpath)
        # 5-6 SQL ID, 항목, 모듈, JS 함수
        text, n = self.re_sqlid.subn(lambda m: SQLID_MAP[m.group(1)], text); c["5-6 sqlid"] += n
        text, n = self.re_item.subn(lambda m: ITEM_MAP[m.group(1)], text); c["5-6 item"] += n
        text = sub("5-6 module", r"(module\s*:\s*)([\"'])QS\2", r"\1\2QH\2", text)
        text = sub("5-6 wrkTp", r"(wrkTp\s*=\s*)([\"'])QS\2", r"\1\2QH\2", text)
        text = sub("5-6 qsfn", r"(?<![A-Za-z0-9_])qsfn", "qhfn", text)
        # 5-5 공통코드
        def code(m):
            v = m.group(0); nv = "QH" + v[2:]
            if nv in self.qh: c["5-5 code"] += 1; return nv
            self.code_keep[v] += 1; return v
        text = re.sub(r"(?<![A-Za-z0-9_])QS[A-Z0-9]+(?![A-Za-z0-9_])", code, text)
        # 5-7 OZ
        text = sub("5-7 oz", r"([\"'])/QS/", r"\1/QH/", text)
        # 5-4b 프로시저 인자를 vplus DB(QH 프로시저) 정의에 맞춤 (사용자 지시, 2026-11-17)
        text = self.fix_proc_args(text)
        return text

    # (프로시저, 이 줄 바로 뒤에, 넣을 줄들) — 37_arg_align.txt 기준
    PROC_ARG_FIX = [
        ("PQHB_RISK_NAM_S", r"#\{EMPE_NO\s+,jdbcType=VARCHAR\}[^\r\n]*",
         ["              ,#{EMPE_NO_PRV       ,jdbcType=VARCHAR}  -- 이전 사원번호 (QH 프로시저 P_EMPE_NO_PRV에 맞춰 추가)"]),
        ("PQHB_RISK_DGR_W", r"#\{MGR_OPIN\s+,jdbcType=VARCHAR\}[^\r\n]*",
         ["              ,#{APRS_STR_DT      ,jdbcType=VARCHAR}  -- 평가시작일 (QH 프로시저 P_APRS_STR_DT에 맞춰 추가)",
          "              ,#{APRS_END_DT      ,jdbcType=VARCHAR}  -- 평가종료일 (QH 프로시저 P_APRS_END_DT에 맞춰 추가)"]),
    ]

    def fix_proc_args(self, text):
        for proc, anchor, add in self.PROC_ARG_FIX:
            m = re.search(r"CALL\s+" + proc + r"\s*\((.*?)\)\s*\}", text, re.S)
            if not m: continue
            blk = m.group(0)
            nl = "\r\n" if "\r\n" in blk else "\n"
            am = re.search(anchor, blk)
            assert am, f"anchor not found in {proc}"
            new_blk = blk[:am.end()] + "".join(nl + a for a in add) + blk[am.end():]
            text = text[:m.start()] + new_blk + text[m.end():]
            self.counts["5-4b proc arg"] += len(add)
        return text


def target_name(dst, conv):
    d, f = os.path.split(dst)
    if f.endswith(".java") and f[:-5] in conv.cls:
        f = conv.cls[f[:-5]] + ".java"
    return f"{d}/{f}"


def build():
    conv = Converter()
    results = []
    for s, d in file_pairs():
        raw = open(os.path.join(J, s), "rb").read()
        text = raw.decode("utf-8")
        new = conv.conv(text, d)
        results.append((s, target_name(d, conv), text, new))
    return conv, results


def common_additions():
    """(상대경로, 원본 bytes, 새 bytes, 추가한 줄 목록)"""
    res = []
    for f, pats, kind in COMMON:
        p = os.path.join(B, f)
        raw = open(p, "rb").read()
        lines = raw.split(b"\n")       # 각 줄 끝의 \r 보존
        out_lines, added = [], []
        i = 0
        while i < len(lines):
            l = lines[i]
            out_lines.append(l)
            hit = any(re.search(pt, l) for pt in pats)
            if hit:
                if kind == "repo":
                    nl = _repo_line(l); out_lines.append(nl); added.append(nl)
                elif kind == "script":
                    nl = l.replace(b"qs.lib.js", b"qh.lib.js"); out_lines.append(nl); added.append(nl)
                elif kind == "nav":
                    nl = l.replace(b"'QS'", b"'QH'").replace(b"navQS.jsp", b"navQH.jsp"); out_lines.append(nl); added.append(nl)
                elif kind == "case":
                    # case "QS": / init_sheet = qsfn...; / break;  -> 3줄 복사 후 QH
                    blk = lines[i + 1:i + 3]
                    assert b"qsfnCodeFindInit" in blk[0] and b"break;" in blk[1], f"unexpected block in {f} line {i+1}"
                    out_lines += blk; i += 2
                    for b0 in [l] + blk:
                        nl = b0.replace(b'"QS"', b'"QH"').replace(b"qsfnCodeFindInit", b"qhfnCodeFindInit")
                        out_lines.append(nl); added.append(nl)
            i += 1
        res.append((f, raw, b"\n".join(out_lines), added))
    return res


def git_status():
    r = subprocess.run(["git", "-C", BREPO, "status", "--porcelain", "--untracked-files=all"], capture_output=True, text=True)
    return [l for l in r.stdout.splitlines() if l.strip()]


# ---------------------------------------------------------------- steps
def precheck():
    conv = Converter()
    log = []
    pairs = file_pairs()
    log.append(f"source files: {len(pairs)} (qs dirs {len(pairs)-len(EXTRA_MAP)}, extra {len(EXTRA_MAP)})")
    exist = [d for _, d in pairs if os.path.exists(os.path.join(B, target_name(d, conv)))]
    log.append(f"target already exists: {len(exist)} {exist}")
    qhdirs = [d for d in ["java/com/hs/partner/qh", "resources/sqlmap/mybatis/qh", "webapp/WEB-INF/jsp/qh"] if os.path.exists(os.path.join(B, d))]
    log.append(f"qh dirs existing: {qhdirs}")
    qhcls = [os.path.join(r, f) for r, _, fs in os.walk(os.path.join(B, "java")) for f in fs if f.startswith("Qh")]
    log.append(f"Qh* classes existing: {len(qhcls)}")
    newcls = set(conv.cls.values())
    allcls = {f[:-5] for r, _, fs in os.walk(os.path.join(B, "java")) for f in fs if f.endswith(".java")}
    log.append(f"new class names colliding with B: {sorted(newcls & allcls)}")
    st = git_status()
    log.append(f"git status lines: {len(st)} {st[:10]}")
    for f, _, _ in COMMON:
        log.append(f"common file exists: {f} {os.path.exists(os.path.join(B, f))}")
    ok = not exist and not qhdirs and not qhcls and not (newcls & allcls) and not st
    log.append("RESULT: " + ("OK" if ok else "NG"))
    out(os.path.join(HERE, "10_precheck.log"), log); print("\n".join(log))


def mapping():
    conv, results = build()
    with open(os.path.join(HERE, "20_path_map.csv"), "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f); w.writerow(["SRC", "DST"])
        for s, d, _, _ in results: w.writerow([s, d])
    with open(os.path.join(HERE, "21_class_map.csv"), "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f); w.writerow(["JH_CLASS", "NEW_CLASS"])
        for k in sorted(conv.cls): w.writerow([k, conv.cls[k]])
    used = defaultdict(set)
    for s, d, text, _ in results:
        for m in re.finditer(r"(?<![A-Za-z0-9_])[A-Z]?[A-Z]QS[A-Z]?_[A-Z0-9_]+(?![A-Za-z0-9_])", text): used[m.group(0)].add(d)
    with open(os.path.join(HERE, "22_dbobj_map.csv"), "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f); w.writerow(["JH_NAME", "ACTION", "NEW_NAME", "FILE_CNT", "FILES"])
        for k in sorted(used):
            a, v = conv.db.get(k, ("NOT_MAPPED", k))
            w.writerow([k, a, v if a == "CREATE" else k, len(used[k]), " ".join(sorted(used[k]))])
    codes = Counter()
    for _, _, text, _ in results:
        for m in re.finditer(r"(?<![A-Za-z0-9_])QS[A-Z0-9]+(?![A-Za-z0-9_])", text): codes[m.group(0)] += 1
    with open(os.path.join(HERE, "23_code_map.csv"), "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f); w.writerow(["JH_CODE", "ACTION", "NEW_CODE", "COUNT"])
        for k in sorted(codes):
            nv = "QH" + k[2:]
            w.writerow([k, "CHANGE" if nv in conv.qh else "KEEP", nv if nv in conv.qh else k, codes[k]])
    print(f"path {len(results)}, class {len(conv.cls)}, db {len(used)}, code {len(codes)}")


LEFT_PAT = re.compile(r"(?i)qs")
def leftovers(results):
    rows = []
    for _, d, _, new in results:
        for i, line in enumerate(new.splitlines(), 1):
            for m in re.finditer(r"[A-Za-z0-9_]*[Qq][Ss][A-Za-z0-9_]*", line):
                tok = m.group(0)
                if re.fullmatch(r"[A-Za-z0-9_]*", tok) and ("qs" in tok.lower()):
                    rows.append((d, i, tok, line.strip()[:160]))
    return rows


def preview():
    conv, results = build()
    adds = common_additions()
    rep = ["# 3단계 변환 미리보기 (파일을 쓰지 않음)", "", f"- 새 파일: {len(results)}개", ""]
    rep.append("## 규칙별 바꾼 곳"); rep.append("")
    rep.append("| 규칙 | 곳 |"); rep.append("|---|---:|")
    for k in sorted(conv.counts): rep.append(f"| {k} | {conv.counts[k]} |")
    rep += ["", "## 남은 QS DB 이름 (매핑표 CREATE 아님)", ""]
    for k in sorted(conv.notmapped):
        rep.append(f"- `{k}` ({conv.db.get(k, ('NOT_MAPPED',))[0]}): {', '.join(sorted(conv.notmapped[k]))}")
    rep += ["", "## 그대로 둔 QS 코드 모양 값 (QH 코드 없음)", "", str(dict(conv.code_keep)) or "-"]
    rep += ["", "## 공통 파일에 추가할 줄", ""]
    for f, _, _, added in adds:
        rep.append(f"- `{f}`: {len(added)}줄")
        for a in added: rep.append(f"    - `{a.decode('utf-8').strip()}`")
    left = leftovers(results)
    tokc = Counter(t for _, _, t, _ in left)
    rep += ["", "## 남은 `qs`/`QS` 토큰 (31_leftover.txt에 줄 단위 목록)", ""]
    for t, n in tokc.most_common(): rep.append(f"- `{t}`: {n}")
    out(os.path.join(HERE, "30_diff_report.md"), rep)
    out(os.path.join(HERE, "31_leftover.txt"), [f"{d}:{i}: [{t}] {l}" for d, i, t, l in left])
    diff = []
    for s, d, old, new in results:
        diff += difflib.unified_diff(old.splitlines(), new.splitlines(), f"JH/{s}", f"B/{d}", lineterm="", n=0)
    for f, raw, new, _ in adds:
        diff += difflib.unified_diff(raw.decode("utf-8").splitlines(), new.decode("utf-8").splitlines(), f"B/{f}", f"B/{f}", lineterm="", n=1)
    out(os.path.join(HERE, "32_preview.diff"), [l.rstrip("\r") for l in diff])
    print("\n".join(rep))


def apply():
    conv, results = build()
    adds = common_additions()
    log = []
    for _, d, _, _ in results:
        if os.path.exists(os.path.join(B, d)):
            print("STOP: target exists", d); sys.exit(1)
    if git_status():
        print("STOP: git working tree not clean"); sys.exit(1)
    for s, d, _, new in results:
        p = os.path.join(B, d); os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "wb") as f: f.write(new.encode("utf-8"))
        log.append(f"WRITE {d}  <- {s}")
    for f, raw, new, added in adds:
        with open(os.path.join(B, f), "wb") as fh: fh.write(new)
        log.append(f"APPEND {f}: +{len(added)} lines")
    log.append(f"TOTAL new {len(results)}, common modified {len(adds)}")
    out(os.path.join(HERE, "50_copy.log"), log); print("\n".join(log[-6:]))


def verify():
    conv, results = build()
    log, ok = [], True
    def chk(name, cond, detail=""):
        nonlocal ok
        ok &= bool(cond); log.append(f"[{'OK' if cond else 'NG'}] {name} {detail}")
    news = [d for _, d, _, _ in results]
    chk("새 파일 72개 존재", all(os.path.exists(os.path.join(B, d)) for d in news) and len(news) == 72, len(news))
    same = all(open(os.path.join(B, d), "rb").read() == new.encode("utf-8") for _, d, _, new in results)
    chk("새 파일 내용 = 변환 결과", same)
    crlf = all((b"\r\n" in open(os.path.join(J, s), "rb").read()) == (b"\r\n" in open(os.path.join(B, d), "rb").read()) for s, d, _, _ in results)
    chk("줄바꿈 보존", crlf)
    st = git_status()
    mod = sorted(l[3:] for l in st if not l.startswith("??"))
    untracked = [l[3:] for l in st if l.startswith("??")]
    exp_mod = sorted("ptn/src/main/" + f for f, _, _ in COMMON)
    chk("수정(M)은 공통 파일 4개뿐", mod == exp_mod, mod)
    exp_new = sorted("ptn/src/main/" + d for d in news)
    chk("새 파일(??)은 대상 경로뿐", sorted(untracked) == exp_new, f"{len(untracked)}")
    r = subprocess.run(["git", "-C", BREPO, "diff", "--numstat"], capture_output=True, text=True).stdout.split("\n")
    dels = [l for l in r if l.strip() and l.split("\t")[1] != "0"]
    chk("공통 파일 diff는 추가만", not dels, dels)
    alltext = {d: open(os.path.join(B, d), encoding="utf-8").read() for d in news}
    bad_pats = {"com.jh.partner": r"com\.jh\.partner", '"/qsX': r"[\"']/qs[abcz](?![A-Za-z0-9_])", "qs/qsX": r"(?<![A-Za-z0-9_])qs/qs[abcz]",
                "href='qs": r"href=['\"]qs[abcz]/", '"qsX/': r"[\"']qs[abcz]/", "/QS/": r"[\"']/QS/", 'module:"QS"': r"module\s*:\s*[\"']QS[\"']",
                'wrkTp="QS"': r"wrkTp\s*=\s*[\"']QS[\"']", "get_QS_": r"get_QS_", "qsfn": r"(?<![A-Za-z0-9_])qsfn",
                "QS_ items": r"(?<![A-Za-z0-9_])(?:" + "|".join(ITEM_MAP) + r")(?![A-Za-z0-9_])"}
    for k, p in bad_pats.items():
        hits = [d for d, t in alltext.items() if re.search(p, t)]
        chk(f"남은 이름 0건: {k}", not hits, hits[:5])
    left_db = set()
    for t in alltext.values():
        left_db |= set(re.findall(r"(?<![A-Za-z0-9_])[A-Z]?[A-Z]QS[A-Z]?_[A-Z0-9_]+(?![A-Za-z0-9_])", t))
    chk("남은 DB 이름 = VQSZ 2 + 미매핑 3", left_db == {"VQSZ_TRADE", "VQSZ_SITEINFO", "PQSC_NCR_AB_S", "PQSC_NCR_REP_S", "TQSC_NCR_REP"}, sorted(left_db))
    # 함수·SQL ID 유일성
    defs = []
    for r_, _, fs in os.walk(os.path.join(B, "webapp", "resources", "js")):
        for f in fs:
            if f.endswith(".js") and re.search(r"function\s+qhfnCodeFindInit\b", open(os.path.join(r_, f), encoding="utf-8", errors="replace").read()):
                defs.append(f)
    chk("qhfnCodeFindInit 정의 1곳(qh.lib.js)", defs == ["qh.lib.js"], defs)
    ids = Counter()
    for r_, _, fs in os.walk(os.path.join(B, "resources", "sqlmap")):
        for f in fs:
            if f.endswith(".xml"):
                for m in re.finditer(r'id="(get_QH_\w+)"', open(os.path.join(r_, f), encoding="utf-8", errors="replace").read()): ids[m.group(1)] += 1
    chk("get_QH_ SQL ID 각 1개", ids == Counter({k: 1 for k in SQLID_MAP.values()}), dict(ids))
    repo = open(os.path.join(B, "java/com/hs/partner/co/comcode/rps/FindCodeRepository.java"), encoding="utf-8").read()
    chk("FindCodeRepository 선언 3개", all(re.search(rf"\b{k}\(Map", repo) for k in SQLID_MAP.values()))
    # 클래스 유일성
    names = Counter(f[:-5] for r_, _, fs in os.walk(os.path.join(B, "java")) for f in fs if f.endswith(".java"))
    dup = [n for n in conv.cls.values() if names[n] != 1]
    chk("새 클래스 이름 유일", not dup, dup)
    # 항목 이름 짝
    cf = alltext["resources/sqlmap/mybatis/co/codefind/QhCodeFind.xml"]; sb = alltext["resources/sqlmap/mybatis/co/selectbox/QhSelectBind.xml"]
    lib = alltext["webapp/resources/js/module/qh.lib.js"]
    md = set(); gc = set()
    for d, t in alltext.items():
        if d.endswith(".jsp"):
            md |= set(re.findall(r"module\s*:\s*[\"']QH[\"']\s*,\s*moduleDiv\s*:\s*[\"']([A-Z0-9_]+)", t))
            gc |= set(re.findall(r"wrkTp=[\"']QH[\"'][^>]*grpCd=[\"']([A-Z0-9_]+)", t))
    miss_md = sorted(x for x in md if f"'{x}'" not in cf or f'"{x}"' not in lib)
    miss_gc = sorted(x for x in gc if f"'{x}'" not in sb)
    chk("코드찾기 항목 짝 (예외: QH_DEPT_H_CD_AUTH, VNDR_REG_SITE_CD)", set(miss_md) <= {"QH_DEPT_H_CD_AUTH", "VNDR_REG_SITE_CD"}, f"used={sorted(md)} missing={miss_md}")
    chk("셀렉트 항목 짝", not miss_gc, f"used={sorted(gc)} missing={miss_gc}")
    log.append("RESULT: " + ("OK" if ok else "NG"))
    out(os.path.join(HERE, "60_verify.log"), log); print("\n".join(log))


if __name__ == "__main__":
    {"precheck": precheck, "map": mapping, "preview": preview, "apply": apply, "verify": verify}[sys.argv[1]]()
