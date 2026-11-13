# TQS 테이블 비교 (JH ↔ vplus)

> 조회일: 2026-11-13 · 대상: `TQS%` 로 시작하는 테이블 · 방법: 데이터 딕셔너리 조회(SELECT 전용)

## 0. 비교 기준

| 구분 | 접속 | 스키마 | 역할 |
|---|---|---|---|
| JH | `192.168.1.25:1521:ORCLU` | `JH202610` | 참조용(수정 금지) |
| vplus | `192.168.1.25:1521:ORCLU` | `VPLUS202611A` | 이식 대상 |

- 비교 항목: 테이블 존재 여부, 컬럼(이름·타입·길이·NULL 여부·DEFAULT), 컬럼 순서, PK/UK/FK, 인덱스(컬럼 구성 기준), 건수(`COUNT(*)`).
- 제약조건·인덱스는 **이름이 아니라 컬럼 구성**으로 비교했다(시스템 생성 이름 차이는 무시).
- **JH 쪽 TQS 테이블에는 테이블·컬럼 코멘트가 하나도 없다**(컬럼 2,153개 중 0개). 그래서 코멘트는 비교에서 제외했고, 아래 표의 '설명'은 vplus 코멘트다.
- 두 DB 문자셋은 모두 `AL32UTF8`로 같다.

## 1. 요약

| 항목 | 개수 |
|---|---:|
| JH TQS 테이블 | 108 |
| vplus TQS 테이블 | 83 |
| 공통 테이블 | 78 |
| &nbsp;&nbsp;└ 구조 동일 | 46 |
| &nbsp;&nbsp;└ 컬럼 순서만 다름 | 0 |
| &nbsp;&nbsp;└ 컬럼 차이 있음 | 21 |
| &nbsp;&nbsp;└ 컬럼은 같고 제약조건·인덱스만 다름 | 11 |
| JH에만 있음 (vplus에 없음) | 30 |
| vplus에만 있음 (JH에 없음) | 5 |

## 2. JH에만 있는 테이블 (30개)

vplus에 없는 테이블이다. JH에 코멘트가 없어 설명은 비워 둔다.

| # | 테이블 | 컬럼 수 | JH 건수 | PK |
|---:|---|---:|---:|---|
| 1 | `TQSA_ARND_CHK_DRY` | 14 | 2 | SIT_CD, CHK_SEQ |
| 2 | `TQSA_EDU_CD_TEMP` | 6 | 145 | - |
| 3 | `TQSA_EDU_DRY` | 13 | 6 | SIT_CD, EDU_SEQ |
| 4 | `TQSA_EDU_MSDS` | 18 | 12 | SIT_CD, EDU_SEQ, MSDS_SEQ |
| 5 | `TQSA_EMG_TRN` | 14 | 3 | SIT_CD, TRN_SEQ |
| 6 | `TQSA_HLTH_CHKUP` | 24 | 2 | SIT_CD, CHKUP_YY |
| 7 | `TQSA_HLTH_CHKUP_LIST` | 30 | 14 | SIT_CD, CHKUP_YY, CHKUP_SEQ |
| 8 | `TQSA_LABOR_JOINT_INSP` | 13 | 1 | SIT_CD, LABOR_SEQ |
| 9 | `TQSA_LABOR_MNG_CNCL` | 13 | 1 | SIT_CD, LABOR_SEQ |
| 10 | `TQSA_MSDS_CD` | 18 | 3 | SIT_CD, MSDS_SEQ |
| 11 | `TQSA_RISK_AREC_TEMP` | 33 | 0 | SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CTP_CD, UNT_CD, CHK_ITM_CD |
| 12 | `TQSA_SAFT_PGM` | 17 | 2 | SIT_CD, PGM_SEQ |
| 13 | `TQSA_SAFT_RGLN` | 14 | 2 | SIT_CD, RGLN_SEQ |
| 14 | `TQSA_WORK_ENV_MON` | 14 | 1 | SIT_CD, MON_SEQ |
| 15 | `TQSA_WRK_PDOC` | 17 | 2 | SIT_CD, WRK_SEQ |
| 16 | `TQSA_WRK_PMPP` | 15 | 2 | SIT_CD, WRK_SEQ |
| 17 | `TQSB_CTPUNT_CHKITM` | 20 | 12,484 | CTP_CD, UNT_CD, CHK_ITM_CD |
| 18 | `TQSB_CTPUNT_CHKITM_TMP` | 5 | 12,482 | - |
| 19 | `TQSB_DAYSAFE_CHKLST` | 31 | 225 | SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CTP_CD, UNT_CD, CHK_ITM_CD, ODAY_CHK_DT, RISK_GRD |
| 20 | `TQSB_DAYSAFE_DT` | 19 | 120 | SIT_CD, PLN_YM, PLN_DGR, ODAY_CHK_DT, RISK_GRD |
| 21 | `TQSB_DAYSAFE_NAM` | 13 | 59 | SIT_CD, PLN_YM, PLN_DGR, ODAY_CHK_DT, EMPE_NO_SEQ, RISK_GRD |
| 22 | `TQSB_RISKPLAN` | 13 | 0 | SIT_CD, FST_DIV, PLN_DGR |
| 23 | `TQSB_RISKPLAN_D` | 23 | 0 | SIT_CD, FST_DIV, PLN_DGR, CTP_CD, UNT_CD, CHK_ITM_CD |
| 24 | `TQSB_RISK_CHK` | 29 | 23 | SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CTP_CD, UNT_CD, CHK_ITM_CD, EMPE_NO |
| 25 | `TQSB_RISK_DGR` | 31 | 5 | SIT_CD, PLN_YM, PLN_DGR |
| 26 | `TQSB_RISK_LST` | 27 | 18 | SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CTP_CD, UNT_CD, CHK_ITM_CD |
| 27 | `TQSB_RISK_NAM` | 16 | 9 | SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, EMPE_NO |
| 28 | `TQSB_RISK_VNDR` | 19 | 9 | SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ |
| 29 | `TQSB_STOP_WK` | 25 | 1 | SIT_CD, STOP_DIV, STOP_DT, STOP_SEQ |
| 30 | `TQSB_VNDRNAM` | 24 | 6 | SIT_CD, CUST_CD, VNDR_SEQ, EMPE_NO |

## 3. vplus에만 있는 테이블 (5개)

| # | 테이블 | 설명 | 컬럼 수 | vplus 건수 | PK |
|---:|---|---|---:|---:|---|
| 1 | `TQSA_HOCHKRPT_CKHIS` | 본사점검보고서_체크리스트구분이력 | 15 | 458 | SIT_CD, CHK_DIV, CHK_DT, COM_CD, HO_CHK_DIV_CD, HO_CHK_DIV_CD2 |
| 2 | `TQSA_HOCHKRPT_DETAIL` | 본사점검보고서_세부점검 | 13 | 14 | SIT_CD, CHK_DIV, CHK_DT, PRTCL_CHK_SEQ |
| 3 | `TQSA_IDAC_MINUS` | 산재 감점자 등록 | 11 | 6 | SIT_CD, ACCD_SEQ, ACCD_PSN |
| 4 | `TQSA_RISK_AREC` | 위험성평가 회의결과 | 32 | 59 | SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CTP_CD, UNT_CD, CHK_ITM_CD |
| 5 | `TQSA_RISK_PRRTCHK` | 위험성평가 차수중점점검 | 24 | 44 | SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CTP_CD, UNT_CD, CHK_ITM_CD |

## 4. 공통 테이블 목록 (78개)

'차이'가 비어 있으면 구조가 같다. 차이가 있는 테이블은 5장에 상세가 있다.

| # | 테이블 | 설명 | 컬럼 수 (JH / vplus) | 건수 (JH / vplus) | 차이 |
|---:|---|---|---|---|---|
| 1 | `TQSA_ADDRISK_ORD` | 추가위험발굴지시 | 38 / 38 | 8 / 33 |  |
| 2 | [`TQSA_APRV`](#tqsa_aprv) | 결재관리 | 16 / 16 | 53 / 932 | 인덱스 |
| 3 | `TQSA_APRVLINE` | 결재선 관리 | 10 / 10 | 2 / 21 |  |
| 4 | `TQSA_APRVLINE_DTL` | 결재선 결재정보 | 11 / 11 | 4 / 44 |  |
| 5 | `TQSA_APRV_LINE` | 결재 라인 | 14 / 14 | 19 / 1,263 |  |
| 6 | `TQSA_AREC_CD` | 회의록코드 | 12 / 12 | 3 / 3 |  |
| 7 | [`TQSA_ASSLOG_CIRC`](#tqsa_asslog_circ) | 협의체회의록_대상자 | 12 / 12 | 15 / 45 | 인덱스 |
| 8 | `TQSA_BON_ORG` | 본사 조직현황 | 14 / 14 | 0 / 1 |  |
| 9 | [`TQSA_CKLST`](#tqsa_cklst) | 본사점검체크리스트구분 | 12 / 12 | 118 / 88 | 컬럼 |
| 10 | [`TQSA_CKLST_ITM`](#tqsa_cklst_itm) | 본사점검체크리스트항목 | 15 / 13 | 395 / 1,468 | 컬럼 |
| 11 | `TQSA_CTP` | 안전공종코드 | 10 / 10 | 182 / 9 |  |
| 12 | `TQSA_CTPUNT` | 안전공종별단위코드 | 10 / 10 | 1,227 / 18 |  |
| 13 | [`TQSA_CTPUNT_CHKITM`](#tqsa_ctpunt_chkitm) | 안전단위작업별 점검항목 | 21 / 20 | 12,485 / 70 | 컬럼 |
| 14 | `TQSA_CTP_PSN` | 공종별 담당자지정 | 9 / 9 | 5 / 20 |  |
| 15 | `TQSA_DAYSAFE_CHKLST` | 일일안전점검 목록 | 29 / 29 | 20 / 102 |  |
| 16 | `TQSA_DAYSAFE_DT` | 일일 안전점검 일자 | 19 / 19 | 15 / 138 |  |
| 17 | [`TQSA_DEEDU_CD`](#tqsa_deedu_cd) | 교육세부코드 등록 | 13 / 12 | 145 / 46 | 컬럼 |
| 18 | [`TQSA_DISASTER_CD`](#tqsa_disaster_cd) | 산업재해 발생형태코드 | 10 / 10 | 124 / 124 | 제약조건 |
| 19 | `TQSA_DISASTER_DIV` | 산업재해 발생형태구분 | 9 / 9 | 42 / 42 |  |
| 20 | [`TQSA_DRM`](#tqsa_drm) | 자료실 | 19 / 19 | 16 / 7 | 인덱스, 컬럼순서 |
| 21 | [`TQSA_DRM_ANNC`](#tqsa_drm_annc) | 알림대상 | 9 / 9 | 0 / 0 | 인덱스 |
| 22 | [`TQSA_EDU`](#tqsa_edu) | 교육일지 등록 | 36 / 39 | 5 / 382 | 컬럼 |
| 23 | `TQSA_EDU_CD` | 교육코드 등록 | 9 / 9 | 9 / 9 |  |
| 24 | [`TQSA_EQMTABK`](#tqsa_eqmtabk) | 건설장비관리대장 | 30 / 26 | 1 / 7 | 컬럼 |
| 25 | [`TQSA_HOCHKRPT`](#tqsa_hochkrpt) | 본사점검보고서 | 62 / 31 | 11 / 36 | 컬럼, 제약조건, 인덱스 |
| 26 | [`TQSA_HOCHKRPT_CK`](#tqsa_hochkrpt_ck) | 본사점검보고서_체크리스트 | 18 / 14 | 1,193 / 1,768 | 컬럼, 제약조건, 인덱스 |
| 27 | [`TQSA_HOCHKRPT_ERR`](#tqsa_hochkrpt_err) | 본사점검보고서_지적사항 | 31 / 30 | 13 / 41 | 컬럼, 제약조건, 인덱스 |
| 28 | [`TQSA_HOCHKRPT_PHOTO`](#tqsa_hochkrpt_photo) | 본사점검보고서_내부점검사진 | 12 / 12 | 2 / 39 | 컬럼, 제약조건, 인덱스 |
| 29 | [`TQSA_HODCAB`](#tqsa_hodcab) | 본사문서접수함 | 16 / 15 | 5 / 4 | 컬럼 |
| 30 | [`TQSA_IDAC`](#tqsa_idac) | 산업재해 | 97 / 65 | 3 / 14 | 컬럼 |
| 31 | `TQSA_IDAC_APRV` | 산재결재 | 10 / 10 | 0 / 28 |  |
| 32 | `TQSA_IDAC_DSVC` | 산재 재해자 등록 | 28 / 28 | 0 / 10 |  |
| 33 | [`TQSA_LABOR_LIST`](#tqsa_labor_list) | 근로자인명부 | 32 / 29 | 2 / 8 | 컬럼 |
| 34 | `TQSA_LAB_AREC` | 노사협의체 회의록 | 23 / 23 | 0 / 13 |  |
| 35 | `TQSA_LBR_CHK` | 노사합동점검 | 22 / 22 | 0 / 11 |  |
| 36 | `TQSA_LBR_CHK_ITM` | 노사합동점검표 | 16 / 16 | 0 / 12 |  |
| 37 | `TQSA_MMEDUPLAN` | 월간안전보건활동교육계획 | 13 / 13 | 4 / 23 |  |
| 38 | `TQSA_MOB_LOG` | 모바일 이력관리 | 10 / 10 | 0 / 0 |  |
| 39 | `TQSA_MSDSMNG` | MSDS관리대장 | 20 / 20 | 1 / 5 |  |
| 40 | `TQSA_NCR_REP` | 안전 부적합보고서 | 41 / 41 | 16 / 49 |  |
| 41 | `TQSA_PRES_SITE` | 대표현장 | 10 / 10 | 0 / 2 |  |
| 42 | [`TQSA_RISKPLAN`](#tqsa_riskplan) | 위험성평가 계획 | 13 / 13 | 1 / 14 | 인덱스 |
| 43 | [`TQSA_RISKPLAN_D`](#tqsa_riskplan_d) | 위험성평가 세부계획 | 23 / 22 | 6 / 191 | 컬럼, 인덱스 |
| 44 | `TQSA_RISKSITE_CIPIF` | 위험성평가(일일안전점수) 등록 | 18 / 18 | 0 / 0 |  |
| 45 | [`TQSA_RISK_CHK`](#tqsa_risk_chk) | 위험성평가 차수점검내용 | 59 / 31 | 0 / 133 | 컬럼 |
| 46 | `TQSA_RISK_DGR` | 위험성평가 일정계획(수시) | 23 / 23 | 2 / 24 |  |
| 47 | [`TQSA_RISK_VNDR`](#tqsa_risk_vndr) | 위험성평가 대상업체 | 27 / 27 | 4 / 73 | 컬럼 |
| 48 | `TQSA_SAFECOST_APRV` | 안전관리비 결재정보 | 11 / 11 | 3 / 25 |  |
| 49 | `TQSA_SAFECOST_ARSLT` | 안전관리비 월별실적 | 42 / 42 | 5 / 173 |  |
| 50 | `TQSA_SAFECOST_ARSLT_CO` | 안전관리비 사용내역(협력업체용) | 44 / 44 | 2 / 128 |  |
| 51 | `TQSA_SAFECOST_BGT` | 안전관리비 전체예산 | 10 / 10 | 9 / 63 |  |
| 52 | `TQSA_SAFECOST_BGTYM` | 안전관리비 월별예산 | 11 / 11 | 288 / 1,287 |  |
| 53 | `TQSA_SAFECOST_INFO` | 안전관리비 계상정보 | 15 / 15 | 1 / 7 |  |
| 54 | `TQSA_SAFECOST_MMARSLT_CO` | 안전관리비 월별실적(협력업체용) | 16 / 16 | 2 / 36 |  |
| 55 | `TQSA_SAFE_PERM_CD` | 안전작업허가 코드관리 | 9 / 9 | 6 / 6 |  |
| 56 | `TQSA_SAFE_PERM_CPLN` | 안전작업별 안전대책 관리 | 10 / 10 | 27 / 27 |  |
| 57 | `TQSA_SAFE_PERREQ` | 안전작업 허가요청 | 41 / 41 | 1 / 37 |  |
| 58 | `TQSA_SAFE_PERREQ_OBJ` | 안전작업 대상작업 | 12 / 12 | 0 / 56 |  |
| 59 | `TQSA_SAFE_PERREQ_OBJLST` | 안전작업 대상작업별 대책 | 11 / 11 | 0 / 87 |  |
| 60 | `TQSA_SAFT_SIT` | 안전현장 | 12 / 12 | 4 / 6 |  |
| 61 | `TQSA_SELECT` | 적격 수급인선정 | 13 / 13 | 0 / 0 |  |
| 62 | [`TQSA_SEL_LST`](#tqsa_sel_lst) | 선택목록 | 13 / 13 | 2 / 1 | 인덱스 |
| 63 | `TQSA_SITEDOC` | 본사문서접수함현장문서 | 18 / 18 | 985 / 460 |  |
| 64 | [`TQSA_SITENAM`](#tqsa_sitenam) | 안전보건_현장직원 | 21 / 20 | 224 / 28 | 컬럼 |
| 65 | [`TQSA_SUBJECT`](#tqsa_subject) | 공지사항 | 17 / 17 | 5 / 6 | 인덱스 |
| 66 | [`TQSA_VIEW_HIS`](#tqsa_view_his) | 열람이력 | 9 / 9 | 21 / 49 | 인덱스 |
| 67 | [`TQSA_VIEW_REQ`](#tqsa_view_req) | 열람신청 | 13 / 13 | 1 / 1 | 인덱스 |
| 68 | [`TQSA_VIEW_REQ_LST`](#tqsa_view_req_lst) | 열람신청목록 | 8 / 8 | 2 / 1 | 인덱스 |
| 69 | [`TQSA_VNDR`](#tqsa_vndr) | 협력업체관리 | 47 / 45 | 11 / 43 | 컬럼, 제약조건 |
| 70 | [`TQSA_WEEK_WORK_LOG`](#tqsa_week_work_log) | 현장주간업무보고 | 50 / 52 | 4 / 0 | 컬럼 |
| 71 | [`TQSA_WEEK_WORK_LOG_HO`](#tqsa_week_work_log_ho) | 본사주간업무보고 | 12 / 13 | 3 / 0 | 컬럼 |
| 72 | `TQSA_WEEK_WORK_LOG_PLAN` | 현장주간업무보고 주요위험작업 | 17 / 17 | 13 / 0 |  |
| 73 | [`TQSA_WEEK_WORK_LOG_PLAN_HO`](#tqsa_week_work_log_plan_ho) | 본사주간업무보고 주요위험작업 | 15 / 12 | 10 / 0 | 컬럼 |
| 74 | `TQSA_YYTRGARSLT` | 년간안전보건목표추진실적 | 17 / 17 | 1 / 20 |  |
| 75 | `TQSA_YYTRGARSLTSEQ` | 년간안전보건목표추진실적차수 | 15 / 15 | 1 / 9 |  |
| 76 | `TQSA_YYTRGPLN` | 년간안전보건목표추진계획 | 16 / 16 | 1 / 22 |  |
| 77 | `TQSA_YYTRGPLNCHR` | 년간안전보건목표추진계획담당자 | 15 / 15 | 3 / 12 |  |
| 78 | `TQSA_YYTRGPLNSEQ` | 년간안전보건목표추진계획차수 | 14 / 14 | 1 / 14 |  |

## 5. 공통 테이블 구조 차이 상세 (32개)

### TQSA_CKLST

본사점검체크리스트구분 · 컬럼 12 / 12 · 건수 118 / 88 (JH / vplus)

**속성이 다른 컬럼 (1)**

| 컬럼 | 설명 | JH | vplus |
|---|---|---|---|
| `HO_CHK_DIV_NM` | 본사점검구분명 | VARCHAR2(100) | VARCHAR2(50) |

### TQSA_CKLST_ITM

본사점검체크리스트항목 · 컬럼 15 / 13 · 건수 395 / 1,468 (JH / vplus)

**JH에만 있는 컬럼 (2)**

| 컬럼 | 타입 |
|---|---|
| `HO_CHK_ITM_NM2` | VARCHAR2(500) |
| `MAX_SCORE` | NUMBER(38) |

### TQSA_CTPUNT_CHKITM

안전단위작업별 점검항목 · 컬럼 21 / 20 · 건수 12,485 / 70 (JH / vplus)

**JH에만 있는 컬럼 (1)**

| 컬럼 | 타입 |
|---|---|
| `RISK_CRIT` | VARCHAR2(10) |

### TQSA_DEEDU_CD

교육세부코드 등록 · 컬럼 13 / 12 · 건수 145 / 46 (JH / vplus)

**JH에만 있는 컬럼 (1)**

| 컬럼 | 타입 |
|---|---|
| `EDU_TIME` | VARCHAR2(100) |

**속성이 다른 컬럼 (1)**

| 컬럼 | 설명 | JH | vplus |
|---|---|---|---|
| `DEEDU_NM` | 세부교육코드명 | VARCHAR2(2000) | VARCHAR2(500) |

### TQSA_EDU

교육일지 등록 · 컬럼 36 / 39 · 건수 5 / 382 (JH / vplus) · 컬럼 순서 다름

**JH에만 있는 컬럼 (10)**

| 컬럼 | 타입 |
|---|---|
| `EDU_DT` | VARCHAR2(8) |
| `EDU_TIME` | VARCHAR2(20) |
| `REL_LNR1` | VARCHAR2(100) |
| `REL_LNR2` | VARCHAR2(100) |
| `MSDS_RMKS` | VARCHAR2(4000) |
| `PHOTO_DT_1` | VARCHAR2(100) |
| `PHOTO_DT_2` | VARCHAR2(100) |
| `PHOTO_GRP3` | VARCHAR2(50) |
| `PHOTO_DESC_3` | VARCHAR2(100) |
| `PHOTO_DT_3` | VARCHAR2(100) |

**vplus에만 있는 컬럼 (13)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `EDU_DIV` | VARCHAR2(10) | 20240226 미사용 |
| `EDU_ETCNM` | VARCHAR2(50) | 기타교육내용 |
| `EDU_STR_DT` | VARCHAR2(8) | 교육시작일 |
| `EDU_END_DT` | VARCHAR2(8) | 교육종료일 |
| `STR_TIME` | VARCHAR2(5) | 시작시간 |
| `END_TIME` | VARCHAR2(5) | 종료시간 |
| `EDU_CTS1` | VARCHAR2(1000) | 공통외 기타교육내용 |
| `CUST_CD` | NUMBER(22) | 거래처코드 |
| `VNDR_SEQ` | NUMBER(3) | 업체순번 |
| `REL_LNR` | VARCHAR2(100) | 관련법규 |
| `DEEDU_CD3` | VARCHAR2(10) | 세부교육코드3 |
| `DEEDU_CD4` | VARCHAR2(10) | 세부교육코드4 |
| `EDU_CTS4` | VARCHAR2(1000) | 공통외특별교육내용4 |

**속성이 다른 컬럼 (9)**

| 컬럼 | 설명 | JH | vplus |
|---|---|---|---|
| `EDU_SEQ` | 교육순번 | NUMBER(13) NOT NULL | NUMBER(*,0) NOT NULL |
| `EDU_CD` | 교육코드 | VARCHAR2(10) NOT NULL | VARCHAR2(10) |
| `DEEDU_CD` | 교육세부코드 | VARCHAR2(10) NOT NULL | VARCHAR2(10) |
| `EDU_OBJ_MAN` | 교육인원_대상남성 | NUMBER | NUMBER(*,0) |
| `EDU_IMPL_MAN` | 교육인원_실시남성 | NUMBER | NUMBER(*,0) |
| `EDU_MTD` | 교육대상 | VARCHAR2(4000) | VARCHAR2(200) |
| `EDU_CTS` | 교육내용 | VARCHAR2(4000) | VARCHAR2(1000) |
| `EDU_CTS2` | 공통외 특별교육내용 | VARCHAR2(4000) | VARCHAR2(1000) |
| `EDU_CTS3` | 공통외특별교육내용3 | VARCHAR2(4000) | VARCHAR2(1000) |

### TQSA_EQMTABK

건설장비관리대장 · 컬럼 30 / 26 · 건수 1 / 7 (JH / vplus)

**JH에만 있는 컬럼 (4)**

| 컬럼 | 타입 |
|---|---|
| `RGL_STR_DD` | VARCHAR2(8) |
| `RGL_END_DD` | VARCHAR2(8) |
| `MNG_PNM` | VARCHAR2(50) |
| `MNG_CELPH` | VARCHAR2(500) |

### TQSA_HOCHKRPT

본사점검보고서 · 컬럼 62 / 31 · 건수 11 / 36 (JH / vplus) · 컬럼 순서 다름

**JH에만 있는 컬럼 (39)**

| 컬럼 | 타입 |
|---|---|
| `CHK_DGR` | NUMBER(3) NOT NULL |
| `INSP_NM` | VARCHAR2(100) |
| `SAFT_MGR` | VARCHAR2(20) |
| `SAFT_MGR_NM` | VARCHAR2(100) |
| `DISS_ACM` | VARCHAR2(100) |
| `DISS_CY` | VARCHAR2(100) |
| `SAFT_MCHR` | NUMBER(38) |
| `SAFT_ACM_AMT` | NUMBER(38) |
| `SAFT_USE_RT` | NUMBER(5,2) |
| `TDAY_WRK` | VARCHAR2(1000) |
| `SCH_WRK` | VARCHAR2(1000) |
| `RVLT_SCR1` | NUMBER(13,2) |
| `RVLT_SCR2` | NUMBER(13,2) |
| `RVLT_SCR3` | NUMBER(13,2) |
| `RVLT_SCR4` | NUMBER(13,2) |
| `RVLT_SCR5` | NUMBER(13,2) |
| `TTM_SCR1` | NUMBER(13,2) |
| `TTM_SCR2` | NUMBER(13,2) |
| `TTM_SCR3` | NUMBER(13,2) |
| `TTM_SCR4` | NUMBER(13,2) |
| `TTM_SCR5` | NUMBER(13,2) |
| `APRS_GRD1` | VARCHAR2(1) |
| `APRS_GRD2` | VARCHAR2(1) |
| `APRS_GRD3` | VARCHAR2(1) |
| `APRS_GRD4` | VARCHAR2(1) |
| `APRS_GRD5` | VARCHAR2(1) |
| `RMKS1` | VARCHAR2(1000) |
| `RMKS2` | VARCHAR2(1000) |
| `RMKS3` | VARCHAR2(1000) |
| `RMKS4` | VARCHAR2(1000) |
| `RMKS5` | VARCHAR2(1000) |
| `EXCL_EXMP` | VARCHAR2(1000) |
| `MNG_MATT` | VARCHAR2(1000) |
| `PRGS_STATS_CD1` | VARCHAR2(20) |
| `APRV_NO1` | VARCHAR2(20) |
| `PRGS_STATS_CD2` | VARCHAR2(20) |
| `APRV_NO2` | VARCHAR2(20) |
| `QUARTER` | VARCHAR2(10) |
| `CLOSE_YN` | VARCHAR2(1) DEFAULT '0' |

**vplus에만 있는 컬럼 (8)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `SIT_NM` | VARCHAR2(100) | 현장명 |
| `INSP_PNM` | VARCHAR2(50) | 점검자성명 |
| `COLL_UNTK` | VARCHAR2(100) | 공동도급 |
| `CHK_MAIN_CTS` | VARCHAR2(1000) | 점검주요내용 |
| `PRGS_STATS_CD8` | VARCHAR2(20) | 본사점검보고서(환경) |
| `APRV_NO8` | VARCHAR2(20) | 본사점검보고서(환경)승인 |
| `PRGS_STATS_CD9` | VARCHAR2(20) | 현장조치보고서 |
| `APRV_NO9` | VARCHAR2(20) | 현장조치보고서승인 |

**속성이 다른 컬럼 (2)**

| 컬럼 | 설명 | JH | vplus |
|---|---|---|---|
| `CNST_AMT` | 공사금액 | NUMBER(38) | NUMBER(15) |
| `CNST_SCAL` | 공사규모 | VARCHAR2(100) | VARCHAR2(1000) |

**제약조건 차이**

| 구분 | 종류 | 컬럼 |
|---|---|---|
| JH에만 | PK | SIT_CD, CHK_DIV, CHK_DGR |
| vplus에만 | PK | SIT_CD, CHK_DIV, CHK_DT |

**인덱스 차이**

| 구분 | 유형 | 컬럼 |
|---|---|---|
| JH에만 | UNIQUE | SIT_CD, CHK_DIV, CHK_DGR |
| vplus에만 | UNIQUE | SIT_CD, CHK_DIV, CHK_DT |

### TQSA_HOCHKRPT_CK

본사점검보고서_체크리스트 · 컬럼 18 / 14 · 건수 1,193 / 1,768 (JH / vplus) · 컬럼 순서 다름

**JH에만 있는 컬럼 (5)**

| 컬럼 | 타입 |
|---|---|
| `CHK_DGR` | NUMBER(3) NOT NULL |
| `APRS_CHK` | VARCHAR2(20) |
| `APRS_PNDS` | NUMBER(38) |
| `APRS_SCR` | NUMBER(38,2) |
| `APRS_CTS` | VARCHAR2(500) |

**vplus에만 있는 컬럼 (1)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `HO_CHK_APRS_SCR` | NUMBER(38) | 공통코드 : QSM04 |

**제약조건 차이**

| 구분 | 종류 | 컬럼 |
|---|---|---|
| JH에만 | PK | SIT_CD, CHK_DIV, CHK_DGR, HO_CHK_DIV_CD, HO_CHK_DIV_CD2, HO_CHK_ITM_CD, COM_CD |
| JH에만 | FK | SIT_CD, CHK_DIV, CHK_DGR |
| vplus에만 | PK | SIT_CD, CHK_DIV, CHK_DT, HO_CHK_DIV_CD, HO_CHK_DIV_CD2, HO_CHK_ITM_CD, COM_CD |

**인덱스 차이**

| 구분 | 유형 | 컬럼 |
|---|---|---|
| JH에만 | UNIQUE | SIT_CD, CHK_DIV, CHK_DGR, HO_CHK_DIV_CD, HO_CHK_DIV_CD2, HO_CHK_ITM_CD, COM_CD |
| vplus에만 | UNIQUE | SIT_CD, CHK_DIV, CHK_DT, HO_CHK_DIV_CD, HO_CHK_DIV_CD2, HO_CHK_ITM_CD, COM_CD |

### TQSA_HOCHKRPT_ERR

본사점검보고서_지적사항 · 컬럼 31 / 30 · 건수 13 / 41 (JH / vplus) · 컬럼 순서 다름

**JH에만 있는 컬럼 (3)**

| 컬럼 | 타입 |
|---|---|
| `CHK_DGR` | NUMBER(3) NOT NULL |
| `INSP_NM` | VARCHAR2(50) |
| `MA_PSN_NM` | VARCHAR2(50) |

**vplus에만 있는 컬럼 (2)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `INSP_PNM` | VARCHAR2(50) | 점검자성명 |
| `MA_PSN_PNM` | VARCHAR2(50) | 조치자성명 |

**속성이 다른 컬럼 (2)**

| 컬럼 | 설명 | JH | vplus |
|---|---|---|---|
| `CHK_MATT` | 지적사항 | VARCHAR2(4000) | VARCHAR2(1000) |
| `MA_MATT` | 조치사항 | VARCHAR2(4000) | VARCHAR2(500) |

**제약조건 차이**

| 구분 | 종류 | 컬럼 |
|---|---|---|
| JH에만 | FK | SIT_CD, CHK_DIV, CHK_DGR |
| vplus에만 | PK | SIT_CD, CHK_DIV, CHK_DT, ERR_SEQ |

**인덱스 차이**

| 구분 | 유형 | 컬럼 |
|---|---|---|
| vplus에만 | UNIQUE | SIT_CD, CHK_DIV, CHK_DT, ERR_SEQ |

### TQSA_HOCHKRPT_PHOTO

본사점검보고서_내부점검사진 · 컬럼 12 / 12 · 건수 2 / 39 (JH / vplus)

**JH에만 있는 컬럼 (2)**

| 컬럼 | 타입 |
|---|---|
| `CHK_DGR` | NUMBER(3) NOT NULL |
| `ATFL_GRP2` | VARCHAR2(50) |

**vplus에만 있는 컬럼 (2)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `CHK_DT` | VARCHAR2(8) NOT NULL | 점검일자 |
| `PHOTO_SEQ` | NUMBER(38) NOT NULL | 사진순번 |

**제약조건 차이**

| 구분 | 종류 | 컬럼 |
|---|---|---|
| JH에만 | FK | SIT_CD, CHK_DIV, CHK_DGR |
| vplus에만 | PK | SIT_CD, CHK_DIV, CHK_DT, PHOTO_SEQ |

**인덱스 차이**

| 구분 | 유형 | 컬럼 |
|---|---|---|
| vplus에만 | UNIQUE | SIT_CD, CHK_DIV, CHK_DT, PHOTO_SEQ |

### TQSA_HODCAB

본사문서접수함 · 컬럼 16 / 15 · 건수 5 / 4 (JH / vplus)

**JH에만 있는 컬럼 (1)**

| 컬럼 | 타입 |
|---|---|
| `ATFL_GRP` | VARCHAR2(50) |

### TQSA_IDAC

산업재해 · 컬럼 97 / 65 · 건수 3 / 14 (JH / vplus) · 컬럼 순서 다름

**JH에만 있는 컬럼 (33)**

| 컬럼 | 타입 |
|---|---|
| `DSVC_MP` | VARCHAR2(4000) |
| `PHOTO_GRP3` | VARCHAR2(50) |
| `PHOTO_DESC_3` | VARCHAR2(100) |
| `PHOTO_GRP4` | VARCHAR2(50) |
| `PHOTO_DESC_4` | VARCHAR2(100) |
| `BZ_HQ` | VARCHAR2(20) |
| `SITE_TEL_NO` | VARCHAR2(20) |
| `EMP_CNT` | NUMBER(13) |
| `PROCRT` | NUMBER(5,2) |
| `TOT_CNST_AMT` | NUMBER(13) |
| `WTS_NM1` | VARCHAR2(50) |
| `WTS_NM2` | VARCHAR2(50) |
| `WTS_NM3` | VARCHAR2(50) |
| `SAFT_EDU_CMPL_DT` | VARCHAR2(8) |
| `OCC_DIS_CNT` | NUMBER(13) |
| `IDRT_TECH` | VARCHAR2(200) |
| `IDRT_EDU` | VARCHAR2(200) |
| `IDRT_WRK` | VARCHAR2(200) |
| `DRT_UNSF_STATS` | VARCHAR2(200) |
| `DRT_UNSF_ACT` | VARCHAR2(200) |
| `DFT_DOC` | VARCHAR2(100) |
| `RPT_DT` | VARCHAR2(8) |
| `ACP_DT` | VARCHAR2(8) |
| `MED_ORG` | VARCHAR2(100) |
| `MED_CADDR` | VARCHAR2(20) |
| `ETC_MATT` | VARCHAR2(500) |
| `APRV_NO` | VARCHAR2(20) |
| `APRV_NO_GW` | VARCHAR2(80) |
| `DISS_TYPE` | VARCHAR2(20) |
| `DSVC_AGE` | NUMBER(3) |
| `DISS_DIV_ETC` | VARCHAR2(100) |
| `DIS_DESC` | VARCHAR2(500) |
| `ATFL_GRP2` | VARCHAR2(50) |

**vplus에만 있는 컬럼 (1)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `DSVC_BRTH` | VARCHAR2(500) | 개인정보 암호화 |

**속성이 다른 컬럼 (4)**

| 컬럼 | 설명 | JH | vplus |
|---|---|---|---|
| `DSVC` | 개인정보 암호화 | VARCHAR2(100) | VARCHAR2(500) |
| `DSVC_VNDR` | 개인정보 암호화 | VARCHAR2(100) | VARCHAR2(4000) |
| `DSVC_HIRDT` | 개인정보 암호화 | VARCHAR2(8) | VARCHAR2(500) |
| `DSVC_RSDNNO` | 재해자_주민번호(개인정보 암호화) | VARCHAR2(4000) | VARCHAR2(500) |

### TQSA_LABOR_LIST

근로자인명부 · 컬럼 32 / 29 · 건수 2 / 8 (JH / vplus)

**JH에만 있는 컬럼 (3)**

| 컬럼 | 타입 |
|---|---|
| `ATFL_GRP` | VARCHAR2(50) |
| `ELDR` | VARCHAR2(500) |
| `HLTH_ABN` | VARCHAR2(500) |

### TQSA_RISKPLAN_D

위험성평가 세부계획 · 컬럼 23 / 22 · 건수 6 / 191 (JH / vplus)

**JH에만 있는 컬럼 (1)**

| 컬럼 | 타입 |
|---|---|
| `RISK_CRIT` | VARCHAR2(10) |

**인덱스 차이**

| 구분 | 유형 | 컬럼 |
|---|---|---|
| vplus에만 | UNIQUE | SIT_CD, FST_DIV, PLN_DGR, CTP_CD, UNT_CD, CHK_ITM_CD |

### TQSA_RISK_CHK

위험성평가 차수점검내용 · 컬럼 59 / 31 · 건수 0 / 133 (JH / vplus) · 컬럼 순서 다름

**JH에만 있는 컬럼 (28)**

| 컬럼 | 타입 |
|---|---|
| `RISK_CRIT` | VARCHAR2(10) |
| `RISK_FREQ2` | VARCHAR2(10) |
| `RISK_APRV2` | VARCHAR2(10) |
| `RISK_CRIT2` | VARCHAR2(10) |
| `RISK_GRD2` | VARCHAR2(10) |
| `MNG_SUPR` | VARCHAR2(10) |
| `RISK_FREQ3` | VARCHAR2(10) |
| `RISK_APRV3` | VARCHAR2(10) |
| `RISK_CRIT3` | VARCHAR2(10) |
| `RISK_GRD3` | VARCHAR2(10) |
| `SAFT_MGR` | VARCHAR2(10) |
| `RISK_FREQ4` | VARCHAR2(10) |
| `RISK_APRV4` | VARCHAR2(10) |
| `RISK_CRIT4` | VARCHAR2(10) |
| `RISK_GRD4` | VARCHAR2(10) |
| `SITE_OMGR` | VARCHAR2(10) |
| `SITE_OPIN` | VARCHAR2(500) |
| `RISK_FREQ5` | VARCHAR2(10) |
| `RISK_APRV5` | VARCHAR2(10) |
| `RISK_CRIT5` | VARCHAR2(10) |
| `RISK_GRD5` | VARCHAR2(10) |
| `RISK_FREQ6` | VARCHAR2(10) |
| `RISK_APRV6` | VARCHAR2(10) |
| `RISK_CRIT6` | VARCHAR2(10) |
| `RISK_GRD6` | VARCHAR2(10) |
| `ITM_ADD_YN` | VARCHAR2(1) DEFAULT '0' |
| `VNDR_WRK_NM` | VARCHAR2(100) |
| `VNDR_WRK_OPIN` | VARCHAR2(500) |

**속성이 다른 컬럼 (1)**

| 컬럼 | 설명 | JH | vplus |
|---|---|---|---|
| `VNDR_SEQ` | 업체순번 | NUMBER(13) NOT NULL | NUMBER(3) NOT NULL |

### TQSA_RISK_VNDR

위험성평가 대상업체 · 컬럼 27 / 27 · 건수 4 / 73 (JH / vplus)

**JH에만 있는 컬럼 (1)**

| 컬럼 | 타입 |
|---|---|
| `VNDR_WRK_NM` | VARCHAR2(100) |

**vplus에만 있는 컬럼 (1)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `SITE_OPIN` | VARCHAR2(500) | 현장소장의견 |

### TQSA_SITENAM

안전보건_현장직원 · 컬럼 21 / 20 · 건수 224 / 28 (JH / vplus)

**JH에만 있는 컬럼 (1)**

| 컬럼 | 타입 |
|---|---|
| `JB_CD` | VARCHAR2(20) |

### TQSA_VNDR

협력업체관리 · 컬럼 47 / 45 · 건수 11 / 43 (JH / vplus) · 컬럼 순서 다름

**JH에만 있는 컬럼 (2)**

| 컬럼 | 타입 |
|---|---|
| `CTP_CD` | VARCHAR2(10) |
| `CTP_NM` | VARCHAR2(100) |

**제약조건 차이**

| 구분 | 종류 | 컬럼 |
|---|---|---|
| JH에만 | FK | CTP_CD |

### TQSA_WEEK_WORK_LOG

현장주간업무보고 · 컬럼 50 / 52 · 건수 4 / 0 (JH / vplus)

**JH에만 있는 컬럼 (1)**

| 컬럼 | 타입 |
|---|---|
| `ETC_INST_MATT` | VARCHAR2(1000) |

**vplus에만 있는 컬럼 (3)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `ETC_INST_YN` | VARCHAR2(1) | 기타설치여부 |
| `ETC_INST_CNT` | NUMBER(13) | 기타설치개수 |
| `ETC_DMT_CNT` | NUMBER(13) | 기타해체개수 |

### TQSA_WEEK_WORK_LOG_HO

본사주간업무보고 · 컬럼 12 / 13 · 건수 3 / 0 (JH / vplus)

**vplus에만 있는 컬럼 (1)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `APRV_NO_GW` | VARCHAR2(20) | 결재번호GW |

### TQSA_WEEK_WORK_LOG_PLAN_HO

본사주간업무보고 주요위험작업 · 컬럼 15 / 12 · 건수 10 / 0 (JH / vplus)

**JH에만 있는 컬럼 (3)**

| 컬럼 | 타입 |
|---|---|
| `RMKS` | VARCHAR2(1000) |
| `TOT_PROCRT` | NUMBER(5,2) |
| `IMPTC_YN` | VARCHAR2(1) |

### TQSA_APRV

결재관리 · 컬럼 16 / 16 · 건수 53 / 932 (JH / vplus)

**인덱스 차이**

| 구분 | 유형 | 컬럼 |
|---|---|---|
| JH에만 | UNIQUE | SIT_CD, APRV_NO |
| vplus에만 | NONUNIQUE | APRV_NO |
| vplus에만 | NONUNIQUE | SIT_CD, APRV_NO, APRV_STATS |

### TQSA_ASSLOG_CIRC

협의체회의록_대상자 · 컬럼 12 / 12 · 건수 15 / 45 (JH / vplus)

**인덱스 차이**

| 구분 | 유형 | 컬럼 |
|---|---|---|
| vplus에만 | UNIQUE | SIT_CD, PLN_YM, PLN_DGR, CO_DIV_CD, EMPE_NO |

### TQSA_DISASTER_CD

산업재해 발생형태코드 · 컬럼 10 / 10 · 건수 124 / 124 (JH / vplus)

**제약조건 차이**

| 구분 | 종류 | 컬럼 |
|---|---|---|
| vplus에만 | FK | DIV_CD |

### TQSA_DRM

자료실 · 컬럼 19 / 19 · 건수 16 / 7 (JH / vplus) · 컬럼 순서 다름

**인덱스 차이**

| 구분 | 유형 | 컬럼 |
|---|---|---|
| vplus에만 | UNIQUE | REG_NO, REG_DGR |

### TQSA_DRM_ANNC

알림대상 · 컬럼 9 / 9 · 건수 0 / 0 (JH / vplus)

**인덱스 차이**

| 구분 | 유형 | 컬럼 |
|---|---|---|
| vplus에만 | UNIQUE | REG_NO, EMPNO |

### TQSA_RISKPLAN

위험성평가 계획 · 컬럼 13 / 13 · 건수 1 / 14 (JH / vplus)

**인덱스 차이**

| 구분 | 유형 | 컬럼 |
|---|---|---|
| vplus에만 | UNIQUE | SIT_CD, FST_DIV, PLN_DGR |

### TQSA_SEL_LST

선택목록 · 컬럼 13 / 13 · 건수 2 / 1 (JH / vplus)

**인덱스 차이**

| 구분 | 유형 | 컬럼 |
|---|---|---|
| vplus에만 | UNIQUE | MNU_CD, USR_ID, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5 |

### TQSA_SUBJECT

공지사항 · 컬럼 17 / 17 · 건수 5 / 6 (JH / vplus)

**인덱스 차이**

| 구분 | 유형 | 컬럼 |
|---|---|---|
| vplus에만 | NONUNIQUE | SIT_CD |

### TQSA_VIEW_HIS

열람이력 · 컬럼 9 / 9 · 건수 21 / 49 (JH / vplus)

**인덱스 차이**

| 구분 | 유형 | 컬럼 |
|---|---|---|
| vplus에만 | UNIQUE | REG_NO, REG_DGR, USR_ID |

### TQSA_VIEW_REQ

열람신청 · 컬럼 13 / 13 · 건수 1 / 1 (JH / vplus)

**인덱스 차이**

| 구분 | 유형 | 컬럼 |
|---|---|---|
| vplus에만 | UNIQUE | APL_SEQ |

### TQSA_VIEW_REQ_LST

열람신청목록 · 컬럼 8 / 8 · 건수 2 / 1 (JH / vplus)

**인덱스 차이**

| 구분 | 유형 | 컬럼 |
|---|---|---|
| vplus에만 | UNIQUE | APL_SEQ, REG_NO |

## 6. 참고

- 이름이 `TQS`로 시작하는 테이블 외 객체(뷰·시퀀스·프로시저 등 포함 조회):
  - JH: `TQSA_MSDS_CD_PK`(INDEX)
  - vplus: `TQSA_APRV_APRV_NO_IDX`(INDEX), `TQSA_APRV_SIT_CD_IDX`(INDEX)
- 건수는 조회 시점의 `COUNT(*)` 값이다. vplus는 이식 대상 DB에 들어 있는 데이터, JH는 참조 DB의 데이터라 건수 차이 자체는 구조 차이가 아니다.
