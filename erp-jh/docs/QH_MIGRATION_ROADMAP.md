# JH → vplus QH 객체 이관 로드맵

> 작성일: 2026-11-13 · 원본: JH `JH202610` · 대상: vplus `VPLUS202611A` (둘 다 192.168.1.25:1521:ORCLU)
> 이름 규칙 근거: [QS_TO_QH_RENAME_PLAN.md](QS_TO_QH_RENAME_PLAN.md) · 1차(QS 이름) 진행 기록: [TQS_MIGRATION_ROADMAP.md](TQS_MIGRATION_ROADMAP.md), [TQS_MIGRATION_RESULT.md](TQS_MIGRATION_RESULT.md)
> 아직 DB는 바꾸지 않았다. 아래 수치는 두 DB를 조회해서 확인한 값이다.

1차 이관(QS 이름)은 되돌렸고, vplus는 이관 전 기준선과 같은 상태다(2026-11-13 13:46 확인). 이 로드맵은 **같은 대상을 QH 이름으로 다시 이관**하는 절차다. 대상, 데이터 범위, 제외 객체, 소스 수정 1건은 1차와 같고 **이름만 다르다.**

## 0. 기본 원칙 (최우선)

> **vplus의 기존 DB는 변경하지 않는다. JH의 객체가 vplus에 추가만 된다.**
> **JH DB는 읽기만 한다.**

| 하는 것 | 하지 않는 것 |
|---|---|
| vplus에 새 테이블·제약조건·인덱스·코멘트·TYPE·함수·프로시저를 **만든다**(`CREATE`) | vplus 기존 객체를 `ALTER`/`DROP`/`CREATE OR REPLACE`/`RENAME`하지 않는다 |
| **새로 만든 테이블에만** 데이터를 넣는다 | vplus 기존 테이블에 `INSERT`/`UPDATE`/`DELETE`/`TRUNCATE`를 하지 않는다 |
| **새로 만든 객체만** 다시 컴파일한다 | vplus에서 이미 INVALID인 기존 객체를 다시 컴파일하거나 고치지 않는다 |
| 새 객체가 vplus 기존 객체(공통 테이블, `VQSZ_*` 뷰, `FQSE_GET_AFTL_CNT` 등)를 **읽거나 호출**하는 것은 허용한다 | 기존 객체의 코멘트, 권한, 통계, 시노님을 바꾸지 않는다 |
| JH는 조회(SELECT, `DBMS_METADATA`, 딕셔너리)만 한다 | JH에 DDL, DML, GRANT를 하지 않는다 |

**원칙을 지키는 장치**

1. **CREATE만 쓴다.** 같은 이름이 있으면 덮어쓰지 않고 오류로 멈춘다.
2. **이름이 겹치지 않는다(확인함).** 새 이름 523개(테이블 108, PK 95, FK 31, TYPE 2, 함수 12, 프로시저 275)는 vplus 기존 객체·제약조건과 겹치지 않는다. vplus에는 `QH`로 시작하는 객체가 하나도 없다.
3. **기존 객체가 새 이름을 쓰지 않는다(확인함).** vplus 기존 소스·뷰 중 새 이름을 참조하는 것은 0건이다.
4. **실행 전후로 비교한다.** 1단계 기준선과 6단계 결과를 비교해 기존 객체의 변화가 0건이어야 한다.
5. **되돌리기는 추가한 객체만 지운다.**

## 1. 이관 규칙

| 대상 | JH 원본 | **vplus 이름** | 예시 |
|---|---|---|---|
| 테이블 | `TQSA_*` | **`TQHA_*`** | `TQSA_RISK_CHK` → `TQHA_RISK_CHK` |
| 테이블 | `TQSB_*` | **`TQHB_*`** | `TQSB_RISK_CHK` → `TQHB_RISK_CHK` |
| PK(와 PK 인덱스) | | **`PK_<vplus 테이블명>`** | `PK_TQSA_IDAC4`(`TQSA_EDU_DRY`) → `PK_TQHA_EDU_DRY` |
| FK | | **`FK_<vplus 부모>_TO_<vplus 자식>`** | `FK_TQSA_CTP_TO_TQSA_CTPUNT` → `FK_TQHA_CTP_TO_TQHA_CTPUNT` |
| 프로시저 | `PQSA_*` / `PQSB_*` | **`PQHA_*` / `PQHB_*`** | `PQSA_RISK_CHK_S` → `PQHA_RISK_CHK_S` |
| 함수 | `FQSA_*` | **`FQHA_*`** | `FQSA_GET_TELNO` → `FQHA_GET_TELNO` |
| 이름에 A/B가 없는 복사 대상 | `FQSZ_*`, `PQSZ_*`, `QSSITE*` | **`FQHZ_*`, `PQHZ_*`, `QHSITE*`** | `PQSZ_IMPORT_EMPS_S` → `PQHZ_IMPORT_EMPS_S` |
| **프로시저·함수·TYPE 소스 내용** | | **소스 안의 테이블·함수·프로시저·TYPE 이름도 위 규칙대로 바꾼다** | `FROM TQSA_RISK_CHK` → `FROM TQHA_RISK_CHK`, `PQSB_X(...)` 호출 → `PQHB_X(...)` |

- 요약하면 **`QSA` → `QHA`, `QSB` → `QHB`**이고, 끝 글자가 JH와 같다.
- **이름은 매핑표로 한 번에 바꾼다.** 매핑표(JH 이름 → vplus 이름)에 있는 이름만 단어 단위로 바꾼다. 테이블 108개와 복사하는 함수·프로시저·TYPE 289개가 대상이다.
- **소스에서 바꾸지 않는 이름**
  - vplus에 원래 있는 QS 객체: `VQSZ_TRADE`(31개 객체가 사용), `VQSZ_SITEINFO`(18), `VQSZ_SUBCONT`(3), `VQSZ_CONT_INFO`(1), `FQSE_GET_AFTL_CNT`(2), `OQSA_DRM_INFO`·`OQSA_DRM_INFO_LIST`(1). 바꾸면 찾지 못해 INVALID가 된다.
  - 주석 안의 옛 이름, `WITH` 절 이름(`TQSA_PRES_HS_PER`, `TQSA_PRES_CU_PER`). 실행과 관계없다.
  - 컬럼 이름과 데이터 값(예: 코드 값 `QS0730101`).
- **소스 수정 1건(승인됨)**: `PQHA_SEND_SMS_Q`(JH `PQSA_SEND_SMS_Q`)의 `A.WORK_CORP_CD`를 `A.CORP_CD`로 바꾼다. vplus `THRA_BASEINFO`에 `WORK_CORP_CD` 컬럼이 없어서다(1차 5단계에서 확인).

## 1-1. 데이터 복사 범위 (14개 테이블)

나머지 94개 테이블은 구조(테이블, PK·NOT NULL·DEFAULT, FK, 코멘트)만 만든다.

| # | JH | **vplus** | 설명 | JH 건수 |
|---:|---|---|---|---:|
| 1 | `TQSA_CKLST` | `TQHA_CKLST` | 본사점검체크리스트구분 | 118 |
| 2 | `TQSA_CKLST_ITM` | `TQHA_CKLST_ITM` | 본사점검체크리스트항목 | 395 |
| 3 | `TQSA_CTP` | `TQHA_CTP` | 안전공종코드 | 182 |
| 4 | `TQSA_CTPUNT` | `TQHA_CTPUNT` | 안전공종별 단위코드 | 1,227 |
| 5 | `TQSA_CTPUNT_CHKITM` | `TQHA_CTPUNT_CHKITM` | 안전단위작업별 점검항목 | 12,485 |
| 6 | `TQSA_DEEDU_CD` | `TQHA_DEEDU_CD` | 교육세부코드 | 145 |
| 7 | `TQSA_DISASTER_CD` | `TQHA_DISASTER_CD` | 산업재해 발생형태코드 | 124 |
| 8 | `TQSA_DISASTER_DIV` | `TQHA_DISASTER_DIV` | 산업재해 발생형태구분 | 42 |
| 9 | `TQSA_EDU_CD` | `TQHA_EDU_CD` | 교육코드 | 9 |
| 10 | `TQSA_MSDS_CD` | `TQHA_MSDS_CD` | MSDS 코드관리 | 3 |
| 11 | `TQSA_AREC_CD` | `TQHA_AREC_CD` | 회의록코드 | 3 |
| 12 | `TQSA_SAFE_PERM_CD` | `TQHA_SAFE_PERM_CD` | 안전작업허가 코드 | 6 |
| 13 | `TQSA_SAFE_PERM_CPLN` | `TQHA_SAFE_PERM_CPLN` | 안전작업별 안전대책 | 27 |
| 14 | `TQSB_CTPUNT_CHKITM` | `TQHB_CTPUNT_CHKITM` | 안전단위작업별 점검항목 | 12,484 |
| | | | 합계 | 27,250 |

건수는 2026-11-13 기준이다. 실행할 때 다시 센다.

## 1-2. PK·FK 이름 정리

PK 95개는 모두 `PK_<vplus 테이블명>`이다. JH에서 테이블 이름과 맞지 않던 10개만 규칙대로 바꾼 이름과 다르다.

| vplus 테이블 | JH PK | **vplus PK** |
|---|---|---|
| `TQHA_EDU_DRY` | `PK_TQSA_IDAC4` | `PK_TQHA_EDU_DRY` |
| `TQHA_EDU_MSDS` | `PK_TQSA_EDU2` | `PK_TQHA_EDU_MSDS` |
| `TQHA_HLTH_CHKUP` | `PK_TQSA_IDAC5` | `PK_TQHA_HLTH_CHKUP` |
| `TQHA_HLTH_CHKUP_LIST` | `PK_TQSA_IDAC3` | `PK_TQHA_HLTH_CHKUP_LIST` |
| `TQHA_MSDS_CD` | `TQSA_MSDS_CD_PK` | `PK_TQHA_MSDS_CD` |
| `TQHA_RISK_AREC_TEMP` | `PK_TQSA_RISK_AREC` | `PK_TQHA_RISK_AREC_TEMP` |
| `TQHA_WEEK_WORK_LOG` | `PK_TQSA_ODAYSAFE_LOG` | `PK_TQHA_WEEK_WORK_LOG` |
| `TQHA_WEEK_WORK_LOG_HO` | `PK_TQSA_ODAYSAFE_LOG_HO` | `PK_TQHA_WEEK_WORK_LOG_HO` |
| `TQHB_DAYSAFE_NAM` | `PK_TQSB_DAYSAFE_DT2` | `PK_TQHB_DAYSAFE_NAM` |
| `TQHB_VNDRNAM` | `PK_TQSB_SITENAM2` | `PK_TQHB_VNDRNAM` |

FK 31개는 모두 `FK_<vplus 부모>_TO_<vplus 자식>`이다. 실제 테이블과 이름이 맞지 않던 3개는 아래처럼 정리된다.

| JH FK | 실제 부모 → 자식(vplus) | **vplus FK** |
|---|---|---|
| `FK_TQSB_CTPUNT_TO_TQSB_CTPUNT_CHKITM` | `TQHA_CTPUNT` → `TQHB_CTPUNT_CHKITM` | `FK_TQHA_CTPUNT_TO_TQHB_CTPUNT_CHKITM` |
| `FK_TQSB_VNDR_TO_TQSB_VNDRNAM` | `TQHA_VNDR` → `TQHB_VNDRNAM` | `FK_TQHA_VNDR_TO_TQHB_VNDRNAM` |
| `FK_TQSA_RISK_VNDR_TO_TQSA_RISK_AREC` | `TQHA_RISK_VNDR` → `TQHA_RISK_AREC_TEMP` | `FK_TQHA_RISK_VNDR_TO_TQHA_RISK_AREC_TEMP` |

PK가 없는 13개 테이블은 JH처럼 PK 없이 만든다. 전체 이름 목록은 [QS_TO_QH_RENAME_PLAN.md](QS_TO_QH_RENAME_PLAN.md) 부록 A~C에 있다.

## 2. 대상과 규모

| 구분 | JH | 복사 | 제외 | vplus 이름 |
|---|---:|---:|---:|---|
| 테이블 `TQSA_*` | 94 | 94 | 0 | `TQHA_*` |
| 테이블 `TQSB_*` | 14 | 14 | 0 | `TQHB_*` |
| 프로시저 `PQSA_*` | 245 | 243 | 2 | `PQHA_*` (`PQSA_ZTEST`, `PQSA_ZTEST1` 제외) |
| 프로시저 `PQSB_*` | 31 | 31 | 0 | `PQHB_*` |
| 함수 `FQSA_*` | 10 | 10 | 0 | `FQHA_*` |
| 그 밖의 함수·프로시저 | 9 | 3 | 6 | `FQHZ_GET_CORP_NM`, `FQHZ_SAFT_DEFC_IF`, `PQHZ_IMPORT_EMPS_S` |
| TYPE | 10 | 2 | 8 | `QHSITEOBJ01`, `QHSITETAB01` |

**제외(16개)**: `PQSA_ZTEST`, `PQSA_ZTEST1`, `PQSZ_DATA_CLEAR_W`, 그리고 vplus에 같은 이름이 있어 vplus 것을 쓰는 13개(`FQSE_GET_AFTL_CNT`, `FQSZ_SIT_PROC`, `FQSZ_USR_INFO`, `PQSC_MMEDUPLAN_S`, `PQSD_SUBCONT_Q`, TYPE 8개).

## 3. 사전 확인 결과

| 항목 | 결과 |
|---|---|
| 새 이름 523개의 중복 / vplus 기존 이름과 충돌 | 0건 / 0건 |
| vplus에 `QH`로 시작하는 객체 | 없음 |
| vplus 기존 소스·뷰가 새 이름을 참조 | 0건 |
| JH 소스에 원래 `QH` 이름이 있는지 | 없음 |
| 가장 긴 이름 | 54자(128자 제한 안) |
| 복사 대상이 참조하는 범위 밖 객체 | 모두 vplus에 있다(1차에서 확인) |
| 동적 SQL, DB 링크, 다른 스키마 참조 | 없음 |
| 컬럼 차이로 인한 오류 | 1차 5단계에서 `SEND_SMS_Q` 1건만 확인됐다. 1장의 소스 수정으로 해결한다 |
| vplus 현재 상태 | 1차 이관을 모두 되돌려 기준선과 같다 |
| vplus 기준선 범위의 INVALID | 2개(`FQSZ_SITE_JOB`, `PQSA_IDAC_MINUS_Q`). 이관과 관계없다 |

## 4. 진행 단계

각 단계가 끝나면 결과를 보고하고, **승인을 받은 뒤 다음 단계로 넘어간다**(AGENTS.md). 모든 SQL은 실행 전에 파일로 만들어 검토받는다.

산출물 위치: `erp-jh/scripts/migration_qh/` · 결과 보고서: `erp-jh/docs/QH_MIGRATION_RESULT.md`
스크립트는 DB 비밀번호를 환경변수 `DB_PASSWORD`에서 읽는다. 1차 스크립트(`scripts/migration/`)를 복사해 이름 규칙만 바꿔 쓴다.

### 1단계 — 기준선 저장 (조회만)
- 1차와 같은 범위(`TQS*` 테이블, 이름에 `QS`가 들어간 객체, `TEST*` 제외)에 **`TQH*` 테이블과 이름에 `QH`가 들어간 객체를 더해** 다시 저장한다. 1차 이후 vplus가 바뀌었을 수 있어서다.
- 1차 기준선(`scripts/migration/01_baseline`)과 비교해 차이를 보고한다.
- ⏸ 보고

### 2단계 — 매핑표와 SQL 생성 (조회만, 검토용)
- `gen_step2.py`의 이름 규칙을 QH로 바꾼다(`QSA`→`QHA`, `QSB`→`QHB`, `FQSZ`→`FQHZ`, `PQSZ`→`PQHZ`, `QSSITE`→`QHSITE`).
- **`SEND_SMS_Q` 소스 수정을 생성 스크립트 안에 넣는다.** 1차처럼 생성한 뒤 손으로 고치지 않는다. 다시 생성해도 수정이 사라지지 않게 하기 위해서다.
- 산출물: `mapping.csv`, `10_tables.sql`, `20_data_tables.csv`, `30_fk.sql`, `40_comments.sql`, `50_types.sql`, `60_functions.sql`, `70_procedures.sql`, `80_replace_report.md`, `99_rollback.sql`.
- 자동 검사
  - 객체 수: 테이블 108, PK 95, FK 31, TYPE 2, 함수 12, 프로시저 275
  - 새 이름 중복·vplus 충돌 0, `CREATE OR REPLACE`·`JH202610`·TABLESPACE 0
  - **소스에 바꿔야 할 JH 이름(매핑표에 있는 `TQSA_`/`TQSB_`/`PQSA_`/`PQSB_`/`FQSA_`/`FQSZ_`/`PQSZ_`/`QSSITE`)이 남지 않았는지**
  - **소스에 1차 이름(`TQSB_`/`TQSC_`/`PQSB_`/`PQSC_`/`FQSB_` 등 QS 계열 새 이름)이 섞이지 않았는지**
  - 원본 이름 수와 바뀐 이름 수가 같은지(1차 기준 3,213곳)
- ⏸ 생성된 SQL과 리포트를 검토받는다.

### 3단계 — 테이블 생성과 데이터 복사 (vplus에 쓰기)
1. 테이블 108개(PK, NOT NULL, DEFAULT 포함, FK 제외)
2. 14개 테이블 데이터 복사(테이블마다 커밋)
3. FK 31개
4. 코멘트(테이블 107, 컬럼 2,140)
5. 검증: 14개는 건수·행 내용이 JH와 같은지, 94개는 0건인지, 컬럼 정의가 같은지, PK·FK가 ENABLED·VALIDATED인지
- ⏸ 보고

### 4단계 — TYPE 생성
- `QHSITEOBJ01` → `QHSITETAB01`. JH와 정의가 같은지 확인한다.
- ⏸ 보고

### 5단계 — 함수·프로시저 생성
- 함수 12개(`FQHA_*` 10, `FQHZ_*` 2) → 프로시저 275개(`PQHA_*` 243, `PQHB_*` 31, `PQHZ_IMPORT_EMPS_S`).
- 새로 만든 객체 중 INVALID만 다시 컴파일한다. INVALID가 더 줄지 않을 때까지 반복한다.
- 남은 오류는 `USER_ERRORS`로 모아 보고한다. **소스를 임의로 고치지 않는다.** 1차에서는 `SEND_SMS_Q` 말고는 오류가 없었다.
- ⏸ 보고

### 6단계 — 최종 검증 (조회만)
- 새 객체 수와 상태(모두 VALID), PK·FK 이름과 상태, vplus 소스가 생성 SQL과 같은지, 데이터 건수.
- **0장 원칙 검증**: 1단계 기준선과 비교해 기존 객체의 변화가 0건이어야 한다.
- 프로시저는 실행하지 않는다(데이터를 바꾸는 프로시저가 있다).
- ⏸ 보고

### 7단계 — 결과 보고
- `erp-jh/docs/QH_MIGRATION_RESULT.md`를 쓴다.

## 5. 되돌리기

- `migration_qh/02_generate/99_rollback.sql`이 이번에 만든 객체만 지운다(프로시저 → 함수 → TYPE → 테이블 `CASCADE CONSTRAINTS PURGE`).
- 지우기 전에 대상이 매핑표에 있고 이번 작업 시간에 만들어진 객체인지 확인한다(1차 `07_rollback`과 같은 방식).
- 단계마다 로그를 남기므로 중간에 멈춰도 어디까지 만들었는지 알 수 있다.

## 6. 결정 사항 (모두 확정)

| # | 항목 | 결정 |
|---|---|---|
| 1 | 함수에도 이름 규칙 적용 | 적용(`FQSA` → `FQHA`) |
| 2 | ZTEST 관련 | 제외 |
| 3 | `PQSZ_DATA_CLEAR_W` | 제외 |
| 4 | 데이터 복사 범위 | 1-1장의 14개만 |
| 5 | PK·FK 이름 | `PK_<테이블>`, `FK_<부모>_TO_<자식>` |
| 6 | 이름 변경 QS → QH | 테이블·프로시저·함수 모두 `QSA`→`QHA`, `QSB`→`QHB` |
| 7 | 이름에 A/B가 없는 복사 대상 5개 | `QS`→`QH` (`FQHZ_*`, `PQHZ_*`, `QHSITE*`) |
| 8 | 1차에서 남긴 QS TYPE | 삭제함(13:46) |
| 9 | `SEND_SMS_Q` 컬럼 오류 | B안: `A.WORK_CORP_CD` → `A.CORP_CD` |

## 7. 이번 범위 밖

- vplus 앱(화면·매퍼)이 새 객체(`PQHA_*` 등)를 호출하도록 바꾸는 일.
- `QHSITEOBJ01.SIT_CD`는 `VARCHAR2(6)`이다. vplus에 7자 이상인 현장코드가 생기면 `FQHA_GETCMSITE01_BY_SITECD`에서 오류가 날 수 있다.
- 1차 산출물(`scripts/migration/`, `TQS_MIGRATION_*` 문서)은 기록으로 그대로 둔다.
