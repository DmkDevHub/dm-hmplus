-- TYPE 2개
-- 생성: 2026-11-13 13:57:58 (QH 2단계, 검토용 - 아직 실행하지 않음)
-- 대상 스키마: VPLUS202611A

-- QSSITEOBJ01 -> QHSITEOBJ01
CREATE TYPE "QHSITEOBJ01" AS OBJECT 
(
  SIT_CD         VARCHAR2(6)  --  현장코드
, LM_YN           VARCHAR2(1)  --  주간사여부(0:비주간사 : 1:주간사)
, CONT_ERT        NUMBER(8,3)  --  계약지분율
, WHL_SPLPRC_AMT  NUMBER(20)   --  전체공급금액
, WHL_VAT         NUMBER(20)   --  전체부가세
)
/

-- QSSITETAB01 -> QHSITETAB01
CREATE TYPE "QHSITETAB01" 
AS TABLE OF QHSITEOBJ01
/
