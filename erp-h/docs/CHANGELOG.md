# 변경 이력 (CHANGELOG)

`erp-h` 디렉토리를 수정할 때마다 아래 형식으로 기록합니다.
최신 항목이 위에 오도록 추가합니다.

## 기록 형식

```
## YYYY-MM-DD
- 변경 내용 요약
  - 대상 경로: `erp-h/...`
  - 이유 또는 배경
```

---

## 2026-11-25

- A/S관리 테스트생성 화면 메뉴 등록 SQL 초안 추가(미실행)
  - 대상 경로: `erp-h/scripts/as-mgmt-test-register.sql`
  - 이유: 사용자 요청 — 분석서 기반 새 화면을 A/S관리와 같은 메뉴(MENU_CS_REG_AS) 아래 등록하기 위함
  - 내용: program · service(정렬 15) · service_i18n · role_service(cs_csChkMng 권한 복사) · 되돌리기 절
  - 비고: 메뉴·권한 등록은 리드 담당(VIBE-CODING §2)이라 파일로만 준비 · 화면 파일 `pages/cs/asMngTest.js` 는 MCP 조회 도구 미연결로 lookup_gate 에 막혀 미작성

- A/S관리 화면 분석서 HTML 판 추가(사람이 읽기 쉬운 형태)
  - 대상 경로: `erp-h/scripts/as-mgmt-screen-analysis.html`
  - 이유: 사용자 요청 — 같은 분석 내용을 화면 구성 모형 · 업무 흐름 · 진행상태 변화 · 버튼 활성 조건 중심으로 재구성
  - 비고: 내용 원천은 같은 폴더 `as-mgmt-screen-analysis.md`(구현용 상세 명세로 유지)

- A/S관리 화면 분석서 추가
  - 대상 경로: `erp-h/scripts/as-mgmt-screen-analysis.md`
  - 이유: 분석서를 기준으로 A/S관리 화면을 새로 구현하기 위함(사용자 요청)
  - 근거: `products-erp-h/app/src/main/resources/pages/cs/csChkMng.js` · `CsChkMngController.java` · `CsIntakeController.java` · `AsAcpDtlsService.java` · `CsIntakeService.java` · `erp-csc-csChkMngListQ.xml` · `erp-csc-csChkMngSave.xml` · 코드·서비스 시드
  - 내용: 화면 배치 · 조회조건 · 목록 컬럼 · 상세 필드와 잠금 조건 · 버튼 활성 조건 · 다이얼로그 9종 · 저장 흐름과 서버 검증 · API 26종 · 테이블 · 코드 그룹 · 모드별 차이 · 구현 규칙 · 확인 필요 사항

## 2026-11-18

- `docs/계정별-권한-테스트-시나리오.md` 화면 권한·버튼 권한 중심으로 재작성
  - 대상 경로: `erp-h/docs/계정별-권한-테스트-시나리오.md`
  - 근거: CS 화면 소스 `products-erp-h/app/src/main/resources/pages/cs/*.js` 버튼 선언 · erp-h 라벨 데이터 · hmp `components-react.js` 프리셋 버튼 등급(BUTTON_PRESETS)·버튼 표시 모드(`ui.auth.button.mode` 기본 disabled) · 화면별 권한 정의표
  - 변경: 판정 규칙(화면 권한·버튼 종류별 요구 조건) · 계정별 화면 권한 시나리오 · CS 23화면·공통/시스템 12화면 버튼×계정 표 · 등급 1 계정에서 활성되는 등급 조건 없는 업무 버튼(★) 8건 · 서버 차단 7건 · 부록 A 유지
  - 비고: 이전 판의 데이터 범위·역할 겹침·기간 시나리오는 제외(버튼 중심 요청)
- `docs/계정별-권한-테스트-시나리오.md` 화면 경로 추가
  - 대상 경로: `erp-h/docs/계정별-권한-테스트-시나리오.md`
  - 근거: 작업대장 v3 메뉴 단계 · `P5-menu-system-full-projection.tsv`(11/11 실측 메뉴) · `sqlh-service-20261109.psv` 부모 메뉴(CS 화면)
  - 변경: 시나리오 화면 칸 92곳을 「메뉴 경로 (화면ID)」로 바꿈 · 부록 A 메뉴 묶음 → 메뉴 경로 · 12장에 관리 화면 경로 · E-07 을 업무그룹 관리(ca-biz-group) 기준으로 수정(biz-group 은 서버 API 묶음)
- `docs/계정별-권한-테스트-시나리오.md` 역할별 상세 시나리오로 확대
  - 대상 경로: `erp-h/docs/계정별-권한-테스트-시나리오.md`
  - 근거: `products-erp-h/db/common-admin/P3-plan-role-service.tsv` 역할×화면 전체 · 서비스명 `db/common-admin/input/sqlh-service-20261109.psv`
  - 변경: 시나리오 유형 11종(메뉴·등급 1·2·3·미부여·직접 호출·범위·역할 겹침·기간·팝업·엑셀) · 계정 8개 시나리오 106건 · 계정 비교·권한 변경 시나리오 · 부록 A(CS 61화면×계정 등급)·B(관리·개발 메뉴 묶음별 등급)
- `docs/계정별-권한-테스트-시나리오.md` 생성
  - 대상 경로: `erp-h/docs/계정별-권한-테스트-시나리오.md`
  - 근거: `products-erp-h/db/common-admin/P3-plan-role-service.tsv`(역할×화면 부여 계획) · `TEST-USERS.md` · 화면별 권한 정의표
  - 이유: 시험 계정별(erpadmin·h.dev01·h.csadm·h.cs01·h.cs02·h.cs03·h.site01·h.bizadm) 메뉴·등급·서버 차단·데이터 범위 시나리오 작성 요청
- `docs/계정별-권한-테스트-순서.md` 생성
  - 대상 경로: `erp-h/docs/계정별-권한-테스트-순서.md`
  - 근거: `products-erp-h/docs/work/common-admin/dev-guide/TEST-USERS.md` · 화면별 권한 정의표 · `docs/계정-권한-흐름도.md`
  - 이유: 시험 계정별 권한 테스트 순서(준비 → 실효 메뉴 사전 확인 → 로그인 → 메뉴 → 화면 등급 → 서버 차단 → 데이터 범위 → 기록) 문서화 요청
- `docs/계정-권한-흐름도.md` 생성
  - 대상 경로: `erp-h/docs/계정-권한-흐름도.md`
  - 근거: `products-erp-h/docs/work/common-admin/dev-guide/PLATFORM.md` §4~§6 · `BRIEFING-20261110.md` §2 · hmp core 판정 클래스 존재 확인
  - 이유: 계정 하나에 권한을 정의·부여하고 로그인·메뉴·화면·API·데이터 범위에 적용되는 흐름을 mermaid 흐름도로 정리 요청
- `docs/계정-권한-흐름도.md` 화면 조작 순서로 재작성
  - 대상 경로: `erp-h/docs/계정-권한-흐름도.md`
  - 근거: hmp `pages/role/role-service.js`·`user-role.js` 화면 구성과 라벨(core `11_label.sql`) · 화면별 권한 정의표
  - 이유: 내부 구조 설명 대신 메뉴를 눌러 따라 할 수 있는 순서도·설명 요청(역할 만들기 → 메뉴·등급 연결 → 계정 부여 → 실효 메뉴 미리 보기 → 그 계정으로 확인 → 점검표)

## 2026-11-12

- `docs/공통관리-작업대장.md` 생성
  - 대상 경로: `erp-h/docs/공통관리-작업대장.md`
  - 근거: `products-erp-h/docs/work/common-admin/공통관리-작업대장_v3.xlsx` (시트 `작업목록`, 216행)
  - 변경: 엑셀 전 열을 우선순위별 표로 옮기고 마지막에 `검토완료` 열(☐) 추가
- `docs/공통관리-작업대장.md` 순번 1(ca-role) 검토완료 ☑
  - 대상 경로: `erp-h/docs/공통관리-작업대장.md`
  - 이유: 코드 검토 통과(실화면 미구동) — 검토 통과면 구동 없이도 체크하기로 함
- `docs/공통관리-작업대장.md` 순번 2(ca-role-common) 검토완료 ☑
  - 대상 경로: `erp-h/docs/공통관리-작업대장.md`
  - 이유: 코드 검토 통과. 「다국어 그리드 삭제 남음」 항목은 11/12 사용자 결정(hmp 925d0a89a · 언어 행 고정·추가/삭제 제거)으로 대체
- `docs/공통관리-작업대장.md` 순번 3(ca-role-rule) 검토완료 ☑
  - 대상 경로: `erp-h/docs/공통관리-작업대장.md`
  - 이유: 검토 중 결함 1건 수정 — role_condition 조건유형 CHECK 에 DUTY·ORG_UNIT·SCOPE·IP 가 없어 직무 등 조건 저장 실패. hmp install DDL 3방언 + upgrade `2026-11-12-role-condition-type-check-*.sql` 추가(운영 DB 적용은 별도)
- `docs/공통관리-작업대장.md` 순번 4(ca-user-role) 검토완료 ☑
  - 대상 경로: `erp-h/docs/공통관리-작업대장.md`
  - 이유: 코드 검토 통과 · 수정 없음
- `docs/공통관리-작업대장.md` 1순위 나머지(순번 5~22·24, 19건) 검토완료 ☑
  - 대상 경로: `erp-h/docs/공통관리-작업대장.md`
  - 통과(수정 없음): 5·6·7·8·9·10·13·14·15·18·20·22·24
  - 수정(hmp 소스 · 커밋 안 함): 11 ca-service(→ 버튼 등급 2 · service_type CHECK 에 API 추가 · 열기방식 LINK 코드 use_yn=N + upgrade `2026-11-12-service-type-check-*.sql` · ERP DB 는 LINK 코드 끄기만 적용), 12 ca-role-service(등급 4 이상 저장 전 차단), 16 ca-org-structure(코드 칼럼 type=select), 17 ca-partner(주민번호 보기 등급 3), 19 ca-employee-manage(실화면 hmp-user-manage.js 상태 공통코드·저장 뒤 재선택·발령 날짜 형식), 21 ca-org-assignment(발령 저장 날짜 형식)

## 2026-11-09

- `docs/menu/` 삭제 (`screens/` 48개 파일, `index.md`)
  - 대상 경로: `erp-h/docs/menu/`
  - 이유: CS 전용 문서로 범위가 맞지 않아 전체 트리 `menu-tree.md` 로 대체
- `docs/menu-tree.md` → `docs/menu/menu-tree.md` 이동
  - 대상 경로: `erp-h/docs/menu/menu-tree.md`
  - 이유: 메뉴 문서를 `docs/menu/` 아래에 모으기 위해
- `docs/menu-tree.md` 상위·하위 메뉴 구분 개편
  - 대상 경로: `erp-h/docs/menu-tree.md` (이후 `docs/menu/menu-tree.md` 로 이동)
  - 변경: 폴더는 제목(`##`, `###`…)으로, 화면은 목록으로 구분하고 화면 하위 화면은 들여쓰기. 루트 메뉴별 `##` 제목과 목차 추가, ID 제거, 경로는 `·` 뒤에 표기, 숨김·사용안함은 짧은 태그로 표시, 상위 메뉴 없는 화면은 별도 절로 분리, 화면 없는 빈 폴더와 API 폴더는 제외
- `docs/menu-tree.md` 전체 메뉴 트리 생성
  - 대상 경로: `erp-h/docs/menu-tree.md`
  - 근거: `products-erp-h/db/common-admin/input/sqlh-service-20261109.psv` (서비스 테이블 추출, 2026-11-09)
  - 범위: 전 모듈 FOLDER/SCREEN 트리. SERVER/API/SECTION 제외. 권한·화면 용도 미포함
  - 한계: 실행 중인 localhost:8080 과 대조하지 않음
- `docs/menu/` 메뉴 문서 생성 (products-erp-h `cs` 모듈, 이후 `menu-tree.md` 로 대체 필요 여부 검토 중)
  - 대상 경로: `erp-h/docs/menu/index.md`, `erp-h/docs/menu/screens/*.md` (화면 48개)
  - 근거: `products-erp-h/app/src/main/resources/db/module/erp/install/common/` 의 `cs-02_program.sql`, `cs-03_service.sql`, `cs-05_role_service.sql`
  - 한계: 설치 시드 기준이며 localhost:8080 실행 DB 와 대조하지 않음. 공통·관리 메뉴(core jar)는 저장소에 없어 제외
  - 참고: 메뉴 트리에 있는 `ecstSlp`, `csSiteTransferSlpPubc` 는 FI 모듈 소유라 경로가 시드에 없음
- `docs/CHANGELOG.md` 생성 (이 문서)
  - 대상 경로: `erp-h/docs/CHANGELOG.md`
- `docs/` 하위 소메뉴 디렉토리 삭제 (`requirements`, `design`, `api`, `db`, `meeting-notes`, `guides`)
  - 대상 경로: `erp-h/docs/`
  - 이유: 대메뉴 구조만 유지하기로 함
- `docs/.gitkeep` 추가
  - 대상 경로: `erp-h/docs/.gitkeep`
  - 이유: 하위 디렉토리가 없어진 뒤에도 Git이 `docs/`를 추적하도록 함
- `README.md` 갱신
  - 대상 경로: `erp-h/README.md`
  - 이유: 삭제된 소메뉴를 디렉토리 구조와 표에서 제거
- `erp-h` 디렉토리 구조 생성
  - 대상 경로: `erp-h/docs`, `erp-h/tools`, `erp-h/scripts`, `erp-h/scratch`, `erp-h/reference`
  - 각 디렉토리에 `.gitkeep` 추가
- `README.md` 작성
  - 대상 경로: `erp-h/README.md`
  - 디렉토리 구조, 용도, 작성 규칙 정리
