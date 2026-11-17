# 3단계 변환 미리보기 (파일을 쓰지 않음)

- 새 파일: 72개

## 규칙별 바꾼 곳

| 규칙 | 곳 |
|---|---:|
| 5-1 package | 116 |
| 5-2 class | 110 |
| 5-3 nav | 8 |
| 5-3 relpath | 5 |
| 5-3 url | 109 |
| 5-3 view | 18 |
| 5-4 db | 85 |
| 5-4b proc arg | 3 |
| 5-5 code | 147 |
| 5-6 item | 5 |
| 5-6 module | 10 |
| 5-6 qsfn | 2 |
| 5-6 sqlid | 3 |
| 5-6 wrkTp | 1 |
| 5-7 oz | 4 |

## 남은 QS DB 이름 (매핑표 CREATE 아님)

- `PQSC_NCR_AB_S` (NOT_MAPPED): resources/sqlmap/mybatis/qh/qhc/NcrActRsltCo.xml
- `PQSC_NCR_REP_S` (NOT_MAPPED): resources/sqlmap/mybatis/qh/qhc/NcrActRsltCo.xml
- `TQSC_NCR_REP` (NOT_MAPPED): resources/sqlmap/mybatis/qh/qhc/NcrActRsltCo.xml, resources/sqlmap/mybatis/qh/qhz/QsMain.xml
- `VQSZ_SITEINFO` (NOT_MAPPED): resources/sqlmap/mybatis/co/codefind/QhCodeFind.xml, resources/sqlmap/mybatis/qh/qhz/QsMain.xml
- `VQSZ_TRADE` (NOT_MAPPED): resources/sqlmap/mybatis/co/codefind/QhCodeFind.xml, resources/sqlmap/mybatis/qh/qha/SafeWorkReqCo.xml

## 그대로 둔 QS 코드 모양 값 (QH 코드 없음)

{'QSE': 2}

## 공통 파일에 추가할 줄

- `java/com/hs/partner/co/comcode/rps/FindCodeRepository.java`: 3줄
    - `List<Map<String,Object>> get_QH_CodeFindList(Map<String, Object> map); // 안전`
    - `List<Map<String,Object>> get_QH_CodeFindList_Proc(Map<String, Object> map); // 안전`
    - `List<Map<String,Object>> get_QH_SelectBindList(Map<String, Object> map); // 안전`
- `webapp/WEB-INF/jsp/include/scriptInclude.jsp`: 1줄
    - `<script type="text/javascript" src="/resources/js/module/qh.lib.js?ver=${script_version}"></script>`
- `webapp/resources/js/app.createcodefinder.js`: 6줄
    - `case "QH":`
    - `init_sheet = qhfnCodeFindInit(initdata.moduleDiv);`
    - `break;`
    - `case "QH":`
    - `init_sheet = qhfnCodeFindInit(initdata.moduleDiv);`
    - `break;`
- `webapp/WEB-INF/jsp/index.jsp`: 1줄
    - `<c:when test="${sysTp eq 'QH'}"><jsp:include page="/WEB-INF/jsp/include/navQH.jsp"></jsp:include></c:when>`

## 남은 `qs`/`QS` 토큰 (31_leftover.txt에 줄 단위 목록)

- `qstringAfPhoto1`: 12
- `qstringAfPhoto2`: 12
- `VQSZ_SITEINFO`: 11
- `vPQSImgPathRule`: 11
- `qsMainRepository`: 8
- `qsMainService`: 8
- `qs_site_cd`: 7
- `qs_site_nm`: 7
- `VQSZ_TRADE`: 6
- `TQSC_NCR_REP`: 6
- `qstring`: 6
- `qstringFile2`: 5
- `qstringFile3`: 5
- `qstringFile`: 4
- `qstringFile1`: 4
- `get_qsDashBoardTopInfo`: 3
- `dashBoardQs`: 3
- `getFrm_qsDashBoardTopInfo`: 3
- `QS_PARTNER`: 3
- `qszAnncBrdDtlPopView`: 2
- `get_QsDashBoardTopInfo`: 2
- `getEnd_QsDashBoardTopInfo`: 2
- `QSE`: 2
- `page_DashBoardQs`: 1
- `PQSC_NCR_REP_S`: 1
- `PQSC_NCR_AB_S`: 1
- `QS`: 1
