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
