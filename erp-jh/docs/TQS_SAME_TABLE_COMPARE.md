# 동일 테이블명 컬럼 비교 (JH ↔ vplus, TQS)

> 조회일: 2026-11-13 · 대상: 두 DB에 **같은 이름으로 있는** `TQS%` 테이블 78개 · 방법: 데이터 딕셔너리 조회(SELECT 전용)

| 구분 | 접속 | 스키마 |
|---|---|---|
| JH | `192.168.1.25:1521:ORCLU` | `JH202610` |
| vplus | `192.168.1.25:1521:ORCLU` | `VPLUS202611A` |

- 비교 항목: 컬럼 존재 여부, 컬럼 속성(타입, 길이, NULL 허용, DEFAULT).
- 제약조건, 인덱스, 코멘트, 컬럼 순서, 건수는 비교하지 않았다. 설명란은 참고용 코멘트다.
- 한쪽에만 있는 테이블(JH에만 30개, vplus에만 5개)은 다루지 않는다.

## 1. 요약

| 구분 | 개수 |
|---|---:|
| 비교 대상 테이블 | 78 |
| 컬럼이 완전히 같은 테이블 | 57 |
| 컬럼 차이가 있는 테이블 | 21 |
| JH에만 있는 컬럼 | 141 (19개 테이블) |
| vplus에만 있는 컬럼 | 32 (9개 테이블) |
| 속성 차이 – 타입 | 0 (0개 테이블) |
| 속성 차이 – 길이 | 18 (7개 테이블) |
| 속성 차이 – NULL | 2 (1개 테이블) |
| 속성 차이 – DEFAULT | 0 (0개 테이블) |

## 2. 전체 목록

빈칸은 차이가 없다는 뜻이다. 차이가 있는 테이블은 이름을 누르면 3장 상세로 간다.

| # | 테이블 | 설명 | 컬럼 수 JH / vplus | JH만 | vplus만 | 속성 차이 |
|---:|---|---|---|---:|---:|---:|
| 1 | `TQSA_ADDRISK_ORD` | 추가위험발굴지시 | 38 / 38 |  |  |  |
| 2 | `TQSA_APRV` | 결재관리 | 16 / 16 |  |  |  |
| 3 | `TQSA_APRVLINE` | 결재선 관리 | 10 / 10 |  |  |  |
| 4 | `TQSA_APRVLINE_DTL` | 결재선 결재정보 | 11 / 11 |  |  |  |
| 5 | `TQSA_APRV_LINE` | 결재 라인 | 14 / 14 |  |  |  |
| 6 | `TQSA_AREC_CD` | 회의록코드 | 12 / 12 |  |  |  |
| 7 | `TQSA_ASSLOG_CIRC` | 협의체회의록_대상자 | 12 / 12 |  |  |  |
| 8 | `TQSA_BON_ORG` | 본사 조직현황 | 14 / 14 |  |  |  |
| 9 | [`TQSA_CKLST`](#tqsa_cklst) | 본사점검체크리스트구분 | 12 / 12 |  |  | 1 |
| 10 | [`TQSA_CKLST_ITM`](#tqsa_cklst_itm) | 본사점검체크리스트항목 | 15 / 13 | 2 |  |  |
| 11 | `TQSA_CTP` | 안전공종코드 | 10 / 10 |  |  |  |
| 12 | `TQSA_CTPUNT` | 안전공종별단위코드 | 10 / 10 |  |  |  |
| 13 | [`TQSA_CTPUNT_CHKITM`](#tqsa_ctpunt_chkitm) | 안전단위작업별 점검항목 | 21 / 20 | 1 |  |  |
| 14 | `TQSA_CTP_PSN` | 공종별 담당자지정 | 9 / 9 |  |  |  |
| 15 | `TQSA_DAYSAFE_CHKLST` | 일일안전점검 목록 | 29 / 29 |  |  |  |
| 16 | `TQSA_DAYSAFE_DT` | 일일 안전점검 일자 | 19 / 19 |  |  |  |
| 17 | [`TQSA_DEEDU_CD`](#tqsa_deedu_cd) | 교육세부코드 등록 | 13 / 12 | 1 |  | 1 |
| 18 | `TQSA_DISASTER_CD` | 산업재해 발생형태코드 | 10 / 10 |  |  |  |
| 19 | `TQSA_DISASTER_DIV` | 산업재해 발생형태구분 | 9 / 9 |  |  |  |
| 20 | `TQSA_DRM` | 자료실 | 19 / 19 |  |  |  |
| 21 | `TQSA_DRM_ANNC` | 알림대상 | 9 / 9 |  |  |  |
| 22 | [`TQSA_EDU`](#tqsa_edu) | 교육일지 등록 | 36 / 39 | 10 | 13 | 9 |
| 23 | `TQSA_EDU_CD` | 교육코드 등록 | 9 / 9 |  |  |  |
| 24 | [`TQSA_EQMTABK`](#tqsa_eqmtabk) | 건설장비관리대장 | 30 / 26 | 4 |  |  |
| 25 | [`TQSA_HOCHKRPT`](#tqsa_hochkrpt) | 본사점검보고서 | 62 / 31 | 39 | 8 | 2 |
| 26 | [`TQSA_HOCHKRPT_CK`](#tqsa_hochkrpt_ck) | 본사점검보고서_체크리스트 | 18 / 14 | 5 | 1 |  |
| 27 | [`TQSA_HOCHKRPT_ERR`](#tqsa_hochkrpt_err) | 본사점검보고서_지적사항 | 31 / 30 | 3 | 2 | 2 |
| 28 | [`TQSA_HOCHKRPT_PHOTO`](#tqsa_hochkrpt_photo) | 본사점검보고서_내부점검사진 | 12 / 12 | 2 | 2 |  |
| 29 | [`TQSA_HODCAB`](#tqsa_hodcab) | 본사문서접수함 | 16 / 15 | 1 |  |  |
| 30 | [`TQSA_IDAC`](#tqsa_idac) | 산업재해 | 97 / 65 | 33 | 1 | 4 |
| 31 | `TQSA_IDAC_APRV` | 산재결재 | 10 / 10 |  |  |  |
| 32 | `TQSA_IDAC_DSVC` | 산재 재해자 등록 | 28 / 28 |  |  |  |
| 33 | [`TQSA_LABOR_LIST`](#tqsa_labor_list) | 근로자인명부 | 32 / 29 | 3 |  |  |
| 34 | `TQSA_LAB_AREC` | 노사협의체 회의록 | 23 / 23 |  |  |  |
| 35 | `TQSA_LBR_CHK` | 노사합동점검 | 22 / 22 |  |  |  |
| 36 | `TQSA_LBR_CHK_ITM` | 노사합동점검표 | 16 / 16 |  |  |  |
| 37 | `TQSA_MMEDUPLAN` | 월간안전보건활동교육계획 | 13 / 13 |  |  |  |
| 38 | `TQSA_MOB_LOG` | 모바일 이력관리 | 10 / 10 |  |  |  |
| 39 | `TQSA_MSDSMNG` | MSDS관리대장 | 20 / 20 |  |  |  |
| 40 | `TQSA_NCR_REP` | 안전 부적합보고서 | 41 / 41 |  |  |  |
| 41 | `TQSA_PRES_SITE` | 대표현장 | 10 / 10 |  |  |  |
| 42 | `TQSA_RISKPLAN` | 위험성평가 계획 | 13 / 13 |  |  |  |
| 43 | [`TQSA_RISKPLAN_D`](#tqsa_riskplan_d) | 위험성평가 세부계획 | 23 / 22 | 1 |  |  |
| 44 | `TQSA_RISKSITE_CIPIF` | 위험성평가(일일안전점수) 등록 | 18 / 18 |  |  |  |
| 45 | [`TQSA_RISK_CHK`](#tqsa_risk_chk) | 위험성평가 차수점검내용 | 59 / 31 | 28 |  | 1 |
| 46 | `TQSA_RISK_DGR` | 위험성평가 일정계획(수시) | 23 / 23 |  |  |  |
| 47 | [`TQSA_RISK_VNDR`](#tqsa_risk_vndr) | 위험성평가 대상업체 | 27 / 27 | 1 | 1 |  |
| 48 | `TQSA_SAFECOST_APRV` | 안전관리비 결재정보 | 11 / 11 |  |  |  |
| 49 | `TQSA_SAFECOST_ARSLT` | 안전관리비 월별실적 | 42 / 42 |  |  |  |
| 50 | `TQSA_SAFECOST_ARSLT_CO` | 안전관리비 사용내역(협력업체용) | 44 / 44 |  |  |  |
| 51 | `TQSA_SAFECOST_BGT` | 안전관리비 전체예산 | 10 / 10 |  |  |  |
| 52 | `TQSA_SAFECOST_BGTYM` | 안전관리비 월별예산 | 11 / 11 |  |  |  |
| 53 | `TQSA_SAFECOST_INFO` | 안전관리비 계상정보 | 15 / 15 |  |  |  |
| 54 | `TQSA_SAFECOST_MMARSLT_CO` | 안전관리비 월별실적(협력업체용) | 16 / 16 |  |  |  |
| 55 | `TQSA_SAFE_PERM_CD` | 안전작업허가 코드관리 | 9 / 9 |  |  |  |
| 56 | `TQSA_SAFE_PERM_CPLN` | 안전작업별 안전대책 관리 | 10 / 10 |  |  |  |
| 57 | `TQSA_SAFE_PERREQ` | 안전작업 허가요청 | 41 / 41 |  |  |  |
| 58 | `TQSA_SAFE_PERREQ_OBJ` | 안전작업 대상작업 | 12 / 12 |  |  |  |
| 59 | `TQSA_SAFE_PERREQ_OBJLST` | 안전작업 대상작업별 대책 | 11 / 11 |  |  |  |
| 60 | `TQSA_SAFT_SIT` | 안전현장 | 12 / 12 |  |  |  |
| 61 | `TQSA_SELECT` | 적격 수급인선정 | 13 / 13 |  |  |  |
| 62 | `TQSA_SEL_LST` | 선택목록 | 13 / 13 |  |  |  |
| 63 | `TQSA_SITEDOC` | 본사문서접수함현장문서 | 18 / 18 |  |  |  |
| 64 | [`TQSA_SITENAM`](#tqsa_sitenam) | 안전보건_현장직원 | 21 / 20 | 1 |  |  |
| 65 | `TQSA_SUBJECT` | 공지사항 | 17 / 17 |  |  |  |
| 66 | `TQSA_VIEW_HIS` | 열람이력 | 9 / 9 |  |  |  |
| 67 | `TQSA_VIEW_REQ` | 열람신청 | 13 / 13 |  |  |  |
| 68 | `TQSA_VIEW_REQ_LST` | 열람신청목록 | 8 / 8 |  |  |  |
| 69 | [`TQSA_VNDR`](#tqsa_vndr) | 협력업체관리 | 47 / 45 | 2 |  |  |
| 70 | [`TQSA_WEEK_WORK_LOG`](#tqsa_week_work_log) | 현장주간업무보고 | 50 / 52 | 1 | 3 |  |
| 71 | [`TQSA_WEEK_WORK_LOG_HO`](#tqsa_week_work_log_ho) | 본사주간업무보고 | 12 / 13 |  | 1 |  |
| 72 | `TQSA_WEEK_WORK_LOG_PLAN` | 현장주간업무보고 주요위험작업 | 17 / 17 |  |  |  |
| 73 | [`TQSA_WEEK_WORK_LOG_PLAN_HO`](#tqsa_week_work_log_plan_ho) | 본사주간업무보고 주요위험작업 | 15 / 12 | 3 |  |  |
| 74 | `TQSA_YYTRGARSLT` | 년간안전보건목표추진실적 | 17 / 17 |  |  |  |
| 75 | `TQSA_YYTRGARSLTSEQ` | 년간안전보건목표추진실적차수 | 15 / 15 |  |  |  |
| 76 | `TQSA_YYTRGPLN` | 년간안전보건목표추진계획 | 16 / 16 |  |  |  |
| 77 | `TQSA_YYTRGPLNCHR` | 년간안전보건목표추진계획담당자 | 15 / 15 |  |  |  |
| 78 | `TQSA_YYTRGPLNSEQ` | 년간안전보건목표추진계획차수 | 14 / 14 |  |  |  |

## 3. 컬럼 차이 상세 (21개 테이블)

### TQSA_CKLST

본사점검체크리스트구분 · 컬럼 12 / 12 (JH / vplus)

**속성이 다른 컬럼 (1)**

| 컬럼 | 설명 | 다른 항목 | JH | vplus |
|---|---|---|---|---|
| `HO_CHK_DIV_NM` | 본사점검구분명 | 길이 | VARCHAR2(100) | VARCHAR2(50) |

### TQSA_CKLST_ITM

본사점검체크리스트항목 · 컬럼 15 / 13 (JH / vplus)

**JH에만 있는 컬럼 (2)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `HO_CHK_ITM_NM2` | VARCHAR2(500) | 본사점검항목명상세 |
| `MAX_SCORE` | NUMBER(38) | 배점 |

### TQSA_CTPUNT_CHKITM

안전단위작업별 점검항목 · 컬럼 21 / 20 (JH / vplus)

**JH에만 있는 컬럼 (1)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `RISK_CRIT` | VARCHAR2(10) | 위험성레벨(QS063) |

### TQSA_DEEDU_CD

교육세부코드 등록 · 컬럼 13 / 12 (JH / vplus)

**JH에만 있는 컬럼 (1)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `EDU_TIME` | VARCHAR2(100) | 교육시간 |

**속성이 다른 컬럼 (1)**

| 컬럼 | 설명 | 다른 항목 | JH | vplus |
|---|---|---|---|---|
| `DEEDU_NM` | 세부교육코드명 | 길이 | VARCHAR2(2000) | VARCHAR2(500) |

### TQSA_EDU

교육일지 등록 · 컬럼 36 / 39 (JH / vplus)

**JH에만 있는 컬럼 (10)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `EDU_DT` | VARCHAR2(8) | 교육일자 |
| `EDU_TIME` | VARCHAR2(20) | 교육시간 |
| `REL_LNR1` | VARCHAR2(100) | 관련법규1 |
| `REL_LNR2` | VARCHAR2(100) | 관련법규2 |
| `MSDS_RMKS` | VARCHAR2(4000) | MSDS비고 |
| `PHOTO_DT_1` | VARCHAR2(100) | 사진일자1 |
| `PHOTO_DT_2` | VARCHAR2(100) | 사진일자2 |
| `PHOTO_GRP3` | VARCHAR2(50) | 첨부파일그룹사진3 |
| `PHOTO_DESC_3` | VARCHAR2(100) | 사진설명3 |
| `PHOTO_DT_3` | VARCHAR2(100) | 사진일자3 |

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

| 컬럼 | 설명 | 다른 항목 | JH | vplus |
|---|---|---|---|---|
| `EDU_SEQ` | 교육순번 | 길이 | NUMBER(13) NOT NULL | NUMBER(*,0) NOT NULL |
| `EDU_CD` | 교육코드 | NULL | VARCHAR2(10) NOT NULL | VARCHAR2(10) |
| `DEEDU_CD` | 교육세부코드 | NULL | VARCHAR2(10) NOT NULL | VARCHAR2(10) |
| `EDU_OBJ_MAN` | 교육인원_대상남성 | 길이 | NUMBER | NUMBER(*,0) |
| `EDU_IMPL_MAN` | 교육인원_실시남성 | 길이 | NUMBER | NUMBER(*,0) |
| `EDU_MTD` | 교육대상 | 길이 | VARCHAR2(4000) | VARCHAR2(200) |
| `EDU_CTS` | 교육내용 | 길이 | VARCHAR2(4000) | VARCHAR2(1000) |
| `EDU_CTS2` | 공통외 특별교육내용 | 길이 | VARCHAR2(4000) | VARCHAR2(1000) |
| `EDU_CTS3` | 공통외특별교육내용3 | 길이 | VARCHAR2(4000) | VARCHAR2(1000) |

### TQSA_EQMTABK

건설장비관리대장 · 컬럼 30 / 26 (JH / vplus)

**JH에만 있는 컬럼 (4)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `RGL_STR_DD` | VARCHAR2(8) | 정기점검 유효기간 시작일 |
| `RGL_END_DD` | VARCHAR2(8) | 정기점검 유효기간 종료일 |
| `MNG_PNM` | VARCHAR2(50) | 관리책임자 |
| `MNG_CELPH` | VARCHAR2(500) | 관리책임자 핸드폰 |

### TQSA_HOCHKRPT

본사점검보고서 · 컬럼 62 / 31 (JH / vplus)

**JH에만 있는 컬럼 (39)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `CHK_DGR` | NUMBER(3) NOT NULL | 점검차수 |
| `INSP_NM` | VARCHAR2(100) | 점검자성명 |
| `SAFT_MGR` | VARCHAR2(20) | 안전관리자 |
| `SAFT_MGR_NM` | VARCHAR2(100) | 안전관리자성명 |
| `DISS_ACM` | VARCHAR2(100) | 재해누계 |
| `DISS_CY` | VARCHAR2(100) | 재해당해 |
| `SAFT_MCHR` | NUMBER(38) | 계상안전관리비 |
| `SAFT_ACM_AMT` | NUMBER(38) | 누계사용금액 |
| `SAFT_USE_RT` | NUMBER(5,2) | 사용율 |
| `TDAY_WRK` | VARCHAR2(1000) | 금일작업 |
| `SCH_WRK` | VARCHAR2(1000) | 예정작업 |
| `RVLT_SCR1` | NUMBER(13,2) | 전회점수1 |
| `RVLT_SCR2` | NUMBER(13,2) | 전회점수2 |
| `RVLT_SCR3` | NUMBER(13,2) | 전회점수3 |
| `RVLT_SCR4` | NUMBER(13,2) | 전회점수4 |
| `RVLT_SCR5` | NUMBER(13,2) | 전회점수5 |
| `TTM_SCR1` | NUMBER(13,2) | 금회점수1 |
| `TTM_SCR2` | NUMBER(13,2) | 금회점수2 |
| `TTM_SCR3` | NUMBER(13,2) | 금회점수3 |
| `TTM_SCR4` | NUMBER(13,2) | 금회점수4 |
| `TTM_SCR5` | NUMBER(13,2) | 금회점수5 |
| `APRS_GRD1` | VARCHAR2(1) | 평가등급1 |
| `APRS_GRD2` | VARCHAR2(1) | 평가등급2 |
| `APRS_GRD3` | VARCHAR2(1) | 평가등급3 |
| `APRS_GRD4` | VARCHAR2(1) | 평가등급4 |
| `APRS_GRD5` | VARCHAR2(1) | 평가등급5 |
| `RMKS1` | VARCHAR2(1000) | 비고1 |
| `RMKS2` | VARCHAR2(1000) | 비고2 |
| `RMKS3` | VARCHAR2(1000) | 비고3 |
| `RMKS4` | VARCHAR2(1000) | 비고4 |
| `RMKS5` | VARCHAR2(1000) | 비고5 |
| `EXCL_EXMP` | VARCHAR2(1000) | 우수사례 |
| `MNG_MATT` | VARCHAR2(1000) | 관리사항 |
| `PRGS_STATS_CD1` | VARCHAR2(20) | 본사점검상태 |
| `APRV_NO1` | VARCHAR2(20) | 본사점검결재번호 |
| `PRGS_STATS_CD2` | VARCHAR2(20) | 조치결과상태 |
| `APRV_NO2` | VARCHAR2(20) | 조치결과결재번호 |
| `QUARTER` | VARCHAR2(10) | 분기 |
| `CLOSE_YN` | VARCHAR2(1) DEFAULT '0' | 마감여부 |

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

| 컬럼 | 설명 | 다른 항목 | JH | vplus |
|---|---|---|---|---|
| `CNST_AMT` | 공사금액 | 길이 | NUMBER(38) | NUMBER(15) |
| `CNST_SCAL` | 공사규모 | 길이 | VARCHAR2(100) | VARCHAR2(1000) |

### TQSA_HOCHKRPT_CK

본사점검보고서_체크리스트 · 컬럼 18 / 14 (JH / vplus)

**JH에만 있는 컬럼 (5)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `CHK_DGR` | NUMBER(3) NOT NULL | 차수 |
| `APRS_CHK` | VARCHAR2(20) | 평가선택 : |
| `APRS_PNDS` | NUMBER(38) | 평가배점 |
| `APRS_SCR` | NUMBER(38,2) | 평가점수 |
| `APRS_CTS` | VARCHAR2(500) | 평가내용 |

**vplus에만 있는 컬럼 (1)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `HO_CHK_APRS_SCR` | NUMBER(38) | 공통코드 : QSM04 |

### TQSA_HOCHKRPT_ERR

본사점검보고서_지적사항 · 컬럼 31 / 30 (JH / vplus)

**JH에만 있는 컬럼 (3)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `CHK_DGR` | NUMBER(3) NOT NULL | 점검차수 |
| `INSP_NM` | VARCHAR2(50) | 점검자성명 |
| `MA_PSN_NM` | VARCHAR2(50) | 조치자성명 |

**vplus에만 있는 컬럼 (2)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `INSP_PNM` | VARCHAR2(50) | 점검자성명 |
| `MA_PSN_PNM` | VARCHAR2(50) | 조치자성명 |

**속성이 다른 컬럼 (2)**

| 컬럼 | 설명 | 다른 항목 | JH | vplus |
|---|---|---|---|---|
| `CHK_MATT` | 지적사항 | 길이 | VARCHAR2(4000) | VARCHAR2(1000) |
| `MA_MATT` | 조치사항 | 길이 | VARCHAR2(4000) | VARCHAR2(500) |

### TQSA_HOCHKRPT_PHOTO

본사점검보고서_내부점검사진 · 컬럼 12 / 12 (JH / vplus)

**JH에만 있는 컬럼 (2)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `CHK_DGR` | NUMBER(3) NOT NULL | 점검일자 |
| `ATFL_GRP2` | VARCHAR2(50) | 첨부파일2 |

**vplus에만 있는 컬럼 (2)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `CHK_DT` | VARCHAR2(8) NOT NULL | 점검일자 |
| `PHOTO_SEQ` | NUMBER(38) NOT NULL | 사진순번 |

### TQSA_HODCAB

본사문서접수함 · 컬럼 16 / 15 (JH / vplus)

**JH에만 있는 컬럼 (1)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `ATFL_GRP` | VARCHAR2(50) | 첨부파일 |

### TQSA_IDAC

산업재해 · 컬럼 97 / 65 (JH / vplus)

**JH에만 있는 컬럼 (33)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `DSVC_MP` | VARCHAR2(4000) | 재해자_휴대폰 |
| `PHOTO_GRP3` | VARCHAR2(50) | 첨부파일그룹사진3 |
| `PHOTO_DESC_3` | VARCHAR2(100) | 사진설명3 |
| `PHOTO_GRP4` | VARCHAR2(50) | 첨부파일그룹사진4 |
| `PHOTO_DESC_4` | VARCHAR2(100) | 사진설명4 |
| `BZ_HQ` | VARCHAR2(20) | 사업본부 |
| `SITE_TEL_NO` | VARCHAR2(20) | 현장전화번호 |
| `EMP_CNT` | NUMBER(13) | 근로자수 |
| `PROCRT` | NUMBER(5,2) | 공정율 |
| `TOT_CNST_AMT` | NUMBER(13) | 총공사금액 |
| `WTS_NM1` | VARCHAR2(50) | 목격자1 |
| `WTS_NM2` | VARCHAR2(50) | 목격자2 |
| `WTS_NM3` | VARCHAR2(50) | 목격자3 |
| `SAFT_EDU_CMPL_DT` | VARCHAR2(8) | 안전교육 이수일자 |
| `OCC_DIS_CNT` | NUMBER(13) | 직업병수 |
| `IDRT_TECH` | VARCHAR2(200) | 간접적원인_기술 |
| `IDRT_EDU` | VARCHAR2(200) | 간접적원인_교육 |
| `IDRT_WRK` | VARCHAR2(200) | 간접적원인_작업관리 |
| `DRT_UNSF_STATS` | VARCHAR2(200) | 직접적원인_불안전상태(물적) |
| `DRT_UNSF_ACT` | VARCHAR2(200) | 직접적원인_불안전행동(인적) |
| `DFT_DOC` | VARCHAR2(100) | 기인물 |
| `RPT_DT` | VARCHAR2(8) | 보고일자 |
| `ACP_DT` | VARCHAR2(8) | 접수일자 |
| `MED_ORG` | VARCHAR2(100) | 의료기관명 |
| `MED_CADDR` | VARCHAR2(20) | 의료기관 연락처 |
| `ETC_MATT` | VARCHAR2(500) | 기타사항 |
| `APRV_NO` | VARCHAR2(20) | 현장 결재번호 |
| `APRV_NO_GW` | VARCHAR2(80) | 본사 결재번호 |
| `DISS_TYPE` | VARCHAR2(20) | 사고형태 (QS070) |
| `DSVC_AGE` | NUMBER(3) | 재해자_나이 |
| `DISS_DIV_ETC` | VARCHAR2(100) | 재해구분 기타내용 |
| `DIS_DESC` | VARCHAR2(500) | 재해발생형태 내용 |
| `ATFL_GRP2` | VARCHAR2(50) | 첨부파일(재해방지) |

**vplus에만 있는 컬럼 (1)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `DSVC_BRTH` | VARCHAR2(500) | 개인정보 암호화 |

**속성이 다른 컬럼 (4)**

| 컬럼 | 설명 | 다른 항목 | JH | vplus |
|---|---|---|---|---|
| `DSVC` | 개인정보 암호화 | 길이 | VARCHAR2(100) | VARCHAR2(500) |
| `DSVC_VNDR` | 개인정보 암호화 | 길이 | VARCHAR2(100) | VARCHAR2(4000) |
| `DSVC_HIRDT` | 개인정보 암호화 | 길이 | VARCHAR2(8) | VARCHAR2(500) |
| `DSVC_RSDNNO` | 재해자_주민번호(개인정보 암호화) | 길이 | VARCHAR2(4000) | VARCHAR2(500) |

### TQSA_LABOR_LIST

근로자인명부 · 컬럼 32 / 29 (JH / vplus)

**JH에만 있는 컬럼 (3)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `ATFL_GRP` | VARCHAR2(50) | 첨부파일 |
| `ELDR` | VARCHAR2(500) | 고령자 |
| `HLTH_ABN` | VARCHAR2(500) | 건강이상자 |

### TQSA_RISKPLAN_D

위험성평가 세부계획 · 컬럼 23 / 22 (JH / vplus)

**JH에만 있는 컬럼 (1)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `RISK_CRIT` | VARCHAR2(10) | 위험성레벨 |

### TQSA_RISK_CHK

위험성평가 차수점검내용 · 컬럼 59 / 31 (JH / vplus)

**JH에만 있는 컬럼 (28)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `RISK_CRIT` | VARCHAR2(10) | 위험성레벨(QS063) |
| `RISK_FREQ2` | VARCHAR2(10) | 빈도레벨(QS003) |
| `RISK_APRV2` | VARCHAR2(10) | 강도레벨(QS004) |
| `RISK_CRIT2` | VARCHAR2(10) | 위험성레벨(QS063) |
| `RISK_GRD2` | VARCHAR2(10) | 위험등급(QS024) |
| `MNG_SUPR` | VARCHAR2(10) | 관리감독자 |
| `RISK_FREQ3` | VARCHAR2(10) | 빈도레벨(QS003) |
| `RISK_APRV3` | VARCHAR2(10) | 강도레벨(QS004) |
| `RISK_CRIT3` | VARCHAR2(10) | 위험성레벨(QS063) |
| `RISK_GRD3` | VARCHAR2(10) | 위험등급(QS024) |
| `SAFT_MGR` | VARCHAR2(10) | 안전관리자 |
| `RISK_FREQ4` | VARCHAR2(10) | 빈도레벨(QS003) |
| `RISK_APRV4` | VARCHAR2(10) | 강도레벨(QS004) |
| `RISK_CRIT4` | VARCHAR2(10) | 위험성레벨(QS063) |
| `RISK_GRD4` | VARCHAR2(10) | 위험등급(QS024) |
| `SITE_OMGR` | VARCHAR2(10) | 현장소장 |
| `SITE_OPIN` | VARCHAR2(500) | 현장소장의견 |
| `RISK_FREQ5` | VARCHAR2(10) | 빈도레벨(QS003) |
| `RISK_APRV5` | VARCHAR2(10) | 강도레벨(QS004) |
| `RISK_CRIT5` | VARCHAR2(10) | 위험성레벨(QS063) |
| `RISK_GRD5` | VARCHAR2(10) | 위험등급(QS024) |
| `RISK_FREQ6` | VARCHAR2(10) | 빈도레벨(QS003) |
| `RISK_APRV6` | VARCHAR2(10) | 강도레벨(QS004) |
| `RISK_CRIT6` | VARCHAR2(10) | 위험성레벨(QS063) |
| `RISK_GRD6` | VARCHAR2(10) | 위험등급(QS024) |
| `ITM_ADD_YN` | VARCHAR2(1) DEFAULT '0' | 기존 : 0, 추가 : 1 |
| `VNDR_WRK_NM` | VARCHAR2(100) | 근로자대표명 |
| `VNDR_WRK_OPIN` | VARCHAR2(500) | 근로자대표의견 |

**속성이 다른 컬럼 (1)**

| 컬럼 | 설명 | 다른 항목 | JH | vplus |
|---|---|---|---|---|
| `VNDR_SEQ` | 업체순번 | 길이 | NUMBER(13) NOT NULL | NUMBER(3) NOT NULL |

### TQSA_RISK_VNDR

위험성평가 대상업체 · 컬럼 27 / 27 (JH / vplus)

**JH에만 있는 컬럼 (1)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `VNDR_WRK_NM` | VARCHAR2(100) | 근로자대표명 |

**vplus에만 있는 컬럼 (1)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `SITE_OPIN` | VARCHAR2(500) | 현장소장의견 |

### TQSA_SITENAM

안전보건_현장직원 · 컬럼 21 / 20 (JH / vplus)

**JH에만 있는 컬럼 (1)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `JB_CD` | VARCHAR2(20) | 직무코드 |

### TQSA_VNDR

협력업체관리 · 컬럼 47 / 45 (JH / vplus)

**JH에만 있는 컬럼 (2)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `CTP_CD` | VARCHAR2(10) | 공종코드 |
| `CTP_NM` | VARCHAR2(100) | 공종명 |

### TQSA_WEEK_WORK_LOG

현장주간업무보고 · 컬럼 50 / 52 (JH / vplus)

**JH에만 있는 컬럼 (1)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `ETC_INST_MATT` | VARCHAR2(1000) | 설치및해체근황 기타 |

**vplus에만 있는 컬럼 (3)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `ETC_INST_YN` | VARCHAR2(1) | 기타설치여부 |
| `ETC_INST_CNT` | NUMBER(13) | 기타설치개수 |
| `ETC_DMT_CNT` | NUMBER(13) | 기타해체개수 |

### TQSA_WEEK_WORK_LOG_HO

본사주간업무보고 · 컬럼 12 / 13 (JH / vplus)

**vplus에만 있는 컬럼 (1)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `APRV_NO_GW` | VARCHAR2(20) | 결재번호GW |

### TQSA_WEEK_WORK_LOG_PLAN_HO

본사주간업무보고 주요위험작업 · 컬럼 15 / 12 (JH / vplus)

**JH에만 있는 컬럼 (3)**

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `RMKS` | VARCHAR2(1000) | 비고 |
| `TOT_PROCRT` | NUMBER(5,2) | 공정률 |
| `IMPTC_YN` | VARCHAR2(1) | 중요여부 |
