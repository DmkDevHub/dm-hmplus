"""매퍼 CALL 인자 vs DB 인자를 이름으로 맞대어 출력 (읽기 전용).
CALL 인자는 최상위 쉼표로 나눠 센다(고정값 인자 포함). usage: DB_PASSWORD=... python -I check_db3.py [NAME...]
"""
import os, re, sys
import oracledb
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import copy_qh_ptn as c

DSN = "192.168.1.25:1521/ORCLU"
SKIP = {"PQSC_NCR_AB_S", "PQSC_NCR_REP_S", "PCOA_SMS_INTERFACE"}

def strip_comments(s):
    s = re.sub(r"<!--.*?-->", "", s, flags=re.S)
    s = re.sub(r"/\*.*?\*/", "", s, flags=re.S)
    return re.sub(r"--[^\n]*", "", s)

def split_args(s):
    s = strip_comments(s)
    out, depth, cur, q = [], 0, "", False
    for ch in s:
        if ch == "'" : q = not q
        if not q:
            if ch in "({": depth += 1
            elif ch in ")}": depth -= 1
            elif ch == "," and depth == 0: out.append(cur); cur = ""; continue
        cur += ch
    if cur.strip(): out.append(cur)
    return [a.strip() for a in out]

def arg_key(a):
    m = re.match(r"#\{\s*([A-Za-z0-9_]+)", a)
    return m.group(1).upper() if m else None

def mapper_calls():
    _, results = c.build()
    res = []
    for _, d, _, new in results:
        if not d.endswith(".xml"): continue
        for m in re.finditer(r"CALL\s+([A-Z0-9_]+)\s*\((.*?)\)\s*\}", new, re.S | re.I):
            res.append((m.group(1).upper(), d, split_args(m.group(2)), m))
    return res

def db_args(cur, name):
    cur.execute("""SELECT POSITION, ARGUMENT_NAME, IN_OUT, DEFAULTED, DATA_TYPE FROM USER_ARGUMENTS
                   WHERE OBJECT_NAME = :1 AND PACKAGE_NAME IS NULL AND DATA_LEVEL = 0 AND ARGUMENT_NAME IS NOT NULL
                   ORDER BY POSITION""", [name])
    return cur.fetchall()

if __name__ == "__main__":
    ALL = "--all" in sys.argv
    only = set(a for a in sys.argv[1:] if a != "--all")
    if ALL: only = {n for n, _, _, _ in mapper_calls()} - SKIP
    with oracledb.connect(user="VPLUS202611A", password=os.environ["DB_PASSWORD"], dsn=DSN) as con:
        cur = con.cursor()
        for name, d, args, _ in mapper_calls():
            if name in SKIP or (only and name not in only): continue
            dba = db_args(cur, name)
            if len(args) == len(dba) and not only: continue
            print(f"### {name}  mapper={len(args)} db={len(dba)}  {d}")
            mk = [arg_key(a) or a for a in args]
            dk = [x[1].upper().removeprefix("P_") for x in dba]
            for i in range(max(len(args), len(dba))):
                a = mk[i] if i < len(mk) else ""
                b = f"{dba[i][1]}{'(D)' if dba[i][3]=='Y' else ''}{'' if dba[i][2]=='IN' else '/'+dba[i][2]}" if i < len(dba) else ""
                flag = "" if (i < len(dk) and a.upper().removeprefix("P_") == dk[i]) else "  <--"
                print(f"   {i+1:2} {a:28} | {b}{flag}")
