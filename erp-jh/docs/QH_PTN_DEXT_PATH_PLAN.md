# VPLUS202611B 협력사 QH 덱스트 업로드 저장 경로 분리 계획

> 작성일: 2026-11-17 · 개정: 2026-11-18 · 대상: `VPLUS202611B/ptn/src/main/webapp/WEB-INF/jsp/qh`
> 관련: [QH_PTN_SOURCE_COPY_PLAN.md](QH_PTN_SOURCE_COPY_PLAN.md)(협력사 QH 화면 복사), [QH_PTN_LOGIN_PLAN.md](QH_PTN_LOGIN_PLAN.md)(협력사 QH 로그인)
> 이 문서의 내용은 B 소스와 vplus DB를 **읽기만 해서** 확인한 것이다. 아직 아무 파일도 고치지 않았다.
> **상태: 실행함(2026-11-18, 사용자 지시 "개발 진행해").** 결과는 8장. VPLUS202611B 커밋 `a42a893`.
> **개정(2026-11-18, 사용자 지시):** 기준을 다시 세웠다.
> 1. A(VPLUS202611A)의 기준은 무시한다.
> 2. B의 QH 화면은 QS와 같은 경로를 쓴다. QS는 건드리지 않고, QH 경로의 `QS`만 `QH`로 바꾼다.
> 3. **이번에만** QS의 `vPQSImgPathRule`처럼 QH용 공통 변수 `vPQHImgPathRule`을 만들어 쓴다(공통 설정 파일 한 줄 추가, 4-2).

## 1. 목적

- B의 QH 화면은 JH의 QS 화면을 복사한 것이다. 그래서 첨부파일 저장 폴더도 QS와 같은 `erp/saf//SH/QS/yyyy/mm`을 쓴다.
- 이 작업은 QH 화면의 저장 폴더만 `erp/saf//SH/QH/yyyy/mm`으로 바꾼다. 경로 안의 `QS`만 `QH`로 바꾸고 나머지 모양은 그대로 둔다.
- B의 QS 화면과 QS 경로는 그대로 둔다.

| 구분 | 지금 | 바꾼 뒤 |
|---|---|---|
| B QS 화면 | `erp/saf//SH/QS/yyyy/mm` | `erp/saf//SH/QS/yyyy/mm` (그대로) |
| B QH 화면 | `erp/saf//SH/QS/yyyy/mm` | **`erp/saf//SH/QH/yyyy/mm`** |

## 2. 현재 구조 (확인함)

### 2-1. 저장 폴더를 정하는 곳

- 화면이 업로더를 만들 때 넘기는 `dxtRule`로 정한다.
- B 공통 JS `resources/js/app.custom.dext5.js:171-181`이 `DEXT5UPLOAD.config.FolderNameRule`을 만든다.
  - `dxtRule`이 있으면 `erp/saf/` + `dxtRule`
  - `dxtRule`이 없으면 `erp/saf//SH/yyyy/mm`
  - `dxtHeavy`면 `erp/haf/`, `dxtShare`면 `hp/`로 시작한다. B qs·qh 화면은 이 두 옵션을 쓰지 않는다.
- B 공통 설정 `resources/js/app.config.min.js:64`
  ```js
  , vPQSImgPathRule = "/SH/QS/yyyy/mm" // partner와 erp 이미지 같이 보게 하기 위한 file path
  ```

### 2-2. B의 QS와 QH는 지금 같은 경로를 쓴다

덱스트 업로드를 쓰는 화면은 QS 8개, QH 8개다. `dxtRule` 값과 위치가 같다.

| 화면 (QS / QH) | QS 줄 | QH 줄 | 모드 | `dxtRule` |
|---|---|---|---|---|
| `qsa/addRiskRegCo` / `qha/addRiskRegCo` | 382, 395 | 382, 395 | edit | `vPQSImgPathRule` |
| `qsa/riskNcrActRsltRegCo` / `qha/riskNcrActRsltRegCo` | 384, 397 | 384, 397 | edit | `vPQSImgPathRule` |
| `qsa/riskNcrActRsltLstCo` / `qha/riskNcrActRsltLstCo` | 232, 245 | 232, 245 | view | `vPQSImgPathRule` |
| `qsa/riskSchdMngCo` / `qha/riskSchdMngCo` | 146 | 146 | edit | `vPQSImgPathRule` |
| `qsa/safeCostReg1Co` / `qha/safeCostReg1Co` | 461, 475 | 453, 467 | edit | `vPQSImgPathRule` |
| `qsc/ncrActRsltRegCo` / `qhc/ncrActRsltRegCo` | 350, 363 | 350, 363 | edit | `vPQSImgPathRule` |
| `qsz/anncBrdDtl` / `qhz/anncBrdDtl` | 90 | 90 | view | `"/SH/MM/yyyy/mm"` |
| `qsa/addRiskLstCo` / `qha/addRiskLstCo` | – | – | view | 없음 |

- 그 밖에 `qhz/anncBrdList.jsp`는 덱스트 관련 코드가 주석 한 줄(`// DEXT5UPLOAD.ResetUpload`)뿐이다.

### 2-3. 이미 올린 파일

- 첨부파일은 파일마다 저장 경로를 DB에 가진다(`TCOZ_ATFL.ATFL_PATH`). 예: `/erp/saf/SH/QS/2026/01/<GUID>.jpg`
- 그래서 저장 폴더 규칙을 바꿔도 **이미 올린 파일은 그대로 보인다.** 바뀌는 것은 QH 화면에서 새로 올리는 파일의 폴더뿐이다.
- vplus DB의 `ATFL_PATH` 분포(2026-11-17 조회): `/SH/QS/` 114건, `/SH/QH/` 0건.

## 3. 원칙

- **A는 기준으로 삼지 않는다. A는 보지도 바꾸지도 않는다.**
- **B의 QS는 건드리지 않는다.** QS JSP, QS 경로 값, 공통 설정 `vPQSImgPathRule`은 그대로 둔다.
- **QH는 QS와 같은 방식으로 둔다.** QS가 공통 변수 `vPQSImgPathRule`을 쓰므로, QH도 공통 변수 `vPQHImgPathRule`을 만들어 쓴다.
  - 경로 값은 `vPQSImgPathRule`의 `QS`만 `QH`로 바꾼 `"/SH/QH/yyyy/mm"`이다. `/SH/`, `/yyyy/mm`, 앞의 `/` 같은 경로 모양은 그대로 둔다.
- **공통 설정 파일은 이번에만 예외로 고친다(사용자 지시 3).** `app.config.min.js`에 `vPQHImgPathRule` 정의 한 줄만 추가한다. 기존 줄(`vPQSImgPathRule` 포함)은 바꾸지 않는다.
- B 공통 JS(`app.custom.dext5.js`)는 고치지 않는다.
- 업로더의 다른 옵션(ID, 모드, 개수, 확장자)은 그대로 둔다.
- DB는 바꾸지 않는다. 이미 올린 파일의 경로도 옮기지 않는다(2-3).
- 커밋·푸시는 사용자가 지시할 때 `main`에 직접 한다.

## 4. 바꿀 내용

### 4-1. QH JSP 6개, 11줄

`dxtRule : vPQSImgPathRule` → `dxtRule : vPQHImgPathRule`

| 파일 (`WEB-INF/jsp/qh/` 아래) | 줄 | 모드 |
|---|---|---|
| `qha/addRiskRegCo.jsp` | 382, 395 | edit |
| `qha/riskNcrActRsltRegCo.jsp` | 384, 397 | edit |
| `qha/riskNcrActRsltLstCo.jsp` | 232, 245 | view |
| `qha/riskSchdMngCo.jsp` | 146 | edit |
| `qha/safeCostReg1Co.jsp` | 453, 467 | edit |
| `qhc/ncrActRsltRegCo.jsp` | 350, 363 | edit |

- 바꾼 뒤 저장 폴더는 `"erp/saf/" + vPQHImgPathRule` = `"erp/saf/" + "/SH/QH/yyyy/mm"` = **`erp/saf//SH/QH/yyyy/mm`**이다. QS 경로(`erp/saf//SH/QS/yyyy/mm`)와 `QS`/`QH`만 다르다.
- 값에는 대문자 `MM`이 없다. 그래서 공통 JS의 `.replace("MM","M‡M")`에 걸리지 않는다. QS 값과 같은 조건이다.
- `riskNcrActRsltLstCo.jsp`는 보기 전용이라 실제 업로드는 없다. 그래도 QS와 같은 위치에 같은 변수를 쓰던 줄이므로 함께 바꿔 통일한다.

### 4-2. 공통 설정 `resources/js/app.config.min.js` — 한 줄 추가 (이번에만 예외)

- 64행 `vPQSImgPathRule` 정의 바로 아래에 한 줄을 추가한다.
  ```js
    , vPQSImgPathRule = "/SH/QS/yyyy/mm" // partner와 erp 이미지 같이 보게 하기 위한 file path   ← 64행, 그대로
    , vPQHImgPathRule = "/SH/QH/yyyy/mm" // QH 협력사 업로드 경로 (vPQSImgPathRule의 QS -> QH)  ← 추가
  ```
- 기존 64행과 같은 모양(앞의 `, `, 들여쓰기, 줄바꿈)으로 쓴다. 다른 줄은 바꾸지 않는다.
- 실행 전에 다음을 확인한다.
  - B에서 `vPQSImgPathRule`을 정의하는 곳이 이 파일 하나뿐인지 확인한다. 다른 곳에도 있으면 그 파일과 맞출지 보고한다.
  - 이 파일을 화면이 실제로 불러오는지 확인한다(`scriptInclude.jsp` 등). QS가 쓰는 `vPQSImgPathRule`이 이 파일에 있으므로 불러오는 것으로 보인다.
  - 64행이 `var` 선언 묶음(쉼표로 이어지는 선언) 안에 있는지 확인한다. 묶음의 마지막 줄이면 쉼표 위치를 맞춘다.
- 이 파일은 이름이 `.min.js`이지만 사람이 읽을 수 있는 형태다. 압축 원본 파일이 따로 있는지도 함께 확인한다.

### 4-3. 바꾸지 않는 것

| 화면·파일 | 이유 |
|---|---|
| B QS JSP 전체 (`jsp/qs/**`) | 사용자 지시 2 |
| `app.config.min.js`의 `vPQSImgPathRule` 줄 | QS가 쓰는 값이다(사용자 지시 2). 이 파일에는 4-2의 한 줄만 추가한다 |
| `app.custom.dext5.js` | 공통 JS (3장 원칙) |
| `qhz/anncBrdDtl.jsp` (`"/SH/MM/yyyy/mm"`) | QS 경로가 아니다. 보기 전용이라 업로드도 없다 |
| `qha/addRiskLstCo.jsp` | 보기 전용이고 `dxtRule`이 없다 |
| `qhz/anncBrdList.jsp` | 덱스트 관련 코드가 주석 한 줄뿐이다 |
| A 전체 | 사용자 지시 1 |

## 5. 실행 절차

| 단계 | 내용 |
|---|---|
| 1. 사전 확인 | B 작업 트리가 깨끗한지 본다. 4-1의 11줄이 그대로 있는지 본다. 4-2의 확인 항목을 본다 |
| 2. 수정 | 4-2의 한 줄을 추가하고, 4-1의 11줄을 바꾼다. 줄바꿈과 들여쓰기는 각 파일의 기존 방식을 유지한다 |
| 3. 확인 | 6장 |
| 4. 보고 | 바꾼 파일, diff, 확인 결과를 보고한다 |

## 6. 확인

| 항목 | 기준 |
|---|---|
| diff | B `jsp/qh` 아래 JSP 6개 11줄, `app.config.min.js` 한 줄 추가만 있다. `jsp/qs`와 공통 JS는 바뀌지 않는다 |
| QH 남은 값 | B `jsp/qh`에 `vPQSImgPathRule`이 0건이고, `vPQHImgPathRule`이 11건이다 |
| 변수 정의 | 화면에서 `vPQHImgPathRule` 값이 `"/SH/QH/yyyy/mm"`이다(브라우저 개발자 도구 콘솔). 정의가 빠지면 QH 업로드 화면에서 스크립트 오류가 나므로 꼭 확인한다 |
| QS 그대로 | B `jsp/qs`의 `vPQSImgPathRule` 11건이 그대로다 |
| QH 업로드 | B QH 계정으로 4-1 화면(예: 위험성평가 일정관리 `riskSchdMngCo`)에서 파일을 올리면 `TCOZ_ATFL.ATFL_PATH`가 `/erp/saf/SH/QH/yyyy/mm/…`로 저장된다 |
| QS 업로드 | B QS 화면에서 올리면 지금처럼 `/erp/saf/SH/QS/yyyy/mm/…`로 저장된다 |
| 기존 파일 | 이미 올린 첨부(`/SH/QS/…`)가 그대로 보이고 내려받아진다 |

- 업로드 확인에는 B QH·QS 테스트 계정이 필요하다. 업로드는 DB와 파일 서버에 기록되므로 사용자 확인 후 한다.

## 7. 위험과 주의

| # | 내용 | 대응 |
|---|---|---|
| 1 | `/SH/QH/` 폴더는 아직 파일 서버에 없다(DB 0건) | DEXT5 업로드는 `FolderNameRule`의 폴더를 만들어 저장한다. 6장 QH 업로드 확인에서 실제로 저장되는지 본다 |
| 2 | 공통 설정 주석에는 `/SH/QS/`가 "partner와 erp 이미지 같이 보게 하기 위한" 경로라고 되어 있다. QH는 이 공유 폴더에서 빠진다 | 첨부는 파일별 `ATFL_PATH`로 열리므로 보기에는 영향이 없다(2-3). ERP 쪽에서 `/SH/QH/`를 쓸지는 이번 범위 밖이다(사용자 지시 1) |
| 3 | 공통 설정 파일을 고친다. 이 파일은 모든 협력사 화면이 불러온다 | 줄 하나만 추가하고 기존 줄은 바꾸지 않는다. 문법이 틀리면 전체 화면 스크립트가 멈추므로, 기동 후 아무 화면(QS·회원 포함)에서 콘솔 오류가 없는지 확인한다 |
| 4 | 브라우저가 예전 `app.config.min.js`를 캐시해 두면 `vPQHImgPathRule`이 없다는 오류가 날 수 있다 | 확인할 때 강력 새로고침(Ctrl+F5)을 한다. 캐시 무효화용 버전 파라미터가 있는지 사전 확인 때 함께 본다 |

## 8. 실행 결과 (2026-11-18)

### 8-1. 사전 확인

| 항목 | 결과 |
|---|---|
| B 작업 트리 | 깨끗함 |
| `vPQSImgPathRule` 정의 위치 | `resources/js/app.config.min.js:64` 한 곳뿐 |
| 선언 묶음 | 64행은 쉼표로 이어지는 선언 묶음의 중간 줄이다(65행 `unicodeByte`, 66행 `Cal`이 이어짐). 쉼표 조정이 필요 없다 |
| 불러오는 곳 | `WEB-INF/jsp/include/scriptInclude.jsp:26` (`?ver=${script_version}` 버전 파라미터 있음), `tiles/layout/layout_print.jsp:54` |
| 압축 원본 | 따로 없음 (`app.config.min.js` 하나) |
| 줄바꿈 | CRLF, BOM 없음 |

### 8-2. 바꾼 파일 (VPLUS202611B, 커밋 `a42a893`)

`git diff --stat` 기준 7개 파일, +12 / −11.

| 파일 | 변경 |
|---|---|
| `resources/js/app.config.min.js` | +1. 64행 아래에 `, vPQHImgPathRule = "/SH/QH/yyyy/mm" // QH 협력사 업로드 경로 (vPQSImgPathRule의 QS -> QH)` |
| `jsp/qh/qha/addRiskRegCo.jsp` | 2줄 (382, 395) |
| `jsp/qh/qha/riskNcrActRsltRegCo.jsp` | 2줄 (384, 397) |
| `jsp/qh/qha/riskNcrActRsltLstCo.jsp` | 2줄 (232, 245) |
| `jsp/qh/qha/riskSchdMngCo.jsp` | 1줄 (146) |
| `jsp/qh/qha/safeCostReg1Co.jsp` | 2줄 (453, 467) |
| `jsp/qh/qhc/ncrActRsltRegCo.jsp` | 2줄 (350, 363) |

- JSP 11줄은 모두 `dxtRule : vPQSImgPathRule` → `dxtRule : vPQHImgPathRule`이다. 다른 글자는 바뀌지 않았다.
- 줄바꿈과 들여쓰기는 원래대로 유지했다.

### 8-3. 확인

| 항목 | 결과 |
|---|---|
| QH 남은 값 | `jsp/qh`의 `vPQSImgPathRule` 0건, `vPQHImgPathRule` 11건 |
| QS 그대로 | `jsp/qs`의 `vPQSImgPathRule` 11건 그대로. `jsp/qs` diff 없음 |
| 공통 JS | `app.custom.dext5.js` diff 없음 |
| 설정 파일 문법 | `node --check app.config.min.js` 통과 |
| 저장 폴더 계산 | QH `erp/saf//SH/QH/yyyy/mm`, QS `erp/saf//SH/QS/yyyy/mm` |

### 8-4. 업로드 확인과 로컬 업로드 루트 변경 (2026-11-18)

- **QH 업로드 확인:** 사용자가 B QH 화면에서 파일을 올렸다. 결과는 아래와 같다.
  - DB `TCOZ_ATFL.ATFL_PATH`: `/erp/saf/SH/QH/2026/11/35ab32e5-a153-4369-a695-b5db8917d5e0.jpg` (첨부그룹 `1722FGES`, 08:59:17)
  - 디스크: `D:\vPlusData\JH202603\erp\saf\SH\QH\2026\11\35ab32e5-….jpg` (108,985바이트)
  - QH 폴더(`/SH/QH/`)로 저장되는 것을 확인했다.
- **물리 파일이 `JH202603` 아래에 저장된 이유**
  - B 로컬 설정 `application-loc.yml`의 `spring.filecfg.uploadPath`가 `D:/vPlusData/JH202603`이었다.
  - 이 값은 B 첫 커밋 `42f0a0b`(2026-11-12, JH 협력사 프로젝트 가져오기)부터 그대로였다.
  - 물리 경로는 `uploadPath` + `ATFL_PATH`다(`Dext5Util.java:61`).
- **사용자가 직접 로컬 루트를 바꿨다.** `application-loc.yml`의 `uploadPath`와 `previewPath`를 `D:/vPlusData/JH202603`에서 `D:/vPlusData/VPLUS202611A`로 바꿨다. A ERP와 같은 루트다.
  - 같은 커밋에 포함한다.
  - `application-dev.yml`(`E:/vPlusData/JH202603`)과 `application-op.yml`은 바꾸지 않았다.
  - 위 테스트 파일 1건은 예전 루트(`JH202603`)에 남아 있다. 새 루트에서는 열리지 않는다.

### 8-5. 남은 확인 (서버·테스트 계정 필요)

- 6장의 화면 확인: 브라우저 콘솔에서 `vPQHImgPathRule` 값, QS·회원 화면 콘솔 오류 없음.
- QS 업로드 후 `TCOZ_ATFL.ATFL_PATH`가 지금처럼 `/erp/saf/SH/QS/…`인지 확인한다.
- 새 루트(`D:/vPlusData/VPLUS202611A`)에서 QH 업로드·보기를 확인한다.
- 업로드는 DB와 파일 서버에 기록되므로 사용자 확인 후 한다.
