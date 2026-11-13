# QH 프로시저·함수의 QS 공통코드 → QH 변경 계획

> 작성일: 2026-11-13 · 대상: vplus `VPLUS202611A` (192.168.1.25:1521:ORCLU)
> 관련: [QH_MIGRATION_RESULT.md](QH_MIGRATION_RESULT.md)(QH 객체 이관), [QS_COMCODE_COPY_PLAN.md](QS_COMCODE_COPY_PLAN.md)(공통코드 QS→QH 복사, 9-3장 남은 사항 1)
> 1~9장의 수치는 vplus를 조회만 해서 확인한 값이다. 실행 결과는 [10장](#10-실행-결과-2026-11-13)에 있다(2026-11-13 실행 완료).

## 1. 목적

QH 이관으로 vplus에 새로 만든 함수·프로시저(`PQHA_*`, `PQHB_*`, `PQHZ_*`, `FQHA_*`, `FQHZ_*`)는 소스 안에서 공통코드를 아직 `QS` 값으로 쓴다(예: `HRNK_CD = 'QS031'`). 공통코드는 이미 `QH`로 복사했으므로(1,032행) 소스의 코드 값도 **`QS…` → `QH…`**로 바꾼다.

```sql
-- 바꾸기 전 (PQHA_APROV_STATS_Q)
SELECT CD_NM FROM TCOA_COMCODE WHERE HRNK_CD = 'QS031' AND COM_CD = B.APRV_STATS
-- 바꾼 뒤
SELECT CD_NM FROM TCOA_COMCODE WHERE HRNK_CD = 'QH031' AND COM_CD = B.APRV_STATS
```

## 2. 원칙

- **바꾸는 대상은 QH 이관으로 새로 만든 객체뿐이다.** vplus의 기존 객체(기존 QS 프로시저, `VQSZ_*` 뷰, 공통 함수 등)는 바꾸지 않는다.
- 소스를 바꾼 객체는 **`DROP` 후 `CREATE`**로 다시 만든다. `CREATE OR REPLACE`는 쓰지 않는다. 지우기 전에 대상이 QH 매핑표(`migration_qh/02_generate/mapping.csv`)에 있는 객체인지 확인한다.
- 코드 값만 바꾼다. 로직, 컬럼, 다른 문자열은 바꾸지 않는다.
- vplus 공통코드(`TCOA_COMCODE`)는 바꾸지 않는다. 기존 QS 코드 776행도 그대로 둔다.

## 3. 조사 결과

QH 객체 289개(TYPE 2, 함수 12, 프로시저 275)의 소스를 조회해, `QS`가 들어간 곳을 모두 분류했다.

| # | 구분 | 규모 | 처리 |
|---|---|---|---|
| A | **공통코드 값 문자열**. 공통코드 조회(`HRNK_CD = 'QS031'`) 153곳과, 업무 컬럼에 쓴 고정값(`RISK_GRD = 'QS0900201'`, `JB_CD IN ('QS07702')`, `THEN 'QS0740202'`) 65곳 | **47종, 218곳, 객체 78개** | **`QS` → `QH`로 바꾼다.** 47종 모두 vplus에 QH 코드가 있다(확인함). 전체 목록은 부록 A |
| B | **오류 메시지 안의 코드 표기**. 예: `'… 결재진행코드(QS005) 1 1차 …필수 입력사항 입니다.'` | 문구 7종, 25곳, 객체 19개 | **`QS` → `QH`로 바꾼다**(6장 결정 1). 목록은 부록 B |
| C | `BB.USR_KND = 'QS'` (`PQHA_SITECURST_Q`, `PQHA_SITEMA_NAM_Q`, `PQHA_SITENAM_Q`) | 3곳 | **`'QH'`로 바꾼다**(6장 결정 4). 공통코드가 아니라 사용자 구분 값이다(`TCOZ_USR_INFO.USR_KND`, 현재 값 `C`/`P`/`ADMIN`) |
| D | 주석 안의 QS 코드·이름 | 952곳, 객체 105개 | **바꾸지 않는다.** 실행과 관계없다 |
| E | 식별자로 쓴 vplus 기존 객체 이름(`VQSZ_TRADE`, `FQSE_GET_AFTL_CNT` 등) | | **바꾸지 않는다.** 공통코드가 아니다(QH 이관 1장) |

- 소스를 바꾸는 객체는 A·B·C를 합쳐 **93개**다(A 78개, B까지 92개, C의 `PQHA_SITEMA_NAM_Q`가 더해져 93개). `PQHA_*` 76개와 `PQHB_*` 17개이고, 함수와 TYPE은 없다.
- A의 218곳 중 153곳은 공통코드 조회다(`TCOA_COMCODE`의 `HRNK_CD`/`COM_CD` 조건). 나머지 65곳은 **고정값**이다(3-1장).
- `LIKE 'QS%'`처럼 앞부분만 비교하거나, `'QS' || …`처럼 이어 붙여서 코드를 만드는 곳은 없다(확인함). 소문자 `qs`가 들어간 문자열도 없다.

## 3-1. A 중 고정값으로 쓴 곳 (용도별 내역)

**이 장의 고정값은 새로 찾은 대상이 아니다. A(47종, 218곳)와 부록 A에 처음부터 들어 있던 것을 용도별로 나눠 보인 것이다.** A 중에서 공통코드 테이블을 조회하지 않고, 업무 컬럼이나 파라미터와 **값을 직접 비교하거나 결과로 저장하는** 곳이다. 여기에 C(`USR_KND = 'QS'`)를 함께 적었다. 예: `RISK_GRD = 'QS0900201'`, `THEN 'QS0740202'`, `USR_KND = 'QS'`. 모두 68곳이다.

| 컬럼(뜻) | 고정값 | 곳 | 객체 | 비교·저장하는 곳 | 지금 데이터 | 처리 |
|---|---|---:|---|---|---|---|
| `RISK_GRD`(위험등급) | `QS0900201`, `QS0900202`, `QS0900203` | 30 | `PQHA_DASHBOARD_Q`, `PQHA_RISK_CHK_AGO_Q`, `PQHB_DAYSAFE_DT_W`, `PQHB_RISK_CHK_S`, `PQHB_SAFT_MNG_ASSIGN_Q`, `PQHB_SAFT_MNG_COPY_W` | `TQHA_RISK_CHK`, `TQHB_RISK_CHK`, `TQHB_DAYSAFE_CHKLST`, `TQHB_DAYSAFE_DT` 등(비교, 그리고 `CASE … THEN`으로 저장) | 모두 0건. 데이터가 있는 `TQHA/TQHB_CTPUNT_CHKITM`도 `RISK_GRD`는 전부 NULL | **QH로 바꾼다** |
| `CHK_DIV`, `HO_CHK_DIV_CD2`(본사 점검구분) | `QS07301`, `QS07302`, `QS0730101`~`QS073020103` 등 15종, 결과값 `QS0740102`, `QS0740202` | 29 | `PQHA_HOCHKRPT_Q`, `PQHA_HOCHKRPT_S`, `PQHA_HOCHKRPT_CK_Q` | `TQHA_CKLST`, `TQHA_CKLST_ITM`, `TQHA_HOCHKRPT*`, 파라미터 `p_CHK_DIV` | `TQHA_CKLST` 118행, `TQHA_CKLST_ITM` 395행에 QS 값(4장). `TQHA_HOCHKRPT*`는 0건 | **QH로 바꾼다.** 데이터도 함께 수정한다(결정 2) |
| `JB_CD`(직무) | `QS07702`, `QS07703` | 5 | `PQHA_DAYSAFE_CHKLST_B1`, `PQHA_RISK_CHK_B1`, `PQHA_SAFE_PERREQ_B1`, `PQHA_SITENAM_S` | `TQHA_SITENAM.JB_CD`, 파라미터 `p_JB_CD` | 0건 | **QH로 바꾼다** |
| `SIT_TERR`(현장지역) | `QSZ0599` | 1 | `PQHA_HODCAB_S` | `TQHA_SAFT_SIT.SIT_TERR` | 0건 | **QH로 바꾼다** |
| `USR_KND`(사용자 구분) | `QS` | 3 | `PQHA_SITECURST_Q`, `PQHA_SITEMA_NAM_Q`, `PQHA_SITENAM_Q` | vplus 기존 테이블 `TCOZ_USR_INFO.USR_KND` | 값은 `C` 471, `P` 19, `ADMIN` 1. `QS`인 행은 없다 | **`'QH'`로 바꾼다**(C, 결정 4) |

- 고정값 65곳(USR_KND 제외)은 모두 공통코드 값(QS090, QS073, QS074, QS077, QSZ05 그룹)이다. QH 코드가 모두 있다.
- 비교·저장 대상 테이블은 모두 QH 이관으로 만든 테이블이다. 데이터가 있는 곳은 `TQHA_CKLST`, `TQHA_CKLST_ITM`뿐이고, 결정 2로 함께 수정한다. 그래서 바꾼 뒤 기존 데이터와 어긋나는 곳은 없다.
- **주의할 점**: `p_CHK_DIV`, `p_JB_CD` 같은 파라미터 값은 화면(앱)이 넘긴다. 바꾼 뒤에는 앱도 QH 코드를 넘겨야 조건이 맞는다. 앱 수정은 이번 범위 밖이다(9장).
- `USR_KND = 'QS'`는 `'QH'`로 바꾼다(결정 4). `TCOZ_USR_INFO`에는 `QS`도 `QH`도 없어서, 바꾸기 전후 모두 이 조건은 지금 참이 되지 않는다(조회 결과는 같다). `TCOZ_USR_INFO`는 vplus 기존 테이블이라 값은 바꾸지 않는다.
- 예전에 "JH에도 없는 코드"로 적었던 `QSZ14`, `QSZ1410`, `QSZ1490`은 주석 안에만 있다(D). 실행에는 영향이 없다.

## 4. 함께 봐야 할 데이터 (중요)

A의 코드 값 중 11종은 복사한 데이터와 직접 비교된다. 데이터는 아직 `QS` 값이다.

| 객체 | 비교하는 곳 | 데이터 |
|---|---|---|
| `PQHA_HOCHKRPT_Q` | `A.CHK_DIV IN ('QS0730101', 'QS0730102')`, `IN ('QS073020101', …)` | 점검 보고서의 점검구분. `TQHA_HOCHKRPT`는 아직 0건 |
| `PQHA_HOCHKRPT_S` | `A.HO_CHK_DIV_CD2 IN ('QS073010101', …) THEN 'QS0740202'` | `TQHA_CKLST`·`TQHA_CKLST_ITM`의 `HO_CHK_DIV_CD2` |
| `PQHA_HOCHKRPT_CK_Q` | `SUBSTR(p_CHK_DIV, 1, 7) = 'QS07301' AND CK.COM_CD = p_CHK_DIV` | `TQHA_CKLST`의 `COM_CD` |

- `TQHA_CKLST`(118행)와 `TQHA_CKLST_ITM`(395행)의 `COM_CD`(3종)와 `HO_CHK_DIV_CD2`(13종)에는 `QS073…` 값이 들어 있다.
- 소스만 `QH`로 바꾸고 이 데이터를 그대로 두면, 위 조건이 맞지 않아 본사 점검 체크리스트가 조회되지 않는다. 데이터만 바꾸고 소스를 두어도 마찬가지다.
- 그래서 **소스와 이 두 테이블의 코드 값을 함께 바꾼다**(6장 결정 2, 확정). 두 테이블은 QH 이관으로 새로 만든 테이블이라 vplus 기존 데이터는 바뀌지 않는다. 이전에 보류했던 공통코드 계획 9-3장 1번의 데이터 부분이 여기에 해당한다.

## 5. 방법

1. **변환 스크립트로 코드 값을 바꾼다**. 이전 산출물(`migration_qh/`)은 고치지 않고, 그 생성 SQL을 입력으로 읽어 `scripts/qh_code_literal/`에 결과를 만든다. 자세한 절차는 [QH_CODE_LITERAL_ROADMAP.md](QH_CODE_LITERAL_ROADMAP.md)에 있다.
   - 코드 영역의 문자열 리터럴 중 값 전체가 A의 47종과 같으면 `QH…`로 바꾼다.
   - B 문구 안의 `(QS005)`, `QSZ03` 같은 코드 표기도 바꾼다(결정 1). 문구의 나머지 글자는 그대로 둔다.
   - `USR_KND = 'QS'`(3곳)는 `'QH'`로 바꾼다(결정 4).
   - 주석과 식별자는 건드리지 않는다.
   - 바꾸기 전에 대상 객체의 vplus 현재 소스를 저장한다(되돌리기용).
2. **변경 비교 리포트**: 바꾸기 전후 SQL을 객체별로 비교한다. 바뀐 부분이 A(와 B)의 코드 값뿐인지 확인한다.
3. **객체 다시 만들기**: 소스가 바뀐 객체(93개)만 `DROP` 후 `CREATE`한다. 그 뒤 INVALID가 된 새 객체만 다시 컴파일한다.
4. **데이터 코드 값 변경**(결정 2): `TQHA_CKLST`, `TQHA_CKLST_ITM`의 `COM_CD`, `HO_CHK_DIV_CD2`를 `QS…` → `QH…`로 `UPDATE`한다. 513행이다.
   - 두 테이블은 PK에 `COM_CD`, `HO_CHK_DIV_CD2`가 들어 있고, `FK`는 없다.
   - 바꾼 키가 기존 키와 겹치지 않는지 미리 검사한다.
5. **검증**
   - 다시 만든 객체가 모두 VALID인지 확인한다.
   - 남은 QS 문자열을 확인한다. A·B·C는 0곳이어야 하고, 주석은 그대로여야 한다.
   - vplus 소스가 새 생성 SQL과 같은지 확인한다.
   - 데이터 513행의 코드 값이 모두 QH 코드로 공통코드에 있는지 확인한다.
   - QH 1단계 기준선과 비교해 기존 vplus 객체의 변화가 0건인지 확인한다.

## 6. 결정이 필요한 사항

| # | 항목 | 제안 |
|---|---|---|
| 1 | 오류 메시지 안의 코드 표기(B, 25곳)도 `QH`로 바꿀지 | **확정(2026-11-13): 바꾼다** |
| 2 | `TQHA_CKLST`·`TQHA_CKLST_ITM`의 코드 값(513행)을 함께 바꿀지 | **확정(2026-11-13): 함께 수정한다** |
| 3 | 주석 안의 QS 코드(952곳) | **확정(2026-11-13): 바꾸지 않는다** |
| 4 | `BB.USR_KND = 'QS'`(C, 3곳) | **확정(2026-11-13): `'QH'`로 바꾼다.** 소스를 바꾸는 객체는 93개 |

## 7. 진행 단계

산출물 위치: `erp-jh/scripts/qh_code_literal/`. 단계마다 결과를 보고하고 승인을 받는다.

| 단계 | 내용 | DB |
|---|---|---|
| 1 | 기준선 저장: QH 객체 상태·소스 해시, `TQHA_CKLST`·`TQHA_CKLST_ITM` 전체 값 | 조회 |
| 2 | 생성 SQL 백업, 생성 스크립트 수정과 재생성, 변경 비교 리포트, 데이터 `UPDATE` SQL과 되돌리기 SQL 생성 | 조회 |
| 3 | 객체 다시 만들기(`DROP` → `CREATE`, 재컴파일) | vplus 쓰기 |
| 4 | 데이터 코드 값 `UPDATE`(결정 2) | vplus 쓰기 |
| 5 | 검증 | 조회 |
| 6 | 결과 보고(이 문서에 덧붙임) | |

## 8. 되돌리기

- **객체**: 2단계에서 백업한 생성 SQL로 해당 객체를 다시 만든다(`DROP` → `CREATE`). 원래 소스로 돌아간다.
- **데이터**: `UPDATE`를 거꾸로 하는 SQL(`QH…` → `QS…`)을 2단계에서 함께 만든다.
- vplus 기존 객체와 공통코드는 바꾸지 않으므로 되돌릴 것이 없다.

## 9. 이번 범위 밖

- vplus 앱(화면, 매퍼, JSP/JS)이 공통코드를 `QS`로 부르는 부분.
- vplus 기존 QS 공통코드 776행의 정리.
- 구조만 만든 94개 테이블은 지금 데이터가 없다. 앞으로 화면에서 저장되는 코드 값은 앱이 넘기는 값을 따른다.

## 10. 실행 결과 (2026-11-13)

> 진행: [QH_CODE_LITERAL_ROADMAP.md](QH_CODE_LITERAL_ROADMAP.md) 1~6단계 · 산출물: `erp-jh/scripts/qh_code_literal/`
> vplus만 접속했다(JH 접속 안 함). QS 객체·QS 공통코드·기존 파일은 수정하지 않았다.

### 10-1. 단계별 결과

| 단계 | 시각 | 내용 | 결과 |
|---|---|---|---|
| 1. 기준선 저장 | 15:56 | QH 기준선, `TQHA_CKLST`/`TQHA_CKLST_ITM` 전체 값 513행, QH 코드 객체 289개 원래 소스(`orig_sources.sql`) | vplus 현재 소스가 `migration_qh` 생성 SQL과 같음 |
| 2. 변경 SQL 생성 | 15:59 | `10_recreate.sql`(93개), `20_data_update.sql`, `80_diff_report.md`, `98_rollback_data.sql`, `99_rollback_objects.sql` | 자동 검사 15개 모두 OK. A 218·B 25·C 3곳, 규칙 밖 차이 0 |
| 3. 객체 다시 만들기 | 16:01 | 93개 `DROP` → `CREATE` | 93개 성공. 호출 객체 2개(`PQHA_SAFECOST_INFO_S`, `PQHB_RISK_DGR_W`)가 INVALID → 재컴파일 1회로 0 |
| 4. 데이터 수정 | 16:03 | `COM_CD`, `HO_CHK_DIV_CD2`의 `QS…` → `QH…` (한 트랜잭션) | `TQHA_CKLST` 118행, `TQHA_CKLST_ITM` 395행, QS 잔존 0 확인 후 커밋 |
| 5. 검증 | 16:06 | 조회만 | 아래 10-2, 모두 OK |

### 10-2. 검증 결과 (`05_verify/step5_result.json`)

| 항목 | 결과 |
|---|---|
| 다시 만든 93개 + 호출 객체 2개 | 95개 모두 VALID, `USER_ERRORS` 0 |
| vplus 소스 = `10_recreate.sql` | 93개 모두 같음 |
| 코드 영역의 `'QS…'` 문자열 | 0곳 (QH 문자열 246곳 = A 218 + B 25 + C 3) |
| `TQHA_CKLST` | 118행, 모두 QH, 다른 컬럼 차이 0, 공통코드에 없는 코드 0 |
| `TQHA_CKLST_ITM` | 395행, 모두 QH, 다른 컬럼 차이 0, 공통코드에 없는 코드 0 |
| 객체 (기준선 비교) | 886 → 886, 추가·삭제 0, 바뀐 것은 대상 95개뿐 |
| 소스 (기준선 비교) | 510 → 510, 바뀐 것은 93개뿐 |
| 제약조건 / 테이블 건수 | 565개 차이 0 / 191개 테이블 건수 차이 0 |

### 10-3. 되돌리기

1. `02_generate/99_rollback_objects.sql`: 93개를 원래 소스로 `DROP` → `CREATE`
2. 호출 객체 2개 재컴파일
3. `02_generate/98_rollback_data.sql`: 데이터 `QH` → `QS`

### 10-4. 남은 사항 (범위 밖)

- vplus 앱이 `p_CHK_DIV`, `p_JB_CD` 등에 QS 코드를 넘기는 부분. 앱이 QH 코드를 넘기도록 바꾸기 전에는 이 조건이 맞지 않는다.
- vplus 기존 QS 공통코드 776행 정리.
- 주석 안의 QS 코드는 그대로 두었다(결정 3).

## 부록 A. 바꿀 공통코드 값 (47종, 218곳)

| 지금 | 바꾼 뒤 | 곳 | 객체 수 | 객체(일부) |
|---|---|---:|---:|---|
| `'QS001'` | `'QH001'` | 1 | 1 | `PQHA_RISKPLAN_Q` |
| `'QS002'` | `'QH002'` | 4 | 3 | `PQHA_RISKPLAN_Q`, `PQHA_RISK_ITM_LIST_OTHER_Q`, `PQHA_RISK_PLAN_OTHER_Q` |
| `'QS003'` | `'QH003'` | 4 | 3 | `PQHA_RISKPLAN_Q`, `PQHA_RISK_ITM_LIST_OTHER_Q`, `PQHA_RISK_PLAN_OTHER_Q` |
| `'QS004'` | `'QH004'` | 4 | 3 | `PQHA_RISKPLAN_Q`, `PQHA_RISK_ITM_LIST_OTHER_Q`, `PQHA_RISK_PLAN_OTHER_Q` |
| `'QS005'` | `'QH005'` | 12 | 9 | `PQHA_DAYSAFE_CHKLST_Q`, `PQHA_MEET_DRFT_OTHER_Q`, `PQHA_RISKPLAN_Q` 외 6개 |
| `'QS024'` | `'QH024'` | 4 | 3 | `PQHA_RISKPLAN_Q`, `PQHA_RISK_ITM_LIST_OTHER_Q`, `PQHA_RISK_PLAN_OTHER_Q` |
| `'QS025'` | `'QH025'` | 3 | 2 | `PQHA_DAY_SAFT_CHK_REG_OTHER_Q`, `PQHA_NCR_REP_Q` |
| `'QS026'` | `'QH026'` | 28 | 5 | `PQHA_SAFECOST_ARSLT_CO_DIV_Q`, `PQHA_SAFECOST_ARSLT_Q`, `PQHA_SAFECOST_BGTYM_B` 외 2개 |
| `'QS031'` | `'QH031'` | 43 | 35 | `PQHA_APROV_STATS_Q`, `PQHA_APRV_Q`, `PQHA_ASSLOG_CIRC_S` 외 32개 |
| `'QS035'` | `'QH035'` | 3 | 2 | `PQHA_CTP_PSN_Q`, `PQHA_RISK_PLAN_OTHER_Q` |
| `'QS036'` | `'QH036'` | 2 | 1 | `PQHA_RISK_ITM_LIST_OTHER_Q` |
| `'QS039'` | `'QH039'` | 5 | 2 | `PQHA_APROV_PAGE_NM_Q`, `PQHA_APRV_Q` |
| `'QS046'` | `'QH046'` | 1 | 1 | `PQHA_DASHBOARD_CO_Q` |
| `'QS050'` | `'QH050'` | 1 | 1 | `PQHA_IDAC_Q` |
| `'QS060'` | `'QH060'` | 2 | 1 | `PQHA_DRM_Q` |
| `'QS061'` | `'QH061'` | 2 | 2 | `PQHA_DRM_Q`, `PQHA_VIEW_REQ_Q` |
| `'QS062'` | `'QH062'` | 1 | 1 | `PQHA_DRM_Q` |
| `'QS063'` | `'QH063'` | 2 | 1 | `PQHA_RISK_ITM_LIST_OTHER_Q` |
| `'QS066'` | `'QH066'` | 1 | 1 | `PQHA_HLTH_CHKUP_EXCEL_S` |
| `'QS067'` | `'QH067'` | 1 | 1 | `PQHA_HLTH_CHKUP_EXCEL_S` |
| `'QS068'` | `'QH068'` | 2 | 2 | `PQHA_HLTH_CHKUP_EXCEL_DEL_S`, `PQHA_HLTH_CHKUP_EXCEL_S` |
| `'QS070'` | `'QH070'` | 1 | 1 | `PQHA_IDAC_Q` |
| `'QS07301'` | `'QH07301'` | 2 | 2 | `PQHA_HOCHKRPT_CK_Q`, `PQHA_HOCHKRPT_S` |
| `'QS0730101'` | `'QH0730101'` | 1 | 1 | `PQHA_HOCHKRPT_Q` |
| `'QS073010101'` | `'QH073010101'` | 2 | 1 | `PQHA_HOCHKRPT_S` |
| `'QS073010102'` | `'QH073010102'` | 2 | 1 | `PQHA_HOCHKRPT_S` |
| `'QS073010103'` | `'QH073010103'` | 2 | 1 | `PQHA_HOCHKRPT_S` |
| `'QS0730102'` | `'QH0730102'` | 1 | 1 | `PQHA_HOCHKRPT_Q` |
| `'QS073010201'` | `'QH073010201'` | 2 | 1 | `PQHA_HOCHKRPT_S` |
| `'QS073010202'` | `'QH073010202'` | 2 | 1 | `PQHA_HOCHKRPT_S` |
| `'QS073010203'` | `'QH073010203'` | 2 | 1 | `PQHA_HOCHKRPT_S` |
| `'QS07302'` | `'QH07302'` | 2 | 2 | `PQHA_HOCHKRPT_CK_Q`, `PQHA_HOCHKRPT_S` |
| `'QS073020101'` | `'QH073020101'` | 3 | 2 | `PQHA_HOCHKRPT_Q`, `PQHA_HOCHKRPT_S` |
| `'QS073020102'` | `'QH073020102'` | 3 | 2 | `PQHA_HOCHKRPT_Q`, `PQHA_HOCHKRPT_S` |
| `'QS073020103'` | `'QH073020103'` | 3 | 2 | `PQHA_HOCHKRPT_Q`, `PQHA_HOCHKRPT_S` |
| `'QS0740102'` | `'QH0740102'` | 2 | 1 | `PQHA_HOCHKRPT_S` |
| `'QS0740202'` | `'QH0740202'` | 2 | 1 | `PQHA_HOCHKRPT_S` |
| `'QS077'` | `'QH077'` | 19 | 10 | `PQHA_APROV_LINE_Q`, `PQHA_ASSLOG_CIRC_Q`, `PQHA_RISK_CHK_Q` 외 7개 |
| `'QS07702'` | `'QH07702'` | 3 | 3 | `PQHA_DAYSAFE_CHKLST_B1`, `PQHA_RISK_CHK_B1`, `PQHA_SAFE_PERREQ_B1` |
| `'QS07703'` | `'QH07703'` | 2 | 2 | `PQHA_DAYSAFE_CHKLST_B1`, `PQHA_SITENAM_S` |
| `'QS0900201'` | `'QH0900201'` | 13 | 6 | `PQHA_DASHBOARD_Q`, `PQHA_RISK_CHK_AGO_Q`, `PQHB_DAYSAFE_DT_W` 외 3개 |
| `'QS0900202'` | `'QH0900202'` | 12 | 5 | `PQHA_DASHBOARD_Q`, `PQHB_DAYSAFE_DT_W`, `PQHB_RISK_CHK_S` 외 2개 |
| `'QS0900203'` | `'QH0900203'` | 5 | 2 | `PQHB_DAYSAFE_DT_W`, `PQHB_RISK_CHK_S` |
| `'QSC01'` | `'QHC01'` | 2 | 1 | `PQHA_MMEDUPLAN_Q` |
| `'QSZ0360'` | `'QHZ0360'` | 1 | 1 | `PQHA_HOCHKRPT_CK_Q` |
| `'QSZ05'` | `'QHZ05'` | 2 | 1 | `PQHA_SITECURST_Q` |
| `'QSZ0599'` | `'QHZ0599'` | 1 | 1 | `PQHA_HODCAB_S` |

## 부록 B. 코드 표기가 들어간 오류 메시지 (7종, 25곳)

| 문구 | 곳 | 객체 |
|---|---:|---|
| `공종별 구분코드(QS035) 01건축 02토목는(은) 필수 입력사항 입니다.` | 1 | `PQHA_CTP_PSN_S` |
| `공통코드 : QSZ0310는(은) 필수 입력사항 입니다.` | 1 | `PQHA_HOCHKRPT_CK_S` |
| `공통코드 : QSZ03는(은) 필수 입력사항 입니다.` | 3 | `PQHA_HOCHKRPT_CK_S`, `PQHA_HOCHKRPT_ERR_S` |
| `안전관리비 예산구분(QS026) 1 안전인건비 는(은) 필수 입력사항 입니다.` | 4 | `PQHA_SAFECOST_ARSLT_CO_S`, `PQHA_SAFECOST_ARSLT_S`, `PQHA_SAFECOST_BGTYM_S` 외 1개 |
| `위험등급(QS09002) 작성는(은) 필수 입력사항 입니다.` | 4 | `PQHB_DAYSAFE_CHKLST_S`, `PQHB_DAYSAFE_DT_S`, `PQHB_DAYSAFE_NAM_S` 외 1개 |
| `차수구분코드(QS005) 1 1차,2 2차는(은) 필수 입력사항 입니다.` | 11 | `PQHA_ASSLOG_CIRC_S`, `PQHA_DAYSAFE_CHKLST_S`, `PQHA_RISK_CHK_S` 외 8개 |
| `차수구분코드(QS005) 는(은) 필수 입력사항 입니다.` | 1 | `PQHB_DAYSAFE_DT_W` |
