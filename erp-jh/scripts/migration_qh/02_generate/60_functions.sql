-- 함수 12개
-- 생성: 2026-11-13 13:57:58 (QH 2단계, 검토용 - 아직 실행하지 않음)
-- 대상 스키마: VPLUS202611A

-- FQSA_DIV_TELNO -> FQHA_DIV_TELNO
CREATE FUNCTION "FQHA_DIV_TELNO" (p_TELNO IN VARCHAR2)
-- ===============================================
-- 설  명: 구분자가 없는 전화번호에 구분자를 추가하여 반환한다.
-- 인  수: p_TELNO IN VARCHAR2 - 결재상태코드
-- 리  턴: 결과      IN VARCHAR2
-- 작성자: 곽민욱
-- 작성일: 2019/09/20
-- 변경이력:
-- ===============================================
    RETURN VARCHAR2
IS
    v_DIV_TELNO VARCHAR2(200);

BEGIN

    SELECT REGEXP_REPLACE(p_TELNO,'(02|031|032|033|041|042|043|051|052|053|054|055|061|062|063|064'||'|010|011|016|017|018|019'||'|030|050|060|070|080)'||'(.+)(.{4})','\1-\2-\3')
       INTO v_DIV_TELNO
      FROM DUAL;

    RETURN(v_DIV_TELNO);
END;
/

-- FQSA_GETCHRC_VAL_1 -> FQHA_GETCHRC_VAL_1
CREATE FUNCTION "FQHA_GETCHRC_VAL_1" (P_CD IN VARCHAR2)
-- ===============================================
-- 설  명: 코드를 받아 코드명을 반환한다.
-- 인  수: V_CD   IN VARCHAR2 - 코드
-- 리  턴: 결과   IN VARCHAR2
-- 작성자: 곽민욱
-- 작성일: 2020/02/11
-- 변경이력:
-- ===============================================
    RETURN VARCHAR2
IS
    v_CDNM VARCHAR2(500);
BEGIN
    SELECT CHRC_VAL_1
      INTO v_CDNM
      FROM TCOA_COMCODE
     WHERE COM_CD   = p_CD;

    RETURN(v_CDNM);
END;
/

-- FQSA_GETCMSITE01_BY_SITECD -> FQHA_GETCMSITE01_BY_SITECD
CREATE FUNCTION "FQHA_GETCMSITE01_BY_SITECD" (
    p_SIT_CD      IN TCMZ_SIT.SIT_CD%TYPE,   -- 현장코드
    p_DEFAULT_DT  IN VARCHAR2                -- 기준일자
) RETURN QHSITETAB01 
IS 
    v_RS          QHSITETAB01;
    v_DEFAULT_DT  VARCHAR2(10);  
BEGIN
    -- 1. 날짜 형식 변환 및 유효성 체크
    BEGIN
        SELECT CASE 
                 WHEN LENGTH(REGEXP_REPLACE(p_DEFAULT_DT, '[^0-9]')) = 6 THEN 
                      TO_CHAR(TO_DATE('20' || REGEXP_REPLACE(p_DEFAULT_DT, '[^0-9]'), 'YYYYMMDD'), 'YYYY/MM/DD')
                 WHEN LENGTH(REGEXP_REPLACE(p_DEFAULT_DT, '[^0-9]')) = 8 THEN 
                      TO_CHAR(TO_DATE(REGEXP_REPLACE(p_DEFAULT_DT, '[^0-9]'), 'YYYYMMDD'), 'YYYY/MM/DD')
                 ELSE TO_CHAR(SYSDATE, 'YYYY/MM/DD') -- 형식이 맞지 않을 경우 기본값 처리 (필요시 수정)
               END
          INTO v_DEFAULT_DT
          FROM DUAL;
    EXCEPTION
        WHEN OTHERS THEN
            v_DEFAULT_DT := TO_CHAR(SYSDATE, 'YYYY/MM/DD');
    END;

    -- 2. 데이터 조회 및 컬렉션 담기 (BULK COLLECT)
    SELECT QHSITEOBJ01 (
             SIT_CD,            -- 현장코드
             LM_YN,             -- 주간사여부
             NVL(CONT_ERT, 100), -- 계약지분율
             WHL_SPLPRC_AMT,    -- 전체공급금액
             WHL_VAT            -- 전체부가세
           )
      BULK COLLECT INTO v_RS
      FROM (
             WITH SITE_INFO AS (
                 SELECT SIT_CD
                   FROM TCMZ_SIT
                  WHERE 1 = CASE 
                              WHEN p_SIT_CD IS NULL THEN 1 
                              WHEN p_SIT_CD = 'X' THEN 0 
                              WHEN SIT_CD = p_SIT_CD THEN 1 
                              ELSE 0 
                            END
             ),
             JV_INFO AS (
                 SELECT SIT_CD, LM_YN, CONT_ERT
                   FROM (
                         SELECT A.SIT_CD,
                                B.LM_YN,
                                B.SKAT_RT AS CONT_ERT,
                                ROW_NUMBER() OVER (PARTITION BY A.SIT_CD ORDER BY A.SEQ DESC) AS SORT_NO
                           FROM TCSB_JOINT_HIS A
                           JOIN TSOC_JOINT_INFO B ON A.SIT_CD = B.SIT_CD AND A.SEQ = B.DGR_CONT_SEQ
                          WHERE A.PAY_DT <= NVL(v_DEFAULT_DT, '2999/12/31')
                            AND 1 = CASE 
                                      WHEN p_SIT_CD IS NULL THEN 1 
                                      WHEN A.SIT_CD = p_SIT_CD THEN 1 
                                      ELSE 0 
                                    END
                        )
                  WHERE SORT_NO = 1
             ),
             CONT_INFO AS (
                 SELECT SIT_CD, WHL_SPLPRC_AMT, WHL_VAT
                   FROM (
                         SELECT SIT_CD,
                                SPLPRC_AMT AS WHL_SPLPRC_AMT,
                                VAT AS WHL_VAT,
                                ROW_NUMBER() OVER (PARTITION BY SIT_CD ORDER BY DGR_CONT_SEQ ASC) AS SORT_NO
                           FROM TSOC_CONTRACT
                          WHERE DGR_CONT_SEQ = 0
                            AND CONT_DT <= NVL(v_DEFAULT_DT, '2999/12/31')
                            AND 1 = CASE 
                                      WHEN p_SIT_CD IS NULL THEN 1 
                                      WHEN SIT_CD = p_SIT_CD THEN 1 
                                      ELSE 0 
                                    END
                        )
                  WHERE SORT_NO = 1
             )
             -- 최종 조인
             SELECT A.SIT_CD,
                    B.LM_YN,
                    B.CONT_ERT,
                    C.WHL_SPLPRC_AMT,
                    C.WHL_VAT
               FROM SITE_INFO A
               LEFT OUTER JOIN JV_INFO B ON A.SIT_CD = B.SIT_CD
               LEFT OUTER JOIN CONT_INFO C ON A.SIT_CD = C.SIT_CD
           );

    RETURN v_RS;

END FQHA_GETCMSITE01_BY_SITECD;
/

-- FQSA_GETCMSITENM_BY_SITECD -> FQHA_GETCMSITENM_BY_SITECD
CREATE FUNCTION "FQHA_GETCMSITENM_BY_SITECD" (
    p_SIT_CD IN TCMZ_SIT.SIT_CD%TYPE
) RETURN VARCHAR2 
IS 
    v_RS TCMZ_SIT.SIT_NM%TYPE := '';
BEGIN
	SELECT DEPT_NM INTO v_RS
	FROM TCOZ_DEPT_INFO 
	WHERE DEPT_CD =p_SIT_CD;
    RETURN v_RS;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN NULL;
    WHEN OTHERS THEN RAISE;
END FQHA_GETCMSITENM_BY_SITECD;
/

-- FQSA_GETDEPTNM_BY_DEPTCD -> FQHA_GETDEPTNM_BY_DEPTCD
CREATE FUNCTION "FQHA_GETDEPTNM_BY_DEPTCD" (
    p_DEPT_CD IN TCOZ_DEPT_INFO.DEPT_CD%TYPE                                  
) RETURN VARCHAR2 
IS 
    v_RS TCOZ_DEPT_INFO.DEPT_NM%TYPE := '';
BEGIN
    -- 1. 회계부서코드와 상위부서 조건을 이용한 조회
    SELECT MAX(DEPT_NM)
      INTO v_RS
      FROM TCOZ_DEPT_INFO
     WHERE ACCTG_DEPT_CD = p_DEPT_CD
       AND HRNK_DEPT_CD NOT LIKE 'D00%';

    -- 2. 결과가 없으면 일반 부서코드로 조회
    IF (v_RS IS NULL) THEN
        SELECT MAX(DEPT_NM)
          INTO v_RS
          FROM TCOZ_DEPT_INFO
         WHERE DEPT_CD = p_DEPT_CD;
    END IF;

    -- 3. 그래도 결과가 없으면 회계부서코드의 MAX값 조회
    IF (v_RS IS NULL) THEN
        SELECT MAX(DEPT_NM)
          INTO v_RS
          FROM TCOZ_DEPT_INFO
         WHERE ACCTG_DEPT_CD = p_DEPT_CD;
    END IF;

    RETURN v_RS;
END FQHA_GETDEPTNM_BY_DEPTCD;
/

-- FQSA_GETLMYN_BY_SITECD -> FQHA_GETLMYN_BY_SITECD
CREATE FUNCTION "FQHA_GETLMYN_BY_SITECD" (
    p_SIT_CD IN TCSA_ERT.SIT_CD%TYPE                        
) RETURN VARCHAR2 
IS 
    v_RS TSOC_JOINT_INFO.LM_YN%TYPE := '';
BEGIN
    SELECT AA.LM_YN
      INTO v_RS
      FROM (
             SELECT DECODE(B.LM_YN, '0', 'N', 'Y') AS LM_YN
                  , ROW_NUMBER() OVER (PARTITION BY A.SIT_CD ORDER BY A.SEQ DESC) AS SORT_NO
               FROM TCSB_JOINT_HIS A
               JOIN TSOC_JOINT_INFO B ON A.SIT_CD = B.SIT_CD AND A.SEQ = B.DGR_CONT_SEQ
              WHERE A.SIT_CD = p_SIT_CD
           ) AA
     WHERE AA.SORT_NO = 1;

    IF (v_RS IS NULL) THEN
       v_RS := 'N';
    END IF;     
    RETURN v_RS;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 'N';
    WHEN OTHERS THEN RETURN 'N';
END FQHA_GETLMYN_BY_SITECD;
/

-- FQSA_GET_CDNM_BY_COMCD -> FQHA_GET_CDNM_BY_COMCD
CREATE FUNCTION "FQHA_GET_CDNM_BY_COMCD" (
    p_COMCD IN TCOA_COMCODE.COM_CD%TYPE                                  
) RETURN VARCHAR2
IS 
    v_RS TCOA_COMCODE.CD_NM%TYPE := '';                                
BEGIN
    SELECT CD_NM
      INTO v_RS
      FROM TCOA_COMCODE
     WHERE COM_CD = p_COMCD  
       AND ROWNUM = 1;
    RETURN v_RS;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN NULL;
    WHEN OTHERS THEN RETURN NULL;
END FQHA_GET_CDNM_BY_COMCD;
/

-- FQSA_GET_TELNO -> FQHA_GET_TELNO
CREATE FUNCTION "FQHA_GET_TELNO" (
    P_TEL_NO VARCHAR2
) RETURN VARCHAR2
IS
BEGIN
    IF P_TEL_NO IS NULL THEN
        RETURN NULL;

    ELSIF P_TEL_NO LIKE '02%' AND LENGTH(P_TEL_NO) = 9 THEN
        RETURN REGEXP_REPLACE(P_TEL_NO,
                              '(02)([0-9]{3})([0-9]{4})',
                              '\1-\2-\3');

    ELSIF P_TEL_NO LIKE '02%' AND LENGTH(P_TEL_NO) = 10 THEN
        RETURN REGEXP_REPLACE(P_TEL_NO,
                              '(02)([0-9]{4})([0-9]{4})',
                              '\1-\2-\3');

    ELSIF LENGTH(P_TEL_NO) = 10 THEN
        RETURN REGEXP_REPLACE(P_TEL_NO,
                              '([0-9]{3})([0-9]{3})([0-9]{4})',
                              '\1-\2-\3');

    ELSIF LENGTH(P_TEL_NO) = 11 THEN
        RETURN REGEXP_REPLACE(P_TEL_NO,
                              '([0-9]{3})([0-9]{4})([0-9]{4})',
                              '\1-\2-\3');

    ELSE
        RETURN P_TEL_NO;
    END IF;
END;
/

-- FQSA_GET_USRNM_BY_USRID -> FQHA_GET_USRNM_BY_USRID
CREATE FUNCTION "FQHA_GET_USRNM_BY_USRID" (
                                 p_USR_ID IN TCOZ_USR_INFO.USR_ID%TYPE                                  
                               ) RETURN VARCHAR2

IS v_RS TCOZ_USR_INFO.USR_NM%TYPE := '';                                

BEGIN
    SELECT (
             SELECT USR_NM
               FROM TCOZ_USR_INFO
              WHERE USR_ID = p_USR_ID
                AND USE_YN  = '1'  
                AND ROWNUM = 1
           )      
      INTO v_RS
      FROM DUAL;                                
  RETURN v_RS;
END FQHA_GET_USRNM_BY_USRID;
/

-- FQSA_XML_CLOB -> FQHA_XML_CLOB
CREATE FUNCTION "FQHA_XML_CLOB" (p_Table_Nmae    VARCHAR2 ) RETURN CLOB

AS
    CURSOR v_CUR IS
        SELECT A.COLUMN_ID, A.COLUMN_NAME, B.COMMENTS, A.DATA_TYPE, A.DATA_LENGTH, A.NULLABLE, DECODE (A.COLUMN_NAME, C.COLUMN_NAME,'Y','N')AS PK, COUNT(A.COLUMN_ID) OVER() CNT
          FROM ALL_TAB_COLUMNS A, ALL_COL_COMMENTS B,
               (SELECT C.TABLE_NAME, C.COLUMN_NAME
                  FROM USER_CONS_COLUMNS C, USER_CONSTRAINTS S
                 WHERE C.CONSTRAINT_NAME = S.CONSTRAINT_NAME
                   AND S.CONSTRAINT_TYPE = 'P'
                   AND C.TABLE_NAME      = p_Table_Nmae ) C
         WHERE A.TABLE_NAME  = B.TABLE_NAME
           AND A.COLUMN_NAME = B.COLUMN_NAME
           AND A.TABLE_NAME  = C.TABLE_NAME(+)
           AND A.COLUMN_NAME = C.COLUMN_NAME(+)
           AND A.OWNER       = 'VPLUS'
           AND A.TABLE_NAME  = p_Table_Nmae
     ORDER BY  A.COLUMN_ID;

    v_COLUMN_ID ALL_TAB_COLUMNS.COLUMN_ID%TYPE;
    v_COLUMN_NAME ALL_TAB_COLUMNS.COLUMN_NAME%TYPE;
    v_COMMENTS ALL_COL_COMMENTS.COMMENTS%TYPE;
    v_DATA_TYPE ALL_TAB_COLUMNS.DATA_TYPE%TYPE;
    v_DATA_LENGTH ALL_TAB_COLUMNS.DATA_LENGTH%TYPE;
    v_NULLABLE ALL_TAB_COLUMNS.NULLABLE%TYPE;

    v_CNT_R INT           :=0;
    v_CNT   INT           := 0;
    v_TEXT CLOB :='';
    v_TYPE VARCHAR2(200);
    v_PK   VARCHAR2(1);

    BEGIN

        v_TEXT := v_TEXT || '    <!-- 설명 -->' || CHR(13);
        v_TEXT := v_TEXT || '    <select id="get_Test" resultType="map">' || CHR(13);
        v_TEXT := v_TEXT || CHR(13);

        OPEN v_CUR;

        LOOP
            FETCH v_CUR INTO v_COLUMN_ID,v_COLUMN_NAME,v_COMMENTS,v_DATA_TYPE,v_DATA_LENGTH,v_NULLABLE,v_PK,v_CNT_R;
            EXIT WHEN v_CUR%NOTFOUND;

            v_CNT := v_CNT + 1;

            IF (v_CNT = 1) THEN
               v_TEXT := v_TEXT || '        SELECT ' || v_COLUMN_NAME || '                -- ' || v_COMMENTS || CHR(13);
            ELSE
                IF v_COLUMN_NAME NOT IN ('UPD_ID','UPD_DTM','UPD_IP','IPT_ID','IPT_DTM','IPT_IP') THEN
                    v_TEXT := v_TEXT || '             , ' || v_COLUMN_NAME || '                -- ' || v_COMMENTS || CHR(13);
                END IF;
            END IF;
        END LOOP;

        CLOSE v_CUR;
        v_TEXT := v_TEXT || CHR(13);
        v_TEXT := v_TEXT || '          FROM ' || p_Table_Nmae || CHR(13);

        v_TEXT := v_TEXT || CHR(13);
        v_TEXT := v_TEXT || '    </select>' || CHR(13);
        v_TEXT := v_TEXT || CHR(13);
        v_TEXT := v_TEXT || CHR(13);

        v_TEXT := v_TEXT || '    <!-- 설명 -->' || CHR(13);
        v_TEXT := v_TEXT || '    <select id="get_Test" statementType="CALLABLE" resultType="map">' || CHR(13);
        v_TEXT := v_TEXT || CHR(13);
        v_TEXT := v_TEXT || '        { CALL PCOZ_TEST_Q(' || CHR(13);
        v_TEXT := v_TEXT || '               #{WRK_TP           ,jdbcType=VARCHAR}  -- 작업종류' || CHR(13);
        v_TEXT := v_TEXT || '              ,#{WRK_ID           ,jdbcType=VARCHAR}  -- 아이디' || CHR(13);
        v_TEXT := v_TEXT || '              ,#{WRK_IP           ,jdbcType=VARCHAR}  -- 아이피' || CHR(13);

        OPEN v_CUR;

        LOOP
            FETCH v_CUR INTO v_COLUMN_ID,v_COLUMN_NAME,v_COMMENTS,v_DATA_TYPE,v_DATA_LENGTH,v_NULLABLE,v_PK,v_CNT_R;
            EXIT WHEN v_CUR%NOTFOUND;

             IF v_COLUMN_NAME NOT IN ('UPD_ID','UPD_DTM','UPD_IP','IPT_ID','IPT_DTM','IPT_IP') THEN
                v_TEXT := v_TEXT || '              ,#{' || v_COLUMN_NAME || '           ,jdbcType=VARCHAR}  -- ' || v_COMMENTS || CHR(13);
             END IF;

        END LOOP;

        CLOSE v_CUR;
        v_TEXT := v_TEXT || '        )}' || CHR(13);
        v_TEXT := v_TEXT || CHR(13);
        v_TEXT := v_TEXT || '    </select>' || CHR(13);

        RETURN  v_TEXT;
    END;
/

-- FQSZ_GET_CORP_NM -> FQHZ_GET_CORP_NM
CREATE FUNCTION "FQHZ_GET_CORP_NM" (p_SIT_CD IN VARCHAR2)
                  RETURN VARCHAR2
/*******************************************************************************************************************
 설  명      : [공통함수] 현장코드를 받아 법인명을 반환
 작성자      : HumamPlus
 작성일      : 2022/12/23
 PARAMETERS  : p_CORP_CD IN VARCHAR2 - 부서코드
 RETURN VALUE: 결과      IN VARCHAR2  
            
 개정번호   개정일자      변경내용요약                                      관련근거
 -------------------------------------------------------------------------------------------------------------------
 
*******************************************************************************************************************/                  
IS
    v_CORP_NM TCOA_CORP.CORP_NM%TYPE;

BEGIN

  SELECT T2.CORP_NM INTO v_CORP_NM
  FROM TCOZ_DEPT_INFO T1
      ,TCOA_CORP T2
 WHERE T1.CORP_CD = T2.CORP_CD
   AND T1.DEPT_CD = p_SIT_CD;

    RETURN(v_CORP_NM);
END;
/

-- FQSZ_SAFT_DEFC_IF -> FQHZ_SAFT_DEFC_IF
CREATE FUNCTION "FQHZ_SAFT_DEFC_IF" (
                                                      p_INQ_DIV IN VARCHAR2 --조회구분(SAFT: 안전_도급/실행금액, DEFC: 하자_도급/실행금액, SM: 안전_계약금액)
                                                     ,p_SIT_CD  IN VARCHAR2 --현장코드
                                                     )

RETURN T_OCMZ_SAFT_DEFC_IF

/******************************************************************************************************************
--설  명     : 조회대상의 [안전_도급,실행금액 / 하자보수_도급,실행금액 / 계약_안전관리비금액]을 반환한다.

--작성자     : HumamPlus
--작성일     : 2024.05.20
--수정일     : 
--PARAMETERS : p_INQ_DIV  : 조회구분(SAFT: 안전_도급/실행금액, DEFC: 하자_도급/실행금액, SM: 안전_계약금액)
               p_SIT_CD   현장코드

RETURN VALUE:  안전_도급,실행금액 / 하자보수_도급,실행금액 / 계약_안전관리비금액 반환

개정번호   개정일자      변경내용요약                                      관련근거 
-------------------------------------------------------------------------------------------------------------------

*******************************************************************************************************************/

IS
    v_RESULT_ROW T_OCMZ_SAFT_DEFC_IF;

    v_EBGT_DGR   NUMBER(10); --현실행차수 

BEGIN
	--#. [현실행차수] SELECT
    SELECT MAX(EBGT_DGR)
      INTO v_EBGT_DGR
      FROM TCMA_EBGT
     WHERE SIT_CD = p_SIT_CD
    ; 

    --#. [안전_도급/실행금액] 조회인 경우
    IF p_INQ_DIV = 'SAFT' THEN
        WITH TMP_10 AS (--안전 : 공종ID SELECT
                        SELECT A.SIT_CD
                              ,A.EBGT_DGR
                              ,A.CTP_ID
                          FROM TCMA_EBGT_DTL A
                         WHERE A.SIT_CD        = p_SIT_CD
                           AND A.EBGT_DGR      = v_EBGT_DGR
                         START WITH A.SIT_CD   = p_SIT_CD
                                AND A.EBGT_DGR = v_EBGT_DGR
                                AND A.STD_CD   = 'B002001' --산업안전보건법
                         CONNECT BY PRIOR A.SIT_CD   = A.SIT_CD
                                AND PRIOR A.EBGT_DGR = A.EBGT_DGR
                                AND PRIOR A.CTP_ID   = A.HRNK_CTP_ID
                       )

        SELECT OCMZ_SAFT_DEFC_IF ( 
                                  Z.SIT_CD        --현장코드                       : SIT_CD       
                                 ,NULL            --계약번호(= 발주번호) : 외주用  : CONT_NO      
                                 ,NULL            --거래처코드           : 외주用  : CUST_CD

                                 ,SUM(Z.UNTK_AMT) --안전_도급금액                  : SAFT_UNTK_AMT
                                 ,SUM(Z.EBGT_AMT) --안전_실행금액                  : SAFT_EBGT_AMT
                                 ,0               --안전_계약금액                  : SAFT_CONT_AMT

                                 ,0               --하자_도급금액                  : DEFC_UNTK_AMT
                                 ,0               --하자_실행금액                  : DEFC_EBGT_AMT
                                 )
          BULK COLLECT INTO v_RESULT_ROW
          FROM TMP_10 A
               INNER JOIN TCMA_EBGT_DTL Z ON Z.SIT_CD   = A.SIT_CD
                                         AND Z.EBGT_DGR = A.EBGT_DGR
                                         AND Z.CTP_ID   = A.CTP_ID
                                         AND Z.SIT_CD   = p_SIT_CD 
                                         AND Z.EBGT_DGR = v_EBGT_DGR
                                         AND Z.DTLS_YN  = '1' --내역여부
         WHERE A.SIT_CD   = p_SIT_CD
           AND A.EBGT_DGR = v_EBGT_DGR
         GROUP BY Z.SIT_CD
        ;


    --#. [하자_도급/실행금액] 조회인 경우
    ELSIF p_INQ_DIV = 'DEFC' THEN
        WITH TMP_10 AS (--하자 : 공종ID SELECT
                        SELECT A.SIT_CD
                              ,A.EBGT_DGR
                              ,A.CTP_ID
                          FROM TCMA_EBGT_DTL A
                         WHERE A.SIT_CD        = p_SIT_CD
                           AND A.EBGT_DGR      = v_EBGT_DGR
                         START WITH A.SIT_CD   = p_SIT_CD
                                AND A.EBGT_DGR = v_EBGT_DGR
                                AND A.STD_CD   = 'E' --하자보수충당금
                         CONNECT BY PRIOR A.SIT_CD   = A.SIT_CD
                                AND PRIOR A.EBGT_DGR = A.EBGT_DGR
                                AND PRIOR A.CTP_ID   = A.HRNK_CTP_ID
                       )

        SELECT OCMZ_SAFT_DEFC_IF ( 
                                  Z.SIT_CD        --현장코드                       : SIT_CD       
                                 ,NULL            --계약번호(= 발주번호) : 외주用  : CONT_NO      
                                 ,NULL            --거래처코드           : 외주用  : CUST_CD

                                 ,0               --안전_도급금액                  : SAFT_UNTK_AMT
                                 ,0               --안전_실행금액                  : SAFT_EBGT_AMT
                                 ,0               --안전_계약금액                  : SAFT_CONT_AMT

                                 ,SUM(Z.UNTK_AMT) --하자_도급금액                  : DEFC_UNTK_AMT
                                 ,SUM(Z.EBGT_AMT) --하자_실행금액                  : DEFC_EBGT_AMT    ( 하자 보수비 ? )
                                 )
          BULK COLLECT INTO v_RESULT_ROW
          FROM TMP_10 A
               INNER JOIN TCMA_EBGT_DTL Z ON Z.SIT_CD   = A.SIT_CD
                                         AND Z.EBGT_DGR = A.EBGT_DGR
                                         AND Z.CTP_ID   = A.CTP_ID
                                         AND Z.SIT_CD   = p_SIT_CD 
                                         AND Z.EBGT_DGR = v_EBGT_DGR
                                         AND Z.DTLS_YN  = '1' --내역여부
         WHERE A.SIT_CD   = p_SIT_CD
           AND A.EBGT_DGR = v_EBGT_DGR
         GROUP BY Z.SIT_CD
        ;


    --#. [안전_계약금액 : 최종계약건 기준] 조회인 경우
    ELSIF p_INQ_DIV = 'SM' THEN
        WITH TMP_10 AS (--안전 : 공종ID SELECT
                        SELECT A.SIT_CD
                              ,A.EBGT_DGR
                              ,A.CTP_ID
                          FROM TCMA_EBGT_DTL A
                         WHERE A.SIT_CD        = p_SIT_CD
                           AND A.EBGT_DGR      = v_EBGT_DGR
                         START WITH A.SIT_CD   = p_SIT_CD
                                AND A.EBGT_DGR = v_EBGT_DGR
                                AND A.STD_CD   = 'B002001' --산업안전보건법
                         CONNECT BY PRIOR A.SIT_CD   = A.SIT_CD
                                AND PRIOR A.EBGT_DGR = A.EBGT_DGR
                                AND PRIOR A.CTP_ID   = A.HRNK_CTP_ID
                       )

        SELECT OCMZ_SAFT_DEFC_IF ( 
                                  Z.SIT_CD        --현장코드                       : SIT_CD       
                                 ,Z.ORD_NO        --계약번호(= 발주번호) : 외주用  : CONT_NO      
                                 ,MAX(B.CUST_CD)  --거래처코드           : 외주用  : CUST_CD

                                 ,0               --안전_도급금액                  : SAFT_UNTK_AMT
                                 ,0               --안전_실행금액                  : SAFT_EBGT_AMT
                                 ,SUM(Z.CONT_AMT) --안전_계약금액                  : SAFT_CONT_AMT

                                 ,0               --하자_도급금액                  : DEFC_UNTK_AMT
                                 ,0               --하자_실행금액                  : DEFC_EBGT_AMT
                                 )

          BULK COLLECT INTO v_RESULT_ROW
          FROM TMP_10 A
               INNER JOIN TSMC_CONT_DTL Z ON Z.SIT_CD      = A.SIT_CD
                                         AND Z.CTP_ID      = A.CTP_ID
               INNER JOIN TSMC_CONT     B ON B.SIT_CD      = Z.SIT_CD
                                         AND B.ORD_NO      = Z.ORD_NO
                                         AND B.ORD_DGR     = Z.ORD_DGR
                                         AND B.SIT_CD      = p_SIT_CD
                                         AND B.CUR_CONT_YN = '1' --현계약여부(최종계약)

         WHERE A.SIT_CD   = p_SIT_CD
           AND A.EBGT_DGR = v_EBGT_DGR
         GROUP BY Z.SIT_CD
                 ,Z.ORD_NO
        ;


    --#. [안전_계약금액 : 최최계약건 기준] 조회인 경우
    ELSIF p_INQ_DIV = 'SM_0' THEN
        WITH TMP_10 AS (--안전 : 공종ID SELECT
                        SELECT A.SIT_CD
                              ,A.EBGT_DGR
                              ,A.CTP_ID
                          FROM TCMA_EBGT_DTL A
                         WHERE A.SIT_CD        = p_SIT_CD
                           AND A.EBGT_DGR      = v_EBGT_DGR
                         START WITH A.SIT_CD   = p_SIT_CD
                                AND A.EBGT_DGR = v_EBGT_DGR
                                AND A.STD_CD   = 'B002001' --산업안전보건법
                         CONNECT BY PRIOR A.SIT_CD   = A.SIT_CD
                                AND PRIOR A.EBGT_DGR = A.EBGT_DGR
                                AND PRIOR A.CTP_ID   = A.HRNK_CTP_ID
                       )

        SELECT OCMZ_SAFT_DEFC_IF ( 
                                  Z.SIT_CD        --현장코드                       : SIT_CD       
                                 ,Z.ORD_NO        --계약번호(= 발주번호) : 외주用  : CONT_NO      
                                 ,MAX(B.CUST_CD)  --거래처코드           : 외주用  : CUST_CD

                                 ,0               --안전_도급금액                  : SAFT_UNTK_AMT
                                 ,0               --안전_실행금액                  : SAFT_EBGT_AMT
                                 ,SUM(Z.CONT_AMT) --안전_계약금액                  : SAFT_CONT_AMT

                                 ,0               --하자_도급금액                  : DEFC_UNTK_AMT
                                 ,0               --하자_실행금액                  : DEFC_EBGT_AMT
                                 )

          BULK COLLECT INTO v_RESULT_ROW
          FROM TMP_10 A
               INNER JOIN TSMC_CONT_DTL Z ON Z.SIT_CD  = A.SIT_CD
                                         AND Z.CTP_ID  = A.CTP_ID
               INNER JOIN TSMC_CONT     B ON B.SIT_CD  = Z.SIT_CD
                                         AND B.ORD_NO  = Z.ORD_NO
                                         AND B.ORD_DGR = Z.ORD_DGR
                                         AND B.SIT_CD  = p_SIT_CD
                                         AND B.ORD_DGR = 0 --최초계약 건

         WHERE A.SIT_CD   = p_SIT_CD
           AND A.EBGT_DGR = v_EBGT_DGR
         GROUP BY Z.SIT_CD
                 ,Z.ORD_NO
        ;
    END IF;

    RETURN v_RESULT_ROW;
END;
/
