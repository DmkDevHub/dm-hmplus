# JH → vplus 소스 복사 계획 (qs → qh)

> 작성일: 2026-11-13 · 원본: `JH_ERP/src/main` (패키지 `com.jh.erp`) · 대상: `VPLUS202611A/erp/src/main` (패키지 `com.hs.hub`)
> 관련: [QH_MIGRATION_RESULT.md](QH_MIGRATION_RESULT.md)(DB 객체 QH 이관), [QS_COMCODE_COPY_PLAN.md](QS_COMCODE_COPY_PLAN.md)(공통코드 QS→QH), [QH_CODE_LITERAL_PLAN.md](QH_CODE_LITERAL_PLAN.md)(DB 소스의 코드 값 QS→QH)
> 이 문서의 수치는 두 소스 트리를 읽기만 해서 확인한 값이다.
> **실행 완료(2026-11-16): 783개 파일을 복사·변환하고 예외 허용 파일 6개를 고쳤다. 검증과 컴파일을 통과했다. 커밋 전이다. 결과는 11장에 있다.**
> **선행 작업 완료(2026-11-16): QH 코드찾기·셀렉트박스 모듈을 추가했다(10장).**

## 1. 목적

JH_ERP의 `qs`로 시작하는 디렉토리의 파일을 **이름의 `qs`를 `qh`로 바꿔** VPLUS202611A의 같은 위치에 복사한다.
DB 쪽(테이블 `TQHA_*`·`TQHB_*`, 프로시저 `PQHA_*`·`PQHB_*`·`PQHZ_*`, 함수 `FQHA_*`·`FQHZ_*`, 공통코드 `QH*`)은 이미 vplus에 있다. 이번 작업은 그 DB 객체를 쓰는 **화면·서버 소스**를 추가하는 것이다.

## 2. 원칙

- **vplus의 기존 파일은 바꾸지 않는다. 새 디렉토리(`qh`)에 파일을 추가만 한다.**
  - vplus에는 `qh` 경로와 `Qh`로 시작하는 클래스가 하나도 없다(확인함). 복사할 파일 경로는 기존 파일과 겹치지 않는다.
  - 같은 경로에 파일이 있으면 덮어쓰지 않고 멈춘다.
  - **예외(사용자 지시, 2026-11-16):** QH 코드찾기 모듈을 연결하려고 기존 공통 파일 4개에 줄을 **추가만** 했다. 기존 줄은 바꾸거나 지우지 않았다(10장).
- **변환 규칙(5장)은 새로 추가하는 `qh` 소스에만 적용한다. vplus의 기존 `qs` 소스는 수정하지 않는다**(사용자 지시, 2026-11-16).
  - 기존 `qs` 소스: `qs` 디렉토리(`java/com/hs/hub/qs`, `sqlmap/mybatis/qs`, `jsp/qs`, `jsp/cont/qs`)와 `qs` 밖의 QS 파일(`qs.lib.js`, `co/codefind/QsCodeFind.xml`, `co/selectbox/QsSelectBind.xml` 등)
  - 바꾸는 대상: 3장의 새 `qh` 파일 783개와 10장의 새 Qh 파일 3개(`QhCodeFind.xml`, `QhSelectBind.xml`, `qh.lib.js`)뿐이다.
  - 기존 `qs` 소스에서 문제가 발견돼도 고치지 않고 보고만 한다.
  - **예외로 허용한 공통 파일 4개(사용자 확인, 2026-11-16):** `FindCodeRepository.java`, `app.createcodefinder.js`, `app.createmulticodefinder.js`, `scriptInclude.jsp`. `qs` 소스가 아닌 공통 파일이고, QH 모듈을 연결하려고 줄을 추가만 했다(10-3). 이 4개 밖의 공통 파일은 허용하지 않는다.
  - **예외로 허용한 결재 레이아웃 파일 3개(사용자 결정, 2026-11-16):** `tiles/tiles.xml`, `tiles/view/approvalinside/header.jsp`, `tiles/view/approvalinside/footer.jsp`. QS와 QH가 결재 레이아웃을 함께 쓰도록 고친다(8장 6번). 고치는 내용은 8장 6번에 적은 것으로 한정한다.
- JH_ERP는 읽기만 한다.
- 원본의 인코딩(UTF-8, BOM 없음)과 줄바꿈(CRLF)을 그대로 지킨다.
- 되돌리기는 이번에 만든 `qh` 디렉토리만 지운다.
- git 커밋은 사용자가 지시할 때만 한다.

## 3. 복사 대상과 경로

JH_ERP의 `qs` 디렉토리 4곳, 파일 **783개**다.

| # | 원본 (`JH_ERP/src/main/` 아래) | 대상 (`VPLUS202611A/erp/src/main/` 아래) | 파일 수 |
|---|---|---|---:|
| 1 | `java/com/jh/erp/qs/aprv` | `java/com/hs/hub/qh/aprv` | 4 |
| 2 | `java/com/jh/erp/qs/qsa` | `java/com/hs/hub/qh/qha` | 450 |
| 3 | `java/com/jh/erp/qs/qsb` | `java/com/hs/hub/qh/qhb` | 20 |
| 4 | `resources/sqlmap/mybatis/qs/aprv` | `resources/sqlmap/mybatis/qh/aprv` | 1 |
| 5 | `resources/sqlmap/mybatis/qs/qsa` | `resources/sqlmap/mybatis/qh/qha` | 112 |
| 6 | `resources/sqlmap/mybatis/qs/qsb` | `resources/sqlmap/mybatis/qh/qhb` | 5 |
| 7 | `webapp/WEB-INF/jsp/qs/aprv` | `webapp/WEB-INF/jsp/qh/aprv` | 16 |
| 8 | `webapp/WEB-INF/jsp/qs/qsa` | `webapp/WEB-INF/jsp/qh/qha` | 157 |
| 9 | `webapp/WEB-INF/jsp/qs/qsb` | `webapp/WEB-INF/jsp/qh/qhb` | 12 |
| 10 | `webapp/WEB-INF/jsp/cont/qs/aprv` | `webapp/WEB-INF/jsp/cont/qh/aprv` | 6 |
| | | **합계** | **783** |

- 하위 디렉토리(`rps`, `svc`, `svc/impl`, `web`)는 그대로 둔다.
- `qs` 디렉토리 밖에 있는 QS 관련 파일은 이번 대상이 아니다(8장).

## 4. 왜 경로만 바꿔서는 안 되는가

vplus의 기존 `qs` 소스는 JH `qs` 소스와 거의 같은 코드다(예: `AddRiskController`는 패키지 이름만 다르고 내용이 같다). 경로만 바꿔 복사하면 아래 세 곳에서 기존 소스와 부딪힌다.

| 충돌 | 내용 | 결과 |
|---|---|---|
| Spring 빈 이름 | 빈 클래스 356개 중 **278개**가 vplus 기존 빈과 클래스 이름이 같다. vplus는 기본 빈 이름 규칙(클래스 이름의 첫 글자를 소문자로)을 쓴다. `@MapperScan(basePackages = "com.hs.hub")`도 같다 | 기동 시 `ConflictingBeanDefinitionException`으로 서버가 뜨지 않는다 |
| URL | `@RequestMapping("/qsa")`, `"/qsb"`, `"/qs/aprv"`가 vplus 기존 컨트롤러와 같다 | 기동 시 `Ambiguous mapping` 오류 |
| DB 객체 | 소스가 `PQSA_*`, `TQSA_*` 등 **QS 이름**을 부른다 | QH 객체가 아니라 vplus 기존 QS 객체를 쓴다 |

그래서 복사하면서 5장의 규칙으로 소스 내용도 바꾼다.

## 5. 변환 규칙

### 5-1. Java 패키지와 import (`.java`, `.xml`)

| 원본 | 바꾼 값 | 대상 파일 |
|---|---|---:|
| `com.jh.erp.qs.qsa` | `com.hs.hub.qh.qha` | |
| `com.jh.erp.qs.qsb` | `com.hs.hub.qh.qhb` | |
| `com.jh.erp.qs.aprv` | `com.hs.hub.qh.aprv` | |
| 그 밖의 `com.jh.erp.` (예: `sys.base.BaseController`) | `com.hs.hub.` | 592 |

- `qs` 밖을 가리키는 import는 24종이다. 모두 vplus에 같은 클래스가 있다(확인함).
- 매퍼 XML의 `namespace`(118개)도 같은 규칙으로 바꾼다.

### 5-2. 클래스 이름 (빈 이름 충돌 해결) — 결정 1 (2026-11-16 확정)

| 원본 클래스 이름 | 바꾼 이름 | 예 |
|---|---|---|
| `Qs`로 시작 | 맨 앞 `Qs` → `Qh` | `QsAprovalController` → `QhAprovalController`, `QszXxx` → `QhzXxx` |
| 그 밖 | 맨 앞에 `Qh`를 붙인다 | `AddRiskController` → `QhAddRiskController`, `AddRiskRepository` → `QhAddRiskRepository` |

- 474개 클래스 모두 같은 규칙으로 바꾼다(빈이 아닌 인터페이스·VO 포함). 그래야 import와 참조를 한 표로 바꿀 수 있다.
- 파일 이름, `class`/`interface` 선언, import, 필드 타입, 매퍼 XML의 `namespace`를 같은 표로 바꾼다.
- 바꿀 때는 **단어 경계**로만 바꾼다(예: `AddRiskService`를 바꿀 때 `AddRiskServiceImpl`을 따로 다룬다). 긴 이름부터 바꾼다.
- 매퍼 XML 파일 이름(`AddRisk.xml` 등)은 그대로 둔다. MyBatis는 `sqlmap/mybatis/**/*.xml`을 모두 읽으므로 파일 이름은 결과에 영향이 없다.

### 5-3. URL (`.java`, `.jsp`, `.html`)

| 원본 | 바꾼 값 | 대상 파일 |
|---|---|---:|
| `"/qsa"`, `"/qsa/…"` | `"/qha"`, `"/qha/…"` | 263 |
| `"/qsb"`, `"/qsb/…"` | `"/qhb"`, `"/qhb/…"` | 19 |
| `"/qs/aprv"`, `"/qs/aprv/…"` | `"/qh/aprv"`, `"/qh/aprv/…"` | |
| `/jsp/qs/qsa/…`, `qs/qsa/…` 같은 JSP 경로 | `/jsp/qh/qha/…`, `qh/qha/…` | 3 |
| `"/qs/qsa/…"`, `"/qs/qsb/…"` (뷰 이름) | `"/qh/qha/…"`, `"/qh/qhb/…"` | |

- 따옴표나 `/`로 둘러싼 경로만 바꾼다. 주석(`[qsa/yyTrgPlan]` 등)은 바꿔도 되고 그대로 둬도 실행에 영향이 없다 — 일관성을 위해 함께 바꾼다.

### 5-4. DB 객체 이름 (`.xml`, `.java`, `.jsp`)

**매핑표(`migration_qh/02_generate/mapping.csv`)의 `VPLUS_NAME`을 그대로 따른다**(2026-11-16 확정). QH 이관 때 실제로 만든 이름이라 소스와 DB가 어긋나지 않는다.

| 매핑표 `ACTION` | 소스의 이름 | 예 |
|---|---|---|
| `CREATE` | `VPLUS_NAME`으로 바꾼다 | `PQSA_ADDRISK_ORD_Q` → `PQHA_ADDRISK_ORD_Q`, `TQSB_RISK_DGR` → `TQHB_RISK_DGR`, `PQSZ_IMPORT_EMPS_S` → `PQHZ_IMPORT_EMPS_S` |
| `EXCLUDE` (vplus 것을 그대로 사용) | `VPLUS_NAME`이 원래 이름과 같으므로 **그대로** | `FQSZ_USR_INFO`, `FQSE_GET_AFTL_CNT`, `PQSD_SUBCONT_Q` |
| 매핑표에 없음 | **바꾸지 않고 목록으로 보고한다**(2026-11-16 확정) | 아래 |

- `VQSZ_TRADE`, `VQSZ_SUBCONT`는 매핑표에 없는 vplus 기존 뷰다. 위 규칙대로 그대로 둔다.
- **매핑표에 없는 이름 134개**(소스가 부르는 401개 중, 2026-11-16 조사)
  - JH와 vplus 기준선(`migration_qh/01_baseline`) 어디에도 없음: 124개. JH에서도 호출하면 오류가 나는 이름이다. 예: `PQSA_JOB_CD_Q`, `PQSA_MON_RSLT_S`, `TQSA_HOCHK_SCHD`, `TQSZ_SITENAM`
  - vplus에만 있음(vplus 기존 QS 객체): 10개. 예: `PQSA_RISK_PRRTCHK_Q`, `PQSA_HOCHKRPT_DETAIL_Q`. 그대로 두면 vplus 기존 QS 객체를 부른다
  - 이 목록은 2단계 `22_dbobj_map.csv`에 `ACTION=NOT_MAPPED`로 남기고, 3단계 보고서와 5단계 로그에 객체별 사용 파일과 함께 보고한다. 실행은 멈추지 않는다.

### 5-5. 공통코드 값 — 결정 2 (2026-11-16 확정)

**QH 공통코드로 복사된 값만 바꾸고, 나머지는 그대로 두고 보고한다**(2026-11-16 확정).

- 대상 토큰: `QS` 뒤에 영문자나 숫자가 이어지는 낱말(예: `QS073`, `QSZ05`, `QSC01`, `QSM02`, `QS01`, `QSZ080`).
- `QS`를 `QH`로 바꾼 값이 공통코드 복사 매핑표(`comcode_qh/02_generate/mapping.csv`의 `VPLUS_COM_CD`·`VPLUS_HRNK_CD`)에 **있으면 바꾼다.** 없으면 **그대로 두고** 2단계 `23_code_map.csv`에 `ACTION=KEEP`으로 남겨 보고한다.

| 경우 | 예 | 처리 |
|---|---|---|
| 복사된 QH 코드가 있음 | `QS073` → `QH073`, `QSZ05` → `QHZ05`, `QSC01` → `QHC01`, `QSM02` → `QHM02` | 바꾼다 |
| 다른 공통코드 그룹의 값 | `QS01` (시스템 구분 `CO22`의 값) | 그대로 |
| 메뉴코드 | `QSZ080`, `QSZ09010`, `QSZ110`, `QSC6040` (`setMNU_CD`) | 그대로. 메뉴 등록 계획에서 다룬다 |
| 공통코드에 없는 값 | `QSZ14`, `QSZ1410`, `QSA01050`, `QSI01`, `QSK03` 등 (주석·식별자) | 그대로 |

- 처음 규칙(`QS`+숫자, `QSZ`는 모두 바꾼다)은 3단계 미리보기에서 공통코드가 아닌 값(`QS01`, 메뉴코드)까지 바꾸고, 복사된 `QSC`·`QSM` 코드는 놓쳐서 바꿨다.
- DB 소스의 코드 값 변경([QH_CODE_LITERAL_PLAN.md](QH_CODE_LITERAL_PLAN.md))도 복사된 코드를 기준으로 했다(예: `QSC01` → `QHC01`).

### 5-6. 코드찾기·셀렉트박스 모듈 코드와 공통 JS 함수 (`.jsp`) — 결정 3

새 화면이 10장의 QH 모듈(`QhCodeFind.xml`, `QhSelectBind.xml`, `qh.lib.js`)을 쓰도록 바꾼다. JH `qs` JSP에서 센 값이다.

| 원본 | 바꾼 값 | 쓰임 | 개수 |
|---|---|---|---:|
| `module:"QS"` | `module:"QH"` | 코드찾기(`app.createcodefinder.js` → `get_QH_CodeFindList`) | 188 |
| `wrkTp="QS"` (`<tag:ibEnum>`) | `wrkTp="QH"` | 셀렉트 목록(`get_QH_SelectBindList`) | |
| `workType="QS"` (`<tag:select>` 등) | `workType="QH"` | 셀렉트박스·체크박스·라디오(`get_QH_SelectBindList`) | |
| `"QS-JOB_CD"`, `"QS-SAFT_PLN_DGR"` | `"QH-JOB_CD"`, `"QH-SAFT_PLN_DGR"` | 셀렉트박스 `codeKnd`(`모듈-항목`) | 4 |
| `qsf…` 함수 호출 (예: `qsfnCodeFindInit`, `qsfGetThisYear`) | `qhf…` | `qh.lib.js`의 함수 | 114 |

- `"QS"`가 위 쓰임이 아닌 곳(예: `"&KEY=" + "QS" + "riskSchdMng"`)은 바꾸지 않고, 3단계 미리보기의 남은 목록(`31_leftover.txt`)에 낸다.

#### 항목 이름 `QS_…` → `QH_…` (2026-11-16 결정)

코드찾기·셀렉트박스의 항목 이름도 `QH`로 맞춘다. 항목 이름은 MyBatis `<when>`과 JS `case`에서 실행할 SQL·그리드를 고르는 데만 쓰고 DB로는 넘어가지 않는다(확인함). 그래서 **JSP, XML, JS 세 곳을 같은 표로 함께 바꿔야 한다.** 한 곳이라도 빠지면 코드찾기 결과가 비어 나온다.

| 원본 | 바꾼 값 | JSP | `QhCodeFind.xml` | `QhSelectBind.xml` | `qh.lib.js` |
|---|---|---:|---:|---:|---:|
| `QS_DEPT_H_CD_AUTH` | `QH_DEPT_H_CD_AUTH` | 111 | 1 | | 1 |
| `QS_COMCD1` | `QH_COMCD1` | | | 1 | |
| `QS_COMCD2` | `QH_COMCD2` | 3 | | 1 | |
| `QS_COMCD3` | `QH_COMCD3` | 6 | | 1 | |
| `QS_CHRC_VAL` | `QH_CHRC_VAL` | 1 | | 1 | |
| `QS_CTPUNT` | `QH_CTPUNT` | | | 1 | |
| `QS_CTP_CD` | `QH_CTP_CD` | | | 1 | |

- JSP에서는 `moduleDiv`, `grpCd`, `grpCode` 등의 값과 셀렉트박스 `codeKnd`(`"QH-…"`)의 항목 부분에서 바꾼다. XML에서는 `<when test="WRK_TP == '…'">`·`GRP_CD == '…'`, JS에서는 `case "…"`에서 바꾼다.
- **위 표에 있는 이름만 바꾼다.** `QS_`로 시작해도 항목 이름이 아닌 것은 그대로 둔다.
  - `QS_SEQ`: 그리드 컬럼 이름이자 매퍼 파라미터 `#{QS_SEQ}`다. 화면과 서버가 같은 이름을 쓴다.
  - `QS_PARTNER`: `"&KEY=" + "QS_PARTNER" + …`처럼 키 문자열의 일부다.
- `QS` 뒤가 `_`가 아닌 항목 이름(예: `SAFT_PLN_DGR`, `JOB_CD`, `VNDR_INFO`)은 원래 `QS`가 들어 있지 않으므로 그대로다.
- 항목에 붙는 코드 값(예: `extFd="QS073"`)은 5-5 규칙으로 따로 `QH073`이 된다.

### 5-7. OZ 리포트 경로 `/QS/` → `/QH/` (2026-11-16 결정) — 결정 4

리포트도 QH 테이블을 읽도록 리포트 파일 경로를 `QH` 폴더로 바꾼다.

| 원본 | 바꾼 값 | 대상 | 개수 |
|---|---|---|---:|
| `"/QS/…"`, `'/QS/…'` (`rptName`) | `"/QH/…"`, `'/QH/…'` | JSP 31개 파일 | 48 |
| `"/QS/qsa/…ozr"`, `"/QS/qsb/…ozr"` (`RPTNAME`) | `"/QH/qha/…ozr"`, `"/QH/qhb/…ozr"` | `qh.lib.js` | 3 |
| 그 밖의 `"/QS/<폴더>/…ozr"` (`qsn`, `qso`, `qsk`, `qsg`, `qsm`, `qsp`, `qst`, `qsf`) | `"/QH/<폴더>/…ozr"` (하위 폴더 이름은 그대로) | `qh.lib.js` | 11 |
| `gfnConfOzRptPath({"node": "QS", …})` | `"node": "QH"` | JSP 1곳 (주석 안) | 1 |

- JSP의 `rptName`은 `"/QS/" + rtnData.PAGE_TTL + ".ozr"`처럼 폴더 뒤에 바로 파일 이름이 온다. 폴더(`/QS/`)만 바꾸고, 파일 이름은 그대로 둔다.
- `qh.lib.js`의 하위 폴더는 5-3의 URL 규칙과 맞춰 `qsa` → `qha`, `qsb` → `qhb`만 바꾼다. 그 밖의 폴더는 JH에 해당 화면 소스가 없어 이름을 정할 근거가 없으므로 그대로 둔다.
- Java·매퍼 XML에는 OZ 경로가 없다(확인함).
- **선행 조건:** 리포트 서버에 `/QH/` 폴더와 QH 테이블을 읽는 `.ozr` 파일이 있어야 한다. 없으면 출력이 "파일 없음"으로 실패한다. 리포트 파일 작업은 이 소스 작업 밖이다(8장 결정 4).

### 5-8. 바꾸지 않는 것

| 값 | 쓰임 | 이유 |
|---|---|---|
| `QS_SEQ`, `QS_PARTNER` | 그리드 컬럼·파라미터, 키 문자열 | 항목 이름이 아니다(5-6) |
| `QSE >`, `QSE 공지사항` 등 화면 설명 문구 | 주석·제목 | 실행에 영향 없음 |
| `VQSZ_*`, `FQSE_*` | vplus 기존 DB 객체 | 5-4 |

## 6. 실행 절차

스크립트는 `dm-hmplus/erp-jh/scripts/source_qh/`에 둔다(기존 `migration_qh/`, `qh_code_literal/`과 같은 방식).

| 단계 | 내용 | 산출물 |
|---|---|---|
| 1. 사전 확인 | 대상 경로(`qh`)가 비어 있는지, `Qh*` 클래스가 없는지, vplus git 작업 트리가 깨끗한지 확인 | `10_precheck.log` |
| 2. 매핑표 생성 | 파일 경로 매핑(783행), 클래스 이름 매핑(474행), DB 객체 매핑, 공통코드 매핑을 만든다 | `20_path_map.csv`, `21_class_map.csv`, `22_dbobj_map.csv`, `23_code_map.csv` |
| 3. 변환 미리보기 | 복사하지 않고 규칙별 바꿀 곳 수와 diff를 만든다. 규칙 밖에서 `qs`/`QS`가 남는 곳을 목록으로 낸다 | `30_diff_report.md`, `31_leftover.txt` |
| 4. 사용자 확인 | 3단계 보고서를 보고 진행 여부를 정한다 | |
| 5. 복사·변환 | ① 매핑표대로 새 `qh` 경로에 쓴다. 같은 경로에 파일이 있으면 멈춘다. ② **10장의 Qh 파일 3개에 5-6(항목 이름)·5-7(OZ 경로) 규칙을 함께 적용한다**(10-5 1번). 항목 이름: `QhCodeFind.xml` 1곳, `QhSelectBind.xml` 6곳, `qh.lib.js` 1곳. OZ 경로: `qh.lib.js` 14곳. ③ **결재 공통 레이아웃 3개 파일을 8-1대로 고친다.** ①·②·③은 같은 실행에서 한다. ②가 빠지면 항목 이름이 맞지 않아 코드찾기 결과가 비어 나오고, ③이 빠지면 QH 결재 화면이 열리지 않는다 | `50_copy.log` |
| 6. 검증 | 7장 | `60_verify.log` |

## 7. 검증

| 항목 | 기준 |
|---|---|
| 파일 수 | 새 `qh` 경로 아래 783개 |
| 기존 파일 | `git status`에서 수정(M)은 예외로 허용한 6개뿐이다: Qh 파일 3개(`QhCodeFind.xml`, `QhSelectBind.xml`, `qh.lib.js`, 6장 5단계 ②)와 결재 레이아웃 3개(`tiles.xml`, `approvalinside/header.jsp`, `footer.jsp`, ③). 새 파일(??)은 `qh` 경로(3장의 4곳)에만 생긴다. 기존 `qs` 소스의 수정은 0건이다 |
| 남은 이름 | 새 파일에 `com.jh.erp`, `"/qsa`, `"/qsb`, `"/qs/aprv`, `/QS/`, 5-6 표의 `QS_` 항목 이름이 0건. 남은 `PQSA_`·`PQSB_`·`TQSA_`·`TQSB_` 등 DB 이름은 모두 5-4의 매핑표에 없는 목록(`NOT_MAPPED`) 또는 `EXCLUDE`에 있는 이름이어야 한다 |
| 항목 이름 짝 | 새 JSP가 쓰는 항목 이름(`moduleDiv`, `grpCd` 등)이 모두 `QhCodeFind.xml`·`QhSelectBind.xml`·`qh.lib.js`에 있다 |
| 클래스 이름 | 새 클래스 이름이 vplus 전체에서 하나뿐 |
| 컴파일 | `mvn -DskipTests compile` 성공 (JDK 11) |
| 기동 | `run-vplus.cmd`로 기동, 빈 충돌·URL 충돌 오류 없음 |
| 화면 | 메뉴 등록 후(8장) 대표 화면 몇 개를 열어 조회가 되는지 확인 |

## 8. 범위 밖과 영향 (결정 필요)

| # | 항목 | 내용 | 제안 |
|---|---|---|---|
| 결정 1 | 클래스 이름 규칙 | **확정(2026-11-16): `Qh` 접두어 방식**(5-2). 빈 이름을 직접 지정하는 방법은 `@Repository` 매퍼 때문에 기존 설정(`DataBaseConfiguration`)을 고쳐야 해서 쓰지 않는다 | 확정 |
| 결정 2 | 공통코드 값 | **확정(2026-11-16): 바꾼다**(5-5). `QS…` → `QH…`. DB 쪽 공통코드·QH 프로시저와 맞춘다 | 확정 |
| 결정 3 | 코드찾기·셀렉트박스 모듈 | **확정(2026-11-16): QH 모듈을 새로 만든다.** 10장에서 완료. 화면 복사 때 5-6 규칙으로 `QS` → `QH` | 완료 |
| 결정 4 | OZ 리포트 `"/QS/…ozr"` | **확정(2026-11-16): 소스의 경로는 `/QH/`로 바꾼다**(5-7). `.ozr` 파일은 리포트 서버에 **나중에 추가할 예정**이다(사용자 작업). 파일이 추가되기 전까지 QH 화면의 출력은 실패한다 | 소스는 바꾼다. 필요한 `.ozr` 목록은 3단계 보고서에 낸다 |
| 5 | `resources/js/module/qs.lib.js` | **해결(2026-11-16):** JH 원본으로 `qh.lib.js`를 만들었다(10장). 결재 경로 `APR_APP_PATH`도 `"/qha/…"`, `"/qhb/…"`로 바꿨다 | 완료 |
| 6 | 결재 공통 레이아웃 (`tiles.xml`, `approvalinside/header.jsp`, `footer.jsp`) | **확정(2026-11-16): QS와 QH가 함께 쓰도록 고친다. 결재 주소를 tiles 설정(`aprvBase`)으로 넘기는 방식.** 아래 "8-1" | 6장 5단계 ③에서 한다 |
| 7 | `co/dashboard/DashBoardQs.xml`, `dashBoardQs.jsp`, `qsMontlyChart.jsp` | `qs` 밖의 대시보드다. **확정(2026-11-16): 건드리지 않는다.** 대시보드는 계속 QS 데이터를 보여 준다 | 확정(수정 없음) |
| 8 | 메뉴 등록 | 화면 JSP 경로는 DB 메뉴의 `FILE_PATH`에서 온다(`AuthorityAspect`). 새 URL(`/qha/…`)과 `FILE_PATH`(`qh/qha/…`)를 메뉴에 등록해야 화면이 열린다. **확정(2026-11-16): 일단 계획 문서만 별도로 만든다. DB에는 등록하지 않는다** | 확정(문서만). 등록 전까지 새 화면은 열리지 않는다 |

### 8-1. 결재 공통 레이아웃을 QS·QH 공통으로 (8장 6번)

**현재 상태(2026-11-16 조사)**

- 결재 레이아웃은 `tiles.xml`의 `"/qs/aprv/*"` 정의로만 연결된다. 그래서 `/qh/aprv/…` 화면은 레이아웃 정의가 없어 열리지 않는다.
- `header.jsp` 8곳, `footer.jsp` 2곳이 `"/qs/aprv/…"`를 직접 호출한다(결재선 조회·저장, 반려, 첨부파일).
- `layout_approvalinside.jsp`에는 QS를 직접 쓴 곳이 없다.

**방식: 결재 주소를 tiles 설정으로 넘긴다.** 정의마다 결재 주소(`aprvBase`)를 넘기고, header·footer는 그 값을 받아 쓴다. 값이 없으면 기본값 `/qs/aprv`를 쓴다.

| 파일 | 변경 |
|---|---|
| `tiles/tiles.xml` | `"/qh/aprv/*"` 정의를 **추가**한다. 기존 `"/qs/aprv/*"` 정의는 그대로 둔다 |
| `tiles/view/approvalinside/header.jsp` | 맨 위에 tiles taglib 선언 1줄과 `aprvBase` 받기 2줄을 추가한다. `"/qs/aprv/…"` 8곳을 `"${aprvBase}/…"`로 바꾼다 |
| `tiles/view/approvalinside/footer.jsp` | 같은 3줄을 추가하고, 2곳을 바꾼다 |

```xml
<!-- tiles.xml 추가 -->
<definition name="/qh/aprv/*" extends="layout.approvalinside">
    <put-attribute name="header" expression="/WEB-INF/tiles/view/approvalinside/header.jsp" />
    <put-attribute name="body"   expression="/WEB-INF/jsp/qh/aprv/{1}.jsp" />
    <put-attribute name="footer" value="/WEB-INF/tiles/view/approvalinside/footer.jsp" />
    <put-attribute name="aprvBase" value="/qh/aprv" />
</definition>
```

```jsp
<%-- header.jsp, footer.jsp 맨 위 추가 --%>
<%@ taglib prefix="tiles" uri="http://tiles.apache.org/tags-tiles" %>
<tiles:importAttribute name="aprvBase" ignore="true" />
<c:if test="${empty aprvBase}"><c:set var="aprvBase" value="/qs/aprv" /></c:if>
```

- **기존 QS 결재 화면은 동작이 그대로다.** QS 정의에는 `aprvBase`가 없어 기본값 `/qs/aprv`를 쓴다.
- header·footer는 QS와 QH가 하나를 함께 쓴다. 결재 화면을 고칠 때 한 곳만 고치면 된다.
- 바꾼 뒤 header·footer에 `"/qs/aprv/"`가 0곳이어야 한다(7장).
- QH 결재 컨트롤러(`/qh/aprv`)와 JSP는 3장 복사로 생기므로, 이 수정은 그 복사와 같은 실행에서 한다(6장 5단계 ③).
- 기동한 뒤 QS 결재 화면 1개와 QH 결재 화면 1개를 열어, 결재선 조회와 첨부파일이 각자의 `/qs/aprv`, `/qh/aprv`로 호출되는지 확인한다.

## 9. 되돌리기

새로 만든 디렉토리만 지운다. 기존 파일은 건드리지 않았으므로 이것으로 원래 상태가 된다.

```
VPLUS202611A/erp/src/main/java/com/hs/hub/qh
VPLUS202611A/erp/src/main/resources/sqlmap/mybatis/qh
VPLUS202611A/erp/src/main/webapp/WEB-INF/jsp/qh
VPLUS202611A/erp/src/main/webapp/WEB-INF/jsp/cont/qh
```

(`target/` 아래 빌드 결과는 `mvn clean`으로 지운다.)

8-1의 결재 레이아웃 파일 3개(`tiles.xml`, `approvalinside/header.jsp`, `footer.jsp`)는 `git checkout -- <파일>`로 되돌린다.

10장의 선행 작업을 되돌리려면 새 파일 3개를 지우고, 기존 파일 4개는 `git checkout -- <파일>`로 되돌린다(추가한 줄만 사라진다).

## 10. 선행 작업: QH 코드찾기·셀렉트박스 모듈 (2026-11-16 완료)

새 `qh` 화면이 쓸 코드찾기·셀렉트박스·공통 JS를 먼저 만들었다(사용자 지시).

### 10-1. 원본 선택

처음에는 vplus의 `Qs` 파일을 복사했다. 하지만 JH 원본이 더 컸고, 새 화면이 쓰는 항목은 JH에만 있었다. 그래서 **JH 원본으로 다시 만들었다**(사용자 결정).

| 파일 | JH | vplus | JH에만 있는 항목 |
|---|---:|---:|---|
| `QsCodeFind.xml` | 622줄 | 510줄 | `QS_DEPT_H_CD_AUTH`(JH JSP에서 72번), `VNDR_LIST`, `VNDR_INFO_SITE`, `VNDR_INFO_TRADE`, `MSDS_CD` |
| `QsSelectBind.xml` | 150줄 | 65줄 | `QS_COMCD1~3`, `QS_CHRC_VAL`, `QS_CTPUNT`, `QS_CTP_CD`, `SAFT_PLN_DGR` |
| `qs.lib.js` | 3,116줄 | 2,940줄 | `VNDR_LIST` 등 |

vplus에만 있는 항목은 없다.

### 10-2. 새로 만든 파일 (3개)

스크립트: `scripts/source_qh/gen_codefind_qh.py` · 로그: `scripts/source_qh/gen_codefind_qh.log`

| 새 파일 (`VPLUS202611A/erp/src/main/` 아래) | 원본 (`JH_ERP/src/main/` 아래) | 바꾼 내용 |
|---|---|---|
| `resources/sqlmap/mybatis/co/codefind/QhCodeFind.xml` | `resources/sqlmap/mybatis/co/codefind/QsCodeFind.xml` | namespace `com.jh.erp.` → `com.hs.hub.` 1곳, id `get_QS_` → `get_QH_` 2곳, 테이블 `TQSA_*` → `TQHA_*` 13종 17곳, 공통코드 7곳(`QS028`, `QS077`, `QSZ05`, `QSZ0599`) |
| `resources/sqlmap/mybatis/co/selectbox/QhSelectBind.xml` | `resources/sqlmap/mybatis/co/selectbox/QsSelectBind.xml` | namespace 1곳, id 1곳, 테이블 `TQHA_CTP`, `TQHA_CTPUNT`, `TQHB_RISK_DGR` 3곳, 공통코드 `QH07301`, `QH0730201` 2곳 |
| `webapp/resources/js/module/qh.lib.js` | `webapp/resources/js/module/qs.lib.js` | 함수 이름 `qsf…` → `qhf…` 193곳, 결재 경로 `"/qsa/"` → `"/qha/"` 2곳·`"/qsb/"` → `"/qhb/"` 1곳, 주석 경로 `[qsa/`·`[qsb/` 5곳, 공통코드 4곳(주석) |

- 바꾸지 않은 것
  - `VQSZ_TRADE`: vplus 기존 뷰다.
  - 항목 이름(`QS_DEPT_H_CD_AUTH` 등)과 `RPTNAME "/QS/…ozr"`: 만들 때는 그대로 두었다. **2026-11-16 결정(5-6, 5-7)에 따라 바꿔야 한다**(10-5 1번).
  - 결재 경로 `"/qsn/"`, `"/qso/"`, `"/qsk/"`, `"/qsg/"`, `"/qsm/"`: JH에도 해당 소스가 없다.
- `var saveSeq`는 `qs.lib.js`와 `qh.lib.js`가 같은 전역 변수를 함께 쓴다. `var`라서 오류는 나지 않는다.

### 10-3. 기존 파일에 추가한 줄 (4개 파일, 22줄)

| 파일 | 추가 내용 |
|---|---|
| `java/com/hs/hub/co/comcode/rps/FindCodeRepository.java` | `get_QH_CodeFindList`, `get_QH_CodeFindList_Proc`, `get_QH_SelectBindList` 메서드 선언 3줄. 각 `QS` 줄 바로 아래 |
| `webapp/resources/js/app.createcodefinder.js` | `case "QH": init_sheet = qhfnCodeFindInit(...)` 블록. `case "QS"` 아래 2곳 |
| `webapp/resources/js/app.createmulticodefinder.js` | 같은 블록. `case "QS"` 아래 1곳 |
| `webapp/WEB-INF/jsp/include/scriptInclude.jsp` | `qh.lib.js` `<script>` 1줄. `qs.lib.js` 아래 |

- 연결 구조: 서비스와 태그(`FindCodeServiceImpl`, `ibEnumTagLib`, `SelectBoxTagLib`, `CheckBoxTagLib`, `RadioButtonTagLib`)는 `"get_" + 모듈 + "_CodeFindList"`, `"get_" + 모듈 + "_SelectBindList"` 이름으로 `FindCodeRepository`의 메서드를 찾아 부른다. 그래서 위 3개 메서드만 추가하면 `module:"QH"`, `wrkTp="QH"`, `workType="QH"`가 동작한다. 서비스와 태그 파일은 고치지 않았다.
- 압축본(`*.min.js`)에는 코드찾기 분기가 없다(확인함).

### 10-4. 검증

| 항목 | 결과 |
|---|---|
| 인코딩·줄바꿈 | 새 파일 3개, 수정한 파일 4개 모두 UTF-8, CRLF 유지. 새 파일은 원본과 바이트 수가 같다 |
| XML 형식 | `QhCodeFind.xml`, `QhSelectBind.xml` 파싱 OK. statement id는 `get_QH_*`만 있다(기존 `get_QS_*`와 겹치지 않음) |
| 남은 이름 | `qsf`, `get_QS_`, `com.jh`, `"/qsa/"`, `"/qsb/"`, `PQSB_`, `PQSZ_`, `TQSB_` 0건. 남은 `TQSA_`·`PQSA_`는 아래 10-5의 7종뿐 |
| 컴파일 | `mvn -o -DskipTests compile` 성공(JDK 11) |
| git | 수정(M) 4개(추가만), 새 파일(??) 3개 |
| 기동·화면 | **아직 안 했다.** 서버 기동과 코드찾기 화면 확인은 화면 복사 후 7장에서 한다 |

### 10-5. 남은 사항

| # | 내용 | 영향 |
|---|---|---|
| 1 | **10장 파일에 5-6·5-7 규칙 적용(미진행).** 항목 이름: `QhCodeFind.xml` 1곳, `QhSelectBind.xml` 6곳, `qh.lib.js` 1곳. OZ 경로: `qh.lib.js` 14곳 | 화면 JSP와 같은 때에 바꿔야 한다. 한쪽만 바꾸면 항목 이름이 맞지 않아 코드찾기 결과가 비어 나온다. **6장 5단계 ②에서 한다** |
| 2 | **`qh.lib.js` 변환 오류 2곳(미수정).** 함수 이름 규칙(`\bqsf` → `qhf`)이 결재 화면 경로에도 걸렸다. 2197행 `APR_APP_PATH "/qsf/eduDryMng"` → `"/qhf/eduDryMng"`, 2198행 `RPTNAME "/QS/qsf/eduDryMng_R01.ozr"` → `"/QS/qhf/…"` | 원래대로 되돌려야 한다. 2197행은 `"/qsf/eduDryMng"`, 2198행은 5-7 규칙을 적용해 `"/QH/qsf/eduDryMng_R01.ozr"`. 스크립트 규칙은 함수 이름(`qsf` 뒤에 영문자)에만 걸리도록 고친다(예: `(?<![/\w])qsf(?=[A-Za-z_])`) |
| 3 | QH 이관 매핑표에 없어 그대로 둔 DB 객체 7종: `TQSA_HOCHK_ITM`, `TQSA_JOB_CD`, `TQSA_JOB_CTS`, `TQSA_JOB_ITEM`, `TQSA_JOIN_OBJ`, `TQSC_BSAS_REG`, `PQSA_JOB_OBJ_USER_POP_Q`. **JH와 vplus 기준선 어디에도 없다**(`migration_qh/01_baseline`) | 이 객체를 쓰는 항목(`QhCodeFind`의 본사점검·작업·공동도급 관련 `WRK_TP`, `QhSelectBind`의 `JOB_CD`)은 호출하면 `ORA-00942`가 난다. JH에서도 같은 상태다 |
| 4 | `QHZ14`, `QHZ1420`, `QHZ1490`은 QH 공통코드에 없다 | `qh.lib.js` 주석 안에만 있다. 실행에 영향 없음 |
| 5 | 3장의 783개 파일 복사 | **완료(2026-11-16).** 11장 |

## 11. 실행 결과 (2026-11-16)

스크립트: `scripts/source_qh/copy_qh.py` (`precheck` → `map` → `preview` → `apply` → `verify`)

| 단계 | 결과 | 산출물 (`scripts/source_qh/`) |
|---|---|---|
| 1. 사전 확인 | 통과. 착오 1건 정정: 결재 주소는 header 8곳, footer 2곳(합 10곳) | `10_precheck.log` |
| 2. 매핑표 | 경로 783, 클래스 474, DB 이름 403(CREATE 264, EXCLUDE 3, NOT_MAPPED 136), 코드 115종(바꿈 92, 그대로 23) | `20_path_map.csv`, `21_class_map.csv`, `22_dbobj_map.csv`, `23_code_map.csv` |
| 3. 미리보기 | 5-5 규칙을 "복사된 QH 코드만 바꾼다"로 고친 뒤 다시 만들었다 | `30_diff_report.md`, `31_leftover.txt`, `32_preview.diff` |
| 4. 사용자 확인 | 진행 결정 | |
| 5. 복사·변환 | 새 파일 783개, 예외 허용 파일 6개 수정 | `50_copy.log` |
| 6. 검증 | 파일 검증 18개 항목 통과, 컴파일 성공(`qh` 클래스 474개) | `60_verify.log` |

**규칙별 바꾼 곳 (새 파일 783개)**

| 규칙 | 곳 | 규칙 | 곳 |
|---|---:|---|---:|
| 5-1 패키지 | 1,480 | 5-5 공통코드 값 (바꿈) | 709 |
| 5-2 클래스 이름 | 1,319 | 5-5 코드 모양 값 (그대로) | 84 |
| 5-3 URL·경로 | 893 | 5-6 모듈 코드·함수·항목 이름 | 438 |
| 5-4 DB 이름 (CREATE) | 415 | 5-7 OZ 경로 | 49 |

**예외 허용 파일 6개**: Qh 파일 3개(항목 이름 8곳, OZ 경로 14곳), `tiles.xml`(`/qh/aprv/*` 정의 추가), `header.jsp`(3줄 추가, 결재 주소 8곳), `footer.jsp`(3줄 추가, 결재 주소 2곳)

**하지 않은 것**

- 화면 확인(7장): 메뉴 등록(8장 8번) 전에는 새 화면이 열리지 않는다.

**기동 확인 (2026-11-16)**: `mvn -o -DskipTests spring-boot:run`(JDK 11, 프로필 `loc`)으로 기동했다. `Started Application in 575.313 seconds`, Tomcat 9076. 빈 이름 충돌·URL 중복 매핑·MyBatis statement 중복 오류는 없었다. 로그의 오류 1건(`tradesign3280_loc.properties` 없음)은 전자서명 설정으로, 이번 작업과 무관하다. 로그인하지 않은 요청은 `/qsa`, `/qha` 모두 403이라 URL 등록은 로그인 후에 확인해야 한다.
- 커밋·푸시: 사용자 지시 때 한다.
- OZ 리포트 파일(결정 4), 메뉴 등록 계획 문서(8장 8번)
