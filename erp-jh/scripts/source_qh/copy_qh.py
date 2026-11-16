"""JH qs 소스를 QH로 바꿔 vplus qh 경로에 복사한다.

계획: dm-hmplus/erp-jh/docs/QH_SOURCE_COPY_PLAN.md (6장 실행 절차)

사용법:
    python -I -X utf8 copy_qh.py precheck   # 1단계: 사전 확인        -> 10_precheck.log
    python -I -X utf8 copy_qh.py map        # 2단계: 매핑표 생성      -> 20~23_*.csv
    python -I -X utf8 copy_qh.py preview    # 3단계: 변환 미리보기    -> 30_diff_report.md, 31_leftover.txt, 32_preview.diff
    python -I -X utf8 copy_qh.py apply      # 5단계: 복사·변환        -> 50_copy.log   (4단계 사용자 확인 후에만)

원칙(계획 2장)
- JH_ERP는 읽기만 한다.
- vplus 기존 qs 소스는 바꾸지 않는다. 새 qh 파일만 쓴다.
- 예외로 허용한 기존 파일만 고친다: Qh 파일 3개(10장), 결재 레이아웃 3개(8-1).
- 바이트 단위로 처리해서 UTF-8, CRLF를 그대로 지킨다.
"""
import csv
import difflib
import os
import re
import subprocess
import sys
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
JH = os.path.join(ROOT, "JH_ERP", "src", "main")
VP_REPO = os.path.join(ROOT, "VPLUS202611A")
VP = os.path.join(VP_REPO, "erp", "src", "main")
DBMAP = os.path.join(ROOT, "dm-hmplus", "erp-jh", "scripts", "migration_qh", "02_generate", "mapping.csv")
BASE_JH = os.path.join(ROOT, "dm-hmplus", "erp-jh", "scripts", "migration_qh", "01_baseline", "jh_qs_objects.csv")
BASE_VP = os.path.join(ROOT, "dm-hmplus", "erp-jh", "scripts", "migration_qh", "01_baseline", "vplus_objects.csv")
CODEMAP = os.path.join(ROOT, "dm-hmplus", "erp-jh", "scripts", "comcode_qh", "02_generate", "mapping.csv")

# 계획 3장: 원본 디렉토리 -> 대상 디렉토리 (src/main 기준)
DIRS = [
    ("java/com/jh/erp/qs/aprv", "java/com/hs/hub/qh/aprv"),
    ("java/com/jh/erp/qs/qsa", "java/com/hs/hub/qh/qha"),
    ("java/com/jh/erp/qs/qsb", "java/com/hs/hub/qh/qhb"),
    ("resources/sqlmap/mybatis/qs/aprv", "resources/sqlmap/mybatis/qh/aprv"),
    ("resources/sqlmap/mybatis/qs/qsa", "resources/sqlmap/mybatis/qh/qha"),
    ("resources/sqlmap/mybatis/qs/qsb", "resources/sqlmap/mybatis/qh/qhb"),
    ("webapp/WEB-INF/jsp/qs/aprv", "webapp/WEB-INF/jsp/qh/aprv"),
    ("webapp/WEB-INF/jsp/qs/qsa", "webapp/WEB-INF/jsp/qh/qha"),
    ("webapp/WEB-INF/jsp/qs/qsb", "webapp/WEB-INF/jsp/qh/qhb"),
    ("webapp/WEB-INF/jsp/cont/qs/aprv", "webapp/WEB-INF/jsp/cont/qh/aprv"),
]
DST_ROOTS = [
    "java/com/hs/hub/qh",
    "resources/sqlmap/mybatis/qh",
    "webapp/WEB-INF/jsp/qh",
    "webapp/WEB-INF/jsp/cont/qh",
]
EXPECTED_FILES = 783

# 계획 10장: 이미 만든 Qh 파일 3개 (5단계 ②)
QH_MODULE_FILES = [
    "resources/sqlmap/mybatis/co/codefind/QhCodeFind.xml",
    "resources/sqlmap/mybatis/co/selectbox/QhSelectBind.xml",
    "webapp/resources/js/module/qh.lib.js",
]
# 계획 8-1: 결재 레이아웃 3개 (5단계 ③)
TILES = "webapp/WEB-INF/tiles/tiles.xml"
HEADER = "webapp/WEB-INF/tiles/view/approvalinside/header.jsp"
FOOTER = "webapp/WEB-INF/tiles/view/approvalinside/footer.jsp"

# 계획 5-6: 항목 이름
ITEM_NAMES = ["DEPT_H_CD_AUTH", "COMCD1", "COMCD2", "COMCD3", "CHRC_VAL", "CTPUNT", "CTP_CD"]
RE_ITEM = re.compile(rb"\bQS_(" + b"|".join(n.encode() for n in ITEM_NAMES) + rb")\b")

RE_DBOBJ = re.compile(rb"\b(?:T_)?[A-Z]QS[A-Z]_[A-Z0-9_]+\b|\bQSSITE[A-Z0-9_]+\b")
# 5-5: QS 뒤에 영문자·숫자가 이어지는 낱말. QH로 바꾼 값이 복사된 공통코드에 있을 때만 바꾼다
RE_CODE = re.compile(rb"\bQS([0-9A-Z][0-9A-Z]*)\b")
RE_LEFT = re.compile(rb"(?<![A-Za-z])[Qq][Ss]\w*")


def out(name):
    return os.path.join(HERE, name)


def rd(path):
    with open(path, "rb") as f:
        return f.read()


def rel(p, base):
    return os.path.relpath(p, base).replace("\\", "/")


# ---------------------------------------------------------------- 수집

def source_files():
    """[(src_rel, dst_dir_rel, filename)]"""
    rows = []
    for s, d in DIRS:
        sd = os.path.join(JH, s)
        for dp, _, fns in os.walk(sd):
            for fn in sorted(fns):
                sub = rel(dp, sd)
                sub = "" if sub == "." else sub
                rows.append((
                    "/".join(x for x in (s, sub, fn) if x),
                    "/".join(x for x in (d, sub) if x),
                    fn,
                ))
    return rows


def java_pkg(src_rel):
    # java/com/jh/erp/qs/qsa/web/X.java -> com.jh.erp.qs.qsa.web
    return ".".join(src_rel.split("/")[1:-1])


def new_simple(simple):
    return "Qh" + simple[2:] if simple.startswith("Qs") else "Qh" + simple


def convert_pkg(pkg):
    for a, b in (("com.jh.erp.qs.qsa", "com.hs.hub.qh.qha"),
                 ("com.jh.erp.qs.qsb", "com.hs.hub.qh.qhb"),
                 ("com.jh.erp.qs.aprv", "com.hs.hub.qh.aprv")):
        if pkg == a or pkg.startswith(a + "."):
            return b + pkg[len(a):]
    return pkg.replace("com.jh.erp.", "com.hs.hub.", 1)


def class_map(files):
    m = []
    for src, _, fn in files:
        if fn.endswith(".java"):
            s = fn[:-5]
            pkg = java_pkg(src)
            m.append({"OLD_FQCN": pkg + "." + s, "NEW_FQCN": convert_pkg(pkg) + "." + new_simple(s),
                      "OLD_NAME": s, "NEW_NAME": new_simple(s)})
    return m


def load_dbmap():
    m = {}
    with open(DBMAP, encoding="utf-8-sig", newline="") as f:
        for r in csv.DictReader(f):
            m[r["JH_NAME"]] = (r["ACTION"], r["VPLUS_NAME"], r["KIND"], r["NOTE"])
    return m


def load_names(path):
    with open(path, encoding="utf-8-sig", newline="") as f:
        return {r["OBJECT_NAME"] for r in csv.DictReader(f)}


def load_codes():
    s = set()
    with open(CODEMAP, encoding="utf-8-sig", newline="") as f:
        for r in csv.DictReader(f):
            s.add(r["VPLUS_COM_CD"])
            s.add(r["VPLUS_HRNK_CD"])
    return s


# ---------------------------------------------------------------- 변환

class Converter:
    def __init__(self, cmap):
        self.db = load_dbmap()
        self.codes = load_codes()
        names = sorted((c["OLD_NAME"] for c in cmap), key=len, reverse=True)
        self.cls = {c["OLD_NAME"].encode(): c["NEW_NAME"].encode() for c in cmap}
        self.re_cls = re.compile(rb"\b(" + b"|".join(n.encode() for n in names) + rb")\b")
        self.stats = Counter()            # 규칙별 바꾼 곳
        self.db_use = defaultdict(set)    # DB 이름 -> 파일
        self.code_use = defaultdict(set)  # 코드 -> 파일

    def sub(self, key, pat, rep, data, flags=0):
        data, n = re.subn(pat, rep, data, flags=flags)
        if n:
            self.stats[key] += n
        return data

    def db_obj(self, data, fname):
        def f(m):
            name = m.group(0).decode()
            self.db_use[name].add(fname)
            act = self.db.get(name)
            if act and act[0] == "CREATE" and act[1]:
                self.stats["5-4 DB 이름 (CREATE)"] += 1
                return act[1].encode()
            return m.group(0)
        return RE_DBOBJ.sub(f, data)

    def code(self, data, fname):
        def f(m):
            old = m.group(0).decode()
            new = "QH" + m.group(1).decode()
            if new not in self.codes:
                if old != "QSE":   # 화면 설명 문구(5-8)
                    self.code_use[old].add(fname)
                    self.stats["5-5 공통코드 값 (QH 코드 없음, 그대로)"] += 1
                return m.group(0)
            self.code_use[old].add(fname)
            self.stats["5-5 공통코드 값 (바꿈)"] += 1
            return new.encode()
        return RE_CODE.sub(f, data)

    def convert(self, data, fname):
        ext = fname.rsplit(".", 1)[-1].lower()
        # 5-4 DB 이름
        data = self.db_obj(data, fname)
        # 5-1 패키지
        data = self.sub("5-1 패키지 qs.qsa", rb"com\.jh\.erp\.qs\.qsa\b", b"com.hs.hub.qh.qha", data)
        data = self.sub("5-1 패키지 qs.qsb", rb"com\.jh\.erp\.qs\.qsb\b", b"com.hs.hub.qh.qhb", data)
        data = self.sub("5-1 패키지 qs.aprv", rb"com\.jh\.erp\.qs\.aprv\b", b"com.hs.hub.qh.aprv", data)
        data = self.sub("5-1 패키지 그 밖", rb"com\.jh\.erp\.", b"com.hs.hub.", data)
        # 5-2 클래스 이름 (.java, .xml)
        if ext in ("java", "xml"):
            def fc(m):
                self.stats["5-2 클래스 이름"] += 1
                return self.cls[m.group(1)]
            data = self.re_cls.sub(fc, data)
        # 5-3 URL·경로
        data = self.sub("5-3 경로 qs/qsa", rb"(?<!\w)qs/qsa(?=[/\"'\s?.{]|$)", b"qh/qha", data)
        data = self.sub("5-3 경로 qs/qsb", rb"(?<!\w)qs/qsb(?=[/\"'\s?.{]|$)", b"qh/qhb", data)
        data = self.sub("5-3 경로 qs/aprv", rb"(?<!\w)qs/aprv(?=[/\"'\s?.{]|$)", b"qh/aprv", data)
        data = self.sub("5-3 URL /qsa", rb"(?<![\w/])/qsa(?=[/\"'?\s]|$)", b"/qha", data)
        data = self.sub("5-3 URL /qsb", rb"(?<![\w/])/qsb(?=[/\"'?\s]|$)", b"/qhb", data)
        data = self.sub("5-3 주석 [qsa/", rb"\[qsa/", b"[qha/", data)
        data = self.sub("5-3 주석 [qsb/", rb"\[qsb/", b"[qhb/", data)
        # 5-6 모듈 코드, 함수, 항목 이름
        data = self.sub("5-6 module:\"QS\"", rb"(\bmodule\s*:\s*)([\"'])QS\2", rb"\1\2QH\2", data)
        data = self.sub("5-6 wrkTp=\"QS\"", rb"(\bwrkTp\s*=\s*)([\"'])QS\2", rb"\1\2QH\2", data)
        data = self.sub("5-6 workType=\"QS\"", rb"(\bworkType\s*=\s*)([\"'])QS\2", rb"\1\2QH\2", data)
        data = self.sub("5-6 \"QS-항목\"", rb"([\"'])QS-(?=[A-Z])", rb"\1QH-", data)
        data = self.sub("5-6 함수 qsf -> qhf", rb"(?<![/\w])qsf(?=[A-Za-z_])", b"qhf", data)
        data = self.sub("5-6 항목 이름 QS_ -> QH_", RE_ITEM, rb"QH_\1", data)
        # 5-7 OZ 경로
        data = self.sub("5-7 OZ /QS/qsa/", rb"/QS/qsa/", b"/QH/qha/", data)
        data = self.sub("5-7 OZ /QS/qsb/", rb"/QS/qsb/", b"/QH/qhb/", data)
        data = self.sub("5-7 OZ /QS/", rb"/QS/", b"/QH/", data)
        data = self.sub("5-7 OZ node QS", rb"([\"']node[\"']\s*:\s*[\"'])QS([\"'])", rb"\1QH\2", data)
        # 5-5 공통코드 값
        data = self.code(data, fname)
        return data


def module_rules(data, stats):
    """5단계 ②: Qh 파일 3개에 5-6 항목 이름, 5-7 OZ 경로만 적용"""
    for key, pat, rep in (
        ("② 항목 이름", RE_ITEM, rb"QH_\1"),
        ("② OZ /QS/qsa/", rb"/QS/qsa/", b"/QH/qha/"),
        ("② OZ /QS/qsb/", rb"/QS/qsb/", b"/QH/qhb/"),
        ("② OZ /QS/", rb"/QS/", b"/QH/"),
    ):
        data, n = re.subn(pat, rep, data)
        stats[key] += n
    return data


TILE_DEF = (
    b'    <definition name="/qh/aprv/*" extends="layout.approvalinside">\r\n'
    b'        <put-attribute name="header" expression="/WEB-INF/tiles/view/approvalinside/header.jsp" />\r\n'
    b'        <put-attribute name="body" expression="/WEB-INF/jsp/qh/aprv/{1}.jsp"></put-attribute>\r\n'
    b'        <put-attribute name="footer" value="/WEB-INF/tiles/view/approvalinside/footer.jsp" />\r\n'
    b'        <put-attribute name="aprvBase" value="/qh/aprv" />\r\n'
    b'        </definition>\r\n'
)
APRV_HEAD = (
    b'<%@ taglib prefix="tiles" uri="http://tiles.apache.org/tags-tiles" %>\r\n'
    b'<tiles:importAttribute name="aprvBase" ignore="true" />\r\n'
    b'<c:if test="${empty aprvBase}"><c:set var="aprvBase" value="/qs/aprv" /></c:if>\r\n'
)


def aprv_layout(path_rel, data, stats):
    """5단계 ③: 8-1 결재 레이아웃"""
    if path_rel == TILES:
        anchor = re.search(rb'    <definition name="/qs/aprv/\*".*?</definition>\r\n', data, re.S)
        if not anchor or b'"/qh/aprv/*"' in data:
            raise SystemExit("tiles.xml: /qs/aprv/* 정의를 찾지 못했거나 /qh/aprv/* 정의가 이미 있다")
        stats["③ tiles 정의 추가"] += 1
        return data[:anchor.end()] + TILE_DEF + data[anchor.end():]
    # header/footer: jstl core taglib 줄 바로 다음에 3줄 추가, "/qs/aprv/ -> "${aprvBase}/
    m = re.search(rb'<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>\r\n', data)
    if not m or b"aprvBase" in data:
        raise SystemExit(path_rel + ": jstl core taglib 줄을 찾지 못했거나 이미 aprvBase가 있다")
    data = data[:m.end()] + APRV_HEAD + data[m.end():]
    stats["③ " + os.path.basename(path_rel) + " 머리 3줄"] += 1
    data, n = re.subn(rb'"/qs/aprv/', b'"${aprvBase}/', data)
    stats["③ " + os.path.basename(path_rel) + " 결재 주소"] += n
    return data


# ---------------------------------------------------------------- 1단계

def precheck():
    log, fail = [], []

    def ok(cond, msg):
        log.append(("OK   " if cond else "FAIL ") + msg)
        if not cond:
            fail.append(msg)

    files = source_files()
    ok(len(files) == EXPECTED_FILES, f"원본 파일 수 {len(files)} (기대 {EXPECTED_FILES})")
    exts = Counter(f[2].rsplit(".", 1)[-1].lower() for f in files)
    log.append("     확장자: " + ", ".join(f"{k} {v}" for k, v in sorted(exts.items())))

    for d in DST_ROOTS:
        ok(not os.path.exists(os.path.join(VP, d)), f"대상 경로 없음: {d}")

    vp_java = {}
    for dp, _, fns in os.walk(os.path.join(VP, "java")):
        for fn in fns:
            if fn.endswith(".java"):
                vp_java.setdefault(fn[:-5], []).append(rel(os.path.join(dp, fn), VP))
    qh_existing = [n for n in vp_java if n.startswith("Qh")]
    ok(not qh_existing, f"vplus에 Qh로 시작하는 클래스 없음 ({len(qh_existing)}개)")

    cmap = class_map(files)
    news = [c["NEW_NAME"] for c in cmap]
    dup = [n for n, c in Counter(news).items() if c > 1]
    ok(not dup, f"새 클래스 이름 {len(news)}개가 서로 겹치지 않음 (겹침 {dup})")
    clash = [n for n in news if n in vp_java]
    ok(not clash, f"새 클래스 이름이 vplus 기존 클래스와 겹치지 않음 (겹침 {clash})")

    # qs 밖 import 확인: vplus에 있는지, 이름이 qs 클래스와 겹치지 않는지
    olds = {c["OLD_NAME"] for c in cmap}
    ext_imports = set()
    for src, _, fn in files:
        if fn.endswith(".java"):
            for m in re.finditer(rb"^import\s+(?:static\s+)?(com\.jh\.erp\.[\w.]+);", rd(os.path.join(JH, src)), re.M):
                name = m.group(1).decode()
                if not name.startswith("com.jh.erp.qs."):
                    ext_imports.add(name)
    missing = [n for n in sorted(ext_imports)
               if not os.path.exists(os.path.join(VP, "java", n.replace("com.jh.erp.", "com.hs.hub.").replace(".", "/") + ".java"))]
    ok(not missing, f"qs 밖 import {len(ext_imports)}종이 vplus에 있음 (없음 {missing})")
    same = [n for n in ext_imports if n.rsplit(".", 1)[-1] in olds]
    ok(not same, f"qs 밖 import의 클래스 이름이 qs 클래스 이름과 겹치지 않음 (겹침 {same})")

    # 인코딩
    bad, bom, crlf, lf = [], 0, 0, 0
    for src, _, _ in files:
        b = rd(os.path.join(JH, src))
        try:
            b.decode("utf-8")
        except UnicodeDecodeError:
            bad.append(src)
        bom += b.startswith(b"\xef\xbb\xbf")
        if b"\r\n" in b:
            crlf += 1
        elif b"\n" in b:
            lf += 1
    ok(not bad, f"원본이 모두 UTF-8 (아닌 파일 {len(bad)}: {bad[:5]})")
    log.append(f"     BOM {bom}개, CRLF 파일 {crlf}개, LF 파일 {lf}개 (원본 그대로 유지)")

    # 예외 허용 파일
    for p in QH_MODULE_FILES + [TILES, HEADER, FOOTER]:
        ok(os.path.exists(os.path.join(VP, p)), f"예외 허용 파일 있음: {p}")
    h = rd(os.path.join(VP, HEADER))
    f_ = rd(os.path.join(VP, FOOTER))
    t = rd(os.path.join(VP, TILES))
    ok(h.count(b'"/qs/aprv/') == 8, f'header.jsp의 "/qs/aprv/" {h.count(b"\"/qs/aprv/")}곳 (기대 8)')
    ok(f_.count(b'"/qs/aprv/') == 2, f'footer.jsp의 "/qs/aprv/" {f_.count(b"\"/qs/aprv/")}곳 (기대 2)')
    ok(b'"/qs/aprv/*"' in t and b'"/qh/aprv/*"' not in t, "tiles.xml에 /qs/aprv/* 정의만 있음")
    ok(b"aprvBase" not in h + f_ + t, "결재 레이아웃에 aprvBase가 아직 없음")

    # 매핑 자료
    for p in (DBMAP, BASE_JH, BASE_VP, CODEMAP):
        ok(os.path.exists(p), "매핑 자료 있음: " + rel(p, ROOT))

    # git
    st = subprocess.run(["git", "-C", VP_REPO, "status", "--porcelain"], capture_output=True, text=True)
    ok(st.returncode == 0 and st.stdout.strip() == "", f"vplus git 작업 트리가 깨끗함 ({st.stdout.strip()[:200]})")

    log.append("")
    log.append("결과: " + ("통과" if not fail else f"실패 {len(fail)}건"))
    with open(out("10_precheck.log"), "w", encoding="utf-8", newline="\r\n") as f:
        f.write("\n".join(log) + "\n")
    print("\n".join(log))
    return not fail


# ---------------------------------------------------------------- 2단계

def build_maps():
    files = source_files()
    cmap = class_map(files)
    cls_rename = {c["OLD_NAME"] + ".java": c["NEW_NAME"] + ".java" for c in cmap}

    with open(out("20_path_map.csv"), "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(["SRC (JH_ERP/src/main)", "DST (VPLUS202611A/erp/src/main)"])
        for src, dd, fn in files:
            w.writerow([src, dd + "/" + cls_rename.get(fn, fn)])

    with open(out("21_class_map.csv"), "w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["OLD_FQCN", "NEW_FQCN", "OLD_NAME", "NEW_NAME"])
        w.writeheader()
        w.writerows(cmap)

    # DB 이름·공통코드 사용처 (원본 기준)
    conv = Converter(cmap)
    for src, _, fn in files:
        data = rd(os.path.join(JH, src))
        conv.db_obj(data, src)
        for m in RE_CODE.finditer(data):
            if m.group(0) != b"QSE":
                conv.code_use[m.group(0).decode()].add(src)
    jh_objs, vp_objs = load_names(BASE_JH), load_names(BASE_VP)
    rows = []
    for name in sorted(conv.db_use):
        act = conv.db.get(name)
        if act and act[0] == "CREATE" and act[1]:
            a, new = "CREATE", act[1]
        elif act:
            a, new = "EXCLUDE", name
        else:
            a, new = "NOT_MAPPED", name
        where = "JH,vplus" if name in jh_objs and name in vp_objs else "JH" if name in jh_objs else "vplus" if name in vp_objs else "없음"
        rows.append([name, a, new, act[3] if act else "", where, len(conv.db_use[name]), " ".join(sorted(conv.db_use[name]))])
    with open(out("22_dbobj_map.csv"), "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(["JH_NAME", "ACTION", "NEW_NAME", "MAPPING_NOTE", "BASELINE", "FILE_CNT", "FILES"])
        w.writerows(rows)

    crow = []
    for old in sorted(conv.code_use):
        new = "QH" + old[2:]
        has = new in conv.codes
        crow.append([old, new if has else old, "Y" if has else "N", "CHANGE" if has else "KEEP",
                     len(conv.code_use[old]), " ".join(sorted(conv.code_use[old]))])
    with open(out("23_code_map.csv"), "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(["OLD", "NEW", "IN_QH_COMCODE", "ACTION", "FILE_CNT", "FILES"])
        w.writerows(crow)

    acts = Counter(r[1] for r in rows)
    print(f"20_path_map.csv  {len(files)}행")
    print(f"21_class_map.csv {len(cmap)}행")
    print(f"22_dbobj_map.csv {len(rows)}행 " + dict(acts).__repr__())
    print(f"23_code_map.csv  {len(crow)}행 (QH 코드 없음 {sum(1 for r in crow if r[2] == 'N')})")


# ---------------------------------------------------------------- 3·5단계

def run(write):
    files = source_files()
    cmap = class_map(files)
    conv = Converter(cmap)
    cls_rename = {c["OLD_NAME"] + ".java": c["NEW_NAME"] + ".java" for c in cmap}
    results = []  # (src, dst, old, new)
    for src, dd, fn in files:
        old = rd(os.path.join(JH, src))
        new = conv.convert(old, src)
        if old.count(b"\r\n") != new.count(b"\r\n"):
            raise SystemExit("CRLF 개수가 바뀌었다: " + src)
        results.append((src, dd + "/" + cls_rename.get(fn, fn), old, new))

    stats2 = Counter()
    extra = []  # (path, old, new)
    for p in QH_MODULE_FILES:
        o = rd(os.path.join(VP, p))
        extra.append((p, o, module_rules(o, stats2)))
    for p in (TILES, HEADER, FOOTER):
        o = rd(os.path.join(VP, p))
        extra.append((p, o, aprv_layout(p, o, stats2)))

    if write:
        log = []
        for d in DST_ROOTS:
            if os.path.exists(os.path.join(VP, d)):
                raise SystemExit("대상 경로가 이미 있다: " + d)
        for src, dst, _, new in results:
            p = os.path.join(VP, dst)
            if os.path.exists(p):
                raise SystemExit("같은 경로에 파일이 있다: " + dst)
            os.makedirs(os.path.dirname(p), exist_ok=True)
            with open(p, "wb") as f:
                f.write(new)
            log.append(f"COPY {src} -> {dst}")
        for p, _, new in extra:
            with open(os.path.join(VP, p), "wb") as f:
                f.write(new)
            log.append(f"EDIT {p}")
        log.append("")
        log += [f"{v:6d}  {k}" for k, v in sorted(conv.stats.items())]
        log += [f"{v:6d}  {k}" for k, v in sorted(stats2.items())]
        with open(out("50_copy.log"), "w", encoding="utf-8", newline="\r\n") as f:
            f.write("\n".join(log) + "\n")
        print(f"복사 {len(results)}개, 수정 {len(extra)}개. 50_copy.log")
        return

    # ---- 미리보기 산출물
    with open(out("32_preview.diff"), "w", encoding="utf-8", newline="\n") as f:
        for src, dst, old, new in results:
            if old != new:
                f.writelines(difflib.unified_diff(
                    old.decode("utf-8").splitlines(True), new.decode("utf-8").splitlines(True),
                    "JH_ERP/src/main/" + src, "VPLUS202611A/erp/src/main/" + dst, n=0))
        for p, old, new in extra:
            f.writelines(difflib.unified_diff(
                old.decode("utf-8").splitlines(True), new.decode("utf-8").splitlines(True),
                "a/" + p, "b/" + p, n=1))

    # 남은 qs/QS
    allowed_db = set()
    with open(out("22_dbobj_map.csv"), encoding="utf-8-sig", newline="") as f:
        for r in csv.DictReader(f):
            if r["ACTION"] != "CREATE":
                allowed_db.add(r["JH_NAME"])
    left_tok = Counter()
    left_lines = []
    for src, dst, _, new in results:
        for i, line in enumerate(new.split(b"\n"), 1):
            toks = [t.decode() for t in RE_LEFT.findall(line)]
            if toks:
                for t in toks:
                    left_tok[t] += 1
                left_lines.append(f"{dst}:{i}: [{' '.join(toks)}] {line.decode('utf-8').strip()[:200]}")
    with open(out("31_leftover.txt"), "w", encoding="utf-8", newline="\r\n") as f:
        f.write("# 변환 뒤 새 파일에 남은 qs/QS 토큰 (앞에 영문자가 없는 것)\n")
        f.write("# 토큰별 개수\n")
        for t, c in left_tok.most_common():
            f.write(f"{c:6d}  {t}\n")
        f.write("\n# 줄별\n")
        f.write("\n".join(left_lines) + "\n")

    # 보고서
    with open(out("22_dbobj_map.csv"), encoding="utf-8-sig", newline="") as f:
        dbrows = list(csv.DictReader(f))
    with open(out("23_code_map.csv"), encoding="utf-8-sig", newline="") as f:
        coderows = list(csv.DictReader(f))
    changed = sum(1 for r in results if r[2] != r[3])
    ozr = sorted({m.decode() for _, _, _, n in results for m in re.findall(rb"/QH/[\w/.\-\"' +]*?\.ozr", n)})
    ozr_js = sorted({m.decode() for m in re.findall(rb"/QH/[\w/.\-]+\.ozr", extra[2][2])})

    L = []
    L.append("# QH 소스 복사 미리보기 보고서 (3단계)\n")
    L.append("> 계획: [QH_SOURCE_COPY_PLAN.md](../../docs/QH_SOURCE_COPY_PLAN.md) · 아직 파일을 쓰지 않았다. "
             "줄 단위 diff는 `32_preview.diff`, 남은 qs/QS는 `31_leftover.txt`\n")
    L.append("## 1. 요약\n")
    L.append("| 항목 | 값 |\n|---|---:|")
    L.append(f"| 새로 만들 파일 | {len(results)} |")
    L.append(f"| 그중 내용이 바뀌는 파일 | {changed} |")
    L.append(f"| 수정할 기존 파일(예외 허용) | {len(extra)} |")
    L.append(f"| 매핑표에 없는 DB 이름(NOT_MAPPED) | {sum(1 for r in dbrows if r['ACTION'] == 'NOT_MAPPED')} |")
    L.append(f"| 바꾼 코드 값 (종류) | {sum(1 for r in coderows if r['ACTION'] == 'CHANGE')} |")
    L.append(f"| 그대로 둔 코드 모양 값 (종류) | {sum(1 for r in coderows if r['ACTION'] == 'KEEP')} |\n")
    L.append("## 2. 규칙별 바꾸는 곳 (새 파일 783개)\n")
    L.append("| 규칙 | 곳 |\n|---|---:|")
    for k, v in sorted(conv.stats.items()):
        L.append(f"| {k} | {v} |")
    L.append("\n## 3. 기존 파일 수정 (5단계 ②·③)\n")
    L.append("| 규칙 | 곳 |\n|---|---:|")
    for k, v in sorted(stats2.items()):
        L.append(f"| {k} | {v} |")
    L.append("\n## 4. DB 이름\n")
    L.append("| ACTION | 개수 |\n|---|---:|")
    for k, v in sorted(Counter(r["ACTION"] for r in dbrows).items()):
        L.append(f"| {k} | {v} |")
    L.append("\n### 4-1. 매핑표에 없는 이름 (바꾸지 않음, 5-4)\n")
    L.append("| 이름 | 기준선 | 파일 수 | 사용 파일 |\n|---|---|---:|---|")
    for r in dbrows:
        if r["ACTION"] == "NOT_MAPPED":
            L.append(f"| `{r['JH_NAME']}` | {r['BASELINE']} | {r['FILE_CNT']} | {r['FILES'][:160]} |")
    L.append("\n### 4-2. EXCLUDE (vplus 것을 그대로 사용)\n")
    L.append("| 이름 | 파일 수 |\n|---|---:|")
    for r in dbrows:
        if r["ACTION"] == "EXCLUDE":
            L.append(f"| `{r['JH_NAME']}` | {r['FILE_CNT']} |")
    L.append("\n## 5. 그대로 둔 코드 모양 값 (QH 공통코드에 없음, 5-5)\n")
    L.append("| 값 | 파일 수 | 사용 파일 |\n|---|---:|---|")
    for r in coderows:
        if r["ACTION"] == "KEEP":
            L.append(f"| `{r['OLD']}` | {r['FILE_CNT']} | {r['FILES'][:160]} |")
    L.append("\n## 6. 남은 qs/QS 토큰 (상위 40개, 전체는 31_leftover.txt)\n")
    L.append("| 토큰 | 곳 |\n|---|---:|")
    for t, c in left_tok.most_common(40):
        L.append(f"| `{t}` | {c} |")
    L.append("\n## 7. 리포트 서버에 필요한 OZ 경로 (결정 4, 나중에 추가)\n")
    L.append("JSP의 `rptName`(파일 이름이 변수인 것 포함)과 `qh.lib.js`의 `RPTNAME`이다.\n")
    for x in ozr + ozr_js:
        L.append(f"- `{x}`")
    with open(out("30_diff_report.md"), "w", encoding="utf-8", newline="\r\n") as f:
        f.write("\n".join(L) + "\n")

    print(f"새 파일 {len(results)}개 (내용 바뀜 {changed}), 기존 파일 수정 {len(extra)}개")
    for k, v in sorted(conv.stats.items()):
        print(f"  {v:6d}  {k}")
    for k, v in sorted(stats2.items()):
        print(f"  {v:6d}  {k}")
    print("남은 토큰 상위:", ", ".join(f"{t}({c})" for t, c in left_tok.most_common(25)))


# ---------------------------------------------------------------- 6단계

def verify():
    log, fail = [], []

    def ok(cond, msg):
        log.append(("OK   " if cond else "FAIL ") + msg)
        if not cond:
            fail.append(msg)

    with open(out("20_path_map.csv"), encoding="utf-8-sig", newline="") as f:
        dsts = [r[1] for r in list(csv.reader(f))[1:]]
    new_files = []
    for d in DST_ROOTS:
        for dp, _, fns in os.walk(os.path.join(VP, d)):
            new_files += [rel(os.path.join(dp, fn), VP) for fn in fns]
    ok(len(new_files) == EXPECTED_FILES and set(new_files) == set(dsts), f"새 파일 {len(new_files)}개가 경로 매핑과 같음")

    # git
    st = subprocess.run(["git", "-C", VP_REPO, "status", "--porcelain", "--untracked-files=normal"], capture_output=True, text=True).stdout.splitlines()
    mod = sorted(l[3:] for l in st if l.startswith(" M") or l.startswith("M "))
    unt = sorted(l[3:].rstrip("/") for l in st if l.startswith("??"))
    want_mod = sorted("erp/src/main/" + p for p in QH_MODULE_FILES + [TILES, HEADER, FOOTER])
    want_unt = sorted("erp/src/main/" + d for d in DST_ROOTS)
    ok(mod == want_mod, f"수정(M)은 예외 허용 6개뿐 ({len(mod)}개)")
    ok(unt == want_unt, f"새 파일(??)은 qh 경로 4곳뿐 ({unt})")
    others = [l for l in st if not (l.startswith(" M") or l.startswith("M ") or l.startswith("??"))]
    ok(not others, f"그 밖의 변경 없음 ({others})")
    ok(not any("/qs/" in p or "/qs." in p for p in mod + unt), "기존 qs 소스 수정 0건")

    # 남은 이름
    allowed = set()
    with open(out("22_dbobj_map.csv"), encoding="utf-8-sig", newline="") as f:
        for r in csv.DictReader(f):
            if r["ACTION"] != "CREATE":
                allowed.add(r["JH_NAME"])
    pats = {"com.jh.erp": rb"com\.jh\.erp", '"/qsa': rb"[\"']/qsa\b", '"/qsb': rb"[\"']/qsb\b",
            '"/qs/aprv': rb"[\"']/qs/aprv", "/QS/": rb"/QS/", "QS_ 항목 이름": RE_ITEM}
    hits = Counter()
    bad_db = Counter()
    crlf_bad = []
    for p in new_files:
        b = rd(os.path.join(VP, p))
        for k, pat in pats.items():
            hits[k] += len(re.findall(pat, b))
        for m in RE_DBOBJ.findall(b):
            if m.decode() not in allowed and not re.match(rb"(?:T_)?[A-Z]QH", m):
                bad_db[m.decode()] += 1
        if b.count(b"\n") != b.count(b"\r\n"):
            crlf_bad.append(p)
    for k in pats:
        ok(hits[k] == 0, f"새 파일에 {k} {hits[k]}곳")
    ok(not bad_db, f"남은 QS DB 이름이 모두 NOT_MAPPED/EXCLUDE 목록에 있음 (밖 {dict(bad_db)})")
    ok(not crlf_bad, f"새 파일 줄바꿈 모두 CRLF (아님 {crlf_bad[:5]})")

    # 예외 파일
    h = rd(os.path.join(VP, HEADER)) + rd(os.path.join(VP, FOOTER))
    ok(h.count(b'"/qs/aprv/') == 0 and h.count(b'"${aprvBase}/') == 10, "header/footer 결재 주소 10곳이 aprvBase로 바뀜")
    ok(rd(os.path.join(VP, TILES)).count(b'"/qh/aprv/*"') == 1, "tiles.xml에 /qh/aprv/* 정의 1개")
    mods = b"".join(rd(os.path.join(VP, p)) for p in QH_MODULE_FILES)
    ok(not RE_ITEM.search(mods) and b"/QS/" not in mods, "Qh 파일 3개에 QS_ 항목 이름·/QS/ 0곳")

    # 항목 이름 짝: 새 JSP의 QH_ 항목 이름이 Qh 모듈에 있음
    used = Counter()
    for p in new_files:
        if p.endswith(".jsp"):
            for m in re.findall(rb"\bQH_[A-Z0-9_]+\b", rd(os.path.join(VP, p))):
                used[m.decode()] += 1
    missing = [n for n in used if n.encode() not in mods]
    ok(not missing, f"새 JSP의 QH_ 항목 이름 {len(used)}종이 Qh 모듈에 있음 (없음 {missing})")

    # 클래스 이름 유일
    names = Counter()
    for dp, _, fns in os.walk(os.path.join(VP, "java")):
        for fn in fns:
            if fn.endswith(".java"):
                names[fn] += 1
    dup = [n for n, c in names.items() if c > 1 and n.startswith("Qh")]
    ok(not dup, f"Qh 클래스 이름이 vplus 전체에서 하나뿐 (겹침 {dup})")

    log.append("")
    log.append("결과: " + ("통과" if not fail else f"실패 {len(fail)}건"))
    with open(out("60_verify.log"), "w", encoding="utf-8", newline="\r\n") as f:
        f.write("\n".join(log) + "\n")
    print("\n".join(log))
    return not fail


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "verify":
        sys.exit(0 if verify() else 1)
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "precheck":
        sys.exit(0 if precheck() else 1)
    elif cmd == "map":
        build_maps()
    elif cmd == "preview":
        run(write=False)
    elif cmd == "apply":
        if not precheck():
            sys.exit("사전 확인 실패. 복사하지 않았다.")
        run(write=True)
    else:
        sys.exit(__doc__)
