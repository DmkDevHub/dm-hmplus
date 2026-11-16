# QH 메뉴 권한·DTL 생성 계획

> 작성일: 2026-11-16 · 대상: `VPLUS202611A` · 선행 작업: [QH_MENU_COPY_PLAN.md](QH_MENU_COPY_PLAN.md)(QH 메뉴 135건 등록 완료)
> 이 문서의 내용은 vplus 소스(JSP·Java)와 DB 프로시저 본문을 읽기만 해서 확인한 것이다. **아직 실행하지 않았다.**

## 1. 목적

방금 등록한 QH 메뉴 135건에 권한(`TCOU_AUTH_OBJ`, `TCOU_AUTH_APRC`)과 메뉴함수(`TCOZ_MNU_INFO_DTL`)를 만들어, 사용자가 QH 화면을 열고 조회·저장할 수 있게 한다.
SQL로 직접 넣지 않고 **vplus 화면에서 저장**해서 만든다. 그래야 프로시저의 검증과 권한 변경 로그(`PCOU_AUTH_GRP_LOG_S`)가 함께 남는다.

## 2. 결론: 어느 화면에서 무엇이 생기나

**메뉴정보 화면(`COZ04`, `/mnu/mnuMng`)에서 메뉴를 다시 저장해도 DTL과 권한은 생기지 않는다.**
`PCOZ_MNU_INFO_S`는 `TCOZ_MNU_INFO`만 INSERT/UPDATE한다. 권한을 지우는 건 메뉴를 삭제할 때뿐이다.

실제로 생성되는 경로는 다음과 같다.

| 만들 데이터 | 화면 (메뉴코드, URL) | 저장 프로시저 | 생성 방식 |
|---|---|---|---|
| 메뉴 사용권한 `TCOU_AUTH_OBJ` | 권한그룹 (`COB01`, `/auth/authGrp`) 가운데 메뉴 그리드 | `PCOU_AUTH_MNU_S` | 그룹 1개 × 체크한 메뉴마다 MERGE |
| 상세권한 `TCOU_AUTH_APRC` | 권한그룹 (`COB01`) 오른쪽 상세권한 그리드 | `PCOU_AUTH_APRC_S` | **그룹(SYS0101) 메뉴에서 저장하면 하위 메뉴 전체에 일괄 생성** |
| 위 두 가지를 메뉴 단위로 | 메뉴권한 (`COB05`, `/auth/authMnu`) | `PCOU_MNU_AUTH_INFO_S` | 메뉴 1개 × 그룹마다 두 테이블을 MERGE |
| 메뉴함수 `TCOZ_MNU_INFO_DTL` | (화면 없음) QH 화면을 실제로 사용 | `PCOU_MNU_AUTH_CHECK` | 처음 호출된 URL을 자동 등록 |
| 메뉴함수 보정 | 메뉴함수 (`COZ11`, `/auth/mnuMethodAuth`), 메뉴정보 (`COZ04`) 아래쪽 그리드 | `set_MenuMethodAuth` (MERGE) | 수동 입력 |

권장 경로는 **권한그룹 화면(`COB01`)에서 그룹 단위로 저장**하는 것이다(4장). 메뉴권한 화면(`COB05`)은 메뉴 한 개씩 저장해야 해서, 권한 대상 76개 메뉴에는 맞지 않는다.

## 3. 현재 상태

| 항목 | QH | 참고: vplus QS (SYSADM 그룹) |
|---|---:|---:|
| `TCOU_AUTH_OBJ` | 0 | 124 (그룹 35, 메뉴 82, 숨김 7) |
| `TCOU_AUTH_APRC` | 0 | 124 (모두 `AUTH_GRD=0`, `UPD_YN=1`, `PRNT_YN=1`) |
| `TCOZ_MNU_INFO_DTL` | 0 | 807 (QS 전체) |

- 권한은 **그룹(SYS0101)·메뉴(SYS0102)·숨김(SYS0103)** 메뉴에만 준다. 상속(SYS0106) 메뉴는 권한 그리드에 나오지 않고, 상위 메뉴 권한을 따른다.
- QH에서 권한을 줄 메뉴는 **그룹 1개당 최대 76건**이다: root `QH` 1, 그룹 9, 메뉴 63, 숨김 3. 이 중 `USE_YN='0'` 메뉴 9건은 일괄 상세권한에서 빠진다.
- 권한이 없는 지금은 메뉴 트리에는 보이지만, 화면을 열면 "해당화면에 권한이 존재하지 않습니다"가 뜬다. `PCOU_MNU_AUTH_Q`가 `TCOU_AUTH_OBJ`를 INNER JOIN하기 때문이다.

## 4. 권한 부여 절차 (권한그룹 화면 `COB01`)

권한 줄 그룹마다 4-1~4-3을 반복한다. **반드시 4-1(사용권한)을 먼저 저장한 뒤 4-2(상세권한)를 저장한다.** 일괄 상세권한은 그 그룹의 `TCOU_AUTH_OBJ`에 있는 메뉴만 대상으로 하기 때문이다.

### 4-1. 메뉴 사용권한 (`TCOU_AUTH_OBJ`)

1. `권한관리 > 권한그룹`을 연다.
2. 왼쪽 그리드에서 그룹을 선택한다(예: `SYSADM`).
3. 가운데 메뉴 트리에서 `(신)안전`을 찾아 **사용** 체크박스를 켠다.
4. 하위 메뉴에도 같은 값을 주려면 **메뉴명을 더블클릭**하고 "하위메뉴를 모두 동일한 값으로 변경하시겠습니까?"에서 확인을 누른다.
   - 더블클릭은 **바로 아래 단계**에만 적용된다. `(신)안전` → 그룹 9개 → 각 그룹의 메뉴 순서로, 단계마다 더블클릭해야 한다.
5. 메뉴권한 **저장**을 누른다(`setGrd_AuthMenuCode` → `PCOU_AUTH_MNU_S`).

### 4-2. 상세권한 (`TCOU_AUTH_APRC`)

1. 같은 화면 가운데 트리에서 `(신)안전`(그룹 메뉴)을 클릭한다. 오른쪽 제목이 **"상세권한(일괄)"**으로 바뀌고 "하위 메뉴에 동일한 권한이 지정됩니다."가 표시된다.
   - 방금 체크해서 아직 저장하지 않은 행(상태 `U`)은 상세권한 그리드가 열리지 않는다. 4-1을 저장한 뒤 다시 조회한다.
2. **행추가** 후 권한등급·조회·수정·인쇄 값을 넣는다. vplus QS의 SYSADM과 같게 하려면 등급 `전사(법인)`(0), 수정 1, 인쇄 1로 둔다.
3. **저장**을 누른다(`setGrd_AuthAprc` → `PCOU_AUTH_APRC_S`).
   - 메뉴 종류가 그룹(SYS0101)이므로 프로시저가 `GI` 모드로 동작한다. `(신)안전` 아래에서 이 그룹의 사용권한이 있고 `USE_YN='1'`인 그룹·메뉴·숨김 메뉴의 상세권한을 **지우고 다시 만든다**.
   - 특정 메뉴만 다르게 주려면, 일괄 저장한 뒤 그 메뉴를 클릭해서 따로 저장한다. 다시 상위에서 일괄 저장하면 개별 설정이 덮어써진다.

### 4-3. 사용자 매핑 확인

권한은 그룹 단위다. 테스트할 사용자가 그 그룹에 매핑돼 있는지 같은 화면의 권한사용자 그리드나 `권한관리 > 사용자`(`COB03`)에서 확인한다.

## 5. 메뉴함수(DTL) 생성 절차

DTL은 사용하면서 쌓인다. 별도로 저장할 화면이 없다.

1. 4장에서 권한을 받은 계정으로 로그인한다.
2. QH 메뉴를 하나씩 열고 **조회**, **저장**(테스트 데이터), 팝업·하위 화면 열기를 실행한다.
3. 호출마다 `AuthorityAspect`가 `PCOU_MNU_AUTH_CHECK`를 부르고, DTL에 없는 URL이면 그 자리에서 INSERT한 뒤 통과시킨다(`registration`).
   - `MNU_CD`: 화면이 넘기는 `WRK_MNU`. 메뉴 진입 때 받은 QH 코드다.
   - `KND`: URL에 `/get`이 있으면 `Q`, `/set`이 있으면 `S`, 둘 다 없으면 `NULL`.
   - `IPT_ID`: 사용자ID 뒤에 `_v2`가 붙는다. 자동 등록된 건은 이 값으로 구분할 수 있다.
4. 다 돌린 뒤 `시스템관리 > 메뉴함수`(`COZ11`)에서 QH 메뉴를 조회해 보정한다.
   - `KND`가 비어 있는 행은 `조회`(Q)나 `저장`(S)으로 지정한다.
   - 결재(`A`)는 자동으로 정해지지 않는다. 결재 URL은 직접 바꾼다.

주의:
- DTL이 쌓이기 전에도 조회·저장은 막히지 않는다(`registration`은 통과). 다만 첫 호출 뒤부터는 `S` URL이 **수정 권한(`UPD_YN=1`)이 있는 그룹에서만** 통과한다.
- 수정 권한이 없는 계정으로 먼저 돌리면, DTL은 생기지만 저장은 그다음 호출부터 막힌다. 수정 권한이 있는 계정으로 돌린다.
- 화면에서 호출하지 않은 URL은 DTL에 생기지 않는다. 화면마다 버튼을 빠짐없이 눌러 본다.

## 6. 검증 SQL (조회만)

```sql
-- 6-1. 그룹별 사용권한 건수 (그룹당 최대 76)
SELECT O.GRP_CD, M.MNU_KND, COUNT(*)
  FROM TCOU_AUTH_OBJ O JOIN TCOZ_MNU_INFO M ON M.MNU_CD = O.MNU_CD
 WHERE O.MNU_CD = 'QH' OR O.MNU_CD LIKE 'QH_%'
 GROUP BY O.GRP_CD, M.MNU_KND ORDER BY 1, 2;

-- 6-2. 사용권한은 있는데 상세권한이 없는 메뉴 (USE_YN='1' 기준, 0건이어야 함)
SELECT O.GRP_CD, O.MNU_CD
  FROM TCOU_AUTH_OBJ O JOIN TCOZ_MNU_INFO M ON M.MNU_CD = O.MNU_CD
 WHERE (O.MNU_CD = 'QH' OR O.MNU_CD LIKE 'QH_%') AND O.USE_YN = '1' AND M.USE_YN = '1'
   AND NOT EXISTS (SELECT 1 FROM TCOU_AUTH_APRC A WHERE A.GRP_CD = O.GRP_CD AND A.MNU_CD = O.MNU_CD);

-- 6-3. 상세권한 값 분포
SELECT GRP_CD, AUTH_GRD, UPD_YN, PRNT_YN, COUNT(*)
  FROM TCOU_AUTH_APRC WHERE MNU_CD = 'QH' OR MNU_CD LIKE 'QH_%'
 GROUP BY GRP_CD, AUTH_GRD, UPD_YN, PRNT_YN ORDER BY 1;

-- 6-4. 메뉴함수 진행 상황 (KND별)
SELECT NVL(KND, '(null)') KND, COUNT(*) FROM TCOZ_MNU_INFO_DTL WHERE MNU_CD LIKE 'QH%' GROUP BY KND;

-- 6-5. DTL이 아직 하나도 없는 QH 메뉴·숨김 화면
SELECT M.MNU_CD, M.MNU_NM, M.URL FROM TCOZ_MNU_INFO M
 WHERE M.MNU_CD LIKE 'QH_%' AND M.MNU_KND IN ('SYS0102','SYS0103','SYS0106') AND M.USE_YN = '1'
   AND NOT EXISTS (SELECT 1 FROM TCOZ_MNU_INFO_DTL D WHERE D.MNU_CD = M.MNU_CD)
 ORDER BY M.MNU_CD;
```

## 7. 결정할 사항

| # | 항목 | 기본안 |
|---|---|---|
| 1 | 권한 줄 그룹 | `SYSADM` 먼저. 확인 후 8장 후보에서 추가 |
| 2 | 상세권한 값 | vplus QS의 SYSADM과 같게: 등급 `전사(법인)`(0), 수정 1, 인쇄 1 |
| 3 | `USE_YN='0'` 메뉴 9건 사용권한 | 트리 일괄 체크에 포함(일괄 상세권한에서는 자동으로 빠짐) |
| 4 | DTL 생성 계정 | 수정 권한이 있는 테스트 계정 |

## 8. 참고: vplus QS 메뉴에 권한이 있는 그룹

QH 권한 그룹을 정할 때 참고한다. 건수는 vplus `TCOU_AUTH_OBJ`의 QS 메뉴 건수다.

| 그룹 | 이름 | QS 건수 |
|---|---|---:|
| `SYSADM` | 시스템관리자 | 124 |
| `11290` | 시스템관리자(IT) | 171 |
| `QS001` | 안전팀 | 94 |
| `QS101` | 본사안전 | 93 |
| `QS002` | 안전팀(협력업체) | 15 |
| `CM_05`~`CM_09` | 현장소장·공사·공무·안전·관리 | 122~123 |
| `10020` | 공통권한(현장) | 61 |
| `EX01` | 임원그룹 | 52 |
| `FI01` | 회계담당_관리자 | 52 |
| `Z01` | 예산관리 | 78 |
| `11291` | 시연용 | 139 |
| `11289`, `X9999` | 모의해킹(일반), 모의해킹 | 124 |
| `BM03`, `CS003`, `CS004` | 전략경영_추가그룹, 품질관리팀(건축), 토목지원(안전) | 5 |
| `11400`, `11500`, `FI02`, `FI03`, `R1000`, `TR01` | (일부 삭제예정 그룹 포함) | 1~121 |
