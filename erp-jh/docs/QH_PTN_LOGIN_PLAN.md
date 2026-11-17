# VPLUS202611B 협력사 로그인 QH 처리 계획

> 작성일: 2026-11-17 · 대상: `VPLUS202611B/ptn/src/main` (패키지 `com.hs.partner`) · DB: vplus `VPLUS202611A`
> 관련: [QH_PTN_SOURCE_COPY_PLAN.md](QH_PTN_SOURCE_COPY_PLAN.md)(협력사 QH 화면 소스 복사, 10장 후속 작업)
> 이 문서의 내용은 B 소스, JH 소스, vplus DB를 **읽기만 해서** 확인한 것이다. 아직 아무 파일도 고치지 않았다.
> **상태: 실행함(2026-11-17, 사용자 지시 "문서에 정리하고 개발 진행해").** 8-2의 결정은 제안대로 적용했다. 결과는 10장. VPLUS202611B 커밋 `40d22a7`.

## 1. 목적

QH 협력사 화면(`/qha`, `/qhb`, `/qhc`, `/qhz`)은 B에 복사됐다(커밋 `189f7b1`). 그러나 아직 **QH 사용자로 로그인할 방법이 없다.** 그래서 새 화면은 메뉴로 들어갈 수 없다.

이 문서는 **QH 로그인**을 추가하는 계획이다. QH 로그인은 다음을 갖춘다.
- QH 계정으로 로그인한다
- QH 메뉴(`navQH.jsp`)가 나온다
- QH 화면에 접근 권한이 있다
- 비밀번호 변경과 실패 횟수 관리가 동작한다

**핵심 결정(사용자 지시, 2026-11-17)**

| 항목 | 내용 |
|---|---|
| 참고 원본 | `JH_PTN/src/main/resources/sqlmap/mybatis/sys/Account.xml`의 QS 로그인 구문 |
| QH 계정 테이블 | **`TQHB_VNDRNAM`에서만 조회한다** (근로자 명단, ID `EMPE_NO`). `TQHA_VNDR`는 업체명을 가져오는 조인에만 쓴다 |
| 기존 로그인 | 회원·QS 로그인에 문제가 없어야 한다 |
| 같은 ID | 같은 ID가 `TQHB_VNDRNAM`과 다른 계정 테이블에 함께 있으면 **`TQHB_VNDRNAM`을 우선한다.** QS·SM 같은 모듈 구분 없이, ID가 `TQHB_VNDRNAM`에 있는지만 본다 |

## 2. 현재 구조 (확인함)

### 2-1. 사용자 종류는 ID가 어느 테이블에 있는지로 정해진다

로그인 화면에는 모듈 선택이 없다. ID와 비밀번호만 받는다. 사용자 종류는 로그인 검증 쿼리 `accountVerify`가 정한다(`sys/Account.xml`). 계정 테이블에는 QS·QH 같은 업무 구분 값이 없다. **계정 구분은 ID가 들어 있는 테이블로 정해진다.**

| 계정 테이블 | 대상 | 권한 | 모듈(`FNL_CNCT_MDL` → `sysTp`) |
|---|---|---|---|
| `TEPZ_MBR_REG` (+`TEPZ_MBR_ADD`) | 협력사 회원 | `ROLE_CO`, `ROLE_SM_USER` 등 | 마지막 접속 모듈 또는 `SM`/`MM`/`GC`/`CW` |
| `TQSA_VNDR` | 협력업체 안전담당자(`VNDR_PSN_ID`/`VNDR_PSN_PWD`) | `ROLE_QS_USER` | **`'QS'` 고정** |

- 두 테이블을 `UNION ALL`로 합쳐 ID 하나로 조회한다.
- 결과는 `Map` 1건으로 받는다. 그래서 **같은 ID가 두 테이블에 있으면 행이 2개 나와 로그인이 실패한다**(`TooManyResultsException`).

### 2-2. 흐름

```
login (usrId/pswd)
 └─ AccountServiceImpl.loadUserByUsername
      accountVerify(userId)  → 권한, FNL_CNCT_MDL
      session.sysTp = FNL_CNCT_MDL                      ('QS')
 ├─ 성공: LoginSuccessHandler
 │    sysTp == QS → set_RsetFailCntQs (TQSA_VNDR.FAIL_CNT = 0)
 │    getLoginUserInfo: QS → get_loginUserInfoQs (TQSA_VNDR)
 │    get_PtnAccProp → RSET_YN (112행, 결과가 null이면 114행 NPE)
 │    switch(sysTp) case "QS": USR_ID, USR_NM, SIT_CD, VNDR_CD, VNDR_NM, VNDR_SEQ, CUST_CD, RSET_YN 를 세션(AccountVO)에
 │    → /index
 └─ 실패: LoginFailureHandler (BadCredentials)
      회원이면 set_FailCnt, 아니고 get_ExistUsrQs = Y 이면 get_FailCntQs / set_FailCntQs, 아니면 "계정없음"

/index (MainController)
   moduleInfo = 화면에서 고른 모듈 또는 세션 SYS_TP
   QS가 아니면 set_LoginModule (TEPZ_MBR_REG.FNL_CNCT_MDL 갱신)
index.jsp
   sysTp != 'QS' 일 때만 모듈 변경 셀렉트(<tag:ChangeModule>)를 보인다
   sysTp 에 따라 navXX.jsp 를 고른다 (QH 분기는 화면 복사 때 이미 추가함)
URL 권한 (SecurityConfiguration)
   /qs*/** → ROLE_QS_USER
   그 밖 → 로그인만 되어 있으면 허용 (anyRequest().authenticated())
```

### 2-3. QH 화면이 세션에서 쓰는 값

- 새 `qh` 소스는 세션 값 `USR_ID`, `USR_NM`, `CUST_CD`, `VNDR_SEQ`, `VNDR_CD`, `VNDR_NM`, `SIT_CD`를 쓴다(`principal.*`, `BaseUtils.ssInfo()`).
- 이 값들은 `LoginSuccessHandler`의 `case "QS"`에서만 채워진다.
- 따라서 **QH 로그인도 같은 값을 채워야 한다.** 값은 `TQHB_VNDRNAM`에서 가져온다. 업체명(`VNDR_NM`)만 `TQHA_VNDR`를 조인해 가져온다(4-1 #2).

### 2-4. JH와 B의 QS 로그인 차이

| 항목 | B (`VPLUS202611B`) | JH (`JH_PTN`) |
|---|---|---|
| QS 계정 테이블 | `TQSA_VNDR` (업체 담당자) | `TQSB_VNDRNAM` (근로자 명단) |
| ID / 비밀번호 컬럼 | `VNDR_PSN_ID` / `VNDR_PSN_PWD` | `EMPE_NO` / `VNDR_PSN_PWD` |
| 사용자명 | `VNDR_PSN_NM` | `PNM` |
| 업체명 | `TQSA_VNDR.VNDR_NM` | `TQSA_VNDR`를 LEFT JOIN 해서 `VNDR_NM` |
| 비번 리셋 여부 | `get_PtnAccProp`(회원 + `TQSA_VNDR` UNION). `LoginSuccessHandler:112`에서 호출 | `get_PtnAccPropQs` 별도 구문. **JH Java 어디에서도 호출하지 않는다** |

- B의 QS 로그인은 JH 이전 구조다. B의 QS 구문은 그대로 둔다.
- QH는 JH 구조를 따른다. JH의 QS 업무가 B의 QH로 옮겨졌으므로(화면 복사 qs→qh), JH의 `TQSB_VNDRNAM` 로그인이 B의 `TQHB_VNDRNAM` 로그인이 된다.

### 2-5. DB 상태 (vplus `VPLUS202611A`, 2026-11-17 조회)

| 테이블 | 행 수 | 비고 |
|---|---:|---|
| `TEPZ_MBR_REG` | 2,769 | 협력사 회원 |
| `TQSA_VNDR` | 43 | 기존 QS 계정 |
| `TQHB_VNDRNAM` | 2 | **QH 계정.** 2건 모두 비밀번호(`VNDR_PSN_PWD`)가 있다. 컬럼 24개. PK `SIT_CD, CUST_CD, VNDR_SEQ, EMPE_NO` |
| `TQHA_VNDR` | 3 | QH 업체. 업체명 조인용. PK `SIT_CD, CUST_CD, VNDR_SEQ` |
| `TQSB_VNDRNAM` | — | vplus DB에 없다(JH에만 있음). 어디에도 쓰지 않는다 |

- `TQHB_VNDRNAM`에는 JH 로그인 SQL이 쓰는 컬럼이 모두 있다: `EMPE_NO`, `PNM`, `SIT_CD`, `CUST_CD`, `VNDR_SEQ`, `RSET_YN`, `VNDR_PSN_PWD`, `FAIL_CNT`, `UPD_ID`, `UPD_IP`, `UPD_DTM`, `PWD_NO_CHG_DT`
- `TQHB_VNDRNAM`에는 업무 구분 컬럼이 없다.
- `EMPE_NO`는 테이블 안에서 중복이 없다.
- ID 겹침은 0건이다. `TQHB_VNDRNAM.EMPE_NO`를 `TEPZ_MBR_REG.ID`, `TQSA_VNDR.VNDR_PSN_ID`와 각각 비교했다.

## 3. 원칙

- **기존 로그인(회원·QS)에 문제가 없어야 한다.**
  - 기존 블록과 구문은 지우거나 바꾸지 않는다.
  - 새 SQL에는 vplus DB에 있는 테이블만 쓴다. 없는 테이블을 쓰면 `accountVerify` 전체가 ORA-00942로 실패해 **모든 로그인이 막힌다.**
- **QH 계정은 `TQHB_VNDRNAM`에서만 조회한다.** 권한은 `ROLE_QH_USER`, 모듈은 `'QH'`다. QH 구문은 JH QS 구문을 1:1로 옮긴다. 테이블 하나라 `UNION`이나 PL/SQL 블록이 필요 없다.
- **같은 ID면 `TQHB_VNDRNAM`을 우선한다.** 기존 회원·QS 블록에 "`TQHB_VNDRNAM`에 그 ID가 없을 때만"이라는 조건(`NOT EXISTS`) 한 줄을 붙인다(4-1 우선순위).
- 기존 줄을 바꾸는 대신 다음만 한다.
  - 새 줄 추가: 새 SQL, 새 메서드 선언, 새 `case`, 새 `else if`
  - 조건식 넓히기: `"QS"` → `"QS"` 또는 `"QH"`
  - 예외 두 가지 (`TQHB_VNDRNAM` 우선 규칙 때문)
    - `Account.xml`: 기존 회원·QS 블록에 `NOT EXISTS` 조건 한 줄씩 추가 (`accountVerify`, `get_PtnAccProp`)
    - `LoginFailureHandler`: QH 확인을 맨 앞에 넣는다. 그래서 기존 첫 `if`가 `else if`가 된다(4-4)
- DB는 바꾸지 않는다(DDL·DML 없음).
- 이번 작업은 **공통 Java 수정을 포함한다.** 화면 복사 때 "로그인 관련은 나중에 수정한다"고 미뤄 둔 부분이다(QH_PTN_SOURCE_COPY_PLAN 2-2, 10장).
- 커밋·푸시는 사용자가 지시할 때 `main`에 직접 한다.

## 4. 바꿀 파일과 내용

모두 `VPLUS202611B/ptn/src/main/` 아래다. 줄 번호는 2026-11-17 기준이다.

### 4-1. `resources/sqlmap/mybatis/sys/Account.xml` — QH용 SQL 추가

**변환 규칙:** JH QS 구문을 복사해 다음만 바꾼다. 그 밖의 SQL은 JH와 같다.
- `TQSB_VNDRNAM` → `TQHB_VNDRNAM`, `TQSA_VNDR` → `TQHA_VNDR`(매핑표 `22_dbobj_map.csv`)
- `ROLE_QS_USER` → `ROLE_QH_USER`, `'QS'` → `'QH'`
- 구문 ID `Qs` → `Qh`

| # | B 위치 (줄은 2026-11-17 기준) | JH 원본 (줄) | 추가 내용 |
|---|---|---|---|
| 1 | `accountVerify` | QS 블록 (34–44) | 기존 회원·QS 블록에 우선순위 조건 한 줄씩. QS 블록 뒤(44행 뒤)에 `UNION ALL` + `TQHB_VNDRNAM` 블록 |
| 2 | `get_loginUserInfoQs` 뒤 (86행 뒤) | `get_loginUserInfoQs` (76–91) | 새 구문 `get_loginUserInfoQh` |
| 3 | `get_lastPwQs` 뒤 (108행 뒤) | `get_lastPwQs` (110–113) | 새 구문 `get_lastPwQh` |
| 4 | `get_FailCntQs` 뒤 (180행 뒤) | `get_FailCntQs` (180–185) | 새 구문 `get_FailCntQh` |
| 5 | `get_ExistUsrQs` 뒤 (199행 뒤) | `get_ExistUsrQs` (201–204) | 새 구문 `get_ExistUsrQh` |
| 6 | `set_ChgPswdQs` 뒤 (232행 뒤) | `set_ChgPswdQs` (228–237) | 새 구문 `set_ChgPswdQh` |
| 7 | `set_FailCntQs` 뒤 (280행 뒤) | `set_FailCntQs` (281–285) | 새 구문 `set_FailCntQh` |
| 8 | `set_RsetFailCntQs` 뒤 (294행 뒤) | `set_RsetFailCntQs` (295–299) | 새 구문 `set_RsetFailCntQh` |
| 9 | `get_PtnAccProp` | `get_PtnAccPropQs` (310–314) | 기존 회원·QS 블록에 우선순위 조건 한 줄씩. QS 블록 뒤(314행 뒤)에 `UNION ALL` + `TQHB_VNDRNAM` 블록 |

**B의 QS 전용 구문과 QH 구문 대응** — B `Account.xml`에서 QS 테이블(`TQSA_VNDR`)을 쓰는 구문은 아래 9개가 전부다(전수 확인, 2026-11-17). 모두 `TQHB_VNDRNAM`용 QH 대응이 있다.

| B의 QS 구문 | QH 대응 | 쓰는 곳 |
|---|---|---|
| `accountVerify` (QS 블록) | #1 같은 구문에 `TQHB_VNDRNAM` 블록 추가 | 로그인 검증 |
| `get_loginUserInfoQs` | #2 `get_loginUserInfoQh` | 로그인 성공 – 세션 정보 |
| `get_lastPwQs` | #3 `get_lastPwQh` | 비밀번호 변경 – 기존·새 비밀번호 비교 (4-5의 223행, 261행) |
| `get_FailCntQs` | #4 `get_FailCntQh` | 로그인 실패 |
| `get_ExistUsrQs` | #5 `get_ExistUsrQh` | 로그인 실패 |
| `set_ChgPswdQs` | #6 `set_ChgPswdQh` | 비밀번호 변경 |
| `set_FailCntQs` | #7 `set_FailCntQh` | 로그인 실패 |
| `set_RsetFailCntQs` | #8 `set_RsetFailCntQh` | 로그인 성공 |
| `get_PtnAccProp` (QS 블록) | #9 같은 구문에 `TQHB_VNDRNAM` 블록 추가 | 로그인 성공 – 비번 리셋 여부 |

- 그 밖의 구문은 QS·QH 전용이 아니라서 QH용을 따로 만들지 않는다.
  - 접속 이력 `get_UsrLog`, `get_UsrLastLog`: 공통 로그 테이블 `TCOL_USR_LOG`
  - 비밀번호 이력 `get_PwHist`: 공통 프로시저
  - 그 밖의 구문: 회원·내부 사용자 전용

**우선순위 (`TQHB_VNDRNAM` 우선)**
- 같은 ID가 `TQHB_VNDRNAM`과 회원 또는 QS 테이블에 함께 있으면 `TQHB_VNDRNAM` 행만 남긴다. 그래서 로그인 쿼리가 2행을 돌려줘 로그인이 실패하는 일이 없다.
- 방법: #1과 #9의 기존 회원·QS 블록 `WHERE` 끝에 아래 조건 한 줄을 더한다. 기존 줄은 그대로 둔다.
  ```sql
  AND NOT EXISTS (SELECT 1 FROM TQHB_VNDRNAM WHERE EMPE_NO = #{userId})   -- #9는 #{usrId}
  ```
- **모듈과 관계없이 적용한다.** 회원 블록은 한 블록이 SM·MM·GC·CW를 모두 다룬다. 그래서 조건 한 줄로 모든 회원 모듈에 적용된다. 조건에는 모듈 값을 쓰지 않고, ID가 있는지만 본다.
- 겹치는 ID가 없으면 조건은 항상 참이다. 지금 데이터(겹침 0건)에서는 결과가 이전과 같다(아래 사전 검증).
- 회원과 QS 사이의 겹침에는 우선순위를 두지 않는다. 지금 B와 같은 동작이다.
- #2~#8은 `TQHB_VNDRNAM`만 보므로 조건이 필요 없다.

**#9를 JH처럼 별도 구문(`get_PtnAccPropQs`)으로 두지 않는 이유**
- B는 `LoginSuccessHandler:112`에서 `get_PtnAccProp` 하나만 부르고, 114행에서 결과의 `RSET_YN`을 읽는다.
- QH 블록이 없으면 QH 사용자의 결과가 null이 되어 **NPE로 로그인이 실패한다.**
- JH의 `get_PtnAccPropQs`는 호출하는 곳이 없으므로 옮기지 않는다.

#### 추가할 SQL (초안)

```xml
<!-- #1 accountVerify -->
<!--   (가) 기존 회원 블록: 32행 "AND T1.ID = #{userId}" 아래에 한 줄 추가 -->
           AND NOT EXISTS (SELECT 1 FROM TQHB_VNDRNAM WHERE EMPE_NO = #{userId})
<!--   (나) 기존 QS 블록: 44행 "WHERE VNDR_PSN_ID = #{userId}" 아래에 한 줄 추가 -->
           AND NOT EXISTS (SELECT 1 FROM TQHB_VNDRNAM WHERE EMPE_NO = #{userId})
<!--   (다) QS 블록 뒤, </select> 앞에 추가 -->
     UNION ALL

        SELECT EMPE_NO               AS USERNAME
             , VNDR_PSN_PWD          AS PASSWORD
             , 'true'                AS ENABLED
             , 'true'                AS EXPIRED
             , 'ROLE_QH_USER'        AS AUTHORITY
             , CASE WHEN NVL(FAIL_CNT,0) >= 5 THEN 'false' ELSE 'true' END AS LOCKED
             , 'QH' FNL_CNCT_MDL
          FROM TQHB_VNDRNAM
         WHERE EMPE_NO = #{userId}

<!-- #2 -->
    <!-- 안전(QH) -->
    <select id="get_loginUserInfoQh" parameterType="String" resultType="map" >
        SELECT T1.EMPE_NO     AS USR_ID  -- 사용자 ID
             , T1.PNM         AS USR_NM  -- 사용자 명
             , T1.SIT_CD                 -- 현장코드
             , T1.CUST_CD                -- 업체코드
             , T2.VNDR_NM                -- 업체명
             , T1.VNDR_SEQ               -- 업체순번
             , T1.RSET_YN     AS RSET_YN -- 비밀번호 초기화 여부
          FROM TQHB_VNDRNAM T1
    LEFT OUTER JOIN TQHA_VNDR T2
                 ON T1.SIT_CD = T2.SIT_CD
                AND T1.CUST_CD = T2.CUST_CD
                AND T1.VNDR_SEQ = T2.VNDR_SEQ
                AND T1.EMPE_NO = T2.VNDR_PSN_ID
         WHERE EMPE_NO = #{userId}
    </select>

<!-- #3 -->
    <!-- 이전 패스워드 조회(안전 QH) -->
    <select id="get_lastPwQh" parameterType="map" resultType="String" >
        SELECT CASE WHEN (#{PSWD} = (SELECT VNDR_PSN_PWD FROM TQHB_VNDRNAM WHERE EMPE_NO = #{USR_ID}))
                    THEN 'Y' ELSE 'N' END AS EQUAL_YN FROM DUAL
    </select>

<!-- #4 -->
    <!-- 로그인 실패 횟수 조회, 비밀번호 NULL 여부 조회 (안전 QH) -->
    <select id="get_FailCntQh" parameterType="map" resultType="map">
        SELECT NVL(FAIL_CNT, 0) AS FAIL_CNT
              ,CASE WHEN VNDR_PSN_PWD IS NULL THEN 'Y' ELSE 'N' END AS PWD_IS_NULL
          FROM TQHB_VNDRNAM
         WHERE EMPE_NO = #{usrId}
    </select>

<!-- #5 -->
    <!-- 사용자 아이디 존재 여부 (안전 QH) -->
    <select id="get_ExistUsrQh" parameterType="map" resultType="String">
        SELECT CASE WHEN (#{usrId} = (SELECT EMPE_NO FROM TQHB_VNDRNAM WHERE EMPE_NO = #{usrId}))
                    THEN 'Y' ELSE 'N' END AS EXIST_USR FROM DUAL
    </select>

<!-- #6 -->
    <!-- 내정보관리 : 비밀번호 변경 (안전 QH) -->
    <update id="set_ChgPswdQh" parameterType="map">
        UPDATE TQHB_VNDRNAM
           SET VNDR_PSN_PWD = #{PSWD}
             , UPD_ID = #{WRK_ID}
             , UPD_IP = #{WRK_IP}
             , UPD_DTM = SYSDATE
             , RSET_YN = 0
             , PWD_NO_CHG_DT = TO_CHAR(SYSDATE, 'YYYYMMDD')
         WHERE EMPE_NO = #{WRK_ID}
    </update>

<!-- #7 -->
    <!-- 로그인 실패 횟수 저장 (안전 QH) -->
    <update id="set_FailCntQh" parameterType="map">
         UPDATE TQHB_VNDRNAM
            SET FAIL_CNT = NVL(FAIL_CNT, 0) + 1
          WHERE EMPE_NO = #{usrId}
    </update>

<!-- #8 -->
    <!-- 로그인 성공 시 로그인 실패 횟수 초기화 (안전 QH) -->
    <update id="set_RsetFailCntQh" parameterType="map">
         UPDATE TQHB_VNDRNAM
            SET FAIL_CNT = 0
          WHERE EMPE_NO = #{usrId}
    </update>

<!-- #9 get_PtnAccProp -->
<!--   (가) 기존 회원 블록: 308행 "WHERE ID = #{usrId}" 아래에 한 줄 추가 -->
            AND NOT EXISTS (SELECT 1 FROM TQHB_VNDRNAM WHERE EMPE_NO = #{usrId})
<!--   (나) 기존 QS 블록: 314행 "WHERE VNDR_PSN_ID = #{usrId}" 아래에 한 줄 추가 -->
           AND NOT EXISTS (SELECT 1 FROM TQHB_VNDRNAM WHERE EMPE_NO = #{usrId})
<!--   (다) QS 블록 뒤, </select> 앞에 추가 -->
        UNION ALL

        SELECT RSET_YN
          FROM TQHB_VNDRNAM
         WHERE EMPE_NO = #{usrId}
```

#### SELECT 구문 사전 검증 (vplus DB, 조회만, 2026-11-17)

- 실행한 구문: #1~#5와 #9의 SELECT. 바인드 변수로 바꿔 실제로 실행했다.
  - #1과 #9는 기존 회원·QS 블록과 우선순위 조건까지 포함한 전체를 실행했다.
- 계정 종류마다 대표 ID 1개로 실행했다.

| 계정 종류 | #1 결과 | #2 | #3 (틀린 비번) | #4 | #5 | #9 |
|---|---|---|---|---|---|---|
| QH `TQHB_VNDRNAM` | 1행, `ROLE_QH_USER`, `QH` | 1행, **업체명 NULL** | `N` | 1행 | `Y` | 1행 |
| QS `TQSA_VNDR` | 1행, `ROLE_QS_USER`, `QS` (기존과 같음) | 0행 | `N` | 0행 | `N` | 1행 |
| 회원 `TEPZ_MBR_REG` | 1행, `ROLE_CO`, 기존 모듈 (기존과 같음) | 0행 | `N` | 0행 | `N` | 1행 |
| `TQHA_VNDR` 담당자 | 0행 (로그인 대상 아님) | 0행 | `N` | 0행 | `N` | 0행 |
| 없는 ID | 0행 | 0행 | `N` | 0행 | `N` | 0행 |

- #6~#8(UPDATE)은 DML이므로 실행하지 않았다. 7장에서 실제 로그인으로 확인한다. JH 구문과 같은 단순 UPDATE다.
- 같은 ID가 겹치는 경우는 DB에 그런 데이터가 없어 실행해 보지 못했다(7장, 8-2 결정 3).

#### Account.xml에서 주의할 점

| # | 내용 |
|---|---|
| a | **업체명이 비어 있을 수 있다.** JH 조인 조건에 `T1.EMPE_NO = T2.VNDR_PSN_ID`가 있다. 그래서 근로자가 업체 담당자 본인이 아니면 `VNDR_NM`이 NULL이다. 지금 계정 2건 모두 NULL이다. 이 조건을 빼면 2건 모두 업체가 1건씩 연결된다(PK `SIT_CD, CUST_CD, VNDR_SEQ`로 조인). JH와 같게 둘지는 8-2 결정 2에서 정한다 |
| b | **세션 `VNDR_CD`.** `LoginSuccessHandler:132`는 `rst.get("VNDR_CD")`를 세션에 넣는다. 그런데 B의 QS 구문도, JH 구문(#2)도 `VNDR_CD`를 돌려주지 않는다. 그래서 지금 QS도 이 값이 문자열 `"null"`이다. QH도 같아진다. 이번 범위에서는 고치지 않고 보고만 한다 |
| c | `#{PSWD}`는 JH와 같이 typeHandler 없이 받는다. 해시는 호출하는 쪽(`AccountServiceImpl`)에서 한다 |
| d | **반영은 9개 파일을 함께 한다.** Java 쪽 선언(4-2)이 없어도 XML만 추가해서는 오류가 나지 않는다. 다만 #1을 넣으면 QH 계정이 로그인을 시도할 수 있게 된다. 4-3~4-6 없이 #1만 반영하면 QH 로그인이 중간에 실패한다 |
| e | **`TQHA_VNDR` 담당자 계정(3건)은 로그인할 수 없다.** QH 계정은 `TQHB_VNDRNAM`에서만 조회하기 때문이다(1장 핵심 결정) |
| f | **같은 ID가 `TQHB_VNDRNAM`과 회원·QS에 함께 있으면 QH로 로그인한다.** 그 ID로 회원·QS 계정(비밀번호 포함)에는 로그인할 수 없게 된다. 의도한 결과다(1장 핵심 결정) |

### 4-2. `java/com/hs/partner/sys/security/service/impl/AccountRepository.java` — 선언 7줄 추가

- QS 선언 바로 아래에 `Qh` 선언을 추가한다. 시그니처는 QS 것과 같다.

| 추가할 선언 | 위치 (QS 선언 줄 아래) |
|---|---:|
| `get_loginUserInfoQh` | 57 |
| `get_lastPwQh` | 86 |
| `get_FailCntQh` | 129 |
| `get_ExistUsrQh` | 150 |
| `set_ChgPswdQh` | 183 |
| `set_FailCntQh` | 210 |
| `set_RsetFailCntQh` | 225 |

### 4-3. `java/com/hs/partner/sys/security/handler/LoginSuccessHandler.java`

| 줄 | 지금 | 바꾼 뒤 |
|---|---|---|
| 97–101 | `if (QS) set_RsetFailCntQs else set_RsetFailCnt` | `else if(sysTp.equals("QH")) rpsAcct.set_RsetFailCntQh(parm);` 추가 |
| 127 | `case "QS":` | `case "QS": case "QH":` (세션에 넣는 값이 같으므로 같은 블록을 쓴다) |
| 219 | `case "QS": return rpsAcct.get_loginUserInfoQs(map);` | 아래에 `case "QH": return rpsAcct.get_loginUserInfoQh(map);` 추가 |

### 4-4. `java/com/hs/partner/sys/security/handler/LoginFailureHandler.java`

- 지금 확인 순서는 회원(`get_ExistUsr`, 110행) → QS(`get_ExistUsrQs`, 124행) → 계정없음이다.
- **QH 확인을 맨 앞에 둔다.**
  - 110행 앞에 `if (rpsAcct.get_ExistUsrQh(parm).equals("Y")) { … }` 블록을 넣는다.
  - 기존 110행 `if`는 `} else if`로 이어 붙인다. 기존 회원·QS 블록 안의 내용은 바꾸지 않는다.
  - 이유: 우선순위(`TQHB_VNDRNAM` 우선)를 실패 처리에도 맞추기 위해서다. 같은 ID가 회원과 `TQHB_VNDRNAM`에 함께 있을 때 회원을 먼저 확인하면, 로그인은 QH로 시도했는데 실패 횟수는 회원 쪽에 올라간다.
- 블록 안의 내용은 QS 블록(124–136행)과 같다. `get_FailCntQh`, `set_FailCntQh`를 쓴다.
- 이 블록이 없으면 QH 계정은 비밀번호를 틀려도 "계정없음"(`S0150`)이 나오고, 실패 횟수와 잠금이 동작하지 않는다.

### 4-5. `java/com/hs/partner/sys/security/service/impl/AccountServiceImpl.java` (`set_ChgPswd`)

| 줄 | 지금 | 바꾼 뒤 |
|---|---|---|
| 223–227 | `if (QS) get_lastPwQs else get_lastPw` | `else if (stp.equals("QH")) equalYn = rpsAcct.get_lastPwQh(tmpMap);` 추가 (입력한 **기존** 비밀번호 확인) |
| 261 | `equalYn = rpsAcct.get_lastPw(tmpMap);` (분기 없음) | QH일 때 `get_lastPwQh`를 쓰게 분기한다 (**새** 비밀번호가 지금 비밀번호와 같은지 확인) |
| 271–275 | `if (QS) set_ChgPswdQs else set_ChgPswd` | `else if (stp.equals("QH")) rpsAcct.set_ChgPswdQh(map);` 추가 |

- **261행 (추가 확인, 2026-11-17)**
  - 지금은 모듈과 관계없이 회원 테이블용 `get_lastPw`(`TEPZ_MBR_REG`, `BZMN_NO`로 조회)를 부른다.
  - QS·QH 사용자는 회원 테이블에 행이 없으므로 결과가 늘 `N`이다. 그래서 "새 비밀번호 = 지금 비밀번호" 검사가 동작하지 않는다.
  - QH는 `TQHB_VNDRNAM`을 보도록 분기한다. 제안 형태:
    ```java
    if (stp.equals("QH")) { equalYn = rpsAcct.get_lastPwQh(tmpMap); }
    else { equalYn = rpsAcct.get_lastPw(tmpMap); }
    ```
  - QS도 같은 문제가 있다(기존 동작). 범위 밖이므로 고치지 않고 보고만 한다(8-2 결정 4).
- `loadUserByUsername`(91–120행)은 바꾸지 않는다. `accountVerify`가 `'QH'`를 돌려주면 세션 `sysTp`에 그대로 들어간다.
- 같은 파일의 `accountChangePwd`(319행)도 `get_lastPw`를 쓴다. 이 메서드는 내부 사용자 테이블 `TCOZ_USR_INFO`용 비밀번호 초기화라 QS·QH와 관계없다. 바꾸지 않는다.

### 4-6. `java/com/hs/partner/sys/config/SecurityConfiguration.java`

- 169행 `.antMatchers("/qs*/**").hasRole("QS_USER")` 아래에 `.antMatchers("/qh*/**").hasRole("QH_USER")`를 추가한다.
- **이 줄이 없으면 협력사 회원 등 로그인한 누구나 QH 화면에 들어갈 수 있다**(`anyRequest().authenticated()`).

### 4-7. `java/com/hs/partner/co/main/web/MainController.java`

- 201행 `if (!moduleInfo.equals("QS")) { svcAcct.set_LoginModule(…); }`의 조건에 `&& !moduleInfo.equals("QH")`를 더한다.
- QS처럼 QH도 `TEPZ_MBR_REG.FNL_CNCT_MDL`을 갱신하지 않는다. 지금도 대상 행이 없어 결과는 같지만, 불필요한 UPDATE를 막는다.

### 4-8. `webapp/WEB-INF/jsp/index.jsp`

- 63행 `<c:if test="${sysTp != 'QS'}">`를 `${sysTp != 'QS' and sysTp != 'QH'}`로 바꾼다. QH 사용자에게도 모듈 변경 셀렉트를 숨긴다.
- 84행의 QH 메뉴 분기(`navQH.jsp`)는 화면 복사 때 이미 추가했다.

### 4-9. `webapp/WEB-INF/jsp/co/main/pwdChgPopup.jsp` (내정보관리·비밀번호 변경 팝업)

| 줄 | 지금 | 바꾼 뒤 |
|---|---|---|
| 35 | `<c:if test="${SYS_TP eq 'QS'.toString()}">` | `${SYS_TP eq 'QS'.toString() or SYS_TP eq 'QH'.toString()}` |
| 152 | `<c:if test="${SYS_TP ne 'QS'.toString()}">` | `${SYS_TP ne 'QS'.toString() and SYS_TP ne 'QH'.toString()}` |
| 447, 469, 486, 495 | `if ("${SYS_TP}" == "QS")` | `if ("${SYS_TP}" == "QS" \|\| "${SYS_TP}" == "QH")` |
| 537 | `if ("${SYS_TP}" != "QS")` | `if ("${SYS_TP}" != "QS" && "${SYS_TP}" != "QH")` |

- 이 팝업은 QS 사용자에게 안전담당자용 비밀번호 변경 폼(`frmChgPswdQs`)을 보여 준다.
- QH 사용자도 같은 폼을 쓰고, 저장은 4-5의 `set_ChgPswdQh`로 간다.

### 4-10. 바꾸지 않는 것

| 파일 | 이유 |
|---|---|
| `login.jsp` | 모듈 선택이 없다. ID로 구분한다(2-1) |
| `AccountController.java` | `SYS_TP`를 그대로 서비스로 넘긴다. 분기는 4-5에서 한다 |
| `ChangeModuleTagLib`, `ChangeCorpTagLib` | 회원용이다. QS·QH 사용자에게는 보이지 않는다(4-8) |
| `CustomAuthFilter` | QS 분기가 없다(확인함) |
| 기존 QS SQL·코드 | 3장 원칙 (우선순위 조건 한 줄은 예외) |

## 5. 위험과 주의

| # | 내용 | 대응 |
|---|---|---|
| 1 | **ID 중복**<br>- `TQHB_VNDRNAM`과 회원·QS가 겹치면 `TQHB_VNDRNAM`으로 로그인된다(4-1 우선순위).<br>- 회원과 QS가 겹치면 로그인이 실패한다. 지금 B와 같은 동작이다 | 지금은 겹침 0건이다 |
| 2 | QS와 QH를 모두 쓰는 사람은 계정이 2개 필요하다. 계정 구분이 테이블로 정해지기 때문이다. 모듈 전환(`<tag:ChangeModule>`)으로 QS↔QH를 오갈 수 없다 | 정해짐(8-1) |
| 3 | 권한 줄(4-6)이 빠지면 QH 화면이 모든 로그인 사용자에게 열린다 | 7장 검증 항목 |
| 4 | 공통 로그인 코드와 기존 회원·QS SQL(조건 한 줄)을 고친다. 그래서 기존 로그인에 영향이 갈 수 있다 | 7장에서 회원, QS, QH 계정으로 각각 로그인을 확인한다 |

## 6. 실행 절차

| 단계 | 내용 |
|---|---|
| 1. 사전 확인 | B 작업 트리가 깨끗한지 본다. ID 겹침 조회(2-5)를 다시 한다 |
| 2. 수정 | 4장의 9개 파일을 고친다. `Account.xml`, `AccountRepository.java`, `LoginSuccessHandler.java`, `LoginFailureHandler.java`, `AccountServiceImpl.java`, `SecurityConfiguration.java`, `MainController.java`, `index.jsp`, `pwdChgPopup.jsp` |
| 3. 컴파일·기동 | `mvn -DskipTests compile`, 8088 기동 |
| 4. 검증 | 7장 |
| 5. 보고 | 바꾼 파일, diff, 검증 결과를 보고한다. 커밋은 지시가 있을 때 `main`에 직접 한다 |

## 7. 검증

| 항목 | 기준 |
|---|---|
| diff | 9개 파일만 바뀐다. 기존 줄 변경은 조건식 넓히기, 우선순위 조건 한 줄, `LoginFailureHandler`의 `if`→`else if`뿐이다 |
| 컴파일·기동 | 성공. 매퍼 오류 없음 |
| QH 로그인 | `TQHB_VNDRNAM` 계정(`EMPE_NO`)으로 로그인한다. 다음이 모두 맞아야 한다.<br>- QH 메뉴(`navQH.jsp`)가 나온다<br>- 모듈 변경 셀렉트는 보이지 않는다<br>- 대시보드(`/qhz/dashBoardQs`)가 열린다<br>- 세션 `SYS_TP`=`QH`이고, `CUST_CD`·`VNDR_SEQ`·`SIT_CD`가 채워진다 |
| QH 화면 | 대표 화면(`/qha/riskSchdMngCo`, `/qha/addRiskLstCo`, `/qhb/riskDgrMainList` 등)에서 조회가 된다 |
| 권한 | QH 계정은 `/qs*` 화면에서 403이 나온다. QS 계정과 협력사 회원은 `/qh*` 화면에서 403이 나온다 |
| 실패 횟수 | QH 계정으로 비밀번호를 틀린다.<br>- `TQHB_VNDRNAM.FAIL_CNT`가 오르고 "계정입력"(`S0100`)이 나온다<br>- 5회 틀리면 잠긴다<br>- 로그인에 성공하면 0으로 초기화된다 |
| 비밀번호 변경 | QH 계정의 내정보관리 팝업에서 안전담당자용 폼이 나온다. 바꾼 비밀번호가 `TQHB_VNDRNAM`에 저장된다. `TQSA_VNDR`·`TQHA_VNDR`은 바뀌지 않는다 |
| 비번 리셋 | QH 로그인 후 NPE가 없다. `get_PtnAccProp`(#9)가 `TQHB_VNDRNAM.RSET_YN`을 돌려준다 |
| 우선순위 | 같은 ID가 `TQHB_VNDRNAM`과 회원·QS에 함께 있으면 QH로 로그인된다. 실패 횟수도 `TQHB_VNDRNAM`에 반영된다. 검증 방법은 8-2 결정 3 |
| 기존 로그인 | 협력사 회원 계정과 QS 계정의 로그인·메뉴·비밀번호 변경이 이전과 같다 |

- QH 계정의 비밀번호는 DB에 SHA-256으로 저장된다.
- 테스트용 계정과 비밀번호는 사용자에게 받는다. DB 값은 바꾸지 않는다.

## 8. 결정 사항

### 8-1. 정해진 사항 (사용자 지시, 2026-11-17)

| # | 항목 | 정해진 내용 |
|---|---|---|
| 1 | 참고 원본 | JH `Account.xml`의 QS 로그인 구문 |
| 2 | QH 계정 테이블 | `TQHB_VNDRNAM`에서만 조회한다. `TQHA_VNDR`는 업체명 조인에만 쓴다 |
| 3 | 기존 로그인 | 회원·QS 로그인에 문제가 없어야 한다 |
| 4 | ID 중복 | 같은 ID가 `TQHB_VNDRNAM`과 다른 테이블에 함께 있으면 `TQHB_VNDRNAM`을 우선한다. 모듈 구분 없이 ID가 있는지만 본다. 다른 테이블의 계정으로는 그 ID로 로그인할 수 없다. 이 결과는 의도한 것이다 |
| 5 | QS·QH 겸용 | 계정 구분은 테이블로 정해진다(구분 값 없음). 그래서 한 계정으로 QS와 QH를 오갈 수 없다 |

### 8-2. 남은 결정

| # | 항목 | 내용 | 제안 |
|---|---|---|---|
| 결정 1 | 기존 `qs` 화면의 QH 사용자 접근 | QH 계정은 `ROLE_QH_USER`만 받는다. 그래서 `/qs*`는 403이 나온다 | 제안대로 막는다 |
| 결정 2 | QH 로그인 업체명 (4-1 a) | JH 조인 조건(`EMPE_NO = VNDR_PSN_ID`) 때문에 지금 계정 2건 모두 업체명이 NULL이다. 이 조건을 빼면 2건 모두 업체명이 채워진다 | JH와 같게 둔다. 화면에 업체명이 필요하면 조건을 빼는 쪽으로 바꾼다 |
| 결정 3 | 우선순위 검증 방법 (7장) | 겹치는 ID 데이터가 DB에 없다 | SQL 검토로 대신한다. 테스트 데이터를 만들려면 DML 승인이 필요하다 |
| 결정 4 | QS의 "새 비밀번호 = 지금 비밀번호" 검사 (4-5 261행) | QS도 회원 테이블을 보고 있어 이 검사가 동작하지 않는다(기존 동작) | 이번에는 QH만 고친다. QS를 고칠지는 따로 정한다 |

- 8-2의 결정 1~4는 제안대로 적용했다(2026-11-17, 개발 진행 지시).

## 9. 되돌리기

- 9개 파일을 `git checkout -- <파일>`(커밋 전) 또는 `git revert <커밋>`(커밋 후)로 되돌린다.
- DB는 바꾸지 않으므로 되돌릴 것이 없다.

## 10. 실행 결과 (2026-11-17)

### 10-1. 바꾼 파일 (VPLUS202611B, 커밋 `40d22a7`)

`git diff --stat` 기준 9개 파일, +130 / −11.

| 파일 | 변경 |
|---|---|
| `resources/sqlmap/mybatis/sys/Account.xml` | +86. 4-1 #1~#9 그대로. 기존 회원·QS 블록에 우선순위 조건 4줄(`accountVerify` 2, `get_PtnAccProp` 2). 삭제 줄 없음 |
| `.../service/impl/AccountRepository.java` | +7. `Qh` 선언 7개 |
| `.../handler/LoginSuccessHandler.java` | +4. `set_RsetFailCntQh` 분기, `case "QH":`(세션), `case "QH": get_loginUserInfoQh` |
| `.../handler/LoginFailureHandler.java` | +14 / −1. QH 확인 블록을 맨 앞에 추가. 기존 `if (existUsr…)`가 `else if`가 됨 |
| `.../service/impl/AccountServiceImpl.java` | +9 / −1. 223행·271행 QH 분기, 261행 QH 분기(기존 줄은 들여쓰기만 바뀜) |
| `.../config/SecurityConfiguration.java` | +1. `.antMatchers("/qh*/**").hasRole("QH_USER")` |
| `.../co/main/web/MainController.java` | 1줄. `&& !moduleInfo.equals("QH")` |
| `webapp/WEB-INF/jsp/index.jsp` | 1줄. `sysTp != 'QS' and sysTp != 'QH'` |
| `webapp/WEB-INF/jsp/co/main/pwdChgPopup.jsp` | 7줄. 35, 152, 447, 469, 486, 495, 537행 조건에 QH 추가 |

- 줄바꿈은 9개 파일 모두 CRLF로 유지했다.
- `Account.xml`의 기존 줄 끝 공백(`SELECT RSET_YN `, 공백 줄)도 원래대로 유지했다.

### 10-2. 검증

| 항목 | 결과 |
|---|---|
| 컴파일 | `mvn -q -DskipTests compile` 성공 (EXIT=0) |
| 기동 | 8088, `loc` 프로필. `Started Application in 13.2 seconds`. 매퍼 오류 없음 |
| 없는 ID 로그인 | `nouser_zz9`로 `/accountVerify` POST(CSRF 포함) → 200(로그인 화면) |
| | 로그상 실행 순서: `accountVerify`(우선순위 조건 포함) → `LoginFailureHandler` → `get_ExistUsrQh` → `get_ExistUsr` → `get_ExistUsrQs`. ERROR·Exception 없음 |
| SELECT 사전 검증 | 4-1 표와 같음 (QH 1행, QS·회원 이전과 같음) |
| DB 변경 | 없음. 실제 계정으로 비밀번호를 틀리는 시험은 `FAIL_CNT`를 바꾸므로 하지 않았다 |

### 10-3. 남은 검증 (테스트 계정 필요)

- 7장의 QH 로그인, QH 화면, 권한(403), 실패 횟수, 비밀번호 변경, 비번 리셋, 기존 회원·QS 로그인 항목.
- 이 항목들은 실제 비밀번호를 알아야 하거나 DB 값(`FAIL_CNT`, 비밀번호)을 바꾼다. 그래서 사용자 테스트 계정·승인이 있을 때 한다.

### 10-4. 범위 밖 보고

- QS의 "새 비밀번호 = 지금 비밀번호" 검사가 동작하지 않는다(4-5 261행, 8-2 결정 4). 고치지 않았다.
- 세션 `VNDR_CD`가 QS·QH 모두 문자열 `"null"`이다(4-1 b). 고치지 않았다.
