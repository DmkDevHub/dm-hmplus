# JH → vplus QS 객체 이관 로드맵

> 작성일: 2026-11-13 · 원본: JH `JH202610` · 대상: vplus `VPLUS202611A` (둘 다 192.168.1.25:1521:ORCLU)
> 근거 수치는 두 DB의 데이터 딕셔너리를 조회한 결과다(조회 전용, 아직 DB를 바꾸지 않았다).
> 관련 문서: [TQS_COPY_TO_VPLUS_REVIEW_V2.md](TQS_COPY_TO_VPLUS_REVIEW_V2.md)(테이블 이름 충돌 검토)

## 0. 기본 원칙 (최우선)

> **vplus의 기존 DB는 변경하지 않는다. JH의 객체가 vplus에 추가만 된다.**
> **JH DB는 읽기만 한다.**

이 원칙은 아래 모든 규칙과 단계보다 우선한다. 구체적으로는 다음을 지킨다.

| 하는 것 | 하지 않는 것 |
|---|---|
| vplus에 새 테이블·제약조건·인덱스·코멘트·TYPE·함수·프로시저를 **만든다**(`CREATE`) | vplus 기존 객체를 `ALTER`/`DROP`/`CREATE OR REPLACE`/`RENAME`하지 않는다 |
| **새로 만든 테이블에만** 데이터를 넣는다 | vplus 기존 테이블에 `INSERT`/`UPDATE`/`DELETE`/`TRUNCATE`를 하지 않는다 |
| **새로 만든 객체만** 다시 컴파일한다 | vplus에서 이미 INVALID인 기존 객체를 다시 컴파일하거나 고치지 않는다 |
| 새 객체가 vplus의 기존 객체(공통 테이블, `FQSE_GET_AFTL_CNT`, `OQSA_DRM_INFO` 등)를 **읽거나 호출하는 것**은 허용한다 | 기존 객체의 코멘트, 권한(GRANT), 통계, 시노님을 바꾸지 않는다 |
| JH는 조회(SELECT, `DBMS_METADATA`, 딕셔너리)만 한다 | JH에 GRANT, DDL, DML을 하지 않는다 |

**원칙을 지키는 장치**

1. **CREATE만 사용한다.** `CREATE OR REPLACE`를 쓰지 않는다. 같은 이름이 있으면 덮어쓰지 않고 오류가 나서 멈춘다.
2. **기존 객체와 이름이 겹치지 않는다(확인함).** 새로 만들 이름 397개(테이블 108, 프로시저·함수 284, 이름이 그대로인 객체 5)는 vplus의 기존 객체·제약조건 이름과 하나도 겹치지 않는다.
3. **기존 객체가 새 이름을 쓰지 않는다(확인함).** vplus의 기존 소스(프로시저·함수·패키지·TYPE), 뷰, 트리거 중에 새로 만들 397개 이름을 참조하는 것은 0건이다. 그래서 객체를 추가해도 기존 객체의 컴파일 상태나 동작이 바뀌지 않는다.
4. **실행 전후로 비교한다.** 1단계에서 vplus 기존 객체 중 이관 범위(테이블은 `TQS*`, 그 밖의 객체는 이름에 `QS` 포함, `TEST*` 제외)의 목록, 상태, `LAST_DDL_TIME`, 테이블별 건수를 기준선으로 저장한다. 6단계에서 다시 조회해 비교했을 때 바뀐 것이 0건이어야 한다.
5. **되돌리기는 추가한 객체만 지운다.** DROP 스크립트에는 이번에 만든 객체만 들어간다.

## 1. 이관 규칙

| 대상 | 규칙 | 예시 |
|---|---|---|
| 테이블 | `TQSA_*` → `TQSB_*`, `TQSB_*` → `TQSC_*`, **전부 복사** | `TQSA_RISK_CHK` → `TQSB_RISK_CHK`, `TQSB_RISK_CHK` → `TQSC_RISK_CHK` |
| PK(와 PK 인덱스) | **`PK_<vplus 테이블명>`으로 만든다.** 대부분은 규칙대로 바꾼 이름과 같다. 테이블 이름과 맞지 않던 10개만 이름이 달라진다(1-2장) | `PK_TQSA_APRV` → `PK_TQSB_APRV`, `PK_TQSA_IDAC4`(`TQSA_EDU_DRY`) → `PK_TQSB_EDU_DRY` |
| FK | **`FK_<vplus 부모 테이블>_TO_<vplus 자식 테이블>`로 만든다.** 대부분은 규칙대로 바꾼 이름과 같다. 실제 테이블과 맞지 않던 3개만 이름이 달라진다(1-3장) | `FK_TQSA_CTP_TO_TQSA_CTPUNT` → `FK_TQSB_CTP_TO_TQSB_CTPUNT` |
| 그 밖의 인덱스 | JH에는 PK 인덱스 말고 사용자가 만든 인덱스가 없다. LOB 인덱스 3개(`SYS_IL…`)는 Oracle이 이름을 자동으로 붙인다 | 해당 없음 |
| 프로시저·함수 (`PQSA`/`PQSB`/`FQSA`) | 이름: `PQSA` → `PQSB`, `PQSB` → `PQSC`, `FQSA` → `FQSB`<br>소스: 안에서 쓰는 테이블과 프로시저·함수 이름도 같은 규칙으로 바꾼다 | `PQSA_RISK_CHK_S` → `PQSB_RISK_CHK_S`(소스의 `TQSA_RISK_CHK`도 `TQSB_RISK_CHK`로) |
| 그 밖의 QS 객체 (`PQSC`, `PQSD`, `PQSZ`, `FQSZ`, `FQSE`, TYPE) | 이름은 그대로 둔다. **vplus에 같은 이름이 있으면 복사하지 않는다.** 없는 것만 복사하고, 소스 안의 테이블·프로시저 이름은 같은 규칙으로 바꾼다 | `PQSZ_IMPORT_EMPS_S`(vplus에 없음) → 복사 |

- 함수에도 프로시저 규칙을 똑같이 적용한다(`FQSA` → `FQSB`, 확정).
- **이름은 한 번에 바꾼다.** `TQSA→TQSB`를 한 다음 `TQSB→TQSC`를 하면, 방금 바꾼 이름이 다시 바뀐다. 그래서 "JH 이름 → vplus 이름" 매핑표를 먼저 만들고, 그 표에 있는 이름만 단어 단위로 한 번에 바꾼다. 소스나 주석에 나오는 존재하지 않는 테이블 이름(예: `TQSA_ODAYSAFE_LOG`)은 매핑표에 없으므로 바꾸지 않는다.
- **vplus의 기존 객체는 하나도 바꾸지 않는다.** 객체는 `CREATE OR REPLACE`가 아니라 `CREATE`로 만든다. 같은 이름이 있으면 덮어쓰지 않고 오류가 나게 해서, 실수로 덮어쓰는 일을 막는다.

## 1-1. 데이터 복사 범위

**아래 14개 테이블만 데이터까지 복사한다.** 나머지 94개 테이블은 구조(테이블, PK·NOT NULL·DEFAULT, FK, 코멘트)만 만들고 데이터는 넣지 않는다. 14개는 공통코드처럼 정해진 코드를 담고 다른 테이블이 가져다 쓰는 기준 데이터다.

| # | JH 테이블 | vplus 테이블 | 설명 | JH 건수 |
|---:|---|---|---|---:|
| 1 | `TQSA_CKLST` | `TQSB_CKLST` | 본사점검체크리스트구분 | 118 |
| 2 | `TQSA_CKLST_ITM` | `TQSB_CKLST_ITM` | 본사점검체크리스트항목 | 395 |
| 3 | `TQSA_CTP` | `TQSB_CTP` | 안전공종코드 | 182 |
| 4 | `TQSA_CTPUNT_CHKITM` | `TQSB_CTPUNT_CHKITM` | 안전단위작업별 점검항목 | 12,485 |
| 5 | `TQSA_DEEDU_CD` | `TQSB_DEEDU_CD` | 교육세부코드 | 145 |
| 6 | `TQSA_DISASTER_CD` | `TQSB_DISASTER_CD` | 산업재해 발생형태코드 | 124 |
| 7 | `TQSA_DISASTER_DIV` | `TQSB_DISASTER_DIV` | 산업재해 발생형태구분 | 42 |
| 8 | `TQSA_EDU_CD` | `TQSB_EDU_CD` | 교육코드 | 9 |
| 9 | `TQSA_MSDS_CD` | `TQSB_MSDS_CD` | MSDS 코드관리(PK에 `SIT_CD` 포함, 현장별 코드) | 3 |
| 10 | `TQSA_AREC_CD` | `TQSB_AREC_CD` | 회의록코드 | 3 |
| 11 | `TQSA_SAFE_PERM_CD` | `TQSB_SAFE_PERM_CD` | 안전작업허가 코드 | 6 |
| 12 | `TQSA_SAFE_PERM_CPLN` | `TQSB_SAFE_PERM_CPLN` | 안전작업별 안전대책 | 27 |
| 13 | `TQSB_CTPUNT_CHKITM` | `TQSC_CTPUNT_CHKITM` | 안전단위작업별 점검항목 | 12,484 |
| 14 | `TQSA_CTPUNT` | `TQSB_CTPUNT` | 안전공종별 단위코드 (2026-11-13 추가) | 1,227 |
| | | | 합계 | 27,250 |

건수는 2026-11-13 조회 기준이다. 실제 복사할 때 다시 센다.

**FK 정합성**: 14번 `TQSA_CTPUNT`를 넣었으므로 안전공종 코드 계층(`CTP` → `CTPUNT` → `CTPUNT_CHKITM`)이 모두 데이터와 함께 복사된다. 그래서 4번과 13번이 참조하는 부모 키도 모두 존재한다.
- `FK_TQSA_CTPUNT_TO_TQSA_CTPUNT_CHKITM` → `FK_TQSB_CTPUNT_TO_TQSB_CTPUNT_CHKITM`
- `FK_TQSB_CTPUNT_TO_TQSB_CTPUNT_CHKITM` → `FK_TQSB_CTPUNT_TO_TQSC_CTPUNT_CHKITM`(1-3장)

이 밖에 데이터를 넣는 테이블 사이의 FK(`CTP`→`CTPUNT`, `EDU_CD`→`DEEDU_CD`, `SAFE_PERM_CD`→`SAFE_PERM_CPLN`)도 부모와 자식이 모두 목록 안에 있다. JH에서 이 FK들이 이미 검증된 상태라 그대로 복사하면 FK가 성립한다. 데이터가 없는 테이블을 자식으로 두는 FK(예: `TQSB_CTP`→`TQSB_VNDR`)는 문제가 되지 않는다.

## 1-2. PK 이름 정리

JH에서 테이블 이름과 맞지 않던 PK 10개는 vplus에서 `PK_<vplus 테이블명>`으로 만든다. PK를 받치는 인덱스도 같은 이름으로 만든다(JH도 PK와 인덱스 이름이 같다).

| vplus 테이블 | JH PK 이름 | 규칙대로 바꿨을 때 | **vplus PK 이름** |
|---|---|---|---|
| `TQSB_EDU_DRY` | `PK_TQSA_IDAC4` | `PK_TQSB_IDAC4` | `PK_TQSB_EDU_DRY` |
| `TQSB_EDU_MSDS` | `PK_TQSA_EDU2` | `PK_TQSB_EDU2` | `PK_TQSB_EDU_MSDS` |
| `TQSB_HLTH_CHKUP` | `PK_TQSA_IDAC5` | `PK_TQSB_IDAC5` | `PK_TQSB_HLTH_CHKUP` |
| `TQSB_HLTH_CHKUP_LIST` | `PK_TQSA_IDAC3` | `PK_TQSB_IDAC3` | `PK_TQSB_HLTH_CHKUP_LIST` |
| `TQSB_MSDS_CD` | `TQSA_MSDS_CD_PK` | `TQSB_MSDS_CD_PK` | `PK_TQSB_MSDS_CD` |
| `TQSB_RISK_AREC_TEMP` | `PK_TQSA_RISK_AREC` | `PK_TQSB_RISK_AREC` | `PK_TQSB_RISK_AREC_TEMP` |
| `TQSB_WEEK_WORK_LOG` | `PK_TQSA_ODAYSAFE_LOG` | `PK_TQSB_ODAYSAFE_LOG` | `PK_TQSB_WEEK_WORK_LOG` |
| `TQSB_WEEK_WORK_LOG_HO` | `PK_TQSA_ODAYSAFE_LOG_HO` | `PK_TQSB_ODAYSAFE_LOG_HO` | `PK_TQSB_WEEK_WORK_LOG_HO` |
| `TQSC_DAYSAFE_NAM` | `PK_TQSB_DAYSAFE_DT2` | `PK_TQSC_DAYSAFE_DT2` | `PK_TQSC_DAYSAFE_NAM` |
| `TQSC_VNDRNAM` | `PK_TQSB_SITENAM2` | `PK_TQSC_SITENAM2` | `PK_TQSC_VNDRNAM` |

- **확인한 것**
  - 새 PK 이름은 서로 겹치지 않고 vplus의 기존 이름과도 겹치지 않는다.
  - 가장 긴 이름은 24자다. 새로 만들 제약조건 이름 전체로 보면 가장 긴 것이 54자로, 128자 제한 안이다.
  - JH 프로시저·함수 소스에서 PK·인덱스 이름을 직접 쓰는 곳(힌트 등)은 0건이다. 그래서 이름을 바꿔도 소스에는 영향이 없다.
- **PK가 없는 테이블 13개는 JH처럼 PK 없이 만든다.**
  - `TQSB_ASSLOG_CIRC`, `TQSB_DRM`, `TQSB_DRM_ANNC`, `TQSB_EDU_CD_TEMP`, `TQSB_HOCHKRPT_ERR`, `TQSB_HOCHKRPT_PHOTO`, `TQSB_RISKPLAN`, `TQSB_RISKPLAN_D`, `TQSB_SEL_LST`, `TQSB_VIEW_HIS`, `TQSB_VIEW_REQ`, `TQSB_VIEW_REQ_LST`, `TQSC_CTPUNT_CHKITM_TMP`

## 1-3. FK 이름 정리

FK 31개는 모두 JH 이름 형식 그대로 `FK_<vplus 부모 테이블>_TO_<vplus 자식 테이블>`로 만든다. 28개는 규칙대로 바꾼 이름과 같고, 실제 테이블과 맞지 않던 3개만 이름이 달라진다.

| JH FK 이름 | 규칙대로 바꿨을 때 | 실제 부모 → 자식(vplus) | **vplus FK 이름** |
|---|---|---|---|
| `FK_TQSB_CTPUNT_TO_TQSB_CTPUNT_CHKITM` | `FK_TQSC_CTPUNT_TO_TQSC_CTPUNT_CHKITM` | `TQSB_CTPUNT` → `TQSC_CTPUNT_CHKITM` | `FK_TQSB_CTPUNT_TO_TQSC_CTPUNT_CHKITM` |
| `FK_TQSB_VNDR_TO_TQSB_VNDRNAM` | `FK_TQSC_VNDR_TO_TQSC_VNDRNAM` | `TQSB_VNDR` → `TQSC_VNDRNAM` | `FK_TQSB_VNDR_TO_TQSC_VNDRNAM` |
| `FK_TQSA_RISK_VNDR_TO_TQSA_RISK_AREC` | `FK_TQSB_RISK_VNDR_TO_TQSB_RISK_AREC` | `TQSB_RISK_VNDR` → `TQSB_RISK_AREC_TEMP` | `FK_TQSB_RISK_VNDR_TO_TQSB_RISK_AREC_TEMP` |

- **확인한 것**
  - 새 FK 이름 31개는 서로 겹치지 않고, 새 PK·그 밖의 제약조건 이름과도 겹치지 않으며, vplus의 기존 이름과도 겹치지 않는다.
  - 가장 긴 FK 이름은 54자(`FK_TQSB_WEEK_WORK_LOG_HO_TO_TQSB_WEEK_WORK_LOG_PLAN_HO`)로, 128자 제한 안이다.
  - JH 프로시저·함수 소스에서 FK 이름을 직접 쓰는 곳은 0건이다. 그래서 이름을 바꿔도 소스에는 영향이 없다.

## 2. 대상과 규모

| 구분 | JH 개수 | 복사 | 제외 | 비고 |
|---|---:|---:|---:|---|
| 테이블 `TQSA_*` | 94 | 94 | 0 | → `TQSB_*` |
| 테이블 `TQSB_*` | 14 | 14 | 0 | → `TQSC_*` |
| 프로시저 `PQSA_*` | 245 | 243 | 2 | → `PQSB_*`. ZTEST 관련(`PQSA_ZTEST`, `PQSA_ZTEST1`)은 **제외 확정** |
| 프로시저 `PQSB_*` | 31 | 31 | 0 | → `PQSC_*` |
| 함수 `FQSA_*` | 10 | 10 | 0 | → `FQSB_*` |
| 그 밖의 프로시저·함수 | 9 | 3 | 6 | 아래 표 |
| TYPE | 10 | 2 | 8 | 아래 표 |

바꾼 이름(테이블 108개, 프로시저·함수 284개, 제약조건·인덱스)은 서로 겹치지 않는다. vplus의 기존 이름과도 겹치지 않는다(확인함).

**이름이 바뀌지 않는 객체의 처리**

| 객체 | 종류 | vplus에 있음 | 처리 | 비고 |
|---|---|---|---|---|
| `FQSE_GET_AFTL_CNT` | FUNCTION | 있음(소스 같음) | 제외 | |
| `FQSZ_SIT_PROC` | FUNCTION | 있음(소스 같음) | 제외 | |
| `FQSZ_USR_INFO` | FUNCTION | 있음(소스 같음) | 제외 | |
| `PQSC_MMEDUPLAN_S` | PROCEDURE | 있음(소스 같음) | 제외 | vplus 쪽은 vplus의 `TQSA_MMEDUPLAN`을 그대로 쓴다 |
| `PQSD_SUBCONT_Q` | PROCEDURE | 있음(소스 같음) | 제외 | |
| `FQSZ_GET_CORP_NM` | FUNCTION | 없음 | 복사 | |
| `FQSZ_SAFT_DEFC_IF` | FUNCTION | 없음 | 복사 | |
| `PQSZ_IMPORT_EMPS_S` | PROCEDURE | 없음 | 복사 | 참조: `TQSA_SITENAM` → `TQSB_SITENAM` |
| `PQSZ_DATA_CLEAR_W` | PROCEDURE | 없음 | **제외 확정** | 데이터를 지우는 프로시저다. JH에서 이 프로시저를 호출하는 객체가 없어서, 빼도 다른 객체에 영향이 없다 |
| `OQSA_DRM_INFO`, `OQSA_DRM_INFO_LIST`, `OQSA_SITE_JOB`, `T_OQSA_SITE_JOB`, `OQSZ_SIT_PROC`, `T_OQSZ_SIT_PROC`, `OQSZ_USR_INFO`, `T_OQSZ_USR_INFO` | TYPE | 있음(정의 같음) | 제외 | 복사한 프로시저는 vplus의 기존 TYPE을 그대로 쓴다 |
| `QSSITEOBJ01`, `QSSITETAB01` | TYPE | 없음 | 복사 | `FQSB_GETCMSITE01_BY_SITECD`가 사용한다 |

## 3. 사전 확인 결과 (완료)

| 항목 | 결과 |
|---|---|
| 테이블·제약조건·인덱스 이름 충돌 | 없음 |
| 프로시저·함수의 바꾼 이름 충돌 | 없음(vplus에 `PQSB`·`PQSC`·`FQSB` 계열 객체가 없다. JH의 `PQSC_MMEDUPLAN_S`와 `PQSB→PQSC`로 바뀌는 이름도 겹치지 않는다) |
| 복사 대상이 참조하는 범위 밖 객체 | 41개(테이블 33, 함수 5, TYPE 2, 뷰 1). **모두 vplus에 있다** |
| 바꾼 뒤 참조하는 TQS 테이블 | 모두 이번 복사로 만들어진다 |
| 동적 SQL(`EXECUTE IMMEDIATE`, `DBMS_SQL`) | 없음 |
| DB 링크, 다른 스키마 참조 | 없음. 스키마 이름이 박힌 것은 `PQSA_ZTEST`, `PQSA_ZTEST1`뿐인데, 둘 다 제외한다 |
| ZTEST 관련 객체 | JH에서 이름에 ZTEST가 들어간 객체는 `PQSA_ZTEST`, `PQSA_ZTEST1` 두 개뿐이다. 이 둘을 호출하는 객체도, 이 둘이 참조하는 객체도 없다. 빼도 다른 객체에 영향이 없다 |
| JH 원본 상태 | 대상 객체가 모두 VALID이고 컴파일 오류가 없다 |
| vplus 권한 | `CREATE TABLE`, `CREATE PROCEDURE`, `CREATE TYPE`, `UNLIMITED TABLESPACE` 있음 |
| 스키마 간 권한 | 없음. 그래서 JH에서 읽고 vplus에 쓰는 Python 스크립트로 진행한다(JH는 바꾸지 않는다) |

**vplus 기준선**: vplus에는 지금도 INVALID인 QS 객체가 2개 있다(`PQSA_IDAC_MINUS_Q`, `FQSZ_SITE_JOB`). `TEST`로 시작하는 객체(`TEST_PQSA_*` 79개, 이 중 INVALID 74개)는 기준선과 검증 범위에서 뺀다. 모두 이관과는 무관하며 건드리지 않는다. 이관 후 검증에서는 이 목록을 기준선으로 삼아 "새로 생긴 INVALID"만 따진다.

**복사할 객체가 쓰는 제외 객체**: `FQSE_GET_AFTL_CNT`(`PQSA_MSDSMNG_Q`, `PQSA_YYTRGARSLT_Q`가 호출), `OQSA_DRM_INFO`·`OQSA_DRM_INFO_LIST`(`PQSA_DRM_Q`가 사용). 세 객체 모두 vplus에서 VALID이고 JH와 정의가 같아서, vplus 버전을 그대로 쓰면 된다.

## 4. 진행 단계

각 단계가 끝나면 결과를 보고하고, **승인을 받은 뒤 다음 단계로 넘어간다**(AGENTS.md 수정 절차). 모든 SQL은 실행 전에 파일로 만들어 검토할 수 있게 한다.

산출물 위치: `erp-jh/scripts/migration/` (생성 SQL, 매핑표, 로그) · 결과 보고서: `erp-jh/docs/`

### 0단계 — 결정 확정
6장의 결정 사항을 확정한다.

### 1단계 — 기준선 저장 (조회만)
- vplus의 `TQS*` 테이블(건수·제약조건)과 이름에 `QS`가 들어간 객체(목록, 상태(VALID/INVALID), `LAST_DDL_TIME`, 소스 해시)를 저장한다. `TEST`로 시작하는 객체와 그 밖의 vplus 객체는 저장하지 않는다. 이관 후 "기존 객체가 바뀌지 않았음"(0장 원칙)을 증명하는 데 쓴다.
- JH의 대상 객체 목록과 테이블별 건수를 저장한다.

### 2단계 — 매핑표와 SQL 생성 (조회만, 검토용)
- **매핑표**: JH 이름 → vplus 이름. 테이블 108개, 제약조건·인덱스, 이름을 바꿔 복사할 프로시저·함수 284개(ZTEST 2개 제외), 이름이 그대로인 복사 대상 5개(`FQSZ_GET_CORP_NM`, `FQSZ_SAFT_DEFC_IF`, `PQSZ_IMPORT_EMPS_S`, `QSSITEOBJ01`, `QSSITETAB01`), 제외 목록을 담는다.
- **테이블 DDL**: JH에서 `DBMS_METADATA.GET_DDL`로 뽑는다. 테이블스페이스·스토리지 옵션은 빼고, 매핑표대로 이름을 바꾼다. PK·NOT NULL·DEFAULT는 테이블과 함께 만들고, FK는 따로 분리한다.
- **코멘트**: JH 딕셔너리의 테이블·컬럼 코멘트를 매핑표대로 바꾼다.
- **PL/SQL 소스**: JH의 `USER_SOURCE`에서 뽑는다. 매핑표의 이름만 단어 단위로 한 번에 바꾸고, 앞에 `CREATE `를 붙인다.
- **되돌리기 스크립트**: 만들 객체 전부에 대한 DROP 문을 만든다(역순으로, 테이블은 `CASCADE CONSTRAINTS PURGE`).
- **치환 검증 리포트**: 객체마다 바뀐 이름의 목록을 만든다. 그리고 바꾼 소스에 `TQSA_`/`PQSA_`가 남아 있는지 검사한다. 매핑표에 없는 이름이라 일부러 남겨 둔 것이면 그 사유도 적는다.
- ⏸ **여기서 생성된 SQL과 리포트를 검토받는다.**

### 3단계 — 테이블 생성과 데이터 복사 (vplus에 쓰기)
1. 테이블 108개를 만든다(PK, NOT NULL, DEFAULT 포함, FK 제외).
2. 데이터 복사: **1-1장의 14개 테이블만** 복사한다. JH에서 묶음 단위로 읽어 vplus에 `executemany`로 넣고, 테이블마다 커밋한다. 14개에는 CLOB 컬럼이 없다.
3. FK 31개를 만든다.
4. 코멘트를 붙인다.
5. 검증
   - 데이터를 복사한 14개: 건수가 JH와 같은지, 행 내용이 같은지(PK 기준) 확인한다.
   - 구조만 만든 94개: 건수가 0인지 확인한다.
   - 108개 전체: 컬럼 정의(타입·길이·NULL·DEFAULT)가 JH와 같은지, FK가 ENABLED인지 확인한다.
- ⏸ 결과를 보고한다.

### 4단계 — TYPE 생성
- `QSSITEOBJ01`, 그다음 `QSSITETAB01`을 만든다.

### 5단계 — 함수·프로시저 생성
- 순서: 함수(`FQSB_*` 10개, `FQSZ_*` 2개) → 프로시저(`PQSB_*` 243개, `PQSC_*` 31개, `PQSZ_IMPORT_EMPS_S` 1개).
- 서로 호출하는 객체가 있어 처음에는 일부가 INVALID로 만들어질 수 있다. 모두 만든 뒤 새로 만든 객체만 `ALTER ... COMPILE`로 다시 컴파일한다. INVALID 수가 더 줄지 않을 때까지 반복한다.
- 남은 컴파일 오류는 `USER_ERRORS`로 모아서 보고한다. **오류를 고치려고 소스를 임의로 바꾸지 않는다.** 원인과 수정안을 보고하고 승인을 받는다.
- **실행 결과(2026-11-13)**: 287개 중 `PQSB_SEND_SMS_Q` 1개만 INVALID였다. vplus `THRA_BASEINFO`에 `WORK_CORP_CD` 컬럼이 없기 때문이다(JH에는 있음). 사용자 승인(B안)에 따라 이 프로시저 소스만 `A.WORK_CORP_CD` → `A.CORP_CD`로 고쳐 다시 만들었고, VALID가 됐다. 영향: JH 인사 899명 중 근무 회사코드와 소속 회사코드가 다른 93명은 근무부서 이름 대신 부서코드가 나올 수 있다. 이 밖에 소스를 고친 객체는 없다.
- ⏸ 결과를 보고한다.

### 6단계 — 최종 검증
- 새로 만든 객체가 모두 VALID인지 확인한다.
- **0장 원칙 검증**: vplus 기존 객체(1단계 범위: `TQS*` 테이블, 이름에 `QS`가 들어간 객체, `TEST*` 제외)의 목록, 상태, `LAST_DDL_TIME`, 테이블별 건수를 1단계 기준선과 비교한다. 바뀐 것이 0건이어야 한다. 1건이라도 있으면 즉시 보고한다.
- 새로 만든 객체 수가 매핑표와 같은지 확인한다(테이블 108, TYPE 2, 함수 12, 프로시저 275).
- 프로시저는 실행하지 않는다. 데이터를 바꾸는 프로시저가 있어서 컴파일 성공까지만 확인한다.

### 7단계 — 결과 보고
- `erp-jh/docs/`에 결과 보고서를 쓴다: 실제 만든 객체, 건수 검증, 컴파일 결과, 남은 문제, 되돌리기 방법.

## 5. 되돌리기

- 이번 작업은 vplus에 **새 객체를 만들기만** 한다. 기존 객체는 바꾸지 않는다.
- 문제가 생기면 2단계에서 만든 DROP 스크립트로 새 객체만 지우면 원래 상태로 돌아간다.
- 단계마다 결과를 저장하므로, 중간에 멈춰도 어디까지 만들었는지 알 수 있다.

## 6. 결정이 필요한 사항

| # | 항목 | 제안 |
|---|---|---|
| 1 | `FQSA` → `FQSB`처럼 함수에도 프로시저 규칙을 적용할지 | **확정(2026-11-13): 규칙대로 적용** |
| 2 | `PQSA_ZTEST`, `PQSA_ZTEST1`(테스트용이고 스키마 이름이 박혀 있음)을 복사할지 | **확정(2026-11-13): ZTEST 관련은 전부 제외** |
| 3 | `PQSZ_DATA_CLEAR_W`(데이터 삭제 프로시저)를 복사할지 | **확정(2026-11-13): 제외** |
| 4 | 개인정보 컬럼 `TQSA_IDAC.DSVC_RSDNNO`(→ `TQSB_IDAC`, 3건)의 값을 그대로 복사할지 | **해소(2026-11-13)**: `TQSA_IDAC`는 데이터 복사 대상(1-1장)이 아니라서 값이 복사되지 않는다 |
| 6 | 데이터까지 복사할 범위 | **확정(2026-11-13)**: 1-1장의 14개 테이블만 데이터를 복사하고, 나머지는 구조만 만든다 |
| 7 | `TQSA_CTPUNT`를 데이터 복사 대상에 넣을지 | **확정(2026-11-13): 넣는다** |
| 5 | 이름이 테이블과 맞지 않는 PK 10개와, 바꾼 뒤 실제 테이블과 맞지 않는 FK 이름 3개를 정리할지 | **확정(2026-11-13): PK는 `PK_<vplus 테이블명>`(1-2장), FK는 `FK_<vplus 부모>_TO_<vplus 자식>`(1-3장)으로 바꾼다** |

## 7. 이번 범위 밖 (참고)

- **vplus 앱 연결**: 새 프로시저(`PQSB_*` 등)를 vplus 앱 화면이나 매퍼에서 호출하도록 바꾸는 일은 포함하지 않는다.
- **같은 이름이라 제외한 객체**: vplus 버전을 그대로 쓴다. 제외한 5개는 모두 소스가 JH와 같다.
- **길이 차이**: vplus `TCMZ_SIT`의 컬럼이 JH보다 길다(`VARCHAR2(255 CHAR)`). 현재 데이터는 모두 JH 길이 안에 들어간다. 다만 `QSSITEOBJ01.SIT_CD VARCHAR2(6)`처럼 고정 길이를 쓰는 곳은 vplus에 7자 이상인 현장코드가 생기면 오류가 날 수 있다.
