# JH → vplus QS 객체 이관 결과 보고서

> 작업일: 2026-11-13 · 원본: JH `JH202610` · 대상: vplus `VPLUS202611A` (192.168.1.25:1521:ORCLU)
> 계획 문서: [TQS_MIGRATION_ROADMAP.md](TQS_MIGRATION_ROADMAP.md) · 스크립트와 로그: `erp-jh/scripts/migration/`

## 1. 요약

- JH의 TQS 테이블 108개와 QS 함수·프로시저·TYPE을, 이름 규칙(`TQSA→TQSB`, `TQSB→TQSC`, `PQSA→PQSB`, `PQSB→PQSC`, `FQSA→FQSB`)대로 이름을 바꿔 vplus에 **추가**했다.
- 새로 만든 객체는 **모두 VALID**다. 컴파일 오류는 0건이다.
- **vplus의 기존 객체는 하나도 바뀌지 않았다.** 이관 범위(`TQS*` 테이블, 이름에 `QS`가 들어간 객체, `TEST*` 제외)의 기준선과 비교해 확인했다.
- JH는 조회만 했다.
- 소스를 고친 객체는 1개다(`PQSB_SEND_SMS_Q`, 사용자 승인). 자세한 내용은 4장에 있다.

## 2. 만든 객체

| 종류 | 개수 | 내용 |
|---|---:|---|
| 테이블 | 108 | `TQSA_*` 94개 → `TQSB_*`, `TQSB_*` 14개 → `TQSC_*` |
| PK (와 PK 인덱스) | 95 | `PK_<vplus 테이블명>`. PK가 없는 13개 테이블은 JH처럼 PK 없이 만들었다 |
| FK | 31 | `FK_<vplus 부모>_TO_<vplus 자식>` |
| 코멘트 | 2,247 | 테이블 107개, 컬럼 2,140개 |
| TYPE | 2 | `QSSITEOBJ01`, `QSSITETAB01` (이름 그대로) |
| 함수 | 12 | `FQSB_*` 10개, `FQSZ_GET_CORP_NM`, `FQSZ_SAFT_DEFC_IF` |
| 프로시저 | 275 | `PQSB_*` 243개, `PQSC_*` 31개, `PQSZ_IMPORT_EMPS_S` |

- 이름 대응표 전체는 `scripts/migration/02_generate/mapping.csv`에 있다.
- 함수·프로시저 소스 안의 테이블 이름도 같은 규칙으로 바꿨다. 289개 객체에서 3,213곳이다.
- 다른 함수·프로시저를 부르는 이름도 같은 규칙으로 바꿨다. 24곳이다.
- 소스에 남은 옛 이름은 주석 안의 이름과 `WITH` 절 이름 2개(`TQSA_PRES_HS_PER`, `TQSA_PRES_CU_PER`)뿐이다. 둘 다 실행과 관계없다. 목록은 `02_generate/80_replace_report.md`에 있다.

### 데이터를 복사한 테이블 (14개, 27,250건)

| JH | vplus | 건수 |
|---|---|---:|
| `TQSA_CKLST` | `TQSB_CKLST` | 118 |
| `TQSA_CKLST_ITM` | `TQSB_CKLST_ITM` | 395 |
| `TQSA_CTP` | `TQSB_CTP` | 182 |
| `TQSA_CTPUNT` | `TQSB_CTPUNT` | 1,227 |
| `TQSA_CTPUNT_CHKITM` | `TQSB_CTPUNT_CHKITM` | 12,485 |
| `TQSA_DEEDU_CD` | `TQSB_DEEDU_CD` | 145 |
| `TQSA_DISASTER_CD` | `TQSB_DISASTER_CD` | 124 |
| `TQSA_DISASTER_DIV` | `TQSB_DISASTER_DIV` | 42 |
| `TQSA_EDU_CD` | `TQSB_EDU_CD` | 9 |
| `TQSA_MSDS_CD` | `TQSB_MSDS_CD` | 3 |
| `TQSA_AREC_CD` | `TQSB_AREC_CD` | 3 |
| `TQSA_SAFE_PERM_CD` | `TQSB_SAFE_PERM_CD` | 6 |
| `TQSA_SAFE_PERM_CPLN` | `TQSB_SAFE_PERM_CPLN` | 27 |
| `TQSB_CTPUNT_CHKITM` | `TQSC_CTPUNT_CHKITM` | 12,484 |

나머지 94개 테이블은 구조만 만들었고 데이터는 0건이다.

### 복사하지 않은 객체 (16개)

| 객체 | 사유 |
|---|---|
| `PQSA_ZTEST`, `PQSA_ZTEST1` | ZTEST 관련 제외(결정 2) |
| `PQSZ_DATA_CLEAR_W` | 데이터 삭제 프로시저 제외(결정 3) |
| `FQSE_GET_AFTL_CNT`, `FQSZ_SIT_PROC`, `FQSZ_USR_INFO`, `PQSC_MMEDUPLAN_S`, `PQSD_SUBCONT_Q` | vplus에 같은 이름이 있음. vplus 것을 그대로 쓴다 |
| `OQSA_DRM_INFO`, `OQSA_DRM_INFO_LIST`, `OQSA_SITE_JOB`, `T_OQSA_SITE_JOB`, `OQSZ_SIT_PROC`, `T_OQSZ_SIT_PROC`, `OQSZ_USR_INFO`, `T_OQSZ_USR_INFO` (TYPE) | vplus에 같은 이름이 있음. vplus 것을 그대로 쓴다 |

## 3. 진행 경과

| 단계 | 시각 | 내용 | 결과 |
|---|---|---|---|
| 1 | 12:36 | 기준선 저장(조회) | vplus 객체 394, 제약조건 213, 소스 221, `TQS*` 테이블 83 |
| 2 | 12:42 | 매핑표·SQL·되돌리기 스크립트 생성(조회) | 자동 검사 모두 OK |
| 3 | 12:46~12:47 | 테이블·데이터·FK·코멘트 | 오류 없음, 검증 OK |
| 4 | 12:51 | TYPE 2개 | VALID |
| 5 | 12:55 | 함수 12, 프로시저 275 | 286개 VALID, 1개 INVALID |
| 5 보완 | 13:01 | `PQSB_SEND_SMS_Q` 다시 만듦(B안) | VALID |
| 6 | 13:02 | 최종 검증(조회) | 19개 항목 모두 OK |

## 4. 소스를 고친 객체 (1건)

| 항목 | 내용 |
|---|---|
| 객체 | `PQSB_SEND_SMS_Q` (JH `PQSA_SEND_SMS_Q`) |
| 원인 | vplus 공통 테이블 `THRA_BASEINFO`에 `WORK_CORP_CD` 컬럼이 없다(JH에는 있다). 그래서 `ORA-00904`가 났다 |
| 수정 | `LEFT OUTER JOIN THRZ_DEPT C ON C.CORP_CD = A.WORK_CORP_CD` → `... = A.CORP_CD` (사용자 승인 B안) |
| 영향 | 근무부서 이름을 찾는 조인이 소속 회사 기준으로 바뀐다. JH 인사 899명 중 근무 회사코드와 소속 회사코드가 다른 93명은, 근무부서 이름 대신 부서코드가 나올 수 있다(`NVL(C.DEPT_NM, DEPT_WORK_CD)`). 조회 결과에서 사람이 빠지지는 않는다 |
| 하지 않은 것 | vplus `THRA_BASEINFO`에 컬럼을 추가하지 않았다(기존 객체 변경 금지 원칙) |

## 5. 검증 결과 (6단계)

| 검사 | 결과 |
|---|---|
| 새 객체 수(테이블 108, TYPE 2, 함수 12, 프로시저 275) | 매핑표와 같음 |
| 새 객체 상태 / 컴파일 오류 | 모두 VALID / 0건 |
| PK 95, FK 31, PK 인덱스 95 | 이름이 매핑표와 같음. 모두 ENABLED·VALIDATED, 인덱스 VALID |
| vplus 소스와 생성 SQL | 289개 모두 같음(공백 무시) |
| 데이터 14개 / 구조만 94개 | 건수와 행 내용이 JH와 같음(3단계에서 PK 기준 전체 비교) / 모두 0건 |
| 컬럼 정의(타입·길이·NULL·DEFAULT) | 108개 모두 JH와 같음(3단계) |
| **기존 vplus 객체(기준선 비교)** | 바뀜 0, 사라짐 0, 이관과 관계없는 추가 0 |
| 기준선 범위의 INVALID | 이관 전과 같은 2개(`FQSZ_SITE_JOB`, `PQSA_IDAC_MINUS_Q`). 새로 생긴 INVALID 없음 |

프로시저는 실행하지 않았다. 데이터를 바꾸는 프로시저가 있어서 컴파일 성공까지만 확인했다.

## 6. 되돌리기

- `scripts/migration/02_generate/99_rollback.sql`을 vplus에서 실행하면 이번에 만든 객체만 지워진다.
- 지우는 순서: 프로시저 → 함수 → TYPE(`QSSITETAB01` → `QSSITEOBJ01`) → 테이블(`CASCADE CONSTRAINTS PURGE`).
- 테이블을 지우면 PK, FK, 인덱스, 코멘트, 복사한 데이터도 함께 지워진다.
- vplus의 기존 객체는 이 스크립트에 들어 있지 않다.

## 7. 남은 사항

| # | 내용 | 비고 |
|---|---|---|
| 1 | `02_generate/gen_step2.py`로 SQL을 다시 만들면 4장의 소스 수정이 사라진다 | 다시 만들면 `70_procedures.sql`의 같은 줄을 다시 고쳐야 한다 |
| 2 | vplus 앱(화면·매퍼)이 새 객체(`PQSB_*` 등)를 호출하도록 바꾸는 일은 이번 범위가 아니다 | 로드맵 7장 |
| 3 | `QSSITEOBJ01.SIT_CD`는 `VARCHAR2(6)`이다 | vplus에 7자 이상인 현장코드가 생기면 `FQSB_GETCMSITE01_BY_SITECD`에서 오류가 날 수 있다 |
| 4 | 기준선 범위 밖의 vplus 객체는 비교하지 않았다 | 이관 작업은 모두 새 객체 `CREATE`와 새 테이블 `INSERT`였다 |

## 8. 산출물

스크립트는 DB 비밀번호를 환경변수 `DB_PASSWORD`에서 읽는다(접속 정보는 `docs/db_info.md`, 저장소에는 올리지 않음).
예: PowerShell `$env:DB_PASSWORD='...'; python -I scripts/migration/06_verify/run_step6.py`

| 폴더 | 내용 |
|---|---|
| `scripts/migration/01_baseline/` | 이관 전 기준선, `baseline.py` |
| `scripts/migration/02_generate/` | `mapping.csv`, 생성 SQL(10~70), 치환 리포트(80), 되돌리기(99), `gen_step2.py` |
| `scripts/migration/03_tables/` | `run_step3.py`, `step3.log`, `step3_result.json` |
| `scripts/migration/04_types/` | `run_step4.py`, `step4.log`, `step4_result.json` |
| `scripts/migration/05_code/` | `run_step5.py`, `fix_send_sms.py`, `step5.log`, `step5_result.json` |
| `scripts/migration/06_verify/` | `run_step6.py`, `step6_result.md`, `step6_result.json`, `after_baseline/` |
