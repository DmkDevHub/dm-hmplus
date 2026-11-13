# QH 프로시저 코드 값 QS → QH 변경 로드맵

> 작성일: 2026-11-13 · 대상: vplus `VPLUS202611A` (192.168.1.25:1521:ORCLU)
> 계획·조사 결과: [QH_CODE_LITERAL_PLAN.md](QH_CODE_LITERAL_PLAN.md) · 관련: [QH_MIGRATION_RESULT.md](QH_MIGRATION_RESULT.md), [QS_COMCODE_COPY_PLAN.md](QS_COMCODE_COPY_PLAN.md)
> 아직 DB는 바꾸지 않았다. 아래 수치는 vplus를 조회해서 확인한 값이다.

## 0. 기본 원칙

> **바꾸는 것은 QH 이관으로 새로 만든 객체와 테이블뿐이다. vplus 기존 객체와 데이터는 바꾸지 않는다.**

| 하는 것 | 하지 않는 것 |
|---|---|
| QH 프로시저 93개의 소스에서 코드 값만 `QS` → `QH`로 바꿔 다시 만든다(`DROP` → `CREATE`) | `CREATE OR REPLACE`, 로직·컬럼·다른 문자열 변경 |
| QH 이관으로 만든 테이블 `TQHA_CKLST`, `TQHA_CKLST_ITM`의 코드 값을 `UPDATE`한다 | vplus 기존 테이블(`TCOA_COMCODE`, `TCOZ_USR_INFO` 등)의 `INSERT`/`UPDATE`/`DELETE` |
| 이번에 다시 만든 객체와 그 객체를 호출하는 QH 객체만 다시 컴파일한다 | vplus 기존 객체의 재컴파일·수정 |
| JH는 접속하지 않는다 | |

- 지우기 전에, 대상이 QH 매핑표(`migration_qh/02_generate/mapping.csv`)에 있는 객체인지 확인한다.
- **변경 대상은 QH뿐이다. QS는 객체도 파일도 수정하지 않는다.**
  - vplus의 QS 객체(`PQSA_*`, `TQSA_*`, `VQSZ_*` 등)와 QS 공통코드는 바꾸지 않는다.
  - 기존 파일(`scripts/migration/`, `scripts/migration_qh/`, `scripts/comcode_qh/`, `TQS_*` 문서)은 수정하지 않는다. `migration_qh`의 생성 SQL은 입력으로 읽기만 한다. 결과는 새 폴더 `scripts/qh_code_literal/`에만 만든다.
  - 기준선에 QS 객체가 들어 있는 것은 "바뀌지 않았음"을 비교하기 위해서다(읽기만 한다).

## 1. 변경 규칙

| # | 대상 | 규칙 | 규모 |
|---|---|---|---|
| A | 공통코드 값 문자열 | 코드 영역의 문자열 리터럴 **값 전체**가 부록 A의 47종 중 하나이면 `QS…` → `QH…` | 218곳(조회 153, 고정값 65) |
| B | 오류 메시지 안의 코드 표기 | 메시지 문자열 안의 `QS005`, `QS026`, `QS035`, `QS09002`, `QSZ03`, `QSZ0310`을 `QH…`로 바꾼다. 나머지 글자는 그대로 둔다 | 7종 문구, 25곳 |
| C | `BB.USR_KND = 'QS'` | `'QS'` → `'QH'` | 3곳 |
| 데이터 | `TQHA_CKLST`, `TQHA_CKLST_ITM`의 `COM_CD`, `HO_CHK_DIV_CD2` | 맨 앞의 `QS` → `QH` | 118행 + 395행 |

**바꾸지 않는 것**
- 주석(952곳)
- 식별자(`VQSZ_TRADE`, `FQSE_GET_AFTL_CNT` 등 vplus 기존 객체 이름)
- 컬럼 이름

**확인한 것**
- 47종과 B의 6개 코드 모두 vplus 공통코드에 QH 값이 있다.
- 소스를 바꾸는 객체는 93개(`PQHA_*` 76, `PQHB_*` 17)이고, 함수와 TYPE은 없다. 93개 모두 지금 VALID이다.
- 93개에 걸린 권한(GRANT)이나 시노님은 없다.
- 93개를 호출하는 다른 객체는 2개(`PQHA_SAFECOST_INFO_S`, `PQHB_RISK_DGR_W`)다. 둘 다 QH 이관으로 만든 객체이고, 다시 컴파일만 하면 된다.
- 데이터 2개 테이블은 PK에 `COM_CD`, `HO_CHK_DIV_CD2`가 들어 있다. FK로 참조하는 테이블은 없다.

## 2. 진행 단계

산출물 위치: `erp-jh/scripts/qh_code_literal/` · 스크립트는 DB 비밀번호를 환경변수 `DB_PASSWORD`에서 읽는다.
**각 단계가 끝나면 결과를 보고하고, 승인을 받은 뒤 다음 단계로 넘어간다.**

### 1단계 — 기준선 저장 (조회만)
- QH 기준선 스크립트(`migration_qh/01_baseline/baseline.py`)로 다시 저장한다.
  - 대상: `TQS*`/`TQH*` 테이블 건수·제약조건, 이름에 `QS`/`QH`가 들어간 객체의 상태·`LAST_DDL_TIME`·소스 해시
- `TQHA_CKLST`, `TQHA_CKLST_ITM` 전체 값(513행)을 저장한다.
- 다시 만들 93개 객체의 vplus 현재 소스를 파일로 저장한다(되돌리기 원본).
- 확인: vplus 현재 소스가 `migration_qh/02_generate`의 생성 SQL과 같은지.
- ⏸ 보고

### 2단계 — 변경 SQL 생성 (조회만, 검토용)
- 변환 스크립트가 `migration_qh/02_generate/60_functions.sql`, `70_procedures.sql`을 읽어 1장 규칙을 적용한다. 주석과 식별자는 코드 영역을 구분해서 건드리지 않는다.
- 산출물
  - `10_recreate.sql`: 바뀐 93개 객체의 `DROP PROCEDURE` + `CREATE PROCEDURE`
  - `20_data_update.sql`: `TQHA_CKLST`, `TQHA_CKLST_ITM`의 `UPDATE` 2문(`SET COM_CD = 'QH' || SUBSTR(COM_CD, 3), …`), 대상 행 수 주석 포함
  - `80_diff_report.md`: 객체별로 바뀐 줄의 전후 비교
  - `98_rollback_data.sql`: 데이터 `QH` → `QS`
  - `99_rollback_objects.sql`: 1단계에서 저장한 원래 소스로 93개를 다시 만드는 SQL
- 자동 검사
  - 바뀐 객체가 93개인지, 모두 QH 매핑표에 있는지
  - **바뀐 부분이 1장 규칙의 문자열뿐인지**(전후를 토큰 단위로 비교해서 다른 차이가 0인지)
  - 바뀐 소스의 코드 영역에 `'QS…'` 문자열이 0개인지(주석은 제외)
  - 바뀐 코드 값이 모두 vplus 공통코드에 있는지
  - 데이터를 바꾼 뒤의 키가 기존 키와 겹치지 않는지, 513행이 모두 `QH`로 바뀌는지
  - `CREATE OR REPLACE` 0, 대상 밖 `DROP` 0
- ⏸ 생성된 SQL과 비교 리포트를 검토받는다.

### 3단계 — 객체 다시 만들기 (vplus에 쓰기)
1. 대상 93개가 있는지, 상태가 VALID인지, QH 매핑표에 있는지 확인한다.
2. 객체마다 `DROP` 후 `CREATE`한다. `CREATE`가 실패하면 그 객체를 1단계의 원래 소스로 바로 다시 만들고 멈춘다.
3. 다시 만든 93개와 이 객체들을 호출하는 QH 객체 2개 중 INVALID인 것만 다시 컴파일한다. INVALID가 더 줄지 않을 때까지 반복한다.
4. 남은 오류는 `USER_ERRORS`로 모아 보고한다. 소스를 임의로 고치지 않는다.
- ⏸ 보고

### 4단계 — 데이터 코드 값 수정 (vplus에 쓰기)
1. `TQHA_CKLST`(118행), `TQHA_CKLST_ITM`(395행)의 `COM_CD`, `HO_CHK_DIV_CD2`를 `QS…` → `QH…`로 `UPDATE`한다.
2. 한 트랜잭션으로 실행한다. 바뀐 행 수가 118, 395와 다르거나 오류가 나면 전체를 롤백하고 멈춘다.
- ⏸ 보고

### 5단계 — 검증 (조회만)
- 다시 만든 93개와 호출하는 2개가 VALID이고, 컴파일 오류가 0건인지
- vplus 소스가 `10_recreate.sql`의 소스와 같은지
- 바뀐 소스의 코드 영역에 `'QS…'` 문자열이 0곳인지(A·B·C)
- 데이터
  - 513행의 코드 값이 모두 `QH`로 바뀌었는지
  - 다른 컬럼은 1단계 값과 같은지
  - 바뀐 코드가 모두 공통코드에 있는지
- **0장 원칙 검증**
  - 1단계 기준선과 비교해, 이번 대상 93개 객체와 2개 테이블 말고는 바뀐 것이 0건인지
  - 객체 수와 테이블 건수가 같은지
- 프로시저는 실행하지 않는다.
- ⏸ 보고

### 6단계 — 결과 보고
- [QH_CODE_LITERAL_PLAN.md](QH_CODE_LITERAL_PLAN.md)에 결과를 덧붙인다.

## 3. 되돌리기

| 대상 | 방법 |
|---|---|
| 객체 93개 | `99_rollback_objects.sql`: 1단계에서 저장한 원래 소스로 `DROP` → `CREATE` |
| 데이터 513행 | `98_rollback_data.sql`: `QH` → `QS` `UPDATE` |
| 호출하는 객체 2개 | 다시 컴파일만 한다 |

vplus 기존 객체와 공통코드는 바꾸지 않으므로 되돌릴 것이 없다.

## 4. 범위 밖

- vplus 앱(화면, 매퍼, JSP/JS)이 공통코드를 `QS`로 넘기는 부분. 특히 `p_CHK_DIV`, `p_JB_CD` 같은 파라미터는 앱이 QH 코드를 넘겨야 조건이 맞는다.
- vplus 기존 QS 공통코드 776행의 정리.
- 주석 안의 QS 코드.

## 5. 결정 사항 (모두 확정, 2026-11-13)

| # | 항목 | 결정 |
|---|---|---|
| 1 | 오류 메시지 안의 코드 표기 | 바꾼다 |
| 2 | `TQHA_CKLST`, `TQHA_CKLST_ITM` 코드 값 | 함께 수정한다 |
| 3 | 주석 안의 QS 코드 | 바꾸지 않는다 |
| 4 | `BB.USR_KND = 'QS'` | `'QH'`로 바꾼다 |
