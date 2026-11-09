# 전체 메뉴 트리

> 원본: `products-erp-h/db/common-admin/input/sqlh-service-20261109.psv` (서비스 테이블 추출, 2026-11-09)
>
> 표기: `·` 뒤는 화면 경로. *(숨김)* 은 메뉴 트리에 노출되지 않는 화면, *(사용안함)* 은 사용 중지 메뉴입니다.
> 포함하지 않은 것: SERVER(API), SECTION(구분선), 화면이 하나도 없는 빈 폴더, 권한, 화면 용도. 실행 중인 localhost:8080 과는 대조하지 않았습니다.

요약: 폴더 97 · 화면 408 · 숨김 44 · 사용안함 52

## 목차

- 데이터 표준 — 화면 4개
- 공사 — 화면 1개
- 공통 — 화면 64개
- 대시보드 — 화면 13개
- 하자 — 화면 63개
- 개발프로젝트관리 — 화면 60개
- 개인 — 화면 16개
- 시스템 — 화면 187개
- 상위 메뉴 없음 — 화면 37개

## 데이터 표준

- 데이터 표준 사전 · `system/data-standard`
- 코드 등록 요청 관리 · `system/code-request`
- 코드 등록 요청 · `system/code-request-form`
- 공공 표준 코드 · `system/public-std-code`

## 공사


### 도급기성·원가

- 현장철수계획서 · `cm/plotPln` *(숨김)*

## 공통


### 기초정보관리

- 공통코드 · `co/comCode`
- 거래처관리 · `co/tradeInfo`
  - 협력업체정보 변경승인(GW) · `co/vndrInfoAprvGw` *(숨김)*
  - 거래처등록/수정 · `co/tradeInfo_P01` *(숨김)*
  - 거래처삭제정보관리 · `co/custDelInfo` *(숨김)*
- 사용자정보 · `co/usrMng` *(사용안함)*
- 부서/현장정보 · `co/deptMng`
- 휴일관리 · `co/holidayMng`
- 통화코드관리 · `common/currency`
- 국가코드관리 · `co/ctryCode`
- 법인/회사정보 · `co/corpMng` *(사용안함)*
- 환율정보관리 · `co/fertInfo`
- 은행정보관리 · `common/bank`
- 사용자겸직정보 · `co/deptCrent` *(사용안함)*

### 권한관리

- 권한그룹 · `co/authGrp` *(사용안함)*
- 역할그룹 · `co/roleGrp` *(사용안함)*
- 부서별겸직정보 · `co/deptCriteriaCrent` *(사용안함)*
- 직무연동 · `co/authGrpMapp` *(사용안함)*
- 메뉴권한 · `co/authMnu` *(사용안함)*
- 서비스 관리(모바일) · `role/service` *(사용안함)*
- 대시보드 · `co/dashbrdAuth` *(사용안함)*
- 사용자 · `co/authMapp` *(사용안함)*
- 개인정보 접속이력 · `log/log-privacy`

### 권한이력

- (권한현황) 권한그룹-메뉴권한 · `co/authGrpInfo` *(사용안함)*
- (권한현황) 권한그룹-사용자 · `co/authUsrInfo` *(사용안함)*
- (권한현황) 사용자-권한그룹 · `co/usrAuthInfo` *(사용안함)*
- (변경이력) 사용자 · `log/log-role-grant` *(사용안함)*
- (변경이력) 권한그룹 · `log/log-role-service` *(사용안함)*
- (접속이력) 개인정보 · `log/log-privacy`

### 권한신청

- 전산사용권한신청 · `co/srRequestAuth`
- 전산사용권한신청 상세 · `co/srRequestAuthDtl` *(숨김)*
- 전산겸직신청 · `co/srRequestSBJB`
- 전산겸직신청 상세 · `co/srRequestSBJBDtl` *(숨김)*

### 커뮤니티

- 공지사항 · `co/noticeList`
  - 공지사항 상세 · `co/noticeView` *(숨김)*
  - 공지사항 입력 · `co/noticeWrite` *(숨김)*
- 질문게시판 · `co/qnaList` *(사용안함)*
  - 질문게시판 상세 · `co/qnaView` *(사용안함, 숨김)*
  - 질문게시판 입력 · `co/qnaWrite` *(사용안함, 숨김)*

### 공통기능

- 전표조회 · `co/slipList`
  - 전표조회(GW) · `co/slipListGW` *(사용안함, 숨김)*
- 시스템승인-Dialog · `approval/approval-form`
- 전자메일·SMS-Template · `msg/msg-template`
- 문서양식관리 · `co/elcDoc`
- 전자서명검증 · `co/signValidation`
- 인증서유효기간 · `co/signValidityCheck`
- 문의등록 · `inquiry/inquiry-form`
- 전표조회(팝업) · `co/dsSlipList` *(사용안함, 숨김)*

### 시스템관리

- 결재로그팝업 · `co/aprvLogPop` *(숨김)*
- 결재로그팝업 · `co/aprvLogPop` *(사용안함, 숨김)*
- 메뉴정보 관리 · `co/mnuMng` *(사용안함)*
- 메뉴도움말 관리 · `co/mnuHelpMng`
- 메뉴도움말 팝업 · `co/mnuHelpPop`
- 프로그램 관리 · `role/program`
- 북마크 · `system/favorite` *(사용안함)*
- 북마크관리 · `co/bookMarkMng`
- 에러로그 · `log/log-error`
- 에러로그팝업 · `co/queryPop` *(사용안함, 숨김)*
- 결재로그 · `co/aprvLog`
- 시스템접속로그 · `log/log-login`
- DB객체관리 · `co/dbObject`
- 시스템접근통제 · `system/allowed-ip` *(사용안함, 숨김)*
- 세션모니터링 · `system/user-session` *(사용안함)*
- 메뉴함수 · `co/mnuMethodAuth` *(사용안함)*

## 대시보드

- 경영 현황 · `co/dashBordBM`
  - 매출/매출손익 현황 · `co/dashBordBMPL` *(숨김)*
- 영업 · `co/dashBordSO`
- 분양 · `co/dashBoardDS`
- 임대 · `co/dashBoardRS`
- 예산 · `co/dashBoardCM_1`
- 공사 · `co/dashBoardCM`
- 외주구매 · `co/dashBoardSM`
  - 상세목록 · `co/dashBoardSMDtl` *(숨김)*
- 하자 · `co/dashBoardCS`
- 재무 · `co/dashBoardFI`
- 인사 · `co/dashBoardHr`
- 현장 · `co/dashBoardSite`

## 하자

- 발주 내역 · `cs/ordDtls`

### 일정관리

- 일정관리 · `cs/schMng`

### 기본정보

- 현장정보 · `cs/siteInfo`
- 협력업체정보 · `cs/copCoInfo`

### 하자 등록 및 처리


#### 공통

- 공종코드 · `cs/ctpCd`
- 현장별 공간 부위 코드 · `cs/sitSpacePartCd`
- 담당현장 · `cs/chrSite`
- 기준정보 등록 요청 · `cs/baseCdReq`
- 엔지니어 승인관리 · `cs/mobileUsrAprv`
- 기준정보 등록 승인 · `cs/baseCdReq`
- 모바일사용자 · `cs/mobileUsr`

#### 기초자료

- 점검일정 · `cs/chkSch`
- 공종별협력업체 · `cs/bctyCopCo`
- 세대정보 · `cs/hhldInfo`
- 하자분류 매칭 · `cs/ctpMatch`

#### 준공전품질점검

- 품질점검 · `cs/csChkMng`

#### 입주자사전점검

- 사전점검 · `cs/csChkMng`
- 사전방문 예약 · `cs/visitRsv`

#### 인수인계

- 표준인수인계파일등록 · `cs/tnhFile`
- 현장인수인계요청 · `cs/siteTnhReq`
- 현장인수인계승인 · `cs/siteTnhReq`

#### AS관리

- A/S관리 · `cs/csChkMng`
- 작업관리 · `cs/wrkCmplMng`
- 하자 문자발송 · `cs/csSendSms`
- 분쟁 단지 현황 · `cs/dsptMng`

#### 점검내역대량등록

- 점검내역대량등록 · `cs/chkDtlsBlkReg`

#### 현황조회

- 하자처리현황 · `cs/disComCurst`
- 하자 접수 및 처리대장 · `cs/dealAcp`
- 협력업체별현황 · `cs/byCopCoCurst`
- 협력업체공종별현황 · `cs/byCopCoCtpCurst`
- 유형별현황 · `cs/byTpCurst`
- 공간/부위별 접수처리 현황 · `cs/spaceCurst`
- 현장별 AS접수 통계 · `cs/bySiteAcpStats`
- 공종별 처리현황 · `cs/ctpDiscomCurst`
- 업체별 처리현황 · `cs/cooDiscomCurst`
- 장기 미처리 하자 관리 · `cs/ltrmDefect`
- 하자 통합 분석 · `cs/defectAnalysis`
- 확인점검 결과 대시보드 · `cs/chkDashboard`
- 장기 미처리 공문 결재 · `cs/apprv_LtrmLtr` *(숨김)*

#### [참고]홈페이지 관리 *(사용안함)*

- HP 하자접수 등록 · `cs/hpMng` *(숨김)*

### 하자처리보고

- 하자처리보고서 · `cs/dealRep`
  - 하자처리 등록 · `cs/dealRepDtl` *(숨김)*
- 하자처리보고서 결재 · `cs/apprv_DealRepAprv`
- 발주·정산 품의 · `cs/apprv_OrdAprv` *(숨김)*
- 현장인수인계 결재 · `cs/apprv_SiteTnhInfoAprv`

### 하자보수비

- 비율등록 · `cs/asByyyBgtCd`
- 연도별예산관리 · `cs/asByyyBgt`
- 집행실적관리 · `cs/asSiteCs`
- 비용 집행 · `cs/costClaim`
- 보증금 청구 관리 · `cs/gntClm`
  - 공문 작성 · `cs/gntDocDlg` *(숨김)*

#### 하자전표관리

- 하자전표발행 · `cs/ecstSlp`
- 하자대표현장 대체전표발행 · `cs/csSiteTransferSlpPubc`
- 공동도급안분 · `cs/jonitVenture`

#### 현황조회

- 현장종합 투입금액 · `cs/siteTotCst`
- 자금집계표 · `cs/siteMoneyCst`
- 월별 하자보수비 현황 · `cs/bymAsExpIptCurst`
- 일반관리비 실적 · `cs/generlCst`
- 보증현황 · `cs/sponSionCst`
- 전표조회 · `cs/asSlpCst`
- 협력업체 공지사항 · `cs/jcAnncBrdLst`
  - 공지사항 상세 · `cs/jcAnncBrdDtl` *(숨김)*

### 개발/임시

- 데이타이관(채들) · `cs/transLst` *(숨김)*

## 개발프로젝트관리


### 프로젝트

- 프로젝트 관리 · `devpmo/devpmo-project`
- 프로젝트 대시보드 · `devpmo/devpmo-project-dashboard`
- 공정 작업 · `devpmo/devpmo-project-task`
- 고객 산출물 · `devpmo/devpmo-project-document`

### 대시보드

- PM 대시보드 · `devpmo/devpmo-dashboard-pm`
- PL 대시보드 · `devpmo/devpmo-dashboard-pl`
- 개발자 대시보드 · `devpmo/devpmo-dashboard-developer`
- 품질 대시보드 · `devpmo/devpmo-dashboard-quality`
- 발주처 대시보드 · `devpmo/devpmo-dashboard-client`
- 포트폴리오 · `devpmo/devpmo-dashboard-portfolio`
- PDCA 현황판 · `devpmo/devpmo-dashboard-pdca`

### 조직 관리

- 업무그룹 관리 · `devpmo/devpmo-work-group`
- 인원 관리 · `devpmo/devpmo-member`
- 마일스톤 · `devpmo/devpmo-milestone`
- 투입인력 관리 · `devpmo/devpmo-resource`
- 타임시트 · `devpmo/devpmo-timesheet`
- 휴가/부재 관리 · `devpmo/devpmo-absence`

### 개발 관리

- 서비스 현황 · `devpmo/devpmo-service-status`
- 이슈 관리 · `devpmo/devpmo-issue`
- 변경 이력 · `devpmo/devpmo-change-log`

### 요구사항

- 요구사항 관리 · `devpmo/devpmo-requirement` *(숨김)*
- 요구사항 추적 · `devpmo/devpmo-req-trace`
- RTM 매트릭스 · `devpmo/devpmo-rtm-matrix`

### 테스트

- 테스트 계획 · `devpmo/devpmo-test-plan`
- 성능테스트 관리 · `devpmo/devpmo-perf-test` *(사용안함, 숨김)*
- 테스트 결과 · `devpmo/devpmo-test-result` *(숨김)*
- 데이터 마이그레이션 · `devpmo/devpmo-migration` *(사용안함, 숨김)*
- 데이터 품질 관리 · `devpmo/devpmo-data-quality` *(사용안함, 숨김)*

### 산출물

- 산출물 템플릿 · `devpmo/devpmo-deliverable-template`
- 산출물 생성 · `devpmo/devpmo-deliverable-generate` *(숨김)*
- 교훈 관리 · `devpmo/devpmo-lessons-learned`

### 원가 관리

- 예산 관리 · `devpmo/devpmo-budget`
- 조달/외주 관리 · `devpmo/devpmo-procurement` *(사용안함, 숨김)*
- EVM/S-Curve · `devpmo/devpmo-evm`

### 위험 관리

- 리스크 관리 · `devpmo/devpmo-risk`

### 커뮤니케이션

- 회의 관리 · `devpmo/devpmo-meeting`
- 보고서 관리 · `devpmo/devpmo-report`
- 이해관계자 · `devpmo/devpmo-stakeholder`

### 변경통제

- 승인 관리 · `devpmo/devpmo-approval`
- 베이스라인 관리 · `devpmo/devpmo-baseline`
- 변경요청 관리 · `devpmo/devpmo-cr`
- 형상 관리 · `devpmo/devpmo-config`
- 릴리즈 관리 · `devpmo/devpmo-release`
- 검수 관리 · `devpmo/devpmo-inspection`

### 품질 관리

- 품질 대시보드 · `devpmo/devpmo-quality-dashboard`
- 외부검증/감리 · `devpmo/devpmo-audit`
- 감사 스케줄 · `devpmo/devpmo-quality-schedule`
- 멤버 성과 · `devpmo/devpmo-performance`

### 법무/계약

- 계약 관리 · `devpmo/devpmo-contract`
- 법무 관리 · `devpmo/devpmo-legal` *(사용안함, 숨김)*

### 교육 관리

- 교육 관리 · `devpmo/devpmo-training` *(사용안함, 숨김)*

### 운영전환

- 환경 구성 관리 · `devpmo/devpmo-environment` *(사용안함, 숨김)*
- 배포 이력 관리 · `devpmo/devpmo-deployment`
- 오픈 체크리스트 · `devpmo/devpmo-go-live`
- 장애 관리 · `devpmo/devpmo-incident`
- SLA 관리 · `devpmo/devpmo-sla` *(사용안함, 숨김)*

### 협업 공통

- Q&A 관리 · `devpmo/devpmo-qna`
- 공지 관리 · `devpmo/devpmo-notice`
- 용어사전 · `devpmo/devpmo-term`
- 프로젝트 템플릿 · `devpmo/devpmo-template`

## 개인


### 전자결재

- 결재함 · `approval/approval`
- 결재선 템플릿 · `approval/approval-template`
- 결재 위임 · `approval/approval-delegate`
- 결재 현황 · `approval/approval-dashboard`

### 소통

- 조직도 · `mypage/org-chart`
- 주소록 · `mypage/address-book`
- 알림 센터 · `notification/notification-center`
- 매뉴얼 · `manual/manual-viewer`

### 설문

- 동의서 · `agreement/agreement-consent`

### 마이페이지

- 내 정보 · `mypage/my-page`
- 사용자 대시보드 · `mypage/user-dashboard`
- 캘린더 · `mypage/calendar`
- 개인설정 · `mypage/user-preference`
- 즐겨찾기 · `system/favorite`
- 권한위임 · `role/role-delegation` *(사용안함)*

### AI

- AI 어시스턴트 · `ai/ai-agent`

## 시스템


### 플랫폼


#### 시스템 관리

- 시스템 관리 · `system/my-system`
- 업무그룹 관리 · `system/biz-group`
- 시스템언어 관리 · `system/system-language`
- 배포모듈 관리 · `system/module`
- 데이터소스 관리 · `system/datasource`
- 기능모듈 관리 · `system/feature-module`
- 시스템 정책 · `system/system-policy` *(사용안함)*
- Timezone · `system/timezone`
- 커스텀 필드 관리 · `system/custom-field` *(사용안함)*
- 웹훅 · `system/webhook`

#### 설정

- 설정 관리 · `system/config`
- 페이지정책 관리 · `system/page-policy`
- HTTP정책 관리 · `system/http-policy`
- HTTP캐시정책 관리 · `system/http-cache-policy`
- 데이터캐시정책 관리 · `system/data-cache-policy`
- DRM설정 관리 · `system/drm-config`
- 기능 플래그 · `system/feature-flag`
- 시스템 가이드 · `manual/system-guide`

#### 테넌트 관리

- 테넌트 관리 · `system/tenant-manage`
- Tenant Wizard · `system/tenant-wizard`
- Tenant Wizard · `system/tenant-wizard`
- Tenant Capability · `system/tenant-capability`

### 보안


#### 보안정책

- 보안정책 관리 · `system/security-policy`
- 인증정책 관리 · `system/auth-policy`
- 접근정책 관리 · `system/network-access-policy`
- ReBAC 권한 튜플 관리 · `system/permission-tuple` *(사용안함)*
- ABAC 접근 정책 관리 · `system/access-policy`
- 동적 필드 정의 관리 · `system/custom-field-definition`

#### 접근관리

- 허용IP 관리 · `system/allowed-ip`
- 내부IP 관리 · `system/internal-ip`
- CORS 허용도메인 관리 · `system/cors-allowed-origin`
- 접근제어 관리 · `system/service-access`
- 접근 정책 규칙 관리 · `system/access-rule`
- 네트워크 접근정책 관리 · `system/network-access-policy`

#### 개인정보

- Watermark Config · `system/watermark-config`
- E-Signature Config · `system/e-signature-config`
- 문서 보존 정책 · `system/records-retention`
- 개인정보컬럼 관리 · `system/privacy-column`
- Privacy Retention · `system/privacy-retention`
- 동의서 관리 · `agreement/agreement-manage` *(사용안함)*

### 조직관리


#### 내부조직

- Employee Management · `system/hmp-user-manage`
- 프로젝트 상세(PM) · `project/project-org-detail`

#### 조직 마스터

- 회사 관리 · `organization/company`
- 사업장 관리 · `organization/business-place`
- 부서 관리 · `co/deptMng`

##### 조직 구조 *(숨김)*

- 조직 구조 관리 · `organization/org-structure` *(숨김)*
- 조직 단위 관리 · `organization/org-unit` *(숨김)*

##### 내부조직 *(사용안함, 숨김)*

- 프로젝트 상세(PM) · `project/project-org-detail` *(숨김)*
- 사용자 발령 관리 · `system/org-assignment` *(숨김)*

#### 사용자 관리

- 임직원 관리 · `organization/employee`
- 사용자 관리 · `system/hmp-user-manage`
- 사용자 발령 관리 · `system/org-assignment`
- 사용자 발령 관리 · `system/org-assignment`
- 사용자 법인 소속 관리 · `organization/user-company`

#### 조직 구조

- 조직 구조 관리 · `organization/org-structure`
- 조직 단위 관리 · `organization/org-unit`

#### 외부사용자

- 외부 사용자 초대·승인·만료 · `organization/external-access`
- 협력업체 관리 · `organization/partner`
- 협력업체사용자 관리 · `organization/partner-user`
- Partner User Management · `system/hmp-user-manage`

#### 외부 동기화

- 외부 동기화 매핑 · `system/sync-mapping`
- 외부 동기화 스케줄 · `system/sync-schedule`
- 외부 동기화 로그 · `system/sync-log`
- SCIM 2.0 공급자 · `system/scim-provider`

### 권한/서비스


#### 권한 마스터

- 권한 관리 · `role/role`
- 사용자권한 관리 · `role/user-role`
- 사용자권한 조회 · `role/user-role-inquiry`

#### 권한 정책

- 공통권한 관리 · `role/role-common`
- 발령권한 관리 · `role/role-rule`
- 지정권한 관리 · `role/role-assign`

#### 위임/조건

- 권한위임 관리 · `role/role-delegation` *(사용안함)*
- 권한조절 공급자 · `role/auth-adjust-provider`
- 권한조건 관리 · `role/role-condition`
- 권한·겸직 신청 · `role/role-request`

#### 서비스관리

- 서비스 관리 · `role/service`
- 인증항목패턴 관리 · `role/auth-item-pattern`
- 권한서비스 매핑 · `role/role-service`

### 기준정보


#### 코드관리

- 코드그룹/코드 관리 · `code/code`
- 코드그룹 관리 · `code/code-group` *(사용안함, 숨김)*
- 국가코드 관리 · `common/country`
- 화폐 관리 · `common/currency`
- 환율 관리 · `common/exchange-rate`
- 언어코드 관리 · `common/language`
- 은행 관리 · `common/bank`
- 공휴일 관리 · `common/holiday`
- 채번 규칙 · `numbering/numbering-rule`

#### 데이터표준

- 데이터 표준 사전 · `system/data-standard`
- 코드 등록 요청 관리 · `system/code-request`
- 코드 등록 요청 · `system/code-request-form`
- 공공 표준 코드 · `system/public-std-code`

#### 다국어

- 메시지 관리 · `i18n/message`
- 라벨 관리 · `i18n/label`
- 포맷정책 관리 · `system/format-policy`

### 업무


#### 결재 공통

- 결재 양식 관리 · `approval/approval-form-template` *(사용안함)*
- 결재 기안/상세 · `approval/approval-form`

#### 내부결재

- 결재함(core 헤더 serviceId approval · D-N15b) · `approval/approval` *(숨김)*
- 결재함 · `approval/approval`
- 결재선 템플릿 · `approval/approval-template`
- 결재선 규칙 · `approval/approval-route` *(사용안함)*
- 결재 위임 · `approval/approval-delegate`
- 결재 현황 · `approval/approval-dashboard`

#### GW결재

- 결재 체이닝 · `approval/approval-chain-manage` *(사용안함)*
- GW결재 목록 · `approval/gw-approval-list`
- GW결재 콜백 관리 · `approval/gw-approval-callback-manage`

#### 스케줄러

- 스케줄러 관리 · `scheduler/scheduler`
- 스케줄러 실행이력 · `scheduler/scheduler-history`
- 메시지채널 관리 · `msg/msg-channel`
- 통합 메시지 발송 · `msg/msg-send` *(사용안함)*
- 메시지 이력 · `msg/msg-history`
- 수신거부 관리 · `msg/msg-opt-out` *(사용안함)*
- 메시지템플릿 관리 · `msg/msg-template`
- 알림 관리 · `notification/notification-manage`

#### 워크플로우

- 결정표 · `decision/decision-table`

### 연동/AI


#### AI

- AI 연결 · `ai/ai-provider`
- AI 사용량·한도 · `ai/ai-usage-dashboard`
- AI 가 볼 수 있는 데이터 · `ai/ai-admin`
- AI 권한 설명기 · `ai/ai-access-explainer`
- 이상감지 규칙 · `ai/ai-anomaly-rule`
- 사용자 프로그램 관리 · `userprogram/user-program-admin`
- AI 스케줄러 운영 · `ai/ai-scheduler`
- 스키마 컨텍스트 · `ai/ai-schema-context`
- 프롬프트 규칙 · `ai/ai-prompt-template`
- 외부 컬럼 매핑 · `ai/ai-external-column-map`

### 운영


#### 모니터링

- 모니터링 대시보드 · `monitoring/monitoring-dashboard`
- 성능 인사이트 · `monitoring/performance-insight`
- 화면 모니터링 · `monitoring/screen-viewer`
- 로그 대시보드 · `monitoring/log-dashboard`

#### 로그조회

- 이력 조회 · `revision/entity-version`
- 로그설정 관리 · `system/log-config`
- 로그인 로그 · `log/log-login`
- 페이지 로그 · `log/log-page`
- API 로그 · `log/log-service`
- 오류 로그 · `log/log-error`
- 개인정보 로그 · `log/log-privacy`
- 파일다운로드 이력 · `log/log-file-download`
- 권한부여 로그 · `log/log-role-grant`
- 권한서비스 로그 · `log/log-role-service`

#### 플랫폼 서비스

- 모듈 상태 · `system/module-health`
- 플랫폼 서비스 카탈로그 · `system/platform-service`
- 포털 템플릿 · `dashboard/portal-template`
- 단축 URL · `system/short-url`
- 사용자 세션 관리 · `system/user-session`
- 점검 모드 · `system/maintenance-mode`
- 서버파일 관리 · `file-batch/server-file`
- 홈 화면 규칙 · `dashboard/home-service-rule`
- 페이지 확장 · `system/page-extension` *(사용안함)*

#### 파일 관리

- 파일그룹 관리 · `file-batch/file-group`
- 파일 관리 · `file-batch/attached-file`
- 파일 관리 · `file-batch/file` *(사용안함)*

#### 데이터 감사

- 테이블 감사 · `system/table-audit`
- 로그 파일 뷰어 · `system/log-file-viewer`

#### 배치

- 대량처리 작업 · `excel/excel-job`

### 개발도구


#### 빌더

- 화면 빌더 · `screen-builder/screen-builder`
- 서버 빌더 · `server-builder/server-builder`
- DB 빌더 · `db-builder/db-builder`
- 커스텀 컴포넌트 빌더 · `devtool/custom-component`
- 스니펫관리 · `devtool/snippet-manage`
- DDL 실행 이력 · `db-builder/ddl-history`

#### 코드 생성

- 통합 코드 생성기 · `devtool/code-generator`
- 스캐폴드 마법사 · `scaffold-wizard`

#### 테스트

- 테스트 커버리지 · `devtool/test-coverage`
- 테스트 데이터 팩토리 · `devtool/test-data-factory`

#### API & DB

- API 테스트 · `devtool/api-playground`
- DB 탐색기 · `devtool/db-explorer`
- CRUD 매트릭스 · `system/crud-matrix`
- 스키마 마이그레이션 · `devtool/schema-migration`

#### 보안 & 인증서

- 권한 매트릭스 · `devtool/auth-matrix`
- 암호화 도구 · `system/crypto-tool`
- 인증서 관리 · `devtool/dev-certificate`
- 보안 점검 · `devtool/security-audit`
- 통합 인증 공급자 · `system/auth-provider`

#### DevOps

- 설정 비교 · `devtool/config-diff`
- DevOps 콘솔 · `devtool/devops-console`
- 서비스 의존성 · `devtool/service-dependency`
- 디버그정책 관리 · `system/debug-policy`
- 개발모듈오버라이드 · `system/dev-module-override`

#### 문서

- 매뉴얼 · `manual/manual-viewer`

### AI 관리

- AI 연결 · `ai/ai-provider`
- AI 사용량·한도 · `ai/ai-usage-dashboard`
- AI 가 볼 수 있는 데이터 · `ai/ai-admin`
- AI 권한 설명기 · `ai/ai-access-explainer`
- 프롬프트 템플릿 · `ai/ai-prompt-template`
- 사용자 프로그램 관리 · `userprogram/user-program-admin`
- 외부 컬럼 매핑 · `ai/ai-external-column-map`
- AI 스케줄러 운영 · `ai/ai-scheduler`

### AI 분석

- 스키마 컨텍스트 · `ai/ai-schema-context`
- 이상감지 규칙 · `ai/ai-anomaly-rule`

## 상위 메뉴 없음

상위 폴더가 없는 화면입니다. 대부분 다른 화면에서 링크로 열리는 숨김 화면입니다.

- AI 브리핑 · `ai/ai-briefing`
- AI 어시스턴트 · `ai/ai-agent` *(숨김)*
- AI 어시스턴트 · `ai/ai-agent` *(숨김)*
- AI 한도 · 단가 · `ai/ai-quota` *(숨김)*
- DDL 실행 이력 · `db-builder/ddl-history` *(숨김)*
- GW 전자결재 상신 공용팝업 · `co/gwAprvSubmit` *(숨김)*
- Inquiry Form · `inquiry/inquiry-form` *(숨김)*
- Portal · `dashboard/portal` *(숨김)*
- 개인 프로그램 · `userprogram/host` *(숨김)*
- 공휴일 관리 · `common/holiday` *(숨김)*
- 공휴일 관리 · `common/holiday` *(숨김)*
- 근거 문서 · `ai/ai-doc-viewer` *(숨김)*
- 내 예약 보고서 · `report/user-job` *(숨김)*
- 내 프로그램 · `userprogram/my-programs` *(숨김)*
- 내역변경현황(GW) 공용팝업 · `co/ebgtDtlsCurstDlgGw` *(숨김)*
- 로그인 · `erp/login` *(숨김)*
- 매뉴얼 팝업 · `manual/manual-popup` *(숨김)*
- 메뉴 메모 팝업 · `mypage/menu-memo-popup` *(숨김)*
- 메인 · `erp/main` *(숨김)*
- 문서 정의 편집 · `document/document-definition-editor` *(숨김)*
- 변경 이력 · `revision/revision-history` *(숨김)*
- 보고서 편집기 · `report/report-editor` *(숨김)*
- 수주 추진 계획 · `co/dashBordBMRvord` *(숨김)*
- 시스템 가이드 · `manual/system-guide` *(숨김)*
- 시스템승인 팝업(미이주) · `co/sysAprvPop` *(숨김)*
- 에이전트 프로필 · `ai/ai-agent-profile` *(숨김)*
- 외부 동기화 어댑터 · `system/sync-adapter` *(숨김)*
- 은행 관리 · `common/bank` *(숨김)*
- 은행 관리 · `common/bank` *(숨김)*
- 통합 코드 생성기(API) · `devtool/code-generator` *(숨김)*
- 판매 추진 계획 · `co/dashBordBMSals` *(숨김)*
- 협력사 공지 입력 · `co/btobWrite1` *(숨김)*
- 협력사 공지 입력 · `co/btobWrite1` *(숨김)*
- 협력업제정보 · `link/vndrInfoAprvGw` *(숨김)*
- 화면 소스 편집 · `devtool/page-source-editor` *(숨김)*
- 환율 관리 · `common/exchange-rate` *(숨김)*
- 환율 관리 · `common/exchange-rate` *(숨김)*

