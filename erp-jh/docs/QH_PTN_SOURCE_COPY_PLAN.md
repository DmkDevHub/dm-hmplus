# JH_PTN → VPLUS202611B 소스 복사 계획 (qs → qh)

> 작성일: 2026-11-17 · 원본: `JH_PTN/src/main` (패키지 `com.jh.partner`) · 대상: `VPLUS202611B/ptn/src/main` (패키지 `com.hs.partner`)
> 관련: [QH_SOURCE_COPY_PLAN.md](QH_SOURCE_COPY_PLAN.md)(ERP 쪽 같은 작업, 규칙의 출처), [QH_MIGRATION_RESULT.md](QH_MIGRATION_RESULT.md)(DB 객체 QH 이관), [QS_COMCODE_COPY_PLAN.md](QS_COMCODE_COPY_PLAN.md)(공통코드 QS→QH)
> 1~9장의 수치는 두 소스 트리를 읽기만 해서 확인한 값이다(계획 시점).
> **상태: 실행 완료(2026-11-17).** 새 파일 72개를 복사·변환했고, 공통 파일 4개에 줄을 추가했다. 파일 검증, 컴파일, 기동을 통과했다. 커밋 전이다. 결과는 12장에 있다.

## 1. 목적

JH_PTN(협력사 포털)의 QS 소스를 **이름의 `qs`를 `qh`로 바꿔** VPLUS202611B에 복사한다. 대상은 다음 두 가지다.
- `qs` 디렉토리와 하위 파일
- `qs` 밖의 QS 파일 4개: `qs.lib.js`, `navQS.jsp`, `QsCodeFind.xml`, `QsSelectBind.xml` (사용자 지시, 2026-11-17)

배경은 다음과 같다.
- DB 쪽(테이블 `TQHA_*`·`TQHB_*`, 프로시저 `PQHA_*`·`PQHB_*`, 함수 `FQHA_*`·`FQHZ_*`, 공통코드 `QH*`)은 이미 vplus DB(`VPLUS202611A` 스키마)에 있다.
- VPLUS202611B의 `loc` 프로필도 이 스키마에 접속한다.
- 이번 작업은 그 DB 객체를 쓰는 **협력사 화면·서버 소스**를 추가하는 것이다.

## 2. 원칙

[AGENTS.md](../AGENTS.md)의 이식 규칙과 ERP 작업(QH_SOURCE_COPY_PLAN 2장)의 원칙을 따른다.

### 2-1. 새 파일

- 새 파일은 3장의 경로에만 만든다(72개). 변환 규칙(5장)은 이 새 파일에만 적용한다.
- 새 경로는 기존 파일과 겹치지 않는다. B에는 다음이 하나도 없다(확인함).
  - `qh` 경로, `Qh`로 시작하는 클래스
  - `qh.lib.js`, `navQH.jsp`, `QhCodeFind.xml`, `QhSelectBind.xml`
- 같은 경로에 파일이 있으면 덮어쓰지 않고 멈춘다.

### 2-2. B의 기존 파일 (사용자 지시, 2026-11-17)

| 구분 | 처리 | 해당 파일 |
|---|---|---|
| 기존 QS 소스 | **수정하지 않는다.** 문제가 있어도 보고만 한다 | `java/com/hs/partner/qs`, `sqlmap/mybatis/qs`, `jsp/qs`, `qs.lib.js`, `navQS.jsp`, `QsCodeFind.xml`, `QsSelectBind.xml` |
| **공통 Java** | **수정하지 않는다.** 예외는 `FindCodeRepository.java` 하나다: QH 메서드 선언 3줄을 **추가만** 한다(5-6-3) | 수정하지 않는 파일: `FindCodeServiceImpl.java`, `FindCodeController.java`, `ibEnumTagLib.java`, `SelectBoxTagLib.java` 등 |
| **로그인 관련 Java** | **이번에는 수정하지 않는다. 나중에 별도로 수정한다**(사용자 지시, 2026-11-17) | `LoginSuccessHandler.java`, `AccountServiceImpl.java`, `MainController.java` |
| **공통 JSP·JS** | QH 연결에 필요한 **줄 추가는 한다.** 기존 줄은 바꾸거나 지우지 않는다 | 5-6-3의 파일: `scriptInclude.jsp`, `app.createcodefinder.js`, `index.jsp` |

### 2-3. 그 밖

- JH_PTN은 읽기만 한다.
- 원본의 인코딩과 줄바꿈을 그대로 지킨다. 원본 72개 파일 모두 UTF-8(BOM 없음), CRLF다(확인함). 줄을 추가하는 공통 파일도 그 파일의 인코딩·줄바꿈을 따른다.
- git 커밋과 push는 사용자가 지시할 때만 한다. 현재 B의 작업 트리는 깨끗하다(확인함).

## 3. 복사 대상과 경로

JH_PTN의 `qs` 디렉토리 68개(3-1)와 `qs` 밖의 QS 파일 4개(3-2), 합계 **72개**다.

### 3-1. `qs` 디렉토리 (68개)

| # | 원본 (`JH_PTN/src/main/` 아래) | 대상 (`VPLUS202611B/ptn/src/main/` 아래) | 파일 수 |
|---|---|---|---:|
| 1 | `java/com/jh/partner/qs/qsa` | `java/com/hs/partner/qh/qha` | 20 |
| 2 | `java/com/jh/partner/qs/qsb` | `java/com/hs/partner/qh/qhb` | 12 |
| 3 | `java/com/jh/partner/qs/qsc` | `java/com/hs/partner/qh/qhc` | 4 |
| 4 | `java/com/jh/partner/qs/qsz` | `java/com/hs/partner/qh/qhz` | 4 |
| 5 | `resources/sqlmap/mybatis/qs/qsa` | `resources/sqlmap/mybatis/qh/qha` | 5 |
| 6 | `resources/sqlmap/mybatis/qs/qsb` | `resources/sqlmap/mybatis/qh/qhb` | 3 |
| 7 | `resources/sqlmap/mybatis/qs/qsc` | `resources/sqlmap/mybatis/qh/qhc` | 1 |
| 8 | `resources/sqlmap/mybatis/qs/qsz` | `resources/sqlmap/mybatis/qh/qhz` | 1 |
| 9 | `webapp/WEB-INF/jsp/qs/qsa` | `webapp/WEB-INF/jsp/qh/qha` | 9 |
| 10 | `webapp/WEB-INF/jsp/qs/qsb` | `webapp/WEB-INF/jsp/qh/qhb` | 4 |
| 11 | `webapp/WEB-INF/jsp/qs/qsc` | `webapp/WEB-INF/jsp/qh/qhc` | 2 |
| 12 | `webapp/WEB-INF/jsp/qs/qsz` | `webapp/WEB-INF/jsp/qh/qhz` | 3 |
| | | **합계** | **68** |

- 하위 디렉토리(`rps`, `svc`, `svc/impl`, `web`)는 그대로 둔다.
- `qsb`(위험성평가 차수·점검·목록)는 B의 기존 `qs`에 없는 기능이다. 나머지(`qsa`, `qsc`, `qsz`)는 B의 `qs`에 같은 이름의 파일이 있다.

### 3-2. `qs` 밖의 QS 파일 (4개)

| # | 원본 (`JH_PTN/src/main/` 아래) | 대상 (`VPLUS202611B/ptn/src/main/` 아래) | 줄 수 | 하는 일 |
|---|---|---|---:|---|
| 13 | `webapp/resources/js/module/qs.lib.js` | `webapp/resources/js/module/qh.lib.js` | 252 | 코드찾기 그리드 정의(`qsfnCodeFindInit`) |
| 14 | `webapp/WEB-INF/jsp/include/navQS.jsp` | `webapp/WEB-INF/jsp/include/navQH.jsp` | 20 | 협력사 안전 메뉴(정적 링크) |
| 15 | `resources/sqlmap/mybatis/co/codefind/QsCodeFind.xml` | `resources/sqlmap/mybatis/co/codefind/QhCodeFind.xml` | 240 | 코드찾기 SQL |
| 16 | `resources/sqlmap/mybatis/co/selectbox/QsSelectBind.xml` | `resources/sqlmap/mybatis/co/selectbox/QhSelectBind.xml` | 58 | 셀렉트박스 SQL |

- 4개 모두 B에 같은 이름의 QS 파일이 이미 있다. B 파일은 그대로 두고 옆에 Qh 파일을 새로 만든다.
- B의 QS 파일이 아니라 **JH_PTN 원본**으로 만든다. B 파일에는 JH_PTN 화면이 쓰는 항목 일부가 없기 때문이다.
  - B의 `QsCodeFind.xml`(177줄)에는 `VNDR_INFO_SITE`, `VNDR_INFO_TRADE` 항목이 없다.
  - B의 `QsSelectBind.xml`(29줄)에는 `QS_CHRC_VAL`, `QS_CTPUNT`, `QS_CTP_CD` 항목이 없다.
- 새 파일이 실제로 동작하는 범위는 5-6과 8장에 정리했다.

## 4. 왜 경로만 바꿔서는 안 되는가

B의 기존 `qs` 소스는 JH_PTN `qs`와 거의 같은 코드다. 패키지만 `com.jh.partner` → `com.hs.partner`로 다르다. 경로만 바꿔 복사하면 아래 세 곳에서 기존 소스와 부딪힌다.

| 충돌 | 내용 | 결과 |
|---|---|---|
| Spring 빈 이름 | 클래스 40개 중 **28개**가 B의 기존 클래스와 이름이 같다(`AddRiskCoController`, `QsMainService` 등). B는 기본 빈 이름 규칙을 쓴다. `@MapperScan(basePackages = "com.hs.partner", annotationClass = Repository.class)`도 같다 | 기동 시 `ConflictingBeanDefinitionException`으로 서버가 뜨지 않는다 |
| URL | 클래스의 `@RequestMapping` 값 `"/qsa"`(5개), `"/qsc"`, `"/qsz"`가 B 기존 컨트롤러와 같다. 메서드 URL도 대부분 같다 | 기동 시 `Ambiguous mapping` 오류 |
| DB 객체 | 소스가 `PQSA_*`, `TQSA_*` 등 **QS 이름**을 부른다 | QH 객체가 아니라 vplus 기존 QS 객체를 쓴다 |

그래서 복사하면서 5장의 규칙으로 소스 내용도 바꾼다. **규칙은 ERP 작업에서 확정한 것과 같다.**

## 5. 변환 규칙

### 5-1. Java 패키지와 import (`.java`, `.xml`)

| 원본 | 바꾼 값 |
|---|---|
| `com.jh.partner.qs.qsa` | `com.hs.partner.qh.qha` |
| `com.jh.partner.qs.qsb` | `com.hs.partner.qh.qhb` |
| `com.jh.partner.qs.qsc` | `com.hs.partner.qh.qhc` |
| `com.jh.partner.qs.qsz` | `com.hs.partner.qh.qhz` |
| 그 밖의 `com.jh.partner.` | `com.hs.partner.` |

- `qs` 밖을 가리키는 import는 6종이다. 6종 모두 B에 같은 클래스가 있다(확인함).
  - `co.file.svc.FileService`, `co.file.vo.FileInfoVO`
  - `sys.base.BaseController`, `sys.base.BaseService`
  - `sys.security.service.AccountVO`, `sys.utility.BaseUtils`
- 매퍼 XML의 `namespace` 10개도 같은 규칙으로 바꾼다.
- `QhCodeFind.xml`·`QhSelectBind.xml`의 `namespace`는 `com.jh.partner.co.comcode.rps.FindCodeRepository` → `com.hs.partner.co.comcode.rps.FindCodeRepository`가 된다.
  - 이것은 B의 기존 공통 인터페이스다. `qh` 패키지가 아니며, 5-2의 클래스 이름 규칙도 적용하지 않는다.
  - B의 `QsCodeFind.xml` 등도 같은 `namespace`를 쓴다. SQL ID가 다르므로(`get_QH_…`) 충돌하지 않는다.

### 5-2. 클래스 이름 (빈 이름 충돌 해결) — ERP 결정 1과 같음

| 원본 클래스 이름 | 바꾼 이름 | 예 |
|---|---|---|
| `Qs`로 시작 | 맨 앞 `Qs` → `Qh` | `QsMainController` → `QhMainController` |
| 그 밖 | 맨 앞에 `Qh`를 붙인다 | `AddRiskCoController` → `QhAddRiskCoController`, `RiskChkRepository` → `QhRiskChkRepository` |

- 40개 클래스 모두 같은 규칙으로 바꾼다. 충돌이 없는 `qsb` 12개도 포함한다. 그래야 import와 참조를 한 표로 바꿀 수 있다.
- 같은 표로 바꾸는 곳: 파일 이름, `class`/`interface` 선언, import, 필드 타입, 매퍼 XML의 `namespace`
- 바꿀 때는 단어 경계로만 바꾸고, 긴 이름부터 바꾼다. 예: `AddRiskCoService`와 `AddRiskCoServiceImpl`을 따로 다룬다.
- 매퍼 XML 파일 이름(`AddRiskCo.xml` 등)은 그대로 둔다. B는 `classpath*:sqlmap/mybatis/**/*.xml`을 모두 읽으므로 결과에 영향이 없다(확인함).

### 5-3. URL과 뷰 경로 (`.java`, `.jsp`)

| 원본 | 바꾼 값 | 곳 (파일) |
|---|---|---:|
| `"/qsa"`, `"/qsa/…"` | `"/qha"`, `"/qha/…"` | 62 (16) |
| `"/qsb"`, `"/qsb/…"` | `"/qhb"`, `"/qhb/…"` | 28 (8) |
| `"/qsc"`, `"/qsc/…"` | `"/qhc"`, `"/qhc/…"` | 8 (4) |
| `"/qsz"`, `"/qsz/…"` | `"/qhz"`, `"/qhz/…"` | 11 (3) |
| 뷰 이름·JSP 경로 `qs/qsa/…`, `/qs/qsz/…` 등 | `qh/qha/…`, `/qh/qhz/…` | 18 (10) |
| 메뉴 링크 `href='qsa/…'` 등 (`navQH.jsp`) | `href='qha/…'` 등 | 8 (1) |
| 따옴표로 시작하는 상대 경로 `"qsa/…"` (`setActiveMenu("qsa/addRiskLstCo")` 등, 메뉴 링크와 짝) | `"qha/…"` | 5 (5) — 3단계 미리보기에서 찾아 추가(2026-11-17) |

- 컨트롤러는 JSP 경로를 문자열로 돌려준다(예: `return "qs/qsb/riskChk"`). ERP처럼 DB 메뉴의 `FILE_PATH`를 쓰지 않는다.
- 메서드 URL의 뒷부분(`/getGrd_AddRisk`, `/dashBoardQs`, `/getFrm_qsDashBoardTopInfo` 등)은 그대로 둔다. 앞부분이 `/qhz`로 바뀌므로 충돌하지 않는다.
- `navQH.jsp`의 링크 8개에는 원본에서 주석 처리된 링크도 들어 있다. 일관성을 위해 함께 바꾼다.

### 5-4. DB 객체 이름 (`.xml`, `.java`, `.jsp`) — ERP 5-4와 같음

**QH 이관 매핑표(`scripts/migration_qh/02_generate/mapping.csv`)의 `VPLUS_NAME`을 따른다.** QH 이관 때 실제로 만든 이름이다.

`qs` 디렉토리 68개 파일이 부르는 QS 이름은 **49개**다. 여기에 3-2의 XML 2개만 부르는 테이블 5개(`TQSA_CTP`, `TQSA_CTPUNT`, `TQSA_SITENAM`, `TQSA_VNDR`, `TQSB_VNDRNAM`, 모두 `CREATE`)가 더해져 **54개**다(2단계에서 정정, 2026-11-17).

| 구분 | 개수 | 처리 |
|---|---:|---|
| 매핑표 `CREATE` | 49 (44 + 3-2의 5) | `VPLUS_NAME`으로 바꾼다. 예: `TQSA_SITENAM` → `TQHA_SITENAM`, `TQSB_RISK_DGR` → `TQHB_RISK_DGR` |
| vplus 기존 뷰 `VQSZ_TRADE`, `VQSZ_SITEINFO` | 2 | 그대로 둔다(ERP와 같음) |
| 매핑표·기준선 어디에도 없음 | 3 | **바꾸지 않고 보고한다.** 아래 표 |

| 이름 | 쓰는 곳 |
|---|---|
| `PQSC_NCR_AB_S` | `qsc/NcrActRsltCo.xml` |
| `PQSC_NCR_REP_S` | `qsc/NcrActRsltCo.xml` |
| `TQSC_NCR_REP` | `qsc/NcrActRsltCo.xml`, `qsz/QsMain.xml` |

- 3개 모두 품질 부적합(`qsc`) 기능이다. B의 메뉴(`navQS.jsp`)에서도 이 화면은 주석 처리돼 있다.
- QH 이관 범위(JH `TQSA_*`·`TQSB_*`)에 들어 있지 않았다. 그대로 두면 vplus에 같은 이름의 객체가 있을 때만 동작한다(9장 미확인 2).

### 5-5. 공통코드 값 — ERP 결정 2와 같음

`QS` 뒤에 영문자나 숫자가 이어지는 낱말에서 `QS`를 `QH`로 바꾼다. 단, 바꾼 값이 공통코드 복사 매핑표(`scripts/comcode_qh/02_generate/mapping.csv`)에 있을 때만 바꾼다.

- **19종이고, 모두 QH 코드가 있다.** 그대로 둘 값은 없다.
  - `qs` 디렉토리 18종, 146곳: `QS002`~`QS005`, `QS022`, `QS024`~`QS026`, `QS036`, `QS046`, `QS063`, `QS07702`, `QS07703`, `QS090`, `QS09001`~`QS09004`
  - `QhCodeFind.xml` 1종, 1곳: `QS077`
- `qh.lib.js`·`QhSelectBind.xml` 주석 안의 `QSE`는 공통코드가 아니라서 그대로 둔다.
- `riskChk.jsp`의 JS 변수 이름 `var QS090`도 같은 토큰이라 `QH090`으로 바뀐다. 파일 안에서 함께 바뀌므로 동작은 같다.

### 5-6. 코드찾기·셀렉트박스 QH 모듈

3-2의 Qh 파일로 QH 모듈을 새로 만들고, 새 화면이 이 QH 모듈을 쓰도록 바꾼다. ERP 결정 3과 같은 방식이다(확정, 2026-11-17).

#### 5-6-1. B의 동작 방식 (확인함)

화면의 모듈 값(`module:"QS"`, `wrkTp="QS"`)이 JS 함수, 서버 메서드, SQL ID를 모두 정한다.

| 기능 | 흐름 | `QS`일 때 | `QH`로 바꾸면 필요한 것 |
|---|---|---|---|
| 코드찾기 그리드 | `app.createcodefinder.js`의 `switch (module)` → 모듈별 init 함수 | `case "QS"` → `qsfnCodeFindInit` (`qs.lib.js`) | `case "QH"` 줄 추가, `qh.lib.js` 로드 |
| 코드찾기 조회 | JS가 `/codefind/getGrd_CodeFindList`로 요청 → `FindCodeServiceImpl`이 리플렉션으로 `FindCodeRepository`의 `"get_" + 모듈 + "_CodeFindList"`를 부른다 | `get_QS_CodeFindList`(`FindCodeRepository.java:37`에 선언) | `FindCodeRepository`에 `get_QH_CodeFindList` 선언 추가 |
| 셀렉트 목록 | 태그(`ibEnumTagLib`, `SelectBoxTagLib`, `CheckBoxTagLib`, `RadioButtonTagLib`)와 `FindCodeServiceImpl`이 `"get_" + wrkTp + "_SelectBindList"`를 부른다 | `get_QS_SelectBindList`(`:61`) | `FindCodeRepository`에 `get_QH_SelectBindList` 선언 추가 |

- 공통 Java는 모두 메서드 이름을 문자열로 만들어 리플렉션으로 부른다. 모듈별 `if`/`switch`나 허용 목록은 없다(확인함).
- 그래서 **`FindCodeRepository.java`에 선언만 추가하면** `FindCodeServiceImpl`과 태그 클래스는 그대로 둔 채 `QhCodeFind.xml`·`QhSelectBind.xml`의 SQL이 실행된다.
- 페이징 코드찾기(`get_…_CodeFindPageList`)는 QS에도 없고, JH_PTN 화면도 쓰지 않는다(확인함). 그래서 추가하지 않는다.
- 다중 코드찾기(`app.createmulticodefinder.js`)도 JH_PTN 화면이 쓰지 않는다(확인함). 그래서 수정하지 않는다.

#### 5-6-2. 새 Qh 파일의 변환

| 원본 | 바꾼 값 | 파일 | 곳 |
|---|---|---|---:|
| 함수 `qsfnCodeFindInit` (주석의 `qsfnMethod` 포함) | `qhfnCodeFindInit`, `qhfnMethod` | `qh.lib.js` | 2 |
| SQL ID `get_QS_CodeFindList`, `get_QS_CodeFindList_Proc` | `get_QH_CodeFindList`, `get_QH_CodeFindList_Proc` | `QhCodeFind.xml` | 2 |
| SQL ID `get_QS_SelectBindList` | `get_QH_SelectBindList` | `QhSelectBind.xml` | 1 |
| 항목 이름 `QS_CHRC_VAL`, `QS_CTPUNT`, `QS_CTP_CD` | `QH_CHRC_VAL`, `QH_CTPUNT`, `QH_CTP_CD` | `QhSelectBind.xml` | 3 |

- **함수 이름은 반드시 바꿔야 한다.** B의 `qs.lib.js`에도 `qsfnCodeFindInit`가 있다. 같은 전역 함수 이름이면 나중에 로드된 쪽이 덮어써서, 기존 QS 화면의 코드찾기가 깨진다.
- `qh.lib.js`에는 전역 변수(`var`)가 없다(확인함).
- 테이블 이름과 공통코드 값은 5-4, 5-5 규칙으로 바꾼다.

#### 5-6-3. 기존 공통 파일에 추가하는 줄 (2-2에서 허용)

기존 줄은 바꾸거나 지우지 않고, 아래 줄만 추가한다.

| 파일 | 추가 내용 | 효과 |
|---|---|---|
| `java/com/hs/partner/co/comcode/rps/FindCodeRepository.java` | QS 선언 아래에 같은 모양으로 3줄을 추가한다: `get_QH_CodeFindList`, `get_QH_CodeFindList_Proc`, `get_QH_SelectBindList` (`List<Map<String,Object>> …(Map<String, Object> map);`) | 코드찾기 조회와 셀렉트 목록이 QH SQL로 동작한다 |
| `webapp/WEB-INF/jsp/include/scriptInclude.jsp` | `qh.lib.js` `<script>` 1줄 (`qs.lib.js` 줄 아래) | `qhfnCodeFindInit`를 쓸 수 있다 |
| `webapp/resources/js/app.createcodefinder.js` | `case "QH": init_sheet = qhfnCodeFindInit(initdata.moduleDiv); break;` 2곳 (`case "QS"` 아래) | 코드찾기 그리드가 열린다 |
| `webapp/WEB-INF/jsp/index.jsp` | `<c:when test="${sysTp eq 'QH'}">` → `navQH.jsp` 1줄 (`QS` 줄 아래) | 메뉴 분기를 준비한다. 로그인 모듈 `QH` 처리는 나중에 한다(8장 결정 2). 그 전에는 이 분기로 들어오지 않는다 |

#### 5-6-4. 화면 JSP의 모듈 값과 항목 이름

| 원본 | 바꾼 값 | 파일 | 곳 |
|---|---|---|---:|
| `module:"QS"` | `module:"QH"` | 새 JSP 9개 | 10 |
| `wrkTp="QS"` | `wrkTp="QH"` | `qhb/riskChk.jsp` | 1 |
| `grpCd="QS_CHRC_VAL"` | `grpCd="QH_CHRC_VAL"` | `qhb/riskChk.jsp` | 1 |
| `moduleDiv:"QS_DEPT_H_CD_AUTH"` | `moduleDiv:"QH_DEPT_H_CD_AUTH"` | `qhb/riskDgrMng.jsp` | 1 |

- 코드찾기 항목 `VNDR_REG_SIT_CD`, `SITE_USER_INFO`, `VNDR_INFO_SITE`에는 `QS`가 없어서 그대로 둔다. 셋 모두 `QhCodeFind.xml`과 `qh.lib.js`에 있다.
- 아래 두 항목은 JH_PTN 모듈에도 없다. 원본부터 결과가 비어 나오므로 보고만 한다.
  - `QH_DEPT_H_CD_AUTH`(원본 `QS_DEPT_H_CD_AUTH`)
  - `VNDR_REG_SITE_CD`(`qhc/ncrActRsltLstCo.jsp`)
- `"QS_PARTNER"`는 항목 이름이 아니라서 그대로 둔다(5-8).

### 5-7. OZ 리포트 경로 `/QS/` → `/QH/` — ERP의 현재 상태와 같음

| 원본 | 바꾼 값 | 곳 |
|---|---|---|
| `"/QS/riskItmRegCo.ozr"` | `"/QH/riskItmRegCo.ozr"` | `qsa/riskItmRegCo.jsp`, `qsb/riskLst.jsp` |
| `"/QS/" + "safeCostRegCoAprv" + ".ozr"` | `"/QH/" + …` | `qsa/safeCostReg1Co.jsp` |
| `"/QS/" + "safeWorkRegAppr" + ".ozr"` | `"/QH/" + …` | `qsa/safeWorkReqRegCo.jsp` |

- 폴더(`/QS/`)만 바꾸고 파일 이름에는 `qh_`를 붙이지 않는다. ERP JSP의 현재 상태와 같다.
- 로컬 OZ 폴더(`C:\vPlus\oz\jh_erp\QH`) 기준으로 보면 다음과 같다.
  - `safeCostRegCoAprv.ozr`, `safeWorkRegAppr.ozr`: 있다
  - **`riskItmRegCo.ozr`: QH·QS 어디에도 없다.** 리포트를 추가하기 전까지 이 출력은 실패한다.

### 5-8. 바꾸지 않는 것

| 값 | 쓰임 | 이유 |
|---|---|---|
| `"QS_PARTNER"` (3곳) | `"&KEY=" + "QS_PARTNER" + "riskItmRegCo"` 같은 키 문자열의 일부 | 항목 이름이 아니다(ERP 5-8과 같음) |
| `VQSZ_TRADE`, `VQSZ_SITEINFO` | vplus 기존 뷰 | 5-4 |
| 메서드 URL·메서드 이름 안의 `Qs` (`dashBoardQs`, `getFrm_qsDashBoardTopInfo`) | URL 뒷부분 | 앞부분(`/qhz`)으로 이미 구분된다 |
| 화면 설명 문구, 주석 | | 실행에 영향 없음 |

## 6. 실행 절차

스크립트와 산출물은 `dm-hmplus/erp-jh/scripts/source_qh_ptn/`에 둔다. ERP 작업의 `scripts/source_qh/`와 같은 방식이다.

| 단계 | 내용 | 산출물 |
|---|---|---|
| 1. 사전 확인 | 대상 경로에 파일이 없는지(`qh` 경로, `Qh*` 클래스, 3-2의 Qh 파일 4개), B git 작업 트리가 깨끗한지 확인한다 | `10_precheck.log` |
| 2. 매핑표 생성 | 파일 경로(72행), 클래스 이름(40행), DB 객체(49행), 공통코드(19행) 매핑을 만든다 | `20_path_map.csv`, `21_class_map.csv`, `22_dbobj_map.csv`, `23_code_map.csv` |
| 3. 변환 미리보기 | 복사하지 않고 규칙별 바꿀 곳 수와 diff를 만든다. 공통 파일 4개에 추가할 줄도 diff로 낸다. 규칙 밖에서 `qs`/`QS`가 남는 곳은 목록으로 낸다 | `30_diff_report.md`, `31_leftover.txt`, `32_preview.diff` |
| 4. 사용자 확인 | 3단계 보고서를 보고 진행 여부를 정한다 | |
| 5. 복사·변환 | ① 새 파일 72개를 쓴다. 같은 경로에 파일이 있으면 멈춘다 ② 공통 파일 4개에 5-6-3의 줄을 추가한다. ①과 ②는 같은 실행에서 한다. ②가 빠지면 새 화면의 코드찾기·셀렉트 목록이 동작하지 않는다 | `50_copy.log` |
| 6. 검증 | 7장 | `60_verify.log` |

## 7. 검증

| 항목 | 기준 |
|---|---|
| 파일 수 | 새 파일 72개 |
| 기존 파일 | `git status`의 수정(`M`)은 공통 파일 4개(`FindCodeRepository.java`, `scriptInclude.jsp`, `app.createcodefinder.js`, `index.jsp`)뿐이다. 4개 모두 diff에 추가 줄(`+`)만 있어야 한다. 그 밖의 공통 Java, 로그인 관련 Java, 기존 QS 소스의 수정은 0건이고, 삭제(`D`)도 0건이다 |
| 남은 이름 | 새 파일에 다음이 0건이다: `com.jh.partner`, `"/qsa`, `"/qsb`, `"/qsc`, `"/qsz`, `qs/qs`, `href='qs`, `/QS/`, `module:"QS"`, `wrkTp="QS"`, `get_QS_`, `qsfn`, 5-6 표의 `QS_` 항목 이름 |
| 함수·SQL ID | `qhfnCodeFindInit`가 B 전체에서 `qh.lib.js` 한 곳에만 정의돼 있다. `get_QH_CodeFindList`, `get_QH_CodeFindList_Proc`, `get_QH_SelectBindList`가 B 매퍼 XML 전체에서 하나씩만 있고, `FindCodeRepository.java`에 선언이 있다 |
| 항목 이름 짝 | 새 JSP가 쓰는 코드찾기 항목(`moduleDiv`)과 셀렉트 항목(`grpCd`)이 `QhCodeFind.xml`·`QhSelectBind.xml`·`qh.lib.js`에 있다. 원본부터 없던 `QH_DEPT_H_CD_AUTH`, `VNDR_REG_SITE_CD`는 예외로 보고한다 |
| 남은 DB 이름 | 남은 QS 이름은 5-4의 5개(`VQSZ_*` 2, 미매핑 3)뿐이다 |
| 클래스 이름 | 새 클래스 이름이 B 전체에서 하나뿐이다 |
| 프로시저 인자 | 매퍼가 부르는 QH 프로시저의 인자 개수·이름이 vplus DB의 `PQHA_*`/`PQHB_*`와 맞다(9장 미확인 1) |
| 컴파일 | `mvn -DskipTests compile` 성공 (JDK 11) |
| 기동 | 8088 포트로 기동, 빈 충돌·URL 충돌·매퍼 오류 없음 |
| 화면 | 메뉴로는 들어갈 수 없으므로(결정 2) URL을 직접 입력해 대표 화면을 연다. 조회, 코드찾기, 셀렉트 목록이 QH 데이터로 나오는지 본다 |

## 8. 결정 사항

| # | 항목 | 내용 | 상태 |
|---|---|---|---|
| 결정 1 | 코드찾기·셀렉트박스 (5-6) | QH 모듈을 새로 만들어 쓴다. 연결은 공통 파일 4개에 줄을 추가해서 한다: `FindCodeRepository.java` 선언 3줄, `scriptInclude.jsp`, `app.createcodefinder.js`, `index.jsp`. `FindCodeServiceImpl` 등 그 밖의 공통 Java는 고치지 않는다 | **확정(2026-11-17)** |
| 결정 2 | 메뉴 연결·로그인 | `navQH.jsp`를 만들고 `index.jsp`에 분기 1줄을 추가한다. 로그인 모듈 `QH` 처리(`LoginSuccessHandler.java`, `AccountServiceImpl.java`, `MainController.java`)는 **나중에 별도로 수정한다.** 그 전까지는 QH 메뉴로 들어올 수 없으므로 새 화면은 URL을 직접 입력해서 확인한다 | **확정(2026-11-17).** 로그인은 후속 작업 |
| 결정 3 | 미매핑 DB 객체 3개 (5-4, `PQSC_NCR_*`, `TQSC_NCR_REP`) | 품질 부적합(`qsc`) 기능에서 쓴다 | 제안: 그대로 두고 보고한다. `qsc` 화면은 메뉴에서도 빠져 있다 |
| 결정 4 | OZ 리포트 `riskItmRegCo.ozr` (5-7) | 로컬 OZ 폴더의 QH·QS 어디에도 없다 | 제안: 소스 경로는 `/QH/`로 바꾸고, 리포트 파일은 사용자 작업으로 추가한다 |

## 9. 미확인 사항 (실행 전에 확인)

| # | 항목 | 내용 |
|---|---|---|
| 1 | 원본 버전 차이 | B의 README에 따르면 협력사 원본은 JH202603(SVN `JH202603/ptn`)이다. QH DB 객체는 JH202610에서 이관했다. 그래서 JH_PTN 매퍼가 부르는 프로시저의 인자가 QH 프로시저와 다를 수 있다. 3단계에서 매퍼의 `CALL` 인자 목록과 vplus DB의 `PQHA_*`/`PQHB_*` 인자를 비교한다(조회만) |
| 2 | 미매핑 DB 객체 3개 | `PQSC_NCR_AB_S`, `PQSC_NCR_REP_S`, `TQSC_NCR_REP`가 vplus DB에 있는지 조회한다(조회만) |
| 3 | JH_PTN의 출처 | `JH_PTN` 폴더는 git 저장소가 아니라서 어느 리비전인지 기록이 없다. 다음 중 어느 쪽인지 확인이 필요하다: B의 `ptn`(JH202603)과 같은 계열인지, README의 참조 소스(JH202610 `JUNGHEUNG-PARTNER`)인지 |

## 10. 후속 작업 (이번 범위 밖)

- 로그인 모듈 `QH` 처리: `LoginSuccessHandler.java`, `AccountServiceImpl.java`, `MainController.java`의 `QS` 전용 분기. 이 작업이 끝나야 `index.jsp`의 `navQH.jsp` 분기가 동작한다.
- OZ 리포트 `riskItmRegCo.ozr` 추가(결정 4).

## 11. 되돌리기

- 새로 만든 파일을 지운다.
  - `qh` 디렉토리 3곳: `java/com/hs/partner/qh`, `resources/sqlmap/mybatis/qh`, `webapp/WEB-INF/jsp/qh`
  - 3-2의 Qh 파일 4개: `qh.lib.js`, `navQH.jsp`, `QhCodeFind.xml`, `QhSelectBind.xml`
- 줄을 추가한 공통 파일 4개는 `git checkout -- <파일>`로 되돌린다: `FindCodeRepository.java`, `scriptInclude.jsp`, `app.createcodefinder.js`, `index.jsp`
- DB는 바꾸지 않으므로 되돌릴 것이 없다.

## 12. 실행 결과 (2026-11-17)

스크립트와 로그: `scripts/source_qh_ptn/`

| 단계 | 결과 | 산출물 |
|---|---|---|
| 1. 사전 확인 | 대상 경로 비어 있음, `Qh*` 클래스 0, 새 클래스 이름 충돌 0, B 작업 트리 깨끗함 | `10_precheck.log` |
| 2. 매핑표 | 경로 72, 클래스 40, DB 이름 54(CREATE 49, NOT_MAPPED 5), 코드 20종(바꿈 19, 그대로 1: 주석의 `QSE`) | `20_path_map.csv`, `21_class_map.csv`, `22_dbobj_map.csv`, `23_code_map.csv` |
| 3. 미리보기 | 규칙별 바꿀 곳과 공통 파일 추가 줄 확인. 남은 `qs` 토큰 중 `setActiveMenu("qsa/…")` 5곳을 찾아 규칙 추가(5-3) | `30_diff_report.md`, `31_leftover.txt`, `32_preview.diff` |
| 3-1. DB 조회(9장 미확인 1·2) | 아래 12-1 | `35_db_check.log`, `36_db_check_detail.log`, `37_arg_align.txt` |
| 4. 사용자 확인 | 인자 개수는 DB 기준으로 맞춘다. 없는 프로시저와 `PCOA_SMS_INTERFACE`는 무시한다(사용자 지시) | |
| 5. 복사·변환 | 새 파일 72개, 공통 파일 4개 줄 추가(`FindCodeRepository.java` +3, `scriptInclude.jsp` +1, `app.createcodefinder.js` +6, `index.jsp` +1) | `50_copy.log` |
| 6. 검증 | 파일 검증 23개 항목 모두 OK. `mvn -DskipTests compile` 성공. 8088 기동 성공(70초), 빈 충돌·URL 충돌·매퍼 오류 없음. `/resources/js/module/qh.lib.js` 200 | `60_verify.log` |

**규칙별 바꾼 곳 (새 파일 72개)**

| 규칙 | 곳 | 규칙 | 곳 |
|---|---:|---|---:|
| 5-1 패키지 | 116 | 5-5 공통코드 | 147 |
| 5-2 클래스 이름 | 110 | 5-6 모듈(`module:"QH"`) | 10 |
| 5-3 URL | 109 | 5-6 `wrkTp` | 1 |
| 5-3 뷰 경로 | 18 | 5-6 항목 이름 | 5 |
| 5-3 메뉴 링크 | 8 | 5-6 SQL ID | 3 |
| 5-3 상대 경로(`setActiveMenu`) | 5 | 5-6 JS 함수(`qhfn`) | 2 |
| 5-4 DB 이름 | 85 | 5-7 OZ 경로 | 4 |
| 5-4b 프로시저 인자 추가 | 3 | | |

### 12-1. 프로시저 인자 대조 (vplus DB, 조회만)

새 매퍼의 CALL 49곳을 vplus DB(`USER_ARGUMENTS`)와 위치별로 대조했다. 처음 비교는 `#{…}`만 세어서 12개가 다르게 나왔다. 그러나 `'Q'` 같은 고정값 인자와 주석을 반영해 다시 세니, 실제로 다른 것은 2개였다. 이 2개는 **DB 기준으로 맞췄다**(사용자 지시, 5-4b).

| 프로시저 | 매퍼 → DB | 처리 |
|---|---|---|
| `PQHB_RISK_NAM_S` (`qhb/RiskDgr.xml`) | 13 → 14 | 10번째에 `#{EMPE_NO_PRV ,jdbcType=VARCHAR}` 추가. 화면이 이 값을 넘기지 않으므로 NULL이 들어간다. 프로시저는 `p_EMPE_NO_PRV != p_EMPE_NO`일 때만 이전 사원 행을 처리하므로, NULL이면 그 처리를 건너뛴다 |
| `PQHB_RISK_DGR_W` (`qhb/RiskDgr.xml`) | 7 → 9 | 끝에 `#{APRS_STR_DT}`, `#{APRS_END_DT}` 추가. 같은 화면(`riskDgrMainList.jsp`, `riskChk.jsp`)에 이 키가 있다 |

**무시한 것 (사용자 지시)**
- vplus DB에 없는 객체: `PQSC_NCR_AB_S`, `PQSC_NCR_REP_S`, `TQSC_NCR_REP`(`qhc` 품질 부적합), `PCOA_SMS_INTERFACE`(SMS 발송, B의 기존 QS 화면도 같은 이름을 부른다)

**INVALID였던 프로시저 2개 — 해결됨**
- `PQHA_RISK_CHK_B`, `PQHB_RISK_CHK_S`는 13:53 조회 때 **INVALID**였다(`36_db_check_detail.log`).
- 다시 조회하니 둘 다 **VALID**다. `LAST_DDL_TIME`이 2026-11-17 13:56:18, 13:56:48로, 그 사이에 다시 컴파일됐다. 이 작업의 스크립트는 조회만 했다.
- 컴파일 오류(`USER_ERRORS`)는 0건이다. 의존 테이블(`TQHA_RISK_CHK`, `TQHB_RISK_LST`, `TQHB_RISK_VNDR`, `TQHB_RISK_CHK`)도 모두 VALID다.

### 12-2. 남은 사항

| # | 내용 |
|---|---|
| 1 | 화면 동작 확인은 하지 않았다. 로그인하지 않으면 새 URL이 403을 돌려주고, 로그인 모듈 `QH` 처리는 후속 작업이다(10장). |
| 2 | ~~INVALID 프로시저 2개~~ → 13:56에 다시 컴파일되어 VALID(12-1) |
| 3 | `QH_DEPT_H_CD_AUTH`(`qhb/riskDgrMng.jsp`), `VNDR_REG_SITE_CD`(`qhc/ncrActRsltLstCo.jsp`)는 원본 모듈에도 없는 코드찾기 항목이라 결과가 비어 나온다 |
| 4 | OZ 리포트 `riskItmRegCo.ozr` 없음(결정 4) |
| 5 | 커밋 전이다. 커밋은 사용자 지시가 있을 때 한다 |
