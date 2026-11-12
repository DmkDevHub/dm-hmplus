# TQSA / TQSB 테이블 복제 사전 분석 및 실행 계획서

> 계획 근거: [db_plan.md](db_plan.md)
> 작업 범위: 사전 분석 및 문서 작성만 수행. CREATE/ALTER/DROP/INSERT/UPDATE/DELETE 등 DB 변경은 수행하지 않았다. 조회(SELECT 및 메타데이터 조회)만 사용했다.
> 상태: **사용자 검토 및 승인 대기** (승인 전까지 복제 SQL 실행 금지)

## 1. 작업 개요

- 원본: **DB JH** (스키마 `JH202610`)
- 대상: **DB vplus** (스키마 `JH202603`)
- 복제 대상: 테이블명에 `TQSA` 또는 `TQSB`가 포함된 테이블 **108개** (TQSA 포함 94개, TQSB 포함 14개)
- 이름 규칙: 테이블명의 `TQSA`는 `TQSB`로 변경, 기존 `TQSB` 이름은 유지, 컬럼명은 원본 유지
- 복제 범위: 테이블/컬럼 구조, 데이터 타입·길이·정밀도·NULL·DEFAULT, PK, FK, UK, CHECK, INDEX, 테이블/컬럼 COMMENT
- 데이터 복사: 하지 않음

> **확인 필요 (방향 표기)**: 계획서 1항은 원본=JH, 대상=vplus로 적고, 3.2항은 "DB B에서 조회", 3.3항은 "DB A로 복제"라고 적고 있어 A/B 표기가 같은 방향을 가리키는지 명확하지 않다. 본 문서는 1항의 명시(원본 JH → 대상 vplus)를 따랐다.

## 2. DB 환경 분석 결과

| 항목 | 원본 (JH) | 대상 (vplus) | 판정 |
|---|---|---|---|
| 접속 스키마 | JH202610 | JH202603 | 접속 성공 |
| Oracle 버전 | 19.3.0.0.0 | 19.3.0.0.0 | 동일 (19c) |
| DB 이름 | orclu | orclu | 같은 인스턴스(ORCLU) 내 다른 스키마 |
| 기본 테이블스페이스 | TS_ORCLU_JH202610 | TS_ORCLU_JH202603 | 원본 테이블은 모두 TS_ORCLU_JH202610 사용. DDL의 TABLESPACE 절을 대상 테이블스페이스로 바꿔야 함 |
| 대상 테이블스페이스 쿼터 | - | 무제한 (MAX_BYTES = -1) | 충분 |
| 시스템 권한 | - | CREATE TABLE, CREATE SEQUENCE, CREATE TRIGGER, CREATE VIEW, CREATE PROCEDURE, CREATE SYNONYM, CREATE TYPE, CREATE MATERIALIZED VIEW, CREATE SESSION | 스키마 내 테이블/인덱스/제약조건 생성 가능 |
| 역할 | - | CONNECT, RESOURCE | 확인 |
| 메타데이터 조회 | USER_* 뷰 조회 가능 | USER_* 뷰 조회 가능 | DBA_* 뷰는 두 계정 모두 조회 불가 (이전 분석에서 확인) |
| DBMS_METADATA.GET_DDL | 호출 성공 (조회 테스트 1건) | - | 사용 가능. 전체 객체 추출은 실행 전 재검증 필요 |
| 객체 생성 권한 (권한 변경 없음) | - | 생성에 필요한 권한 있음 | 확인됨. 권한 변경 불필요 |

> 참고: 두 스키마는 같은 DB 인스턴스(ORCLU) 안에 있으므로, 이 작업은 인스턴스 간 복제가 아니라 **스키마 간 복제**다.

## 3. 복제 대상 테이블 전체 목록

총 108개. 컬럼 수 합계 2153개. 파티션 테이블, 임시 테이블, 트리거 없음.

| No | 원본 테이블명 | 대상 테이블명 | 컬럼 수 | PK | FK 출력 / 입력 | COMMENT | 충돌 |
|---|---|---|---|---|---|---|---|
| 1 | TQSA_ADDRISK_ORD | TQSB_ADDRISK_ORD | 38 | 있음 (3컬럼) | 0 / 0 | 없음 | 없음 |
| 2 | TQSA_APRV | TQSB_APRV | 16 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 3 | TQSA_APRVLINE | TQSB_APRVLINE | 10 | 있음 (3컬럼) | 0 / 0 | 없음 | 없음 |
| 4 | TQSA_APRVLINE_DTL | TQSB_APRVLINE_DTL | 11 | 있음 (4컬럼) | 0 / 0 | 없음 | 없음 |
| 5 | TQSA_APRV_LINE | TQSB_APRV_LINE | 14 | 있음 (3컬럼) | 0 / 0 | 없음 | 없음 |
| 6 | TQSA_AREC_CD | TQSB_AREC_CD | 12 | 있음 (1컬럼) | 0 / 0 | 없음 | 없음 |
| 7 | TQSA_ARND_CHK_DRY | TQSB_ARND_CHK_DRY | 14 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 8 | TQSA_ASSLOG_CIRC | TQSB_ASSLOG_CIRC | 12 | 없음 | 0 / 0 | 없음 | 없음 |
| 9 | TQSA_BON_ORG | TQSB_BON_ORG | 14 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 10 | TQSA_CKLST | TQSB_CKLST | 12 | 있음 (3컬럼) | 0 / 0 | 없음 | 없음 |
| 11 | TQSA_CKLST_ITM | TQSB_CKLST_ITM | 15 | 있음 (4컬럼) | 0 / 0 | 없음 | 없음 |
| 12 | TQSA_CTP | TQSB_CTP | 10 | 있음 (1컬럼) | 0 / 2 | 없음 | 없음 |
| 13 | TQSA_CTPUNT | TQSB_CTPUNT | 10 | 있음 (2컬럼) | 1 / 2 | 없음 | 없음 |
| 14 | TQSA_CTPUNT_CHKITM | TQSB_CTPUNT_CHKITM | 21 | 있음 (3컬럼) | 1 / 1 | 없음 | **원본 내 이름 충돌** |
| 15 | TQSA_CTP_PSN | TQSB_CTP_PSN | 9 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 16 | TQSA_DAYSAFE_CHKLST | TQSB_DAYSAFE_CHKLST | 29 | 있음 (7컬럼) | 1 / 0 | 없음 | **원본 내 이름 충돌** |
| 17 | TQSA_DAYSAFE_DT | TQSB_DAYSAFE_DT | 19 | 있음 (2컬럼) | 0 / 1 | 없음 | **원본 내 이름 충돌** |
| 18 | TQSA_DEEDU_CD | TQSB_DEEDU_CD | 13 | 있음 (2컬럼) | 1 / 0 | 없음 | 없음 |
| 19 | TQSA_DISASTER_CD | TQSB_DISASTER_CD | 10 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 20 | TQSA_DISASTER_DIV | TQSB_DISASTER_DIV | 9 | 있음 (1컬럼) | 0 / 0 | 없음 | 없음 |
| 21 | TQSA_DRM | TQSB_DRM | 19 | 없음 | 0 / 0 | 없음 | 없음 |
| 22 | TQSA_DRM_ANNC | TQSB_DRM_ANNC | 9 | 없음 | 0 / 0 | 없음 | 없음 |
| 23 | TQSA_EDU | TQSB_EDU | 36 | 있음 (2컬럼) | 0 / 1 | 없음 | 없음 |
| 24 | TQSA_EDU_CD | TQSB_EDU_CD | 9 | 있음 (1컬럼) | 0 / 1 | 없음 | 없음 |
| 25 | TQSA_EDU_CD_TEMP | TQSB_EDU_CD_TEMP | 6 | 없음 | 0 / 0 | 없음 | 없음 |
| 26 | TQSA_EDU_DRY | TQSB_EDU_DRY | 13 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 27 | TQSA_EDU_MSDS | TQSB_EDU_MSDS | 18 | 있음 (3컬럼) | 1 / 0 | 없음 | 없음 |
| 28 | TQSA_EMG_TRN | TQSB_EMG_TRN | 14 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 29 | TQSA_EQMTABK | TQSB_EQMTABK | 30 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 30 | TQSA_HLTH_CHKUP | TQSB_HLTH_CHKUP | 24 | 있음 (2컬럼) | 0 / 1 | 없음 | 없음 |
| 31 | TQSA_HLTH_CHKUP_LIST | TQSB_HLTH_CHKUP_LIST | 30 | 있음 (3컬럼) | 1 / 0 | 없음 | 없음 |
| 32 | TQSA_HOCHKRPT | TQSB_HOCHKRPT | 62 | 있음 (3컬럼) | 0 / 3 | 없음 | 없음 |
| 33 | TQSA_HOCHKRPT_CK | TQSB_HOCHKRPT_CK | 18 | 있음 (7컬럼) | 1 / 0 | 없음 | 없음 |
| 34 | TQSA_HOCHKRPT_ERR | TQSB_HOCHKRPT_ERR | 31 | 없음 | 1 / 0 | 없음 | 없음 |
| 35 | TQSA_HOCHKRPT_PHOTO | TQSB_HOCHKRPT_PHOTO | 12 | 없음 | 1 / 0 | 없음 | 없음 |
| 36 | TQSA_HODCAB | TQSB_HODCAB | 16 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 37 | TQSA_IDAC | TQSB_IDAC | 97 | 있음 (2컬럼) | 0 / 1 | 없음 | 없음 |
| 38 | TQSA_IDAC_APRV | TQSB_IDAC_APRV | 10 | 있음 (3컬럼) | 0 / 0 | 없음 | 없음 |
| 39 | TQSA_IDAC_DSVC | TQSB_IDAC_DSVC | 28 | 있음 (3컬럼) | 1 / 0 | 없음 | 없음 |
| 40 | TQSA_LABOR_JOINT_INSP | TQSB_LABOR_JOINT_INSP | 13 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 41 | TQSA_LABOR_LIST | TQSB_LABOR_LIST | 32 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 42 | TQSA_LABOR_MNG_CNCL | TQSB_LABOR_MNG_CNCL | 13 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 43 | TQSA_LAB_AREC | TQSB_LAB_AREC | 23 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 44 | TQSA_LBR_CHK | TQSB_LBR_CHK | 22 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 45 | TQSA_LBR_CHK_ITM | TQSB_LBR_CHK_ITM | 16 | 있음 (3컬럼) | 0 / 0 | 없음 | 없음 |
| 46 | TQSA_MMEDUPLAN | TQSB_MMEDUPLAN | 13 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 47 | TQSA_MOB_LOG | TQSB_MOB_LOG | 10 | 있음 (1컬럼) | 0 / 0 | 없음 | 없음 |
| 48 | TQSA_MSDSMNG | TQSB_MSDSMNG | 20 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 49 | TQSA_MSDS_CD | TQSB_MSDS_CD | 18 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 50 | TQSA_NCR_REP | TQSB_NCR_REP | 41 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 51 | TQSA_PRES_SITE | TQSB_PRES_SITE | 10 | 있음 (1컬럼) | 0 / 0 | 없음 | 없음 |
| 52 | TQSA_RISKPLAN | TQSB_RISKPLAN | 13 | 없음 | 0 / 0 | 없음 | **원본 내 이름 충돌** |
| 53 | TQSA_RISKPLAN_D | TQSB_RISKPLAN_D | 23 | 없음 | 0 / 0 | 없음 | **원본 내 이름 충돌** |
| 54 | TQSA_RISKSITE_CIPIF | TQSB_RISKSITE_CIPIF | 18 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 55 | TQSA_RISK_AREC_TEMP | TQSB_RISK_AREC_TEMP | 33 | 있음 (8컬럼) | 1 / 0 | 없음 | 없음 |
| 56 | TQSA_RISK_CHK | TQSB_RISK_CHK | 59 | 있음 (8컬럼) | 2 / 0 | 없음 | **원본 내 이름 충돌** |
| 57 | TQSA_RISK_DGR | TQSB_RISK_DGR | 23 | 있음 (3컬럼) | 0 / 1 | 없음 | **원본 내 이름 충돌** |
| 58 | TQSA_RISK_VNDR | TQSB_RISK_VNDR | 27 | 있음 (5컬럼) | 2 / 2 | 없음 | **원본 내 이름 충돌** |
| 59 | TQSA_SAFECOST_APRV | TQSB_SAFECOST_APRV | 11 | 있음 (3컬럼) | 0 / 0 | 없음 | 없음 |
| 60 | TQSA_SAFECOST_ARSLT | TQSB_SAFECOST_ARSLT | 42 | 있음 (5컬럼) | 0 / 0 | 없음 | 없음 |
| 61 | TQSA_SAFECOST_ARSLT_CO | TQSB_SAFECOST_ARSLT_CO | 44 | 있음 (7컬럼) | 0 / 0 | 없음 | 없음 |
| 62 | TQSA_SAFECOST_BGT | TQSB_SAFECOST_BGT | 10 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 63 | TQSA_SAFECOST_BGTYM | TQSB_SAFECOST_BGTYM | 11 | 있음 (3컬럼) | 0 / 0 | 없음 | 없음 |
| 64 | TQSA_SAFECOST_INFO | TQSB_SAFECOST_INFO | 15 | 있음 (1컬럼) | 0 / 0 | 없음 | 없음 |
| 65 | TQSA_SAFECOST_MMARSLT_CO | TQSB_SAFECOST_MMARSLT_CO | 16 | 있음 (4컬럼) | 0 / 0 | 없음 | 없음 |
| 66 | TQSA_SAFE_PERM_CD | TQSB_SAFE_PERM_CD | 9 | 있음 (1컬럼) | 0 / 2 | 없음 | 없음 |
| 67 | TQSA_SAFE_PERM_CPLN | TQSB_SAFE_PERM_CPLN | 10 | 있음 (2컬럼) | 1 / 0 | 없음 | 없음 |
| 68 | TQSA_SAFE_PERREQ | TQSB_SAFE_PERREQ | 41 | 있음 (2컬럼) | 0 / 1 | 없음 | 없음 |
| 69 | TQSA_SAFE_PERREQ_OBJ | TQSB_SAFE_PERREQ_OBJ | 12 | 있음 (3컬럼) | 2 / 1 | 없음 | 없음 |
| 70 | TQSA_SAFE_PERREQ_OBJLST | TQSB_SAFE_PERREQ_OBJLST | 11 | 있음 (4컬럼) | 1 / 0 | 없음 | 없음 |
| 71 | TQSA_SAFT_PGM | TQSB_SAFT_PGM | 17 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 72 | TQSA_SAFT_RGLN | TQSB_SAFT_RGLN | 14 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 73 | TQSA_SAFT_SIT | TQSB_SAFT_SIT | 12 | 있음 (1컬럼) | 0 / 0 | 없음 | 없음 |
| 74 | TQSA_SELECT | TQSB_SELECT | 13 | 있음 (4컬럼) | 0 / 0 | 없음 | 없음 |
| 75 | TQSA_SEL_LST | TQSB_SEL_LST | 13 | 없음 | 0 / 0 | 없음 | 없음 |
| 76 | TQSA_SITEDOC | TQSB_SITEDOC | 18 | 있음 (3컬럼) | 0 / 0 | 없음 | 없음 |
| 77 | TQSA_SITENAM | TQSB_SITENAM | 21 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 78 | TQSA_SUBJECT | TQSB_SUBJECT | 17 | 있음 (1컬럼) | 0 / 0 | 없음 | 없음 |
| 79 | TQSA_VIEW_HIS | TQSB_VIEW_HIS | 9 | 없음 | 0 / 0 | 없음 | 없음 |
| 80 | TQSA_VIEW_REQ | TQSB_VIEW_REQ | 13 | 없음 | 0 / 0 | 없음 | 없음 |
| 81 | TQSA_VIEW_REQ_LST | TQSB_VIEW_REQ_LST | 8 | 없음 | 0 / 0 | 없음 | 없음 |
| 82 | TQSA_VNDR | TQSB_VNDR | 47 | 있음 (3컬럼) | 1 / 2 | 없음 | 없음 |
| 83 | TQSA_WEEK_WORK_LOG | TQSB_WEEK_WORK_LOG | 50 | 있음 (2컬럼) | 0 / 1 | 없음 | 없음 |
| 84 | TQSA_WEEK_WORK_LOG_HO | TQSB_WEEK_WORK_LOG_HO | 12 | 있음 (1컬럼) | 0 / 1 | 없음 | 없음 |
| 85 | TQSA_WEEK_WORK_LOG_PLAN | TQSB_WEEK_WORK_LOG_PLAN | 17 | 있음 (3컬럼) | 1 / 0 | 없음 | 없음 |
| 86 | TQSA_WEEK_WORK_LOG_PLAN_HO | TQSB_WEEK_WORK_LOG_PLAN_HO | 15 | 있음 (2컬럼) | 1 / 0 | 없음 | 없음 |
| 87 | TQSA_WORK_ENV_MON | TQSB_WORK_ENV_MON | 14 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 88 | TQSA_WRK_PDOC | TQSB_WRK_PDOC | 17 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 89 | TQSA_WRK_PMPP | TQSB_WRK_PMPP | 15 | 있음 (2컬럼) | 0 / 0 | 없음 | 없음 |
| 90 | TQSA_YYTRGARSLT | TQSB_YYTRGARSLT | 17 | 있음 (5컬럼) | 0 / 0 | 없음 | 없음 |
| 91 | TQSA_YYTRGARSLTSEQ | TQSB_YYTRGARSLTSEQ | 15 | 있음 (4컬럼) | 0 / 0 | 없음 | 없음 |
| 92 | TQSA_YYTRGPLN | TQSB_YYTRGPLN | 16 | 있음 (4컬럼) | 0 / 1 | 없음 | 없음 |
| 93 | TQSA_YYTRGPLNCHR | TQSB_YYTRGPLNCHR | 15 | 있음 (5컬럼) | 1 / 0 | 없음 | 없음 |
| 94 | TQSA_YYTRGPLNSEQ | TQSB_YYTRGPLNSEQ | 14 | 있음 (3컬럼) | 0 / 0 | 없음 | 없음 |
| 95 | TQSB_CTPUNT_CHKITM | TQSB_CTPUNT_CHKITM | 20 | 있음 (3컬럼) | 1 / 0 | 없음 | **원본 내 이름 충돌** |
| 96 | TQSB_CTPUNT_CHKITM_TMP | TQSB_CTPUNT_CHKITM_TMP | 5 | 없음 | 0 / 0 | 없음 | 없음 |
| 97 | TQSB_DAYSAFE_CHKLST | TQSB_DAYSAFE_CHKLST | 31 | 있음 (10컬럼) | 0 / 0 | 없음 | **원본 내 이름 충돌** |
| 98 | TQSB_DAYSAFE_DT | TQSB_DAYSAFE_DT | 19 | 있음 (5컬럼) | 0 / 1 | 없음 | **원본 내 이름 충돌** |
| 99 | TQSB_DAYSAFE_NAM | TQSB_DAYSAFE_NAM | 13 | 있음 (6컬럼) | 1 / 0 | 없음 | 없음 |
| 100 | TQSB_RISKPLAN | TQSB_RISKPLAN | 13 | 있음 (3컬럼) | 0 / 1 | 없음 | **원본 내 이름 충돌** |
| 101 | TQSB_RISKPLAN_D | TQSB_RISKPLAN_D | 23 | 있음 (6컬럼) | 1 / 0 | 없음 | **원본 내 이름 충돌** |
| 102 | TQSB_RISK_CHK | TQSB_RISK_CHK | 29 | 있음 (9컬럼) | 1 / 0 | 없음 | **원본 내 이름 충돌** |
| 103 | TQSB_RISK_DGR | TQSB_RISK_DGR | 31 | 있음 (3컬럼) | 0 / 1 | 없음 | **원본 내 이름 충돌** |
| 104 | TQSB_RISK_LST | TQSB_RISK_LST | 27 | 있음 (8컬럼) | 1 / 1 | 없음 | 없음 |
| 105 | TQSB_RISK_NAM | TQSB_RISK_NAM | 16 | 있음 (6컬럼) | 1 / 0 | 없음 | 없음 |
| 106 | TQSB_RISK_VNDR | TQSB_RISK_VNDR | 19 | 있음 (5컬럼) | 1 / 2 | 없음 | **원본 내 이름 충돌** |
| 107 | TQSB_STOP_WK | TQSB_STOP_WK | 25 | 있음 (4컬럼) | 0 / 0 | 없음 | 없음 |
| 108 | TQSB_VNDRNAM | TQSB_VNDRNAM | 24 | 있음 (4컬럼) | 1 / 0 | 없음 | 없음 |

> COMMENT: 원본 JH의 TQSA/TQSB 테이블과 컬럼에는 COMMENT가 하나도 없다 (테이블 0건, 컬럼 0건). 복제 대상에 COMMENT 적용 작업은 없다.

## 4. 원본 → 대상 테이블명 매핑

### 4.1 매핑 규칙 결과
- TQSA 포함 테이블 94개 → `TQSA`를 `TQSB`로 치환
- TQSB 포함 테이블 14개 → 이름 유지
- **이름 충돌 8쌍**: 원본의 TQSA 테이블을 치환하면 원본에 이미 있는 TQSB 테이블과 이름이 같아진다. 현재 규칙만으로는 대상 이름이 정해지지 않으므로 사용자 결정이 필요하다 (6.1 참고).
- 치환 후 이름 중 대상(vplus)에 이미 있는 이름: 0개 (없음이면 충돌 없음)

| 치환 후 이름 | 원본 TQSA 테이블 | 원본 TQSB 테이블 (기존 이름) |
|---|---|---|
| TQSB_CTPUNT_CHKITM | TQSA_CTPUNT_CHKITM | TQSB_CTPUNT_CHKITM |
| TQSB_DAYSAFE_CHKLST | TQSA_DAYSAFE_CHKLST | TQSB_DAYSAFE_CHKLST |
| TQSB_DAYSAFE_DT | TQSA_DAYSAFE_DT | TQSB_DAYSAFE_DT |
| TQSB_RISKPLAN | TQSA_RISKPLAN | TQSB_RISKPLAN |
| TQSB_RISKPLAN_D | TQSA_RISKPLAN_D | TQSB_RISKPLAN_D |
| TQSB_RISK_CHK | TQSA_RISK_CHK | TQSB_RISK_CHK |
| TQSB_RISK_DGR | TQSA_RISK_DGR | TQSB_RISK_DGR |
| TQSB_RISK_VNDR | TQSA_RISK_VNDR | TQSB_RISK_VNDR |

### 4.2 제약조건 및 인덱스 이름 변환
- 사용자 지정 이름 제약조건 126개 중 TQSA 포함 105개 → TQSB로 변환, TQSB 포함 21개는 그대로
- 시스템 생성 이름 제약조건 226개 (`SYS_C...`): TQSA/TQSB를 포함하지 않으므로 변환하지 않는다. 새로 생성하면 Oracle이 새 이름을 부여한다.
- 인덱스 98개 중 TQSA 포함 82개 (PK 인덱스 95개 + LOB 인덱스 3개 시스템 생성)
- 치환 후 이름이 중복되는 제약조건/인덱스 이름 8개 (4.1의 테이블 충돌과 같은 원인):

  - FK_TQSB_CTPUNT_TO_TQSB_CTPUNT_CHKITM
  - FK_TQSB_RISK_DGR_TO_TQSB_RISK_VNDR
  - PK_TQSB_CTPUNT_CHKITM
  - PK_TQSB_DAYSAFE_CHKLST
  - PK_TQSB_DAYSAFE_DT
  - PK_TQSB_RISK_CHK
  - PK_TQSB_RISK_DGR
  - PK_TQSB_RISK_VNDR

## 5. 테이블별 구조 및 관련 객체 분석

### 5.1 전체 요약
- 컬럼 데이터 타입: VARCHAR2 1690개, NUMBER 242개, DATE 218개, CLOB 3개
- PK: 95개 테이블. PK가 없는 테이블 13개 (이 중 TQSA_RISKPLAN, TQSA_RISKPLAN_D는 이름 충돌 대상)
- UNIQUE 제약조건: 0개
- CHECK 제약조건(NOT NULL 제외): 0개. NOT NULL 제약조건 226개는 NULL 허용 속성에 반영된다.
- FK: 31개. 모두 복제 대상 내부 참조이며 외부 테이블 참조는 없다. 삭제 규칙은 모두 NO ACTION.
- 일반 인덱스(PK·LOB 외): 0개
- LOB: CLOB 컬럼 3개 (TQSA_DRM.DATA_DESC, TQSA_LAB_AREC.DECD_MATT, TQSA_SUBJECT.DTL_CTS). LOB 저장 옵션은 DBMS_METADATA 추출 결과 확인 필요.
- DEFAULT: 숫자 기본값 `0` 또는 `'0'`만 존재. `SYSDATE`, `SYS_GUID`, `NEXTVAL` 기본값은 없음 (확인함).
- 트리거: 복제 대상 테이블에 없음
- 외부 의존성: 원본 DB에서 복제 대상 테이블을 참조하는 PROCEDURE 274개 (의존 행 730건). 복제 범위에 포함하지 않는다 (6.2 참고).
- 외부 테이블이 복제 대상 테이블을 FK로 참조하는 경우: 없음

### 5.2 테이블별 상세

| 원본 테이블 | 컬럼 수 | PK 컬럼 | LOB | 대상 테이블 | 충돌 |
|---|---|---|---|---|---|
| TQSA_ADDRISK_ORD | 38 | SIT_CD, WRT_DT, WRT_SEQ | - | TQSB_ADDRISK_ORD | - |
| TQSA_APRV | 16 | SIT_CD, APRV_NO | - | TQSB_APRV | - |
| TQSA_APRVLINE | 10 | SIT_CD, APRV_WRTR, APRVLINE_SEQ | - | TQSB_APRVLINE | - |
| TQSA_APRVLINE_DTL | 11 | SIT_CD, APRV_WRTR, APRVLINE_SEQ, APRV_SO | - | TQSB_APRVLINE_DTL | - |
| TQSA_APRV_LINE | 14 | SIT_CD, APRV_NO, APRV_SO | - | TQSB_APRV_LINE | - |
| TQSA_AREC_CD | 12 | AREC_CD | - | TQSB_AREC_CD | - |
| TQSA_ARND_CHK_DRY | 14 | SIT_CD, CHK_SEQ | - | TQSB_ARND_CHK_DRY | - |
| TQSA_ASSLOG_CIRC | 12 | 없음 | - | TQSB_ASSLOG_CIRC | - |
| TQSA_BON_ORG | 14 | SIT_CD, RLV_YM | - | TQSB_BON_ORG | - |
| TQSA_CKLST | 12 | COM_CD, HO_CHK_DIV_CD2, HO_CHK_DIV_CD | - | TQSB_CKLST | - |
| TQSA_CKLST_ITM | 15 | COM_CD, HO_CHK_DIV_CD2, HO_CHK_DIV_CD, HO_CHK_ITM_CD | - | TQSB_CKLST_ITM | - |
| TQSA_CTP | 10 | CTP_CD | - | TQSB_CTP | - |
| TQSA_CTPUNT | 10 | CTP_CD, UNT_CD | - | TQSB_CTPUNT | - |
| TQSA_CTPUNT_CHKITM | 21 | CTP_CD, UNT_CD, CHK_ITM_CD | - | TQSB_CTPUNT_CHKITM | 충돌 |
| TQSA_CTP_PSN | 9 | SIT_CD, CTP_DIV | - | TQSB_CTP_PSN | - |
| TQSA_DAYSAFE_CHKLST | 29 | SIT_CD, PLN_YM, PLN_DGR, ODAY_CHK_DT, CTP_CD, UNT_CD, CHK_ITM_CD | - | TQSB_DAYSAFE_CHKLST | 충돌 |
| TQSA_DAYSAFE_DT | 19 | SIT_CD, ODAY_CHK_DT | - | TQSB_DAYSAFE_DT | 충돌 |
| TQSA_DEEDU_CD | 13 | EDU_CD, DEEDU_CD | - | TQSB_DEEDU_CD | - |
| TQSA_DISASTER_CD | 10 | DIV_CD, DIS_CD | - | TQSB_DISASTER_CD | - |
| TQSA_DISASTER_DIV | 9 | DIV_CD | - | TQSB_DISASTER_DIV | - |
| TQSA_DRM | 19 | 없음 | O | TQSB_DRM | - |
| TQSA_DRM_ANNC | 9 | 없음 | - | TQSB_DRM_ANNC | - |
| TQSA_EDU | 36 | SIT_CD, EDU_SEQ | - | TQSB_EDU | - |
| TQSA_EDU_CD | 9 | EDU_CD | - | TQSB_EDU_CD | - |
| TQSA_EDU_CD_TEMP | 6 | 없음 | - | TQSB_EDU_CD_TEMP | - |
| TQSA_EDU_DRY | 13 | SIT_CD, EDU_SEQ | - | TQSB_EDU_DRY | - |
| TQSA_EDU_MSDS | 18 | SIT_CD, EDU_SEQ, MSDS_SEQ | - | TQSB_EDU_MSDS | - |
| TQSA_EMG_TRN | 14 | SIT_CD, TRN_SEQ | - | TQSB_EMG_TRN | - |
| TQSA_EQMTABK | 30 | SIT_CD, REG_NO | - | TQSB_EQMTABK | - |
| TQSA_HLTH_CHKUP | 24 | SIT_CD, CHKUP_YY | - | TQSB_HLTH_CHKUP | - |
| TQSA_HLTH_CHKUP_LIST | 30 | SIT_CD, CHKUP_YY, CHKUP_SEQ | - | TQSB_HLTH_CHKUP_LIST | - |
| TQSA_HOCHKRPT | 62 | SIT_CD, CHK_DIV, CHK_DGR | - | TQSB_HOCHKRPT | - |
| TQSA_HOCHKRPT_CK | 18 | SIT_CD, CHK_DIV, CHK_DGR, HO_CHK_DIV_CD, HO_CHK_DIV_CD2, HO_CHK_ITM_CD, COM_CD | - | TQSB_HOCHKRPT_CK | - |
| TQSA_HOCHKRPT_ERR | 31 | 없음 | - | TQSB_HOCHKRPT_ERR | - |
| TQSA_HOCHKRPT_PHOTO | 12 | 없음 | - | TQSB_HOCHKRPT_PHOTO | - |
| TQSA_HODCAB | 16 | WRT_DT, SEQ | - | TQSB_HODCAB | - |
| TQSA_IDAC | 97 | SIT_CD, ACCD_SEQ | - | TQSB_IDAC | - |
| TQSA_IDAC_APRV | 10 | SIT_CD, ACCD_SEQ, APRV_DIV | - | TQSB_IDAC_APRV | - |
| TQSA_IDAC_DSVC | 28 | SIT_CD, ACCD_SEQ, DSVC_SEQ | - | TQSB_IDAC_DSVC | - |
| TQSA_LABOR_JOINT_INSP | 13 | SIT_CD, LABOR_SEQ | - | TQSB_LABOR_JOINT_INSP | - |
| TQSA_LABOR_LIST | 32 | SIT_CD, LAB_SEQ | - | TQSB_LABOR_LIST | - |
| TQSA_LABOR_MNG_CNCL | 13 | SIT_CD, LABOR_SEQ | - | TQSB_LABOR_MNG_CNCL | - |
| TQSA_LAB_AREC | 23 | SIT_CD, CONF_SEQ | O | TQSB_LAB_AREC | - |
| TQSA_LBR_CHK | 22 | SIT_CD, CHK_SEQ | - | TQSB_LBR_CHK | - |
| TQSA_LBR_CHK_ITM | 16 | SIT_CD, CHK_SEQ, CHK_CD | - | TQSB_LBR_CHK_ITM | - |
| TQSA_MMEDUPLAN | 13 | SIT_CD, ACY_EDU_SEQ | - | TQSB_MMEDUPLAN | - |
| TQSA_MOB_LOG | 10 | LOG_ID | - | TQSB_MOB_LOG | - |
| TQSA_MSDSMNG | 20 | SIT_CD, MSDS_SEQ | - | TQSB_MSDSMNG | - |
| TQSA_MSDS_CD | 18 | SIT_CD, MSDS_SEQ | - | TQSB_MSDS_CD | - |
| TQSA_NCR_REP | 41 | SIT_CD, NCR_DOC_NO | - | TQSB_NCR_REP | - |
| TQSA_PRES_SITE | 10 | SIT_CD | - | TQSB_PRES_SITE | - |
| TQSA_RISKPLAN | 13 | 없음 | - | TQSB_RISKPLAN | 충돌 |
| TQSA_RISKPLAN_D | 23 | 없음 | - | TQSB_RISKPLAN_D | 충돌 |
| TQSA_RISKSITE_CIPIF | 18 | SIT_CD, RLV_YM | - | TQSB_RISKSITE_CIPIF | - |
| TQSA_RISK_AREC_TEMP | 33 | SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CTP_CD, UNT_CD, CHK_ITM_CD | - | TQSB_RISK_AREC_TEMP | - |
| TQSA_RISK_CHK | 59 | SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CTP_CD, UNT_CD, CHK_ITM_CD | - | TQSB_RISK_CHK | 충돌 |
| TQSA_RISK_DGR | 23 | SIT_CD, PLN_YM, PLN_DGR | - | TQSB_RISK_DGR | 충돌 |
| TQSA_RISK_VNDR | 27 | SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ | - | TQSB_RISK_VNDR | 충돌 |
| TQSA_SAFECOST_APRV | 11 | SIT_CD, APRV_DIV, APRV_YM | - | TQSB_SAFECOST_APRV | - |
| TQSA_SAFECOST_ARSLT | 42 | SIT_CD, ITM_DIV, RLV_YM, USE_DT, USE_SEQ | - | TQSB_SAFECOST_ARSLT | - |
| TQSA_SAFECOST_ARSLT_CO | 44 | SIT_CD, CUST_CD, VNDR_SEQ, RLV_YM, ITM_DIV, USE_DT, USE_SEQ | - | TQSB_SAFECOST_ARSLT_CO | - |
| TQSA_SAFECOST_BGT | 10 | SIT_CD, ITM_DIV | - | TQSB_SAFECOST_BGT | - |
| TQSA_SAFECOST_BGTYM | 11 | SIT_CD, ITM_DIV, RLV_YM | - | TQSB_SAFECOST_BGTYM | - |
| TQSA_SAFECOST_INFO | 15 | SIT_CD | - | TQSB_SAFECOST_INFO | - |
| TQSA_SAFECOST_MMARSLT_CO | 16 | SIT_CD, CUST_CD, VNDR_SEQ, RLV_YM | - | TQSB_SAFECOST_MMARSLT_CO | - |
| TQSA_SAFE_PERM_CD | 9 | PER_CD | - | TQSB_SAFE_PERM_CD | - |
| TQSA_SAFE_PERM_CPLN | 10 | PER_CD, CPLN_CD | - | TQSB_SAFE_PERM_CPLN | - |
| TQSA_SAFE_PERREQ | 41 | SIT_CD, REQ_SEQ | - | TQSB_SAFE_PERREQ | - |
| TQSA_SAFE_PERREQ_OBJ | 12 | SIT_CD, REQ_SEQ, PER_CD | - | TQSB_SAFE_PERREQ_OBJ | - |
| TQSA_SAFE_PERREQ_OBJLST | 11 | SIT_CD, REQ_SEQ, PER_CD, CPLN_CD | - | TQSB_SAFE_PERREQ_OBJLST | - |
| TQSA_SAFT_PGM | 17 | SIT_CD, PGM_SEQ | - | TQSB_SAFT_PGM | - |
| TQSA_SAFT_RGLN | 14 | SIT_CD, RGLN_SEQ | - | TQSB_SAFT_RGLN | - |
| TQSA_SAFT_SIT | 12 | SIT_CD | - | TQSB_SAFT_SIT | - |
| TQSA_SELECT | 13 | SIT_CD, ORD_NO, ORD_DGR, BD_DGR | - | TQSB_SELECT | - |
| TQSA_SEL_LST | 13 | 없음 | - | TQSB_SEL_LST | - |
| TQSA_SITEDOC | 18 | WRT_DT, SEQ, SIT_CD | - | TQSB_SITEDOC | - |
| TQSA_SITENAM | 21 | SIT_CD, EMPE_NO | - | TQSB_SITENAM | - |
| TQSA_SUBJECT | 17 | BLT_NO | O | TQSB_SUBJECT | - |
| TQSA_VIEW_HIS | 9 | 없음 | - | TQSB_VIEW_HIS | - |
| TQSA_VIEW_REQ | 13 | 없음 | - | TQSB_VIEW_REQ | - |
| TQSA_VIEW_REQ_LST | 8 | 없음 | - | TQSB_VIEW_REQ_LST | - |
| TQSA_VNDR | 47 | SIT_CD, CUST_CD, VNDR_SEQ | - | TQSB_VNDR | - |
| TQSA_WEEK_WORK_LOG | 50 | SIT_CD, RPTING_DT | - | TQSB_WEEK_WORK_LOG | - |
| TQSA_WEEK_WORK_LOG_HO | 12 | RPTING_DT | - | TQSB_WEEK_WORK_LOG_HO | - |
| TQSA_WEEK_WORK_LOG_PLAN | 17 | SIT_CD, RPTING_DT, PLN_SEQ | - | TQSB_WEEK_WORK_LOG_PLAN | - |
| TQSA_WEEK_WORK_LOG_PLAN_HO | 15 | RPTING_DT, PLN_SEQ | - | TQSB_WEEK_WORK_LOG_PLAN_HO | - |
| TQSA_WORK_ENV_MON | 14 | SIT_CD, MON_SEQ | - | TQSB_WORK_ENV_MON | - |
| TQSA_WRK_PDOC | 17 | SIT_CD, WRK_SEQ | - | TQSB_WRK_PDOC | - |
| TQSA_WRK_PMPP | 15 | SIT_CD, WRK_SEQ | - | TQSB_WRK_PMPP | - |
| TQSA_YYTRGARSLT | 17 | SIT_CD, TRG_YY, TRG_DGR, ARSLT_DGR, DRV_ARSLT_SEQ | - | TQSB_YYTRGARSLT | - |
| TQSA_YYTRGARSLTSEQ | 15 | SIT_CD, TRG_YY, TRG_DGR, ARSLT_DGR | - | TQSB_YYTRGARSLTSEQ | - |
| TQSA_YYTRGPLN | 16 | SIT_CD, TRG_YY, TRG_DGR, DRV_TRG_SEQ | - | TQSB_YYTRGPLN | - |
| TQSA_YYTRGPLNCHR | 15 | SIT_CD, TRG_YY, TRG_DGR, DRV_TRG_SEQ, EMPE_NO | - | TQSB_YYTRGPLNCHR | - |
| TQSA_YYTRGPLNSEQ | 14 | SIT_CD, TRG_YY, TRG_DGR | - | TQSB_YYTRGPLNSEQ | - |
| TQSB_CTPUNT_CHKITM | 20 | CTP_CD, UNT_CD, CHK_ITM_CD | - | TQSB_CTPUNT_CHKITM | 충돌 |
| TQSB_CTPUNT_CHKITM_TMP | 5 | 없음 | - | TQSB_CTPUNT_CHKITM_TMP | - |
| TQSB_DAYSAFE_CHKLST | 31 | SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CTP_CD, UNT_CD, CHK_ITM_CD, ODAY_CHK_DT, RISK_GRD | - | TQSB_DAYSAFE_CHKLST | 충돌 |
| TQSB_DAYSAFE_DT | 19 | SIT_CD, PLN_YM, PLN_DGR, ODAY_CHK_DT, RISK_GRD | - | TQSB_DAYSAFE_DT | 충돌 |
| TQSB_DAYSAFE_NAM | 13 | SIT_CD, PLN_YM, PLN_DGR, ODAY_CHK_DT, EMPE_NO_SEQ, RISK_GRD | - | TQSB_DAYSAFE_NAM | - |
| TQSB_RISKPLAN | 13 | SIT_CD, FST_DIV, PLN_DGR | - | TQSB_RISKPLAN | 충돌 |
| TQSB_RISKPLAN_D | 23 | SIT_CD, FST_DIV, PLN_DGR, CTP_CD, UNT_CD, CHK_ITM_CD | - | TQSB_RISKPLAN_D | 충돌 |
| TQSB_RISK_CHK | 29 | SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CTP_CD, UNT_CD, CHK_ITM_CD, EMPE_NO | - | TQSB_RISK_CHK | 충돌 |
| TQSB_RISK_DGR | 31 | SIT_CD, PLN_YM, PLN_DGR | - | TQSB_RISK_DGR | 충돌 |
| TQSB_RISK_LST | 27 | SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CTP_CD, UNT_CD, CHK_ITM_CD | - | TQSB_RISK_LST | - |
| TQSB_RISK_NAM | 16 | SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, EMPE_NO | - | TQSB_RISK_NAM | - |
| TQSB_RISK_VNDR | 19 | SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ | - | TQSB_RISK_VNDR | 충돌 |
| TQSB_STOP_WK | 25 | SIT_CD, STOP_DIV, STOP_DT, STOP_SEQ | - | TQSB_STOP_WK | - |
| TQSB_VNDRNAM | 24 | SIT_CD, CUST_CD, VNDR_SEQ, EMPE_NO | - | TQSB_VNDRNAM | - |

## 6. 기존 객체와의 충돌 분석

- 대상(vplus) 테이블 이름 충돌: **없음** (치환 후 이름 108개 기준)
- 대상(vplus) 제약조건/인덱스 이름 충돌: **없음** (치환 후 이름 기준으로 확인)
- 원본 내부 이름 충돌: **8쌍 (16개 원본 테이블)**
- 대상(vplus)에는 이미 TQSA 이름의 테이블 116개가 있다. 치환 규칙으로는 TQSA 이름이 생성되지 않으므로 이 테이블들과 충돌하지 않는다.
- 외부 참조 충돌: FK 참조 대상이 모두 복제 대상 내부에 있으므로 외부 테이블 존재 여부는 문제되지 않는다.

### 6.1 사용자 결정이 필요한 충돌

다음 8쌍은 TQSA 테이블을 TQSB로 치환하면 원본의 TQSB 테이블과 이름이 같아진다.

| 치환 후 이름 | 원본 TQSA 테이블 | 원본 TQSB 테이블 | 영향 |
|---|---|---|---|
| TQSB_CTPUNT_CHKITM | TQSA_CTPUNT_CHKITM | TQSB_CTPUNT_CHKITM | 테이블명, PK/FK 이름 중복 |
| TQSB_DAYSAFE_CHKLST | TQSA_DAYSAFE_CHKLST | TQSB_DAYSAFE_CHKLST | 테이블명, PK/FK 이름 중복 |
| TQSB_DAYSAFE_DT | TQSA_DAYSAFE_DT | TQSB_DAYSAFE_DT | 테이블명, PK/FK 이름 중복 |
| TQSB_RISKPLAN | TQSA_RISKPLAN | TQSB_RISKPLAN | 테이블명, PK/FK 이름 중복 |
| TQSB_RISKPLAN_D | TQSA_RISKPLAN_D | TQSB_RISKPLAN_D | 테이블명, PK/FK 이름 중복 |
| TQSB_RISK_CHK | TQSA_RISK_CHK | TQSB_RISK_CHK | 테이블명, PK/FK 이름 중복 |
| TQSB_RISK_DGR | TQSA_RISK_DGR | TQSB_RISK_DGR | 테이블명, PK/FK 이름 중복 |
| TQSB_RISK_VNDR | TQSA_RISK_VNDR | TQSB_RISK_VNDR | 테이블명, PK/FK 이름 중복 |

처리 방안 (검토용, 결정 전까지 실행하지 않음):
1. TQSA 쪽 테이블에 다른 치환 규칙 적용 (예: 접두어 또는 접미어 추가). 계획서의 "TQSA→TQSB" 규칙과 다르므로 사용자 확인 필요
2. 원본 TQSB 테이블만 복제하고 TQSA 쪽은 건너뜀. 데이터 누락 위험이 있음
3. 이 쌍을 보류하고 나머지 테이블만 먼저 복제 후 별도 결정

### 6.2 원본 프로시저 의존성

- 원본 JH에 복제 대상 테이블을 참조하는 PROCEDURE가 274개 있다.
- 복제 계획은 테이블 구조만 다룬다. 프로시저, 뷰, 패키지는 복제하지 않는다. 대상 DB에서 같은 로직이 필요하면 별도 작업이 필요하다.

## 7. 복제 방법 및 기술적 검토

| 항목 | 검토 결과 |
|---|---|
| DDL 추출 | `DBMS_METADATA.GET_DDL`로 원본 테이블 DDL을 추출한다. 호출 권한은 확인됐다(조회 테스트 1건). TABLESPACE, STORAGE, LOB 절은 대상 환경에 맞게 바꿔야 한다. |
| 이름 변환 | DDL 텍스트에서 `TQSA`를 `TQSB`로 치환한다. 대상은 테이블명, 제약조건명, 인덱스명, FK 참조명이다. 컬럼명은 치환하지 않는다. |
| 생성 순서 | (1) 테이블(컬럼만) → (2) PK → (3) UK(없음) → (4) CHECK(없음, NOT NULL은 컬럼 속성) → (5) 인덱스(PK 외 없음, LOB 인덱스는 LOB 세그먼트와 함께 생성) → (6) FK (모든 테이블과 PK 생성 뒤) → (7) COMMENT (원본에 없으므로 생략) |
| FK 순서 | FK 31개는 모두 복제 대상 내부 참조다. 참조 대상 PK가 먼저 있어야 하므로 FK는 마지막에 적용한다. |
| PK/UK/CHECK | PK 95개. UK 없음. 실제 CHECK 없음. |
| 인덱스 | PK 인덱스 95개, LOB 인덱스 3개(시스템 생성). 추가 인덱스 없음. PK 인덱스는 PK 생성 때 자동 생성된다. |
| COMMENT | 원본에 COMMENT가 없으므로 적용할 항목이 없다. |
| 데이터 복사 | 하지 않는다. 대상 테이블은 빈 상태로 생성한다. |
| 실행 도구 | 승인 후 별도 SQL 스크립트를 만든다. 이 단계에서는 스크립트를 만들거나 실행하지 않는다. |

## 8. 실제 SQL 실행 순서 (승인 후 실행, 현재 미실행)

> 아래는 승인 후 실행할 순서다. 현재 단계에서는 실행하지 않는다.

1. **사전 확인 (읽기 전용)**: 6절 충돌 결정 사항 반영 여부 확인, 대상 이름 중복 재조회
2. **결정 사항 확정**: 6.1의 충돌 쌍 처리 방안, TQSA→TQSB 이름 규칙 최종 확정 (사용자 승인)
3. **DDL 추출**: 원본(JH)에서 `DBMS_METADATA.GET_DDL`로 테이블, PK, FK, 인덱스 DDL을 파일로 추출 (읽기 전용)
4. **DDL 변환**: 테이블명·제약조건명·인덱스명·FK 참조명의 TQSA→TQSB 치환, TABLESPACE를 `TS_ORCLU_JH202603`으로 변경. 파일로 저장하고 실행하지 않는다.
5. **테이블 생성**: 컬럼 구조만 있는 CREATE TABLE 실행 (대상 vplus 스키마)
6. **PK 생성**: PRIMARY KEY 제약조건 추가 (PK 인덱스 자동 생성)
7. **LOB 저장 옵션 확인 후 생성**: CLOB 3개 테이블의 LOB 세그먼트 설정 확인
8. **FK 생성**: FK 전부, 모든 PK 생성 뒤 적용
9. **검증 (읽기 전용)**: 10절 기준으로 대상 객체 수, 컬럼 구조, 제약조건 수 확인

실패 시 처리 방안 (실행 전 확정 필요):
- 단계별로 실패하면 해당 단계에서 중단하고 사용자에게 보고한다.
- 복구는 이번 작업 중 생성한 객체만 제거하는 방식으로 한다. 기존 객체에는 손대지 않는다. 제거(DROP)는 사용자 승인 후에만 한다.
- 승인 없이 DROP, TRUNCATE를 실행하지 않는다.

## 9. 위험 요소 및 대응 방법

| 위험 | 내용 | 대응 |
|---|---|---|
| 원본 내부 이름 충돌 | 8쌍 (6.1) | 사용자 결정 전까지 실행 금지 |
| 테이블스페이스 불일치 | 원본은 TS_ORCLU_JH202610, 대상은 TS_ORCLU_JH202603 | DDL의 TABLESPACE 절을 대상 테이블스페이스로 변경 |
| 이름 길이 | 제약조건명 최대 54자, 인덱스명 최대 29자. Oracle 19c 허용 범위 안 | 변환 후 길이 재확인 |
| 시스템 생성 이름 | SYS_C 제약조건 226개, LOB 인덱스 시스템 이름 | 이름이 원본과 달라질 수 있음. 구조 비교 기준으로 검증 |
| LOB 저장 옵션 | CLOB 3개 | DBMS_METADATA 추출 결과의 LOB 절 확인 |
| 프로시저 의존성 | 원본 PROCEDURE 274개가 복제 대상을 참조 | 복제 범위 밖. 대상에 같은 로직이 필요하면 별도 작업 |
| 대상 기존 객체 | 대상에 TQSA 이름 테이블 116개가 있음 | 치환 후 이름이 TQSB이므로 충돌 없음. 대상의 기존 객체는 건드리지 않음 |
| 권한 | CREATE 권한 확인됨. DBA_* 조회 불가 | 권한 변경 없이 진행 |
| 실행 중 변경 | 승인 전 DB 변경 금지 | 승인 후 단계별로 실행 |

## 10. 실행 후 검증 계획

| 검증 항목 | 기준 | 확인 방법 |
|---|---|---|
| 테이블 수 | 대상 생성 테이블 수 = 108 (치환 후 이름 기준) | USER_TABLES 조회 |
| 컬럼 수 | 테이블별 컬럼 수 = 원본 (합계 2153) | USER_TAB_COLUMNS 비교 |
| 컬럼 속성 | 데이터 타입, 길이, 정밀도, 소수 자릿수, NULL, DEFAULT 일치 | 원본과 대상 비교 (이전 비교 방식 재사용) |
| PK | PK 95개, 컬럼 구성 일치 | USER_CONSTRAINTS, USER_CONS_COLUMNS |
| FK | FK 31개, 참조 대상이 TQSB 이름으로 일치 | USER_CONSTRAINTS, R_CONSTRAINT_NAME |
| 인덱스 | 인덱스 98개 (PK 인덱스 + LOB 인덱스) | USER_INDEXES |
| 제약조건 이름 | 사용자 지정 이름이 TQSB로 바뀌었는지 | 이름 목록 비교 |
| 데이터 | 복사하지 않았으므로 모든 테이블 0건 | 필요 시 COUNT(*)로 확인 (데이터 값 비교는 하지 않음) |
| 원본 불변 | 원본 JH 객체가 변경되지 않았는지 | 실행 전후 원본 객체 수 및 제약조건 수 비교 |
| 기존 대상 객체 불변 | 대상의 기존 TQSA/TQSB 테이블 구조가 바뀌지 않았는지 | 실행 전후 비교 |

## 11. 사용자 확인이 필요한 사항

1. **원본/대상 방향**: 계획서 1항(원본 JH → 대상 vplus)과 3항(DB B → DB A)의 표기가 다르다. 본 문서는 1항을 따랐다. 맞는지 확인이 필요하다.
2. **이름 충돌 8쌍 처리 방안**: 6.1의 방안 중 선택하거나 다른 규칙을 지정해야 한다.
3. **프로시저 274개 처리**: 복제 범위에서 제외했다. 대상에도 같은 프로시저가 필요한지 확인이 필요하다.
4. **CLOB LOB 저장 옵션**: 원본 설정을 그대로 쓸지, 대상 기본값을 쓸지 확인이 필요하다.
5. **COMMENT**: 원본에 COMMENT가 없으므로 복제 대상에서 제외했다. 맞는지 확인이 필요하다.
6. **DBMS_METADATA 추출 결과**: 조회 가능 여부만 확인했다. 실제 DDL 추출 결과는 승인 후 확인이 필요하다. 추정하지 않고 확인 필요로 남긴다.
7. **실행 시점**: 이 문서 승인 후 별도 실행 지시가 있을 때까지 DB 변경을 하지 않는다.

### 확인 필요 항목 (실제 조회하지 않아 추정하지 않음)
- 대상 vplus에서 DBMS_METADATA 추출 결과의 세부 옵션 (STORAGE, LOB 절): 확인 필요
- 원본 테이블의 실제 데이터 크기와 복제 소요 시간: 확인 필요 (데이터 조회 범위 밖)
- 원본 프로시저의 실제 호출 관계와 영향: 확인 필요
