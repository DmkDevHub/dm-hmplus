# QH 소스 복사 미리보기 보고서 (3단계)

> 계획: [QH_SOURCE_COPY_PLAN.md](../../docs/QH_SOURCE_COPY_PLAN.md) · 아직 파일을 쓰지 않았다. 줄 단위 diff는 `32_preview.diff`, 남은 qs/QS는 `31_leftover.txt`

## 1. 요약

| 항목 | 값 |
|---|---:|
| 새로 만들 파일 | 783 |
| 그중 내용이 바뀌는 파일 | 775 |
| 수정할 기존 파일(예외 허용) | 6 |
| 매핑표에 없는 DB 이름(NOT_MAPPED) | 136 |
| 바꾼 코드 값 (종류) | 92 |
| 그대로 둔 코드 모양 값 (종류) | 23 |

## 2. 규칙별 바꾸는 곳 (새 파일 783개)

| 규칙 | 곳 |
|---|---:|
| 5-1 패키지 qs.aprv | 8 |
| 5-1 패키지 qs.qsa | 907 |
| 5-1 패키지 qs.qsb | 40 |
| 5-1 패키지 그 밖 | 525 |
| 5-2 클래스 이름 | 1319 |
| 5-3 URL /qsa | 780 |
| 5-3 URL /qsb | 52 |
| 5-3 경로 qs/aprv | 55 |
| 5-3 경로 qs/qsa | 2 |
| 5-3 경로 qs/qsb | 1 |
| 5-3 주석 [qsa/ | 2 |
| 5-3 주석 [qsb/ | 1 |
| 5-4 DB 이름 (CREATE) | 415 |
| 5-5 공통코드 값 (QH 코드 없음, 그대로) | 84 |
| 5-5 공통코드 값 (바꿈) | 709 |
| 5-6 "QS-항목" | 4 |
| 5-6 module:"QS" | 188 |
| 5-6 workType="QS" | 3 |
| 5-6 wrkTp="QS" | 8 |
| 5-6 함수 qsf -> qhf | 114 |
| 5-6 항목 이름 QS_ -> QH_ | 121 |
| 5-7 OZ /QS/ | 48 |
| 5-7 OZ node QS | 1 |

## 3. 기존 파일 수정 (5단계 ②·③)

| 규칙 | 곳 |
|---|---:|
| ② OZ /QS/ | 11 |
| ② OZ /QS/qsa/ | 2 |
| ② OZ /QS/qsb/ | 1 |
| ② 항목 이름 | 8 |
| ③ footer.jsp 결재 주소 | 2 |
| ③ footer.jsp 머리 3줄 | 1 |
| ③ header.jsp 결재 주소 | 8 |
| ③ header.jsp 머리 3줄 | 1 |
| ③ tiles 정의 추가 | 1 |

## 4. DB 이름

| ACTION | 개수 |
|---|---:|
| CREATE | 264 |
| EXCLUDE | 3 |
| NOT_MAPPED | 136 |

### 4-1. 매핑표에 없는 이름 (바꾸지 않음, 5-4)

| 이름 | 기준선 | 파일 수 | 사용 파일 |
|---|---|---:|---|
| `PQSA_APRS_AGG_W` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/JobResult.xml |
| `PQSA_APRS_COPY_W` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/JobCd.xml |
| `PQSA_APRS_DTL_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/AprsItmManage.xml |
| `PQSA_APRS_ITM_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/AprsItmManage.xml |
| `PQSA_APRS_ITM_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/AprsItmManage.xml |
| `PQSA_APRS_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/AprsItmManage.xml |
| `PQSA_APRVLST_YYTRGPLAN_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/YyTrgPlan.xml |
| `PQSA_BASE_CD_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/BaseCd.xml |
| `PQSA_BASE_CD_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/BaseCd.xml |
| `PQSA_CAR_LIST_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/RollMngChkLst.xml |
| `PQSA_CAR_LIST_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/RollMngChkLst.xml |
| `PQSA_CHKITMANA1_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ChkItmAna1.xml |
| `PQSA_DANGEROUS_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/DayHealtLogLst.xml |
| `PQSA_DANGEROUS_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/DayHealtLogLst.xml |
| `PQSA_DISASTER_DIV_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/BaseCd.xml |
| `PQSA_FINE_OBJ_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/FineLst.xml |
| `PQSA_FINE_OBJ_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/FineLst.xml |
| `PQSA_FINE_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/FineLst.xml |
| `PQSA_FINE_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/FineLst.xml |
| `PQSA_FINE_VLT_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/FineLst.xml |
| `PQSA_FINE_VLT_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/FineLst.xml |
| `PQSA_HOCHKRPT_DETAIL_Q` | vplus | 1 | resources/sqlmap/mybatis/qs/qsa/hoChk4Dtl.xml |
| `PQSA_HOCHKRPT_DETAIL_S` | vplus | 1 | resources/sqlmap/mybatis/qs/qsa/hoChk4Dtl.xml |
| `PQSA_HOCHK_ITM_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ChkItmManage.xml |
| `PQSA_HOCHK_ITM_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ChkItmManage.xml |
| `PQSA_HOCHK_MA_Q` | 없음 | 2 | resources/sqlmap/mybatis/qs/qsa/ActionRsltLst.xml resources/sqlmap/mybatis/qs/qsa/ChkItmReg.xml |
| `PQSA_HOCHK_MA_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ActionRsltLst.xml |
| `PQSA_HOCHK_REG_ANTM_S` | 없음 | 2 | java/com/jh/erp/qs/qsa/web/ChkItmRegController.java resources/sqlmap/mybatis/qs/qsa/ChkItmReg.xml |
| `PQSA_HOCHK_REG_RGL_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ChkItmReg.xml |
| `PQSA_HOCHK_RSLT_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ActionRsltLst.xml |
| `PQSA_HOCHK_RSLT_W` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ActionRsltLst.xml |
| `PQSA_HOCHK_SCHD_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ChkItmSchedule.xml |
| `PQSA_HOCHK_SCHD_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ChkItmSchedule.xml |
| `PQSA_HOCHK_SCHD_SMRY_Q` | 없음 | 2 | resources/sqlmap/mybatis/qs/qsa/ActionRsltLst.xml resources/sqlmap/mybatis/qs/qsa/ChkItmReg.xml |
| `PQSA_IDAC_MINUS_Q` | vplus | 1 | resources/sqlmap/mybatis/qs/qsa/IndustAcciLst.xml |
| `PQSA_IDAC_MINUS_S` | vplus | 1 | resources/sqlmap/mybatis/qs/qsa/IndustAcciLst.xml |
| `PQSA_JOB_CD_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/JobCd.xml |
| `PQSA_JOB_CD_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/JobCd.xml |
| `PQSA_JOB_CTSRESULT_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/JobResult.xml |
| `PQSA_JOB_CTSRESULT_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/JobResult.xml |
| `PQSA_JOB_CTS_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/JobCd.xml |
| `PQSA_JOB_CTS_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/JobCd.xml |
| `PQSA_JOB_ITEM_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/JobCd.xml |
| `PQSA_JOB_ITEM_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/JobCd.xml |
| `PQSA_JOB_OBJ_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ObjCd.xml |
| `PQSA_JOB_OBJ_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ObjCd.xml |
| `PQSA_JOB_RESULT_DET_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/JobResult.xml |
| `PQSA_JOB_RESULT_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/JobResult.xml |
| `PQSA_JOB_RESULT_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/JobResult.xml |
| `PQSA_JOB_SITE_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ObjCd.xml |
| `PQSA_JOB_SITE_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ObjCd.xml |
| `PQSA_JOB_SITE_W` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ObjCd.xml |
| `PQSA_JOIN_OBJ_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ObjCd.xml |
| `PQSA_JOIN_OBJ_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ObjCd.xml |
| `PQSA_MON_PSN_B` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/MonthSiteReg.xml |
| `PQSA_MON_PSN_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/MonthSiteReg.xml |
| `PQSA_MON_PSN_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/MonthSiteReg.xml |
| `PQSA_MON_RSLT_B` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/MonthSiteReg.xml |
| `PQSA_MON_RSLT_DTL_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/MonthSiteReg.xml |
| `PQSA_MON_RSLT_LST_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/MonthRsltLst.xml |
| `PQSA_MON_RSLT_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/MonthSiteReg.xml |
| `PQSA_MON_RSLT_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/MonthSiteReg.xml |
| `PQSA_MON_SUBPSN_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/MonthSiteReg.xml |
| `PQSA_MON_SUBPSN_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/MonthSiteReg.xml |
| `PQSA_MON_SUBPSN_W` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/MonthSiteReg.xml |
| `PQSA_MOVE_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/MoveReg.xml |
| `PQSA_MOVE_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/MoveReg.xml |
| `PQSA_ODAYHEALT_LOG_B` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/DayHealtLogLst.xml |
| `PQSA_ODAYHEALT_LOG_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/DayHealtLogLst.xml |
| `PQSA_ODAYHEALT_LOG_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/DayHealtLogLst.xml |
| `PQSA_ODAYSAFE_LOG_APRV_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ApprMng2Repository.xml |
| `PQSA_ODAYSAFE_LOG_B` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/DaySafeLogLst.xml |
| `PQSA_ODAYSAFE_LOG_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/DaySafeLogLst.xml |
| `PQSA_ODAYSAFE_LOG_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/DaySafeLogLst.xml |
| `PQSA_ODAYSAFE_STOP_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/DaySafeLogLst.xml |
| `PQSA_ODAYSAFE_STOP_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/DaySafeLogLst.xml |
| `PQSA_PERF_BONSA_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ResultChkObj.xml |
| `PQSA_PERF_OBJ_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ResultChkObj.xml |
| `PQSA_PERF_OBJ_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ResultChkObj.xml |
| `PQSA_PERF_SAFE_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ResultChkObj.xml |
| `PQSA_PERF_SITE_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ResultChkObj.xml |
| `PQSA_RISKSITE_CIPIFUPLD_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/OdaycipifReg.xml |
| `PQSA_RISKSITE_CIPIFUPLD_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/OdaycipifReg.xml |
| `PQSA_RISKSITE_CIPIF_B` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/OdaycipifReg.xml |
| `PQSA_RISKSITE_CIPIF_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/OdaycipifReg.xml |
| `PQSA_RISKSITE_CIPIF_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/OdaycipifReg.xml |
| `PQSA_RISK_AREC_B` | vplus | 1 | resources/sqlmap/mybatis/qs/qsa/RiskItmLst.xml |
| `PQSA_RISK_AREC_S` | vplus | 2 | resources/sqlmap/mybatis/qs/qsa/CurrPlnLst.xml resources/sqlmap/mybatis/qs/qsa/MeetDrft.xml |
| `PQSA_RISK_CIPIFUPLD_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/RiskcipifReg.xml |
| `PQSA_RISK_CIPIFUPLD_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/RiskcipifReg.xml |
| `PQSA_RISK_CIPIF_B` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/RiskcipifReg.xml |
| `PQSA_RISK_CIPIF_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/RiskcipifReg.xml |
| `PQSA_RISK_CIPIF_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/RiskcipifReg.xml |
| `PQSA_RISK_PRRTCHK_B` | vplus | 1 | resources/sqlmap/mybatis/qs/qsa/MainMngItmReg.xml |
| `PQSA_RISK_PRRTCHK_C` | vplus | 1 | resources/sqlmap/mybatis/qs/qsa/MainMngItmReg.xml |
| `PQSA_RISK_PRRTCHK_Q` | vplus | 1 | resources/sqlmap/mybatis/qs/qsa/MainMngItmReg.xml |
| `PQSA_RISK_PRRTCHK_S` | vplus | 1 | resources/sqlmap/mybatis/qs/qsa/MainMngItmReg.xml |
| `PQSA_SAFECOST_PROCRT_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/SafeCostMng.xml |
| `PQSA_SEALED_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/DayHealtLogLst.xml |
| `PQSA_SEALED_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/DayHealtLogLst.xml |
| `PQSA_SELECT_Q` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/SelectMngChkLst.xml |
| `PQSA_SELECT_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/SelectMngChkLst.xml |
| `PQSA_SITEAPRS_B` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/AprsItmManage.xml |
| `PQSA_SITEAPRS_DTL_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/AprsItmManage.xml |
| `PQSA_SITEAPRS_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/AprsItmManage.xml |
| `PQSA_SITEAPRS_VNDR_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/AprsItmManage.xml |
| `PQSA_YYTRGPLNCHR_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/YyTrgPlan.xml |
| `PQSZ_APRVLST_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/YyTrgArslt.xml |
| `PQSZ_SITENAM_S` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/QszSiteMng.xml |
| `PQSZ_SITESNSBDTS_S` | 없음 | 2 | resources/sqlmap/mybatis/qs/qsa/QszSiteMng.xml resources/sqlmap/mybatis/qs/qsa/QszSiteMngCp.xml |
| `TQSA_APRS_DTL` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/AprsItmManage.xml |
| `TQSA_APRS_ITM` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/AprsItmManage.xml |
| `TQSA_FINE` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/FineLst.xml |
| `TQSA_HOCHK_ITM` | 없음 | 3 | resources/sqlmap/mybatis/qs/qsa/ActionRsltLst.xml resources/sqlmap/mybatis/qs/qsa/ChkItmManage.xml resources/sqlmap/mybatis/qs/qsa/ChkItmReg.xml |
| `TQSA_HOCHK_MA` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ActionRsltLst.xml |
| `TQSA_HOCHK_REG_ANTM` | 없음 | 2 | resources/sqlmap/mybatis/qs/qsa/ActionRsltLst.xml resources/sqlmap/mybatis/qs/qsa/ChkItmReg.xml |
| `TQSA_HOCHK_REG_RGL` | 없음 | 2 | resources/sqlmap/mybatis/qs/qsa/ActionRsltLst.xml resources/sqlmap/mybatis/qs/qsa/ChkItmReg.xml |
| `TQSA_HOCHK_RSLT` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ActionRsltLst.xml |
| `TQSA_HOCHK_SCHD` | 없음 | 2 | resources/sqlmap/mybatis/qs/qsa/ActionRsltLst.xml resources/sqlmap/mybatis/qs/qsa/ChkItmReg.xml |
| `TQSA_JOB_CD` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/AprsCts.xml |
| `TQSA_JOB_CTS` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/AprsCts.xml |
| `TQSA_JOB_ITEM` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/AprsCts.xml |
| `TQSA_MON_RSLT` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/MonthSiteReg.xml |
| `TQSA_MON_SAFE` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/MonthSafeReg.xml |
| `TQSA_PERF_OBJ` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/ResultChkObj.xml |
| `TQSA_SAFECOST_PROCRT` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/SafeCostMng.xml |
| `TQSA_SITEAPRS` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/AprsItmManage.xml |
| `TQSA_SITEAPRS_DTL` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/AprsItmManage.xml |
| `TQSA_SITEAPRS_VNDR` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/AprsItmManage.xml |
| `TQSB_RSKEVLNAM` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/QszSiteMng.xml |
| `TQSM_HOCHKRPT` | 없음 | 3 | resources/sqlmap/mybatis/qs/qsa/SiteMa.xml resources/sqlmap/mybatis/qs/qsa/hoChk4.xml resources/sqlmap/mybatis/qs/qsa/hoChk5Curst.xml |
| `TQSN_CK_DD` | 없음 | 1 | resources/sqlmap/mybatis/qs/qsa/QszSiteMng.xml |
| `TQSZ_SITENAM` | 없음 | 2 | resources/sqlmap/mybatis/qs/qsa/QszSiteMng.xml resources/sqlmap/mybatis/qs/qsa/hoChk4.xml |
| `TQSZ_SITESNSBDTS` | 없음 | 2 | resources/sqlmap/mybatis/qs/qsa/QszSiteMng.xml resources/sqlmap/mybatis/qs/qsa/QszSiteMngCp.xml |
| `VQSZ_SUBCONT` | JH,vplus | 1 | resources/sqlmap/mybatis/qs/qsa/AprsItmManage.xml |
| `VQSZ_TRADE` | JH,vplus | 2 | resources/sqlmap/mybatis/qs/qsa/AprsItmManage.xml resources/sqlmap/mybatis/qs/qsa/ResultChkObj.xml |

### 4-2. EXCLUDE (vplus 것을 그대로 사용)

| 이름 | 파일 수 |
|---|---:|
| `FQSZ_USR_INFO` | 2 |
| `PQSC_MMEDUPLAN_S` | 1 |
| `PQSD_SUBCONT_Q` | 1 |

## 5. 그대로 둔 코드 모양 값 (QH 공통코드에 없음, 5-5)

| 값 | 파일 수 | 사용 파일 |
|---|---:|---|
| `QS01` | 1 | java/com/jh/erp/qs/qsa/svc/impl/SafeCostRegServiceImpl.java |
| `QSA01` | 3 | webapp/WEB-INF/jsp/qs/qsa/yyTrgArsltSeq.jsp webapp/WEB-INF/jsp/qs/qsa/yyTrgPlanSeq.jsp webapp/WEB-INF/jsp/qs/qsa/yyTrgPlanStf.jsp |
| `QSA010` | 2 | webapp/WEB-INF/jsp/qs/qsa/yyTrgArsltSeq.jsp webapp/WEB-INF/jsp/qs/qsa/yyTrgPlanSeq.jsp |
| `QSA01010` | 2 | webapp/WEB-INF/jsp/qs/qsa/yyTrgArsltSeq.jsp webapp/WEB-INF/jsp/qs/qsa/yyTrgPlanSeq.jsp |
| `QSA01050` | 2 | webapp/WEB-INF/jsp/qs/qsa/yyTrgArsltSeq.jsp webapp/WEB-INF/jsp/qs/qsa/yyTrgPlanSeq.jsp |
| `QSA01090` | 2 | webapp/WEB-INF/jsp/qs/qsa/yyTrgArsltSeq.jsp webapp/WEB-INF/jsp/qs/qsa/yyTrgPlanSeq.jsp |
| `QSA01095` | 2 | webapp/WEB-INF/jsp/qs/qsa/yyTrgArsltSeq.jsp webapp/WEB-INF/jsp/qs/qsa/yyTrgPlanSeq.jsp |
| `QSA02` | 1 | webapp/WEB-INF/jsp/qs/qsa/yyTrgPlan.jsp |
| `QSC6040` | 1 | java/com/jh/erp/qs/qsa/svc/impl/EqmTabkServiceImpl.java |
| `QSI01` | 1 | resources/sqlmap/mybatis/qs/qsa/EqmTabk.xml |
| `QSI02` | 1 | resources/sqlmap/mybatis/qs/qsa/EqmTabk.xml |
| `QSK03` | 4 | resources/sqlmap/mybatis/qs/qsa/SiteMa.xml resources/sqlmap/mybatis/qs/qsa/hoChk1Err.xml resources/sqlmap/mybatis/qs/qsa/hoChk4Err.xml resources/sqlmap/mybatis/ |
| `QSZ080` | 1 | java/com/jh/erp/qs/qsa/svc/impl/EqmTabkServiceImpl.java |
| `QSZ09010` | 1 | java/com/jh/erp/qs/qsa/svc/impl/QszSiteMngServiceImpl.java |
| `QSZ110` | 1 | java/com/jh/erp/qs/qsa/svc/impl/QszSiteMngCpServiceImpl.java |
| `QSZ1210` | 2 | webapp/WEB-INF/jsp/qs/qsa/yyTrgArslt.jsp webapp/WEB-INF/jsp/qs/qsa/yyTrgPlan.jsp |
| `QSZ1220` | 1 | webapp/WEB-INF/jsp/qs/qsa/yyTrgPlan.jsp |
| `QSZ1230` | 1 | webapp/WEB-INF/jsp/qs/qsa/yyTrgPlan.jsp |
| `QSZ1240` | 1 | webapp/WEB-INF/jsp/qs/qsa/yyTrgPlan.jsp |
| `QSZ14` | 6 | resources/sqlmap/mybatis/qs/qsa/YyTrgArslt.xml resources/sqlmap/mybatis/qs/qsa/YyTrgPlan.xml webapp/WEB-INF/jsp/qs/qsa/yyTrgArslt.jsp webapp/WEB-INF/jsp/qs/qsa/ |
| `QSZ1410` | 3 | webapp/WEB-INF/jsp/qs/qsa/yyTrgArslt.jsp webapp/WEB-INF/jsp/qs/qsa/yyTrgPlan.jsp webapp/WEB-INF/jsp/qs/qsa/yyTrgPlanSeq.jsp |
| `QSZ1420` | 5 | webapp/WEB-INF/jsp/qs/qsa/yyTrgArslt.jsp webapp/WEB-INF/jsp/qs/qsa/yyTrgArsltSeq.jsp webapp/WEB-INF/jsp/qs/qsa/yyTrgPlan.jsp webapp/WEB-INF/jsp/qs/qsa/yyTrgPlan |
| `QSZ1490` | 5 | webapp/WEB-INF/jsp/qs/qsa/yyTrgArslt.jsp webapp/WEB-INF/jsp/qs/qsa/yyTrgArsltSeq.jsp webapp/WEB-INF/jsp/qs/qsa/yyTrgPlan.jsp webapp/WEB-INF/jsp/qs/qsa/yyTrgPlan |

## 6. 남은 qs/QS 토큰 (상위 40개, 전체는 31_leftover.txt)

| 토큰 | 곳 |
|---|---:|
| `qstringFile` | 199 |
| `qstring` | 102 |
| `qstringPhoto2` | 77 |
| `qstringPhoto1` | 69 |
| `QsAprvInfo` | 64 |
| `qs_sit_cd` | 54 |
| `qs_sit_nm` | 54 |
| `QsaSafeCostInfo` | 17 |
| `qs` | 17 |
| `QsSendSms` | 16 |
| `Qs` | 15 |
| `QSZ14` | 13 |
| `qsEduDry` | 12 |
| `qstringPhoto3` | 12 |
| `qstringBfPhoto1` | 10 |
| `qstringBfPhoto2` | 10 |
| `qstringAfPhoto1` | 10 |
| `qstringAfPhoto2` | 10 |
| `qstringPhoto` | 10 |
| `QSZ1420` | 10 |
| `QSZ1490` | 10 |
| `QsAdmPageLst` | 9 |
| `qsAprvDlg` | 9 |
| `QsAprvAtflGrp` | 8 |
| `QSE` | 8 |
| `qstringPhoto4` | 8 |
| `qscd014` | 6 |
| `qsaYyTrgPlanStf` | 6 |
| `QsSendSmsResult` | 5 |
| `QS` | 5 |
| `qsSendSms` | 5 |
| `QSZ1410` | 5 |
| `qsaYyTrgArsltSeq` | 5 |
| `QSZ1210` | 5 |
| `QsSendSmsW` | 4 |
| `qsAdmPageRepository` | 4 |
| `qsAdmPageService` | 4 |
| `QSK03` | 4 |
| `qstringFile1` | 4 |
| `qstringPhoto5` | 4 |

## 7. 리포트 서버에 필요한 OZ 경로 (결정 4, 나중에 추가)

JSP의 `rptName`(파일 이름이 변수인 것 포함)과 `qh.lib.js`의 `RPTNAME`이다.

- `/QH/" + "safeCostRegAprv" + ".ozr`
- `/QH/" + rtnData.PAGE_TTL + ".ozr`
- `/QH/aprsItmSiteAprv.ozr`
- `/QH/aprsItmSiteAprv2.ozr`
- `/QH/assLogAprv.ozr`
- `/QH/chkConfirmRpt.ozr`
- `/QH/chkItmRegRpt.ozr`
- `/QH/daySafeChk_01.ozr`
- `/QH/daySafeChk_02.ozr`
- `/QH/daySafeChk_03.ozr`
- `/QH/eqmTabk.ozr`
- `/QH/hlthChkup.ozr`
- `/QH/jobResult.ozr`
- `/QH/riskAssRpt.ozr`
- `/QH/riskItmRegCo.ozr`
- `/QH/riskItmRpt1.ozr`
- `/QH/riskPlanRpt.ozr`
- `/QH/safeCostRpt1-10.ozr`
- `/QH/safeCostRpt1-2.ozr`
- `/QH/safeCostRpt1-3.ozr`
- `/QH/safeCostRpt1-4.ozr`
- `/QH/safeCostRpt1-5.ozr`
- `/QH/safeCostRpt1-6.ozr`
- `/QH/safeCostRpt1-7.ozr`
- `/QH/safeCostRpt1-8.ozr`
- `/QH/safeCostRpt1-9.ozr`
- `/QH/safeCostRpt1.ozr`
- `/QH/safeWorkRegAppr.ozr`
- `/QH/siteMaAprvNew.ozr`
- `/QH/siteMaAprvNew2.ozr`
- `/QH/weekWorkLogHoAprv.ozr`
- `/QH/qha/yyTrgArslt_R01.ozr`
- `/QH/qha/yyTrgPlan_R01.ozr`
- `/QH/qhb/rskEvlMngTy_R01.ozr`
- `/QH/qhf/eduDryMng_R01.ozr`
- `/QH/qsg/assLog_R01.ozr`
- `/QH/qsk/dissOcurMng_R01.ozr`
- `/QH/qsm/hoChk4_R01.ozr`
- `/QH/qsm/siteMa_R01.ozr`
- `/QH/qsn/ddChkDry_R01.ozr`
- `/QH/qsn/mmSaftChr_R01.ozr`
- `/QH/qsn/sfatChkDry_R01.ozr`
- `/QH/qso/prvtmaReq_R01.ozr`
- `/QH/qsp/copAssCurst_R01.ozr`
- `/QH/qst/envChkClsMng_R01.ozr`
