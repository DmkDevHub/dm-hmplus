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
