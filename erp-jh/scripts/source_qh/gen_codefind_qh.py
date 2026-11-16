"""JH의 QS 코드찾기·셀렉트박스·모듈 JS 3개를 QH로 바꿔 vplus에 만든다.

원본: JH_ERP (읽기만 한다)
대상: VPLUS202611A 의 Qh 파일 3개 (새 파일. 기존 Qs 파일은 건드리지 않는다)
규칙: dm-hmplus/erp-jh/docs/QH_SOURCE_COPY_PLAN.md 5장, 9장
바이트 단위로 처리해서 UTF-8과 CRLF를 그대로 지킨다.
"""
import csv
import os
import re
import sys
from collections import Counter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))
JH = os.path.join(ROOT, "JH_ERP", "src", "main")
VP = os.path.join(ROOT, "VPLUS202611A", "erp", "src", "main")
MAPPING = os.path.join(ROOT, "dm-hmplus", "erp-jh", "scripts", "migration_qh", "02_generate", "mapping.csv")
COMCODE = os.path.join(ROOT, "dm-hmplus", "erp-jh", "scripts", "comcode_qh", "02_generate", "mapping.csv")

FILES = [
    ("resources/sqlmap/mybatis/co/codefind/QsCodeFind.xml", "resources/sqlmap/mybatis/co/codefind/QhCodeFind.xml", "xml"),
    ("resources/sqlmap/mybatis/co/selectbox/QsSelectBind.xml", "resources/sqlmap/mybatis/co/selectbox/QhSelectBind.xml", "xml"),
    ("webapp/resources/js/module/qs.lib.js", "webapp/resources/js/module/qh.lib.js", "js"),
]

# QH 이관 매핑표: JH 이름 -> vplus 이름
obj_map = {}
with open(MAPPING, encoding="utf-8-sig", newline="") as f:
    for r in csv.DictReader(f):
        obj_map[r["JH_NAME"]] = r["VPLUS_NAME"]

# 복사된 QH 공통코드 (COM_CD, HRNK_CD 모두)
qh_codes = set()
with open(COMCODE, encoding="utf-8-sig", newline="") as f:
    for r in csv.DictReader(f):
        qh_codes.add(r["VPLUS_COM_CD"])
        qh_codes.add(r["VPLUS_HRNK_CD"])

RE_OBJ = re.compile(rb"\b[TPF]QS[A-Z]_[A-Z0-9_]+\b")
RE_CODE = re.compile(rb"\bQS(Z?[0-9][0-9A-Z]*)\b")


def convert(data: bytes, kind: str, stats: Counter, report: list):
    def obj(m):
        name = m.group(0).decode()
        new = obj_map.get(name)
        if new is None:
            stats["obj_unmapped:" + name] += 1
            return m.group(0)
        stats["obj:" + name + " -> " + new] += 1
        return new.encode()

    def code(m):
        old = m.group(0).decode()
        new = "QH" + m.group(1).decode()
        stats["code:" + old + " -> " + new + ("" if new in qh_codes else " (QH 코드 없음)")] += 1
        return new.encode()

    rules = [
        (rb"com\.jh\.erp\.", b"com.hs.hub."),
    ]
    if kind == "xml":
        rules += [(rb'(<select id=")get_QS_', rb"\1get_QH_")]
    else:
        rules += [
            (rb"\bqsf", b"qhf"),               # 전역 함수 이름 (qsfnCodeFindInit 등)
            (rb'"/qsa/', b'"/qha/'),          # 결재 화면 경로 APR_APP_PATH
            (rb'"/qsb/', b'"/qhb/'),
            (rb"\[qsa/", b"[qha/"),           # 주석의 화면 경로 표기
            (rb"\[qsb/", b"[qhb/"),
        ]
    for pat, rep in rules:
        data, n = re.subn(pat, rep, data)
        if n:
            stats["rule:" + pat.decode() + " -> " + rep.decode()] += n
    data = RE_OBJ.sub(obj, data)
    data = RE_CODE.sub(code, data)
    return data


def main():
    for src, dst, kind in FILES:
        s = os.path.join(JH, src)
        d = os.path.join(VP, dst)
        with open(s, "rb") as f:
            data = f.read()
        stats = Counter()
        out = convert(data, kind, stats, [])
        if b"\r\n" in data and out.count(b"\r\n") != data.count(b"\r\n"):
            sys.exit("CRLF 개수가 바뀌었다: " + dst)
        with open(d, "wb") as f:   # 이전에 만든 Qh 사본(vplus 기준)을 JH 기준으로 바꿔 쓴다
            f.write(out)
        print("==", dst, f"({len(data)} -> {len(out)} bytes)")
        for k, v in sorted(stats.items()):
            print(f"  {v:4d}  {k}")


if __name__ == "__main__":
    main()
