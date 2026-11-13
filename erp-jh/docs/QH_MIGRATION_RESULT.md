# JH → vplus QH 객체 이관 결과 보고서

> 작업일: 2026-11-13 · 원본: JH `JH202610` · 대상: vplus `VPLUS202611A` (192.168.1.25:1521:ORCLU)
> 계획: [QH_MIGRATION_ROADMAP.md](QH_MIGRATION_ROADMAP.md) · 이름 규칙: [QS_TO_QH_RENAME_PLAN.md](QS_TO_QH_RENAME_PLAN.md) · 스크립트와 로그: `erp-jh/scripts/migration_qh/`

## 1. 요약

- JH의 TQS 테이블 108개와 QS 함수·프로시저·TYPE을 **QH 이름**으로 바꿔 vplus에 **추가**했다.
  - 이름 규칙: `QSA` → `QHA`, `QSB` → `QHB`, `FQSZ`/`PQSZ`/`QSSITE` → `FQHZ`/`PQHZ`/`QHSITE`.
  - 함수·프로시저·TYPE 소스 안의 이름도 같은 규칙으로 바꿨다.
- 새로 만든 객체 **397개 모두 VALID**이고, 컴파일 오류는 0건이다.
- **vplus 기존 객체는 하나도 바뀌지 않았다.** 이관 전 기준선과 비교해 확인했다.
- JH는 조회만 했다.
- 소스를 고친 객체는 `PQHA_SEND_SMS_Q` 1개다. 미리 승인된 수정이며, 생성 단계에서 자동으로 넣었다.
- 1차(QS 이름) 이관은 되돌렸고, QS 이름 객체는 vplus에 남아 있지 않다. 1차 기록은 `TQS_MIGRATION_*` 문서와 `scripts/migration/`에 있다.

## 2. 만든 객체

| 종류 | 개수 | vplus 이름 |
|---|---:|---|
| 테이블 | 108 | `TQHA_*` 94개(JH `TQSA_*`), `TQHB_*` 14개(JH `TQSB_*`) |
| PK(와 PK 인덱스) | 95 | `PK_<vplus 테이블명>`. PK가 없는 13개 테이블은 JH처럼 PK 없이 만들었다 |
| FK | 31 | `FK_<vplus 부모>_TO_<vplus 자식>` |
| 코멘트 | 2,247 | 테이블 107, 컬럼 2,140 |
| TYPE | 2 | `QHSITEOBJ01`, `QHSITETAB01` |
| 함수 | 12 | `FQHA_*` 10개, `FQHZ_GET_CORP_NM`, `FQHZ_SAFT_DEFC_IF` |
| 프로시저 | 275 | `PQHA_*` 243개, `PQHB_*` 31개, `PQHZ_IMPORT_EMPS_S` |

- 이름 대응표 전체는 `scripts/migration_qh/02_generate/mapping.csv`에 있다(만든 것 523행, 제외 16행).
- **소스 안의 이름**: 원본 이름 3,646곳을 바꿨다. 바꿀 대상은 테이블 108개와 함수·프로시저·TYPE 289개다.
- **소스에 그대로 둔 QS 이름**
  - vplus에 원래 있는 객체(`VQSZ_TRADE`, `VQSZ_SITEINFO`, `VQSZ_SUBCONT`, `VQSZ_CONT_INFO`, `FQSE_GET_AFTL_CNT`, `OQSA_DRM_INFO`, `OQSA_DRM_INFO_LIST`)를 호출하는 이름이다. 이 객체들은 vplus에 있는 것을 그대로 쓴다.
  - 그 밖에는 주석 안의 옛 이름과 `WITH` 절 이름 2개뿐이다.
  - 전체 목록은 `02_generate/80_replace_report.md`에 있다.

### 데이터를 복사한 테이블 (14개, 27,250건)

| JH | vplus | 건수 |
|---|---|---:|
| `TQSA_CKLST` | `TQHA_CKLST` | 118 |
| `TQSA_CKLST_ITM` | `TQHA_CKLST_ITM` | 395 |
| `TQSA_CTP` | `TQHA_CTP` | 182 |
| `TQSA_CTPUNT` | `TQHA_CTPUNT` | 1,227 |
| `TQSA_CTPUNT_CHKITM` | `TQHA_CTPUNT_CHKITM` | 12,485 |
| `TQSA_DEEDU_CD` | `TQHA_DEEDU_CD` | 145 |
| `TQSA_DISASTER_CD` | `TQHA_DISASTER_CD` | 124 |
| `TQSA_DISASTER_DIV` | `TQHA_DISASTER_DIV` | 42 |
| `TQSA_EDU_CD` | `TQHA_EDU_CD` | 9 |
| `TQSA_MSDS_CD` | `TQHA_MSDS_CD` | 3 |
| `TQSA_AREC_CD` | `TQHA_AREC_CD` | 3 |
| `TQSA_SAFE_PERM_CD` | `TQHA_SAFE_PERM_CD` | 6 |
| `TQSA_SAFE_PERM_CPLN` | `TQHA_SAFE_PERM_CPLN` | 27 |
| `TQSB_CTPUNT_CHKITM` | `TQHB_CTPUNT_CHKITM` | 12,484 |

나머지 94개 테이블은 구조만 만들었고, 데이터는 0건이다.

### 복사하지 않은 객체 (16개)

| 객체 | 사유 |
|---|---|
| `PQSA_ZTEST`, `PQSA_ZTEST1` | ZTEST 관련 제외 |
| `PQSZ_DATA_CLEAR_W` | 데이터 삭제 프로시저 제외 |
| `FQSE_GET_AFTL_CNT`, `FQSZ_SIT_PROC`, `FQSZ_USR_INFO`, `PQSC_MMEDUPLAN_S`, `PQSD_SUBCONT_Q` | vplus에 같은 이름이 있어서 vplus 것을 그대로 쓴다 |
| `OQSA_DRM_INFO`, `OQSA_DRM_INFO_LIST`, `OQSA_SITE_JOB`, `T_OQSA_SITE_JOB`, `OQSZ_SIT_PROC`, `T_OQSZ_SIT_PROC`, `OQSZ_USR_INFO`, `T_OQSZ_USR_INFO` (TYPE) | vplus에 같은 이름이 있어서 vplus 것을 그대로 쓴다 |

## 3. 진행 경과

| 단계 | 시각 | 내용 | 결과 |
|---|---|---|---|
| 1 | 13:55 | 기준선 저장(조회) | vplus 객체 394, 제약조건 213, 소스 221, 테이블 83. 1차 기준선과 같음 |
| 2 | 13:57 | 매핑표·SQL·되돌리기 스크립트 생성(조회) | 자동 검사 모두 OK |
| 3 | 13:59~14:00 | 테이블·데이터·FK·코멘트 | 오류 없음, 검증 OK |
| 4 | 14:26 | TYPE 2개 | VALID, JH 정의와 같음 |
| 5 | 14:28 | 함수 12, 프로시저 275 | 처음에 1개 INVALID → 다시 컴파일 1회 후 모두 VALID |
| 6 | 14:29 | 최종 검증(조회) | 19개 항목 모두 OK |

## 4. 소스를 고친 객체 (1건)

| 항목 | 내용 |
|---|---|
| 객체 | `PQHA_SEND_SMS_Q` (JH `PQSA_SEND_SMS_Q`) |
| 원인 | vplus 공통 테이블 `THRA_BASEINFO`에 `WORK_CORP_CD` 컬럼이 없다(JH에는 있다). 1차 이관 5단계에서 `ORA-00904`로 확인했다 |
| 수정 | `LEFT OUTER JOIN THRZ_DEPT C ON C.CORP_CD = A.WORK_CORP_CD` → `... = A.CORP_CD` (승인된 B안) |
| 적용 방식 | `gen_step2.py` 안에 넣었다. 그래서 SQL을 다시 생성해도 수정이 유지된다 |
| 영향 | 근무부서 이름을 찾는 조인이 소속 회사 기준으로 바뀐다. JH 인사 899명 중 근무 회사코드와 소속 회사코드가 다른 93명은, 근무부서 이름 대신 부서코드가 나올 수 있다. 조회 결과에서 사람이 빠지지는 않는다 |

## 5. 검증 결과 (6단계)

| 검사 | 결과 |
|---|---|
| 새 객체 수(테이블 108, TYPE 2, 함수 12, 프로시저 275) | 매핑표와 같음 |
| 새 객체 상태 / 컴파일 오류 | 모두 VALID / 0건 |
| PK 95, FK 31, PK 인덱스 95 | 이름이 매핑표와 같음. 모두 ENABLED·VALIDATED, 인덱스 VALID |
| vplus 소스와 생성 SQL | 289개 모두 같음(공백 무시) |
| 데이터 14개 / 구조만 94개 | 건수·행 내용이 JH와 같음(3단계에서 전체 행 비교) / 모두 0건 |
| 컬럼 정의(타입·길이·NULL·DEFAULT) | 108개 모두 JH와 같음(3단계) |
| **기존 vplus 객체(기준선 비교)** | 바뀜 0, 사라짐 0, 이관과 관계없는 추가 0 |
| 기준선 범위의 INVALID | 이관 전과 같은 2개(`FQSZ_SITE_JOB`, `PQSA_IDAC_MINUS_Q`). 새로 생긴 INVALID 없음 |

프로시저는 실행하지 않았다. 데이터를 바꾸는 프로시저가 있어서 컴파일 성공까지만 확인했다.

## 6. 되돌리기

- `scripts/migration_qh/02_generate/99_rollback.sql`을 실행하면 이번에 만든 객체만 지운다.
  - 지우는 순서: 프로시저 → 함수 → TYPE(`QHSITETAB01` → `QHSITEOBJ01`) → 테이블(`CASCADE CONSTRAINTS PURGE`).
- 지우기 전에 대상이 매핑표에 있고 이번 작업 시간에 만든 객체인지 확인한다. 1차의 `scripts/migration/07_rollback/run_rollback.py`와 같은 방식이다.
- 테이블을 지우면 PK, FK, 인덱스, 코멘트, 복사한 데이터도 함께 지워진다.

## 7. 남은 사항

| # | 내용 | 비고 |
|---|---|---|
| 1 | vplus 앱(화면·매퍼)이 새 객체(`PQHA_*` 등)를 호출하도록 바꾸는 일은 이번 범위가 아니다 | |
| 2 | `QHSITEOBJ01.SIT_CD`는 `VARCHAR2(6)`이다 | vplus에 7자 이상인 현장코드가 생기면 `FQHA_GETCMSITE01_BY_SITECD`에서 오류가 날 수 있다 |
| 3 | 기준선 범위(`TQS*`/`TQH*` 테이블, 이름에 `QS`/`QH`가 들어간 객체, `TEST*` 제외) 밖의 vplus 객체는 비교하지 않았다 | 이관 작업은 모두 새 객체 `CREATE`와 새 테이블 `INSERT`였다 |
| 4 | 1차(QS) 산출물(`scripts/migration/`, `TQS_MIGRATION_ROADMAP.md`, `TQS_MIGRATION_RESULT.md`)은 기록으로 남아 있다 | 필요 없으면 정리할 수 있다 |

## 8. 산출물

스크립트는 DB 비밀번호를 환경변수 `DB_PASSWORD`에서 읽는다. 예: PowerShell `$env:DB_PASSWORD='...'; python -I scripts/migration_qh/06_verify/run_step6.py`

| 폴더 | 내용 |
|---|---|
| `scripts/migration_qh/01_baseline/` | 이관 전 기준선, `baseline.py` |
| `scripts/migration_qh/02_generate/` | `mapping.csv`, 생성 SQL(10~70), 치환 리포트(80), 되돌리기(99), `gen_step2.py` |
| `scripts/migration_qh/03_tables/` | `run_step3.py`, `step3.log`, `step3_result.json` |
| `scripts/migration_qh/04_types/` | `run_step4.py`, `step4.log`, `step4_result.json` |
| `scripts/migration_qh/05_code/` | `run_step5.py`, `step5.log`, `step5_result.json` |
| `scripts/migration_qh/06_verify/` | `run_step6.py`, `step6_result.md`, `step6_result.json`, `after_baseline/` |
