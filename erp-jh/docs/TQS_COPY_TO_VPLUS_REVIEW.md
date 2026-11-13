# TQS 테이블 vplus 복사 사전 검토 (JH TQSA → TQSB)

> 작성일: 2026-11-13 · 근거: 두 DB의 데이터 딕셔너리 조회(SELECT 전용, DB 변경 없음)

## 0. 결론

**계획 그대로는 진행할 수 없다.** 실행 전에 반드시 정해야 할 것이 1건, 방법을 바꿔야 할 것이 3건 있다.

| 구분 | 문제 | 요지 |
|---|---|---|
| ⛔ 결정 필요 | 대상 이름 충돌 8쌍 | JH에 `TQSA_X`와 `TQSB_X`가 둘 다 있다. TQSA_X를 TQSB_X로 바꾸면 기존 TQSB_X와 이름이 같아진다. 두 테이블은 구조와 데이터가 다르다. |
| ⚠ 방법 변경 | 제약조건·인덱스 이름 | `PK_TQSA_...` 같은 이름이 vplus에 이미 있다. 테이블 이름만 바꾸면 PK 생성이 실패한다. 이름 안의 `TQSA`도 `TQSB`로 바꿔야 한다. |
| ⚠ 방법 변경 | DDL 원본 | `erp-jh/scripts/JH_QS/*.sql`에는 PK·FK·NOT NULL이 없다. 이 스크립트만으로 만들면 제약조건이 전부 빠진다. |
| ⚠ 방법 변경 | 복사 경로 | 두 계정이 서로의 테이블을 조회할 권한이 없다. `CREATE TABLE ... AS SELECT`로 바로 복사할 수 없다. |

그 밖의 항목(vplus의 기존 객체와 테이블 이름 충돌, 트리거·뷰·시노님, 이름 길이, 문자셋, 용량)은 문제가 없다.

## 1. 작업 범위

| 구분 | JH 테이블 | vplus에 만들 이름 | 개수 |
|---|---|---|---:|
| 이름 변경 복사 | `TQSA_*` | `TQSB_*` | 94 |
| 그대로 복사 | `TQSB_*` | `TQSB_*` | 14 |
| 합계 | | | 108 |

- 원본: JH `JH202610` (192.168.1.25:1521:ORCLU), 대상: vplus `VPLUS202611A` (같은 인스턴스)
- vplus에 이미 있는 `TQSA_*` 테이블 83개는 건드리지 않는다. 지금 vplus에는 `TQSB`로 시작하는 객체가 하나도 없다.
- 충돌을 빼면 vplus에 생길 테이블 이름은 100개다. 108개 중 8개가 다른 테이블과 이름이 겹친다.

## 2. ⛔ 대상 이름 충돌 (결정 필요)

JH에 아래 8쌍은 `TQSA_X`와 `TQSB_X`가 함께 있다. TQSA를 TQSB로 바꾸면 vplus에서 같은 이름이 된다.

| vplus 대상 이름 | JH 원본 A (`TQSA_`) | JH 원본 B (`TQSB_`) | 컬럼 수 A / B | 공통 컬럼 | 건수 A / B | A에만 있는 컬럼 | B에만 있는 컬럼 |
|---|---|---|---|---:|---|---|---|
| `TQSB_CTPUNT_CHKITM` | `TQSA_CTPUNT_CHKITM` | `TQSB_CTPUNT_CHKITM` | 21 / 20 | 20 | 12,485 / 12,484 | PRRT_REG | - |
| `TQSB_DAYSAFE_CHKLST` | `TQSA_DAYSAFE_CHKLST` | `TQSB_DAYSAFE_CHKLST` | 29 / 31 | 28 | 20 / 225 | ODAY_INSP | CHK_ITM_SEQ, EMPE_NO, RISK_GRD |
| `TQSB_DAYSAFE_DT` | `TQSA_DAYSAFE_DT` | `TQSB_DAYSAFE_DT` | 19 / 19 | 10 | 15 / 120 | MNG_APRV_DT, MNG_APRV_STATS, MNG_SUPR, SAFT_APRV_DT, SAFT_APRV_STATS, SAFT_MGR 외 3개 | EMPE_NO_OMGR, EMPE_NO_SAFT, RISK_GRD, SAFT_MGR_DT, SAFT_MGR_OPIN, SAFT_MGR_YN 외 3개 |
| `TQSB_RISKPLAN` | `TQSA_RISKPLAN` | `TQSB_RISKPLAN` | 13 / 13 | 13 | 1 / 0 | - | - |
| `TQSB_RISKPLAN_D` | `TQSA_RISKPLAN_D` | `TQSB_RISKPLAN_D` | 23 / 23 | 23 | 6 / 0 | - | - |
| `TQSB_RISK_CHK` | `TQSA_RISK_CHK` | `TQSB_RISK_CHK` | 59 / 29 | 24 | 0 / 23 | CHK_ITM_NM, CHK_LOC, DISS_SHP, IMPRV_END_DT, IMPRV_STR_DT, ITM_ADD_YN 외 29개 | APRS_NAMSEQ, DTY_CD, EMPE_NO, SBM_DT, SBM_YN |
| `TQSB_RISK_DGR` | `TQSA_RISK_DGR` | `TQSB_RISK_DGR` | 23 / 31 | 22 | 2 / 5 | APRV_NO | AREC_NAM, EMPE_NO_OMGR, EMPE_NO_SAFT, SAFT_MGR_DT, SAFT_MGR_OPIN, SAFT_MGR_YN 외 3개 |
| `TQSB_RISK_VNDR` | `TQSA_RISK_VNDR` | `TQSB_RISK_VNDR` | 27 / 19 | 17 | 4 / 9 | MNG_APRV_DT, MNG_APRV_STATS, MNG_SUPR, SAFT_APRV_DT, SAFT_APRV_STATS, SAFT_MGR 외 4개 | CTP_CD, CTP_NM |

- `TQSB_RISKPLAN`과 `TQSB_RISKPLAN_D`만 A·B의 컬럼 구성이 같다. 나머지 6쌍은 구조가 다르다.
- 충돌하는 쌍끼리는 FK도 얽혀 있다. 예: `TQSA_RISK_CHK`는 `TQSA_CTPUNT_CHKITM`과 `TQSA_RISK_VNDR`을 참조하고, `TQSB_RISK_CHK`는 `TQSB_RISK_LST`를 참조한다. 어느 쪽을 살리느냐에 따라 FK 구성이 달라진다.

**선택지**

| 안 | 내용 | 장점 | 단점 |
|---|---|---|---|
| A | 충돌 8개의 `TQSA_X`는 다른 이름으로 복사한다(예: `TQSC_X`, `TQSB_X_A`). | 데이터가 빠지지 않는다. | 규칙 밖의 이름이 생긴다. JH 프로시저를 이식할 때 이 8개는 따로 치환해야 한다. |
| B | 충돌 8개는 JH의 `TQSB_X`(원래 TQSB)만 복사하고, `TQSA_X`는 복사하지 않는다. | 이름 규칙이 유지된다. | TQSA 쪽 데이터·구조가 빠진다. 그 테이블을 쓰는 JH 기능은 이식할 수 없다. |
| C | 충돌 8개는 `TQSA_X`만 `TQSB_X`로 복사하고, 원래 `TQSB_X`는 복사하지 않는다. | TQSA 계열의 FK 관계가 유지된다. | TQSB 쪽 데이터·구조가 빠진다. |

어느 안으로 갈지는 JH에서 실제로 쓰는 테이블이 어느 쪽인지에 따라 정해야 한다. JH 프로시저 중 이 16개 테이블을 참조하는 것이 68개다. 그중 2개는 같은 쌍의 A와 B를 함께 참조한다(7장).

## 3. ⚠ 제약조건·인덱스 이름

- JH TQS 테이블의 제약조건은 352개다. 이름을 직접 붙인 PK 95개와 FK 31개, 시스템 이름(`SYS_C...`)이 붙은 NOT NULL 226개다.
- PK 이름이 `PK_TQSA_APRV`처럼 `TQSA`를 포함한다. vplus의 기존 TQSA 테이블에도 **같은 이름의 PK가 이미 있다**. 오라클에서 제약조건·인덱스 이름은 스키마 안에서 유일해야 하므로, 이름을 그대로 쓰면 `ORA-02264`/`ORA-00955`가 난다.
- 이름 안의 `TQSA`를 전부 `TQSB`로 바꾸면 vplus 기존 이름과는 하나도 겹치지 않는다(확인함). 단, 2장의 충돌 8쌍에 속한 PK·FK 8개는 바꾼 뒤 서로 이름이 같아진다. 2장을 결정할 때 함께 정해야 한다.
- 테이블 이름과 맞지 않는 PK 이름이 있다. 복사할 때 정리할지 정해야 한다.
  - `TQSA_EDU_DRY` → `PK_TQSA_IDAC4`
  - `TQSA_EDU_MSDS` → `PK_TQSA_EDU2`
  - `TQSA_HLTH_CHKUP` → `PK_TQSA_IDAC5`
  - `TQSA_HLTH_CHKUP_LIST` → `PK_TQSA_IDAC3`
  - `TQSA_MSDS_CD` → `TQSA_MSDS_CD_PK`
  - `TQSA_RISK_AREC_TEMP` → `PK_TQSA_RISK_AREC`
  - `TQSA_WEEK_WORK_LOG` → `PK_TQSA_ODAYSAFE_LOG`
  - `TQSA_WEEK_WORK_LOG_HO` → `PK_TQSA_ODAYSAFE_LOG_HO`
  - `TQSB_DAYSAFE_NAM` → `PK_TQSB_DAYSAFE_DT2`
  - `TQSB_VNDRNAM` → `PK_TQSB_SITENAM2`
- NOT NULL 제약은 시스템 이름이라 새로 만들 때 자동으로 새 이름이 붙는다. 문제없다.
- LOB 인덱스 3개(CLOB 컬럼용)는 테이블을 만들 때 자동으로 생긴다.

## 4. ⚠ DDL 원본

`erp-jh/scripts/JH_QS/*.sql` 108개를 확인한 결과 아래 내용이 들어 있다.

| 항목 | 스크립트 | JH 실제 |
|---|---:|---:|
| CREATE TABLE | 108 | 108 |
| COMMENT ON | 2,247 | 2,247 |
| PRIMARY KEY | 0 | 95 |
| FOREIGN KEY | 0 | 31 |
| NOT NULL | 0 | 226 |
| DEFAULT 포함 줄 | 7 | DEFAULT 있는 컬럼 13 |

**조치**: 이 스크립트를 DDL 원본으로 쓰지 않는다. JH에서 `DBMS_METADATA.GET_DDL`로 테이블·PK·FK·인덱스 DDL을 다시 뽑는다(조회 전용). 그다음 이름을 바꾸고, TABLESPACE를 vplus 기본(`TS_ORCLU_VPLUS202611A`)으로 바꾼다. JH 테이블은 모두 `TS_ORCLU_JH202610`에 있어서 DDL을 그대로 쓰면 vplus 쪽에서 실패한다. 코멘트는 JH_QS 스크립트나 JH 딕셔너리에서 가져와 이름만 바꾸면 된다.

## 5. ⚠ 복사 경로 (권한)

- JH와 vplus는 같은 인스턴스(orclu)에 있다. 하지만 `ALL_TABLES`로 보면 서로의 테이블이 보이지 않는다. 그래서 `INSERT INTO VPLUS... SELECT * FROM JH202610.TQSA_...`는 안 된다.
- vplus 계정 권한은 `CREATE TABLE`, `UNLIMITED TABLESPACE`이고 `ANY` 계열 권한은 없다.

| 방법 | 필요한 것 | 비고 |
|---|---|---|
| ① 스크립트 이관 | 없음(두 계정 비밀번호만) | JH에서 읽어 vplus에 INSERT하는 스크립트(Python 등). JH를 바꾸지 않는다. 데이터가 약 22MB로 작아서 이 방법으로 충분하다(8장). |
| ② `GRANT SELECT` 후 INSERT ... SELECT | JH 계정에서 vplus로 GRANT | **JH 객체 권한을 바꾸는 것**이다. AGENTS.md의 'JH 수정 금지'에 걸린다. |
| ③ Data Pump(expdp/impdp, REMAP_TABLE) | DBA 권한, DIRECTORY 객체 | DBA 협조가 필요하다. |

권장은 ①이다.

## 6. FK 관계

JH TQS 테이블의 FK 31개는 모두 TQS 테이블끼리의 관계다. 다른 테이블을 참조하는 FK는 없다. 이름을 바꾼 뒤의 관계는 다음과 같다.

| JH 자식 → 부모 | vplus 자식 → 부모 | 비고 |
|---|---|---|
| `TQSA_CTPUNT` → `TQSA_CTP` | `TQSB_CTPUNT` → `TQSB_CTP` |  |
| `TQSA_VNDR` → `TQSA_CTP` | `TQSB_VNDR` → `TQSB_CTP` |  |
| `TQSA_CTPUNT_CHKITM` → `TQSA_CTPUNT` | `TQSB_CTPUNT_CHKITM` → `TQSB_CTPUNT` | 충돌 테이블 포함 |
| `TQSB_CTPUNT_CHKITM` → `TQSA_CTPUNT` | `TQSB_CTPUNT_CHKITM` → `TQSB_CTPUNT` | 충돌 테이블 포함 · TQSB가 TQSA를 참조 |
| `TQSA_RISK_CHK` → `TQSA_CTPUNT_CHKITM` | `TQSB_RISK_CHK` → `TQSB_CTPUNT_CHKITM` | 충돌 테이블 포함 |
| `TQSA_DAYSAFE_CHKLST` → `TQSA_DAYSAFE_DT` | `TQSB_DAYSAFE_CHKLST` → `TQSB_DAYSAFE_DT` | 충돌 테이블 포함 |
| `TQSA_EDU_MSDS` → `TQSA_EDU` | `TQSB_EDU_MSDS` → `TQSB_EDU` |  |
| `TQSA_DEEDU_CD` → `TQSA_EDU_CD` | `TQSB_DEEDU_CD` → `TQSB_EDU_CD` |  |
| `TQSA_HLTH_CHKUP_LIST` → `TQSA_HLTH_CHKUP` | `TQSB_HLTH_CHKUP_LIST` → `TQSB_HLTH_CHKUP` |  |
| `TQSA_HOCHKRPT_CK` → `TQSA_HOCHKRPT` | `TQSB_HOCHKRPT_CK` → `TQSB_HOCHKRPT` |  |
| `TQSA_HOCHKRPT_ERR` → `TQSA_HOCHKRPT` | `TQSB_HOCHKRPT_ERR` → `TQSB_HOCHKRPT` |  |
| `TQSA_HOCHKRPT_PHOTO` → `TQSA_HOCHKRPT` | `TQSB_HOCHKRPT_PHOTO` → `TQSB_HOCHKRPT` |  |
| `TQSA_IDAC_DSVC` → `TQSA_IDAC` | `TQSB_IDAC_DSVC` → `TQSB_IDAC` |  |
| `TQSA_RISK_VNDR` → `TQSA_RISK_DGR` | `TQSB_RISK_VNDR` → `TQSB_RISK_DGR` | 충돌 테이블 포함 |
| `TQSA_RISK_AREC_TEMP` → `TQSA_RISK_VNDR` | `TQSB_RISK_AREC_TEMP` → `TQSB_RISK_VNDR` | 충돌 테이블 포함 |
| `TQSA_RISK_CHK` → `TQSA_RISK_VNDR` | `TQSB_RISK_CHK` → `TQSB_RISK_VNDR` | 충돌 테이블 포함 |
| `TQSA_SAFE_PERM_CPLN` → `TQSA_SAFE_PERM_CD` | `TQSB_SAFE_PERM_CPLN` → `TQSB_SAFE_PERM_CD` |  |
| `TQSA_SAFE_PERREQ_OBJ` → `TQSA_SAFE_PERM_CD` | `TQSB_SAFE_PERREQ_OBJ` → `TQSB_SAFE_PERM_CD` |  |
| `TQSA_SAFE_PERREQ_OBJ` → `TQSA_SAFE_PERREQ` | `TQSB_SAFE_PERREQ_OBJ` → `TQSB_SAFE_PERREQ` |  |
| `TQSA_SAFE_PERREQ_OBJLST` → `TQSA_SAFE_PERREQ_OBJ` | `TQSB_SAFE_PERREQ_OBJLST` → `TQSB_SAFE_PERREQ_OBJ` |  |
| `TQSA_RISK_VNDR` → `TQSA_VNDR` | `TQSB_RISK_VNDR` → `TQSB_VNDR` | 충돌 테이블 포함 |
| `TQSB_VNDRNAM` → `TQSA_VNDR` | `TQSB_VNDRNAM` → `TQSB_VNDR` | TQSB가 TQSA를 참조 |
| `TQSA_WEEK_WORK_LOG_PLAN` → `TQSA_WEEK_WORK_LOG` | `TQSB_WEEK_WORK_LOG_PLAN` → `TQSB_WEEK_WORK_LOG` |  |
| `TQSA_WEEK_WORK_LOG_PLAN_HO` → `TQSA_WEEK_WORK_LOG_HO` | `TQSB_WEEK_WORK_LOG_PLAN_HO` → `TQSB_WEEK_WORK_LOG_HO` |  |
| `TQSA_YYTRGPLNCHR` → `TQSA_YYTRGPLN` | `TQSB_YYTRGPLNCHR` → `TQSB_YYTRGPLN` |  |
| `TQSB_DAYSAFE_NAM` → `TQSB_DAYSAFE_DT` | `TQSB_DAYSAFE_NAM` → `TQSB_DAYSAFE_DT` | 충돌 테이블 포함 |
| `TQSB_RISKPLAN_D` → `TQSB_RISKPLAN` | `TQSB_RISKPLAN_D` → `TQSB_RISKPLAN` | 충돌 테이블 포함 |
| `TQSB_RISK_VNDR` → `TQSB_RISK_DGR` | `TQSB_RISK_VNDR` → `TQSB_RISK_DGR` | 충돌 테이블 포함 |
| `TQSB_RISK_CHK` → `TQSB_RISK_LST` | `TQSB_RISK_CHK` → `TQSB_RISK_LST` | 충돌 테이블 포함 |
| `TQSB_RISK_LST` → `TQSB_RISK_VNDR` | `TQSB_RISK_LST` → `TQSB_RISK_VNDR` | 충돌 테이블 포함 |
| `TQSB_RISK_NAM` → `TQSB_RISK_VNDR` | `TQSB_RISK_NAM` → `TQSB_RISK_VNDR` | 충돌 테이블 포함 |

- `TQSB_CTPUNT_CHKITM → TQSA_CTPUNT`, `TQSB_VNDRNAM → TQSA_VNDR`처럼 원래 TQSB가 TQSA를 참조하는 FK가 있다. 이름을 바꾸면 부모가 `TQSB_CTPUNT`, `TQSB_VNDR`이 되어 관계가 그대로 유지된다.
- FK가 있으니 데이터는 부모 → 자식 순서로 넣거나, FK를 맨 마지막에 만든다.

## 7. 의존 객체 (프로시저)

- JH에서 TQS 테이블을 참조하는 객체는 모두 PROCEDURE이고 274개다. 트리거·뷰·시노님은 없다.
- **테이블만 복사하면 vplus의 기존 프로시저에는 영향이 없다.** vplus 프로시저는 vplus의 기존 TQSA 테이블을 계속 쓴다.
- 나중에 JH 프로시저를 vplus로 옮길 때는 아래를 주의해야 한다(이번 범위 밖).
  - JH 프로시저 274개 중 190개는 vplus에 **같은 이름의 프로시저가 이미 있다**(`PQSA_*` 등). 그대로 만들면 vplus 프로시저를 덮어쓴다.
  - 프로시저 안의 `TQSA_` 참조를 `TQSB_`로 바꿔야 한다.
  - 충돌 8쌍을 참조하는 프로시저가 68개다. 그중 같은 쌍의 A와 B를 함께 참조하는 2개는 단순 치환이 불가능하다.

  A·B를 함께 참조하는 프로시저: `PQSA_RISK_CHK_Q`, `PQSZ_DATA_CLEAR_W`

## 8. 문제없음으로 확인한 항목

| 항목 | 결과 |
|---|---|
| vplus의 기존 객체와 테이블 이름 충돌 | 없음(vplus에 `TQSB` 객체 0개) |
| vplus 앱 소스의 TQSB 참조 | `TQSB_ENVCHK`, `TQSB_SMS`, `TQSB_RSKEVLNAM`, `TQSB_RSKEVLCOP`를 참조한다. 이번에 만들 이름과 겹치지 않는다(이 4개는 vplus DB와 JH DB 어디에도 없다). |
| 이름 길이 | `TQSA`→`TQSB`는 길이가 같다. 128자 초과 없음 |
| 트리거 / 뷰 / 시노님 | JH·vplus 모두 TQS 대상 없음 |
| 시퀀스 | 이름에 TQS가 들어간 시퀀스 없음 |
| 파티션 / 임시 테이블 / IOT | 없음(108개 모두 일반 힙 테이블) |
| 문자셋 | 둘 다 `AL32UTF8` |
| 용량 | JH TQS 테이블+인덱스 약 22.4 MB. vplus 테이블스페이스는 쿼터 무제한 |
| 데이터 타입 | VARCHAR2, NUMBER, DATE, CLOB(3개 컬럼: `TQSA_DRM.DATA_DESC`, `TQSA_LAB_AREC.DECD_MATT`, `TQSA_SUBJECT.DTL_CTS`). LONG 없음 |
| CHECK 제약 | NOT NULL 외의 CHECK 없음 |

## 9. 기타 주의

- **개인정보**: `TQSA_IDAC.DSVC_RSDNNO`(3건), `TQSA_IDAC_DSVC.DSVC_RSDNNO`(0건)는 주민번호로 보이는 컬럼이다. JH 데이터를 vplus 개발 DB로 옮겨도 되는지 확인이 필요하다.
- **데이터 성격**: 복사하는 데이터는 JH(참조 시스템)의 데이터다. vplus의 기존 TQSA 데이터와 섞이지 않고 별도의 TQSB 테이블에 들어간다.
- **되돌리기**: vplus에 새 테이블을 만드는 작업이라 `DROP TABLE ... CASCADE CONSTRAINTS PURGE`로 되돌릴 수 있다. 실행 전에 DROP 스크립트를 함께 준비한다.

## 10. 결정이 필요한 사항

1. 충돌 8쌍 처리 방법(2장 A/B/C 중 선택, A라면 새 이름 규칙).
2. 복사 경로(5장, 권장 ①).
3. 테이블 이름과 맞지 않는 PK 이름을 정리할지(3장).
4. 개인정보 컬럼 데이터를 그대로 복사할지(9장).
5. 데이터까지 복사할지, 구조만 만들지.

## 부록. 대상 테이블 매핑 (108개)

| # | JH 원본 | vplus 대상 | 컬럼 수 | JH 건수 | PK | 비고 |
|---:|---|---|---:|---:|---|---|
| 1 | `TQSA_ADDRISK_ORD` | `TQSB_ADDRISK_ORD` | 38 | 8 | PK_TQSA_ADDRISK_ORD |  |
| 2 | `TQSA_APRV` | `TQSB_APRV` | 16 | 53 | PK_TQSA_APRV |  |
| 3 | `TQSA_APRVLINE` | `TQSB_APRVLINE` | 10 | 2 | PK_TQSA_APRVLINE |  |
| 4 | `TQSA_APRVLINE_DTL` | `TQSB_APRVLINE_DTL` | 11 | 4 | PK_TQSA_APRVLINE_DTL |  |
| 5 | `TQSA_APRV_LINE` | `TQSB_APRV_LINE` | 14 | 19 | PK_TQSA_APRV_LINE |  |
| 6 | `TQSA_AREC_CD` | `TQSB_AREC_CD` | 12 | 3 | PK_TQSA_AREC_CD |  |
| 7 | `TQSA_ARND_CHK_DRY` | `TQSB_ARND_CHK_DRY` | 14 | 2 | PK_TQSA_ARND_CHK_DRY |  |
| 8 | `TQSA_ASSLOG_CIRC` | `TQSB_ASSLOG_CIRC` | 12 | 15 | 없음 |  |
| 9 | `TQSA_BON_ORG` | `TQSB_BON_ORG` | 14 | 0 | PK_TQSA_BON_ORG |  |
| 10 | `TQSA_CKLST` | `TQSB_CKLST` | 12 | 118 | PK_TQSA_CKLST |  |
| 11 | `TQSA_CKLST_ITM` | `TQSB_CKLST_ITM` | 15 | 395 | PK_TQSA_CKLST_ITM |  |
| 12 | `TQSA_CTP` | `TQSB_CTP` | 10 | 182 | PK_TQSA_CTP |  |
| 13 | `TQSA_CTPUNT` | `TQSB_CTPUNT` | 10 | 1,227 | PK_TQSA_CTPUNT |  |
| 14 | `TQSA_CTPUNT_CHKITM` | `TQSB_CTPUNT_CHKITM` | 21 | 12,485 | PK_TQSA_CTPUNT_CHKITM | ⛔ 이름 충돌 |
| 15 | `TQSA_CTP_PSN` | `TQSB_CTP_PSN` | 9 | 5 | PK_TQSA_CTP_PSN |  |
| 16 | `TQSA_DAYSAFE_CHKLST` | `TQSB_DAYSAFE_CHKLST` | 29 | 20 | PK_TQSA_DAYSAFE_CHKLST | ⛔ 이름 충돌 |
| 17 | `TQSA_DAYSAFE_DT` | `TQSB_DAYSAFE_DT` | 19 | 15 | PK_TQSA_DAYSAFE_DT | ⛔ 이름 충돌 |
| 18 | `TQSA_DEEDU_CD` | `TQSB_DEEDU_CD` | 13 | 145 | PK_TQSA_DEEDU_CD |  |
| 19 | `TQSA_DISASTER_CD` | `TQSB_DISASTER_CD` | 10 | 124 | PK_TQSA_DISASTER_CD |  |
| 20 | `TQSA_DISASTER_DIV` | `TQSB_DISASTER_DIV` | 9 | 42 | PK_TQSA_DISASTER_DIV |  |
| 21 | `TQSA_DRM` | `TQSB_DRM` | 19 | 16 | 없음 |  |
| 22 | `TQSA_DRM_ANNC` | `TQSB_DRM_ANNC` | 9 | 0 | 없음 |  |
| 23 | `TQSA_EDU` | `TQSB_EDU` | 36 | 5 | PK_TQSA_EDU |  |
| 24 | `TQSA_EDU_CD` | `TQSB_EDU_CD` | 9 | 9 | PK_TQSA_EDU_CD |  |
| 25 | `TQSA_EDU_CD_TEMP` | `TQSB_EDU_CD_TEMP` | 6 | 145 | 없음 |  |
| 26 | `TQSA_EDU_DRY` | `TQSB_EDU_DRY` | 13 | 6 | PK_TQSA_IDAC4 |  |
| 27 | `TQSA_EDU_MSDS` | `TQSB_EDU_MSDS` | 18 | 12 | PK_TQSA_EDU2 |  |
| 28 | `TQSA_EMG_TRN` | `TQSB_EMG_TRN` | 14 | 3 | PK_TQSA_EMG_TRN |  |
| 29 | `TQSA_EQMTABK` | `TQSB_EQMTABK` | 30 | 1 | PK_TQSA_EQMTABK |  |
| 30 | `TQSA_HLTH_CHKUP` | `TQSB_HLTH_CHKUP` | 24 | 2 | PK_TQSA_IDAC5 |  |
| 31 | `TQSA_HLTH_CHKUP_LIST` | `TQSB_HLTH_CHKUP_LIST` | 30 | 14 | PK_TQSA_IDAC3 |  |
| 32 | `TQSA_HOCHKRPT` | `TQSB_HOCHKRPT` | 62 | 11 | PK_TQSA_HOCHKRPT |  |
| 33 | `TQSA_HOCHKRPT_CK` | `TQSB_HOCHKRPT_CK` | 18 | 1,193 | PK_TQSA_HOCHKRPT_CK |  |
| 34 | `TQSA_HOCHKRPT_ERR` | `TQSB_HOCHKRPT_ERR` | 31 | 13 | 없음 |  |
| 35 | `TQSA_HOCHKRPT_PHOTO` | `TQSB_HOCHKRPT_PHOTO` | 12 | 2 | 없음 |  |
| 36 | `TQSA_HODCAB` | `TQSB_HODCAB` | 16 | 5 | PK_TQSA_HODCAB |  |
| 37 | `TQSA_IDAC` | `TQSB_IDAC` | 97 | 3 | PK_TQSA_IDAC |  |
| 38 | `TQSA_IDAC_APRV` | `TQSB_IDAC_APRV` | 10 | 0 | PK_TQSA_IDAC_APRV |  |
| 39 | `TQSA_IDAC_DSVC` | `TQSB_IDAC_DSVC` | 28 | 0 | PK_TQSA_IDAC_DSVC |  |
| 40 | `TQSA_LABOR_JOINT_INSP` | `TQSB_LABOR_JOINT_INSP` | 13 | 1 | PK_TQSA_LABOR_JOINT_INSP |  |
| 41 | `TQSA_LABOR_LIST` | `TQSB_LABOR_LIST` | 32 | 2 | PK_TQSA_LABOR_LIST |  |
| 42 | `TQSA_LABOR_MNG_CNCL` | `TQSB_LABOR_MNG_CNCL` | 13 | 1 | PK_TQSA_LABOR_MNG_CNCL |  |
| 43 | `TQSA_LAB_AREC` | `TQSB_LAB_AREC` | 23 | 0 | PK_TQSA_LAB_AREC |  |
| 44 | `TQSA_LBR_CHK` | `TQSB_LBR_CHK` | 22 | 0 | PK_TQSA_LBR_CHK |  |
| 45 | `TQSA_LBR_CHK_ITM` | `TQSB_LBR_CHK_ITM` | 16 | 0 | PK_TQSA_LBR_CHK_ITM |  |
| 46 | `TQSA_MMEDUPLAN` | `TQSB_MMEDUPLAN` | 13 | 4 | PK_TQSA_MMEDUPLAN |  |
| 47 | `TQSA_MOB_LOG` | `TQSB_MOB_LOG` | 10 | 0 | PK_TQSA_MOB_LOG |  |
| 48 | `TQSA_MSDSMNG` | `TQSB_MSDSMNG` | 20 | 1 | PK_TQSA_MSDSMNG |  |
| 49 | `TQSA_MSDS_CD` | `TQSB_MSDS_CD` | 18 | 3 | TQSA_MSDS_CD_PK |  |
| 50 | `TQSA_NCR_REP` | `TQSB_NCR_REP` | 41 | 16 | PK_TQSA_NCR_REP |  |
| 51 | `TQSA_PRES_SITE` | `TQSB_PRES_SITE` | 10 | 0 | PK_TQSA_PRES_SITE |  |
| 52 | `TQSA_RISKPLAN` | `TQSB_RISKPLAN` | 13 | 1 | 없음 | ⛔ 이름 충돌 |
| 53 | `TQSA_RISKPLAN_D` | `TQSB_RISKPLAN_D` | 23 | 6 | 없음 | ⛔ 이름 충돌 |
| 54 | `TQSA_RISKSITE_CIPIF` | `TQSB_RISKSITE_CIPIF` | 18 | 0 | PK_TQSA_RISKSITE_CIPIF |  |
| 55 | `TQSA_RISK_AREC_TEMP` | `TQSB_RISK_AREC_TEMP` | 33 | 0 | PK_TQSA_RISK_AREC |  |
| 56 | `TQSA_RISK_CHK` | `TQSB_RISK_CHK` | 59 | 0 | PK_TQSA_RISK_CHK | ⛔ 이름 충돌 |
| 57 | `TQSA_RISK_DGR` | `TQSB_RISK_DGR` | 23 | 2 | PK_TQSA_RISK_DGR | ⛔ 이름 충돌 |
| 58 | `TQSA_RISK_VNDR` | `TQSB_RISK_VNDR` | 27 | 4 | PK_TQSA_RISK_VNDR | ⛔ 이름 충돌 |
| 59 | `TQSA_SAFECOST_APRV` | `TQSB_SAFECOST_APRV` | 11 | 3 | PK_TQSA_SAFECOST_APRV |  |
| 60 | `TQSA_SAFECOST_ARSLT` | `TQSB_SAFECOST_ARSLT` | 42 | 5 | PK_TQSA_SAFECOST_ARSLT |  |
| 61 | `TQSA_SAFECOST_ARSLT_CO` | `TQSB_SAFECOST_ARSLT_CO` | 44 | 2 | PK_TQSA_SAFECOST_ARSLT_CO |  |
| 62 | `TQSA_SAFECOST_BGT` | `TQSB_SAFECOST_BGT` | 10 | 9 | PK_TQSA_SAFECOST_BGT |  |
| 63 | `TQSA_SAFECOST_BGTYM` | `TQSB_SAFECOST_BGTYM` | 11 | 288 | PK_TQSA_SAFECOST_BGTYM |  |
| 64 | `TQSA_SAFECOST_INFO` | `TQSB_SAFECOST_INFO` | 15 | 1 | PK_TQSA_SAFECOST_INFO |  |
| 65 | `TQSA_SAFECOST_MMARSLT_CO` | `TQSB_SAFECOST_MMARSLT_CO` | 16 | 2 | PK_TQSA_SAFECOST_MMARSLT_CO |  |
| 66 | `TQSA_SAFE_PERM_CD` | `TQSB_SAFE_PERM_CD` | 9 | 6 | PK_TQSA_SAFE_PERM_CD |  |
| 67 | `TQSA_SAFE_PERM_CPLN` | `TQSB_SAFE_PERM_CPLN` | 10 | 27 | PK_TQSA_SAFE_PERM_CPLN |  |
| 68 | `TQSA_SAFE_PERREQ` | `TQSB_SAFE_PERREQ` | 41 | 1 | PK_TQSA_SAFE_PERREQ |  |
| 69 | `TQSA_SAFE_PERREQ_OBJ` | `TQSB_SAFE_PERREQ_OBJ` | 12 | 0 | PK_TQSA_SAFE_PERREQ_OBJ |  |
| 70 | `TQSA_SAFE_PERREQ_OBJLST` | `TQSB_SAFE_PERREQ_OBJLST` | 11 | 0 | PK_TQSA_SAFE_PERREQ_OBJLST |  |
| 71 | `TQSA_SAFT_PGM` | `TQSB_SAFT_PGM` | 17 | 2 | PK_TQSA_SAFT_PGM |  |
| 72 | `TQSA_SAFT_RGLN` | `TQSB_SAFT_RGLN` | 14 | 2 | PK_TQSA_SAFT_RGLN |  |
| 73 | `TQSA_SAFT_SIT` | `TQSB_SAFT_SIT` | 12 | 4 | PK_TQSA_SAFT_SIT |  |
| 74 | `TQSA_SELECT` | `TQSB_SELECT` | 13 | 0 | PK_TQSA_SELECT |  |
| 75 | `TQSA_SEL_LST` | `TQSB_SEL_LST` | 13 | 2 | 없음 |  |
| 76 | `TQSA_SITEDOC` | `TQSB_SITEDOC` | 18 | 985 | PK_TQSA_SITEDOC |  |
| 77 | `TQSA_SITENAM` | `TQSB_SITENAM` | 21 | 224 | PK_TQSA_SITENAM |  |
| 78 | `TQSA_SUBJECT` | `TQSB_SUBJECT` | 17 | 5 | PK_TQSA_SUBJECT |  |
| 79 | `TQSA_VIEW_HIS` | `TQSB_VIEW_HIS` | 9 | 21 | 없음 |  |
| 80 | `TQSA_VIEW_REQ` | `TQSB_VIEW_REQ` | 13 | 1 | 없음 |  |
| 81 | `TQSA_VIEW_REQ_LST` | `TQSB_VIEW_REQ_LST` | 8 | 2 | 없음 |  |
| 82 | `TQSA_VNDR` | `TQSB_VNDR` | 47 | 11 | PK_TQSA_VNDR |  |
| 83 | `TQSA_WEEK_WORK_LOG` | `TQSB_WEEK_WORK_LOG` | 50 | 4 | PK_TQSA_ODAYSAFE_LOG |  |
| 84 | `TQSA_WEEK_WORK_LOG_HO` | `TQSB_WEEK_WORK_LOG_HO` | 12 | 3 | PK_TQSA_ODAYSAFE_LOG_HO |  |
| 85 | `TQSA_WEEK_WORK_LOG_PLAN` | `TQSB_WEEK_WORK_LOG_PLAN` | 17 | 13 | PK_TQSA_WEEK_WORK_LOG_PLAN |  |
| 86 | `TQSA_WEEK_WORK_LOG_PLAN_HO` | `TQSB_WEEK_WORK_LOG_PLAN_HO` | 15 | 10 | PK_TQSA_WEEK_WORK_LOG_PLAN_HO |  |
| 87 | `TQSA_WORK_ENV_MON` | `TQSB_WORK_ENV_MON` | 14 | 1 | PK_TQSA_WORK_ENV_MON |  |
| 88 | `TQSA_WRK_PDOC` | `TQSB_WRK_PDOC` | 17 | 2 | PK_TQSA_WRK_PDOC |  |
| 89 | `TQSA_WRK_PMPP` | `TQSB_WRK_PMPP` | 15 | 2 | PK_TQSA_WRK_PMPP |  |
| 90 | `TQSA_YYTRGARSLT` | `TQSB_YYTRGARSLT` | 17 | 1 | PK_TQSA_YYTRGARSLT |  |
| 91 | `TQSA_YYTRGARSLTSEQ` | `TQSB_YYTRGARSLTSEQ` | 15 | 1 | PK_TQSA_YYTRGARSLTSEQ |  |
| 92 | `TQSA_YYTRGPLN` | `TQSB_YYTRGPLN` | 16 | 1 | PK_TQSA_YYTRGPLN |  |
| 93 | `TQSA_YYTRGPLNCHR` | `TQSB_YYTRGPLNCHR` | 15 | 3 | PK_TQSA_YYTRGPLNCHR |  |
| 94 | `TQSA_YYTRGPLNSEQ` | `TQSB_YYTRGPLNSEQ` | 14 | 1 | PK_TQSA_YYTRGPLNSEQ |  |
| 95 | `TQSB_CTPUNT_CHKITM` | `TQSB_CTPUNT_CHKITM` | 20 | 12,484 | PK_TQSB_CTPUNT_CHKITM | ⛔ 이름 충돌 |
| 96 | `TQSB_CTPUNT_CHKITM_TMP` | `TQSB_CTPUNT_CHKITM_TMP` | 5 | 12,482 | 없음 |  |
| 97 | `TQSB_DAYSAFE_CHKLST` | `TQSB_DAYSAFE_CHKLST` | 31 | 225 | PK_TQSB_DAYSAFE_CHKLST | ⛔ 이름 충돌 |
| 98 | `TQSB_DAYSAFE_DT` | `TQSB_DAYSAFE_DT` | 19 | 120 | PK_TQSB_DAYSAFE_DT | ⛔ 이름 충돌 |
| 99 | `TQSB_DAYSAFE_NAM` | `TQSB_DAYSAFE_NAM` | 13 | 59 | PK_TQSB_DAYSAFE_DT2 |  |
| 100 | `TQSB_RISKPLAN` | `TQSB_RISKPLAN` | 13 | 0 | PK_TQSB_RISKPLAN | ⛔ 이름 충돌 |
| 101 | `TQSB_RISKPLAN_D` | `TQSB_RISKPLAN_D` | 23 | 0 | PK_TQSB_RISKPLAN_D | ⛔ 이름 충돌 |
| 102 | `TQSB_RISK_CHK` | `TQSB_RISK_CHK` | 29 | 23 | PK_TQSB_RISK_CHK | ⛔ 이름 충돌 |
| 103 | `TQSB_RISK_DGR` | `TQSB_RISK_DGR` | 31 | 5 | PK_TQSB_RISK_DGR | ⛔ 이름 충돌 |
| 104 | `TQSB_RISK_LST` | `TQSB_RISK_LST` | 27 | 18 | PK_TQSB_RISK_LST |  |
| 105 | `TQSB_RISK_NAM` | `TQSB_RISK_NAM` | 16 | 9 | PK_TQSB_RISK_NAM |  |
| 106 | `TQSB_RISK_VNDR` | `TQSB_RISK_VNDR` | 19 | 9 | PK_TQSB_RISK_VNDR | ⛔ 이름 충돌 |
| 107 | `TQSB_STOP_WK` | `TQSB_STOP_WK` | 25 | 1 | PK_TQSB_STOP_WK |  |
| 108 | `TQSB_VNDRNAM` | `TQSB_VNDRNAM` | 24 | 6 | PK_TQSB_SITENAM2 |  |
