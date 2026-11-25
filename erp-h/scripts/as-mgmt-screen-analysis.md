# A/S관리 화면 분석서 (cs_csChkMng · PAGE_ID=AS)

- 작성일: 2026-11-25
- 대상 메뉴: 하자 > 하자 등록 및 처리 > AS관리 > A/S관리
- 용도: 이 문서를 기준으로 A/S관리 화면을 새로 구현하기 위한 명세

## 1. 개요

A/S관리 화면은 현장·동·호 단위로 입주 후 하자(A/S) 접수 건을 조회·등록·수정·삭제하고, 접수 건별 이력·공종이관·사진·예약알림·반려·확인요청·재분류·미해당 처리를 수행하는 마스터-디테일 화면이다. 같은 화면 정의 `pages/cs/csChkMng.js` 를 품질점검(QLT)·주부품질점검(HWF)·사전점검(BF)·A/S관리(AS) 네 메뉴가 공유하며, 서비스 등록 파라미터 `PAGE_ID` 로 모드를 구분한다. 이 문서는 AS 모드 기준으로 정리하고, 다른 모드와 갈리는 지점은 따로 표시한다.

## 2. 소스 위치 (products-erp-h)

| 구분 | 경로 |
|---|---|
| 화면 정의 | `app/src/main/resources/pages/cs/csChkMng.js` (2,271줄) |
| 컨트롤러(주) | `app/src/main/java/hmplus/erp/cs/csc/controller/CsChkMngController.java` (`/csc`) |
| 컨트롤러(H사 확장) | `app/src/main/java/hmplus/erp/cs/csb/controller/CsIntakeController.java` (확인요청·재분류·미해당·토목) |
| 컨트롤러(매칭) | `app/src/main/java/hmplus/erp/cs/csb/controller/CtpMatchController.java` (`getFrm_CtpMatch`) |
| 코드 조회 | `app/src/main/java/hmplus/erp/cs/csz/controller/CsCodeLookupController.java` (`/csz/codeLookup`) |
| 목록 서비스·매퍼 | `CsChkMngListQService.java` · `erp-csc-csChkMngListQ.xml` |
| 저장 서비스·매퍼 | `CsChkMngSaveService.java` · `erp-csc-csChkMngSave.xml` |
| AS 접수 저장 | `app/src/main/java/hmplus/erp/cs/csb/service/AsAcpDtlsService.java` |
| H사 확장 저장 | `app/src/main/java/hmplus/erp/cs/csb/service/CsIntakeService.java` |
| 프로그램·서비스 시드 | `db/module/erp/install/common/cs-02_program.sql:23` · `cs-03_service.sql:45` |

서비스 등록값

| 서비스 ID | 메뉴명 | params | 상위 메뉴 |
|---|---|---|---|
| `cs_csChkMng` | A/S관리 | `{"PAGE_ID":"AS"}` | `MENU_CS_REG_AS` |
| `cs_csChkMng_bf` | 사전점검 | `{"PAGE_ID":"BF"}` | `MENU_CS_REG_BF` |
| `cs_csChkMng_qlt` | 품질점검 | `{"PAGE_ID":"QLT"}` | `MENU_CS_REG_QLT` |

- 프로그램 ID `cs_csChkMng`, 경로 `cs/csChkMng`, 열기 방식 TAB, 데이터 범위 `LEGAL`
- 화면 속성: `dirtyCheck: true`, `searchOnLoad: true`

## 3. 화면 배치

```
┌ TitleBar ───────────────────────────────────────────────────────────────────┐
│ [예약 일괄등록][출력옵션][완료확인서출력][작업지시서출력][세대정보][엑셀업로드][저장][조회] │
├ SearchBar (4열, 라벨폭 72px, columnWidths 0.34/0.24/0.22/0.2) ───────────────┤
│ *현장 [코드|명 파인더]   접수기간 [시작]~[종료]   동/호 [동▼][호]   완료 [전체▼]     │
│ 협력업체 [파인더]        공종 [대][중](표시)      긴급 [전체▼]       진행상태 [▼]     │
│ 검사구분 [전체▼]                                                              │
├ HBox ────────────────────────────────┬─────────────────────────────────────┤
│ GridPanel "A/S관리"  Total:N [+추가][삭제] │ FormPanel "상세내용" (2열, 라벨폭 90px)   │
│  순번|선택|접수순번|독촉|접수일자|진행상태|  │  머리줄: [신규작성 표시][이력정보][공종이관]│
│  동|호|휴대폰번호|공종|접수내용|완료여부|    │   [사진등록][세대복사][반려][확인요청]    │
│  완료일자|등록일자|접수처|접수자           │   [재분류][미해당 처리][토목 처리주체]    │
│  (frozen 8, 필터행, 단일선택)              │  필드 영역(4장 참조)                      │
│                                      Splitter ├─────────────────────────────────────┤
│                                          │ FormPanel 사진상태(1열, 라벨폭 110px)     │
│                                          │        근경사진   | 원경사진             │
│                                          │  처리 전 [파일명]  | [파일명]             │
│                                          │  처리 후 [파일명]  | [파일명]             │
│                                          │  서명/완료확인서 [서명] | [완료확인서]     │
└──────────────────────────────────────┴─────────────────────────────────────┘
```

- 좌측 그리드와 우측 상세는 `Splitter` 로 폭 조절 가능
- 우측 상세 패널은 세로 스크롤만 허용(코어 `.fw-formpanel` 기본값), `overflow="auto"` 선언 금지

## 4. 조회조건 (SearchBar · `search` 모델)

| 라벨 | 필드 | 컴포넌트 | 규칙 |
|---|---|---|---|
| 현장 | `csSiteCd` / `csSiteNm` | `CsSiteStepFinder` (폭 350px, 코드칸 80px) | 필수, `remember` (재진입 시 복원) |
| 접수기간 | `acpStrDt` ~ `acpEndDt` | `DateRange` (표시 `yy-mm-dd`, 값 `yyyyMMdd`) | 기본값 당해 1월 1일 ~ 오늘, 시작>종료 자동보정 |
| 동/호 | `searchBl` / `searchRm` | `Select`(lookup `blOptions`, 90) + `InputText`(90) | `remember`, 동 목록 첫 항목 자동선택 |
| 완료 | `searchSucYn` | `Select` (전체/예/아니오 = ''/1/0) | |
| 협력업체 | `searchCustCd` / `searchCustNm` | `CsCoFinder` (params `SITE_CD`) | 선택 시 `searchCopCoSeq`·`searchCtp`·공종명 동반 설정 |
| 공종 | `searchCtp1` / `searchCtp2` | `InputText` 2개, disabled | 표시 전용(대공종명·중공종명) |
| 긴급 | `searchUyYn` | `Select` (전체/예/아니오) | |
| 진행상태 | `searchPrgsStats` | `Select` 코드그룹 `CS54`, firstRow L | |
| 검사구분 | `searchAcpDiv` | `Select` 코드그룹 `CS09`, firstRow N | AS 모드에서만 표시 |

조회 필수 규칙

- 현장 미선택 시 토스트 `CS_SELECT_SITE` 후 중단
- 동·협력업체·진행상태 중 하나가 반드시 있어야 함(`requiredAny`), 단 긴급=예 이면 통과 — 미충족 시 `CS_SELECT_BL_OR_CUST` 알림
- 자동조회(`searchOnLoad`)도 위 `requiredAny` 게이트를 통과해야 실행됨

조회조건 동작

- 현장 선택(`onSiteSelect`): 동·호·완료·협력업체·공종·긴급·검사구분 초기화, 접수 시작일은 비우고 종료일은 오늘로 설정 → 동 목록 재조회 → 첫 동 선택 → 자동 조회
- 협력업체 해제: 공종 표시값·`searchCopCoSeq`·`searchCtp` 초기화
- 조회조건 변경(`onSearchFieldChange`): 상세폼 초기화, 목록 비움, 선택 해제(silent), `searched=false`
- SearchBar `guard`: 미저장 상태에서 조건 변경 시 확인창, 취소하면 이전 값 복원

## 5. 접수목록 그리드 (`sheet1Store`, key `ACP_SEQ`)

그리드 속성: `frozen="8"`, `selection="single"`, `guard="form"`(행 이동 전 상세폼 미저장 확인), `keep-selection="SITE_CD,ACP_SEQ"`, `filterable`, `rowStatus=false`, `clearFilterOnSearch`, 순번 헤더 `labels.SEQ`, `ext-object-type="TCSB_ACP_DTLS"`

| 순서 | 헤더 | 필드 | 타입 | 폭 | 정렬 | 비고 |
|---|---|---|---|---|---|---|
| 1 | 선택 | `DUM_CHK` | check | 50 | center | 유일한 편집 칸, `headerCheck`, `noChanged`, 1/0 |
| 2 | 접수순번 | `ACP_SEQ` | number | 70 | right | |
| - | 접수번호 | `ACP_NO` | text | 110 | center | 숨김 |
| 3 | 독촉 | `C_CNT` | number | 50 | center | 3 이상이면 빨강·굵게(`sheet1C_CNTFormula`) |
| 4 | 접수일자 | `ACP_DT` | date | 95 | center | format ymd |
| 5 | 진행상태 | `PRGS_STATS` | select | 80 | center | 코드그룹 `CS54` |
| 6 | 동 | `BL` | text | 55 | center | |
| 7 | 호 | `RM` | text | 55 | center | 여기까지 고정영역 |
| - | 긴급 | `UY_YN` | check | 50 | center | 숨김 |
| - | 시설구분 | `FAC_DIV` | select | 60 | center | 숨김, `CS71` |
| 8 | 휴대폰번호 | `MP_NO` | text | 105 | center | format phone, 개인정보 마스킹(`0*******2`), QLT 모드 숨김 |
| 9 | 공종 | `CTP_2NM` | text | 150 | left | 중공종명 |
| 10 | 접수내용 | `ACP_CTS` | text | 200 | left | |
| 11 | 완료여부 | `CMPL_YN` | check | 60 | center | `CMPL_DT` 유무로 서버가 산출 |
| 12 | 완료일자 | `CMPL_DT` | date | 95 | center | |
| 13 | 등록일자 | `IPT_DT` | date | 95 | center | `ins_datetime` 의 YYYYMMDD |
| 14 | 접수처 | `ACPLC` | text | 70 | center | |
| 15 | 접수자 | `RECEP_NM` | text | 100 | center | |
| - | 숨김 | `SITE_CD`·`CUST_NM`·`TEL_NO`·`REQ_PSN_NM`·`RECEP_ID`·`NA_RSN` | | | | |

- 그리드 헤더 도구: `AddButton`(추가) · `DeleteButton`(삭제). GridPanel 내장 add/delete prop 은 쓰지 않음 — 추가는 상세폼 신규 모드 진입, 삭제는 상세 저장 API 의 D 처리
- 선택 축(`selection`)과 일괄선택 축(`DUM_CHK`)은 독립. 출력·예약일괄은 `DUM_CHK=1` 행 기준
- 행 선택 → `loadDetail` → 상세(`get_Form`)·사진상태(`get_Atfl`) 동시 조회. 필터행·헤더행(`_kind`) 선택은 무시
- 조회 후 포커스: 이전 선택 행 유지, 없으면 첫 행(프레임워크 `grid.select.first`)
- 정렬(서버): 접수일자 내림 → 동 좌패딩 4자리 → 호 좌패딩 10자리 → 접수순번 내림

## 6. 상세내용 폼 (`form` 모델, FormPanel 2열)

### 6.1 필드 목록 (화면 순서)

| 라벨 | 필드 | 컴포넌트 | 필수 | 잠금·표시 조건 |
|---|---|---|---|---|
| 접수일자 | `ACP_DT` + `SPCL_MNG_OBJ` | `DatePicker`(120, `minDate=acpMinDate`) + `Check` "특별관리대상"(1/0) | 필수 | 접수일자는 기존 행이면 항상 잠금(`acpBlRmReadonly`), 특별관리대상은 잠그지 않음 |
| 접수자 | `ACPLC` / `RECEP_NM` | `InputText` 2개 disabled (40 / 80) + [독촉] 버튼 + "독촉: N회" 텍스트 | | 독촉 버튼·텍스트는 AS 모드만 |
| 동/호 | `BL` / `RM` | `CsSiteBlFinder` + `CsSiteRmFinder` (single) | 필수 | 기존 행이면 잠금(`acpBlRmReadonly`) |
| (라벨 없음) | - | [평면도] 버튼(hover 시 360×270 썸네일 미리보기) + [3D 도면] 버튼 | | 평면도: `FLR_PLAN_YN='1'` 인 데이터행 선택 시 활성, 3D: `form.SITE_CD` 있을 때 |
| 요청자 | `REQ_PSN_NM` | `InputText` maxByte 50 | 필수 | QLT 모드는 colspan 2 |
| 등록 | `ACP_AUTO_REG_YN` + `OWN_DIV` | `Checkbox`(1/0) + `Select` `CS04`(120) | | QLT 숨김, 소유구분은 체크 시에만 표시, 체크박스 잠금은 `autoRegDisabled` |
| 연락처 | `MP_NO` / `TEL_NO` | `InputMask` `999-9999-9999`(48%) + `InputText` maxLength 30(48%) | AS·BF 필수(휴대폰) | QLT 숨김, 변경 시 휴대폰 형식 검사 |
| 입주일자 | `MIBL_DT` | `DatePicker`(120) | | QLT 숨김 |
| 공종검색 | `CTP_SEARCH_CD` / `CTP_SEARCH_NM` | `CsSchCtpFinder` (params `siteCd`) | | 선택 시 협력업체·공종·하자유형 3단까지 채움 |
| 협력업체 | `CUST_CD` / `CUST_NM` | `CsCoFinder` (params `SITE_CD`) | 필수 | 선택 시 공종 1·2단 채움, 하자유형은 비움 |
| 공종 | `CTP_1NM` / `CTP_2NM` | `InputText` 2개 disabled | | 표시 전용 |
| 하자유형 | `ASTYPE_3` | `Select`(150, lookup `asTypeList`) | 필수 | 옵션이 선택 안내 1건뿐이면 disabled |
| 공간/부위 | `SPACE_CD`·`SPACE_NM` / `PART_CD`·`PART_NM` | `CsSpaceCdFinder` + `CsPartCdFinder` | 필수 | AS 모드 colspan 1, 그 외 2 |
| 관리연차 | `TMYER` | `Select` `CS07`(125) | | AS 모드만 표시, 신규 작성 중 disabled(서버가 산출) |
| 직영/긴급/반려 | `DCTL_YN` / `UY_YN` / `RSTOR_YN` | `Select` 3개(81, 예/아니오) | | 반려는 항상 disabled |
| 접수구분 | `ACP_DIV` / `ACP_STP` | `Select` `CS09` + `Select` `CS10`(각 125) | 필수 | 둘 다 disabled(신규 시 CS0901 / 모드값 자동) |
| 시설구분 | `FAC_DIV` | `Select` `CS71`(125) | | 토목(CS7102)이면 colspan 1, 아니면 2. 비우면 서버 설정값 |
| 발주처/공문번호 | `CVL_CLIENT_NM` / `CVL_DOC_NO` | `InputText` 2개(maxByte 100/50) | | 시설구분=토목일 때만 표시 |
| 미해당 사유 | `NA_RSN` | `InputText` disabled, colspan 2 | | 값이 있을 때만 표시 |
| 접수내용 | `ACP_CTS` | `Textarea` maxByte 4000, 높이 85, colspan 2 | 필수 | |
| 콜센터주의사항 | `CC_RMKS` | `Textarea` maxByte 1000, 높이 65 | | AS 모드만 |
| 비고 | `RMKS` | `Textarea` maxByte 4000, 높이 65 (AS) / 85·colspan 2 (그 외) | | |
| 진행상태 | `PRGS_STATS` | `Select` `CS54`(100) | | |
| 공종이관상태 | `CTPTCTL_STATS` | `Select` `CS50`(100) disabled | | |
| 예약일자 | `BKING_DT` | `DatePicker` | | |
| 예약시간 | `BKING_TM` + [알림] | `InputMask` `99:99`(50) + 버튼 | | 알림: 예약일자·시간 있고 미완료일 때 활성 |
| 완료일자 | `CMPL_DT` | `DatePicker`(120) | | QLT 는 `minDate=ACP_DT` |
| 임의종결 | `OPTL_TRMN_YN` | `Select`(70, 예/아니오) | | |

숨김 보관 필드: `SITE_CD`, `ACP_SEQ`, `AS_TP`, `ATFL_GRP`(평면도 파일그룹), `SHR_PRTL_YN`(공유부), `COP_CO_SEQ`, `CTP`, `CTP_NM`, `CTP_1~3`, `ASTYPE_1~2`, `CMPL_REQ_DT`, `RECEP_ID`, `C_CNT`, `NA_DT`, `NA_NOTI_DT`, `INFO_TXT`(머리줄 "신규작성" 표시), `completed`(완료 판정)

### 6.2 사진상태 패널 (`form2`)

| 행 | 근경사진 | 원경사진 |
|---|---|---|
| 처리 전 | `ACTBEF_PHOTO1_NM` | `ACTBEF_PHOTO2_NM` |
| 처리 후 | `ACTAFT_PHOTO1_NM` | `ACTAFT_PHOTO2_NM` |
| 서명/완료확인서 | `SGN_FILE_NM` | `AFT_PHOTO_NM` |

- 각 칸은 readonly `InputText`(50%), 더블클릭 시 사진등록 다이얼로그 열림

### 6.3 상태 판정식 (파생값, 상태 변수로 두지 않음)

| 이름 | 식 | 쓰는 곳 |
|---|---|---|
| `formReadonly` | 신규 작성 중이면 false, 선택 행 없으면 true, 그 외 `form.completed` | 상세폼 전체 잠금 |
| `acpBlRmReadonly` | `!vm.isNew('form')` | 접수일자·동·호 |
| `completed` | `CMPL_DT` 있음 또는 `OPTL_TRMN_YN='1'` (상세 조회 시 1회 확정) | 반려·독촉·알림·확인요청·재분류 |
| `stepEditable` | 점검단계 행의 `AS_EDIT_YN !== 'N'` (BF=`BF_EDIT_YN`, QLT·HWF=`QLT_EDIT_YN`) | 추가·세대복사 |
| `acpMinDate` | 점검단계 행의 `AS_MNG_DT` (BF=`MIBL_BF_CHK`, QLT=`QLT_CHK_DT`) | 접수일자 하한 |
| `isNewForm` | `vm.isNew('form')` | 신규 중 비활성 버튼 |
| `dataRowSelected` | 선택 행이 있고 필터·헤더 행이 아님 | 접수건 대상 버튼 |
| `hasFloorPlan` | `dataRowSelected` 이고 `FLR_PLAN_YN='1'` | 평면도 |
| `autoRegDisabled` | 접수단계 CS1001·CS1004 이거나, `SHR_PRTL_YN !== 'N'` 이거나, 완료일자 있음 | 등록 체크박스 |
| `photoReadonly` | 완료일자 있음 | 사진 슬롯 |
| `dunningText` | `C_CNT>0` 이면 "독촉: N회" | 독촉 옆 텍스트 |
| `sheet1Title` | AS=`AS_MGMT`, BF=`PRE_INSP`, QLT=`QUALITY_INSP`, HWF=`CS_CHK_LIST_HWF` | 그리드 제목 |

### 6.4 값 연동 (watch)

- `form.BL` 변경 → `RM`·`REQ_PSN_NM`·`MP_NO`·`TEL_NO` 비움
- `form.CUST_CD` 비워짐 → 공종(`CTP*`)·하자유형(`ASTYPE_1~3`) 비움
- `form.ACP_AUTO_REG_YN` = '1' → `OWN_DIV='CS0401'`(자가), 해제 → '' (QLT 제외)
- `form.PART_CD` 입력 + 신규 + 협력업체 비어 있음 + 공간 있음 → `/csc/getFrm_CtpMatch` 조회, 후보 1건이면 협력업체·공종·하자유형 자동 채움 후 토스트 `CS_CTP_MATCH_APPLIED`
- 호 선택(`cfd_SiteRm`) → `RM`·`MP_NO`·`TEL_NO`·`RMKS`·`REQ_PSN_NM`(=`MIBL_PSN`)·`SHR_PRTL_YN`·`SPCL_MNG_OBJ` 채움, 공유부(`Y`)면 등록 체크 해제
- 하자유형 옵션: `/csz/codeLookup`(group `CS_TP`, level 3) 전체를 받아 `parentCode === form.ASTYPE_2` 로 거름

구현 주의: 폼 일부 값을 바꿀 때 `vm.set('form.X')` 를 쓰면 신규 표식이 풀려 잠금이 뒤집힘 — `vm.apply('form', {...})` 사용. 서버 값 주입·세대복사는 `{ silent: true }` 로 watch 연쇄를 막음.

## 7. 버튼과 활성 조건

### 7.1 TitleBar

| 버튼 | 라벨 키 | 활성 조건 | 동작 |
|---|---|---|---|
| 예약 일괄등록 | `BKING_BATCH` | 데이터행 선택, QLT 숨김 | 미저장이면 `CS_SAVE_FIRST`, 체크행 없으면 `CS_SELECT_BATCH_HHLD` → 예약 일괄등록 다이얼로그 |
| 출력옵션 | `PRINT_OPTION` | 조회 완료 & 신규 아님, `authLevel="2"` | 옵션 조회 후 다이얼로그 |
| 완료확인서출력 | `CMPL_CONF_PRINT` | 데이터행 선택 & 신규 아님 | 체크행 중 완료건 필요 → 출력이력 저장 → 리포트 `CS_WRK_CMPL_CNFSH_R01` |
| 작업지시서출력 | `WORK_ORDER_PRINT` | 데이터행 선택 & 신규 아님 | 출력이력 저장 → 리포트 `CS_WRK_IDC_R01` |
| 세대정보 | `HHLD_INFO` | 조회 완료 | `app.open('cs_hhldInfo')` 새 탭 |
| 엑셀업로드 | `BTN_EXL_UPLD` | 조회 완료 | 현장 필수, 미저장 시 `CS_UNSAVED_SAVE_FIRST2` → `app.openSub('cs_chkDtlsBlkReg', …)` 같은 탭 전환 |
| 사전방문 예약 | `CS_VISIT_RSV` | BF 모드만 표시 | `app.open('cs_visitRsv')` |
| 저장 | SaveButton | `searchGate`(조회 완료 후) | `saveDetail` |
| 조회 | TitleBar `search` | 항상 | `onSearch` |

엑셀업로드 전달값: `P_SITE_CD`, `P_SITE_NM`, `P_ACP_DIV='CS0901'`, `P_ACP_STP`(모드값), `P_TCTL_YN='0'`, `P_OPEN_ID='cs_csChkMng'`, `fstrAll`(조회조건 쿼리문자열). 복귀는 대량등록 화면의 목록 버튼 → `app.closeSub`.

출력 공통 검사: 목록 0건 `CS_NO_LIST`, 미저장 `CS_SAVE_FIRST`, 체크행 없음 `CS_SELECT_PRINT_ITEM`. 리포트 인자 `{ SITE_CD, ACP_SEQ_LIST }`, 창 1200×800.

### 7.2 그리드 헤더

| 버튼 | 활성 조건 | 동작 |
|---|---|---|
| 추가 | 조회 완료 & `stepEditable` & 신규 아님 | 미저장 확인(`WRN003`) → 현장명 필수 → `newForm()` 으로 신규 모드 |
| 삭제 | 조회 완료 | 신규 중이면 상세 원복, 아니면 `CS_CONFIRM_DELETE` 확인 후 `set_Form1('D')` |

신규 초기값(`newForm`): `INFO_TXT=신규작성`, `SITE_CD=현장`, `ACP_DT=오늘`, `ACP_DIV='CS0901'`, `ACP_STP='CS1003'`(AS), `DCTL_YN/UY_YN/RSTOR_YN/OPTL_TRMN_YN='0'`

### 7.3 상세 머리줄

| 버튼 | 활성 조건 | 동작 |
|---|---|---|
| 이력정보 | 데이터행 & 신규 아님, QLT 숨김 | 이력정보 다이얼로그 |
| 공종이관 | 데이터행 & 신규 아님, QLT 숨김 | 미저장 시 `CS_UNSAVED_SAVE_FIRST` → 공종이관 다이얼로그 |
| 사진등록 | 데이터행 & 신규 아님 | 사진등록 다이얼로그 |
| 세대복사 | 데이터행 & `stepEditable` & 신규 아님 | 신규 모드 + 선택행의 `SITE_CD·BL·RM·REQ_PSN_NM·TEL_NO·MP_NO` 복사 |
| 반려 | `completed` | `CS_CONFIRM_REJECT` 확인 → `/csc/setFrm_CsMngReturn` → 상세 재조회 |
| 확인요청 | 데이터행 & 신규 아님 & 미완료 | 미저장 검사 → 확인요청 다이얼로그 |
| 재분류 | 데이터행 & 신규 아님 & 미완료 | 미저장 검사 → 재분류 다이얼로그 |
| 미해당 처리 | 데이터행 & 신규 아님 | 미저장 검사 → 미해당 다이얼로그 |
| 토목 처리주체 | 시설구분=CS7102 일 때 표시, 조회 완료 | 후보 조회 후 다이얼로그 |

반려 버튼은 완료건에서 열려야 하므로 Field 안이 아니라 FormPanel `Tools` 에 둔다(폼 잠금 전파 회피).

### 7.4 필드 내 버튼

| 버튼 | 활성 조건 | 동작 |
|---|---|---|
| 독촉 | 데이터행 & 미완료, AS 모드만 | `CS_CONFIRM_DUNNING` → `/csc/setFrm_BlrmHstDunning` → 목록 `C_CNT+1`(updateSilent) → 상세 재조회 |
| 평면도 | `hasFloorPlan` | `/sys/attached-file/file-link`(fileGroupId `cs_sitSpacePartCd`, uploadId `ATFL_GRP`) 원본을 700×500 새 창 |
| 3D 도면 | `form.SITE_CD` 있음 | `/cs-model/{siteCd}.glb` HEAD 확인 → 있으면 `/cs-model/model-viewer.html?model=…&site=…`, 없으면 같은 창에 평면도 |
| 알림 | 예약일자·시간 있음 & 미완료 | 미저장 검사 → `CS_CONFIRM_SEND_RESV` → `/csc/setFrm_BkingSend` → 응답 문자열이 있으면 그 사유, 없으면 `CS_RESV_NOTI_SENT` → 재조회 |

새 창은 클릭과 같은 틱에 빈 창을 먼저 열고 주소를 나중에 넣어 팝업 차단을 피한다.

## 8. 다이얼로그

| 다이얼로그 | 크기 | 구성 | 저장 API |
|---|---|---|---|
| 출력옵션 | 300px | 3열: 작업지시서-요청자 / 완료확인서-요청자·일자 (출력/미출력) | `/csc/setFrm_AsAcpRptOptn` (SaveButton confirm `CS_CONFIRM_SAVE_PRINT_OPT`) |
| 예약 일괄등록 | 320px | 예약일자(DatePicker) · 예약시간(`99:99`, 기본 1200) | `/csc/setGrd_BkingReg` `{wrkDiv:'U', dBkingDt, dBkingTm, rows}` → 재조회 |
| 공종이관 | 1400×480 | 툴바 [추가][저장][반려][승인] + 그리드(8.1) | `/csc/setGrd_CtpHst`, 승인·반려 `/csc/setGrd_CtpHstW` |
| 이력정보 | 1400×480 | 툴바 [전체이력 체크][조회][추가][저장] + 그리드(8.2) | `/csc/setGrd_BlrmHst` |
| 사진등록 | 1350px | 2단 머리글 표: 처리 전(근경·원경) · 처리 후(근경·원경) · 서명 · 완료확인서 = `ErpPhotoSlot` 6칸 | `/csc/setFrm_PhotoList` |
| 확인요청 | 420px | 변경사유 Textarea(maxByte 1000) | `/csc/setFrm_AcpCnfReq` |
| 재분류 | 720px | 공간/부위, 공종검색, 협력업체(표시), 하자유형, 변경사유 + 분류변경이력 그리드(높이 180) | `/csc/setFrm_AcpReclass` |
| 미해당 처리 | 480px | 미해당 사유, 안내일자(표시) · [저장][미해당 안내][미해당 완료] | `setFrm_AcpNaSave` · `setFrm_AcpNaNotice` · `setFrm_AcpNaComplete` |
| 토목 처리주체 | 760px | 후보 그리드(업체·계약명·보증시작/종료·보증유효·거래상태·전화) + [확인] | 저장 없음, 상세 협력업체에 반영 |
| MMS | 450px | 메시지·문의전화·수신번호 | `/csc/setFrm_AsMngMms` (현재 여는 버튼 없음, AS-IS 에서도 주석 처리) |

### 8.1 공종이관 그리드 (`ctpTransferStore`, key `CTP_SEQ`)

| 헤더 | 필드 | 편집 | 비고 |
|---|---|---|---|
| 선택 | `CHECKBOX` | O | noChanged |
| 신청업체 | `CONT_CO_CUST_NM` | | |
| 공종명 | `CTP_NM` | | |
| 하자보수유형 | `AS_TP` | | 공통코드 매핑 금지(공종트리 값) |
| 신청일자 | `CTPTCTL_DT` | O | |
| 내용 | `CTPTCTL_CTS` | O | textarea, maxLength 1000 |
| 변경업체 | `CHG_CO_CUST_NM` + 돋보기 버튼(`_BTN`) | O, 필수 | `csCo` 파인더 |
| 공종명 | `CHG_CTP_NM` | | |
| 하자보수유형 | `CHG_AS_TP_NM` + 돋보기 버튼(`_BTN`) | O, 필수 | `csTp` 파인더(`HRNK_CD=CHG_MCTP`) |
| 승인일자 | `CHG_DT` | | |
| 진행상태 | `CTPTCTL_STATS` | | `CS50` (요청 CS5001 / 승인 CS5002 / 반려 CS5003) |

- 편집 게이트: 진행상태 CS5002(승인) 행은 편집 불가
- 추가: 상세폼 값으로 신규행(신청일자=오늘, 상태=CS5001)
- 추가·저장: 완료건(`form.CMPL_DT`)이면 비활성
- 승인·반려: 선택행 상태가 CS5001 이고 미완료일 때, `authLevel="2"`. 승인은 체크행의 변경업체·변경유형 필수(`CS_CHG_CO_TYPE_REQUIRED`)
- 변경업체명·유형명을 사용자가 직접 고치면 딸린 코드(`CHG_*`) 비움
- 닫을 때 목록 해당 행 재조회

### 8.2 이력정보 그리드 (`historyStore`, key 미선언)

| 헤더 | 필드 | 편집 | 비고 |
|---|---|---|---|
| 삭제 | `CHK_DEL` | 완료 이력행 제외 | headerCheck, noChanged |
| 동 / 호 / 접수일자 / 접수내용 | `BL`·`RM`·`ACP_DT`·`ACP_CTS` | | |
| 분류 | `HST_DIV` | O, 필수 | `CS52` |
| 등록일자 | `HST_DT` | O, 필수 | |
| 내용 | `HST_CTS` | O, 필수 | maxLength 500 |
| 비고 | `RMKS` | O | maxLength 100 |
| 완료 | `CMPL_YN` | | 1 이면 행 편집 불가 |

- 전체이력 체크(`allRecYn`) 변경 시 재조회(`chkYn` 으로 전달)
- 추가: 선택 이력행(없으면 목록 선택행)의 접수 정보를 복사한 신규행
- 저장 행 구성: 삭제 체크된 기존행 D, 삭제 체크 안 된 신규행 C, 수정행 U(단 `HST_SEQ` 가 비어 있으면 C)
- 이력 PK: `SITE_CD + ACP_SEQ + HST_SEQ`

### 8.3 사진 6채널

| 필드 | 슬롯 | 파일그룹 | 의미 |
|---|---|---|---|
| `ACTBEF_PHOTO1` | p1 | `cs_csChkMng_1` | 처리 전 근경 |
| `ACTBEF_PHOTO2` | p2 | `cs_csChkMng_2` | 처리 전 원경 |
| `ACTAFT_PHOTO1` | p3 | `cs_csChkMng_3` | 처리 후 근경 |
| `ACTAFT_PHOTO2` | p4 | `cs_csChkMng_4` | 처리 후 원경 |
| `SGN_FILE` | p5 | `cs_csChkMng_5` | 서명 |
| `AFT_PHOTO` | p6 | `cs_csChkMng_6` | 완료확인서 |

- 열 때 슬롯별 `/sys/attached-file/files` 조회 → `app.fileStore` 생성
- [저장] 시 보류 파일을 `__photoFiles` 로 함께 전송, 활성 파일이 없으면 컬럼 '' 저장, 파일스토어가 없는 구데이터 슬롯은 원값 유지
- 완료건은 슬롯 disabled
- 닫을 때 사진상태(`get_Atfl`) 재조회

## 9. 저장 흐름 (상세)

화면 검사(`saveDetail`)

1. 필수값 일괄 검사 후 한 번에 알림(`CS_REQUIRED_ITEM`), 닫힌 뒤 첫 빈칸 포커스
   - 순서: 접수일자 → 동 → 호 → 요청자 → 휴대폰번호(QLT 제외) → 협력업체 → 하자유형 → 공간 → 부위 → 접수구분 → 접수내용
2. 접수일자 < `acpMinDate` 이면 `CS_CHKMNG_ACP_AFTER_AS`(BF/QLT 별도 메시지)
3. QLT 모드만: 접수일자 > 완료일자이면 `CS_CHKDTLSBLKREG_CMPL_DT_BEFORE_ACP`
4. `set_Form1(I 또는 U)`

전송값 변환(`set_Form1`)

- `ACTION`(I/U/D), `SITE_CD`=조회 현장, `PAGE_ID`
- 읽기 별칭 → DB 컬럼 복원: `LCTP=CTP_1`, `MCTP=CTP_2`, `SCTP=CTP_3`, `AS_TP=ASTYPE_3`, `CONT_CO_CUST_CD=CUST_CD` — 쓰기 매퍼가 조건 없이 SET 하므로 누락 시 컬럼이 NULL 로 덮임
- 날짜 `ACP_DT`·`MIBL_DT`·`BKING_DT`·`CMPL_DT` 는 `YYYYMMDD`, 빈 값은 반드시 `null`('' 저장 시 완료 판정이 뒤집힘)
- 삭제(D)는 `*` 가 든 개인정보 칸을 본문에서 제거(코어 `MaskedPrivacyInputGuard` 회피)

서버 처리(`/csc/setFrm_CsChkMngDtl` → AS 는 `AsAcpDtlsService.saveAsAcp`)

| 단계 | 내용 | 오류 코드 |
|---|---|---|
| 필수 | 현장·접수일자·동·호·접수내용 | `CSB_AS_ACP_*_REQUIRED` |
| 일정 | 신규만: A/S관리 점검일정 미등록 차단 | `CSB_AS_ACP_SCHEDULE_NOT_REGISTERED` |
| 기간 | 신규만: 접수일자가 AS관리 시작일 이전이면 차단 | `CSB_AS_ACP_NOT_IN_PERIOD` |
| 일자 | 접수일자 > 완료일자 차단 | `CSB_AS_ACP_DATE_INVALID` |
| 세대 | 신규만: 동·호 세대정보 없으면 차단 | `CSB_AS_ACP_HHLD_NOT_FOUND` |
| 연차 | 보증개시일 → 준공일 다음날 → 세대 기준일 순으로 기준일 산출 후 관리연차 `CS0701~CS0706` 계산 | |
| 채번 | 신규: 현장 잠금 후 현장별 `MAX(ACP_SEQ)+1`, 접수처는 설정(`intake.center-user-prefix`)으로 판정, 접수번호(`ACP_NO`) 채움 | |
| 분기 | I=INSERT(반환 신규순번) / U=UPDATE(반환 0) / D=논리삭제 `DEL_YN`(반환 -1) | |
| 세대이력 | I·U 이고 등록 체크 시 세대이력(TCSA_HHLD_HST) 중복 없을 때 INSERT, 새 행만 자동등록 유지 | |
| 부가속성 | `CsIntakeService.saveDetailAttrs`: 시설구분(빈 값이면 설정 기본값), 토목일 때만 발주처·공문번호 | |

저장 후 반영(`refresh_Sheet1`)

- 반환 -1(삭제) → 전체 재조회
- 반환 0(수정) → `/csc/getGrd_CsChkMng` 로 해당 행만 받아 `updateSilent` 반영 후 상세·사진 재조회
- 신규순번 → 목록에 없으므로 `pinSelection` 으로 새 행 지정 후 전체 재조회
- 재조회 완료 후 `acceptChanges()` 로 dirty 기준점 재설정(실패 시 호출 안 함)

## 10. API 목록

| URL | 용도 | 요청 | 응답 |
|---|---|---|---|
| `/csc/getGrdMlt_CsChkMngList` | 목록 + 점검단계 | search 전체 + `csAcpStp`·`pageId` | `{ibSheet2: 점검단계 1행, ibSheet1: 목록}` (`target` 매핑) |
| `/csc/getGrd_CsChkMng` | 목록 1행 재조회 | `siteCd`, `acpSeq` | 1행 |
| `/csc/getFrm_CsChkMngDtl` | 상세 | `siteCd`, `acpSeq` | 1행(날짜 YYYYMMDD) |
| `/csc/getFrm_CsChkMngAtfl` | 사진상태 | `siteCd`, `acpSeq` | 6채널 키·파일명 |
| `/csc/getFrm_CsBlList` | 현장 동 목록 | `csSiteCd` | `COM_CD`, `COM_NM` |
| `/csc/getFrm_AsAcpRptOptn` · `/csc/setFrm_AsAcpRptOptn` | 출력옵션 조회·저장 | `csSiteCd` / `siteCd`+3옵션 | |
| `/csc/setFrm_CsChkMngDtl` | 상세 저장 | 폼 전체 + `ACTION`·`PAGE_ID` | 신규순번 / 0 / -1 |
| `/csc/setFrm_CsMngReturn` | 반려 | `siteCd`, `acpSeq` | `RSTOR_YN='1'`, `CMPL_DT=NULL`, `PRGS_STATS='CS5401'` |
| `/csc/setGrd_AsOpt` | 출력이력 | `{rows:[{SITE_CD, ACP_SEQ}]}` | |
| `/csc/setFrm_BlrmHstDunning` | 독촉 | `siteCd`, `acpSeq` | 이력 `HST_DIV='CS5203'` 자동 등록 |
| `/csc/setFrm_BkingSend` | 예약 알림톡 | `siteCd`, `acpSeq` | 미발송 사유 문자열(빈 값=발송) |
| `/csc/setGrd_BkingReg` | 예약 일괄 | `wrkDiv`, `dBkingDt`, `dBkingTm`, `rows` | |
| `/csc/getGrd_CtpHst` · `/csc/setGrd_CtpHst` · `/csc/setGrd_CtpHstW` | 공종이관 조회·저장·승인/반려 | 선택행 / `rows` / `wrkDiv`(CMPL·REJECT)+`rows` | |
| `/csc/getGrd_BlrmHst` · `/csc/setGrd_BlrmHst` | 이력정보 | 선택행+`allRecYn` / `rows` | |
| `/csc/setFrm_PhotoList` | 사진 저장 | 6채널 키 + `__photoFiles` | |
| `/csc/setFrm_AsMngMms` | MMS | `subject`, `msg`, `key`, `rcvMpNo`, `sndTelNo` | |
| `/csc/setFrm_AcpCnfReq` | 확인요청 | `SITE_CD`, `ACP_SEQ`, `CHG_RSN` | `PRGS_STATS='CS5465'`, 분류이력 기록 |
| `/csc/setFrm_AcpReclass` · `/csc/getGrd_AcpClsHst` | 재분류·분류이력 | 키 + 재분류값 | 확인요청 상태였으면 접수(CS5401)로 복귀 |
| `/csc/setFrm_AcpNaSave` | 미해당 저장 | 키 + `NA_RSN` | `PRGS_STATS='CS5467'`, `NA_DT=오늘` |
| `/csc/setFrm_AcpNaNotice` | 미해당 안내 | 키 | `NA_NOTI_DT`, 이력 `CS5265` |
| `/csc/setFrm_AcpNaComplete` | 미해당 완료 | 키 | 미해당 상태 필수, 입주 세대는 완료확인서(`AFT_PHOTO`) 필수, `CMPL_DT=오늘` |
| `/csc/getGrd_CivilOwner` | 토목 처리주체 후보 | `siteCd`, `MCTP` | |
| `/csc/getFrm_CtpMatch` | 공간·부위 → 하자분류 매칭 | `siteCd`, `spaceCd`, `partCd`, `bl`, `rm` | |
| `/csz/codeLookup` | 하자유형 코드 | `workType:'CS'`, `group:'CS_TP'`, `level:3` | |
| `/sys/attached-file/files` · `/sys/attached-file/file-link` | 첨부·평면도 | `fileGroupId`, `uploadId` | |

- 모든 API 는 POST, 컨트롤러 메소드는 `@Auth`
- H사 확장 API(확인요청·재분류·미해당)는 완료건(`CMPL_DT` 있음)이면 `CS_ACP_ALREADY_CLOSED` 로 거부

## 11. 목록 조회 SQL 요지 (`selectCsChkMngList`)

- 주 테이블 `VPLUS40.TCSB_ACP_DTLS A`
- 조인: `TCOA_TRADE`(업체명) · `TCSA_BCTY_COPCO`(협력업체-공종) · `TCSB_BLRM_HST`(독촉 `HST_DIV='CS5203'` 건수) · `TCSA_CTP`×2(대·중공종명) · `TCSA_HHLD_INFO`(입주일자) · `TCSA_EXCSZ_TY`(평면도 `ATFL_GRP`) · `TCOZ_USR_INFO`(접수자명)
- 접수단계 조건: AS 모드는 `ACP_STP IN ('CS1002','CS1003')` (사전점검 건 포함), QLT/BF/HWF 는 해당 단계 1개
- `DEL_YN = '0'` 행만
- 완료 조건: 예=`CMPL_DT IS NOT NULL OR OPTL_TRMN_YN='1'`, 아니오=`CMPL_DT IS NULL AND OPTL_TRMN_YN='0'`
- 협력업체 조건: 협력사순번·공종이 있으면 `TCSA_BCTY_COPCO` 기준, 없으면 `CONT_CO_CUST_CD` 문자열 비교
- 호 조건은 `LIKE`
- MSSQL 은 `OPTION (RECOMPILE)` (전체 기간 20만 행 조회 17.9초 → 2.3초 실측)
- 점검단계(`selectChkStep`): `TCSA_SITE_INFO` + `TCSA_CHK_SCH` 의 `QLT_CHK_DT`·`MIBL_BF_CHK`·`AS_MNG_DT`, 편집가능여부(`*_EDIT_YN`)는 서비스가 계산

## 12. 관련 테이블

| 테이블 | 용도 |
|---|---|
| `TCSB_ACP_DTLS` | 하자 접수 본체(사진 6채널 컬럼 포함) |
| `TCSB_BLRM_HST` | 동호 이력(독촉·미해당 안내 등) |
| `TCSB_CTP_HST` | 공종이관 이력 |
| `TCSB_ACP_CLS_HST` | 분류 변경 이력(확인요청·재분류) |
| `TCSA_CHK_SCH` | 현장 점검일정(AS관리 시작일) |
| `TCSA_SITE_INFO` | 현장(출력옵션 포함) |
| `TCSA_HHLD_INFO` · `TCSA_HHLD_HST` | 세대정보 · 세대이력 |
| `TCSA_EXCSZ_TY` | 평형 타입(평면도 첨부) |
| `TCSA_BCTY_COPCO` · `TCOA_TRADE` · `TCSA_CTP` | 협력업체·거래처·공종 |

모든 업무 테이블은 스키마 `VPLUS40`.

## 13. 코드 그룹

| 그룹 | 용도 | 값 |
|---|---|---|
| `CS04` | 소유구분 | CS0401 자가, CS0402 세입 |
| `CS07` | 관리연차 | CS0701~CS0705 1~5년차, CS0706 10년차 |
| `CS09` | 접수구분·검사구분 | CS0901 수시점검, CS0902 연차점검 |
| `CS10` | 접수단계 | CS1001 품질점검, CS1002 사전점검, CS1003 A/S관리, CS1004 주부품질점검 |
| `CS50` | 공종이관 상태 | CS5001 요청, CS5002 승인, CS5003 반려 |
| `CS52` | 이력 분류 | CS5201 방문부재, CS5202 연락두절, CS5203 입주민독촉, CS5204 기타, CS5265 미해당 안내, CS5266 재분류, CS5267 확인요청 |
| `CS54` | 진행상태 | CS5401 접수, CS5402 작업지시, CS5408 완료대기, CS5409 완료, CS5465 확인요청, CS5467 미해당, CS5481 조치예정, CS5482 방문예정, CS5483 방문부재 |
| `CS71` | 시설구분 | CS7101 건축, CS7102 토목 |
| `CS_TP` | 하자유형(3단 트리) | `/csz/codeLookup` level 3 |

## 14. 진입 처리 (onLoad)

- 모드: 서비스 params `PAGE_ID`(`app.page.params`). QLT·HWF·BF·AS 외 값은 AS 로 정규화
- 호출측 진입값은 `app.getParams()` 로 받음: `CS_SITE_CD`, `CS_SITE_NM`, `fstrAll`
- `fstrAll`(작업관리 더블클릭 등) 복원 키: `CS_SITE_CD`, `CS_SITE_NM`, `ACP_STR_DT`, `ACP_END_DT`, `SEARCH_RM`, `SEARCH_SUC_YN`, `SEARCH_CUST_CD`, `SEARCH_CUST_NM`, `SEARCH_COP_CO_SEQ`, `SEARCH_CTP`, `SEARCH_CTP_1`, `SEARCH_CTP_2`
- 현장 우선순위: 진입 파라미터 > remember 복원값
- 초기값은 `app.silentSet` 으로 넣어 SearchBar 변경감지를 일으키지 않음
- 초기 조회는 `searchOnLoad` 가 수행(화면에서 직접 호출하지 않음)

## 15. 모드별 차이 요약

| 항목 | AS | BF | QLT·HWF |
|---|---|---|---|
| 목록 접수단계 | CS1002·CS1003 | CS1002 | CS1001 / CS1004 |
| 저장 서비스 | `AsAcpDtlsService` | `AcpDtls02Service` | `AcpDtlsService.saveQltChk` |
| 접수일자 하한 | `AS_MNG_DT` | `MIBL_BF_CHK` | `QLT_CHK_DT` |
| 검사구분 조회조건 | 표시 | 숨김 | 숨김 |
| 독촉·관리연차·콜센터주의사항 | 표시 | 숨김 | 숨김 |
| 휴대폰·입주일자·등록·이력정보·공종이관·예약일괄 | 표시 | 표시 | 숨김 |
| 사전방문 예약 버튼 | 숨김 | 표시 | 숨김 |

## 16. 구현 시 지켜야 할 사항

- 화면 정의 파일은 하나의 객체 식(`({ ... })`)으로 작성, `page.define()` 등으로 감싸지 않음
- 버튼 활성·폼 잠금은 template 표현식과 viewModel getter 로만 표현, `btnXxx` 같은 파생 불리언 상태 변수 금지
- 버튼 핸들러 안에 활성 여부 중복 가드를 두지 않음(`:disabled` 가 이미 막음)
- 미저장 확인은 SearchBar `guard`, GridPanel `guard="form"` 에 맡기고 `onSearch` 에서 다시 하지 않음(확인창 이중 표시 방지)
- 서버 값을 목록에 반영할 때는 `updateSilent`, 상세 로드 직후와 저장 성공 직후 `acceptChanges()` 호출
- 날짜는 화면 `YYYY-MM-DD`, 서버 `YYYYMMDD`, 빈 날짜는 `null`
- 읽기 별칭(`CTP_1/2/3`, `ASTYPE_3`, `CUST_CD`)을 저장 시 DB 컬럼명으로 되돌림
- `ACP_SEQ` 는 숫자 컬럼이므로 필터행·빈 값을 서버로 보내지 않음(`Number.isFinite` 검사)
- 이벤트 바인딩은 `@`, 데이터 바인딩은 `:` (products-erp-h `CLAUDE.md` 규칙), `v-model` 직접 사용 금지
- 라벨·메시지는 `labels.*`·`msgs.*` 키 사용(하드코딩 금지), 새 키는 라벨 시드 3방언 등록 필요
- 화면 수정 전 컴포넌트별 `hmp_spec_query`, `doc_search(repo="hmplus/products-erp")`, `doc_search(repo="hmplus/platform-hmp")` 선행(훅 `lookup_gate` 대상)

## 17. 사용 컴포넌트 목록

- 코어: `VBox`, `HBox`, `TitleBar`, `SearchBar`, `Field`, `GridPanel`, `Column`, `Tools`, `AddButton`, `DeleteButton`, `SaveButton`, `SearchButton`, `CloseButton`, `Button`, `FormPanel`, `Splitter`, `ModalDialog`, `Footer`, `Select`, `InputText`, `InputMask`, `Textarea`, `DatePicker`, `DateRange`, `Check`, `Checkbox`, `Text`, `Box`, `Fragment`, `ImagePanel`
- CS 파인더: `CsSiteStepFinder`, `CsCoFinder`, `CsSiteBlFinder`, `CsSiteRmFinder`, `CsSchCtpFinder`, `CsSpaceCdFinder`, `CsPartCdFinder`
- ERP 공통: `ErpPhotoSlot`
- 파인더 API: `app.openFinder({ type: 'csCo' | 'csTp' })`
- 스타일 클래스: `erp-plan-anchor`, `erp-plan-preview`, `erp-photo-table`·`-th`·`-sub`·`-td`·`-span-c2`·`-span-r2`, `csc-flex1`, `csc-photo-hd`, `csc-photo-nm`, `erp-plaintext`

## 18. 확인 필요 사항

- 등록 체크박스 잠금 조건(`SHR_PRTL_YN !== 'N'` 이면 기존 건 항상 잠금)이 AS-IS 의도인지 부수 효과인지 미확정(소스 주석 「E 의도확인 10」)
- MMS 다이얼로그는 여는 버튼이 없음 — 새 화면에서 노출 여부 결정 필요
- 사진 슬롯의 AS-IS DEXT5 그룹키 구데이터는 표시되지 않음(파일 이관 별건)
- 3D 도면은 `/cs-model/{siteCd}.glb` 가 배치된 현장에서만 뷰어가 열림
