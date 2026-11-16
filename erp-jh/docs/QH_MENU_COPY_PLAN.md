# JH → vplus 메뉴 복사 계획 (QS 메뉴 → QH 메뉴)

> 작성일: 2026-11-16 · 원본: `JH202610.TCOZ_MNU_INFO` · 대상: `VPLUS202611A.TCOZ_MNU_INFO`
> 관련: [QH_SOURCE_COPY_PLAN.md](QH_SOURCE_COPY_PLAN.md)(QH 소스 복사), [db_info.md](db_info.md)(접속 정보)
> 실행 스크립트: [QH_MENU_COPY.sql](QH_MENU_COPY.sql)
> 이 문서의 수치는 두 DB를 조회만 해서 확인한 값이다.
> **실행 완료(2026-11-16): 8장 기본안대로 135건을 INSERT하고 COMMIT했다. 결과는 10장에 있다.**

## 1. 목적

JH의 QS 메뉴 트리를 vplus의 QH 메뉴(`QH`, 메뉴명 `(신)안전`) 아래에 복사한다.
이미 이식한 QH 소스(`/qha`, `/qhb`, `/qh/aprv`)에 메뉴로 들어갈 수 있게 하는 작업이다.

## 2. 범위

| 테이블 | 이번 작업 | 비고 |
|---|---|---|
| `TCOZ_MNU_INFO` | **INSERT 135건** | 이번 작업의 유일한 DML |
| `TCOZ_MNU_INFO_DTL` | 하지 않음 | 화면을 쓰면 자동 등록됨(6장) |
| `TCOU_AUTH_OBJ`, `TCOU_AUTH_APRC` | 하지 않음 | 권한관리 화면에서 직접 부여(6장) |
| `TCOZ_MNU_HELP`, `TCOZ_MYMNU_INFO` | 하지 않음 | JH QS 도움말 0건, 즐겨찾기는 사용자별 데이터 |

- vplus의 기존 행은 바꾸지 않는다. `QH` root 1건은 이미 있으므로 그대로 쓴다.
- vplus의 기존 QS 메뉴 243건은 건드리지 않는다.
- JH는 읽기만 한다.

## 3. 현재 상태

| 항목 | JH `QS` | vplus `QS` | vplus `QH` |
|---|---:|---:|---:|
| `TCOZ_MNU_INFO` | 136 (root 포함) | 243 | 1 (root만) |

- 두 DB의 `TCOZ_MNU_INFO` 구조는 같다(24개 컬럼, PK `MNU_CD` VARCHAR2(20)).
- JH QS 코드는 최대 8자리라 길이 문제가 없다.
- JH QS 트리에서 상위가 없는 행은 없다(135건 모두 `QS`에서 이어진다).
- vplus 계정에서 `JH202610` 테이블을 SELECT할 권한이 없다(ORA-00942). 그래서 `INSERT ... SELECT` 대신 JH 데이터로 만든 INSERT 문 135개를 쓴다.

메뉴 종류별 건수:

| MNU_KND | 의미 | 건수 |
|---|---|---:|
| SYS0101 | 그룹 | 9 |
| SYS0102 | 메뉴 | 63 |
| SYS0103 | 숨김 | 3 |
| SYS0106 | 상속(하위 화면, 상위 메뉴 권한을 따름) | 60 |

`USE_YN = '0'` 9건(QHI40, QHD69, QHD70, QHD80, QHD98, QHE30, QHH80, QHH30, QHH50)은 JH 값 그대로 미사용으로 넣는다.

## 4. 변환 규칙

| 컬럼 | 규칙 | 예 |
|---|---|---|
| `MNU_CD` | 앞 2자리 `QS` → `QH` | `QSA4010` → `QHA4010` |
| `HRNK_CD` | 앞 2자리 `QS` → `QH` | `QS` → `QH`, `QSA40` → `QHA40` |
| `URL` | `/qsa/` → `/qha/`, `/qsb/` → `/qhb/`, `/qs/aprv/` → `/qh/aprv/` | `/qsa/drmLst` → `/qha/drmLst` |
| `FILE_PATH` | `/qs/qsa/` → `/qh/qha/`, `/qs/qsb/` → `/qh/qhb/`, `/qs/aprv/` → `/qh/aprv/` | `/qs/qsa/drmLst` → `/qh/qha/drmLst` |
| `IPT_ID` | `'MIG_JH_QS'` (되돌리기 식별용) | |
| `IPT_DTM` | `SYSDATE` | |
| `IPT_IP`, `UPD_*` | `NULL` | |
| 나머지 | JH 값 그대로 (`MNU_NM`, `MNU_SO`, `MNU_KND`, `USE_YN`, `SYS_YN`, `AUTH_YN`, `PRIV_YN`, `FAFF_YN`, `RMKS`, `CRT_DTM`, `CRT_USR` 등) | |

- 코드는 `REPLACE`가 아니라 앞 2자리만 바꾼다(`'QH' || SUBSTR(x, 3)`). 중간에 나오는 `QS`는 바꾸지 않는다.
- JH의 `QS` root 행은 넣지 않는다. JH에서 `HRNK_CD = 'QS'`인 2단계 그룹 9개(QSA~QSI)가 변환 후 vplus의 `QH` root를 가리킨다.
- 메뉴명은 JH 그대로 쓴다. root만 vplus의 `(신)안전`이다.

## 5. 사전 검증 결과

변환한 값을 vplus 소스와 DB에 대조했다.

| 항목 | 결과 |
|---|---|
| URL이 있는 메뉴 | 126건 |
| QH 컨트롤러에 매핑이 있는 URL | 125건 |
| `FILE_PATH`의 JSP가 있는 메뉴 | 125건 |
| vplus 기존 메뉴와 URL 중복 | 0건 |
| 변환 후 URL끼리 중복 | 0건 |
| vplus에 이미 있는 `QH_%` 코드 | 0건 (PK 충돌 없음) |

URL이 중복되면 화면 진입이 실패한다. `PCOU_MNU_AUTH_Q`가 `WHERE URL = p_REQ_URL`로 메뉴를 한 건만 읽기 때문이다.

**예외 1건: `QHA4010` 조치사항결재 (상속, 상위 `QHA40` 현장결재함)**
- 변환한 URL `/qh/aprv/siteMa_R01`의 컨트롤러 매핑과 JSP가 없다.
- JH에서도 같은 상태다. `siteMa_R01`은 화면이 아니라 OZ 리포트 이름(`qs.lib.js`의 `RPTNAME`)이다. JH에서도 이 메뉴로는 화면이 열리지 않는다.
- 기본안: JH와 똑같이 넣는다. 상속 메뉴라 트리에 보이지 않고, 다른 화면에 영향이 없다.

## 6. 복사 후 할 일 (이번 작업 범위 밖)

메뉴만 넣으면 메뉴 트리에는 보이지만, 권한이 없어서 화면은 열리지 않는다.

1. **권한 부여 (직접 해야 함)**
   - `/auth/authMnu` 화면에서 그룹별로 QH 메뉴를 준다(`TCOU_AUTH_OBJ`). 이 데이터가 없으면 "해당화면에 권한이 존재하지 않습니다"가 뜬다.
   - 권한등급(`TCOU_AUTH_APRC`)에서 수정 권한을 준다. 없으면 조회만 되고 저장이 막힌다.
   - 상속(SYS0106) 메뉴는 상위 메뉴 권한을 따르므로 따로 줄 필요가 없다.
   - JH의 권한 데이터는 복사하지 않는다. 같은 그룹코드인데 그룹명이 다른 경우가 있다(예: `11291`, `CS001`, `CS003`).
2. **DTL (자동으로 쌓임)**
   - 화면에서 조회·저장을 호출하면 `PCOU_MNU_AUTH_CHECK`가 `TCOZ_MNU_INFO_DTL`에 URL을 자동으로 등록한다(`registration`).
   - KND는 URL에 `/get`이 있으면 `Q`, `/set`이 있으면 `S`, 둘 다 없으면 `NULL`이다.
   - 끝나면 `/auth/mnuMethodAuth` 화면에서 KND가 `NULL`인 건과, `permit`이 필요한 공통 URL을 보정한다.
3. **확인**
   - 메뉴 트리에 `(신)안전` 아래 9개 그룹이 JH와 같은 순서로 나오는지 본다.
   - 메뉴 2~3개를 열어 화면과 조회를 확인한다.

## 7. 실행 절차

[QH_MENU_COPY.sql](QH_MENU_COPY.sql)을 VPLUS202611A 계정으로 실행한다. 스크립트는 COMMIT하지 않는다.

1. **[1] 사전 확인**: 결과가 각각 `1`(QH root), `0`(QH 하위), `0`(QH URL)이어야 진행한다.
2. **[2] 백업**: 필요하면 `TCOZ_MNU_INFO` 전체를 백업한다(스크립트에는 주석 처리됨).
3. **[3] INSERT** 135건: 상위 메뉴부터 하위 순서로 들어가 있다.
4. **[4] 사후 검증**

   | 검증 | 기대값 |
   |---|---|
   | 4-1 `IPT_ID = 'MIG_JH_QS'` 건수 | 135 |
   | 4-2 상위가 없는 QH 메뉴 | 0 |
   | 4-3 `QH`부터 트리 조회 | 136 (root 포함) |
   | 4-4 전체 메뉴 URL 중복 | 0건 |
   | 4-5 QH 메뉴에 남은 `/qs` 경로 | 0 |

5. 모두 맞으면 `COMMIT`한다.
6. 서버는 재기동하지 않아도 될 것으로 본다. 메뉴·권한을 메모리나 세션에 캐시하는 코드는 찾지 못했다. 메뉴가 안 보이면 다시 로그인해서 확인한다.

**되돌리기**

```sql
DELETE FROM TCOZ_MNU_INFO WHERE MNU_CD LIKE 'QH_%' AND IPT_ID = 'MIG_JH_QS';
COMMIT;
```

`QH` root는 `IPT_ID`가 `dev_hs`라서 지워지지 않는다. 권한을 이미 줬다면 메뉴관리 화면에서 지워야 권한도 함께 지워진다(`PCOZ_MNU_INFO_S`의 삭제 로직).

## 8. 결정할 사항

| # | 항목 | 기본안 |
|---|---|---|
| 1 | `QHA4010`(URL에 화면 없음) 포함 여부 | JH와 같게 포함 |
| 2 | 메뉴명 | JH 그대로 (`(신)` 등 접두어 없음) |
| 3 | `IPT_ID` 값 | `MIG_JH_QS` |
| 4 | `USE_YN = '0'` 9건 | JH 그대로 미사용으로 넣음 |

## 9. 복사 대상 목록 (135건)

들여쓰기(`└`)는 트리 깊이다. URL은 변환 후 값이다.

| # | JH 코드 | vplus 코드 | 메뉴명 | 종류 | 사용 | URL |
|---:|---|---|---|---|---|---|
| 1 | QSA | QHA | 자료/문서관리 | 그룹 | Y |  |
| 2 | QSA40 | QHA40 | └ 현장결재함 | 메뉴 | Y | `/qha/apprMng2` |
| 3 | QSA4010 | QHA4010 | └ └ 조치사항결재 | 상속 | Y | `/qh/aprv/siteMa_R01` |
| 4 | QSA50 | QHA50 | └ 공지사항 | 메뉴 | Y | `/qha/anncBrdLst` |
| 5 | QSA5010 | QHA5010 | └ └ 공지사항 상세 | 상속 | Y | `/qha/anncBrdDtl` |
| 6 | QSA5020 | QHA5020 | └ └ 공지사항 입력 | 상속 | Y | `/qha/anncBrdReg` |
| 7 | QSA80 | QHA80 | └ 문자발송 | 메뉴 | Y | `/qha/qsSendSms` |
| 8 | QSA60 | QHA60 | └ 자료실 | 메뉴 | Y | `/qha/drmLst` |
| 9 | QSA6010 | QHA6010 | └ └ 자료등록 | 상속 | Y | `/qha/drmReg` |
| 10 | QSA6020 | QHA6020 | └ └ 버전이력 | 상속 | Y | `/qha/drmHis` |
| 11 | QSA70 | QHA70 | └ 자료열람승인 | 메뉴 | Y | `/qha/drmViewAplAprv` |
| 12 | QSA90 | QHA90 | └ 문서접수/등록(본사) | 메뉴 | Y | `/qha/hodCab` |
| 13 | QSA95 | QHA95 | └ 문서접수/등록(현장) | 메뉴 | Y | `/qha/siteCab` |
| 14 | QSB | QHB | 안전보건목표 | 그룹 | Y |  |
| 15 | QSB10 | QHB10 | └ 안전보건목표 | 메뉴 | Y | `/qha/yyTrgPlan` |
| 16 | QSB1010 | QHB1010 | └ └ 계획차수 | 상속 | Y | `/qha/yyTrgPlanSeq` |
| 17 | QSB1020 | QHB1020 | └ └ 검토자지정 | 상속 | Y | `/qha/yyTrgPlanStf` |
| 18 | QSB1030 | QHB1030 | └ └ 안전보건목표 결재문서 | 상속 | Y | `/qh/aprv/yyTrgPlanAprv` |
| 19 | QSB20 | QHB20 | └ 안전보건실적 | 메뉴 | Y | `/qha/yyTrgArslt` |
| 20 | QSB2010 | QHB2010 | └ └ 실적차수 | 상속 | Y | `/qha/yyTrgArsltSeq` |
| 21 | QSB2020 | QHB2020 | └ └ 그리드 첨부파일 팝업 | 상속 | Y | `/qha/yyTrgArslt_P01` |
| 22 | QSB2030 | QHB2030 | └ └ 안전보건실적 결재문서 | 상속 | Y | `/qh/aprv/yyTrgArsltAprv` |
| 23 | QSC | QHC | 안전보건계획 | 그룹 | Y |  |
| 24 | QSC10 | QHC10 | └ 안전보건활동계획 | 메뉴 | Y | `/qha/mmEduPlan` |
| 25 | QSC20 | QHC20 | └ 안전보건활동현황 | 메뉴 | Y | `/qha/mmEduPlanCurst` |
| 26 | QSC80 | QHC80 | └ 주간업무보고(본사) | 메뉴 | Y | `/qha/weekWorkLogHo` |
| 27 | QSC8010 | QHC8010 | └ └ 주간업무보고등록 | 상속 | Y | `/qha/weekWorkLogRegHo` |
| 28 | QSC8020 | QHC8020 | └ └ 주간업무보고출력 | 상속 | Y | `/qha/weekWorkLogHoRpt` |
| 29 | QSC70 | QHC70 | └ 주간업무보고(현장) | 메뉴 | Y | `/qha/weekWorkLog` |
| 30 | QSC7010 | QHC7010 | └ └ 주간업무보고등록 | 상속 | Y | `/qha/weekWorkLogReg` |
| 31 | QSC7020 | QHC7020 | └ └ 주간업무보고결재 | 상속 | Y | `/qh/aprv/weekWorkLogSiteAprv` |
| 32 | QSC91 | QHC91 | └ 노사협의체 | 메뉴 | Y | `/qha/laborMngCncl` |
| 33 | QSC94 | QHC94 | └ 안전보건관리규정 | 메뉴 | Y | `/qha/saftRgln` |
| 34 | QSI | QHI | 위험성평가 | 그룹 | Y |  |
| 35 | QSI10 | QHI10 | └ 최초/정기위험성평가 | 메뉴 | Y | `/qha/riskPlanLst` |
| 36 | QSI1010 | QHI1010 | └ └ 위험성평가 계획작성 | 상속 | Y | `/qha/riskPlanReg` |
| 37 | QSI1020 | QHI1020 | └ └ 위험성평가서 출력 | 상속 | Y | `/qha/riskPlanRpt` |
| 38 | QSI1030 | QHI1030 | └ └ 위험성평가 결재문서 | 상속 | Y | `/qh/aprv/riskPlanAprv` |
| 39 | QSI20 | QHI20 | └ 수시위험성평가 | 메뉴 | Y | `/qhb/riskDgrMainList` |
| 40 | QSI2010 | QHI2010 | └ └ 회의록 추가 | 상속 | Y | `/qhb/riskDgrMng` |
| 41 | QSI2020 | QHI2020 | └ └ 위험성평가표작성 | 상속 | Y | `/qhb/riskLst` |
| 42 | QSI2030 | QHI2030 | └ └ 위험성평가표점수등록 | 상속 | Y | `/qhb/riskChk` |
| 43 | QSI2040 | QHI2040 | └ └ 위험성평가 첨부파일 | 상속 | Y | `/qhb/riskDgr_P01` |
| 44 | QSI2050 | QHI2050 | └ └ 출력 | 상속 | Y | `/qhb/riskRptPrint` |
| 45 | QSI30 | QHI30 | └ 위험성평가회의 | 메뉴 | Y | `/qha/meetDrftLst` |
| 46 | QSI3010 | QHI3010 | └ └ 협의체 회의작성 | 상속 | Y | `/qha/meetDrft` |
| 47 | QSI3020 | QHI3020 | └ └ 회의록 결재문서 | 상속 | Y | `/qh/aprv/assLogAprv` |
| 48 | QSI303 | QHI303 | └ └ 회의록 개요 | 상속 | Y | `/qha/meetInfo` |
| 49 | QSI40 | QHI40 | └ 위험성평가현황 | 메뉴 | N | `/qha/siterskEvlCurst` |
| 50 | QSI50 | QHI50 | └ 안전책임자 지정 | 메뉴 | Y | `/qhb/saftMngAssign` |
| 51 | QSI60 | QHI60 | └ 중점점검활동 | 메뉴 | Y | `/qha/daySaftChkReg` |
| 52 | QSI70 | QHI70 | └ 일상점검활동 | 메뉴 | Y | `/qha/daySaftChkReg2` |
| 53 | QSI80 | QHI80 | └ 추가위험발굴 | 메뉴 | Y | `/qha/addRiskLst` |
| 54 | QSI8010 | QHI8010 | └ └ 추가위험발굴작성 | 상속 | Y | `/qha/addRiskReg` |
| 55 | QSI90 | QHI90 | └ 부적합보고서 | 메뉴 | Y | `/qha/riskNcrLst` |
| 56 | QSI9010 | QHI9010 | └ └ 부적합보고서작성 | 상속 | Y | `/qha/riskNcrReg` |
| 57 | QSI100 | QHI100 | └ 소리함/작업중지권 | 메뉴 | Y | `/qhb/stopWk` |
| 58 | QSI10010 | QHI10010 | └ └ 조치전 첨부사진 | 상속 | Y | `/qhb/stopWk_P01` |
| 59 | QSI10020 | QHI10020 | └ └ 조치후 첨부사진 | 상속 | Y | `/qhb/stopWk_P02` |
| 60 | QSI10030 | QHI10030 | └ └ 첨부파일 | 상속 | Y | `/qhb/stopWk_P03` |
| 61 | QSD | QHD | 안전보건활동 | 그룹 | Y |  |
| 62 | QSD60 | QHD60 | └ 안전보건교육 | 메뉴 | Y | `/qha/eduLst` |
| 63 | QSD6010 | QHD6010 | └ └ 교육일지등록 | 상속 | Y | `/qha/eduReg` |
| 64 | QSD6020 | QHD6020 | └ └ 교육일지 결재문서 | 상속 | Y | `/qh/aprv/eduRegAprv` |
| 65 | QSD65 | QHD65 | └ 안전보건점검교육일지 | 메뉴 | Y | `/qha/eduDryList` |
| 66 | QSD95 | QHD95 | └ 근로자누적관리현황 | 메뉴 | Y | `/qha/rollMngChkLst` |
| 67 | QSD68 | QHD68 | └ 건강관리프로그램 | 메뉴 | Y | `/qha/saftPgmList` |
| 68 | QSD97 | QHD97 | └ 건강진단 | 메뉴 | Y | `/qha/hlthChkup` |
| 69 | QSD9710 | QHD9710 | └ └ 건강진단목록 | 상속 | Y | `/qha/hlthChkupList` |
| 70 | QSD9720 | QHD9720 | └ └ 건강진단현황표출력 | 상속 | Y | `/qha/hlthChkupRpt` |
| 71 | QSD67 | QHD67 | └ 비상대피훈련 | 메뉴 | Y | `/qha/emgTrnList` |
| 72 | QSD69 | QHD69 | └ 노사합동점검관리 | 메뉴 | N | `/qha/lavorMngChkLst` |
| 73 | QSD6910 | QHD6910 | └ └ 노사합동점검등록 | 상속 | Y | `/qha/lavorMngChkReg` |
| 74 | QSD6920 | QHD6920 | └ └ 노사합동점검 결재문서 | 상속 | Y | `/qh/aprv/lavorMngChkAprv` |
| 75 | QSD70 | QHD70 | └ 안전작업알림요청 | 메뉴 | N | `/qha/safeWorkReqLst3` |
| 76 | QSD7010 | QHD7010 | └ └ 안전작업허가요청상세 | 상속 | Y | `/qha/safeWorkReqReg3` |
| 77 | QSD80 | QHD80 | └ 안전작업알림승인 | 메뉴 | N | `/qha/safeWorkReqLst2` |
| 78 | QSD8010 | QHD8010 | └ └ 안전작업허가요청승인상세 | 상속 | Y | `/qha/safeWorkReqReg2` |
| 79 | QSD8020 | QHD8020 | └ └ 안전작업허가요청승인출력 | 상속 | Y | `/qha/safeWorkRegAppr` |
| 80 | QSD35 | QHD35 | └ 순회점검일지 | 메뉴 | Y | `/qha/arndChkDryList` |
| 81 | QSD98 | QHD98 | └ 협의체회의관리 | 메뉴 | N | `/qha/lavorMngConvLst` |
| 82 | QSD9810 | QHD9810 | └ └ 협의체회의 | 상속 | Y | `/qha/lavorMngConvReg` |
| 83 | QSD9820 | QHD9820 | └ └ 노사협의체 결재문서 | 상속 | Y | `/qh/aprv/lavorMngConvAprv` |
| 84 | QSE | QHE | 재해예방관리 | 그룹 | Y |  |
| 85 | QSE20 | QHE20 | └ 재해보고(본사) | 메뉴 | Y | `/qha/industAcciLst` |
| 86 | QSE2010 | QHE2010 | └ └ 산재등록(본사) | 상속 | Y | `/qha/industAcciReg` |
| 87 | QSE2020 | QHE2020 | └ └ 평가항목 | 상속 | Y | `/qha/aprsCts` |
| 88 | QSE10 | QHE10 | └ 재해보고(현장) | 메뉴 | Y | `/qha/industAcciSiteLst` |
| 89 | QSE1010 | QHE1010 | └ └ 산재등록(현장) | 상속 | Y | `/qha/industAcciSiteReg` |
| 90 | QSE1020 | QHE1020 | └ └ 산재등록(현장) 결재문서 | 상속 | Y | `/qh/aprv/industAcciSiteRegAprv` |
| 91 | QSE1030 | QHE1030 | └ └ 재해자 등록 | 상속 | Y | `/qha/industAcciSiteDsvc` |
| 92 | QSE60 | QHE60 | └ 안전작업계획서 | 메뉴 | Y | `/qha/wrkPdoc` |
| 93 | QSE70 | QHE70 | └ 안전작업허가서 | 메뉴 | Y | `/qha/wrkPmpp` |
| 94 | QSE40 | QHE40 | └ 건설기계관리 | 메뉴 | Y | `/qha/eqmTabk` |
| 95 | QSE4010 | QHE4010 | └ └ 관리대장 첨부사진 | 상속 | Y | `/qha/eqmTabk_P02` |
| 96 | QSE30 | QHE30 | └ MSDS관리대장 | 메뉴 | N | `/qha/msdsMng` |
| 97 | QSE3010 | QHE3010 | └ └ MSDS첨부파일 | 상속 | Y | `/qha/msdsMng_P01` |
| 98 | QSF | QHF | 산업안전보건관리비 | 그룹 | Y |  |
| 99 | QSF10 | QHF10 | └ 산업안전보건관리비 | 메뉴 | Y | `/qha/safeCostMng` |
| 100 | QSF20 | QHF20 | └ 협력업체 계약금액 | 메뉴 | Y | `/qha/safeCostCont` |
| 101 | QSF30 | QHF30 | └ 월별실적관리 | 메뉴 | Y | `/qha/safeCostReg` |
| 102 | QSF3010 | QHF3010 | └ └ 월별실적관리 결재 | 상속 | Y | `/qh/aprv/safeCostRegAprv` |
| 103 | QSF40 | QHF40 | └ 협력업체 현황 | 메뉴 | Y | `/qha/safeCostLst` |
| 104 | QSF50 | QHF50 | └ 당사 월별 실적 입력 | 숨김 | Y | `/qha/safeCostReg1` |
| 105 | QSF60 | QHF60 | └ 협력업체 월별 실적 조회 | 숨김 | Y | `/qha/safeCostReg2` |
| 106 | QSF70 | QHF70 | └ 정산결과 분석 | 메뉴 | Y | `/qha/safeAnalysisList` |
| 107 | QSG | QHG | 평가및개선 | 그룹 | Y |  |
| 108 | QSG20 | QHG20 | └ 본사분기점검 | 메뉴 | Y | `/qha/hoChk4Curst` |
| 109 | QSG2010 | QHG2010 | └ └ 점검보고서 | 상속 | Y | `/qha/hoChk4` |
| 110 | QSG2070 | QHG2070 | └ └ 본사점검 결재문서 | 상속 | Y | `/qh/aprv/hoChk4Aprv` |
| 111 | QSG2080 | QHG2080 | └ └ 지적사항 첨부사진 | 상속 | Y | `/qha/hoChk4Err_P01` |
| 112 | QSG30 | QHG30 | └ 소규모분기점검 | 메뉴 | Y | `/qha/hoChk4Curst2` |
| 113 | QSG40 | QHG40 | └ 조치결과 등록 | 메뉴 | Y | `/qha/siteMaCurst` |
| 114 | QSG4010 | QHG4010 | └ └ 본사점검 조치결과 | 상속 | Y | `/qha/siteMa` |
| 115 | QSG4020 | QHG4020 | └ └ 조치결과 결재문서 | 상속 | Y | `/qh/aprv/siteMaAprv` |
| 116 | QSG4030 | QHG4030 | └ └ 조치후 첨부사진 | 상속 | Y | `/qha/siteMa_P01` |
| 117 | QSG4040 | QHG4040 | └ └ 조치보고서 첨부파일 | 상속 | Y | `/qha/siteMa_P02` |
| 118 | QSG4050 | QHG4050 | └ └ 조치전 첨부사진 | 상속 | Y | `/qha/siteMa_P03` |
| 119 | QSG50 | QHG50 | └ 조치결과 마감 | 메뉴 | Y | `/qha/siteMaClose` |
| 120 | QSH | QHH | 표준정보 | 그룹 | Y |  |
| 121 | QSH70 | QHH70 | └ 현장기준정보(본사) | 메뉴 | Y | `/qha/siteCurst` |
| 122 | QSH7010 | QHH7010 | └ └ 현장기준정보상세 | 상속 | Y | `/qha/qszSiteMngCp` |
| 123 | QSH7020 | QHH7020 | └ └ 서명등록 | 숨김 | Y | `/qha/qszSiteMngCp_P01` |
| 124 | QSH75 | QHH75 | └ 현장기준정보(현장) | 메뉴 | Y | `/qha/qszSiteMngCp2` |
| 125 | QSH80 | QHH80 | └ 현장담당자등록 | 메뉴 | N | `/qha/riskPlanChr` |
| 126 | QSH90 | QHH90 | └ 협력업체관리 | 메뉴 | Y | `/qha/coInfo` |
| 127 | QSH9010 | QHH9010 | └ └ 적격성평가 결과 | 상속 | Y | `/qha/safeAprsLst` |
| 128 | QSH10 | QHH10 | └ 공종관리 | 메뉴 | Y | `/qha/riskWkMng` |
| 129 | QSH20 | QHH20 | └ 위험요인관리 | 메뉴 | Y | `/qha/riskItmMng` |
| 130 | QSH25 | QHH25 | └ 재해발생유형코드 | 메뉴 | Y | `/qha/disCdMng` |
| 131 | QSH30 | QHH30 | └ 안전작업허가코드 | 메뉴 | N | `/qha/safeWorkReqCd` |
| 132 | QSH40 | QHH40 | └ 교육코드 | 메뉴 | Y | `/qha/eduCd` |
| 133 | QSH50 | QHH50 | └ 협의체코드 | 메뉴 | N | `/qha/arecCd` |
| 134 | QSH60 | QHH60 | └ 점검체크리스트지표 | 메뉴 | Y | `/qha/ckLstItm` |
| 135 | QSH95 | QHH95 | └ MSDS교육 제품등록 | 메뉴 | Y | `/qha/msdsCd` |

## 10. 실행 결과 (2026-11-16)

8장 기본안(1~4 모두 기본안)대로 실행했다. VPLUS202611A 계정으로 한 트랜잭션에서 실행했고, 사후 검증이 모두 맞을 때만 COMMIT하도록 했다.

| 단계 | 결과 | 기대값 |
|---|---|---|
| [1] 사전 확인 (QH root / QH 하위 / QH URL) | 1 / 0 / 0 | 1 / 0 / 0 |
| [3] INSERT 반영 행 | 135 | 135 |
| 4-1 `IPT_ID = 'MIG_JH_QS'` 건수 | 135 | 135 |
| 4-2 상위가 없는 QH 메뉴 | 0 | 0 |
| 4-3 `QH`부터 트리 조회 | 136 | 136 |
| 4-4 전체 메뉴 URL 중복 | 0 | 0 |
| 4-5 QH 메뉴에 남은 `/qs` 경로 | 0 | 0 |
| COMMIT | 완료 | |

추가 확인:
- 넣은 135건의 메뉴명·정렬·종류·사용여부·플래그·비고·생성일시·생성자를 JH 원본과 컬럼별로 비교했다. 모두 같다(한글 깨짐 없음).
- `QH` 아래 2단계 그룹 9개가 JH와 같은 순서로 들어갔다: 자료/문서관리, 안전보건목표, 안전보건계획, 위험성평가, 안전보건활동, 재해예방관리, 산업안전보건관리비, 평가및개선, 표준정보.

남은 일: 6장(권한 부여, DTL 보정, 화면 확인). 아직 하지 않았다.
