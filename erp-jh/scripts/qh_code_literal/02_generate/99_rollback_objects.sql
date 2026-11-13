-- 되돌리기: 93개를 1단계에서 저장한 원래 소스로 다시 만든다
-- 생성: 2026-11-13 15:59:55 (QH 코드 값 변경 2단계, 검토용 - 아직 실행하지 않음)
-- 대상 스키마: VPLUS202611A

-- PQHA_APROV_LINE_Q
DROP PROCEDURE "PQHA_APROV_LINE_Q";
CREATE PROCEDURE "PQHA_APROV_LINE_Q" (
    p_WRK_TP                VARCHAR2 DEFAULT 'Q'        -- FLAG( Q: SELECT )
,   p_SIT_CD                VARCHAR2                    -- 현장코드
,   p_SRCH_WRD              VARCHAR2                    -- 검색어
,   p_APRV_NO               VARCHAR2                    -- 결재번호
,   p_APRV_WRTR             VARCHAR2                    -- 결재상신자
,   p_APRVLINE_SEQ          VARCHAR2                    -- 결재선순번
,   RTN_CURSOR              OUT SYS_REFCURSOR
)
IS 
    /**************************************************************************************************************************
      Purpose : QSE > 안전관리 결재선 조회

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2025/02/25                                    최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리
    ---------------------------------------------------------------------------------------------------------------------------

    ----------------------------------------------------------------------------------------------------
    -- get_UsrInfoLineAprv 조회 
    IF p_WRK_TP = 'Q1' THEN
        OPEN RTN_CURSOR FOR
        SELECT EMPE_NO AS USR_ID
             , PNM AS USR_NM
             --, DTY_CD AS JB_CD
             --, DTY_NM AS JB_NM
             , JB_CD
             , NVL((SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = T1.JB_CD AND HRNK_CD = 'QS077' AND USE_YN = '1'),'') AS JB_NM
             , CELPH    AS MP_NO
          FROM TQHA_SITENAM T1 
         WHERE SIT_CD   = p_SIT_CD
           AND (UPPER(T1.EMPE_NO) LIKE UPPER(p_SRCH_WRD) || '%' OR UPPER(T1.PNM) LIKE '%' || UPPER(p_SRCH_WRD) || '%')
           AND USE_YN = '1'
         ORDER 
            BY CO_DIV_CD, PNM, DTY_CD
        ;

    ----------------------------------------------------------------------------------------------------
    -- 결재선정보 조회
    ELSIF p_WRK_TP = 'Q2' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD               -- 현장코드
             , A.APRV_NO               -- 결재번호
             , A.APRV_SO               -- 결재순서
             , A.APRV_PSN_ID AS USR_ID -- 결재자ID
             , B.PNM AS USR_NM
             , NVL((SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = B.JB_CD AND HRNK_CD = 'QS077' AND USE_YN = '1'),'') AS JB_NM
             , A.APRV_STATS            -- 결재상태
             , A.APRV_OPIN             -- 결재의견
          FROM TQHA_APRV_LINE A
             , TQHA_SITENAM B
         WHERE A.APRV_PSN_ID    = B.EMPE_NO 
           AND A.SIT_CD         = B.SIT_CD 
           AND A.SIT_CD         = p_SIT_CD
           AND A.APRV_NO        = p_APRV_NO
        ;

    ----------------------------------------------------------------------------------------------------
    -- 개인결재선 selectBox 조회
    ELSIF p_WRK_TP = 'Q3' THEN

        OPEN RTN_CURSOR FOR
        SELECT APRVLINE_SEQ -- 결재선순번
             , APRVLINE_NM  -- 결재선명
          FROM TQHA_APRVLINE
         WHERE SIT_CD       = p_SIT_CD
           AND APRV_WRTR    = p_APRV_WRTR
         ORDER BY APRVLINE_SEQ
        ;

    ----------------------------------------------------------------------------------------------------
    -- 개인결재선 상세 조회
    ELSIF p_WRK_TP = 'Q4' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD               -- 현장코드
             , A.APRV_SO               -- 결재선순번
             , A.APRV_PSN_ID AS USR_ID -- 결재자ID
             , B.PNM AS USR_NM
             , NVL((SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = B.JB_CD AND HRNK_CD = 'QS077' AND USE_YN = '1'),'') AS JB_NM
          FROM TQHA_APRVLINE_DTL A
             , TQHA_SITENAM B
         WHERE A.APRV_PSN_ID    = B.EMPE_NO 
           AND A.SIT_CD         = B.SIT_CD
           AND A.SIT_CD         = p_SIT_CD
           AND A.APRV_WRTR      = p_APRV_WRTR
           AND A.APRVLINE_SEQ   = p_APRVLINE_SEQ
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHA_APROV_PAGE_NM_Q
DROP PROCEDURE "PQHA_APROV_PAGE_NM_Q";
CREATE PROCEDURE "PQHA_APROV_PAGE_NM_Q" (
    p_WRK_TP                VARCHAR2 DEFAULT 'Q'        -- FLAG( Q: SELECT )
,   p_SITE_APRV_TP          VARCHAR2                    -- 결재유형
,   RTN_CURSOR              OUT SYS_REFCURSOR
)
IS 
    /**************************************************************************************************************************
      Purpose : QSE > 안전관리 결재 페이지 조회

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2025/02/25                                    최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리
    ---------------------------------------------------------------------------------------------------------------------------

    OPEN RTN_CURSOR FOR
    SELECT MAX(CHRC_VAL_1)  AS RTN_PAGE_NM       -- 화면명
      FROM TCOA_COMCODE
     WHERE HRNK_CD  = 'QS039'
       AND COM_CD   = p_SITE_APRV_TP
    ;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHA_APROV_STATS_Q
DROP PROCEDURE "PQHA_APROV_STATS_Q";
CREATE PROCEDURE "PQHA_APROV_STATS_Q" (
    p_WRK_TP                VARCHAR2 DEFAULT 'Q'        -- FLAG( Q: SELECT )
,   p_SIT_CD                VARCHAR2                    -- 현장코드
,   p_APRV_NO               VARCHAR2                    -- 결재번호
,   RTN_CURSOR              OUT SYS_REFCURSOR
)
IS 
    /**************************************************************************************************************************
      Purpose : QSE > 안전관리 결재 상태 조회

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2025/02/25                                    최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리
    ---------------------------------------------------------------------------------------------------------------------------

    ----------------------------------------------------------------------------------------------------
    -- 결재상태 조회 
    IF p_WRK_TP = 'Q1' THEN
        OPEN RTN_CURSOR FOR
        SELECT B.APRV_STATS         -- 결재상태(QS031)
             , B.APRV_CLS_NO        -- 키변수처리
             , B.APRV_ATFL_GRP      -- 결재첨부파일
             , B.SITE_APRV_TP       -- 결재유형(QS039)
             , '▶ 결재상태 : ' || NVL(( SELECT CD_NM FROM TCOA_COMCODE WHERE HRNK_CD = 'QS031' AND COM_CD = B.APRV_STATS ), '-') AS APRV_STATS_NM -- 결재상태명
             , B.APRV_NO
          FROM TQHA_APRV B
         WHERE B.SIT_CD     = p_SIT_CD
           AND B.APRV_NO    = p_APRV_NO
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHA_APRV_Q
DROP PROCEDURE "PQHA_APRV_Q";
CREATE PROCEDURE "PQHA_APRV_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'         -- FLAG
,   p_USR_ID            IN VARCHAR2                     -- 사용자ID
,   p_SIT_CD            IN VARCHAR2                     -- 현장코드
,   p_SEARCH_STR_YM     IN VARCHAR2                     -- 결재년월
,   p_SITE_APRV_TP      IN VARCHAR2                     -- 결재유형
,   p_APRV_STATS        IN VARCHAR2                     -- 결재상태
,   p_APRV_NO           IN VARCHAR2                     -- 결재번호
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [안전 결재관리] PROCEDRE 

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2026/02/05                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    -- 
    IF p_WRK_TP = 'Q1' THEN

        -- 결재선 미결함
        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                                                                                                             -- 현장코드
             , A.APRV_NO                                                                                                            -- 결재번호
             , A.SITE_APRV_TP                                                                                                       -- 결재 유형
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.SITE_APRV_TP AND HRNK_CD = 'QS039')         AS APRV_TP_NM           -- 결재유형명칭
             , (SELECT CHRC_VAL_1 FROM TCOA_COMCODE WHERE COM_CD = A.SITE_APRV_TP AND HRNK_CD = 'QS039')    AS APRV_TP_PAGE_NM      -- 결재유형별 화면명
             , A.APRV_TTL                                                                                                           -- 결재 제목
             , A.APRV_SCHF                                                                                                          -- 결재 상신자ID
             , B.USR_NM                                                                                                             -- 상신자 성명
             , TO_CHAR(A.APRV_SCHF_DTM, 'YYYY-MM-DD')                                                       AS APRV_SCHF_DTM        -- 결재 상신일자
             , TO_CHAR(A.APRV_APRV_DTM, 'YYYY-MM-DD')                                                       AS APRV_APRV_DTM        -- 결재 승인일자(진행중/최종 일자 함게 사용)
             , A.APRV_STATS                                                                                                         -- 결재 상태
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.APRV_STATS AND HRNK_CD = 'QS031')           AS APRV_STATS_NM        -- 결재 상태명칭
             , A.APRV_CLS_NO                                                                                                        -- 결재 키 변수
          FROM TQHA_APRV A
             , TCOZ_USR_INFO B
             , ( -- 결재 내가 바로 결재해야 할 항목 조회(미결함)
                SELECT SIT_CD        -- 현장코드
                     , APRV_NO        -- 결재번호
                     , APRV_SO        -- 결재순서
                     , APRV_PSN_ID    -- 결재자 id
                     , APRV_STATS     -- 결재상태
                     , PRE_APRV_STATS -- 이전 결재자의 결재상태
                     , APRV_APRV_DTM  -- 결재승인일자
                     , APRV_OPIN      -- 결재의견
                  FROM ( -- 결재번호별 이전 결재자의 결재상태를 조회
                        SELECT SIT_CD                                                                           -- 현장코드
                             , APRV_NO                                                                          -- 결재번호
                             , APRV_SO                                                                          -- 결재순서
                             , APRV_PSN_ID                                                                      -- 결재자 id
                             , APRV_STATS                                                                       -- 결재상태
                             , LAG(APRV_STATS) OVER (ORDER BY SIT_CD, APRV_NO , APRV_SO) AS PRE_APRV_STATS      -- 이전 결재자의 결재상태
                             , APRV_APRV_DTM                                                                    -- 결재승인일자
                             , APRV_OPIN                                                                        -- 결재의견
                          FROM TQHA_APRV_LINE
                         WHERE SIT_CD   = p_SIT_CD -- 변수 (현장코드)
                         ORDER BY SIT_CD
                             , APRV_NO
                             , APRV_SO
                      )
                 WHERE SIT_CD       = p_SIT_CD          -- 변수 (현장코드)
                   AND APRV_PSN_ID  IN (p_USR_ID) -- 결재자
                   AND (APRV_STATS  IS NULL AND PRE_APRV_STATS = '4') -- 이전 결재자가 결재완료 한경우 완 내가 결재 안한 상태를 조회
               ) C
         WHERE A.SIT_CD     = p_SIT_CD              -- 변수 (현장코드)
           AND A.APRV_STATS = '2'                   -- 변수 (결재상태) 2 결재진행
           AND A.SIT_CD     = C.SIT_CD
           AND A.APRV_NO    = C.APRV_NO
           AND A.APRV_SCHF  = B.USR_ID
           AND (SUBSTR(TO_CHAR(A.APRV_SCHF_DTM, 'YYYYMMDD'), 1, 6) = p_SEARCH_STR_YM 
                OR
                NVL(p_SEARCH_STR_YM, 0) = 0)        -- 검색조전 변수 결재년월 ( 결재상신일자 기준 )
           AND (A.SITE_APRV_TP = p_SITE_APRV_TP OR NVL(p_SITE_APRV_TP, 0) = 0)                                                   -- 검색조건 변수 결재유형 ( 결재유형 )
         ORDER BY TO_CHAR(A.APRV_SCHF_DTM, 'YYYY-MM-DD') DESC
        ;

    ELSIF p_WRK_TP = 'Q2' THEN

        -- 미결함 이외의 결재함(진행, 완료, 반려)
        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                                                                                                         -- 현장코드
             , A.APRV_NO                                                                                                        -- 결재번호
             , A.SITE_APRV_TP                                                                                                   -- 결재 유형
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.SITE_APRV_TP AND HRNK_CD = 'QS039')        AS APRV_TP_NM       -- 결재유형명칭
             , (SELECT CHRC_VAL_1 FROM TCOA_COMCODE WHERE COM_CD = A.SITE_APRV_TP AND HRNK_CD = 'QS039')    AS APRV_TP_PAGE_NM  -- 결재유형별 화면명
             , A.APRV_TTL                                                                                                       -- 결재 제목
             , A.APRV_SCHF                                                                                                      -- 결재 상신자ID
             , B.USR_NM                                                                                                         -- 상신자 성명 
             , TO_CHAR(A.APRV_SCHF_DTM, 'YYYY-MM-DD')                                                       AS APRV_SCHF_DTM    -- 결재 상신일자
             , TO_CHAR(A.APRV_APRV_DTM, 'YYYY-MM-DD')                                                       AS APRV_APRV_DTM    -- 결재 승인일자(진행중/최종 일자 함게 사용)
             , A.APRV_STATS                                                                                                     -- 결재 상태
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.APRV_STATS AND HRNK_CD = 'QS031')          AS APRV_STATS_NM    --  결재 상태명칭
             , A.APRV_CLS_NO                                                                                                    -- 결재 키 변수
          FROM TQHA_APRV A
             , TCOZ_USR_INFO B
             , ( -- 결재라인에 있는 결재자 인지 체크(진행함)
                SELECT SIT_CD                   -- 현장코드
                     , APRV_NO                  -- 결재번호
                     , APRV_SO                  -- 결재순서
                     , APRV_PSN_ID              -- 결재자 id
                     , APRV_STATS               -- 결재상태
                     , APRV_APRV_DTM            -- 결재승인일자
                     , APRV_OPIN                -- 결재의견
                  FROM TQHA_APRV_LINE
                 WHERE SIT_CD = p_SIT_CD            -- 변수 (현장코드)
                   AND APRV_PSN_ID IN (p_USR_ID)    -- 변수 (사용자 id)
               ) C
         WHERE A.SIT_CD         = p_SIT_CD          -- 변수 (현장코드)
           AND A.APRV_STATS     = p_APRV_STATS      -- 변수 (결재상태) 3 결재반려
           AND A.SIT_CD         = C.SIT_CD
           AND A.APRV_NO        = C.APRV_NO
           AND A.APRV_SCHF      = B.USR_ID
           AND (SUBSTR(TO_CHAR(A.APRV_SCHF_DTM,'YYYYMMDD'),1,6) = p_SEARCH_STR_YM OR  NVL(p_SEARCH_STR_YM, 0) = 0)  -- 검색조전 변수 결재년월 ( 결재상신일자 기준 )
           AND (A.SITE_APRV_TP = p_SITE_APRV_TP OR NVL(p_SITE_APRV_TP, 0) = 0)                                      -- 검색조건 변수 결재유형 ( 결재유형 )
         ORDER BY TO_CHAR(A.APRV_SCHF_DTM, 'YYYY-MM-DD') DESC
        ;

    ELSIF p_WRK_TP = 'Q3' THEN

        -- 결재선 미결함 ( 결재상태 )
        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                                                                                                 -- 현장코드
             , A.APRV_NO                                                                                                -- 결재번호
             , A.APRV_SO                                                                                                -- 결재순서
             , A.APRV_PSN_ID                                                                                            -- 결재자 id
             , B.USR_NM                                                                                                 -- 결재자 성명                                
             , A.APRV_STATS                                                                                             -- 결재상태
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.APRV_STATS AND HRNK_CD = 'QS031') AS APRV_STATS_NM      --  결재 상태명칭
             , TO_CHAR(A.APRV_APRV_DTM, 'YYYY-MM-DD') AS APRV_APRV_DTM                                                  -- 결재 승인일자(진행중/최종 일자 함게 사용)
             , A.APRV_OPIN                                                                                              -- 결재의견
          FROM TQHA_APRV_LINE A
             , TCOZ_USR_INFO B
         WHERE A.SIT_CD         = p_SIT_CD      -- 변수 (현장코드)
           AND A.APRV_NO        = p_APRV_NO     -- 변수 (결재번호)  
           AND A.APRV_PSN_ID    = B.USR_ID
        ;

    ELSIF p_WRK_TP = 'Q4' THEN

        -- 현장소장
     OPEN RTN_CURSOR FOR
     SELECT A.JB_CD
	  FROM TQHA_SITENAM A
	 WHERE 1=1
	    AND A.SIT_CD = p_SIT_CD
	    AND A.EMPE_NO = p_USR_ID
	    ;
--    
--        OPEN RTN_CURSOR FOR
--        SELECT JB_CD                -- 직무 (현장소장)
--          FROM TCOZ_USR_INFO
--         WHERE USR_ID =  p_USR_ID   -- 사번
--        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_APRV_Q;
/

-- PQHA_ASSLOG_CIRC_Q
DROP PROCEDURE "PQHA_ASSLOG_CIRC_Q";
CREATE PROCEDURE "PQHA_ASSLOG_CIRC_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'         -- FLAG
,   p_SIT_CD            IN VARCHAR2                     -- 현장코드
,   p_PLN_YM            IN VARCHAR2                     -- 계획년월 
,   p_PLN_DGR           IN VARCHAR2                     -- 계획회차
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [수시위험성평가회의 참석자] PROCEDRE  

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2026/03/04                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    --------------------------------------------------------------------------------------
    -- 회의록 개요 : 당사 그리드 조회
    IF (p_WRK_TP = 'Q1') THEN

        OPEN RTN_CURSOR FOR
        SELECT T1.EMPE_NO
             , T3.USR_NM
             , T1.DTY_NM
             ,(SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = T1.JB_CD AND HRNK_CD = 'QS077' AND USE_YN = '1') AS JB_NM
             , T2.PRTR_YN                       -- 참석여부
             , T1.SIT_CD
             , p_PLN_YM         AS PLN_YM
             , p_PLN_DGR        AS PLN_DGR
             , '1'              AS CO_DIV_CD    -- 회사구분 1:당사
          FROM TQHA_SITENAM T1
          LEFT JOIN TQHA_ASSLOG_CIRC T2
            ON T1.EMPE_NO       = T2.EMPE_NO
           AND T2.PLN_YM        = p_PLN_YM
           AND T2.PLN_DGR       = p_PLN_DGR
           AND T2.CO_DIV_CD     = '1'
          LEFT JOIN TCOZ_USR_INFO T3 ON T1.EMPE_NO = T3.USR_ID
         WHERE T1.SIT_CD = p_SIT_CD
         ORDER BY T3.USR_NM
        ;

    ---------------------------------------------------------------------------------------
    -- 회의록 개요 : 협력회사 그리드 조회
    ELSIF p_WRK_TP = 'Q2' THEN

        OPEN RTN_CURSOR FOR
        SELECT T1.VNDR_PSN_ID       AS EMPE_NO
             , T1.VNDR_PSN_NM       AS USR_NM       -- 협력사명
             , T3.CUST_NM
             , T2.PRTR_YN                           -- 참석여부
             , T1.SIT_CD
             , p_PLN_YM             AS PLN_YM
             , p_PLN_DGR            AS PLN_DGR
             , '2'                  AS CO_DIV_CD    -- 회사구분 1:당사
          FROM TQHA_VNDR T1
          LEFT JOIN TQHA_ASSLOG_CIRC T2
            ON T1.VNDR_PSN_ID = T2.EMPE_NO
           AND T2.PLN_YM    = p_PLN_YM
           AND T2.PLN_DGR   = p_PLN_DGR
           AND T2.CO_DIV_CD = '2'
          LEFT JOIN VQSZ_TRADE T3 ON T1.CUST_CD = T3.CUST_CD
          WHERE T1.SIT_CD = p_SIT_CD
          ORDER BY T1.VNDR_PSN_NM
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_ASSLOG_CIRC_Q;
/

-- PQHA_ASSLOG_CIRC_S
DROP PROCEDURE "PQHA_ASSLOG_CIRC_S";
CREATE PROCEDURE "PQHA_ASSLOG_CIRC_S" (
    p_WRK_TP            VARCHAR2 :='U'                              -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID            VARCHAR2                                    -- 사용자 ID 
,   p_WRK_IP            VARCHAR2                                    -- 사용자 IP 
,   p_SIT_CD            TQHA_ASSLOG_CIRC.SIT_CD         %TYPE       -- 현장코드
,   p_PLN_YM            TQHA_ASSLOG_CIRC.PLN_YM         %TYPE       -- 계획년월
,   p_PLN_DGR           TQHA_ASSLOG_CIRC.PLN_DGR        %TYPE       -- 차수구분코드(QS005) 1 1차,2 2차
,   p_CO_DIV_CD         TQHA_ASSLOG_CIRC.CO_DIV_CD      %TYPE       -- 회사구분코드
,   p_EMPE_NO           TQHA_ASSLOG_CIRC.EMPE_NO        %TYPE       -- 사원번호
,   p_PRTR_YN           TQHA_ASSLOG_CIRC.PRTR_YN        %TYPE       -- 참석여부
)
IS 
    /**************************************************************************************************************************
      Purpose : 

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/01/28 09:30:07                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_YM IS NULL)  THEN
        ERR_MSG := '계획년월는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_DGR IS NULL)  THEN
        ERR_MSG := '차수구분코드(QS005) 1 1차,2 2차는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CO_DIV_CD IS NULL)  THEN
        ERR_MSG := '회사구분코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_EMPE_NO IS NULL)  THEN
        ERR_MSG := '사원번호는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------
    -- 결재상태 체크
    SELECT MAX(T2.APRV_STATS)
         , MAX(T3.CD_NM )
      INTO v_APRV_STATS
         , v_APRV_STATS_NM
      FROM TQHA_RISK_DGR        T1
      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
                                  AND T1.APRV_NO    = T2.APRV_NO
      LEFT JOIN TCOA_COMCODE    T3 ON T2.APRV_STATS = T3.COM_CD 
                                  AND T3.HRNK_CD    = 'QS031'
     WHERE T1.SIT_CD    = p_SIT_CD
       AND T1.PLN_YM    = p_PLN_YM
       AND T1.PLN_DGR   = p_PLN_DGR
    ;

    IF v_APRV_STATS IN ('2', '4') THEN
        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_PRTR_YN = '0') THEN

        DELETE FROM TQHA_ASSLOG_CIRC
         WHERE SIT_CD    = p_SIT_CD
           AND PLN_YM    = p_PLN_YM
           AND PLN_DGR   = p_PLN_DGR
           AND CO_DIV_CD = p_CO_DIV_CD
           AND EMPE_NO   = p_EMPE_NO
       ;

    -----------------------------------------------------------------------------
    ELSIF (p_PRTR_YN = '1') THEN

        MERGE 
          INTO TQHA_ASSLOG_CIRC T
         USING DUAL 
        ON (
                T.SIT_CD    = p_SIT_CD     
            AND T.PLN_YM    = p_PLN_YM     
            AND T.PLN_DGR   = p_PLN_DGR    
            AND T.CO_DIV_CD = p_CO_DIV_CD  
            AND T.EMPE_NO   = p_EMPE_NO
        )
        WHEN MATCHED THEN
            UPDATE 
               SET T.PRTR_YN    = p_PRTR_YN
                 , T.UPD_ID     = p_WRK_ID
                 , T.UPD_DTM    = SYSDATE
                 , T.UPD_IP     = p_WRK_IP
        WHEN NOT MATCHED THEN
            INSERT 
                 ( SIT_CD                  --현장코드
                 , PLN_YM                  --계획년월
                 , PLN_DGR                 --차수구분코드(QS005) 1 1차,2 2차
                 , CO_DIV_CD               --회사구분코드
                 , EMPE_NO                 --사원번호
                 , PRTR_YN                 --참석여부
                 , IPT_ID                  --입력ID
                 , IPT_DTM                 --입력일시
                 , IPT_IP                  --입력IP
                 , UPD_ID                  --수정ID
                 , UPD_DTM                 --수정일시
                 , UPD_IP                  --수정IP
                 ) 
            VALUES 
                 ( p_SIT_CD                --현장코드
                 , p_PLN_YM                --계획년월
                 , p_PLN_DGR               --차수구분코드(QS005) 1 1차,2 2차
                 , p_CO_DIV_CD             --회사구분코드
                 , p_EMPE_NO               --사원번호
                 , '1'                     --참석여부
                 , p_WRK_ID                --입력ID 
                 , SYSDATE()               --입력일시
                 , p_WRK_IP                --입력IP
                 , p_WRK_ID                --수정ID
                 , SYSDATE()               --수정일시
                 , p_WRK_IP                --수정IP
                 )
            ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_ASSLOG_CIRC_S;
/

-- PQHA_CTP_PSN_Q
DROP PROCEDURE "PQHA_CTP_PSN_Q";
CREATE PROCEDURE "PQHA_CTP_PSN_Q" (
    p_WRK_TP              IN VARCHAR2 DEFAULT 'Q'           -- FLAG(Q)
,   p_SIT_CD              IN VARCHAR2                       -- 현장 
,   p_CTP_DIV             IN VARCHAR2                       -- 공종코드
,   RTN_CURSOR            OUT SYS_REFCURSOR
) 
IS 
    /**************************************************************************************************************************
    COPYRIGHT:    HUMAN PLUS         
    PROCEDURE:    [PQHA_CTP_PSN_Q] PROCEDRE 
    설명     :    [QSE > 안전관리 > 위험성평가(최초/연간) > 현장담당자등록 목록  조회] 프로시저

     개정일자                      변경내용요약                                 관련근거
    --------------------------------------------------------------------------------------------------------------------------- 
     2023-11-28   HUMANPLUS        신규
    ***************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009 ; --ERROR 코드
    ERR_MSG        VARCHAR2(200)   ; --ERROR Message
    USER_EXCEPTION EXCEPTION       ;

BEGIN
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리
    ---------------------------------------------------------------------------------------------------------------------------

    -- get_RiskPlanChrList 현장별 담당자 지정
    IF p_WRK_TP = 'Q1' THEN

        OPEN RTN_CURSOR FOR

        SELECT B.SIT_CD         -- 현장코드
             , A.CTP_DIV        -- 공종구분
             , A.CTP_DIV_NM     -- 공종구분명칭
             , B.CTP_CHR_PSN    -- 공종담당자ID
             , C.USR_NM AS CTP_CHR_PSN_NM -- 공종담당자명
          FROM (SELECT CTP_DIV
                     , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = CTP_DIV AND HRNK_CD = 'QS035') AS CTP_DIV_NM  -- 공종구분명
                  FROM TQHA_CTP
                 GROUP BY CTP_DIV 
                 ORDER BY CTP_DIV ) A
             , TQHA_CTP_PSN B
             , TCOZ_USR_INFO C
         WHERE A.CTP_DIV        = B.CTP_DIV(+)
           AND B.CTP_CHR_PSN    = C.USR_ID(+)
           AND B.SIT_CD(+)      = p_SIT_CD
         ORDER BY A.CTP_DIV
        ;

    ---------------------------------------------------------------------------
    -- get_RiskPlanChrDtlList 공종
    ELSIF p_WRK_TP = 'Q2' THEN

        OPEN RTN_CURSOR FOR

        SELECT TC.CTP_CD        AS CTP_CD        -- 공종코드
             , TC.CTP_NM        AS CTP_NM        -- 공종명칭
             , TC.CTP_DIV       AS CTP_DIV       -- 공종별 구분코드(QS035)
             , TA.CD_NM         AS CTP_DIV_NM    -- 공종구분명
             , TC.USE_YN        AS USE_YN        -- 공종 사용유무
          FROM TQHA_CTP TC
          LEFT JOIN TCOA_COMCODE TA ON TA.HRNK_CD = 'QS035'
                                   AND TA.COM_CD  = TC.CTP_DIV
         WHERE CTP_DIV = p_CTP_DIV
         ORDER BY CTP_CD
        ;

    END IF; -- 'Q' END


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END ;
/

-- PQHA_CTP_PSN_S
DROP PROCEDURE "PQHA_CTP_PSN_S";
CREATE PROCEDURE "PQHA_CTP_PSN_S" (
    p_WRK_TP            VARCHAR2 :='U'                          -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID            VARCHAR2                                -- 사용자 ID 
,   p_WRK_IP            VARCHAR2                                -- 사용자 IP 
,   p_SIT_CD            TQHA_CTP_PSN.SIT_CD         %TYPE       -- 현장코드
,   p_CTP_DIV           TQHA_CTP_PSN.CTP_DIV        %TYPE       -- 공종별 구분코드(QS035) 01건축 02토목
,   p_CTP_CHR_PSN       TQHA_CTP_PSN.CTP_CHR_PSN    %TYPE       -- 공종담당자
)
IS 
    /**************************************************************************************************************************
      Purpose : 

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2021/11/30 12:53:23                         최초생성

    **************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;


BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CTP_DIV IS NULL)  THEN
        ERR_MSG := '공종별 구분코드(QS035) 01건축 02토목는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN

        DELETE 
          FROM TQHA_CTP_PSN
         WHERE SIT_CD   = p_SIT_CD      -- 현장코드
           AND CTP_DIV  = p_CTP_DIV     -- 공종별 구분코드(QS035) 01건축 02토목
        ;

    -------------------------------------------------------------------------------
    -- 
    ELSIF (p_WRK_TP ='U') THEN

        UPDATE TQHA_CTP_PSN
           SET CTP_CHR_PSN      = p_CTP_CHR_PSN     --공종담당자
             , UPD_ID           = p_WRK_ID          --수정ID 
             , UPD_DTM          = SYSDATE()         --수정일시
             , UPD_IP           = p_WRK_IP          --수정IP
         WHERE SIT_CD           = p_SIT_CD          --현장코드
           AND CTP_DIV          = p_CTP_DIV         --공종별 구분코드(QS035) 01건축 02토목
        ;

    -------------------------------------------------------------------------------
    -- 
    ELSE 

        INSERT 
          INTO TQHA_CTP_PSN
             ( SIT_CD               -- 현장코드
             , CTP_DIV              -- 공종별 구분코드(QS035) 01건축 02토목
             , CTP_CHR_PSN          -- 공종담당자
             , IPT_ID               -- 입력ID
             , IPT_DTM              -- 입력일시
             , IPT_IP               -- 입력IP
             , UPD_ID               -- 수정ID
             , UPD_DTM              -- 수정일시
             , UPD_IP               -- 수정IP
             )
        VALUES 
             ( p_SIT_CD             -- 현장코드
             , p_CTP_DIV            -- 공종별 구분코드(QS035) 01건축 02토목
             , p_CTP_CHR_PSN        -- 공종담당자
             , p_WRK_ID             -- 입력ID 
             , SYSDATE()            -- 입력일시
             , p_WRK_IP             -- 입력IP
             , p_WRK_ID             -- 수정ID
             , SYSDATE()            -- 수정일시
             , p_WRK_IP             -- 수정IP
             )
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END ;
/

-- PQHA_DASHBOARD_CO_Q
DROP PROCEDURE "PQHA_DASHBOARD_CO_Q";
CREATE PROCEDURE "PQHA_DASHBOARD_CO_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'             -- FLAG(Q: 현장평가, Q1:본사평가)
,   p_SIT_CD            IN VARCHAR2                         -- 현장코드
,   p_CUST_CD           IN VARCHAR2                         -- 고객코드
,   p_VNDR_SEQ          IN VARCHAR2                         -- 업체순번
,   p_WRK_CORP          IN VARCHAR2                         -- 법인코드
,   p_SEARCH_DIV        IN VARCHAR2                         -- 검색구분
,   p_SEARCH_TEXT       IN VARCHAR2                         -- 검색단어
,   p_BLT_NO            IN VARCHAR2                         -- 게시번호
,   RTN_CURSOR       OUT SYS_REFCURSOR
)
IS

    /**************************************************************************************************************************
      Purpose : 안전 파트너 대시보드 

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2026/03/03                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    -- 추가 위험발굴 작성
    IF p_WRK_TP = 'Q1' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                                                                -- 현장코드
              , (SELECT CNST_NM FROM VQSZ_SITEINFO WHERE SIT_CD = A.SIT_CD) AS CNST_NM -- 현장명칭
              , A.WRT_YY                                                                 -- 작성년도
              , SUBSTR(A.WRT_MM, 5,2) AS WRT_MM                                          -- 작성월
              , NVL(A.WRT_CNT, 0) AS WRT_CNT                                             -- 지시건수
              , NVL(B.MA_CNT, 0) AS MA_CNT                                               -- 조치건수
              , (NVL(B.MA_CNT, 0) / NVL(A.WRT_CNT, 0)) * 100 AS RATE                     -- 대비
              , p_VNDR_SEQ VNDR_SEQ
           FROM ( -- 지시건수
                  SELECT SIT_CD                          -- 현장코드
                       , substr(WRT_DT, 1, 4)  AS WRT_YY  -- 작성년도
                       , substr(WRT_DT, 1, 6)  AS WRT_MM  -- 작성월
                       , nvl(count(WRT_DT), 0) AS WRT_CNT -- 지시건수
                  FROM TQHA_ADDRISK_ORD
                  WHERE CUST_CD     = p_CUST_CD -- 변수(업체코드)
                    AND VNDR_SEQ    = p_VNDR_SEQ     -- 변수(업체순번)
                    AND SIT_CD      = p_SIT_CD
                  GROUP BY SIT_CD, substr(WRT_DT, 1, 4), substr(WRT_DT, 1, 6)
                  ORDER BY SIT_CD, substr(WRT_DT, 1, 4), substr(WRT_DT, 1, 6)
                ) A
              , ( -- 조치건수
                  SELECT SIT_CD                             -- 현장코드
                       , substr(VNDR_MA_DT, 1, 4)  AS MA_YY  -- 작성년도
                       , substr(VNDR_MA_DT, 1, 6)  AS MA_MM  -- 작성월
                       , nvl(count(VNDR_MA_DT), 0) AS MA_CNT -- 처리건수
                  FROM TQHA_ADDRISK_ORD
                  WHERE CUST_CD         = p_CUST_CD -- 변수(업체코드)
                    AND VNDR_SEQ        = p_VNDR_SEQ     -- 변수(업체순번)
                    AND VNDR_MA_YN      = '1'   -- 조치여부(1 조치완료)
                    AND SIT_CD = p_SIT_CD
                  GROUP BY SIT_CD, substr(VNDR_MA_DT, 1, 4), substr(VNDR_MA_DT, 1, 6)
                  ORDER BY SIT_CD, substr(VNDR_MA_DT, 1, 4), substr(VNDR_MA_DT, 1, 6)
                ) B
          WHERE A.SIT_CD    = B.SIT_CD(+)
            AND A.WRT_YY    = B.MA_YY(+) 
            AND A.WRT_MM    = B.MA_MM(+)
          ORDER BY WRT_YY DESC, WRT_MM DESC
        ;

    --------------------------------------------------------------------------------
    -- 
    ELSIF p_WRK_TP = 'Q2' THEN 

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                                                                -- 현장코드
              , (SELECT CNST_NM FROM VQSZ_SITEINFO WHERE SIT_CD = A.SIT_CD) AS CNST_NM -- 현장명칭
              , A.PUBC_YY                                                                -- 작성년도
              , SUBSTR(A.PUBC_MM, 0, 4) || '-' || SUBSTR(A.PUBC_MM, 5, 6) PUBC_MM        -- 작성월
              , '안전' DIV_NM                                                                     -- 구분
              , A.PUBC_CNT                                                               -- 지시건수
              , B.MA_CNT                                                                 -- 조치건수
              , (B.MA_CNT / A.PUBC_CNT) * 100 RATE                                           -- 대비
         FROM ( -- 지시건수
                  SELECT SIT_CD                            -- 현장코드
                       , substr(PUBC_DT, 1, 4)  AS PUBC_YY  -- 작성년도
                       , substr(PUBC_DT, 1, 6)  AS PUBC_MM  -- 작성월
                       , nvl(count(PUBC_DT), 0) AS PUBC_CNT -- 지시건수
                  FROM TQHA_NCR_REP
                  WHERE CUST_CD     = p_CUST_CD         -- 변수(업체코드)
                    AND VNDR_SEQ    = p_VNDR_SEQ        -- 변수(업체순번)
                    AND SIT_CD      = p_SIT_CD
                  GROUP BY SIT_CD, substr(PUBC_DT, 1, 4), substr(PUBC_DT, 1, 6)
                  ORDER BY SIT_CD, substr(PUBC_DT, 1, 4), substr(PUBC_DT, 1, 6)
              ) A,
              ( -- 조치건수
                  SELECT SIT_CD                                 -- 현장코드
                       , substr(VNDR_MA_DT, 1, 4)  AS MA_YY     -- 작성년도
                       , substr(VNDR_MA_DT, 1, 6)  AS MA_MM     -- 작성월
                       , nvl(count(VNDR_MA_DT), 0) AS MA_CNT    -- 처리건수
                  FROM TQHA_NCR_REP
                  WHERE CUST_CD         = p_CUST_CD         -- 변수(업체코드)
                    AND VNDR_SEQ        = p_VNDR_SEQ        -- 변수(업체순번)
                    AND VNDR_MA_YN      = '1'   -- 조치여부(1 조치완료)
                    AND SIT_CD          = p_SIT_CD
                  GROUP BY SIT_CD, substr(VNDR_MA_DT, 1, 4), substr(VNDR_MA_DT, 1, 6)
                  ORDER BY SIT_CD, substr(VNDR_MA_DT, 1, 4), substr(VNDR_MA_DT, 1, 6)
              ) B
         WHERE A.SIT_CD     = B.SIT_CD
           AND A.PUBC_YY    = B.MA_YY
           AND A.PUBC_MM    = B.MA_MM
        --  <!-- UNION ALL
        -- - 품질 부적합보고서 작성
        --  SELECT A.SIT_CD                                                                - 현장코드
        --       , (SELECT CNST_NM FROM VQSZ_SITEINFO WHERE SIT_CD = A.SIT_CD) AS CNST_NM  - 현장명칭
        --       , A.PUBC_YY                                                                - 작성년도
        --       , SUBSTR(A.PUBC_MM, 0, 4) || '-' || SUBSTR(A.PUBC_MM, 5, 6) PUBC_MM        - 작성월
        --       , '품질' DIV_NM                                                            - 구분
        --       , NVL(A.PUBC_CNT, 0)                                                       - 지시건수
        --       , NVL(B.MA_CNT, 0)                                                         - 조치건수
        --       , (NVL(B.MA_CNT, 0) / NVL(A.PUBC_CNT, 0)) * 100 RATE                       - 대비
        --  FROM ( - 지시건수
        --           SELECT SIT_CD                            - 현장코드
        --                , substr(PUBC_DT, 1, 4)  AS PUBC_YY  - 작성년도
        --                , substr(PUBC_DT, 1, 6)  AS PUBC_MM  - 작성월
        --                , nvl(count(PUBC_DT), 0) AS PUBC_CNT - 지시건수
        --           FROM TQSC_NCR_REP
        --           WHERE CUST_CD = P_CUST_CD - 변수(업체코드)
        --             AND VNDR_SEQ = P_VNDR_SEQ     - 변수(업체순번)
        --             AND SIT_CD = P_SIT_CD
        --           GROUP BY SIT_CD, substr(PUBC_DT, 1, 4), substr(PUBC_DT, 1, 6)
        --           ORDER BY SIT_CD, substr(PUBC_DT, 1, 4), substr(PUBC_DT, 1, 6)
        --       ) A,
        --       ( - 조치건수
        --           SELECT SIT_CD                               - 현장코드
        --                , substr(VNDR_APRV_DT, 1, 4)  AS MA_YY  - 작성년도
        --                , substr(VNDR_APRV_DT, 1, 6)  AS MA_MM  - 작성월
        --                , nvl(count(VNDR_APRV_DT), 0) AS MA_CNT - 처리건수
        --           FROM TQSC_NCR_REP
        --           WHERE CUST_CD = P_CUST_CD - 변수(업체코드)
        --             AND VNDR_SEQ = P_VNDR_SEQ     - 변수(업체순번)
        --             AND SIT_CD = P_SIT_CD
        --           GROUP BY SIT_CD, substr(VNDR_APRV_DT, 1, 4), substr(VNDR_APRV_DT, 1, 6)
        --           ORDER BY SIT_CD, substr(VNDR_APRV_DT, 1, 4), substr(VNDR_APRV_DT, 1, 6)
        --       ) B
        --  WHERE A.SIT_CD = B.SIT_CD(+)
        --    AND A.PUBC_YY = B.MA_YY(+)
        --    AND A.PUBC_MM = B.MA_MM(+)
        -- ORDER BY PUBC_MM DESC -->
        ;

    --------------------------------------------------------------------------------
    -- 위험성 평가 작성/승인요청 건수
    ELSIF p_WRK_TP = 'Q3' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                                                                -- 현장코드
             , (SELECT CNST_NM FROM VQSZ_SITEINFO WHERE SIT_CD = A.SIT_CD) AS CNST_NM -- 현장명칭
             , A.PLN_YM                                                                 -- 평가년월
             , A.PLN_DGR                                                                -- 평가차수
          FROM TQHA_RISK_VNDR A
         WHERE A.CUST_CD    = P_CUST_CD -- 변수(업체코드)
           AND A.VNDR_SEQ   = P_VNDR_SEQ     -- 변수(업체순번)
           AND (A.SBM_YN != '1' OR nvl(A.SBM_YN, 0) = 0) -- 평가서 제출 안한 경우
           AND A.SIT_CD     = P_SIT_CD
        ;

    --------------------------------------------------------------------------------
    -- 산업안전 관리비 작성/승인 요청 건수
    ELSIF p_WRK_TP = 'Q4' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                                                                -- 현장코드
             , (SELECT CNST_NM FROM VQSZ_SITEINFO WHERE SIT_CD = A.SIT_CD) AS CNST_NM -- 현장명칭
             , A.RLV_YM                                                                 -- 해당년월
          FROM TQHA_SAFECOST_MMARSLT_CO A
         WHERE A.CUST_CD    = P_CUST_CD -- 변수(업체코드)
           AND A.VNDR_SEQ   = P_VNDR_SEQ     -- 변수(업체순번)
           AND (A.VNDR_APRV_YN != '1' OR nvl(A.VNDR_APRV_YN, 0) = 0) -- 평가서 제출 안한 경우
           AND A.SIT_CD     = P_SIT_CD
        ;

    --------------------------------------------------------------------------------
    -- 안전작업허가 승인요청
    ELSIF p_WRK_TP = 'Q5' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                                                                -- 현장코드
             , (SELECT CNST_NM FROM VQSZ_SITEINFO WHERE SIT_CD = A.SIT_CD) AS CNST_NM -- 현장명칭
             , A.VNDR_REQ_DT                                                            -- 요청일자
          FROM TQHA_SAFE_PERREQ A
         WHERE A.CUST_CD        = P_CUST_CD -- 변수(업체코드)
           AND A.VNDR_SEQ       = P_VNDR_SEQ     -- 변수(업체순번)
           AND (A.VNDR_APRV_YN  != '1' OR nvl(A.VNDR_APRV_YN, 0) = 0) -- 안전작업 허가 요청승인 안한 경우
           AND A.SIT_CD         = P_SIT_CD
        ;

    --------------------------------------------------------------------------------
    -- 
    ELSIF p_WRK_TP = 'Q6' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                                                                -- 현장코드
             , (SELECT CNST_NM FROM VQSZ_SITEINFO WHERE SIT_CD = A.SIT_CD) AS CNST_NM -- 현장명칭
             , A.VNDR_REQ_DT                                                            -- 요청일자
          FROM TQHA_SAFE_PERREQ A
         WHERE A.CUST_CD            = P_CUST_CD    -- 변수(업체코드)
           AND A.VNDR_SEQ           = P_VNDR_SEQ        -- 변수(업체순번)
           -- AND A.VNDR_APRV_YN    = '1' -- 안전작업 허가 요청 승인한 경우
           AND A.SITE_APRV_STATS    = '1' -- 혀장소장 승인 완료
           AND (A.VNDR_CMPL_YN != '1' OR nvl(A.VNDR_CMPL_YN, 0) = 0) -- 안전작업 허가 작업죵료 요청 안한 경우
           AND A.SIT_CD             = P_SIT_CD
        ;

    --------------------------------------------------------------------------------
    -- 공지사항(협력업체용)
    ELSIF p_WRK_TP = 'Q7' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.BLT_NO -- 게시번호
             , A.BLT_DIV -- 공통코드(QS046)
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.BLT_DIV AND HRNK_CD = 'QS046') AS BLT_DIV_NM -- 공통코드명
             , A.SIT_CD -- 현장코드
             , ( SELECT CNST_NM FROM VQSZ_SITEINFO WHERE SIT_CD = A.SIT_CD ) AS SIT_NM -- 현장명칭
             , A.BLT_TTL -- 게시제목
             , A.DTL_CTS -- 상세내용
             , FCOZ_GET_USR_NM(p_WRK_CORP, A.BLT_PSN) AS BLT_PSN -- 게시자
             , A.BLT_DT -- 게시일자
             , A.INQ_NO -- 조회수
             , A.ATFL_GRP -- 첨부파일그룹
             , A.ANNC_STR_DD -- 공지시작일
             , A.ANNC_END_DD -- 공지종료일
          FROM TQHA_SUBJECT A
         WHERE (BLT_DIV = '3'
                OR ( BLT_DIV = '2' AND SIT_CD = p_SIT_CD ) )     -- 변수(현장코드)
           AND 'Y' = CASE WHEN (p_SEARCH_DIV  = '0' AND (NVL(p_SEARCH_TEXT, '*') = '*' OR FCOZ_GET_USR_NM(p_WRK_CORP, BLT_PSN) LIKE '%'||p_SEARCH_TEXT||'%' ))
                          THEN 'Y'
                          WHEN (p_SEARCH_DIV  = '1' AND (NVL(p_SEARCH_TEXT, '*') = '*' OR (BLT_TTL LIKE '%'||p_SEARCH_TEXT||'%' OR DTL_CTS LIKE '%'||p_SEARCH_TEXT||'%' )))
                          THEN 'Y'
                          WHEN NVL(p_SEARCH_DIV, '*') = '*'
                          THEN 'Y'
                          ELSE 'N'
                    END
         ORDER BY BLT_DT DESC
        ;

    --------------------------------------------------------------------------------
    -- 공지사항 상세정보
    ELSIF p_WRK_TP = 'Q8' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.BLT_NO                                                           --게시번호
             , A.BLT_DIV                                                          --업무구분
             , A.BLT_TTL                                                          --제목
             --, TO_CHAR(A.DTL_CTS) AS DTL_CTS                                      --상세내용
             , A.DTL_CTS
             , A.ATFL_GRP                                                         --첨부파일그룹
             , A.ANNC_STR_DD                                                      --공지시작일
             , A.ANNC_END_DD                                                      --공지종료일
             , A.IPT_ID                                                           --작성자ID
             , FCOZ_GET_USR_NM(p_WRK_CORP, A.IPT_ID) AS IPT_NM                                  --작성자명
             , TO_CHAR(A.IPT_DTM,'YYYY/MM/DD') AS IPT_DTM                         --작성일
             , A.BLT_DT                                                           --게시일자
             , A.INQ_NO                                                           --조회수
             , A.SIT_CD                                                          --현장코드
             , A.BLT_PSN
             , ( SELECT CNST_NM FROM VQSZ_SITEINFO WHERE SIT_CD = A.SIT_CD ) AS SIT_NM -- 현장명칭
          FROM TQHA_SUBJECT A
         WHERE A.BLT_NO = p_BLT_NO
        ;

    END IF;


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_DASHBOARD_CO_Q ;
/

-- PQHA_DASHBOARD_Q
DROP PROCEDURE "PQHA_DASHBOARD_Q";
CREATE PROCEDURE "PQHA_DASHBOARD_Q" (
    p_WRK_TP        VARCHAR2 DEFAULT 'Q'    --FLAG(Q: SELECT)
,   p_SRCH_Y        VARCHAR2                --해당년도 재해현황
,   p_DISS_DIV      VARCHAR2                --재해구분
,   RTN_CURSOR      OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
     Purpose : 안전 대시보드 조회
     Procedure:    [PQHA_DASHBOARD_Q] Procedure
     설명      :   안전 대시보드 조회

     개정일자                      변경내용요약                                 관련근거
    ---------------------------------------------------------------------------------------------------------------------------
     [2024-10-14]         HumanPlus 신규 자동 생성               [Procedure Creator]
    ***************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009; --ERROR 코드
    ERR_MSG        VARCHAR2(200)  ; --ERROR Message
    USER_EXCEPTION EXCEPTION      ;

BEGIN
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리
    ---------------------------------------------------------------------------------------------------------------------------
    IF p_WRK_TP ='Q1' THEN

        OPEN RTN_CURSOR FOR 

        -- 안전 대쉬보드 작업
		WITH 
		/* 1. [기준] SIT_TERR가 NULL이 아닌 현장 목록 */
		BASE_SIT AS (
		    SELECT 
		        SIT_CD
		    FROM TQHA_SAFT_SIT
		    WHERE SIT_TERR IS NOT NULL
		),
		
		/* 2. 점검항목 및 실시건수 집계 (중점 / 일상) */
		CHKLST_AGG AS (
		    SELECT 
		        CHK.SIT_CD,
		        -- 중점점검
		        SUM(CASE WHEN CHK.RISK_GRD = 'QS0900201' AND CHK.ODAY_CHK_RSLT IS NOT NULL THEN 1 ELSE 0 END) AS MAIN_EXEC_CNT,
		        COUNT(CASE WHEN CHK.RISK_GRD = 'QS0900201' THEN CHK.CHK_ITM_CD END)                           AS MAIN_TOT_CNT,
		        -- 일상점검
		        SUM(CASE WHEN CHK.RISK_GRD = 'QS0900202' AND CHK.ODAY_CHK_RSLT IS NOT NULL THEN 1 ELSE 0 END) AS DAILY_EXEC_CNT,
		        COUNT(CASE WHEN CHK.RISK_GRD = 'QS0900202' THEN CHK.CHK_ITM_CD END)                          AS DAILY_TOT_CNT
		    FROM BASE_SIT S
		    INNER JOIN TQHB_DAYSAFE_DT DT 
		            ON S.SIT_CD = DT.SIT_CD
		           AND DT.PLN_YM = p_SRCH_Y
		    INNER JOIN TQHB_DAYSAFE_CHKLST CHK
		            ON DT.SIT_CD      = CHK.SIT_CD
		           AND DT.PLN_YM      = CHK.PLN_YM
		           AND DT.PLN_DGR     = CHK.PLN_DGR
		           AND DT.ODAY_CHK_DT = CHK.ODAY_CHK_DT
		           AND DT.RISK_GRD    = CHK.RISK_GRD
		    GROUP BY CHK.SIT_CD
		),
		
		/* 3. 점검승인일수 집계 (현장소장 승인: SITE_OMGR_YN = '1') */
		APRV_AGG AS (
		    SELECT 
		        DT.SIT_CD,
		        COUNT(DISTINCT CASE WHEN DT.RISK_GRD = 'QS0900201' AND DT.SITE_OMGR_YN = '1' THEN DT.ODAY_CHK_DT END) AS MAIN_APRV_CNT,
		        COUNT(DISTINCT CASE WHEN DT.RISK_GRD = 'QS0900202' AND DT.SITE_OMGR_YN = '1' THEN DT.ODAY_CHK_DT END) AS DAILY_APRV_CNT
		    FROM BASE_SIT S
		    INNER JOIN TQHB_DAYSAFE_DT DT 
		            ON S.SIT_CD = DT.SIT_CD
		           AND DT.PLN_YM = p_SRCH_Y
		    GROUP BY DT.SIT_CD
		),
		
		/* 4. 추가위험발굴 집계 (승인: MGR_APRV_YN = '1') */
		ADDRISK_AGG AS (
		    SELECT 
		        ORD.SIT_CD,
		        COUNT(CASE WHEN ORD.MGR_APRV_YN = '1' THEN 1 END) AS ADD_EXEC_CNT, -- 승인된 건수 (실시)
		        COUNT(*)                                          AS ADD_TOT_CNT   -- 전체 건수
		    FROM BASE_SIT S
		    INNER JOIN TQHA_ADDRISK_ORD ORD
		            ON S.SIT_CD = ORD.SIT_CD
		           AND ORD.WRT_DT LIKE p_SRCH_Y || '%'
		    GROUP BY ORD.SIT_CD
		),
		
		/* 5. 산업보건관리비 실적 집계 */
		ARSLT_TOTAL AS (
		    SELECT SIT_CD
		         , SUM(USE_AMT) AS USE_AMT
		      FROM (
		            SELECT SIT_CD, USE_AMT
		              FROM TQHA_SAFECOST_ARSLT
		             WHERE RLV_YM = p_SRCH_Y
		
		            UNION ALL
		
		            SELECT SIT_CD, USE_AMT
		              FROM TQHA_SAFECOST_ARSLT_CO
		             WHERE RLV_YM = p_SRCH_Y
		           )
		     GROUP BY SIT_CD
		),
		
		/* 6. 산업보건관리비 예산 집계 */
		BGT_TOTAL AS (
		    SELECT SIT_CD
		         , APRP_SAFT_MCHR AS BYM_EBGT_BGT
		      FROM TQHA_SAFECOST_INFO
		)
		
		/* 최종 결과 집합 */
		SELECT 
		    ROW_NUMBER() OVER (ORDER BY B.SIT_CD) AS RNUM,
		    B.SIT_CD,
		    ( SELECT CNST_NM FROM VQSZ_SITEINFO WHERE SIT_CD = B.SIT_CD ) AS SIT_NM,
		    
		    /* 1. 중점점검 */
		    NVL(C.MAIN_EXEC_CNT, 0) AS MAIN_EXEC_CNT, -- 중점 실시
		    NVL(C.MAIN_TOT_CNT, 0)  AS MAIN_TOT_CNT,  -- 중점 전체
		    
		    /* 2. 일상점검 */
		    NVL(C.DAILY_EXEC_CNT, 0) AS DAILY_EXEC_CNT, -- 일상 실시
		    NVL(C.DAILY_TOT_CNT, 0)  AS DAILY_TOT_CNT,  -- 일상 전체
		    
		    /* 3. 추가위험발굴 */
		    NVL(A.ADD_EXEC_CNT, 0) AS ADD_EXEC_CNT, -- 추가위험발굴 실시
		    NVL(A.ADD_TOT_CNT, 0)  AS ADD_TOT_CNT,  -- 추가위험발굴 전체
		    
		    /* 4. 점검승인 */
		    NVL(V.MAIN_APRV_CNT, 0)  AS MAIN_APRV_CNT, -- 중점 승인
		    NVL(V.DAILY_APRV_CNT, 0) AS DAILY_APRV_CNT, -- 일상 승인
		
		    /* 5. 안전보건관리비 (실적 및 예산) */
		    NVL(R.USE_AMT, 0)       AS USE_AMT,     -- 사용금액
		    NVL(BG.BYM_EBGT_BGT, 0) AS BYM_EBGT_BGT -- 예산액
		
		FROM BASE_SIT B
		LEFT JOIN CHKLST_AGG  C  ON B.SIT_CD = C.SIT_CD
		LEFT JOIN APRV_AGG    V  ON B.SIT_CD = V.SIT_CD
		LEFT JOIN ADDRISK_AGG A  ON B.SIT_CD = A.SIT_CD
		LEFT JOIN ARSLT_TOTAL R  ON B.SIT_CD = R.SIT_CD
		LEFT JOIN BGT_TOTAL   BG ON B.SIT_CD = BG.SIT_CD
		ORDER BY B.SIT_CD
        ;

    ELSIF p_WRK_TP ='Q2' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.*
		      ,(SELECT CNST_NM FROM VQSZ_SITEINFO WHERE SIT_CD = A.SIT_CD) AS SIT_NM
		FROM (
		    SELECT 
		        A.SIT_CD                                      AS SIT_CD,
		        COUNT(B.SIT_CD)                               AS TOT_CNT, -- B의 데이터가 있을 때만 집계
		        COUNT(CASE WHEN B.DISS_DIV = '01' THEN 1 END) AS DISS_CNT_01,
		        COUNT(CASE WHEN B.DISS_DIV = '02' THEN 1 END) AS DISS_CNT_02,
		        COUNT(CASE WHEN B.DISS_DIV = '03' THEN 1 END) AS DISS_CNT_03,
		        COUNT(CASE WHEN B.DISS_DIV = '04' THEN 1 END) AS DISS_CNT_04
		    FROM TQHA_SAFT_SIT A
		        ,TQHA_IDAC B
		        ,TCOF_APPROVE C
		    WHERE A.SIT_CD = B.SIT_CD(+) 
		      AND B.APRV_NO_GW = C.APRV_NO(+)
		      AND C.APRV_STATS(+) = '3010'        -- (+) 추가
		      AND B.ACCD_DT(+) LIKE p_SRCH_Y||'%'       -- (+) 추가
		    GROUP BY A.SIT_CD
		) A
		ORDER BY A.SIT_CD;
		
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END;
/

-- PQHA_DAYSAFE_CHKLST_B1
DROP PROCEDURE "PQHA_DAYSAFE_CHKLST_B1";
CREATE PROCEDURE "PQHA_DAYSAFE_CHKLST_B1" (    -- 일일안전점검 승인
    p_WRK_TP                VARCHAR2 :='S'                                  -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE, S : 승인처리)
,   p_WRK_ID                VARCHAR2                                        -- 사용자 ID
,   p_WRK_IP                VARCHAR2                                        -- 사용자 IP
,   p_SIT_CD                TQHA_DAYSAFE_CHKLST.SIT_CD          %TYPE       -- 현장코드
,   p_PLN_YM                TQHA_DAYSAFE_CHKLST.PLN_YM          %TYPE       -- 계획년월
,   p_PLN_DGR               TQHA_DAYSAFE_CHKLST.PLN_DGR         %TYPE       -- 회자
,   p_ODAY_CHK_DT           TQHA_DAYSAFE_CHKLST.ODAY_CHK_DT     %TYPE       -- 점검일자
,   p_USR_ID                TQHA_DAYSAFE_CHKLST.ODAY_INSP       %TYPE       -- 사번
,   p_RTN_BTN               OUT VARCHAR2                                    -- 리턴값 (안전관리자, 현장소장 승인여부)
,   p_RTN_BTN_MGR           OUT VARCHAR2                                    -- 리턴값 (관리감독자 승인여부)
,   p_RTN_MNG_DIV           OUT VARCHAR2                                    -- 리턴값 (관리자/안전/소장)
,   p_RTN_STATS_NM          OUT VARCHAR2                                    -- 리턴값 (상태)
)
IS 
    /**************************************************************************************************************************
      Purpose : 일일안전점검 승인

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2021/12/13 12:48:42                         최초생성

    **************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;


    v_MGR_APRV      VARCHAR2(1) ;   -- 관리감독자 승인여부
    v_SAFT_APRV     VARCHAR2(1) ;   -- 안전감독자 승인여부
    v_SITE_APRV     VARCHAR2(1) ;   -- 현장소장 승인여부

    v_MGR_CNT       INTEGER;        -- 관리감독자 여부
    v_SAFT_CNT      INTEGER;        -- 안전관리자 여부
    v_SITE_CNT      INTEGER;        -- 현장소장 여부

    v_RTN_BTN       VARCHAR2(1)     := 'F' ;    -- 리턴 초기값 (안전관리자, 현장소장인 경우)
    v_RTN_BTN_MGR   VARCHAR2(1)     := 'F' ;    -- 리턴 초기값 (관리감독자인 경우)
    v_RTN_MNG_DIV   VARCHAR2(10)    := 'N' ;    -- 리턴 상태 초기값 ( 관리자 MGR : 관리자, SAFT : 안전관리자, SITE : 현장소장 )

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    -- 일일점검일자테이블에서 승읜 할 데이터가 있는지 체크
    SELECT   nvl(MNG_APRV_STATS,0)           -- 관리감독자 승인여부
           , nvl(SAFT_APRV_STATS,0)          -- 안전관리자 승인여부
           , nvl(SITE_APRV_STATS,0)          -- 현장소장 승인여부
           , '▶ 상태 : ' ||
               CASE WHEN SITE_APRV_STATS IN ('1', '2') THEN
                         CASE WHEN SITE_APRV_STATS = '1' THEN '현장소장-승인'
                              ELSE '현장소장-반려'
                         END
                    ELSE CASE WHEN SAFT_APRV_STATS IN ('1', '2') THEN
                                   CASE WHEN SAFT_APRV_STATS = '1' THEN '안전관리자-승인'
                                        ELSE '안전관리자-반려'
                                   END
                              ELSE CASE WHEN MNG_APRV_STATS IN ('1', '2') THEN
                                             CASE WHEN MNG_APRV_STATS = '1' THEN '관리자-승인요청'
                                                  ELSE '-'
                                             END
                                        ELSE '-'
                                   END
                         END
               END              AS STATS_NM
        INTO v_MGR_APRV                         -- 관리감독자 승인여부
           , v_SAFT_APRV                        -- 안전관리자 승인여부
           , v_SITE_APRV                        -- 현장소장 승인여부
           , p_RTN_STATS_NM
      FROM TQHA_DAYSAFE_DT
     WHERE SIT_CD       = p_SIT_CD              --변수 (현장코드)
       AND ODAY_CHK_DT  = p_ODAY_CHK_DT         --변수 (점검일자 )
    ;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP = 'S') THEN    -- 승인처리

        -- 관리자 승인 전 단계
        IF (v_MGR_APRV = '0') THEN

            -- 관리자가 승인 권한이 있는지 체크
            SELECT nvl(COUNT(MA_PSN),0)
              INTO v_MGR_CNT
              FROM TQHA_RISK_CHK
             WHERE SIT_CD         = p_SIT_CD          -- 변수 (현장코드)
               AND PLN_YM         = p_PLN_YM          -- 변수 (계획년월)
               AND PLN_DGR        = p_PLN_DGR         -- 변수 (차수)
               AND PRRT_REG       = '1'               -- 중점등록 체크
               AND MA_PSN    IN (p_USR_ID)       -- 변수 (사번)
            ;
            -- 숭인권한이 있음
            IF v_MGR_CNT > 0 then
                v_RTN_BTN       := 'F';
                v_RTN_BTN_MGR   := 'T';
                v_RTN_MNG_DIV   := 'MGR';
            END IF;
        END IF;

       -- 관리자 승인 후 단계
        IF (v_MGR_APRV = '1' AND v_SAFT_APRV = '0' ) THEN     -- 관리자 승인 후 AND 안전관리자 승인 전

            /*
            -- 안전관리자 승인 권한이 있는지 체크
            SELECT  nvl(COUNT(JB_CD),0)
              INTO v_SAFT_CNT
              FROM  ( -- 조직도에서 직무코드가 안전관리자인 경우
                     SELECT   DEPT_CD   -- 현장코드
                           , USR_ID    -- 사용자 id
                           , JB_CD     -- 직무코드
                      FROM TCOZ_USR_INFO
                     WHERE DEPT_CD = p_SIT_CD       -- 변수(현장코드)
                     AND  JB_CD IN ('B37E01','CM0135','CM0136','CM0137') ) A
             WHERE A.DEPT_CD = p_SIT_CD   -- 변수 (현장코드)
               AND A.USR_ID = p_USR_ID     -- 변수 (사용자id)
                  ;
            */

            -- 안전관리자 승인 권한이 있는지 체크
            SELECT  nvl(COUNT(JB_CD),0)
              INTO v_SAFT_CNT
              FROM (
                    -- 2026.01.20 주석 처리
                    -- 조직도에서 직무코드가 안전관리자인 경우
                    --SELECT   DEPT_CD   -- 현장코드
                    --        , USR_ID    -- 사용자 id
                    --        , JB_CD     -- 직무코드
                    --  FROM TCOZ_USR_INFO
                    -- WHERE DEPT_CD = p_SIT_CD       -- 변수(현장코드)
                    --   AND  JB_CD IN ('B37E01','CM0135','CM0136','CM0137')
                    -- UNION   -- 2020/5/18 일 겸직정보 추가
                    -- SELECT DEPT_CD   -- 현장코드
                    --       , USR_ID    -- 사용자 id
                    --       , JB_CD     -- 직무코드
                    --   FROM TCOZ_SBJB_INFO
                    --  WHERE DEPT_CD = p_SIT_CD
                    --    AND JB_CD IN ('B37E01','CM0135','CM0136','CM0137')

                     SELECT SIT_CD    AS DEPT_CD
                         , EMPE_NO    AS USR_ID
                         , JB_CD      AS JB_CD
                      FROM TQHA_SITENAM
                     WHERE SIT_CD = p_SIT_CD
                       AND EMPE_NO = p_USR_ID
                       AND JB_CD IN ('QS07702')  -- 안전관리자, 안전총괄
                   ) A
             WHERE A.DEPT_CD     = p_SIT_CD      -- 변수 (현장코드)
               AND A.USR_ID      = p_USR_ID      -- 변수 (사용자id)
            ;

            -- 안전관리자가 승인 권한이 있는지 체크
            IF v_SAFT_CNT > 0 then
                v_RTN_BTN       := 'T';
                v_RTN_BTN_MGR   := 'F';
                v_RTN_MNG_DIV   := 'SAFT';
            END IF;

        END IF;

        -- 안전관리자 승인 후 단계
        IF (v_MGR_APRV = '1' AND v_SAFT_APRV = '1') THEN

            -- 현장소장 승인 권한이 있는지 체크
            SELECT  nvl(COUNT(JB_CD),0)
              INTO v_SITE_CNT
              FROM (
                    -- 2026.01.20 주석
                    -- 조직도에서 직무코드가 안전관리자인 경우
                    --                    SELECT   DEPT_CD   -- 현장코드
                    --                          , USR_ID    -- 사용자 id
                    --                          , JB_CD     -- 직무코드
                    --                     FROM TCOZ_USR_INFO
                    --                    WHERE DEPT_CD = p_SIT_CD   -- 변수(현장코드)
                    --                    AND  JB_CD IN ('B37F01') ) A

                     SELECT SIT_CD    AS DEPT_CD
                         , EMPE_NO    AS USR_ID
                         , JB_CD      AS JB_CD
                      FROM TQHA_SITENAM
                     WHERE SIT_CD = p_SIT_CD
                       AND EMPE_NO = p_USR_ID
                       AND JB_CD IN ('QS07703')  -- 현장소장
                   ) A
             WHERE A.DEPT_CD    = p_SIT_CD      -- 변수 (현장코드)
               AND A.USR_ID     = p_USR_ID      -- 변수 (사용자id)
            ;

            -- 현장소장 승인 권한이 있는지 체크
            IF v_SITE_CNT > 0 then
               v_RTN_BTN        := 'T';
               v_RTN_BTN_MGR    := 'F';
               v_RTN_MNG_DIV    := 'SITE';
            END IF;

        END IF;

       -- 현장소장 승인 후 단계
        IF (v_SITE_APRV <> '0' ) THEN
            v_RTN_BTN       := 'F';
            v_RTN_BTN_MGR   := 'F';
            v_RTN_MNG_DIV   := 'N';
        END IF;

        p_RTN_BTN := v_RTN_BTN ;
        p_RTN_BTN_MGR := v_RTN_BTN_MGR ;
        p_RTN_MNG_DIV := v_RTN_MNG_DIV;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END PQHA_DAYSAFE_CHKLST_B1;
/

-- PQHA_DAYSAFE_CHKLST_Q
DROP PROCEDURE "PQHA_DAYSAFE_CHKLST_Q";
CREATE PROCEDURE "PQHA_DAYSAFE_CHKLST_Q" (  
    p_WRK_TP                IN VARCHAR2 DEFAULT 'Q'             -- FLAG
,   p_SIT_CD                IN VARCHAR2
,   p_PLN_YM                IN VARCHAR2
,   p_PLN_DGR               IN VARCHAR2
,   p_RISK_GRD              IN VARCHAR2
,   RTN_CURSOR              OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [평가항목 조회] PROCEDRE (QSE > 안전관리 > 중점점검관리 > 일일안전점검  )

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2023/12/07                                 최초생성  

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD             -- 현장코드
		     , A.PLN_YM             -- 계획년월
		     , A.PLN_DGR            -- 계획차수
		     , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.PLN_DGR AND HRNK_CD = 'QS005') AS PLN_DGR_NM -- 계획차수명
		     , A.ODAY_CHK_DT        -- 점검일자
		     , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.EMPE_NO_SAFT ) AS EMPE_NO_SAFT_NM --안전책임자
		     , A.EMPE_NO_SAFT
			 , A.SAFT_MGR_YN
			 , DECODE(A.SAFT_MGR_YN,'1','O','X') AS SAFT_MGR_YN_NM
			 , DECODE(A.SAFT_MGR_YN,'1',A.SAFT_MGR_DT,'') AS SAFT_MGR_DT
			 , A.SAFT_MGR_OPIN
			 , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.EMPE_NO_OMGR ) AS EMPE_NO_OMGR_NM --현장소장
			 , A.EMPE_NO_OMGR
			 , A.SITE_OMGR_YN
			 , DECODE(A.SITE_OMGR_YN,'1','O','X') AS SITE_OMGR_YN_NM
			 , DECODE(A.SITE_OMGR_YN,'1',A.SITE_OMGR_DT,'') AS SITE_OMGR_DT
			 , A.SITE_OMGR_OPIN
		     , A.RISK_GRD     
		  FROM TQHB_DAYSAFE_DT A
		 WHERE 1=1
           AND A.SIT_CD = p_SIT_CD
           AND A.PLN_YM = p_PLN_YM
           AND A.RISK_GRD = p_RISK_GRD
         ORDER BY A.ODAY_CHK_DT
	       ;

    END IF;


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_DAYSAFE_CHKLST_Q;
/

-- PQHA_DAYSAFE_CHKLST_S
DROP PROCEDURE "PQHA_DAYSAFE_CHKLST_S";
CREATE PROCEDURE "PQHA_DAYSAFE_CHKLST_S" (
    p_WRK_TP                VARCHAR2 :='U'                                          -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID                VARCHAR2                                                -- 사용자 ID
,   p_WRK_IP                VARCHAR2                                                -- 사용자 IP
,   p_SIT_CD                TQHA_DAYSAFE_CHKLST.SIT_CD              %TYPE           -- 현장코드
,   p_PLN_YM                TQHA_DAYSAFE_CHKLST.PLN_YM              %TYPE           -- 계획년월
,   p_PLN_DGR               TQHA_DAYSAFE_CHKLST.PLN_DGR             %TYPE           -- 차수구분코드(QS005) 1 1차,2 2차
,   p_ODAY_CHK_DT           TQHA_DAYSAFE_CHKLST.ODAY_CHK_DT         %TYPE           -- 일일점검일자
,   p_CTP_CD                TQHA_DAYSAFE_CHKLST.CTP_CD              %TYPE           -- 공종코드
,   p_CHK_ITM_CD            TQHA_DAYSAFE_CHKLST.CHK_ITM_CD          %TYPE           -- 점검항목코드
,   p_UNT_CD                TQHA_DAYSAFE_CHKLST.UNT_CD              %TYPE           -- 단위코드
,   p_CUST_CD               TQHA_DAYSAFE_CHKLST.CUST_CD             %TYPE           -- 협력업체코드
,   p_VNDR_SEQ              TQHA_DAYSAFE_CHKLST.VNDR_SEQ            %TYPE           -- 업체순번
,   p_ODAY_CHK_RSLT         TQHA_DAYSAFE_CHKLST.ODAY_CHK_RSLT       %TYPE           -- 점검결과(QS006) 1 N/A,2 완료(유지),3 불량
,   p_ODAY_CHK_OPIN         TQHA_DAYSAFE_CHKLST.ODAY_CHK_OPIN       %TYPE           -- 일일점검의견
,   p_ODAY_INSP             TQHA_DAYSAFE_CHKLST.ODAY_INSP           %TYPE           -- 일일점검자
,   p_PHOTO_GRP1            TQHA_DAYSAFE_CHKLST.PHOTO_GRP1          %TYPE           -- 첨부파일그룹사진1
,   p_PHOTO_DESC_1          TQHA_DAYSAFE_CHKLST.PHOTO_DESC_1        %TYPE           -- 사진설명1
,   p_PHOTO_GRP2            TQHA_DAYSAFE_CHKLST.PHOTO_GRP2          %TYPE           -- 첨부파일그룹사진2
,   p_PHOTO_DESC_2          TQHA_DAYSAFE_CHKLST.PHOTO_DESC_2        %TYPE           -- 사진설명2
,   p_NCR_PUBC_YN           TQHA_DAYSAFE_CHKLST.NCR_PUBC_YN         %TYPE           -- 발행 1, 미발행 0
,   p_NCR_DOC_NO            TQHA_DAYSAFE_CHKLST.NCR_DOC_NO          %TYPE           -- 부적합문서번호
,   p_MA_DDLN_DT            TQHA_DAYSAFE_CHKLST.MA_DDLN_DT          %TYPE           -- 조치기한일자
,   p_VNDR_NOTI_YN          TQHA_DAYSAFE_CHKLST.VNDR_NOTI_YN        %TYPE           -- 업체통보여부
,   p_VNDR_SEND_DT          TQHA_DAYSAFE_CHKLST.VNDR_SEND_DT        %TYPE           -- 업체발송일자
)
IS
    /**************************************************************************************************************************
      Purpose :

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2021/12/17 14:26:11                         최초생성

    **************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_CNT              NUMBER := 0;
    v_OLD_NCR_DOC_NO   VARCHAR2(50);
    v_VNDR_APRV_YN     VARCHAR2(1);
    v_MGR_APRV_YN      VARCHAR2(1);

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_YM IS NULL)  THEN
        ERR_MSG := '계획년월는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_DGR IS NULL)  THEN
        ERR_MSG := '차수구분코드(QS005) 1 1차,2 2차는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_ODAY_CHK_DT IS NULL)  THEN
        ERR_MSG := '일일점검일자는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CTP_CD IS NULL)  THEN
        ERR_MSG := '공종코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CHK_ITM_CD IS NULL)  THEN
        ERR_MSG := '점검항목코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_UNT_CD IS NULL)  THEN
        ERR_MSG := '단위코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CUST_CD IS NULL)  THEN
        ERR_MSG := '협력업체코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_VNDR_SEQ IS NULL)  THEN
        ERR_MSG := '업체순번는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='P') THEN

        -- 2025.02.02 부적합보고서 승인 상태 체크하여, 업체 승인 요청시 또는 관리자 승인시엔 불량에서 다른걸로 변경하지 못하게 막아야 함.
        SELECT NVL(MAX(NCR_DOC_NO), '*')
          INTO v_OLD_NCR_DOC_NO
          FROM TQHA_DAYSAFE_CHKLST
         WHERE SIT_CD       = p_SIT_CD          --현장코드
           AND PLN_YM       = p_PLN_YM          --계획년월
           AND PLN_DGR      = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
           AND ODAY_CHK_DT  = p_ODAY_CHK_DT     --일일점검일자
           AND CTP_CD       = p_CTP_CD          --공종코드
           AND CHK_ITM_CD   = p_CHK_ITM_CD      --점검항목코드
           AND UNT_CD       = p_UNT_CD          --단위코드
        ;

        IF v_OLD_NCR_DOC_NO != '*' THEN
            SELECT VNDR_APRV_YN
                 , MGR_APRV_YN
              INTO v_VNDR_APRV_YN
                 , v_MGR_APRV_YN
              FROM TQHA_NCR_REP
             WHERE SIT_CD       = p_SIT_CD
               AND NCR_DOC_NO   = v_OLD_NCR_DOC_NO
            ;

            IF v_MGR_APRV_YN = '1' THEN
                ERR_MSG := '부적합보고서 관리자가 승인한 상태여서 변경할 수 없습니다.'
                        || CHR(10) || '관리자 반려 후, 업체 승인요청취소 후에 변경 가능합니다. ';
                RAISE USER_EXCEPTION;
            END IF;

            IF v_VNDR_APRV_YN = '1' THEN
                ERR_MSG := '부적합보고서 업체 승인요청중이어서 변경할 수 없습니다.'
                        || CHR(10) || '승인요청 취소 후 변경 가능합니다 ';
                RAISE USER_EXCEPTION;
            END IF;

        END IF;

        -- 해당 데이터가 있는지 확인
        SELECT COUNT(*) INTO v_CNT
          FROM TQHA_DAYSAFE_CHKLST
         WHERE SIT_CD           = p_SIT_CD          -- 현장코드
           AND PLN_YM           = p_PLN_YM          -- 계획년월
           AND PLN_DGR          = p_PLN_DGR         -- 차수구분코드(QS005) 1 1차,2 2차
           AND ODAY_CHK_DT      = p_ODAY_CHK_DT     -- 일일점검일자
           AND CTP_CD           = p_CTP_CD          -- 공종코드
           AND CHK_ITM_CD       = p_CHK_ITM_CD      -- 점검항목코드
           AND UNT_CD           = p_UNT_CD          -- 단위코드
        ;

        -- 대상업체가 있는 경우
        IF (v_CNT > 0) THEN

            UPDATE TQHA_DAYSAFE_CHKLST
               SET CUST_CD              = p_CUST_CD                 --협력업체코드
                 , VNDR_SEQ             = p_VNDR_SEQ                --업체순번
                 , ODAY_CHK_RSLT        = p_ODAY_CHK_RSLT           --점검결과(QS006) 1 N/A,2 완료(유지),3 불량
                 , ODAY_CHK_OPIN        = p_ODAY_CHK_OPIN           --일일점검의견
                 , ODAY_INSP            = p_ODAY_INSP               --일일점검자
                 , PHOTO_GRP1           = p_PHOTO_GRP1              --첨부파일그룹사진1
                 , PHOTO_DESC_1         = p_PHOTO_DESC_1            --사진설명1
                 , PHOTO_GRP2           = p_PHOTO_GRP2              --첨부파일그룹사진2
                 , PHOTO_DESC_2         = p_PHOTO_DESC_2            --사진설명2
                 , NCR_PUBC_YN          = p_NCR_PUBC_YN             --발행 1, 미발행 0
                 , NCR_DOC_NO           = p_NCR_DOC_NO              --부적합문서번호
                 , MA_DDLN_DT           = p_MA_DDLN_DT              --조치기한일자
                 , VNDR_NOTI_YN         = p_VNDR_NOTI_YN            --업체통보여부
                 , VNDR_SEND_DT         = p_VNDR_SEND_DT            --업체발송일자
                 , UPD_ID               = p_WRK_ID                  --수정ID
                 , UPD_DTM              = SYSDATE()                 --수정일시
                 , UPD_IP               = p_WRK_IP                  --수정IP
             WHERE SIT_CD               = p_SIT_CD                  --현장코드
               AND PLN_YM               = p_PLN_YM                  --계획년월
               AND PLN_DGR              = p_PLN_DGR                 --차수구분코드(QS005) 1 1차,2 2차
               AND ODAY_CHK_DT          = p_ODAY_CHK_DT             --일일점검일자
               AND CTP_CD               = p_CTP_CD                  --공종코드
               AND CHK_ITM_CD           = p_CHK_ITM_CD              --점검항목코드
               AND UNT_CD               = p_UNT_CD                  --단위코드
            ;

        ELSE

            INSERT 
              INTO TQHA_DAYSAFE_CHKLST
                 ( SIT_CD                   -- 현장코드
                 , PLN_YM                   -- 계획년월
                 , PLN_DGR                  -- 차수구분코드(QS005) 1 1차,2 2차
                 , ODAY_CHK_DT              -- 일일점검일자
                 , CTP_CD                   -- 공종코드
                 , CHK_ITM_CD               -- 점검항목코드
                 , UNT_CD                   -- 단위코드
                 , CUST_CD                  -- 협력업체코드
                 , VNDR_SEQ                 -- 업체순번
                 , ODAY_CHK_RSLT            -- 점검결과(QS006) 1 N/A,2 완료(유지),3 불량
                 , ODAY_CHK_OPIN            -- 일일점검의견
                 , ODAY_INSP                -- 일일점검자
                 , PHOTO_GRP1               -- 첨부파일그룹사진1
                 , PHOTO_DESC_1             -- 사진설명1
                 , PHOTO_GRP2               -- 첨부파일그룹사진2
                 , PHOTO_DESC_2             -- 사진설명2
                 , NCR_PUBC_YN              -- 발행 1, 미발행 0
                 , NCR_DOC_NO               -- 부적합문서번호
                 , MA_DDLN_DT               -- 조치기한일자
                 , VNDR_NOTI_YN             -- 업체통보여부
                 , VNDR_SEND_DT             -- 업체발송일자
                 , IPT_ID                   -- 입력ID
                 , IPT_DTM                  -- 입력일시
                 , IPT_IP                   -- 입력IP
                 , UPD_ID                   -- 수정ID
                 , UPD_DTM                  -- 수정일시
                 , UPD_IP                   -- 수정IP
                 )
            VALUES 
                 ( p_SIT_CD                 -- 현장코드
                 , p_PLN_YM                 -- 계획년월
                 , p_PLN_DGR                -- 차수구분코드(QS005) 1 1차,2 2차
                 , p_ODAY_CHK_DT            -- 일일점검일자
                 , p_CTP_CD                 -- 공종코드
                 , p_CHK_ITM_CD             -- 점검항목코드
                 , p_UNT_CD                 -- 단위코드
                 , p_CUST_CD                -- 협력업체코드
                 , p_VNDR_SEQ               -- 업체순번
                 , p_ODAY_CHK_RSLT          -- 점검결과(QS006) 1 N/A,2 완료(유지),3 불량
                 , p_ODAY_CHK_OPIN          -- 일일점검의견
                 , p_ODAY_INSP              -- 일일점검자
                 , p_PHOTO_GRP1             -- 첨부파일그룹사진1
                 , p_PHOTO_DESC_1           -- 사진설명1
                 , p_PHOTO_GRP2             -- 첨부파일그룹사진2
                 , p_PHOTO_DESC_2           -- 사진설명2
                 , p_NCR_PUBC_YN            -- 발행 1, 미발행 0
                 , p_NCR_DOC_NO             -- 부적합문서번호
                 , p_MA_DDLN_DT             -- 조치기한일자
                 , p_VNDR_NOTI_YN           -- 업체통보여부
                 , p_VNDR_SEND_DT           -- 업체발송일자
                 , p_WRK_ID                 -- 입력ID
                 , SYSDATE()                -- 입력일시
                 , p_WRK_IP                 -- 입력IP
                 , p_WRK_ID                 -- 수정ID
                 , SYSDATE()                -- 수정일시
                 , p_WRK_IP                 -- 수정IP
                 )
            ;

    END IF;

    ELSIF (p_WRK_TP ='D') THEN

        DELETE
          FROM TQHA_DAYSAFE_CHKLST
         WHERE SIT_CD           = p_SIT_CD          -- 현장코드
           AND PLN_YM           = p_PLN_YM          -- 계획년월
           AND PLN_DGR          = p_PLN_DGR         -- 차수구분코드(QS005) 1 1차,2 2차
           AND ODAY_CHK_DT      = p_ODAY_CHK_DT     -- 일일점검일자
           AND CTP_CD           = p_CTP_CD          -- 공종코드
           AND CHK_ITM_CD       = p_CHK_ITM_CD      -- 점검항목코드
           AND UNT_CD           = p_UNT_CD          -- 단위코드
        ;

    ELSIF (p_WRK_TP ='U') THEN

        UPDATE TQHA_DAYSAFE_CHKLST
           SET CUST_CD              = p_CUST_CD                 -- 협력업체코드
             , VNDR_SEQ             = p_VNDR_SEQ                -- 업체순번
             , ODAY_CHK_RSLT        = p_ODAY_CHK_RSLT           -- 점검결과(QS006) 1 N/A,2 완료(유지),3 불량
             , ODAY_CHK_OPIN        = p_ODAY_CHK_OPIN           -- 일일점검의견
             , ODAY_INSP            = p_ODAY_INSP               -- 일일점검자
             , PHOTO_GRP1           = p_PHOTO_GRP1              -- 첨부파일그룹사진1
             , PHOTO_DESC_1         = p_PHOTO_DESC_1            -- 사진설명1
             , PHOTO_GRP2           = p_PHOTO_GRP2              -- 첨부파일그룹사진2
             , PHOTO_DESC_2         = p_PHOTO_DESC_2            -- 사진설명2
             , NCR_PUBC_YN          = p_NCR_PUBC_YN             -- 발행 1, 미발행 0
             , NCR_DOC_NO           = p_NCR_DOC_NO              -- 부적합문서번호
             , MA_DDLN_DT           = p_MA_DDLN_DT              -- 조치기한일자
             , VNDR_NOTI_YN         = p_VNDR_NOTI_YN            -- 업체통보여부
             , VNDR_SEND_DT         = p_VNDR_SEND_DT            -- 업체발송일자
             , UPD_ID               = p_WRK_ID                  -- 수정ID
             , UPD_DTM              = SYSDATE()                 -- 수정일시
             , UPD_IP               = p_WRK_IP                  -- 수정IP
         WHERE SIT_CD               = p_SIT_CD                  -- 현장코드
           AND PLN_YM               = p_PLN_YM                  -- 계획년월
           AND PLN_DGR              = p_PLN_DGR                 -- 차수구분코드(QS005) 1 1차,2 2차
           AND ODAY_CHK_DT          = p_ODAY_CHK_DT             -- 일일점검일자
           AND CTP_CD               = p_CTP_CD                  -- 공종코드
           AND CHK_ITM_CD           = p_CHK_ITM_CD              -- 점검항목코드
           AND UNT_CD               = p_UNT_CD                  -- 단위코드
        ;

    ELSE

        INSERT 
          INTO TQHA_DAYSAFE_CHKLST
             ( SIT_CD                   -- 현장코드
             , PLN_YM                   -- 계획년월
             , PLN_DGR                  -- 차수구분코드(QS005) 1 1차,2 2차
             , ODAY_CHK_DT              -- 일일점검일자
             , CTP_CD                   -- 공종코드
             , CHK_ITM_CD               -- 점검항목코드
             , UNT_CD                   -- 단위코드
             , CUST_CD                  -- 협력업체코드
             , VNDR_SEQ                 -- 업체순번
             , ODAY_CHK_RSLT            -- 점검결과(QS006) 1 N/A,2 완료(유지),3 불량
             , ODAY_CHK_OPIN            -- 일일점검의견
             , ODAY_INSP                -- 일일점검자
             , PHOTO_GRP1               -- 첨부파일그룹사진1
             , PHOTO_DESC_1             -- 사진설명1
             , PHOTO_GRP2               -- 첨부파일그룹사진2
             , PHOTO_DESC_2             -- 사진설명2
             , NCR_PUBC_YN              -- 발행 1, 미발행 0
             , NCR_DOC_NO               -- 부적합문서번호
             , MA_DDLN_DT               -- 조치기한일자
             , VNDR_NOTI_YN             -- 업체통보여부
             , VNDR_SEND_DT             -- 업체발송일자
             , IPT_ID                   -- 입력ID
             , IPT_DTM                  -- 입력일시
             , IPT_IP                   -- 입력IP
             , UPD_ID                   -- 수정ID
             , UPD_DTM                  -- 수정일시
             , UPD_IP                   -- 수정IP
             )
        VALUES 
             ( p_SIT_CD                 -- 현장코드
             , p_PLN_YM                 -- 계획년월
             , p_PLN_DGR                -- 차수구분코드(QS005) 1 1차,2 2차
             , p_ODAY_CHK_DT            -- 일일점검일자
             , p_CTP_CD                 -- 공종코드
             , p_CHK_ITM_CD             -- 점검항목코드
             , p_UNT_CD                 -- 단위코드
             , p_CUST_CD                -- 협력업체코드
             , p_VNDR_SEQ               -- 업체순번
             , p_ODAY_CHK_RSLT          -- 점검결과(QS006) 1 N/A,2 완료(유지),3 불량
             , p_ODAY_CHK_OPIN          -- 일일점검의견
             , p_ODAY_INSP              -- 일일점검자
             , p_PHOTO_GRP1             -- 첨부파일그룹사진1
             , p_PHOTO_DESC_1           -- 사진설명1
             , p_PHOTO_GRP2             -- 첨부파일그룹사진2
             , p_PHOTO_DESC_2           -- 사진설명2
             , p_NCR_PUBC_YN            -- 발행 1, 미발행 0
             , p_NCR_DOC_NO             -- 부적합문서번호
             , p_MA_DDLN_DT             -- 조치기한일자
             , p_VNDR_NOTI_YN           -- 업체통보여부
             , p_VNDR_SEND_DT           -- 업체발송일자
             , p_WRK_ID                 -- 입력ID
             , SYSDATE()                -- 입력일시
             , p_WRK_IP                 -- 입력IP
             , p_WRK_ID                 -- 수정ID
             , SYSDATE()                -- 수정일시
             , p_WRK_IP                 -- 수정IP
             )
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END ;
/

-- PQHA_DAY_SAFT_CHK_REG_OTHER_Q
DROP PROCEDURE "PQHA_DAY_SAFT_CHK_REG_OTHER_Q";
CREATE PROCEDURE "PQHA_DAY_SAFT_CHK_REG_OTHER_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'         -- FLAG
,   p_SIT_CD            IN VARCHAR2                     -- 현장코드
,   p_PLN_YM            IN VARCHAR2                     -- 계획연월
,   p_PLN_DGR           IN VARCHAR2                     -- 계획차수
,   p_ODAY_CHK_DT       IN VARCHAR2                     -- 일일점검일자
,   p_RISK_GRD          IN VARCHAR2                     -- 점검구분
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [일일안전점검] PROCEDRE 

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2026/02/09                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    -- 
    IF p_WRK_TP = 'Q1' THEN

        -- 그리드 조회 : 일일안전점검 작성 - 일일안전점검목록
        OPEN RTN_CURSOR FOR
        	SELECT  A.SIT_CD                 --현장코드
		           ,A.PLN_YM                 --계획년월
		           ,A.PLN_DGR                 --차수구분코드(QS005) 1 1차,2 2차
		           ,A.CUST_CD                 --협력업체코드
		           ,A.VNDR_SEQ                 --업체순번   
		           ,(SELECT CUST_NM FROM VQSZ_TRADE WHERE CUST_CD = A.CUST_CD) AS CUST_NM
		           ,A.CTP_CD                 --공종코드
		           ,(SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD) AS CTP_NM
		           ,A.UNT_CD                 --단위코드
		           ,(SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD) AS UNT_NM
		           ,A.CHK_LOC
		           ,A.CHK_ITM_CD                 --점검항목코드
		           ,A.CHK_ITM_SEQ
				   ,A.CHK_ITM_NM
		           ,A.IMPRV_CPLN                 --개선대책
		           ,A.MGR_OPIN                 --관리자의견
		           ,B.RISK_GRD
		           ,B.ODAY_CHK_DT
		           ,B.ODAY_CHK_RSLT                 --점검결과(QS006) 1 N/A,2 완료(유지),3 불량
		           ,B.ODAY_CHK_OPIN                 --일일안전책임자 점검의견
		           ,B.EMPE_NO                 --일일안전책임자 사번
		           ,(SELECT USR_NM FROM TCOZ_USR_INFO WHERE EMPNO = B.EMPE_NO) AS USR_NM
		           ,B.PHOTO_GRP1                 --첨부파일그룹사진1
		           ,B.PHOTO_DESC_1                 --사진설명1
		           ,B.PHOTO_GRP2                 --첨부파일그룹사진2
		           ,B.PHOTO_DESC_2                 --사진설명2
		           ,B.NCR_PUBC_YN                 --발행 1, 미발행 0
		           ,B.VNDR_NOTI_YN                 --발송 1 미발송0
		           ,B.VNDR_SEND_DT                 --업체발송일자
		           ,B.VNDR_MA_YN                 --조치구분(QS007) 1 조치, 0 미조치
		           ,B.NCR_DOC_NO                    -- 부적합문서번호
		           ,C.APRS_STR_DT
				  , C.APRS_END_DT				 
				  , ( SELECT CUST_NM FROM VQSZ_TRADE WHERE CUST_CD = D.CUST_CD ) AS VNDR_NM
	              , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = D.VNDR_MA_YN AND HRNK_CD = 'QS025') AS VNDR_MA_YN_NM
	              , D.MA_DDLN_DT
	              , D.VNDR_MA_DT
	              , DECODE((SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = D.VNDR_MA_PSN), '', D.VNDR_MA_PSN, (SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = D.VNDR_MA_PSN)) AS VNDR_MA_PSN_NM				  
		          FROM TQHB_RISK_LST A
		             , TQHB_DAYSAFE_CHKLST B
		             , TQHB_RISK_DGR C
		             , TQHA_NCR_REP D
		         WHERE A.SIT_CD             = p_SIT_CD
		           AND A.PLN_YM             = p_PLN_YM
		           AND A.PLN_DGR            = p_PLN_DGR
		           AND B.RISK_GRD           = p_RISK_GRD
		           AND B.ODAY_CHK_DT(+)     = p_ODAY_CHK_DT
		           AND A.SIT_CD             = B.SIT_CD(+)
		           AND A.PLN_YM             = B.PLN_YM(+)
		           AND A.PLN_DGR            = B.PLN_DGR(+)
		           AND A.CUST_CD            = B.CUST_CD(+)
		           AND A.VNDR_SEQ           = B.VNDR_SEQ(+)
		           AND A.CTP_CD             = B.CTP_CD(+)
		           AND A.UNT_CD             = B.UNT_CD(+)
		           AND A.CHK_ITM_CD         = B.CHK_ITM_CD(+)
		           AND A.RISK_GRD           = B.RISK_GRD(+)
		           AND A.SIT_CD             = C.SIT_CD(+)
		           AND A.PLN_YM             = C.PLN_YM(+)
		           AND A.PLN_DGR            = C.PLN_DGR(+)
		           AND B.SIT_CD             = D.SIT_CD(+)
		           AND B.NCR_DOC_NO         = D.NCR_DOC_NO(+)
		     ORDER BY A.CUST_CD, A.CTP_CD, A.UNT_CD
		           
        ;

    ---------------------------------------------------------------------------------------
    ELSIF p_WRK_TP = 'Q2' THEN

        -- 그리드 조회 : 조회조건 - 점검일자
        OPEN RTN_CURSOR FOR
        SELECT APRS_STR_DT    -- 평가시작일
             , APRS_END_DT    -- 평가종료일
          FROM TQHB_RISK_DGR A
         WHERE A.SIT_CD     = p_SIT_CD
           AND A.PLN_YM     = p_PLN_YM
           AND A.PLN_DGR    = p_PLN_DGR
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_DAY_SAFT_CHK_REG_OTHER_Q;
/

-- PQHA_DRM_Q
DROP PROCEDURE "PQHA_DRM_Q";
CREATE PROCEDURE "PQHA_DRM_Q" (
    p_WRK_TP            VARCHAR2 DEFAULT 'Q'    -- FLAG( Q: SELECT )
,   p_WRK_ID            IN VARCHAR2             -- 입력자ID
,   p_WRK_CORP          IN VARCHAR2             -- 법인
,   p_WRK_DEPT          IN VARCHAR2             -- 부서
,   p_WRK_MNU           IN VARCHAR2             -- 메뉴코드
,   p_SIT_CD            IN VARCHAR2             -- 현장코드
,   p_SEARCH_TEXT       IN VARCHAR2             -- 검색어
,   p_SEARCH_IPT_YM_FR  IN VARCHAR2             -- 조회기간 ST
,   p_SEARCH_IPT_YM_TO  IN VARCHAR2             -- 조회기간 ED
,   p_SEARCH_DATA_DIV   IN VARCHAR2             -- 자료구분
,   p_SEARCH_OTHER_SIT_INC  IN VARCHAR2         -- 타현장 자료
,   p_REG_NO            IN NUMBER               -- 등록번호
,   p_REG_DGR           IN NUMBER               -- 등록차수
,   p_ADM_YN            IN VARCHAR2             -- 자료실관리자 여부
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS 
    /**************************************************************************************************************************
      Purpose : 

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/01/30 12:36:20                         최초생성
      1.1     2026/04/22                                  3레벨 구조로 변경 (DATA_SUB_DIV2 추가)

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_CURSOR        SYS_REFCURSOR;
    v_LIST          OQSA_DRM_INFO_LIST := OQSA_DRM_INFO_LIST();     -- TYPE OBJECT

    v_REG_NO           NUMBER       ;        -- 등록번호 (NVL 계산식에 숫자가 보여 NUMBER로 지정)
    v_REG_DGR          NUMBER       ;        -- 등록차수
    v_DATA_DIV         VARCHAR2(50) ;        -- 자료구분
    v_DATA_SUB_DIV     VARCHAR2(50) ;        -- 자료구분2
    v_DATA_SUB_DIV2    VARCHAR2(50) ;        -- 자료구분3
    v_DATA_DIV_NM      VARCHAR2(100);        -- 자료구분명
    v_DATA_SUB_DIV_NM  VARCHAR2(100);        -- 자료구분2명
    v_DATA_SUB_DIV2_NM VARCHAR2(100);        -- 자료구분3명
    v_DATA_NM          VARCHAR2(300);        -- 자료명
    v_DATA_DESC        CLOB         ;        -- 자료설명
    v_BLT_MAIL         VARCHAR2(10) ;        -- 게시우편물
    v_BLT_SMS          VARCHAR2(10) ;        -- 게시SMS
    v_ATFL_GRP         VARCHAR2(50) ;        -- 첨부파일 그룹
    v_SIT_CD           VARCHAR2(50) ;        -- 현장코드
    v_SIT_NM           VARCHAR2(200);        -- 현장명
    v_FNL_YN           VARCHAR2(1)  ;        -- 최종여부
    v_TAG              VARCHAR2(100);        -- 검색태그
    v_IPT_ID           VARCHAR2(50) ;        -- 입력자ID
    v_IPT_DTM          DATE         ;        -- 입력일시
    v_IPT_YMD          VARCHAR2(8)  ;        -- 입력일자(YYYYMMDD)
    v_VIEW_YN          VARCHAR2(1)  ;        -- 보기권한 ('1' or '0')
    v_APL_SEQ          NUMBER       ;        -- 열람신청번호
    v_APL_STATS        VARCHAR2(20) ;        -- 열람신청상태
    v_DEPT_CD          VARCHAR2(50) ;        -- 부서코드
    v_VIEW_CNT         NUMBER       ;        -- 조회수
    v_VIEW_STATS       VARCHAR2(100);        -- 열람상태(열람가능 등)
    v_VIEW_TERM        VARCHAR2(100);        -- 열람기간(YYYY-MM-DD~...)
    v_MNU_CD           VARCHAR(50);          -- 메뉴코드
    v_DATA_DIV_1       VARCHAR(20);          -- 자료구분
    v_DATA_DIV_2       VARCHAR(20);          -- 자료구분2
    v_DATA_DIV_3       VARCHAR(20);          -- 자료구분3
    v_EDT_YN           VARCHAR(1);           -- 수정권한
    v_WRTR_NM          VARCHAR(100);         -- 등록자명
BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리
    ---------------------------------------------------------------------------------------------------------------------------

    IF (p_WRK_TP = 'Q') THEN

        OPEN RTN_CURSOR FOR
        SELECT
		      T1.REG_NO                                       -- 등록번호
		    , T1.REG_DGR                                      -- 등록차수
		    , T1.DATA_DIV                                     -- 자료구분
		    , T1.DATA_SUB_DIV                                 -- 자료구분2
		    , T1.DATA_SUB_DIV2                                -- 자료구분3
		    , T7.CD_NM                         AS DATA_DIV_NM
		    , T8.CD_NM                         AS DATA_SUB_DIV_NM
		    , T13.CD_NM                        AS DATA_SUB_DIV2_NM
		    , T1.DATA_NM                                      -- 자료명
		    , T1.DATA_DESC                                    -- 자료설명
		    , T1.BLT_MAIL                                     -- 게시우편물
		    , T1.BLT_SMS                                      -- 게시SMS
		    , T1.ATFL_GRP                                     -- 첨부파일
		    , T1.SIT_CD                                       -- 현장코드
		    , T10.SIT_NM
		    , T1.FNL_YN                                       -- 최종여부
		    , T1.TAG                                          -- 검색태그
		    , T1.IPT_ID
		    , T1.IPT_DTM
		    , TO_CHAR(T1.IPT_DTM, 'YYYYMMDD') AS IPT_YMD      -- 등록일
		    , CASE
		          WHEN NVL(T1.SIT_CD, '*') = '*'
		            OR NVL(T2.DEPT_CD, '*') != '*'
		            OR NVL(T5.REG_NO, -1) != -1
		          THEN '1'
		          ELSE '0'
		      END AS VIEW_YN                                  -- 보기권한
		    , CASE
		          WHEN NVL(T1.SIT_CD, '*') = '*'
		            OR NVL(T2.DEPT_CD, '*') != '*'
		            OR NVL(T5.REG_NO, -1) != -1
		          THEN 0
		          ELSE T6.APL_SEQ
		      END AS APL_SEQ                                  -- 열람신청번호
		    , T6.APL_STATS
		    , T2.DEPT_CD                                      -- 부서코드(현장코드)-권한여부
		    , T9.VIEW_CNT
		    , CASE
		          WHEN NVL(T1.SIT_CD, '*') = '*'
		            OR NVL(T2.DEPT_CD, '*') != '*'
		          THEN '열람가능'
		          WHEN NVL(T5.READ_STR_DD, '*') = '*'
		          THEN ''
		          ELSE NVL(T5.VIEW_STATS, T11.CD_NM)
		      END AS VIEW_STATS
		    , CASE
		          WHEN NVL(T5.READ_STR_DD, '*') = '*'
		          THEN ''
		          ELSE TO_CHAR(TO_DATE(T5.READ_STR_DD, 'YYYYMMDD'), 'YYYY-MM-DD')
		               || '~' ||
		               TO_CHAR(TO_DATE(T5.READ_END_DD, 'YYYYMMDD'), 'YYYY-MM-DD')
		      END AS VIEW_TERM
		    , p_WRK_MNU AS MNU_CD
		    , T1.DATA_DIV AS DATA_DIV_1                       -- 자료구분 - CHAIN 연결 SELECT BOX로 별도 추가.
		    , T1.DATA_SUB_DIV AS DATA_DIV_2                   -- 자료구분2
		    , T1.DATA_SUB_DIV2 AS DATA_DIV_3                  -- 자료구분3
		    , CASE
		          WHEN p_ADM_YN = '1' OR p_WRK_ID = T1.IPT_ID
		          THEN '1'
		          ELSE '0'
		      END AS EDT_YN                                   -- 수정권한여부. 일단 전사 권한은 무조건 수정 가능.
		    , T12.USR_NM AS WRTR_NM
		FROM TQHA_DRM T1
		LEFT JOIN TABLE(
		    FCOZ_USR_DEPT(
		          p_WRK_MNU
		        , p_WRK_ID
		        , p_WRK_CORP
		        , p_WRK_DEPT
		    )
		) T2
		    ON T1.SIT_CD = T2.DEPT_CD
		LEFT JOIN (
		    SELECT
		          ST4.REG_NO
		        , MAX(ST3.APL_SEQ) AS APL_SEQ
		        , MAX(ST3.READ_STR_DD) KEEP (DENSE_RANK LAST ORDER BY ST3.APL_SEQ) AS READ_STR_DD
		        , MAX(ST3.READ_END_DD) KEEP (DENSE_RANK LAST ORDER BY ST3.APL_SEQ) AS READ_END_DD
		        , '열람가능' AS VIEW_STATS
		    FROM TQHA_VIEW_REQ ST3
		    JOIN TQHA_VIEW_REQ_LST ST4
		        ON ST3.APL_SEQ = ST4.APL_SEQ
		    WHERE ST3.READ_STR_DD <= TO_CHAR(SYSDATE, 'YYYYMMDD')
		      AND ST3.READ_END_DD >= TO_CHAR(SYSDATE, 'YYYYMMDD')
		      AND ST3.APL_STATS = '003'                       -- 승인
		      AND ST3.REQ_USR_ID = p_WRK_ID
		    GROUP BY ST4.REG_NO
		) T5
		    ON T1.REG_NO = T5.REG_NO
		-- T5와 T6 차이는 일자를 포함하느냐의 차이로 별개로 구성. 아래는 열람기간에 상관없고, 승인되지 않은 건도 조회.
		LEFT JOIN (
		    SELECT
		          ST6.REG_NO
		        , MAX(ST5.APL_SEQ) AS APL_SEQ
		        , MAX(ST5.APL_STATS) KEEP (DENSE_RANK LAST ORDER BY ST5.APL_SEQ) AS APL_STATS
		    FROM TQHA_VIEW_REQ ST5
		    JOIN TQHA_VIEW_REQ_LST ST6
		        ON ST5.APL_SEQ = ST6.APL_SEQ
		    WHERE 1 = 1
		      AND ST5.REQ_USR_ID = p_WRK_ID
		    GROUP BY ST6.REG_NO
		) T6
		    ON T1.REG_NO = T6.REG_NO
		LEFT JOIN TCOA_COMCODE T7
		    ON T1.DATA_DIV = T7.COM_CD
		   AND T7.HRNK_CD = 'QS060'                           -- 자료구분
		LEFT JOIN TCOA_COMCODE T8
		    ON T1.DATA_SUB_DIV = T8.COM_CD
		   AND T8.HRNK_CD = T1.DATA_DIV
		LEFT JOIN TCOA_COMCODE T13
		    ON T1.DATA_SUB_DIV2 = T13.COM_CD
		   AND T13.HRNK_CD = T1.DATA_SUB_DIV
		LEFT JOIN (
		    SELECT
		          REG_NO
		        , REG_DGR
		        , COUNT(1) AS VIEW_CNT
		    FROM TQHA_VIEW_HIS T1
		    GROUP BY REG_NO, REG_DGR
		) T9
		    ON T1.REG_NO  = T9.REG_NO
		   AND T1.REG_DGR = T9.REG_DGR
		LEFT JOIN TCMZ_SIT T10
		    ON T1.SIT_CD = T10.SIT_CD
		LEFT JOIN TCOA_COMCODE T11
		    ON T6.APL_STATS = T11.COM_CD
		   AND T11.HRNK_CD  = 'QS061'
		LEFT JOIN TCOZ_USR_INFO T12
		    ON T1.IPT_ID = T12.USR_ID
		WHERE T1.FNL_YN = '1'
		  AND (
		        NVL(T1.SIT_CD, '*') = '*'
		        OR (
		            NVL(p_SEARCH_OTHER_SIT_INC, '0') = '1'
		            OR (
		                NVL(p_SIT_CD, '*') = '*'
		                OR T1.SIT_CD = p_SIT_CD
		            )
		        )
		      )
		  AND EXISTS (
		      SELECT
		            ST1.REG_NO
		          , ST1.DATA_NM || ST1.TAG || ST2.ATFL_ORI_NM || ST3.USR_NM
		      FROM TQHA_DRM ST1
		      LEFT JOIN TCOZ_ATFL ST2
		          ON ST1.ATFL_GRP = ST2.ATFL_GRP
		      LEFT JOIN TCOZ_USR_INFO ST3
		          ON ST1.IPT_ID = ST3.USR_ID
		      WHERE ST1.FNL_YN = '1'
		        AND ST1.DATA_NM || ST1.TAG || ST2.ATFL_ORI_NM || ST3.USR_NM
		            LIKE '%' || p_SEARCH_TEXT || '%'
		        AND T1.REG_NO = ST1.REG_NO
		  )
		  AND (
		        NVL(p_SEARCH_IPT_YM_FR, '*') = '*'
		        OR T1.IPT_DTM >= TO_DATE(p_SEARCH_IPT_YM_FR, 'YYYYMMDD')
		      )
		  AND (
		        NVL(p_SEARCH_IPT_YM_TO, '*') = '*'
		        OR T1.IPT_DTM < TO_DATE(p_SEARCH_IPT_YM_TO, 'YYYYMMDD') + 1
		      )
		  AND (
		        NVL(p_SEARCH_DATA_DIV, '*') = '*'
		        OR T1.DATA_DIV = p_SEARCH_DATA_DIV
		      )
		ORDER BY T1.IPT_DTM DESC
        ;

    --------------------------------------------------------------------------------------
    -- FORM 조회
    ELSIF (p_WRK_TP = 'Q1') THEN

        OPEN RTN_CURSOR FOR
        SELECT T1.REG_NO                --등록번호
             , T1.REG_DGR
             , T1.DATA_DIV              --자료구분
             , T1.DATA_SUB_DIV
             , T1.DATA_SUB_DIV2
             , T1.DATA_NM               --자료명
             , T1.DATA_DESC             --자료설명
             , T1.BLT_MAIL              --메일알림여부
             , T1.BLT_SMS               --SMS알림여부
             , T1.ATFL_GRP              --첨부파일그룹
             , T1.SIT_CD                --현장코드
             , T1.SIT_CD    AS SIT_CD2  --현장코드
             , T1.FNL_YN
             , T1.TAG
             , T1.IPT_ID                --입력자
             , T1.IPT_DTM               --입력일시
             , T1.IPT_IP                --입력IP
             , T1.UPD_ID                --수정자
             , T1.UPD_DTM               --수정일시
             , T1.UPD_IP                --수정IP
             , TO_CHAR(T1.IPT_DTM, 'YYYY-MM-DD')    AS REG_DD
             , TO_CHAR(T2.VIEW_CNT, 'FM9,990')      AS VIEW_CNT
             , T3.USR_NM                            AS WRTR_NM
             , T1.DATA_DIV                          AS DATA_DIV_1   -- 자료구분 - CHAIN 연결 SELECT BOX로 별도 추가.
             , T1.DATA_SUB_DIV                      AS DATA_DIV_2   -- 자료구분2
             , T1.DATA_SUB_DIV2                     AS DATA_DIV_3   -- 자료구분3
             , T4.SIT_NM                            AS SIT_NM
             , NVL(T4.SIT_NM, '전사공통')               AS SIT_NM2
--             , T4.SIT_NM                            AS SIT_NM3
             , CASE WHEN p_ADM_YN = '1' OR p_WRK_ID = T1.IPT_ID THEN '1' ELSE '0' END AS EDT_YN    -- 수정권한여부.  일단 전사 권한은 무조건 수정 가능.
             , p_ADM_YN                             AS ADM_YN
          FROM TQHA_DRM T1
          LEFT JOIN (SELECT REG_NO
                          , REG_DGR
                          , COUNT(1)    AS VIEW_CNT
                       FROM TQHA_VIEW_HIS T1
                      GROUP BY REG_NO, REG_DGR
                    )               T2 ON T1.REG_NO     = T2.REG_NO
                                      AND T1.REG_DGR    = T2.REG_DGR
          LEFT JOIN TCOZ_USR_INFO   T3 ON T1.IPT_ID     = T3.USR_ID
          LEFT JOIN TCMZ_SIT        T4 ON T1.SIT_CD     = T4.SIT_CD
         WHERE T1.REG_NO = p_REG_NO
           AND T1.REG_DGR = p_REG_DGR
        ;

    --------------------------------------------------------------------------------------
    -- TREE 조회
    ELSIF (p_WRK_TP = 'Q2') THEN

        PQHA_DRM_Q('Q'                      -- p_WRK_TP
                 , p_WRK_ID                 -- 입력자ID
                 , p_WRK_CORP               -- 법인
                 , p_WRK_DEPT               -- 부서
                 , p_WRK_MNU                -- 메뉴코드
                 , p_SIT_CD                 -- 현장코드
                 , p_SEARCH_TEXT            -- 검색어
                 , p_SEARCH_IPT_YM_FR       -- 조회기간 ST
                 , p_SEARCH_IPT_YM_TO       -- 조회기간 ED
                 , p_SEARCH_DATA_DIV        -- 자료구분
                 , p_SEARCH_OTHER_SIT_INC   -- 타현장 자료
                 , p_REG_NO                 -- 등록번호
                 , p_REG_DGR                -- 등록차수
                 , p_ADM_YN                 -- 자료실관리자 여부
                 , v_CURSOR 
                 );
        LOOP
            FETCH v_CURSOR INTO 
                  v_REG_NO
                , v_REG_DGR
                , v_DATA_DIV
                , v_DATA_SUB_DIV
                , v_DATA_SUB_DIV2
                , v_DATA_DIV_NM
                , v_DATA_SUB_DIV_NM
                , v_DATA_SUB_DIV2_NM
                , v_DATA_NM
                , v_DATA_DESC
                , v_BLT_MAIL
                , v_BLT_SMS
                , v_ATFL_GRP
                , v_SIT_CD
                , v_SIT_NM
                , v_FNL_YN
                , v_TAG
                , v_IPT_ID
                , v_IPT_DTM
                , v_IPT_YMD
                , v_VIEW_YN
                , v_APL_SEQ
                , v_APL_STATS
                , v_DEPT_CD
                , v_VIEW_CNT
                , v_VIEW_STATS
                , v_VIEW_TERM
                , v_MNU_CD
                , v_DATA_DIV_1
                , v_DATA_DIV_2
                , v_DATA_DIV_3
                , v_EDT_YN
                , v_WRTR_NM 
                ; 
            EXIT WHEN v_CURSOR%NOTFOUND;

            v_LIST.EXTEND;
            v_LIST(v_LIST.LAST) := OQSA_DRM_INFO(
                  v_REG_NO
                , v_REG_DGR
                , v_DATA_DIV
                , v_DATA_SUB_DIV
                , v_DATA_SUB_DIV2
                , v_DATA_DIV_NM
                , v_DATA_SUB_DIV_NM
                , v_DATA_SUB_DIV2_NM
                , v_DATA_NM
                , v_DATA_DESC
                , v_BLT_MAIL
                , v_BLT_SMS
                , v_ATFL_GRP
                , v_SIT_CD
                , v_SIT_NM
                , v_FNL_YN
                , v_TAG
                , v_IPT_ID
                , v_IPT_DTM
                , v_IPT_YMD
                , v_VIEW_YN
                , v_APL_SEQ
                , v_APL_STATS
                , v_DEPT_CD
                , v_VIEW_CNT
                , v_VIEW_STATS
                , v_VIEW_TERM
                , v_MNU_CD
                , v_DATA_DIV_1
                , v_DATA_DIV_2
                , v_DATA_DIV_3
                , v_EDT_YN
                , v_WRTR_NM
            );
        END LOOP; 
        CLOSE v_CURSOR;

--        FETCH v_CURSOR BULK COLLECT INTO v_LIST;
--        CLOSE v_CURSOR;
--        
--        OPEN RTN_CURSOR FOR
--        SELECT * 
--          FROM TABLE(v_LIST)
--        ;  

        OPEN RTN_CURSOR FOR
        WITH WT1
            AS (SELECT * 
                  FROM TABLE(v_LIST)
               )
        SELECT LEVEL AS "Level"
             , T1.HRNK_CD
             , T1.COM_CD
             , T1.CD_NM
             , T1.SRT_SO
             , T1.DATA_YN
             , T1.REG_NO
             , T1.REG_DGR
             , T1.DATA_DESC
             , T1.VIEW_CNT
             , T1.VIEW_STATS
             , T1.VIEW_TERM
             , T1.VIEW_YN
             , T1.APL_SEQ
             , T1.SIT_NM
             , T1.IPT_YMD
             , T1.WRTR_NM
          FROM (
                SELECT A.HRNK_CD
                     , A.COM_CD
                     , A.CD_NM
                     , A.SRT_SO
                     , NULL         AS REG_NO
                     , NULL         AS REG_DGR
                     , TO_CLOB('')  AS DATA_DESC
                     , ''           AS VIEW_CNT
                     , ''           AS VIEW_STATS
                     , ''           AS VIEW_TERM
                     , '0'          AS DATA_YN
                     , ''           AS VIEW_YN
                     , NULL         AS APL_SEQ
                     , ''           AS SIT_NM
                     , ''           AS IPT_YMD
                     , ''           AS WRTR_NM
                  FROM TCOA_COMCODE A
                 WHERE A.USE_YN = '1'
                   AND A.COM_CD IN (
                                   SELECT X.COM_CD
                                     FROM TCOA_COMCODE X
                                    START WITH X.COM_CD IN (SELECT DISTINCT DATA_SUB_DIV2 FROM WT1)
                                   CONNECT BY PRIOR X.HRNK_CD = X.COM_CD  
                   )
                UNION ALL
                SELECT DATA_SUB_DIV2    AS HRNK_CD
                     , TO_CHAR(REG_NO)  AS COM_CD
                     , DATA_NM          AS CD_NM
                     , REG_NO           AS SRT_SO
                     , REG_NO
                     , REG_DGR
                     , DATA_DESC                        AS DATA_DESC
                     , TO_CHAR(VIEW_CNT, 'FM9,999,999') AS VIEW_CNT
                     , VIEW_STATS
                     , VIEW_TERM
                     , '1'                              AS DATA_YN
                     , VIEW_YN
                     , APL_SEQ
                     , SIT_NM
                     , IPT_YMD
                     , WRTR_NM
                  FROM WT1
               ) T1
         START WITH T1.HRNK_CD = 'QS060'
        CONNECT BY PRIOR T1.COM_CD = T1.HRNK_CD
         ORDER SIBLINGS BY T1.SRT_SO
        ;

    --------------------------------------------------------------------------------------
    -- 관리자 권한 확인
    ELSIF (p_WRK_TP = 'Q3') THEN

        OPEN RTN_CURSOR FOR
        SELECT NVL(MAX('1'), '0')   AS ADM_YN
          FROM TCOA_COMCODE
         WHERE HRNK_CD = 'QS062'
           AND COM_CD = p_WRK_ID
        ;


    --------------------------------------------------------------------------------------
    -- 버전 이력 조회
    ELSIF (p_WRK_TP = 'Q4') THEN

        OPEN RTN_CURSOR FOR
        SELECT T1.REG_NO                --등록번호
             , T1.REG_DGR
             , T1.DATA_DIV              --자료구분
             , T1.DATA_SUB_DIV
             , T1.DATA_SUB_DIV2
             , T8.CD_NM             AS DATA_SUB_DIV_NM
             , T14.CD_NM            AS DATA_SUB_DIV2_NM
             , T1.DATA_NM               --자료명
             , T1.DATA_DESC             --자료설명
             , T1.BLT_MAIL              --메일알림여부
             , T1.BLT_SMS               --SMS알림여부
             , T1.ATFL_GRP              --첨부파일그룹
             , T1.SIT_CD                --현장코드
             , T1.SIT_CD            AS SIT_CD2      --현장코드
             , T1.FNL_YN
             , T1.TAG
             , T1.IPT_ID                --입력자
             , T1.IPT_DTM               --입력일시
             , T1.IPT_IP                --입력IP
             , T1.UPD_ID                --수정자
             , T1.UPD_DTM               --수정일시
             , T1.UPD_IP                --수정IP
             , TO_CHAR(T1.IPT_DTM, 'YYYY-MM-DD')    AS REG_DD
             , T3.USR_NM                            AS WRTR_NM
             , T1.DATA_DIV                          AS DATA_DIV_1   -- 자료구분 - CHAIN 연결 SELECT BOX로 별도 추가.
             , T1.DATA_SUB_DIV                      AS DATA_DIV_2   -- 자료구분2
             , T1.DATA_SUB_DIV2                     AS DATA_DIV_3   -- 자료구분3
             , T4.SIT_NM                            AS SIT_NM
             , NVL(T4.SIT_NM, '전사공통')               AS SIT_NM2
--             , T4.SIT_NM                            AS SIT_NM3
             , CASE WHEN p_ADM_YN = '1' OR p_WRK_ID = T1.IPT_ID THEN '1' ELSE '0' END AS EDT_YN    -- 수정권한여부.  일단 전사 권한은 무조건 수정 가능.
             , T9.VIEW_CNT
          FROM TQHA_DRM T1
          LEFT JOIN TCOZ_USR_INFO   T3 ON T1.IPT_ID         = T3.USR_ID
          LEFT JOIN TCMZ_SIT        T4 ON T1.SIT_CD         = T4.SIT_CD
          LEFT JOIN TCOA_COMCODE    T8 ON T1.DATA_SUB_DIV   = T8.COM_CD
                                      AND T8.HRNK_CD        = T1.DATA_DIV
          LEFT JOIN TCOA_COMCODE    T14 ON T1.DATA_SUB_DIV2 = T14.COM_CD
                                       AND T14.HRNK_CD      = T1.DATA_SUB_DIV
          LEFT JOIN (   SELECT REG_NO
                             , REG_DGR
                             , COUNT(1)    AS VIEW_CNT
                          FROM TQHA_VIEW_HIS T1
                         GROUP BY REG_NO, REG_DGR
                    )               T9 ON T1.REG_NO         = T9.REG_NO
                                      AND T1.REG_DGR        = T9.REG_DGR
         WHERE T1.REG_NO    = p_REG_NO
         ORDER 
            BY T1.REG_DGR DESC
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHA_EDU_B
DROP PROCEDURE "PQHA_EDU_B";
CREATE PROCEDURE "PQHA_EDU_B" ( -- 교육일지 전일복사 (교육구분에 따른)
    p_WRK_TP                VARCHAR2 :='U'                              -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID                VARCHAR2                                    -- 사용자 ID
,   p_WRK_IP                VARCHAR2                                    -- 사용자 IP
,   p_SIT_CD                TQHA_EDU.SIT_CD             %TYPE           -- 현장코드
,   p_EDU_SEQ               TQHA_EDU.EDU_SEQ            %TYPE           -- 교육순번
,   p_EDU_CD                TQHA_EDU.EDU_CD             %TYPE           -- 교육코드
,   p_DEEDU_CD              TQHA_EDU.DEEDU_CD           %TYPE           -- 세부교육코드
,   p_EDU_DT                TQHA_EDU.EDU_DT             %TYPE           -- 교육일자
,   p_MOBILE_REG_DIV        VARCHAR2                                    -- 모바일등록여부(0:모바일등록x, 1:모바일등록o)
,   p_RTN_EDU_SEQ           OUT VARCHAR2                                -- 리턴변수(교육순번)
)
IS
    /**************************************************************************************************************************
      Purpose : 교육일지 전일복사 

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2022/02/21 16:00:00                         최초생성
      1.1     2024/03/05 10:13:00 정우성                   교육코드/세부교육코드/특별교육내용 추가

    **************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_EDU_SEQ           TQHA_EDU.EDU_SEQ%TYPE ;        -- 순번 변수 선언
    v_BEF_EDU_SEQ       TQHA_EDU.EDU_SEQ%TYPE;         -- 전일 교육순번 변수

    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    ---------------------------------------------------------------------
    -- 결재상태 체크
    SELECT MAX(T2.APRV_STATS)
         , MAX(T3.CD_NM )
      INTO v_APRV_STATS
         , v_APRV_STATS_NM
      FROM TQHA_EDU             T1
      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
                                  AND T1.APRV_NO    = T2.APRV_NO
      LEFT JOIN TCOA_COMCODE    T3 ON T2.APRV_STATS = T3.COM_CD
                                  AND T3.HRNK_CD    = 'QS031'
     WHERE T1.SIT_CD    = p_SIT_CD
       AND T1.EDU_SEQ   = p_EDU_SEQ
    ;

    IF v_APRV_STATS IN ('2', '4') THEN
        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------
    -- 전일 조회
    SELECT MAX(EDU_SEQ) AS EDU_SEQ
      INTO v_BEF_EDU_SEQ
      FROM TQHA_EDU
     WHERE SIT_CD       = p_SIT_CD
      -- 2024/03/05 교육코드/세부교육코드 추가
       AND EDU_CD       = p_EDU_CD
       AND DEEDU_CD     = p_DEEDU_CD
      ------------------------------------------
       --AND EDU_DT < p_EDU_DT
     ;

    IF (v_BEF_EDU_SEQ IS NULL) THEN
        ERR_MSG := '복사할 데이터가 없습니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_EDU_SEQ IS NULL) THEN
        -- 교육순번 생성
        SELECT NVL((MAX(EDU_SEQ)+1), 1)
          INTO v_EDU_SEQ
          FROM TQHA_EDU
         WHERE SIT_CD = p_SIT_CD
         ;
    
        -- 교육순번 생성 완료
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP = 'U') THEN

        IF (p_MOBILE_REG_DIV = '1') THEN      -- 모바일에 등록한 항목은 업데이트 안함

            UPDATE TQHA_EDU
               SET ( 
                       EDU_CD                -- 교육코드
					 , DEEDU_CD                -- 교육세부코드
					 , COP_VNDR_NM                -- 협력업체명칭
					 , EDU_DT                -- 교육시작일
					 , EDU_TIME                -- 교육시간
					 , REL_LNR1                -- 관련법규1
					 , REL_LNR2                -- 관련법규2
					 , EDU_OBJ_MAN                -- 교육대상인원
					 , EDU_IMPL_MAN                -- 교육실시인원
					 , USE_TCMT                -- 교육방법
					 , EDU_IMPL                -- 교육강사
					 , EDU_PLC                -- 교육장소
					 , EDU_MTD                -- 교육대상
					 , EDU_CTS                -- 공통교육내용
					 , EDU_CTS2                -- 개별교육내용
					 , EDU_CTS3                -- 기타교육내용
					 , MSDS_RMKS                -- MSDS비고
                   ----------------------------------------------------------------
                   , UPD_ID       -- 수정ID
                   , UPD_DTM      -- 수정일시
                   , UPD_IP       -- 수정IP
                   ) = ( SELECT 
                                   EDU_CD                -- 교육코드
								 , DEEDU_CD                -- 교육세부코드
								 , COP_VNDR_NM                -- 협력업체명칭
								 , EDU_DT                -- 교육시작일
								 , EDU_TIME                -- 교육시간
								 , REL_LNR1                -- 관련법규1
								 , REL_LNR2                -- 관련법규2
								 , EDU_OBJ_MAN                -- 교육대상인원
								 , EDU_IMPL_MAN                -- 교육실시인원
								 , USE_TCMT                -- 교육방법
								 , EDU_IMPL                -- 교육강사
								 , EDU_PLC                -- 교육장소
								 , EDU_MTD                -- 교육대상
								 , EDU_CTS                -- 공통교육내용
								 , EDU_CTS2                -- 개별교육내용
								 , EDU_CTS3                -- 기타교육내용
								 , MSDS_RMKS                -- MSDS비고
                              ----------------------------------------------------------------
                              , p_WRK_ID     -- 수정ID
                              , SYSDATE()    -- 수정일시
                              , p_WRK_IP     -- 수정IP
                           FROM TQHA_EDU
                          WHERE SIT_CD = p_SIT_CD
                            AND EDU_SEQ = v_BEF_EDU_SEQ )
             WHERE SIT_CD = p_SIT_CD
               AND EDU_SEQ = p_EDU_SEQ;

             v_EDU_SEQ := p_EDU_SEQ;

        ELSIF (p_MOBILE_REG_DIV = '0') THEN   -- 모바일에 등록한 항목도 업데이트 처리

            UPDATE TQHA_EDU
               SET 
                 ( 
				   EDU_CD                -- 교육코드
				 , DEEDU_CD                -- 교육세부코드
				 , COP_VNDR_NM                -- 협력업체명칭
				 , EDU_DT                -- 교육시작일
				 , EDU_TIME                -- 교육시간
				 , REL_LNR1                -- 관련법규1
				 , REL_LNR2                -- 관련법규2
				 , EDU_OBJ_MAN                -- 교육대상인원
				 , EDU_IMPL_MAN                -- 교육실시인원
				 , USE_TCMT                -- 교육방법
				 , EDU_IMPL                -- 교육강사
				 , EDU_PLC                -- 교육장소
				 , EDU_MTD                -- 교육대상
				 , EDU_CTS                -- 공통교육내용
				 , EDU_CTS2                -- 개별교육내용
				 , EDU_CTS3                -- 기타교육내용
				 , MSDS_RMKS                -- MSDS비고
                 ----------------------------------------------------------------
                 , UPD_ID               -- 수정ID
                 , UPD_DTM              -- 수정일시
                 , UPD_IP               -- 수정IP
                 ) 
                 = 
                 ( SELECT 
                          EDU_CD                -- 교육코드
						 , DEEDU_CD                -- 교육세부코드
						 , COP_VNDR_NM                -- 협력업체명칭
						 , EDU_DT                -- 교육시작일
						 , EDU_TIME                -- 교육시간
						 , REL_LNR1                -- 관련법규1
						 , REL_LNR2                -- 관련법규2
						 , EDU_OBJ_MAN                -- 교육대상인원
						 , EDU_IMPL_MAN                -- 교육실시인원
						 , USE_TCMT                -- 교육방법
						 , EDU_IMPL                -- 교육강사
						 , EDU_PLC                -- 교육장소
						 , EDU_MTD                -- 교육대상
						 , EDU_CTS                -- 공통교육내용
						 , EDU_CTS2                -- 개별교육내용
						 , EDU_CTS3                -- 기타교육내용
						 , MSDS_RMKS                -- MSDS비고
                        ----------------------------------------------------------------
                        , p_WRK_ID          -- 수정ID
                        , SYSDATE()         -- 수정일시
                        , p_WRK_IP          -- 수정IP
                     FROM TQHA_EDU
                    WHERE SIT_CD = p_SIT_CD
                      AND EDU_SEQ = v_BEF_EDU_SEQ 
                 )
             WHERE SIT_CD       = p_SIT_CD
               AND EDU_SEQ      = p_EDU_SEQ
            ;

            v_EDU_SEQ := p_EDU_SEQ;

        END IF;

    ELSIF (p_WRK_TP = 'I') THEN

        INSERT 
          INTO TQHA_EDU
             ( 
               SIT_CD                -- 현장코드
			 , EDU_SEQ                -- 교육순번
			 , EDU_CD                -- 교육코드
			 , DEEDU_CD                -- 교육세부코드
			 , COP_VNDR_NM                -- 협력업체명칭
			 , EDU_DT                -- 교육시작일
			 , EDU_TIME                -- 교육시간
			 , REL_LNR1                -- 관련법규1
			 , REL_LNR2                -- 관련법규2
			 , EDU_OBJ_MAN                -- 교육대상인원
			 , EDU_IMPL_MAN                -- 교육실시인원
			 , USE_TCMT                -- 교육방법
			 , EDU_IMPL                -- 교육강사
			 , EDU_PLC                -- 교육장소
			 , EDU_MTD                -- 교육대상
			 , EDU_CTS                -- 공통교육내용
			 , EDU_CTS2                -- 개별교육내용
			 , EDU_CTS3                -- 기타교육내용
			 , MSDS_RMKS                -- MSDS비고
             ----------------------------------------------------------------
             , IPT_ID                   -- 입력ID
             , IPT_DTM                  -- 입력일시
             , IPT_IP                   -- 입력IP
             , UPD_ID                   -- 수정ID
             , UPD_DTM                  -- 수정일시
             , UPD_IP                   -- 수정IP
             )
        SELECT SIT_CD                   -- 현장코드
             , v_EDU_SEQ                -- 교육순번
             , EDU_CD                -- 교육코드
			 , DEEDU_CD                -- 교육세부코드
			 , COP_VNDR_NM                -- 협력업체명칭
			 , EDU_DT                -- 교육시작일
			 , EDU_TIME                -- 교육시간
			 , REL_LNR1                -- 관련법규1
			 , REL_LNR2                -- 관련법규2
			 , EDU_OBJ_MAN                -- 교육대상인원
			 , EDU_IMPL_MAN                -- 교육실시인원
			 , USE_TCMT                -- 교육방법
			 , EDU_IMPL                -- 교육강사
			 , EDU_PLC                -- 교육장소
			 , EDU_MTD                -- 교육대상
			 , EDU_CTS                -- 공통교육내용
			 , EDU_CTS2                -- 개별교육내용
			 , EDU_CTS3                -- 기타교육내용
			 , MSDS_RMKS                -- MSDS비고
             , p_WRK_ID                 -- 입력ID
             , SYSDATE()                -- 입력일시
             , p_WRK_IP                 -- 입력IP
             , p_WRK_ID                 -- 수정ID
             , SYSDATE()                -- 수정일시
             , p_WRK_IP                 -- 수정IP
          FROM TQHA_EDU
         WHERE SIT_CD = p_SIT_CD
           AND EDU_SEQ = v_BEF_EDU_SEQ
        ;
        
        INSERT INTO TQHA_EDU_MSDS
                   ( SIT_CD                  --현장코드
                    ,EDU_SEQ                 --교육순번
                    ,MSDS_SEQ                --MSDS순번
                    ,CHEM_CD                 --대상화학물질
                    ,CHEM_NM                 --대상화학물질명
                    ,HAZ_INFO                --위험성유해성
                    ,HDL_PRECT               --취급주의사항
                    ,PREQ                    --보호구
                    ,FAID_MEAS               --응급조치요령
                    ,GHS_LBL                 --경고표지이해방법
                    ,MSDS_NM                 --제품명
                    ,MNFR_NM                 --제조사명
                    ,IPT_ID                  --입력ID
                    ,IPT_DTM                 --입력일시
                    ,IPT_IP                  --입력IP
                    ,UPD_ID                  --수정ID
                    ,UPD_DTM                 --수정일시
                    ,UPD_IP                  --수정IP
                    )
            SELECT  SIT_CD                 --현장코드
		           ,v_EDU_SEQ                 --교육순번
		           ,MSDS_SEQ               --MSDS순번
		           ,CHEM_CD                 --대상화학물질
		           ,CHEM_NM                 --대상화학물질명
		           ,HAZ_INFO                 --위험성유해성
		           ,HDL_PRECT                 --취급주의사항
		           ,PREQ                 --보호구
		           ,FAID_MEAS                 --응급조치요령
		           ,GHS_LBL                 --경고표지이해방법
		           ,MSDS_NM
				   ,MNFR_NM
		           ,p_WRK_ID                 -- 입력ID
		           ,SYSDATE()                -- 입력일시
		           ,p_WRK_IP                 -- 입력IP
		           ,p_WRK_ID                 -- 수정ID
		           ,SYSDATE()                -- 수정일시
		           ,p_WRK_IP                 -- 수정IP
		      FROM TQHA_EDU_MSDS
		    WHERE SIT_CD = p_SIT_CD                     --현장코드
		      AND EDU_SEQ = v_BEF_EDU_SEQ               --교육순번
		;
    END IF; 

    p_RTN_EDU_SEQ := v_EDU_SEQ;

   ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_EDU_B;
/

-- PQHA_EDU_Q
DROP PROCEDURE "PQHA_EDU_Q";
CREATE PROCEDURE "PQHA_EDU_Q" (
    p_WRK_TP            VARCHAR2 DEFAULT 'Q'        -- FLAG( Q: SELECT )
,   p_SIT_CD            VARCHAR2                    -- 현장코드
,   p_EDU_YM            VARCHAR2                    -- 년월    
--,   p_EDU_DIV           VARCHAR2                    -- 교육구분 
,   p_EDU_SEQ           VARCHAR2                    -- 교육순번
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS 
    /**************************************************************************************************************************
      Purpose :  교육일지 관리 (Q) -> 교육목록 조회, (Q1) -> 교육일지 조회

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2023/11/28 12:46:42                         최초생성 
      1.1      2023/03/04 12:50:00                          교육코드/세부교육코드/공통교육내용/특별교육내용 추가

    **************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;


BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리
    ---------------------------------------------------------------------------------------------------------------------------
    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
        SELECT 
               A.SIT_CD                -- 현장코드
             , A.EDU_SEQ                -- 교육순번
             , A.EDU_CD                -- 교육코드
             , A.DEEDU_CD                -- 교육세부코드
             , A.COP_VNDR_NM                -- 협력업체명칭
             , A.EDU_DT                -- 교육시작일
             , A.EDU_TIME                -- 교육시간
             , A.REL_LNR1                -- 관련법규1
             , A.REL_LNR2                -- 관련법규2
             , A.EDU_OBJ_MAN                -- 교육대상인원
             , A.EDU_IMPL_MAN                -- 교육실시인원
             , A.USE_TCMT                -- 교육방법
             , A.EDU_IMPL                -- 교육강사
             , A.EDU_PLC                -- 교육장소
             , A.EDU_MTD                -- 교육대상
             , A.EDU_CTS                -- 공통교육내용
             , A.EDU_CTS2                -- 개별교육내용
             , A.EDU_CTS3                -- 기타교육내용
             , A.MSDS_RMKS                -- MSDS비고
             , A.PHOTO_GRP1                -- 첨부파일그룹사진1
             , A.PHOTO_DESC_1                -- 사진설명1
             , A.PHOTO_DT_1                -- 사진설명1
             , A.PHOTO_GRP2                -- 첨부파일그룹사진2
             , A.PHOTO_DESC_2                -- 사진설명2
             , A.PHOTO_DT_2                -- 사진일자2
             , A.PHOTO_GRP3                -- 첨부파일그룹사진3
             , A.PHOTO_DESC_3                -- 사진설명3
             , A.PHOTO_DT_3                -- 사진일자3
             , A.ATFL_GRP                -- 첨부파일그룹
             , A.APRV_NO                -- 결재번호
             , C.EDU_NM             --교육코드명
             , D.DEEDU_NM           --세부교육코드명  
             , D.DEEDU_CTS          --세부교육내용
             , B.APRV_STATS         -- 공통코드 QS031
             , E.CD_NM      AS APRV_STATS_NM
          FROM TQHA_EDU             A
          LEFT JOIN TQHA_APRV       B ON A.SIT_CD = B.SIT_CD
                                     AND A.APRV_NO = B.APRV_NO
           -- 2023/03/04     교육코드(명)/세부교육코드(명)/공통교육내용/특별교육내용 추가
          LEFT JOIN TQHA_EDU_CD     C ON C.EDU_CD = A.EDU_CD
          LEFT JOIN TQHA_DEEDU_CD   D ON D.EDU_CD = A.EDU_CD
                                     AND D.DEEDU_CD = A.DEEDU_CD
          LEFT JOIN TCOA_COMCODE    E ON E.COM_CD = B.APRV_STATS
                                     AND E.HRNK_CD = 'QS031'
         WHERE A.SIT_CD = p_SIT_CD
           AND (SUBSTR(A.EDU_DT, 1, 6) = p_EDU_YM OR NVL(p_EDU_YM, '0') = '0')
           --AND (A.EDU_DIV = p_EDU_DIV OR NVL(p_EDU_DIV, '0') = '0')
         ORDER BY A.SIT_CD, A.EDU_DT  DESC, A.EDU_SEQ DESC
        ;

    ELSIF p_WRK_TP = 'Q1' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                -- 현장코드
             , A.EDU_SEQ                -- 교육순번
             , A.EDU_CD                -- 교육코드
             , A.DEEDU_CD                -- 교육세부코드
             , A.COP_VNDR_NM                -- 협력업체명칭
             , A.EDU_DT                -- 교육시작일
             , A.EDU_TIME                -- 교육시간
             , A.REL_LNR1                -- 관련법규1
             , A.REL_LNR2                -- 관련법규2
             , A.EDU_OBJ_MAN                -- 교육대상인원
             , A.EDU_IMPL_MAN                -- 교육실시인원
             , A.USE_TCMT                -- 교육방법
             , A.EDU_IMPL                -- 교육강사
             , A.EDU_PLC                -- 교육장소
             , A.EDU_MTD                -- 교육대상
             , A.EDU_CTS                -- 공통교육내용
             , A.EDU_CTS2                -- 개별교육내용
             , A.EDU_CTS3                -- 기타교육내용
             , A.MSDS_RMKS                -- MSDS비고
             , A.PHOTO_GRP1                -- 첨부파일그룹사진1
             , A.PHOTO_DESC_1                -- 사진설명1
             , A.PHOTO_DT_1                -- 사진설명1
             , A.PHOTO_GRP2                -- 첨부파일그룹사진2
             , A.PHOTO_DESC_2                -- 사진설명2
             , A.PHOTO_DT_2                -- 사진설명1
             , A.PHOTO_GRP3                -- 첨부파일그룹사진3
             , A.PHOTO_DESC_3                -- 사진설명3
             , A.PHOTO_DT_3                -- 사진일자3
             , A.ATFL_GRP                -- 첨부파일그룹
             , A.APRV_NO                -- 결재번호
             , C.EDU_NM            --교육코드명
             , A.DEEDU_CD          --세부교육코드
             , D.DEEDU_NM          --세부교육코드명  
             , D.DEEDU_CTS         --세부교육내용  
             --------------------------------------
             , B.APRV_STATS        -- 결재상태
             , '▶ 결재상태 : ' || NVL(( SELECT CD_NM FROM TCOA_COMCODE WHERE HRNK_CD = 'QS031' AND COM_CD = B.APRV_STATS ), '-') AS APRV_STATS_NM -- 결재상태명
             , (SELECT COUNT(1) FROM TQHA_EDU_MSDS WHERE SIT_CD = A.SIT_CD AND EDU_SEQ = A.EDU_SEQ) AS MSDS_CNT
          FROM TQHA_EDU             A
          LEFT JOIN TQHA_APRV       B ON A.SIT_CD = B.SIT_CD
                                     AND A.APRV_NO = B.APRV_NO
          -- 2023/03/04     교육코드(명)/세부교육코드(명)/공통교육내용/특별교육내용 추가
          LEFT JOIN TQHA_EDU_CD     C ON C.EDU_CD = A.EDU_CD
          LEFT JOIN TQHA_DEEDU_CD   D ON D.EDU_CD = A.EDU_CD
                                     AND D.DEEDU_CD = A.DEEDU_CD
         WHERE A.SIT_CD         = p_SIT_CD
           AND A.EDU_SEQ        = p_EDU_SEQ
           ORDER BY A.SIT_CD, A.EDU_DT DESC, A.EDU_SEQ DESC
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END ;
/

-- PQHA_EDU_S
DROP PROCEDURE "PQHA_EDU_S";
CREATE PROCEDURE "PQHA_EDU_S" (
   					 		 p_WRK_TP  VARCHAR2 :='U'                                     -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
                            ,p_WRK_ID  VARCHAR2                                           -- 사용자 ID 
                            ,p_WRK_IP  VARCHAR2                                           -- 사용자 IP 
                            ,p_SIT_CD TQHA_EDU.SIT_CD%TYPE                                -- 현장코드
                            ,p_EDU_SEQ TQHA_EDU.EDU_SEQ%TYPE                              -- 교육순번
                            ,p_EDU_CD TQHA_EDU.EDU_CD%TYPE                                -- 교육코드
                            ,p_DEEDU_CD TQHA_EDU.DEEDU_CD%TYPE                            -- 교육세부코드
                            ,p_COP_VNDR_NM TQHA_EDU.COP_VNDR_NM%TYPE                      -- 협력업체명칭
                            ,p_EDU_DT TQHA_EDU.EDU_DT%TYPE                                -- 교육일자
                            ,p_EDU_TIME TQHA_EDU.EDU_TIME%TYPE                            -- 교육시간
                            ,p_REL_LNR1 TQHA_EDU.REL_LNR1%TYPE                            -- 관련법규1
                            ,p_REL_LNR2 TQHA_EDU.REL_LNR2%TYPE                            -- 관련법규2
                            ,p_EDU_OBJ_MAN TQHA_EDU.EDU_OBJ_MAN%TYPE                      -- 교육대상인원
                            ,p_EDU_IMPL_MAN TQHA_EDU.EDU_IMPL_MAN%TYPE                    -- 교육실시인원
                            ,p_USE_TCMT TQHA_EDU.USE_TCMT%TYPE                            -- 교육방법
                            ,p_EDU_IMPL TQHA_EDU.EDU_IMPL%TYPE                            -- 교육강사
                            ,p_EDU_PLC TQHA_EDU.EDU_PLC%TYPE                              -- 교육장소
                            ,p_EDU_MTD TQHA_EDU.EDU_MTD%TYPE                              -- 교육대상
                            ,p_EDU_CTS TQHA_EDU.EDU_CTS%TYPE                              -- 공통교육내용
                            ,p_EDU_CTS2 TQHA_EDU.EDU_CTS2%TYPE                            -- 개별교육내용
                            ,p_EDU_CTS3 TQHA_EDU.EDU_CTS3%TYPE                            -- 기타교육내용
                            ,p_MSDS_RMKS TQHA_EDU.MSDS_RMKS%TYPE                          -- MSDS비고
                            ,p_PHOTO_GRP1 TQHA_EDU.PHOTO_GRP1%TYPE                        -- 첨부파일그룹사진1
                            ,p_PHOTO_DESC_1 TQHA_EDU.PHOTO_DESC_1%TYPE                    -- 사진설명1
                            ,p_PHOTO_DT_1 TQHA_EDU.PHOTO_DT_1%TYPE                        -- 사진설명1
                            ,p_PHOTO_GRP2 TQHA_EDU.PHOTO_GRP2%TYPE                        -- 첨부파일그룹사진2
                            ,p_PHOTO_DESC_2 TQHA_EDU.PHOTO_DESC_2%TYPE                    -- 사진설명2
                            ,p_PHOTO_DT_2 TQHA_EDU.PHOTO_DT_2%TYPE                        -- 사진설명1
                            ,p_PHOTO_GRP3 TQHA_EDU.PHOTO_GRP3%TYPE                        -- 첨부파일그룹사진3
                            ,p_PHOTO_DESC_3 TQHA_EDU.PHOTO_DESC_3%TYPE                    -- 사진설명3
                            ,p_PHOTO_DT_3 TQHA_EDU.PHOTO_DT_3%TYPE                        -- 사진일자3
                            ,p_ATFL_GRP TQHA_EDU.ATFL_GRP%TYPE                            -- 첨부파일그룹
                            ,p_APRV_NO TQHA_EDU.APRV_NO%TYPE                             -- 결재번호
							,p_RTN_EDU_SEQ           OUT VARCHAR2                         -- 리턴변수(교육순번)
)
IS
    /**************************************************************************************************************************
      Purpose : 교육일지 저장
 
      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2024/02/20 20:18:08                         최초생성(윤남진)
      1.1     2024/02/28                                  교육코드/세부교육코드 추가, 특별교육내용 추가(정우성)
      1.2       2024/03/21 09:00:00                          개별교육코드(내용) 2,3 추가(정우성)

    **************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_EDU_SEQ           TQHA_EDU.EDU_SEQ%TYPE ;             -- 순번 변수 선언

    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL AND p_WRK_TP <> 'I')  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

--    IF (p_EDU_SEQ IS NULL AND p_WRK_TP <> 'I')  THEN
--        ERR_MSG := '교육순번는(은) 필수 입력사항 입니다.';
--        RAISE USER_EXCEPTION;
--    END IF;

    ---------------------------------------------------------------------
    -- 결재상태 체크
    SELECT MAX(T2.APRV_STATS)
         , MAX(T3.CD_NM )
      INTO v_APRV_STATS
         , v_APRV_STATS_NM
      FROM TQHA_EDU             T1
      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
                                  AND T1.APRV_NO    = T2.APRV_NO
      LEFT JOIN TCOA_COMCODE    T3 ON T2.APRV_STATS = T3.COM_CD
                                  AND T3.HRNK_CD    = 'QS031'
     WHERE T1.SIT_CD    = p_SIT_CD
       AND T1.EDU_SEQ   = p_EDU_SEQ
    ;

    IF v_APRV_STATS IN ('2', '4') THEN
        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN

    	DELETE 
          FROM TQHA_EDU_MSDS
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND EDU_SEQ = p_EDU_SEQ;         --교육순번
           
        DELETE
          FROM TQHA_EDU
         WHERE SIT_CD   = p_SIT_CD      -- 현장코드
           AND EDU_SEQ  = p_EDU_SEQ     -- 교육순번
        ;

        v_EDU_SEQ := p_EDU_SEQ;

    ELSIF (p_WRK_TP ='U') THEN

        UPDATE TQHA_EDU
           SET EDU_CD               = p_EDU_CD                  --교육코드
              ,DEEDU_CD             = p_DEEDU_CD                --교육세부코드
              ,COP_VNDR_NM          = p_COP_VNDR_NM             --협력업체명칭
              ,EDU_DT               = p_EDU_DT                  --교육일자
              ,EDU_TIME             = p_EDU_TIME                --교육시간
              ,REL_LNR1             = p_REL_LNR1                --관련법규1
              ,REL_LNR2             = p_REL_LNR2                --관련법규2
              ,EDU_OBJ_MAN          = p_EDU_OBJ_MAN             --교육대상인원
              ,EDU_IMPL_MAN         = p_EDU_IMPL_MAN            --교육실시인원
              ,USE_TCMT             = p_USE_TCMT                --교육방법
              ,EDU_IMPL             = p_EDU_IMPL                --교육강사
              ,EDU_PLC              = p_EDU_PLC                 --교육장소
              ,EDU_MTD              = p_EDU_MTD                 --교육대상
              ,EDU_CTS              = p_EDU_CTS                 --공통교육내용
              ,EDU_CTS2             = p_EDU_CTS2                --개별교육내용
              ,EDU_CTS3             = p_EDU_CTS3                --기타교육내용
              ,MSDS_RMKS            = p_MSDS_RMKS               --MSDS비고
              ,PHOTO_GRP1           = p_PHOTO_GRP1              --첨부파일그룹사진1
              ,PHOTO_DESC_1         = p_PHOTO_DESC_1            --사진설명1
              ,PHOTO_DT_1           = p_PHOTO_DT_1              --사진설명1
              ,PHOTO_GRP2           = p_PHOTO_GRP2              --첨부파일그룹사진2
              ,PHOTO_DESC_2         = p_PHOTO_DESC_2            --사진설명2
              ,PHOTO_DT_2           = p_PHOTO_DT_2              --사진일자2
              ,PHOTO_GRP3           = p_PHOTO_GRP3              --첨부파일그룹사진3
              ,PHOTO_DESC_3         = p_PHOTO_DESC_3            --사진설명3
              ,PHOTO_DT_3           = p_PHOTO_DT_3              --사진일자3
              ,ATFL_GRP             = p_ATFL_GRP                --첨부파일그룹
              ,APRV_NO              = p_APRV_NO                 --결재번호
              ,UPD_ID               = p_WRK_ID                  --수정ID 
              ,UPD_DTM              = SYSDATE()                 --수정일시
              ,UPD_IP               = p_WRK_IP                  --수정IP
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND EDU_SEQ = p_EDU_SEQ        --교육순번
        ;

        v_EDU_SEQ := p_EDU_SEQ;

    ELSE

           -- 교육순번 생성
        SELECT NVL(MAX(EDU_SEQ),0) + 1
          INTO v_EDU_SEQ
          FROM TQHA_EDU
         WHERE SIT_CD = p_SIT_CD         -- 현장코드
        ;

        INSERT INTO TQHA_EDU
                   ( SIT_CD                  --현장코드
                    ,EDU_SEQ                 --교육순번
                    ,EDU_CD                  --교육코드
                    ,DEEDU_CD                --교육세부코드
                    ,COP_VNDR_NM             --협력업체명칭
                    ,EDU_DT                  --교육일자
                    ,EDU_TIME                --교육시간
                    ,REL_LNR1                --관련법규1
                    ,REL_LNR2                --관련법규2
                    ,EDU_OBJ_MAN             --교육대상인원
                    ,EDU_IMPL_MAN            --교육실시인원
                    ,USE_TCMT                --교육방법
                    ,EDU_IMPL                --교육강사
                    ,EDU_PLC                 --교육장소
                    ,EDU_MTD                 --교육대상
                    ,EDU_CTS                 --공통교육내용
                    ,EDU_CTS2                --개별교육내용
                    ,EDU_CTS3                --기타교육내용
                    ,MSDS_RMKS               --MSDS비고
                    ,PHOTO_GRP1              --첨부파일그룹사진1
                    ,PHOTO_DESC_1            --사진설명1
                    ,PHOTO_DT_1              --사진설명1
                    ,PHOTO_GRP2              --첨부파일그룹사진2
                    ,PHOTO_DESC_2            --사진설명2
                    ,PHOTO_DT_2              --사진설명1
                    ,PHOTO_GRP3              --첨부파일그룹사진3
                    ,PHOTO_DESC_3            --사진설명3
		            ,PHOTO_DT_3              --사진일자3
                    ,ATFL_GRP                --첨부파일그룹
                    ,APRV_NO                 --결재번호
                    ,IPT_ID                  --입력ID
                    ,IPT_DTM                 --입력일시
                    ,IPT_IP                  --입력IP
                    ,UPD_ID                  --수정ID
                    ,UPD_DTM                 --수정일시
                    ,UPD_IP                  --수정IP
                    )
             VALUES (p_SIT_CD                --현장코드
                    ,v_EDU_SEQ               --교육순번
                    ,p_EDU_CD                --교육코드
                    ,p_DEEDU_CD              --교육세부코드
                    ,p_COP_VNDR_NM           --협력업체명칭
                    ,p_EDU_DT                --교육일자
                    ,p_EDU_TIME              --교육시간
                    ,p_REL_LNR1              --관련법규1
                    ,p_REL_LNR2              --관련법규2
                    ,p_EDU_OBJ_MAN           --교육대상인원
                    ,p_EDU_IMPL_MAN          --교육실시인원
                    ,p_USE_TCMT              --교육방법
                    ,p_EDU_IMPL              --교육강사
                    ,p_EDU_PLC               --교육장소
                    ,p_EDU_MTD               --교육대상
                    ,p_EDU_CTS               --공통교육내용
                    ,p_EDU_CTS2              --개별교육내용
                    ,p_EDU_CTS3              --기타교육내용
                    ,p_MSDS_RMKS             --MSDS비고
                    ,p_PHOTO_GRP1            --첨부파일그룹사진1
                    ,p_PHOTO_DESC_1          --사진설명1
                    ,p_PHOTO_DT_1            --사진설명1
                    ,p_PHOTO_GRP2            --첨부파일그룹사진2
                    ,p_PHOTO_DESC_2          --사진설명2
                    ,p_PHOTO_DT_2            --사진설명2
                    ,p_PHOTO_GRP3            --첨부파일그룹사진3
   	                ,p_PHOTO_DESC_3          --사진설명3
	                ,p_PHOTO_DT_3            --사진일자3
                    ,p_ATFL_GRP              --첨부파일그룹
                    ,p_APRV_NO               --결재번호
                    ,p_WRK_ID                --입력ID 
                    ,SYSDATE()               --입력일시
                    ,p_WRK_IP                --입력IP
                    ,p_WRK_ID                --수정ID
                    ,SYSDATE()               --수정일시
                    ,p_WRK_IP)              --수정IP
        ;

    END IF;

    p_RTN_EDU_SEQ := v_EDU_SEQ;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END ;
/

-- PQHA_HLTH_CHKUP_EXCEL_DEL_S
DROP PROCEDURE "PQHA_HLTH_CHKUP_EXCEL_DEL_S";
CREATE PROCEDURE "PQHA_HLTH_CHKUP_EXCEL_DEL_S"
                            (p_WRK_TP  VARCHAR2 :='U'                                     -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
                            ,p_WRK_ID  VARCHAR2                                           -- 사용자 ID 
                            ,p_WRK_IP  VARCHAR2                                           -- 사용자 IP 
                            ,p_SIT_CD TQHA_HLTH_CHKUP_LIST.SIT_CD%TYPE                    -- 현장코드
                            ,p_CHKUP_YY TQHA_HLTH_CHKUP_LIST.CHKUP_YY%TYPE                -- 검진연도
                            ,p_CHKUP_DIV VARCHAR2						                  -- 검진구분
                            )
IS 
    /**************************************************************************************************************************
      Purpose : 

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/06/16 15:43:31                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

	v_SEQ NUMBER;
	v_CUST_CD NUMBER;
BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------

	
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------
    DELETE 
      FROM TQHA_HLTH_CHKUP_LIST
     WHERE SIT_CD = p_SIT_CD           
       AND CHKUP_YY = p_CHKUP_YY      
       AND CHKUP_DIV = (CASE WHEN LENGTH(p_CHKUP_DIV) <= 2 THEN LPAD(p_CHKUP_DIV, 2, '0')
					      ELSE (SELECT COM_CD FROM TCOA_COMCODE WHERE HRNK_CD = 'QS068' AND CD_NM = p_CHKUP_DIV) --검진구분
					 END)
      ;   

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHA_HLTH_CHKUP_EXCEL_S
DROP PROCEDURE "PQHA_HLTH_CHKUP_EXCEL_S";
CREATE PROCEDURE "PQHA_HLTH_CHKUP_EXCEL_S"
                            (p_WRK_TP  VARCHAR2 :='U'                                     -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
                            ,p_WRK_ID  VARCHAR2                                           -- 사용자 ID 
                            ,p_WRK_IP  VARCHAR2                                           -- 사용자 IP 
                            ,p_SIT_CD TQHA_HLTH_CHKUP_LIST.SIT_CD%TYPE                    -- 현장코드
                            ,p_CHKUP_YY TQHA_HLTH_CHKUP_LIST.CHKUP_YY%TYPE                -- 검진연도
                            ,p_CHKUP_SEQ TQHA_HLTH_CHKUP_LIST.CHKUP_SEQ%TYPE              -- 검진순번
                            ,p_CHKUP_DIV VARCHAR2						                  -- 검진구분
                            ,p_CUST_CD TQHA_HLTH_CHKUP_LIST.CUST_CD%TYPE                  -- 업체코드
                            ,p_VNDR_SEQ TQHA_HLTH_CHKUP_LIST.VNDR_SEQ%TYPE                -- 업체순번
                            ,p_DGS_DT TQHA_HLTH_CHKUP_LIST.DGS_DT%TYPE                    -- 진단일자
                            ,p_CHKUP_NM TQHA_HLTH_CHKUP_LIST.CHKUP_NM%TYPE                -- 검진자
                            ,p_CHKUP_AGE TQHA_HLTH_CHKUP_LIST.CHKUP_AGE%TYPE              -- 연령
                            ,p_HRM_ARG TQHA_HLTH_CHKUP_LIST.HRM_ARG%TYPE                  -- 유해인자
                            ,p_HLTH_DIV TQHA_HLTH_CHKUP_LIST.HLTH_DIV%TYPE                -- 건강구분
                            ,p_CHKUP_OPIN TQHA_HLTH_CHKUP_LIST.CHKUP_OPIN%TYPE            -- 검진의견
                            ,p_POST_MNG_OPIN TQHA_HLTH_CHKUP_LIST.POST_MNG_OPIN%TYPE      -- 사후관리의견
                            ,p_DUTY_FIT TQHA_HLTH_CHKUP_LIST.DUTY_FIT%TYPE                -- 업무수행적합도
                            ,p_RSLT_NOTI_YN TQHA_HLTH_CHKUP_LIST.RSLT_NOTI_YN%TYPE        -- 결과통보여부
                            ,p_HLTH_CNS_YN TQHA_HLTH_CHKUP_LIST.HLTH_CNS_YN%TYPE          -- 건강상담여부
                            ,p_PREQ_PAY_YN TQHA_HLTH_CHKUP_LIST.PREQ_PAY_YN%TYPE          -- 보호구지급여부
                            ,p_TRC_EM_YN TQHA_HLTH_CHKUP_LIST.TRC_EM_YN%TYPE              -- 추적검사여부
                            ,p_WRK_TRT_YN TQHA_HLTH_CHKUP_LIST.WRK_TRT_YN%TYPE            -- 근무중치료여부
                            ,p_MOEL_RPT_YN TQHA_HLTH_CHKUP_LIST.MOEL_RPT_YN%TYPE          -- 노동부보고여부
                            ,p_RTCO_YN TQHA_HLTH_CHKUP_LIST.RTCO_YN%TYPE                  -- 퇴수여부
                            ,p_RMKS TQHA_HLTH_CHKUP_LIST.RMKS%TYPE                        -- 비고
                            ,p_ATFL_GRP TQHA_HLTH_CHKUP_LIST.ATFL_GRP%TYPE                -- 첨부파일그룹
                            ,p_PROC_NM TQHA_HLTH_CHKUP_LIST.PROC_NM%TYPE                  -- 공정명
                            ,p_BZMN_NO VARCHAR2  										  -- 사업자번호
                            )
IS 
    /**************************************************************************************************************************
      Purpose : 

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/06/16 15:43:31                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

	v_SEQ NUMBER;
	v_CNT NUMBER;
	v_CUST_CD NUMBER;
BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION; 
    END IF;

    IF (p_CHKUP_YY IS NULL)  THEN
        ERR_MSG := '검진연도는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CHKUP_DIV IS NULL)  THEN
        ERR_MSG := '검진구분는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_BZMN_NO IS NULL)  THEN
        ERR_MSG := '사업자번호는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;
    
    IF (p_CHKUP_NM IS NULL)  THEN
        ERR_MSG := '이름는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;
    
    IF (p_CHKUP_AGE IS NULL)  THEN
        ERR_MSG := '연령는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;
    
    IF (p_HLTH_DIV IS NULL)  THEN
        ERR_MSG := '건강구분는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;
    
    IF (p_CHKUP_DIV IN ('06','07','배치전(수시)','특수(수시)') AND p_DGS_DT IS NULL)  THEN
        ERR_MSG := '수시는 진단일이 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------
       
    -- 거래처번호 가져오기
    SELECT MAX(CUST_CD) INTO v_CUST_CD
--    FROM VQSZ_TRADE 
--    WHERE BZMN_NO = REPLACE(p_BZMN_NO,'-','')
    FROM TCOA_TRADE 
    WHERE BR_NO = REPLACE(p_BZMN_NO,'-','')    
    ;    
    
    IF (v_CUST_CD IS NULL)  THEN
        ERR_MSG := '사업자번호 ' || p_BZMN_NO || ' 의 업체정보가 없습니다.';
        RAISE USER_EXCEPTION;
    END IF;

	SELECT NVL(MAX(CHKUP_SEQ),0) + 1 INTO v_SEQ
      FROM TQHA_HLTH_CHKUP_LIST
     WHERE SIT_CD = p_SIT_CD          --현장코드
       AND CHKUP_YY = p_CHKUP_YY        --검진연도
    ;
	
/*
	-- 수시항목 중복값 찾기
	 SELECT COUNT(1) INTO v_CNT
      FROM TQHA_HLTH_CHKUP_LIST
     WHERE SIT_CD = p_SIT_CD          --현장코드
       AND CHKUP_YY = p_CHKUP_YY      --검진연도
       AND CUST_CD = v_CUST_CD     
       AND CHKUP_NM = p_CHKUP_NM     
       AND CHKUP_AGE = p_CHKUP_AGE
       AND CHKUP_DIV IN ('06','07')
       AND DGS_DT = REPLACE(p_DGS_DT,'-','')
    ;
	
	IF (v_CNT > 0)  THEN
        ERR_MSG := '파일에 중복 데이터가 있어 진행할 수 없습니다.';
        RAISE USER_EXCEPTION;
    END IF;
*/	 
	
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    INSERT INTO TQHA_HLTH_CHKUP_LIST
                   ( SIT_CD                  --현장코드
                    ,CHKUP_YY                --검진연도
                    ,CHKUP_SEQ               --검진순번
                    ,CHKUP_DIV               --검진구분
                    ,CUST_CD                 --업체코드
                    ,VNDR_SEQ                --업체순번
                    ,DGS_DT                  --진단일자
                    ,CHKUP_NM                --검진자
                    ,CHKUP_AGE               --연령
                    ,HRM_ARG                 --유해인자
                    ,HLTH_DIV                --건강구분
                    ,CHKUP_OPIN              --검진의견
                    ,POST_MNG_OPIN           --사후관리의견
                    ,DUTY_FIT                --업무수행적합도
                    ,RSLT_NOTI_YN            --결과통보여부
                    ,HLTH_CNS_YN             --건강상담여부
                    ,PREQ_PAY_YN             --보호구지급여부
                    ,TRC_EM_YN               --추적검사여부
                    ,WRK_TRT_YN              --근무중치료여부
                    ,MOEL_RPT_YN             --노동부보고여부
                    ,RTCO_YN                 --퇴사여부
                    ,RMKS                    --비고
                    ,ATFL_GRP                --첨부파일그룹
                    ,PROC_NM
                    ,IPT_ID                  --입력ID
                    ,IPT_DTM                 --입력일시
                    ,IPT_IP                  --입력IP
                    ,UPD_ID                  --수정ID
                    ,UPD_DTM                 --수정일시
                    ,UPD_IP                  --수정IP
                    )
             VALUES (p_SIT_CD                --현장코드
                    ,p_CHKUP_YY              --검진연도
                    ,v_SEQ		             --검진순번
                    ,CASE WHEN LENGTH(p_CHKUP_DIV) <= 2 THEN LPAD(p_CHKUP_DIV, 2, '0')
					      ELSE (SELECT COM_CD FROM TCOA_COMCODE WHERE HRNK_CD = 'QS068' AND CD_NM = p_CHKUP_DIV) --검진구분
					 END
                    ,v_CUST_CD               --업체코드
                    ,1                       --업체순번
                    ,REPLACE(p_DGS_DT,'-','')  --진단일자
                    ,p_CHKUP_NM              --검진자
                    ,p_CHKUP_AGE             --연령
                    ,p_HRM_ARG               --유해인자
                    ,(SELECT COM_CD FROM TCOA_COMCODE WHERE HRNK_CD = 'QS066' AND CD_NM = p_HLTH_DIV) --건강구분
                    ,p_CHKUP_OPIN            --검진의견
                    ,p_POST_MNG_OPIN         --사후관리의견
                    ,(SELECT COM_CD FROM TCOA_COMCODE WHERE HRNK_CD = 'QS067' AND CD_NM = p_DUTY_FIT) --업무수행적합도
                    ,DECODE(p_RSLT_NOTI_YN,'○','1',p_RSLT_NOTI_YN)          --결과통보여부
                    ,DECODE(p_HLTH_CNS_YN,'○','1',p_HLTH_CNS_YN)           --건강상담여부
                    ,DECODE(p_PREQ_PAY_YN,'○','1',p_PREQ_PAY_YN)           --보호구지급여부
                    ,DECODE(p_TRC_EM_YN,'○','1',p_TRC_EM_YN)             --추적검사여부
                    ,DECODE(p_WRK_TRT_YN,'○','1',p_WRK_TRT_YN)            --근무중치료여부
                    ,DECODE(p_MOEL_RPT_YN,'○','1',p_MOEL_RPT_YN)           --노동부보고여부
                    ,DECODE(p_RTCO_YN,'○','1','퇴사','1',p_RTCO_YN)         --퇴사여부
                    ,p_RMKS                  --비고
                    ,p_ATFL_GRP              --첨부파일그룹
                    ,p_PROC_NM
                    ,p_WRK_ID                --입력ID 
                    ,SYSDATE()               --입력일시
                    ,p_WRK_IP                --입력IP
                    ,p_WRK_ID                --수정ID
                    ,SYSDATE()               --수정일시
                    ,p_WRK_IP);              --수정IP

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHA_HOCHKRPT_CK_Q
DROP PROCEDURE "PQHA_HOCHKRPT_CK_Q";
CREATE PROCEDURE "PQHA_HOCHKRPT_CK_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'         -- FLAG
,   p_SIT_CD            IN VARCHAR2                     -- 현장코드
,   p_CHK_DIV           IN VARCHAR2                     -- 체크구분
,   p_CHK_DGR           IN VARCHAR2                     -- 차수
,   p_HO_CHK_DIV_CD2    IN VARCHAR2                     --
,   p_CHK_CD            IN VARCHAR2                     --
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [본사점검 체크리스트 조회] PROCEDRE (QSE > 재해예방관리 > 본사점검 체크리스트 )

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      XXXX/XX/XX                                 최초생성

    **************************************************************************************************************************/
 
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
        SELECT CK.SIT_CD                -- 현장코드
             , CK.CHK_DIV               -- 공통코드 : QSZ03
             , CK.CHK_DGR                -- 점검일자
             , CK.COM_CD                -- 공통코드 : QSZ03
             , CK.HO_CHK_DIV_CD         -- 공통코드 : QSZ0310
             , B.HO_CHK_DIV_NM
             , CK.HO_CHK_DIV_CD2        -- 본사점검구분코드
             , CK.HO_CHK_ITM_CD         -- 본사점검항목코드
             , C.HO_CHK_ITM_NM         -- 본사점검항목코드
             , C.HO_CHK_ITM_NM2         -- 본사점검항목코드
             , C.MAX_SCORE              -- 배점
             , CK.APRS_CHK
			 , CK.APRS_PNDS
			 , CK.APRS_SCR
			 , CK.APRS_CTS
          FROM TQHA_HOCHKRPT_CK CK
              ,TQHA_CKLST B
              ,TQHA_CKLST_ITM C
         WHERE CK.SIT_CD            = p_SIT_CD
           AND CK.CHK_DIV           = p_CHK_DIV
           AND CK.CHK_DGR           = p_CHK_DGR
           AND CK.HO_CHK_DIV_CD2    = p_HO_CHK_DIV_CD2
            AND (
			       ( SUBSTR(p_CHK_DIV, 1, 7) = 'QS07301' AND CK.COM_CD = p_CHK_DIV ) OR ( SUBSTR(p_CHK_DIV, 1, 7) = 'QS07302' AND CK.HO_CHK_DIV_CD2 = p_CHK_DIV )
		        )
           AND CK.COM_CD            = B.COM_CD
           AND CK.HO_CHK_DIV_CD     = B.HO_CHK_DIV_CD
           AND CK.HO_CHK_DIV_CD2    = B.HO_CHK_DIV_CD2
           AND B.HO_CHK_DIV_USE_YN  = '1'
           AND CK.COM_CD            = C.COM_CD
           AND CK.HO_CHK_DIV_CD     = C.HO_CHK_DIV_CD
           AND CK.HO_CHK_DIV_CD2    = C.HO_CHK_DIV_CD2
           AND CK.HO_CHK_ITM_CD     = C.HO_CHK_ITM_CD
           AND C.HO_CHK_ITM_USE_YN  = '1'
         ORDER BY CK.HO_CHK_DIV_CD ASC, CK.HO_CHK_ITM_CD ASC
        ;

    --------------------------------------------------------------------------------------------
    ELSIF p_WRK_TP = 'Q2' THEN

        OPEN RTN_CURSOR FOR
        SELECT 1 FROM DUAL;

    --------------------------------------------------------------------------------------------
    ELSIF p_WRK_TP = 'Q3' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.COM_CD                       -- 공통코드
             , A.HO_CHK_DIV_CD2               -- 본사점검탭분류
             , A.HO_CHK_DIV_CD                -- 본사점검구분코드
             , A.HO_CHK_DIV_NM                -- 본사점검구분명
             , A.HO_CHK_RMKS                  -- 본사점검비고
             , p_SIT_CD     AS SIT_CD
             , p_CHK_DIV    AS CHK_DIV
             , p_CHK_DGR     AS CHK_DGR
             , DECODE(B.CHK_DGR,NULL,'0','1') AS USE_YN
          FROM TQHA_CKLST A
              ,(SELECT SIT_CD,CHK_DIV,CHK_DGR,COM_CD,HO_CHK_DIV_CD
                  FROM TQHA_HOCHKRPT_CK
                 WHERE SIT_CD           = p_SIT_CD
                   AND CHK_DIV          = p_CHK_DIV
                   AND CHK_DGR           = p_CHK_DGR
                 GROUP BY SIT_CD,CHK_DIV,CHK_DGR,COM_CD,HO_CHK_DIV_CD) B
         WHERE A.COM_CD                 = 'QSZ0360'
           AND A.COM_CD                 = B.COM_CD(+)
           AND A.HO_CHK_DIV_CD          = B.HO_CHK_DIV_CD(+)
           AND A.HO_CHK_DIV_USE_YN      = '1'
         ORDER BY A.HO_CHK_DIV_CD
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_HOCHKRPT_CK_Q;
/

-- PQHA_HOCHKRPT_CK_S
DROP PROCEDURE "PQHA_HOCHKRPT_CK_S";
CREATE PROCEDURE "PQHA_HOCHKRPT_CK_S" (
    p_WRK_TP                VARCHAR2 :='U'                                      -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID                VARCHAR2                                            -- 사용자 ID
,   p_WRK_IP                VARCHAR2                                            -- 사용자 IP
,   p_SIT_CD                TQHA_HOCHKRPT_CK.SIT_CD                 %TYPE       -- 현장코드
,   p_CHK_DIV               TQHA_HOCHKRPT_CK.CHK_DIV                %TYPE       -- 공통코드 : QSZ03
,   p_CHK_DGR               TQHA_HOCHKRPT_CK.CHK_DGR                %TYPE       -- 점검차수
,   p_COM_CD                TQHA_HOCHKRPT_CK.COM_CD                 %TYPE       -- 공통코드 : QSZ03
,   p_HO_CHK_DIV_CD         TQHA_HOCHKRPT_CK.HO_CHK_DIV_CD          %TYPE       -- 공통코드 : QSZ0310
,   p_HO_CHK_DIV_CD2        TQHA_HOCHKRPT_CK.HO_CHK_DIV_CD2         %TYPE       -- 본사점검구분코드
,   p_HO_CHK_ITM_CD         TQHA_HOCHKRPT_CK.HO_CHK_ITM_CD          %TYPE       -- 본사점검항목코드
,   p_APRS_CHK              TQHA_HOCHKRPT_CK.APRS_CHK               %TYPE
,   p_APRS_SCR              TQHA_HOCHKRPT_CK.APRS_SCR               %TYPE
,   p_APRS_CTS              TQHA_HOCHKRPT_CK.APRS_CTS               %TYPE
,   p_USE_YN                VARCHAR2
)

IS
    /**************************************************************************************************************************
      Purpose : [본사점검 체크리스트 저장]

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2019/06/21 16:29:27                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR(200);             -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CHK_DIV IS NULL)  THEN
        ERR_MSG := '공통코드 : QSZ03는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CHK_DGR IS NULL)  THEN
        ERR_MSG := '점검차수는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_COM_CD IS NULL)  THEN
        ERR_MSG := '공통코드 : QSZ03는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_HO_CHK_DIV_CD IS NULL)  THEN
        ERR_MSG := '공통코드 : QSZ0310는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------
    -- 결재상태 체크
--    SELECT MAX(T2.APRV_STATS)
--      INTO v_APRV_STATS
--      FROM TQHA_HOCHKRPT        T1
--      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
--                                  AND T1.APRV_NO1   = T2.APRV_NO
--     WHERE T1.SIT_CD    = p_SIT_CD
--       AND T1.CHK_DIV   = p_CHK_DIV
--       AND T1.CHK_DGR    = p_CHK_DGR
--    ;
--
--    IF v_APRV_STATS IN ('2', '4') THEN
--        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
--        RAISE USER_EXCEPTION;
--    END IF;

   /*
    IF (p_HO_CHK_DIV_CD2 IS NULL)  THEN
        ERR_MSG := '본사점검구분코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_HO_CHK_ITM_CD IS NULL)  THEN
        ERR_MSG := '본사점검항목코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;
    */

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN

        DELETE
          FROM TQHA_HOCHKRPT_CK
         WHERE SIT_CD               = p_SIT_CD              --현장코드
           AND CHK_DIV              = p_CHK_DIV             --공통코드 : QSZ03
           AND CHK_DGR               = p_CHK_DGR              --점검차수
           AND COM_CD               = p_COM_CD              --공통코드 : QSZ03
           AND HO_CHK_DIV_CD        = p_HO_CHK_DIV_CD       --공통코드 : QSZ0310
           AND HO_CHK_DIV_CD2       = p_HO_CHK_DIV_CD2      --본사점검구분코드
           AND HO_CHK_ITM_CD        = p_HO_CHK_ITM_CD       --본사점검항목코드
        ;

    ELSIF (p_WRK_TP ='U') THEN -- 체크리스트 저장 시

        UPDATE TQHA_HOCHKRPT_CK
           SET APRS_CHK      		= p_APRS_CHK
             , APRS_SCR      		= p_APRS_SCR
             , APRS_CTS      		= p_APRS_CTS
             , UPD_ID               = p_WRK_ID              -- 수정ID
             , UPD_DTM              = SYSDATE()             -- 수정일시
             , UPD_IP               = p_WRK_IP              -- 수정IP
         WHERE SIT_CD               = p_SIT_CD              -- 현장코드
           AND CHK_DIV              = p_CHK_DIV             -- 공통코드 : QSZ03
           AND CHK_DGR              = p_CHK_DGR              -- 점검차수
           AND COM_CD               = p_COM_CD              -- 공통코드 : QSZ03
           AND HO_CHK_DIV_CD        = p_HO_CHK_DIV_CD       -- 공통코드 : QSZ0310
           AND HO_CHK_DIV_CD2       = p_HO_CHK_DIV_CD2      -- 본사점검구분코드
           AND HO_CHK_ITM_CD        = p_HO_CHK_ITM_CD       -- 본사점검항목코드
        ;
        
        
        UPDATE TQHA_HOCHKRPT M
		SET -- 1. 전회점수 (이전 차수 데이터가 없으면 0)
		       (M.RVLT_SCR1, M.RVLT_SCR2, M.RVLT_SCR3, M.RVLT_SCR4, M.RVLT_SCR5) = 
		       (
		           SELECT NVL(MAX(PREV.TTM_SCR1), 0)
		                , NVL(MAX(PREV.TTM_SCR2), 0)
		                , NVL(MAX(PREV.TTM_SCR3), 0)
		                , NVL(MAX(PREV.TTM_SCR4), 0)
		                , NVL(MAX(PREV.TTM_SCR5), 0)
		             FROM TQHA_HOCHKRPT PREV
		            WHERE PREV.SIT_CD  = p_SIT_CD
		              AND PREV.CHK_DIV = p_CHK_DIV
		              AND PREV.CHK_DGR = p_CHK_DGR - 1
		       )
		       
		     -- 2. 금회점수 (별칭을 부여해 구조를 단순화)
		     , (M.TTM_SCR1, M.TTM_SCR2, M.TTM_SCR3, M.TTM_SCR4, M.TTM_SCR5) = 
		       (
		             SELECT G.V1, G.V2, G.V3, G.V4
		                  , G.V1 + G.V2 + G.V3 
		             FROM (
		                   SELECT NVL(MAX(CASE WHEN SUBSTR(CK.HO_CHK_DIV_CD2, -1) = '1' THEN CK.SM_SCR END), 0) AS V1
		                        , NVL(MAX(CASE WHEN SUBSTR(CK.HO_CHK_DIV_CD2, -1) = '2' THEN CK.SM_SCR END), 0) AS V2
		                        , NVL(MAX(CASE WHEN SUBSTR(CK.HO_CHK_DIV_CD2, -1) = '3' THEN CK.SM_SCR END), 0) AS V3
		                        , 0 AS V4
		                     FROM (
		                           SELECT HO_CHK_DIV_CD2
		                                , SUM(APRS_SCR) AS SM_SCR
		                             FROM TQHA_HOCHKRPT_CK
		                            WHERE SIT_CD  = p_SIT_CD
		                              AND CHK_DIV = p_CHK_DIV
		                              AND CHK_DGR = p_CHK_DGR
		                            GROUP BY SIT_CD, CHK_DIV, CHK_DGR, HO_CHK_DIV_CD2
		                          ) CK
		                  ) G
		       )
		     
		     -- 3. 기타 변수 반영
		 /*    , M.APRS_GRD1            = p_APRS_GRD1
		     , M.APRS_GRD2            = p_APRS_GRD2
		     , M.APRS_GRD3            = p_APRS_GRD3
		     , M.APRS_GRD4            = p_APRS_GRD4
		     , M.APRS_GRD5            = p_APRS_GRD5
		     , M.ATFL_GRP             = p_ATFL_GRP
		     , M.UPD_ID               = p_WRK_ID
		     , M.UPD_DTM              = SYSDATE()
		     , M.UPD_IP               = p_WRK_IP */
		 WHERE M.SIT_CD  = p_SIT_CD
		   AND M.CHK_DIV = p_CHK_DIV
		   AND M.CHK_DGR = p_CHK_DGR;

    ELSIF (p_WRK_TP ='U2') THEN -- 체크리스트 복사시

        DELETE FROM TQHA_HOCHKRPT_CK
         WHERE SIT_CD           = p_SIT_CD          -- 현장코드
           AND CHK_DIV          = p_CHK_DIV         -- 공통코드 : QSZ03
           AND CHK_DGR           = p_CHK_DGR          -- 점검차수
           AND COM_CD           = p_COM_CD          -- 공통코드 : QSZ03
           AND HO_CHK_DIV_CD    = p_HO_CHK_DIV_CD
        ;

        IF(p_USE_YN != '0') THEN

            INSERT 
              INTO TQHA_HOCHKRPT_CK
                 ( SIT_CD                   -- 현장코드
                 , CHK_DIV                  -- 공통코드 : QSZ03
                 , CHK_DGR                   -- 점검차수
                 , COM_CD                   -- 공통코드 : QSZ03
                 , HO_CHK_DIV_CD            -- 공통코드 : QSZ0310
                 , HO_CHK_DIV_CD2           -- 본사점검구분코드
                 , HO_CHK_ITM_CD            -- 본사점검항목코드
                 , APRS_PNDS
                 , IPT_ID                   -- 신규입력ID
                 , IPT_DTM                  -- 신규입력일시
                 , IPT_IP                   -- 신규입력IP
                 , UPD_ID                   -- 최종수정ID
                 , UPD_DTM                  -- 최종수정일시
                 , UPD_IP                   -- 최종수정IP
                 )
            SELECT p_SIT_CD                 -- 현장코드
                 , p_CHK_DIV                -- 공통코드 : QSZ03
                 , p_CHK_DGR                 -- 점검차수
                 , A.COM_CD
                 , A.HO_CHK_DIV_CD
                 , A.HO_CHK_DIV_CD2
                 , B.HO_CHK_ITM_CD
                 , B.MAX_SCORE
                 , p_WRK_ID                 -- 입력ID
                 , SYSDATE()                -- 입력일시
                 , p_WRK_IP                 -- 입력IP
                 , p_WRK_ID                 -- 수정ID
                 , SYSDATE()                -- 수정일시
                 , p_WRK_IP                 -- 수정IP
              FROM TQHA_CKLST       A
                 , TQHA_CKLST_ITM   B
             WHERE A.COM_CD                 = p_CHK_DIV
               AND A.HO_CHK_DIV_CD          = p_HO_CHK_DIV_CD
               AND A.HO_CHK_DIV_USE_YN      = '1'
               AND B.HO_CHK_ITM_USE_YN      = '1'
               AND A.COM_CD                 = B.COM_CD
               AND A.HO_CHK_DIV_CD          = B.HO_CHK_DIV_CD
               AND A.HO_CHK_DIV_CD2         = B.HO_CHK_DIV_CD2
            ;

        END IF;

    ELSE

        INSERT 
          INTO TQHA_HOCHKRPT_CK
             ( SIT_CD                   -- 현장코드
             , CHK_DIV                  -- 공통코드 : QSZ03
             , CHK_DGR                   -- 점검차수
             , COM_CD                   -- 공통코드 : QSZ03
             , HO_CHK_DIV_CD            -- 공통코드 : QSZ0310
             , HO_CHK_DIV_CD2           -- 본사점검구분코드
             , HO_CHK_ITM_CD            -- 본사점검항목코드
             , APRS_CHK                 -- 공통코드 : QSA04
             , APRS_SCR
             , APRS_CTS             
             , IPT_ID                   -- 신규입력ID
             , IPT_DTM                  -- 신규입력일시
             , IPT_IP                   -- 신규입력IP
             , UPD_ID                   -- 최종수정ID
             , UPD_DTM                  -- 최종수정일시
             , UPD_IP                   -- 최종수정IP
             )
        VALUES 
             ( p_SIT_CD                 -- 현장코드
             , p_CHK_DIV                -- 공통코드 : QSZ03
             , p_CHK_DGR                 -- 점검차수
             , p_COM_CD                 -- 공통코드 : QSZ03
             , p_HO_CHK_DIV_CD          -- 공통코드 : QSZ0310
             , p_HO_CHK_DIV_CD2         -- 본사점검구분코드
             , p_HO_CHK_ITM_CD          -- 본사점검항목코드
             , p_APRS_CHK               -- 공통코드 : QSA04
             , p_APRS_SCR
             , p_APRS_CTS
             , p_WRK_ID                 -- 입력ID
             , SYSDATE()                -- 입력일시
             , p_WRK_IP                 -- 입력IP
             , p_WRK_ID                 -- 수정ID
             , SYSDATE()                -- 수정일시
             , p_WRK_IP                 -- 수정IP
             )
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END;
/

-- PQHA_HOCHKRPT_ERR_S
DROP PROCEDURE "PQHA_HOCHKRPT_ERR_S";
CREATE PROCEDURE "PQHA_HOCHKRPT_ERR_S" (
    p_WRK_TP                VARCHAR2 :='U'                                          -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID                VARCHAR2                                                -- 사용자 ID
,   p_WRK_IP                VARCHAR2                                                -- 사용자 IP
,   p_SIT_CD                TQHA_HOCHKRPT_ERR.SIT_CD                %TYPE           -- 현장코드
,   p_CHK_DIV               TQHA_HOCHKRPT_ERR.CHK_DIV               %TYPE           -- 공통코드 : QSZ03
,   p_CHK_DGR               TQHA_HOCHKRPT_ERR.CHK_DGR               %TYPE           -- 점검차수
,   p_CHK_DT                TQHA_HOCHKRPT_ERR.CHK_DT                %TYPE           -- 점검일자
,   p_ERR_SEQ               TQHA_HOCHKRPT_ERR.ERR_SEQ               %TYPE           -- 지적순번
,   p_DIV_1                 TQHA_HOCHKRPT_ERR.DIV_1                 %TYPE           -- 안전 > 공통코드 : QSA02, 환경 > 공통코드 : QSA03
,   p_DIV_2                 TQHA_HOCHKRPT_ERR.DIV_2                 %TYPE           -- 안전 > 공통코드 : QSA02, 환경 > 공통코드 : QSA03
,   p_DIV_3                 TQHA_HOCHKRPT_ERR.DIV_3                 %TYPE           -- 공통코드 : QSK03
,   p_CHK_ELMT              TQHA_HOCHKRPT_ERR.CHK_ELMT              %TYPE           -- 지적부위
,   p_CHK_MATT              TQHA_HOCHKRPT_ERR.CHK_MATT              %TYPE           -- 지적사항
,   p_CSE                   TQHA_HOCHKRPT_ERR.CSE                   %TYPE           -- 원인
,   p_CPLN_MA_SHM           TQHA_HOCHKRPT_ERR.CPLN_MA_SHM           %TYPE           -- 대책조치방안
,   p_INSP_EMPNO            TQHA_HOCHKRPT_ERR.INSP_EMPNO            %TYPE           -- 점검자
,   p_INSP_NM              TQHA_HOCHKRPT_ERR.INSP_NM                %TYPE           -- 점검자성명
,   p_MA_DT                 TQHA_HOCHKRPT_ERR.MA_DT                 %TYPE           -- 조치일자
,   p_MA_MATT               TQHA_HOCHKRPT_ERR.MA_MATT               %TYPE           -- 조치사항
,   p_MA_PSN_EMPNO          TQHA_HOCHKRPT_ERR.MA_PSN_EMPNO          %TYPE           -- 조치자/담당직원
,   p_MA_PSN_NM            TQHA_HOCHKRPT_ERR.MA_PSN_NM              %TYPE           -- 조치자성명
,   p_CUST_CD               TQHA_HOCHKRPT_ERR.CUST_CD               %TYPE           -- 협력회사
,   p_CUST_NM               TQHA_HOCHKRPT_ERR.CUST_NM               %TYPE           -- 거래처명
,   p_ATFL_GRP              TQHA_HOCHKRPT_ERR.ATFL_GRP              %TYPE           -- 첨부문서
,   p_ATFL_GRP2             TQHA_HOCHKRPT_ERR.ATFL_GRP2             %TYPE           -- 조치전 사진
,   p_ATFL_GRP3             TQHA_HOCHKRPT_ERR.ATFL_GRP3             %TYPE           -- 조치후 사진
,   p_PHOTO_DESC_2          TQHA_HOCHKRPT_ERR.PHOTO_DESC_2          %TYPE           -- 조치전 사진내용
,   p_PHOTO_DESC_3          TQHA_HOCHKRPT_ERR.PHOTO_DESC_3          %TYPE           -- 조치후 사진내용
)
IS
    /**************************************************************************************************************************
      Purpose :

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2019/06/19 17:19:07                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR(200);             -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_cnt               INTEGER;
    v_cnt2              INTEGER;
    v_cnt3              INTEGER;
    v_text              VARCHAR(100);

    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CHK_DIV IS NULL)  THEN
        ERR_MSG := '공통코드 : QSZ03는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    -----------------------------------------------------------------
--     --결재상태 체크
--    SELECT MAX(T2.APRV_STATS)
--      INTO v_APRV_STATS
--      FROM TQHA_HOCHKRPT        T1
--      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
--                                  AND T1.APRV_NO1   = T2.APRV_NO
--     WHERE T1.SIT_CD    = p_SIT_CD
--       AND T1.CHK_DIV   = p_CHK_DIV
--       AND T1.CHK_DGR   = p_CHK_DGR
--    ;
--
--    IF v_APRV_STATS IN ('2', '4') THEN
--        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
--        RAISE USER_EXCEPTION;
--    END IF;
--    ---------------------------------------------------------------------

    
    
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN

        DELETE
          FROM TQHA_HOCHKRPT_ERR
         WHERE SIT_CD       = p_SIT_CD          -- 현장코드
           AND CHK_DIV      = p_CHK_DIV         -- 공통코드 : QSZ03
           AND CHK_DGR      = p_CHK_DGR
           AND ERR_SEQ      = p_ERR_SEQ         -- 지적순번
        ;

    ELSIF (p_WRK_TP ='U') THEN

        UPDATE TQHA_HOCHKRPT_ERR
           SET DIV_1                = p_DIV_1                   -- 안전 > 공통코드 : QSA02, 환경 > 공통코드 : QSA03
             , DIV_2                = p_DIV_2                   -- 안전 > 공통코드 : QSA02, 환경 > 공통코드 : QSA03
             , DIV_3                = p_DIV_3                   -- 공통코드 : QSK03
             , CHK_ELMT             = p_CHK_ELMT                -- 지적부위
             , CHK_MATT             = p_CHK_MATT                -- 지적사항
             , CSE                  = p_CSE                     -- 원인
             , CPLN_MA_SHM          = p_CPLN_MA_SHM             -- 대책조치방안
             , INSP_EMPNO           = p_INSP_EMPNO              -- 점검자
             , INSP_NM              = p_INSP_NM                -- 점검자성명
             , CUST_CD              = p_CUST_CD                 -- 협력회사
             , CUST_NM              = p_CUST_NM                 -- 거래처명
             , ATFL_GRP2            = p_ATFL_GRP2               -- 조치전 사진
             , PHOTO_DESC_2         = p_PHOTO_DESC_2               -- 조치전 사진
             , UPD_ID               = p_WRK_ID                  -- 수정ID
             , UPD_DTM              = SYSDATE()                 -- 수정일시
             , UPD_IP               = p_WRK_IP                  -- 수정IP
         WHERE SIT_CD               = p_SIT_CD                  -- 현장코드
           AND CHK_DIV              = p_CHK_DIV                 -- 공통코드 : QSZ03
           AND CHK_DGR              = p_CHK_DGR
           AND ERR_SEQ              = p_ERR_SEQ                 -- 지적순번
        ;

    ELSIF (p_WRK_TP ='U2') THEN -- 지적사항 조치후 저장시

         UPDATE TQHA_HOCHKRPT_ERR
           SET MA_DT                = p_MA_DT           -- 조치일자
             , MA_MATT              = p_MA_MATT         -- 조치내용
             , MA_PSN_EMPNO         = p_WRK_ID          -- 조치자/담당직원
             , PHOTO_DESC_2         = p_PHOTO_DESC_2    -- 조치전 사진내용
             , PHOTO_DESC_3         = p_PHOTO_DESC_3    -- 조치후 사진내용
             , ATFL_GRP             = p_ATFL_GRP        -- 첨부문서
             , ATFL_GRP2            = p_ATFL_GRP2       -- 조치전 사진
             , ATFL_GRP3            = p_ATFL_GRP3       -- 조치후 사진
             , UPD_ID               = p_WRK_ID          -- 수정ID
             , UPD_DTM              = SYSDATE()         -- 수정일시
             , UPD_IP               = p_WRK_IP          -- 수정IP
         WHERE SIT_CD               = p_SIT_CD          -- 현장코드
           AND CHK_DIV              = p_CHK_DIV         -- 공통코드 : QSZ03
           AND CHK_DGR              = p_CHK_DGR
           AND ERR_SEQ              = p_ERR_SEQ
        ;
         
          UPDATE TQHA_HOCHKRPT
           SET MA_DT                = p_MA_DT
             , UPD_ID               = p_WRK_ID          -- 수정ID
             , UPD_DTM              = SYSDATE()         -- 수정일시
             , UPD_IP               = p_WRK_IP
         WHERE SIT_CD               = p_SIT_CD          -- 현장코드
           AND CHK_DIV              = p_CHK_DIV         -- 공통코드 : QSZ03
           AND CHK_DGR              = p_CHK_DGR
        ;
          
    ELSIF (p_WRK_TP ='U3') THEN

        UPDATE TQHA_HOCHKRPT_ERR
           SET ATFL_GRP2            = p_ATFL_GRP2               -- 조치전 사진
             , UPD_ID               = p_WRK_ID                  -- 수정ID
             , UPD_DTM              = SYSDATE()                 -- 수정일시
             , UPD_IP               = p_WRK_IP                  -- 수정IP
         WHERE SIT_CD               = p_SIT_CD                  -- 현장코드
           AND CHK_DIV              = p_CHK_DIV                 -- 공통코드 : QSZ03
           AND CHK_DGR              = p_CHK_DGR
           AND ERR_SEQ              = p_ERR_SEQ                 -- 지적순번
        ;
        
     ELSIF (p_WRK_TP ='U3_2') THEN

        UPDATE TQHA_HOCHKRPT_ERR
           SET ATFL_GRP3            = p_ATFL_GRP3               -- 조치전 사진
             , UPD_ID               = p_WRK_ID                  -- 수정ID
             , UPD_DTM              = SYSDATE()                 -- 수정일시
             , UPD_IP               = p_WRK_IP                  -- 수정IP
         WHERE SIT_CD               = p_SIT_CD                  -- 현장코드
           AND CHK_DIV              = p_CHK_DIV                 -- 공통코드 : QSZ03
           AND CHK_DGR              = p_CHK_DGR
           AND ERR_SEQ              = p_ERR_SEQ                 -- 지적순번
        ;
        
     ELSIF (p_WRK_TP ='U4') THEN

        UPDATE TQHA_HOCHKRPT_ERR
           SET ATFL_GRP             = p_ATFL_GRP                 -- 첨부
             , UPD_ID               = p_WRK_ID                  -- 수정ID
             , UPD_DTM              = SYSDATE()                 -- 수정일시
             , UPD_IP               = p_WRK_IP                  -- 수정IP
         WHERE SIT_CD               = p_SIT_CD                  -- 현장코드
           AND CHK_DIV              = p_CHK_DIV                 -- 공통코드 : QSZ03
           AND CHK_DGR              = p_CHK_DGR
           AND ERR_SEQ              = p_ERR_SEQ                 -- 지적순번
        ;
        
    ELSE

        INSERT 
          INTO TQHA_HOCHKRPT_ERR
              ( SIT_CD                  -- 현장코드
              , CHK_DIV                 -- 공통코드 : QSZ03
              , CHK_DGR
              , CHK_DT
              , ERR_SEQ                 -- 지적순번
              , DIV_1                   -- 안전 > 공통코드 : QSA02, 환경 > 공통코드 : QSA03
              , DIV_2                   -- 안전 > 공통코드 : QSA02, 환경 > 공통코드 : QSA03
              , DIV_3                   -- 공통코드 : QSK03
              , CHK_ELMT                -- 지적부위
              , CHK_MATT                -- 지적사항
              , CSE                     -- 원인
              , CPLN_MA_SHM             -- 대책조치방안
              , INSP_EMPNO              -- 점검자
              , INSP_NM                -- 점검자성명
              , MA_DT                   -- 조치일자
              , MA_MATT                 -- 조치사항
              , MA_PSN_EMPNO            -- 조치자/담당직원
              , MA_PSN_NM              -- 조치자성명
              , CUST_CD                 -- 협력회사
              , CUST_NM                 -- 거래처명
              , ATFL_GRP                -- 첨부문서
              , ATFL_GRP2               -- 조치전 사진
              , ATFL_GRP3               -- 조치후 사진
              , PHOTO_DESC_3            -- 조치후 사진내용
              , IPT_ID                  -- 신규입력ID
              , IPT_DTM                 -- 신규입력일시
              , IPT_IP                  -- 신규입력IP
              , UPD_ID                  -- 최종수정ID
              , UPD_DTM                 -- 최종수정일시
              , UPD_IP                  -- 최종수정IP
              )
        VALUES 
             ( p_SIT_CD                 -- 현장코드
             , p_CHK_DIV                -- 공통코드 : QSZ03
             , p_CHK_DGR
             , p_CHK_DT
             , (SELECT NVL(MAX(ERR_SEQ),0) +1 FROM TQHA_HOCHKRPT_ERR WHERE SIT_CD = p_SIT_CD AND CHK_DIV = p_CHK_DIV AND CHK_DGR = p_CHK_DGR ) --지적순번
             , p_DIV_1                  -- 안전 > 공통코드 : QSA02, 환경 > 공통코드 : QSA03
             , p_DIV_2                  -- 안전 > 공통코드 : QSA02, 환경 > 공통코드 : QSA03
             , p_DIV_3                  -- 공통코드 : QSK03
             , p_CHK_ELMT               -- 지적부위
             , p_CHK_MATT               -- 지적사항
             , p_CSE                    -- 원인
             , p_CPLN_MA_SHM            -- 대책조치방안
             , p_INSP_EMPNO             -- 점검자
             , p_INSP_NM               -- 점검자성명 
             , NULL                     -- 조치일자
             , p_MA_MATT                -- 조치사항
             , p_MA_PSN_EMPNO           -- 조치자/담당직원
             , p_MA_PSN_NM             -- 조치자성명
             , p_CUST_CD                -- 협력회사
             , p_CUST_NM                -- 거래처명
             , p_ATFL_GRP               -- 첨부문서
             , p_ATFL_GRP2              -- 조치전 사진
             , p_ATFL_GRP3              -- 조치후 사진
             , p_PHOTO_DESC_3           -- 조치후 사진내용
             , p_WRK_ID                 -- 입력ID
             , SYSDATE()                -- 입력일시
             , p_WRK_IP                 -- 입력IP
             , p_WRK_ID                 -- 수정ID
             , SYSDATE()                -- 수정일시
             , p_WRK_IP                 -- 수정IP
             )
        ;


    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END;
/

-- PQHA_HOCHKRPT_Q
DROP PROCEDURE "PQHA_HOCHKRPT_Q";
CREATE PROCEDURE "PQHA_HOCHKRPT_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'         -- FLAG
,   p_SIT_CD            IN VARCHAR2                     -- 현장코드
,   p_CHK_DIV           IN VARCHAR2                     -- 점검구분
,   p_CHK_DGR           IN VARCHAR2                     -- 점검차수
,   p_STR_DT            IN VARCHAR2                     -- 시작일자
,   p_END_DT            IN VARCHAR2                     -- 종료일자
,   p_CHK_DT            IN VARCHAR2                     -- 점검일자
,   p_QUARTER           IN VARCHAR2                     -- 분기
,   p_SCR_DIV           IN VARCHAR2                     -- 
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS 
    /**************************************************************************************************************************
      Purpose : [본사점검(안전/보건) 조회] PROCEDRE (QSE > 재해예방관리 > 본사점검(안전/보건)  )

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      XXXX/XX/XX                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION; 

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR        
        WITH HOCHKRPT AS (
		    SELECT 
		           A.SIT_CD                          -- 현장코드
		         , FQHA_GETCMSITENM_BY_SITECD(A.SIT_CD) AS SIT_NM
		         , A.CHK_DIV                          -- 공통코드 : QSZ03
		         , A.CHK_DGR                          -- 점검차수
		         , A.CHK_DT                           -- 점검일자
		         , A.QUARTER
		         , A.MA_DT                            -- 조치기간
		         , A.SIT_OMGR_EMPNO                   -- 현장소장사번
		         , A.INSP_EMPNO                       -- 점검자
		         , A.SAFT_MGR                         -- 안전관리자
		         -- , A.SIT_OMGR_NM                      -- 현장소장명
		         , A.INSP_NM                         -- 점검자성명
		         , A.SAFT_MGR_NM                     -- 안전관리자성명 
		         --,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.INSP_EMPNO ) AS INSP_NM   			  -- 점검자
		         ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SIT_OMGR_EMPNO ) AS SIT_OMGR_EMPNO_NM   -- 현장소장
	             --,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SAFT_MGR )  AS SAFT_MGR_NM   		  -- 안전관리자명	
		         , A.ORDPLC                           -- 발주처
		         , A.CNST_STR_DD
		         , A.CNST_END_DD                      -- 공사종료일
		         , A.CNST_STR_DD || ' ~ ' || A.CNST_END_DD AS CNST_DD -- 공사기간
		         , A.CNST_AMT                         -- 공사금액
		         , A.PROCRT                           -- 공정율
		         , A.MBOT_PSNNO                       -- 출역인원
		         , A.CNST_SCAL                        -- 공사규모
		         , A.DISS_ACM                         -- 재해누계
		         , A.DISS_CY                          -- 재해당해
		         , A.SAFT_MCHR                        -- 계상안전관리비
		         , A.SAFT_ACM_AMT                     -- 누계사용금액
		         , A.SAFT_USE_RT                      -- 사용율
		         , A.WRK_MATT                         -- 작업사항
		         , A.TDAY_WRK                         -- 금일작업
		         , A.SCH_WRK                          -- 예정작업
		         , A.RVLT_SCR1                        -- 전회점수1
		         , A.RVLT_SCR2                        -- 전회점수2
		         , A.RVLT_SCR3                        -- 전회점수3
		         , A.RVLT_SCR4                        -- 전회점수4
		         , A.RVLT_SCR5                        -- 전회점수5
		         , A.TTM_SCR1                         -- 금회점수1
		         , A.TTM_SCR2                         -- 금회점수2
		         , A.TTM_SCR3                         -- 금회점수3
		         , A.TTM_SCR4                         -- 금회점수4
		         , A.TTM_SCR5                         -- 금회점수5
		         , A.APRS_GRD1                        -- 평가등급1
		         , A.APRS_GRD2                        -- 평가등급2
		         , A.APRS_GRD3                        -- 평가등급3
		         , A.APRS_GRD4                        -- 평가등급4
		         , A.APRS_GRD5                        -- 평가등급5
		         , A.RMKS1                            -- 비고1
		         , A.RMKS2                            -- 비고2
		         , A.RMKS3                            -- 비고3
		         , A.RMKS4                            -- 비고4
		         , A.RMKS5                            -- 비고5
		         , A.EXCL_EXMP                        -- 우수사례
		         , A.MNG_MATT                         -- 관리사항
		         , A.ATFL_GRP                         -- 첨부파일
		         , A.PRGS_STATS_CD1                   -- 본사점검상태
		         , A.APRV_NO1                         -- 본사점검결재번호
		         , A.PRGS_STATS_CD2                   -- 조치결과상태
		         , A.APRV_NO2                         -- 조치결과결재번호
		         , A.CLOSE_YN
		         , DECODE(A.CLOSE_YN,'1','마감','') AS CLOSE_YN_NM
		           -- 1. 스칼라 서브쿼리 영역
		         , (SELECT FQHA_GETDEPTNM_BY_DEPTCD(BB.DEPT_CD)
		              FROM TCOZ_USR_INFO BB
		             WHERE BB.USR_ID = A.INSP_EMPNO) AS INSP_BLN        -- 점검자소속     
		         , (SELECT MAX(ERR.MA_DT)
		              FROM TQHA_HOCHKRPT_ERR ERR
		             WHERE ERR.SIT_CD  = A.SIT_CD
		               AND ERR.CHK_DIV = A.CHK_DIV
		               AND ERR.CHK_DT  = A.CHK_DT)   AS MX_MA_DT        -- 최대 조치일자
		      FROM TQHA_HOCHKRPT A
		      LEFT OUTER JOIN TQHA_APRV C 
		        ON A.SIT_CD   = C.SIT_CD
		       AND A.APRV_NO1 = C.APRV_NO
		     WHERE 1=1
		       AND A.SIT_CD     = NVL(p_SIT_CD, A.SIT_CD)
		       AND (
					    (p_CHK_DIV IS NOT NULL AND A.CHK_DIV = p_CHK_DIV)
					    OR
					    (p_CHK_DIV IS NULL AND (
					        (p_SCR_DIV = 1 AND A.CHK_DIV IN ('QS0730101', 'QS0730102')) OR
					        (p_SCR_DIV = 2 AND A.CHK_DIV IN ('QS073020101', 'QS073020102', 'QS073020103'))
					    ))
					)
		       AND REPLACE(A.CHK_DT, '-', '') BETWEEN REPLACE(NVL(p_STR_DT, A.CHK_DT), '-', '') AND REPLACE(NVL(p_END_DT, A.CHK_DT), '-', '')
		)
		SELECT R.*
		     , (TO_DATE(R.MX_MA_DT, 'YYYY/MM/DD') - TO_DATE(R.MA_DT, 'YYYY/MM/DD')) AS DIFF_MA_DT
		     , CASE WHEN (TO_DATE(R.MX_MA_DT, 'YYYY/MM/DD') - TO_DATE(R.MA_DT, 'YYYY/MM/DD')) > 0 THEN '●'
		            ELSE ''
		       END AS MA_DT_MARK
		  FROM HOCHKRPT R
		 ORDER BY R.CHK_DT DESC, R.CHK_DGR DESC, R.SIT_CD ASC
        ;

    ---------------------------------------------------------------------------------------------
    ELSIF p_WRK_TP = 'Q2' THEN

        OPEN RTN_CURSOR FOR 
            SELECT A.SIT_CD                          -- 현장코드
		         , FQHA_GETCMSITENM_BY_SITECD(A.SIT_CD) AS SIT_NM
		         , A.CHK_DIV                          -- 공통코드 : QSZ03
		         , A.CHK_DGR                          -- 점검차수
		         , A.CHK_DT                           -- 점검일자
		         , A.QUARTER
		         , A.MA_DT                            -- 조치기간
		         , A.SIT_OMGR_EMPNO                   -- 현장소장사번
		         , A.SAFT_MGR                         -- 안전관리자
		         , A.INSP_EMPNO                       -- 점검자		         
		         --,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.INSP_EMPNO ) AS INSP_NM   			  -- 점검자
		         ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SIT_OMGR_EMPNO ) AS SIT_OMGR_EMPNO_NM   -- 현장소장
	             --,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SAFT_MGR )  AS SAFT_MGR_NM   		  -- 안전관리자명		         
		         , A.INSP_NM                         -- 점검자성명		         
		         , A.SAFT_MGR_NM                     -- 안전관리자성명
		         --, A.SIT_OMGR_NM                      -- 현장소장명
		         , A.ORDPLC                           -- 발주처
		         , A.CNST_STR_DD      -- 공사시작일
		         , A.CNST_END_DD      -- 공사종료일
		         , A.CNST_AMT         -- 공사금액
		         , A.PROCRT           -- 공정율
		         , A.MBOT_PSNNO                       -- 출역인원
		         , A.CNST_SCAL                        -- 공사규모		         
		         , A.DISS_CY
		         , A.DISS_ACM		         
		         , A.SAFT_MCHR                        -- 계상안전관리비
		         , A.SAFT_ACM_AMT                     -- 누계사용금액
		         , A.SAFT_USE_RT                      -- 사용율
		         , A.WRK_MATT                         -- 작업사항
		         , A.TDAY_WRK                         -- 금일작업
		         , A.SCH_WRK                          -- 예정작업
		         , A.RVLT_SCR1                        -- 전회점수1
		         , A.RVLT_SCR2                        -- 전회점수2
		         , A.RVLT_SCR3                        -- 전회점수3
		         , A.RVLT_SCR4                        -- 전회점수4
		         , A.RVLT_SCR5                        -- 전회점수5
		         , A.TTM_SCR1                         -- 금회점수1
		         , A.TTM_SCR2                         -- 금회점수2
		         , A.TTM_SCR3                         -- 금회점수3
		         , A.TTM_SCR4                         -- 금회점수4
		         , A.TTM_SCR5                         -- 금회점수5
		         , A.APRS_GRD1                        -- 평가등급1
		         , A.APRS_GRD2                        -- 평가등급2
		         , A.APRS_GRD3                        -- 평가등급3
		         , A.APRS_GRD4                        -- 평가등급4
		         , A.APRS_GRD5                        -- 평가등급5
		         , A.RMKS1                            -- 비고1
		         , A.RMKS2                            -- 비고2
		         , A.RMKS3                            -- 비고3
		         , A.RMKS4                            -- 비고4
		         , A.RMKS5                            -- 비고5
		         , A.EXCL_EXMP                        -- 우수사례
		         , A.MNG_MATT                         -- 관리사항
		         , A.ATFL_GRP                         -- 첨부파일
		         , A.PRGS_STATS_CD1                   -- 본사점검상태
		         , A.APRV_NO1                         -- 본사점검결재번호
		         , A.PRGS_STATS_CD2                   -- 조치결과상태
		         , A.APRV_NO2                         -- 조치결과결재번호
		         , A.CLOSE_YN
		           -- 스칼라 서브쿼리 가공 영역
		         , (SELECT FQHA_GETDEPTNM_BY_DEPTCD(BB.DEPT_CD)
		              FROM TCOZ_USR_INFO BB
		             WHERE BB.USR_ID = A.INSP_EMPNO) AS INSP_BLN        
		         , (SELECT MAX(ERR.MA_DT)
		              FROM TQHA_HOCHKRPT_ERR ERR
		             WHERE ERR.SIT_CD  = A.SIT_CD
		               AND ERR.CHK_DIV = A.CHK_DIV
		               AND ERR.CHK_DT  = A.CHK_DT)   AS MX_MA_DT        
		         , A.CNST_STR_DD || ' ~ ' || A.CNST_END_DD AS CNST_PERIOD -- ★ 별칭 중복 방지를 위해 수정한 공사기간
		         , '▶ 결재상태 : ' || NVL((SELECT CD_NM FROM TCOA_COMCODE WHERE HRNK_CD = 'QS031' AND COM_CD = C.APRV_STATS), '-') AS APRV_STATS_NM 
		      FROM TQHA_HOCHKRPT A
		      LEFT OUTER JOIN TQHA_APRV C 
		        ON A.SIT_CD   = C.SIT_CD
		       AND A.APRV_NO1 = C.APRV_NO
		     WHERE A.SIT_CD  = p_SIT_CD
		       AND A.CHK_DIV = p_CHK_DIV
		       AND A.CHK_DGR = p_CHK_DGR
		 ;
			
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_HOCHKRPT_Q;
/

-- PQHA_HOCHKRPT_S
DROP PROCEDURE "PQHA_HOCHKRPT_S";
CREATE PROCEDURE "PQHA_HOCHKRPT_S" 
                            (p_WRK_TP  VARCHAR2 :='U'                                     -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
                            ,p_WRK_ID  VARCHAR2                                           -- 사용자 ID 
                            ,p_WRK_IP  VARCHAR2                                           -- 사용자 IP 
                            ,p_SIT_CD TQHA_HOCHKRPT.SIT_CD%TYPE                           -- 현장코드
                            ,p_CHK_DIV TQHA_HOCHKRPT.CHK_DIV%TYPE                         -- 공통코드 : QSZ03
                            ,p_CHK_DGR TQHA_HOCHKRPT.CHK_DGR%TYPE                         -- 점검차수
                            ,p_CHK_DT TQHA_HOCHKRPT.CHK_DT%TYPE                           -- 점검일자
                            ,p_QUARTER TQHA_HOCHKRPT.QUARTER%TYPE                         -- 분기
                            ,p_MA_DT TQHA_HOCHKRPT.MA_DT%TYPE                             -- 조치기간
                            ,p_SIT_OMGR_EMPNO TQHA_HOCHKRPT.SIT_OMGR_EMPNO%TYPE           -- 현장소장사번
                            ,p_SIT_OMGR_NM TQHA_HOCHKRPT.SIT_OMGR_NM%TYPE                 -- 현장소장명
                            ,p_INSP_BLN TQHA_HOCHKRPT.INSP_BLN%TYPE                       -- 점검자소속
                            ,p_INSP_EMPNO TQHA_HOCHKRPT.INSP_EMPNO%TYPE                   -- 점검자
                            ,p_INSP_NM TQHA_HOCHKRPT.INSP_NM%TYPE                         -- 점검자성명
                            ,p_SAFT_MGR TQHA_HOCHKRPT.SAFT_MGR%TYPE                       -- 안전관리자
                            ,p_SAFT_MGR_NM TQHA_HOCHKRPT.SAFT_MGR_NM%TYPE                 -- 안전관리자성명
                            ,p_ORDPLC TQHA_HOCHKRPT.ORDPLC%TYPE                           -- 발주처
                            ,p_CNST_STR_DD TQHA_HOCHKRPT.CNST_STR_DD%TYPE                 -- 공사시작일 
                            ,p_CNST_END_DD TQHA_HOCHKRPT.CNST_END_DD%TYPE                 -- 공사종료일
                            ,p_CNST_AMT TQHA_HOCHKRPT.CNST_AMT%TYPE                       -- 공사금액
                            ,p_PROCRT TQHA_HOCHKRPT.PROCRT%TYPE                           -- 공정율
                            ,p_MBOT_PSNNO TQHA_HOCHKRPT.MBOT_PSNNO%TYPE                   -- 출역인원
                            ,p_CNST_SCAL TQHA_HOCHKRPT.CNST_SCAL%TYPE                     -- 공사규모
                            ,p_DISS_ACM TQHA_HOCHKRPT.DISS_ACM%TYPE                       -- 재해누계
                            ,p_DISS_CY TQHA_HOCHKRPT.DISS_CY%TYPE                         -- 재해당해
                            ,p_SAFT_MCHR TQHA_HOCHKRPT.SAFT_MCHR%TYPE                     -- 계상안전관리비
                            ,p_SAFT_ACM_AMT TQHA_HOCHKRPT.SAFT_ACM_AMT%TYPE               -- 누계사용금액
                            ,p_SAFT_USE_RT TQHA_HOCHKRPT.SAFT_USE_RT%TYPE                 -- 사용율
                            ,p_WRK_MATT TQHA_HOCHKRPT.WRK_MATT%TYPE                       -- 작업사항
                            ,p_TDAY_WRK TQHA_HOCHKRPT.TDAY_WRK%TYPE                       -- 금일작업
                            ,p_SCH_WRK TQHA_HOCHKRPT.SCH_WRK%TYPE                         -- 예정작업
                            ,p_RVLT_SCR1 TQHA_HOCHKRPT.RVLT_SCR1%TYPE                     -- 전회점수1
                            ,p_RVLT_SCR2 TQHA_HOCHKRPT.RVLT_SCR2%TYPE                     -- 전회점수2
                            ,p_RVLT_SCR3 TQHA_HOCHKRPT.RVLT_SCR3%TYPE                     -- 전회점수3
                            ,p_RVLT_SCR4 TQHA_HOCHKRPT.RVLT_SCR4%TYPE                     -- 전회점수4
                            ,p_RVLT_SCR5 TQHA_HOCHKRPT.RVLT_SCR5%TYPE                     -- 전회점수5
                            ,p_TTM_SCR1 TQHA_HOCHKRPT.TTM_SCR1%TYPE                       -- 금회점수1
                            ,p_TTM_SCR2 TQHA_HOCHKRPT.TTM_SCR2%TYPE                       -- 금회점수2
                            ,p_TTM_SCR3 TQHA_HOCHKRPT.TTM_SCR3%TYPE                       -- 금회점수3
                            ,p_TTM_SCR4 TQHA_HOCHKRPT.TTM_SCR4%TYPE                       -- 금회점수4
                            ,p_TTM_SCR5 TQHA_HOCHKRPT.TTM_SCR5%TYPE                       -- 금회점수5
                            ,p_APRS_GRD1 TQHA_HOCHKRPT.APRS_GRD1%TYPE                     -- 평가등급1
                            ,p_APRS_GRD2 TQHA_HOCHKRPT.APRS_GRD2%TYPE                     -- 평가등급2
                            ,p_APRS_GRD3 TQHA_HOCHKRPT.APRS_GRD3%TYPE                     -- 평가등급3
                            ,p_APRS_GRD4 TQHA_HOCHKRPT.APRS_GRD4%TYPE                     -- 평가등급4
                            ,p_APRS_GRD5 TQHA_HOCHKRPT.APRS_GRD5%TYPE                     -- 평가등급5
                            ,p_RMKS1 TQHA_HOCHKRPT.RMKS1%TYPE                             -- 비고1
                            ,p_RMKS2 TQHA_HOCHKRPT.RMKS2%TYPE                             -- 비고2
                            ,p_RMKS3 TQHA_HOCHKRPT.RMKS3%TYPE                             -- 비고3
                            ,p_RMKS4 TQHA_HOCHKRPT.RMKS4%TYPE                             -- 비고4
                            ,p_RMKS5 TQHA_HOCHKRPT.RMKS5%TYPE                             -- 비고5
                            ,p_EXCL_EXMP TQHA_HOCHKRPT.EXCL_EXMP%TYPE                     -- 우수사례
                            ,p_MNG_MATT TQHA_HOCHKRPT.MNG_MATT%TYPE                       -- 관리사항
                            ,p_ATFL_GRP TQHA_HOCHKRPT.ATFL_GRP%TYPE                       -- 첨부파일
                            ,p_PRGS_STATS_CD1 TQHA_HOCHKRPT.PRGS_STATS_CD1%TYPE           -- 본사점검상태
                            ,p_APRV_NO1 TQHA_HOCHKRPT.APRV_NO1%TYPE                       -- 본사점검결재번호
                            ,p_PRGS_STATS_CD2 TQHA_HOCHKRPT.PRGS_STATS_CD2%TYPE           -- 조치결과상태
                            ,p_APRV_NO2 TQHA_HOCHKRPT.APRV_NO2%TYPE                       -- 조치결과결재번호
                            )
IS 
    /**************************************************************************************************************************
      Purpose : 

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/07/08 16:56:48                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

	v_cnt           NUMBER;
    v_cnt2          NUMBER;
    v_text          VARCHAR(100); 

    v_aplCnt        NUMBER;
    
    v_SEQ			NUMBER;
    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);
    
BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CHK_DIV IS NULL)  THEN
        ERR_MSG := '점검구분는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_WRK_TP != 'I' AND p_CHK_DGR IS NULL)  THEN
        ERR_MSG := '점검차수는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CHK_DT IS NULL)  THEN
        ERR_MSG := '점검일자는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_QUARTER IS NULL)  THEN
        ERR_MSG := '분기는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------

     -- 결재상태 체크
    SELECT MAX(T2.APRV_STATS)
         , MAX(T3.CD_NM )
      INTO v_APRV_STATS
         , v_APRV_STATS_NM
      FROM TQHA_HOCHKRPT        T1
      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
                                  AND T1.APRV_NO2   = T2.APRV_NO
      LEFT JOIN TCOA_COMCODE    T3 ON T2.APRV_STATS = T3.COM_CD
                                  AND T3.HRNK_CD    = 'QS031'
     WHERE T1.SIT_CD    = p_SIT_CD
       AND T1.CHK_DIV   = p_CHK_DIV
       AND T1.CHK_DGR   = p_CHK_DGR
    ;
--
--    IF v_APRV_STATS IN ('2', '4') THEN
--        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
--        RAISE USER_EXCEPTION;
--    END IF;

    
    
    IF (p_WRK_TP = 'I')  THEN
   		     
	    SELECT COUNT(*) INTO v_cnt2
	      FROM TQHA_HOCHKRPT
	     WHERE SIT_CD       = p_SIT_CD
	       AND CHK_DIV      = p_CHK_DIV
	       AND QUARTER      = p_QUARTER
	       AND SUBSTR(CHK_DT,1,4) = SUBSTR(p_CHK_DT,1,4)
	    ;
	    IF (v_cnt2 > 0)  THEN
	        ERR_MSG := '이미 등록된 분기 입니다.';
	        RAISE USER_EXCEPTION;
	    END IF;
    
    END IF;
    
     SELECT COUNT(*) INTO v_cnt
      FROM TQHA_HOCHKRPT_CK
     WHERE SIT_CD       = p_SIT_CD
       AND CHK_DIV      = p_CHK_DIV
       AND CHK_DGR      = p_CHK_DGR
    ;
     
     /*
    IF LENGTHB(p_EXCL_EXMP) > 1000 THEN
	    ERR_MSG := '우수사례 글자수가 너무 많습니다.';
	    RAISE USER_EXCEPTION;
	END IF;
    
    IF LENGTHB(p_MNG_MATT) > 1000 THEN
	    ERR_MSG := '관리사항 글자수가 너무 많습니다.';
	    RAISE USER_EXCEPTION;
	END IF;
     */     

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN
    
        IF v_APRV_STATS IN ('2', '4') THEN
            ERR_MSG := '결재중 또는 결재완료된 문서는 삭제 할 수 없습니다.';
            RAISE USER_EXCEPTION;
        END IF;
        
        --본사점검보고서_지적사항
        DELETE
          FROM TQHA_HOCHKRPT_ERR
         WHERE SIT_CD       = p_SIT_CD
           AND CHK_DIV      = p_CHK_DIV
           AND CHK_DGR      = p_CHK_DGR
        ;
        --본사점검보고서_체크리스트
        DELETE
          FROM TQHA_HOCHKRPT_CK
         WHERE SIT_CD       = p_SIT_CD
           AND CHK_DIV      = p_CHK_DIV
           AND CHK_DGR      = p_CHK_DGR
        ;
        
        --본사점검보고서_점검사진
        DELETE
          FROM TQHA_HOCHKRPT_PHOTO
         WHERE SIT_CD       = p_SIT_CD
           AND CHK_DIV      = p_CHK_DIV
           AND CHK_DGR      = p_CHK_DGR
         ;
          
        DELETE 
          FROM TQHA_HOCHKRPT
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND CHK_DIV = p_CHK_DIV         --공통코드 : QSZ03
           AND CHK_DGR = p_CHK_DGR;        --점검차수

    ELSIF (p_WRK_TP ='U') THEN
    
        UPDATE TQHA_HOCHKRPT
           SET CHK_DT               = p_CHK_DT                  --점검일자
              ,QUARTER              = p_QUARTER
              ,MA_DT                = p_MA_DT                   --조치기간
              ,SIT_OMGR_EMPNO       = p_SIT_OMGR_EMPNO          --현장소장사번
              ,SIT_OMGR_NM          = p_SIT_OMGR_NM             --현장소장명
              ,INSP_BLN             = p_INSP_BLN                --점검자소속
              ,INSP_EMPNO           = p_INSP_EMPNO              --점검자
              ,INSP_NM              = p_INSP_NM                --점검자성명
              ,SAFT_MGR             = p_SAFT_MGR                --안전관리자
              ,SAFT_MGR_NM          = p_SAFT_MGR_NM            --안전관리자성명
              ,ORDPLC               = p_ORDPLC                  --발주처
              ,CNST_STR_DD          = p_CNST_STR_DD             --공사시작일
              ,CNST_END_DD          = p_CNST_END_DD             --공사종료일
              ,CNST_AMT             = p_CNST_AMT                --공사금액
              ,PROCRT               = p_PROCRT                  --공정율
              ,MBOT_PSNNO           = p_MBOT_PSNNO              --출역인원
              ,CNST_SCAL            = p_CNST_SCAL               --공사규모
              ,DISS_ACM             = p_DISS_ACM                --재해누계
              ,DISS_CY              = p_DISS_CY                 --재해당해
              ,SAFT_MCHR            = p_SAFT_MCHR               --계상안전관리비
              ,SAFT_ACM_AMT         = p_SAFT_ACM_AMT            --누계사용금액
              ,SAFT_USE_RT          = p_SAFT_USE_RT             --사용율
              ,WRK_MATT             = p_WRK_MATT                --작업사항
              ,TDAY_WRK             = p_TDAY_WRK                --금일작업
              ,SCH_WRK              = p_SCH_WRK                 --예정작업
              ,RVLT_SCR1            = p_RVLT_SCR1               --전회점수1
              ,RVLT_SCR2            = p_RVLT_SCR2               --전회점수2
              ,RVLT_SCR3            = p_RVLT_SCR3               --전회점수3
              ,RVLT_SCR4            = p_RVLT_SCR4               --전회점수4
              ,RVLT_SCR5            = p_RVLT_SCR5               --전회점수5
              ,TTM_SCR1             = p_TTM_SCR1                --금회점수1
              ,TTM_SCR2             = p_TTM_SCR2                --금회점수2
              ,TTM_SCR3             = p_TTM_SCR3                --금회점수3
              ,TTM_SCR4             = p_TTM_SCR4                --금회점수4
              ,TTM_SCR5             = p_TTM_SCR5                --금회점수5
              ,APRS_GRD1            = p_APRS_GRD1               --평가등급1
              ,APRS_GRD2            = p_APRS_GRD2               --평가등급2
              ,APRS_GRD3            = p_APRS_GRD3               --평가등급3
              ,APRS_GRD4            = p_APRS_GRD4               --평가등급4
              ,APRS_GRD5            = p_APRS_GRD5               --평가등급5
              ,RMKS1                = p_RMKS1                   --비고1
              ,RMKS2                = p_RMKS2                   --비고2
              ,RMKS3                = p_RMKS3                   --비고3
              ,RMKS4                = p_RMKS4                   --비고4
              ,RMKS5                = p_RMKS5                   --비고5
              ,EXCL_EXMP            = p_EXCL_EXMP               --우수사례
              ,MNG_MATT             = p_MNG_MATT                --관리사항
              ,ATFL_GRP             = p_ATFL_GRP                --첨부파일
              ,UPD_ID               = p_WRK_ID                  --수정ID 
              ,UPD_DTM              = SYSDATE()                 --수정일시
              ,UPD_IP               = p_WRK_IP                  --수정IP
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND CHK_DIV = p_CHK_DIV         --공통코드 : QSZ03
           AND CHK_DGR = p_CHK_DGR;        --점검차수
           
           
            IF (v_cnt <= 0)  THEN

            INSERT 
              INTO TQHA_HOCHKRPT_CK
                 ( SIT_CD               -- 현장코드
                 , CHK_DIV              -- 공통코드 : QSZ03
                 , CHK_DGR               -- 점검차수
                 , CHK_DT               -- 점검일자
                 , COM_CD               -- 공통코드 : QSZ03
                 , HO_CHK_DIV_CD        -- 공통코드 : QSZ0310
                 , HO_CHK_DIV_CD2       -- 본사점검구분코드
                 , HO_CHK_ITM_CD        -- 본사점검항목코드
                 , APRS_CHK 		    -- 공통코드 : QSA04
                 , APRS_PNDS
                 , IPT_ID               -- 신규입력ID
                 , IPT_DTM              -- 신규입력일시
                 , IPT_IP               -- 신규입력IP
                 , UPD_ID               -- 최종수정ID
                 , UPD_DTM              -- 최종수정일시
                 , UPD_IP               -- 최종수정IP
                 )
            SELECT 
		           p_SIT_CD             -- 현장코드
                 , p_CHK_DIV            -- 공통코드 : QSZ03
                 , p_CHK_DGR               -- 점검차수
                 , p_CHK_DT             -- 점검일자
                 , A.COM_CD
			     , A.HO_CHK_DIV_CD
			     , A.HO_CHK_DIV_CD2
			     , A.HO_CHK_ITM_CD
			      , NULL                 -- 공통코드 : QSA04
			     , A.MAX_SCORE
                 , p_WRK_ID             -- 입력ID
                 , SYSDATE()            -- 입력일시
                 , p_WRK_IP             -- 입력IP
                 , p_WRK_ID             -- 수정ID
                 , SYSDATE()            -- 수정일시
                 , p_WRK_IP             -- 수정IP
		   FROM TQHA_CKLST_ITM A,
		   (
		   	   SELECT HO_CHK_DIV_CD2
			   FROM TQHA_CKLST
			   WHERE COM_CD = p_CHK_DIV
			   AND HO_CHK_DIV_USE_YN = '1'
			   GROUP BY HO_CHK_DIV_CD2
		   ) B
		   WHERE A.HO_CHK_DIV_CD2 = B.HO_CHK_DIV_CD2
 		     AND A.HO_CHK_ITM_USE_YN = '1'
		   ORDER BY HO_CHK_DIV_CD, HO_CHK_ITM_CD
		   ;
		   
        END IF;
        
    ELSE 
    
    	SELECT NVL(MAX(CHK_DGR), 0) + 1 INTO v_SEQ
    	FROM TQHA_HOCHKRPT
    	WHERE SIT_CD = p_SIT_CD
          AND CHK_DIV = p_CHK_DIV;
    	
        INSERT INTO TQHA_HOCHKRPT
                   ( SIT_CD                  --현장코드
                    ,CHK_DIV                 --공통코드 : QSZ03
                    ,CHK_DGR                 --점검차수
                    ,CHK_DT                  --점검일자
                    ,QUARTER
                    ,MA_DT                   --조치기간
                    ,SIT_OMGR_EMPNO          --현장소장사번
                    ,SIT_OMGR_NM             --현장소장명
                    ,INSP_BLN                --점검자소속
                    ,INSP_EMPNO              --점검자
                    ,INSP_NM                --점검자성명
                    ,SAFT_MGR                --안전관리자
                    ,SAFT_MGR_NM            --안전관리자성명
                    ,ORDPLC                  --발주처
                    ,CNST_STR_DD             --공사시작일
                    ,CNST_END_DD             --공사종료일
                    ,CNST_AMT                --공사금액
                    ,PROCRT                  --공정율
                    ,MBOT_PSNNO              --출역인원
                    ,CNST_SCAL               --공사규모
                    ,DISS_ACM                --재해누계
                    ,DISS_CY                 --재해당해
                    ,SAFT_MCHR               --계상안전관리비
                    ,SAFT_ACM_AMT            --누계사용금액
                    ,SAFT_USE_RT             --사용율
                    ,WRK_MATT                --작업사항
                    ,TDAY_WRK                --금일작업
                    ,SCH_WRK                 --예정작업
                    ,RVLT_SCR1               --전회점수1
                    ,RVLT_SCR2               --전회점수2
                    ,RVLT_SCR3               --전회점수3
                    ,RVLT_SCR4               --전회점수4
                    ,RVLT_SCR5               --전회점수5
                    ,TTM_SCR1                --금회점수1
                    ,TTM_SCR2                --금회점수2
                    ,TTM_SCR3                --금회점수3
                    ,TTM_SCR4                --금회점수4
                    ,TTM_SCR5                --금회점수5
                    ,APRS_GRD1               --평가등급1
                    ,APRS_GRD2               --평가등급2
                    ,APRS_GRD3               --평가등급3
                    ,APRS_GRD4               --평가등급4
                    ,APRS_GRD5               --평가등급5
                    ,RMKS1                   --비고1
                    ,RMKS2                   --비고2
                    ,RMKS3                   --비고3
                    ,RMKS4                   --비고4
                    ,RMKS5                   --비고5
                    ,EXCL_EXMP               --우수사례
                    ,MNG_MATT                --관리사항
                    ,ATFL_GRP                --첨부파일
                    ,PRGS_STATS_CD1          --본사점검상태
                    ,APRV_NO1                --본사점검결재번호
                    ,PRGS_STATS_CD2          --조치결과상태
                    ,APRV_NO2                --조치결과결재번호
                    ,CLOSE_YN
                    ,IPT_ID                  --입력ID
                    ,IPT_DTM                 --입력일시
                    ,IPT_IP                  --입력IP
                    ,UPD_ID                  --수정ID
                    ,UPD_DTM                 --수정일시
                    ,UPD_IP                  --수정IP
                    )
             VALUES (p_SIT_CD                --현장코드
                    ,p_CHK_DIV               --공통코드 : QSZ03
                    ,v_SEQ                   --점검차수
                    ,p_CHK_DT                --점검일자
                    ,p_QUARTER
                    ,p_MA_DT                 --조치기간
                    ,p_SIT_OMGR_EMPNO        --현장소장사번
                    ,p_SIT_OMGR_NM           --현장소장명
                    ,p_INSP_BLN              --점검자소속
                    ,p_INSP_EMPNO            --점검자
                    ,p_INSP_NM              --점검자성명
                    ,p_SAFT_MGR              --안전관리자
                    ,p_SAFT_MGR_NM          --안전관리자성명
                    ,(SELECT LISTAGG(B.CUST_NM, ', ') WITHIN GROUP (ORDER BY B.CUST_NM) AS CUST_LIST
	                  FROM TCMZ_SIT_CLIENT A
	                       JOIN TCOA_TRADE   B ON B.CUST_CD = A.CUST_CD
	                 WHERE A.SIT_CD         = p_SIT_CD
	                   AND A.ORDPLC_DIV     = '1010'
	                 GROUP BY A.SIT_CD
	                )
                    ,p_CNST_STR_DD             --공사시작일
                    ,p_CNST_END_DD             --공사종료일
                    ,p_CNST_AMT                --공사금액
                    ,p_PROCRT                --공정율
                    ,p_MBOT_PSNNO            --출역인원
                    ,p_CNST_SCAL             --공사규모
                    ,p_DISS_ACM              --재해누계
                    ,p_DISS_CY               --재해당해
                    ,p_SAFT_MCHR             --계상안전관리비
                    ,p_SAFT_ACM_AMT          --누계사용금액
                    ,p_SAFT_USE_RT           --사용율
                    ,p_WRK_MATT              --작업사항
                    ,p_TDAY_WRK              --금일작업
                    ,p_SCH_WRK               --예정작업
                    ,p_RVLT_SCR1             --전회점수1
                    ,p_RVLT_SCR2             --전회점수2
                    ,p_RVLT_SCR3             --전회점수3
                    ,p_RVLT_SCR4             --전회점수4
                    ,p_RVLT_SCR5             --전회점수5
                    ,p_TTM_SCR1              --금회점수1
                    ,p_TTM_SCR2              --금회점수2
                    ,p_TTM_SCR3              --금회점수3
                    ,p_TTM_SCR4              --금회점수4
                    ,p_TTM_SCR5              --금회점수5
                    ,p_APRS_GRD1             --평가등급1
                    ,p_APRS_GRD2             --평가등급2
                    ,p_APRS_GRD3             --평가등급3
                    ,p_APRS_GRD4             --평가등급4
                    ,p_APRS_GRD5             --평가등급5
                    ,p_RMKS1                 --비고1
                    ,p_RMKS2                 --비고2
                    ,p_RMKS3                 --비고3
                    ,p_RMKS4                 --비고4
                    ,p_RMKS5                 --비고5
                    ,p_EXCL_EXMP             --우수사례
                    ,p_MNG_MATT              --관리사항
                    ,p_ATFL_GRP              --첨부파일
                    ,p_PRGS_STATS_CD1        --본사점검상태
                    ,p_APRV_NO1              --본사점검결재번호
                    ,p_PRGS_STATS_CD2        --조치결과상태
                    ,p_APRV_NO2              --조치결과결재번호
                    ,'0'
                    ,p_WRK_ID                --입력ID 
                    ,SYSDATE()               --입력일시
                    ,p_WRK_IP                --입력IP
                    ,p_WRK_ID                --수정ID
                    ,SYSDATE()               --수정일시
                    ,p_WRK_IP);              --수정IP                    
                   
                    
        IF (v_cnt <= 0)  THEN

            INSERT 
              INTO TQHA_HOCHKRPT_CK
                 ( SIT_CD               -- 현장코드
                 , CHK_DIV              -- 공통코드 : QSZ03
                 , CHK_DGR               -- 점검차수
                 , CHK_DT               -- 점검일자
                 , COM_CD               -- 공통코드 : QSZ03
                 , HO_CHK_DIV_CD        -- 공통코드 : QSZ0310
                 , HO_CHK_DIV_CD2       -- 본사점검구분코드
                 , HO_CHK_ITM_CD        -- 본사점검항목코드
                 , APRS_CHK 		    -- 공통코드 : QSA04
                 , APRS_PNDS
                 , IPT_ID               -- 신규입력ID
                 , IPT_DTM              -- 신규입력일시
                 , IPT_IP               -- 신규입력IP
                 , UPD_ID               -- 최종수정ID
                 , UPD_DTM              -- 최종수정일시
                 , UPD_IP               -- 최종수정IP
                 )
            SELECT 
		           p_SIT_CD             -- 현장코드
                 , p_CHK_DIV            -- 공통코드 : QSZ03
                 , v_SEQ                -- 점검차수
                 , p_CHK_DT             -- 점검일자
                 , A.COM_CD
			     , A.HO_CHK_DIV_CD
			     , A.HO_CHK_DIV_CD2
			     , A.HO_CHK_ITM_CD
			     , CASE WHEN A.HO_CHK_DIV_CD2 IN ('QS073010101', 'QS073010102', 'QS073010201', 'QS073010202') THEN 'QS0740202' 
				         WHEN A.HO_CHK_DIV_CD2 IN ('QS073010103', 'QS073010203', 'QS073020101', 'QS073020102','QS073020103') THEN 'QS0740102' 
			       ELSE NULL END
			     , A.MAX_SCORE
                 , p_WRK_ID             -- 입력ID
                 , SYSDATE()            -- 입력일시
                 , p_WRK_IP             -- 입력IP
                 , p_WRK_ID             -- 수정ID
                 , SYSDATE()            -- 수정일시
                 , p_WRK_IP             -- 수정IP
		   FROM TQHA_CKLST_ITM A,
		   (
		   	   SELECT HO_CHK_DIV_CD2
			   FROM TQHA_CKLST
			   WHERE 1=1
			    AND (
				       ( SUBSTR(p_CHK_DIV, 1, 7) = 'QS07301' AND COM_CD = p_CHK_DIV ) OR ( SUBSTR(p_CHK_DIV, 1, 7) = 'QS07302' AND HO_CHK_DIV_CD2 = p_CHK_DIV )
			        )
			   AND HO_CHK_DIV_USE_YN = '1'
			   GROUP BY HO_CHK_DIV_CD2
		   ) B
		   WHERE A.HO_CHK_DIV_CD2 = B.HO_CHK_DIV_CD2
 		     AND A.HO_CHK_ITM_USE_YN = '1'
		   ORDER BY HO_CHK_DIV_CD, HO_CHK_ITM_CD
		   ;
            
            -- 점수
            UPDATE TQHA_HOCHKRPT_CK M
				SET M.APRS_SCR = CASE WHEN HO_CHK_DIV_CD2 IN ('QS073010101', 'QS073010102', 'QS073010201', 'QS073010202') 
											THEN APRS_PNDS * ((SELECT NO_VAL_1 FROM TCOA_COMCODE WHERE COM_CD = 'QS0740202') / 100) -- 항목4개
							          WHEN HO_CHK_DIV_CD2 IN ('QS073010103', 'QS073010203', 'QS073020101', 'QS073020102','QS073020103') 
							          		THEN APRS_PNDS * ((SELECT NO_VAL_1 FROM TCOA_COMCODE WHERE COM_CD = 'QS0740102') / 100) --항목 3개
						         ELSE NULL END
			 WHERE M.SIT_CD  = p_SIT_CD
			   AND M.CHK_DIV = p_CHK_DIV
			   AND M.CHK_DGR = v_SEQ;            
            
            
            -- 총점
            UPDATE TQHA_HOCHKRPT M
			SET -- 1. 전회점수 (이전 차수 데이터가 없으면 0)
		       (M.RVLT_SCR1, M.RVLT_SCR2, M.RVLT_SCR3, M.RVLT_SCR4, M.RVLT_SCR5) = 
		       (
		           SELECT NVL(MAX(PREV.TTM_SCR1), 0)
		                , NVL(MAX(PREV.TTM_SCR2), 0)
		                , NVL(MAX(PREV.TTM_SCR3), 0)
		                , NVL(MAX(PREV.TTM_SCR4), 0)
		                , NVL(MAX(PREV.TTM_SCR5), 0)
		             FROM TQHA_HOCHKRPT PREV
		            WHERE PREV.SIT_CD  = p_SIT_CD
		              AND PREV.CHK_DIV = p_CHK_DIV
		              AND PREV.CHK_DGR = v_SEQ - 1
		       )
		       
		     -- 2. 금회점수 (별칭을 부여해 구조를 단순화)
		     , (M.TTM_SCR1, M.TTM_SCR2, M.TTM_SCR3, M.TTM_SCR4, M.TTM_SCR5) = 
		       (
		             SELECT G.V1, G.V2, G.V3, G.V4
		                  , G.V1 + G.V2 + G.V3 
		             FROM (
		                   SELECT NVL(MAX(CASE WHEN SUBSTR(CK.HO_CHK_DIV_CD2, -1) = '1' THEN CK.SM_SCR END), 0) AS V1
		                        , NVL(MAX(CASE WHEN SUBSTR(CK.HO_CHK_DIV_CD2, -1) = '2' THEN CK.SM_SCR END), 0) AS V2
		                        , NVL(MAX(CASE WHEN SUBSTR(CK.HO_CHK_DIV_CD2, -1) = '3' THEN CK.SM_SCR END), 0) AS V3
		                        , 0 AS V4
		                     FROM (
		                           SELECT HO_CHK_DIV_CD2
		                                , SUM(APRS_SCR) AS SM_SCR
		                             FROM TQHA_HOCHKRPT_CK
		                            WHERE SIT_CD  = p_SIT_CD
		                              AND CHK_DIV = p_CHK_DIV
		                              AND CHK_DGR = v_SEQ
		                            GROUP BY SIT_CD, CHK_DIV, CHK_DGR, HO_CHK_DIV_CD2
		                          ) CK
		                  ) G
		       )
		     
			 WHERE M.SIT_CD  = p_SIT_CD
			   AND M.CHK_DIV = p_CHK_DIV
			   AND M.CHK_DGR = v_SEQ;
            
        END IF;
        
        -- 공사관련 값 가져오기
        MERGE INTO TQHA_HOCHKRPT H
		USING (
		    WITH CM_SIT AS (
		        -- [A] 기본 현장 정보 및 출역인원 조회 (전달해주신 쿼리 기반)
		        SELECT A1.SIT_CD
		             , A1.CNST_STR_DT                              AS CNST_STR_DD
		             , A1.CNST_END_DT                              AS CNST_END_DD
		              , A1.CNST_CMPD                                AS CNST_SCAL
		             , (SELECT SUM(IPT_PCNT) 
		                  FROM TCMW_WRK_MBOT 
		                 WHERE SIT_CD = p_SIT_CD)                 AS MBOT_PSNNO             
		             , B1.OCO_UNTKSO_SUM_AMT AS CNST_AMT
		--             
		--             , TO_CHAR(CASE WHEN NVL(B1.TOT_UNTK_SPLCM_AMT,0) = 0
		--	                   THEN 0
		--                        ELSE ROUND(NVL(B1.OCO_UNTK_SPLCM_AMT,0) * 1.0 /
		--                             NVL(B1.TOT_UNTK_SPLCM_AMT,0) * 100, 2)
		--               END, 'FM999,999,990.00')                     AS PROCRT --지분율(공사)
		--               
		          FROM TCMZ_SIT A1
		         INNER JOIN TCMZ_SIT_CONT B1
		            ON A1.SIT_CD = B1.SIT_CD
		         WHERE A1.SIT_CD = p_SIT_CD
		    ),
		    SAFT_DATA AS (
		        -- [B] 안전관리비 및 재해 현황 데이터 집계
		        SELECT 
		            A.SIT_CD,
		            NVL(I.APRP_SAFT_MCHR, 0) AS APRP_SAFT_MCHR,
		            NVL(B.C_USE_AMT, 0) AS C_USE_AMT,
		            ROUND(NVL(B.C_USE_AMT, 0) / DECODE(I.APRP_SAFT_MCHR, 0, NULL, I.APRP_SAFT_MCHR) * 100, 2) AS APRP_USE_RATE,
		           '사망 : '||D.YTD_DEAD_CNT||'명 / 부상 : '||D.YTD_INJ_CNT||'명' AS YTD_DSS_CNT,
				   '사망 : '||D.TOTAL_DEAD_CNT||'명 / 부상 : '||D.TOTAL_INJ_CNT||'명' AS TOTAL_DSS_CNT
		        FROM (
		            SELECT SIT_CD
		              FROM TQHA_SAFECOST_BGTYM
		             WHERE SIT_CD = p_SIT_CD
		               AND SUBSTR(RLV_YM, 1, 4) <= SUBSTR(p_CHK_DT, 1, 4)
		             GROUP BY SIT_CD
		        ) A
		        LEFT JOIN (
		            SELECT SIT_CD
		                 , SUM(C_USE_AMT) AS C_USE_AMT
		              FROM (
		                  SELECT SIT_CD
		                       , SUM(USE_AMT) AS C_USE_AMT  
		                    FROM TQHA_SAFECOST_ARSLT
		                   WHERE SIT_CD = p_SIT_CD
		                     AND SUBSTR(RLV_YM, 1, 4) <= SUBSTR(p_CHK_DT, 1, 4)
		                   GROUP BY SIT_CD
		                   UNION ALL
		                  SELECT A.SIT_CD
		                       , SUM(A.USE_AMT) AS C_USE_AMT 
		                    FROM TQHA_SAFECOST_ARSLT_CO A
		                    LEFT JOIN TQHA_SAFECOST_MMARSLT_CO B 
		                      ON A.SIT_CD   = B.SIT_CD
		                     AND A.CUST_CD  = B.CUST_CD
		                     AND A.VNDR_SEQ = B.VNDR_SEQ
		                     AND A.RLV_YM   = B.RLV_YM
		                   WHERE A.SIT_CD = p_SIT_CD
		                     AND SUBSTR(A.RLV_YM, 1, 4) <= SUBSTR(p_CHK_DT, 1, 4)
		                     AND B.SITE_APRV_YN = '1'
		                   GROUP BY A.SIT_CD
		              )
		             GROUP BY SIT_CD
		        ) B ON A.SIT_CD = B.SIT_CD
		        LEFT JOIN TQHA_SAFECOST_INFO I ON A.SIT_CD = I.SIT_CD
		        LEFT JOIN (
		            SELECT SIT_CD 
		                 ,SUM(CASE WHEN SUBSTR(ACCD_DT, 1, 4) = SUBSTR(p_CHK_DT, 1, 4) THEN DSS_CNT ELSE 0 END)     AS YTD_DSS_CNT     -- 당해 재해자수
					     ,SUM(CASE WHEN SUBSTR(ACCD_DT, 1, 4) = SUBSTR(p_CHK_DT, 1, 4) THEN DEAD_CNT ELSE 0 END)    AS YTD_DEAD_CNT    -- 당해 사망자수
					     ,SUM(CASE WHEN SUBSTR(ACCD_DT, 1, 4) = SUBSTR(p_CHK_DT, 1, 4) THEN INJ_CNT ELSE 0 END)     AS YTD_INJ_CNT     -- 당해 부상자수
					     ,SUM(CASE WHEN SUBSTR(ACCD_DT, 1, 4) = SUBSTR(p_CHK_DT, 1, 4) THEN OCC_DIS_CNT ELSE 0 END) AS YTD_OCC_DIS_CNT -- 당해 직업병수
					     -- ==========================================
					     -- 2. 전체 누계 (과거 전체 기간 합산)
					     -- ==========================================
					     ,SUM(DSS_CNT)     AS TOTAL_DSS_CNT     -- 전체 누계 재해자수
					     ,SUM(DEAD_CNT)    AS TOTAL_DEAD_CNT    -- 전체 누계 사망자수
					     ,SUM(INJ_CNT)     AS TOTAL_INJ_CNT     -- 전체 누계 부상자수
					     ,SUM(OCC_DIS_CNT) AS TOTAL_OCC_DIS_CNT -- 전체 누계 직업병수			     
		              FROM TQHA_IDAC
		             WHERE SIT_CD = p_SIT_CD
		             GROUP BY SIT_CD
		        ) D ON A.SIT_CD = D.SIT_CD
		    )
		    -- [C] 업데이트에 매핑할 원천 데이터 결합
		    SELECT 
		        H.ROWID AS RID,
		        C.CNST_STR_DD,
		        C.CNST_END_DD,
		        C.CNST_AMT,
		        --C.PROCRT,
		        C.CNST_SCAL,
		        C.MBOT_PSNNO,
		        S.TOTAL_DSS_CNT                      AS DISS_ACM,
		        S.YTD_DSS_CNT                        AS DISS_CY,
		        S.APRP_SAFT_MCHR                     AS SAFT_MCHR,
		        S.C_USE_AMT                          AS SAFT_ACM_AMT,
		        S.APRP_USE_RATE                      AS SAFT_USE_RT
		    FROM TQHA_HOCHKRPT H
		    LEFT JOIN CM_SIT C    ON H.SIT_CD = C.SIT_CD
		    LEFT JOIN SAFT_DATA S ON H.SIT_CD = S.SIT_CD
		    WHERE H.SIT_CD = p_SIT_CD
		      AND H.CHK_DIV = p_CHK_DIV
		      AND H.CHK_DGR = p_CHK_DGR
		) U
		ON (H.ROWID = U.RID)
		WHEN MATCHED THEN
		UPDATE SET 
		    H.CNST_STR_DD  = U.CNST_STR_DD,     -- 공사시작일
		    H.CNST_END_DD  = U.CNST_END_DD,     -- 공사종료일
		    H.CNST_AMT     = U.CNST_AMT,        -- 공사금액
		    --H.PROCRT       = U.PROCRT,          -- 공정율
		    H.CNST_SCAL    = U.CNST_SCAL,       -- 공사규모
		    H.MBOT_PSNNO   = U.MBOT_PSNNO,      -- 출역인원
		    H.DISS_ACM     = U.DISS_ACM,        -- 재해누계 (전체 누계 재해자수)
		    H.DISS_CY      = U.DISS_CY,         -- 재해당해 (당해 재해자수)
		    H.SAFT_MCHR    = U.SAFT_MCHR,       -- 계상안전관리비
		    H.SAFT_ACM_AMT = U.SAFT_ACM_AMT,    -- 누계사용금액
		    H.SAFT_USE_RT  = U.SAFT_USE_RT      -- 사용율
		;
    
        
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END PQHA_HOCHKRPT_S;
/

-- PQHA_HODCAB_S
DROP PROCEDURE "PQHA_HODCAB_S";
CREATE PROCEDURE "PQHA_HODCAB_S" 
                            (p_WRK_TP  VARCHAR2 :='U'                                     -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
                            ,p_WRK_ID  VARCHAR2                                           -- 사용자 ID
                            ,p_WRK_IP  VARCHAR2                                           -- 사용자 IP
                            ,p_WRT_DT TQHA_HODCAB.WRT_DT%TYPE                             -- 작성일자
                            ,p_SEQ TQHA_HODCAB.SEQ%TYPE                                   -- 순번
                            ,p_TTL TQHA_HODCAB.TTL%TYPE                                   -- 제목
                            ,p_WRTR_EMPNO TQHA_HODCAB.WRTR_EMPNO%TYPE                     -- 작성자사번
                            ,p_WRTR_PNM TQHA_HODCAB.WRTR_PNM%TYPE                         -- 작성자성명
                            ,p_REQ_DT TQHA_HODCAB.REQ_DT%TYPE                             -- 요청일자
                            ,p_SNSB_YN TQHA_HODCAB.SNSB_YN%TYPE                           -- 가감점대상
                            ,p_CMPL_YN TQHA_HODCAB.CMPL_YN%TYPE                           -- 완료여부
                            ,p_CMPL_DT TQHA_HODCAB.CMPL_DT%TYPE                           -- 완료일자
                            ,p_ATFL_GRP TQHA_HODCAB.ATFL_GRP%TYPE                         -- 완료일자
                            )
IS
    /**************************************************************************************************************************
      Purpose : 

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2019/05/03 10:39:10                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR(200);             -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_SEQ  TQHA_SITEDOC.SEQ%TYPE;
    v_OBJ_YN       VARCHAR(1);              -- 대상여부

    v_SBM_YN_CNT    NUMBER;              -- 제출여부
    v_ATFL_CNT      NUMBER;              -- 첨부파일유무

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRT_DT IS NULL)  THEN
        ERR_MSG := '작성일자는 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_TTL IS NULL)  THEN
        ERR_MSG := '제목은 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_REQ_DT IS NULL)  THEN
        ERR_MSG := '제출기한은 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN

        --1. 특정 문서함의 대상현장중 제출된 경우 확인
        SELECT COUNT(1)
          INTO v_SBM_YN_CNT
          FROM TQHA_SITEDOC
         WHERE 1=1
           AND WRT_DT = p_WRT_DT
           AND SEQ = p_SEQ
           AND SBM_YN = '1';

        IF (v_SBM_YN_CNT >  0)  THEN
            ERR_MSG := '작성일자 ' || p_WRT_DT || '의 순번 ' || p_SEQ || '은(는) '||CHR(13)||CHR(10) || '제출되었으므로 삭제할 수 없습니다.';
            RAISE USER_EXCEPTION;
        END IF;

        --2. 특정 문서함의 대상현장중 제출하지 않았지만 첨부파일이 있는 경우 확인
       SELECT COUNT(1)
         INTO v_ATFL_CNT
         FROM TQHA_SITEDOC AA
            , TCOZ_ATFL BB
        WHERE 1=1
          AND AA.ATFL_GRP = BB.ATFL_GRP(+)
          AND AA.WRT_DT = p_WRT_DT
          AND AA.SEQ = p_SEQ
          AND AA.ATFL_GRP IS NOT NULL;

        IF (v_ATFL_CNT >  0)  THEN
            ERR_MSG := '작성일자 ' || p_WRT_DT || '의 순번 ' || p_SEQ || '은(는) '||CHR(13)||CHR(10) || '첨부파일 작업중인 현장이 있으므로 삭제할 수 없습니다.';
            RAISE USER_EXCEPTION;
        END IF;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN
        DELETE
          FROM TQHA_HODCAB
         WHERE WRT_DT = p_WRT_DT          --작성일자
           AND SEQ = p_SEQ;

        DELETE
          FROM TQHA_SITEDOC
         WHERE WRT_DT = p_WRT_DT           --작성일자
           AND SEQ = p_SEQ ;        

    ELSIF (p_WRK_TP ='U') THEN

        -- 본부
        UPDATE TQHA_HODCAB
           SET TTL                  = p_TTL                     --제목
              ,WRTR_EMPNO           = p_WRTR_EMPNO              --작성자사번
              ,WRTR_PNM             = p_WRTR_PNM                --작성자성명
              ,REQ_DT               = p_REQ_DT                  --요청일자
              ,SNSB_YN              = p_SNSB_YN                 --가감점대상
              ,CMPL_YN              = p_CMPL_YN                 --완료여부
              ,CMPL_DT              = p_CMPL_DT                 --완료일자
              ,UPD_ID               = p_WRK_ID                  --수정ID
              ,UPD_DTM              = SYSDATE()                 --수정일시
              ,UPD_IP               = p_WRK_IP                  --수정IP
         WHERE WRT_DT = p_WRT_DT                                --작성일자
           AND SEQ = p_SEQ;                                     --순번

        -- 현장
        UPDATE TQHA_SITEDOC
           SET CMPL_YN              = p_CMPL_YN                 --완료여부
              ,CMPL_DT              = p_CMPL_DT                 --완료일자
              ,UPD_ID               = p_WRK_ID                  --수정ID
              ,UPD_DTM              = SYSDATE()                 --수정일시
              ,UPD_IP               = p_WRK_IP                  --수정IP
         WHERE WRT_DT = p_WRT_DT                                --작성일자
           AND SEQ = p_SEQ;                                     --순번
           
    ELSIF (p_WRK_TP ='ATFL') THEN

        -- 본부
        UPDATE TQHA_HODCAB
           SET 
               ATFL_GRP             = p_ATFL_GRP                
              ,UPD_ID               = p_WRK_ID                  --수정ID
              ,UPD_DTM              = SYSDATE()                 --수정일시
              ,UPD_IP               = p_WRK_IP                  --수정IP
         WHERE WRT_DT = p_WRT_DT                                --작성일자
           AND SEQ = p_SEQ;                                     --순번

    ELSE

        SELECT NVL(MAX(SEQ), 0) + 1  INTO v_SEQ
              FROM TQHA_HODCAB
             WHERE 1=1
               AND WRT_DT = p_WRT_DT;

        INSERT INTO TQHA_HODCAB
                   ( WRT_DT                  --작성일자
                    ,SEQ                     --순번
                    ,TTL                     --제목
                    ,WRTR_EMPNO              --작성자사번
                    ,WRTR_PNM                --작성자성명
                    ,REQ_DT                  --요청일자
                    ,SNSB_YN                 --가감점대상
                    ,CMPL_YN                 --완료여부
                    ,CMPL_DT                 --완료일자
                    ,IPT_ID                  --신규입력ID
                    ,IPT_DTM                 --신규입력일시
                    ,IPT_IP                  --신규입력IP
                    ,UPD_ID                  --최종수정ID
                    ,UPD_DTM                 --최종수정일시
                    ,UPD_IP)                 --최종수정IP
             VALUES (p_WRT_DT                --작성일자
                    ,v_SEQ                   --순번
                    ,p_TTL                   --제목
                    ,p_WRTR_EMPNO            --작성자사번
                    ,p_WRTR_PNM              --작성자성명
                    ,p_REQ_DT                --요청일자
                    ,p_SNSB_YN               --가감점대상
                    ,p_CMPL_YN               --완료여부
                    ,p_CMPL_DT               --완료일자
                    ,p_WRK_ID                --입력ID
                    ,SYSDATE()               --입력일시
                    ,p_WRK_IP                --입력IP
                    ,p_WRK_ID                --수정ID
                    ,SYSDATE()               --수정일시
                    ,p_WRK_IP);              --수정IP

        --현장별 더미데이터 입력

        FOR RI IN (
                    SELECT SIT_CD
                         , FQHA_GETDEPTNM_BY_DEPTCD(SIT_CD) AS SIT_NM
                    FROM TQHA_SAFT_SIT
                    WHERE SIT_TERR != 'QSZ0599'
                  )
            LOOP

                INSERT INTO TQHA_SITEDOC (
                                WRT_DT
                              , SEQ
                              , SIT_CD
                              , SIT_NM
                              , TERR_CD
                              , OBJ_YN
                              , SBM_YN
                              , SBM_DT
                              , CMPL_YN
                              , CMPL_DT
                              , ATCH_YN
                              , ATFL_GRP
                              , IPT_ID
                              , IPT_DTM
                              , IPT_IP
                              , UPD_ID
                              , UPD_DTM
                              , UPD_IP
                            )
                       VALUES(
                                p_WRT_DT
                              , v_SEQ
                              , RI.SIT_CD
                              , RI.SIT_NM
                              , NULL        --TERR_CD
                              , NULL
                              , NULL        --SBM_YN
                              , NULL        --SBM_DT
                              , NULL        --CMPL_YN
                              , NULL        --CMPL_DT
                              , NULL        --ATCH_YN
                              , NULL        --ATFL_GRP
                              , p_WRK_ID
                              , SYSDATE()
                              , p_WRK_ID
                              , p_WRK_ID
                              , SYSDATE()
                              , p_WRK_IP
                              );

            END LOOP;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END;
/

-- PQHA_IDAC_Q
DROP PROCEDURE "PQHA_IDAC_Q";
CREATE PROCEDURE "PQHA_IDAC_Q" (
    p_WRK_TP                VARCHAR2 DEFAULT 'Q'                -- FLAG( Q: SELECT )
,   p_SIT_CD                TQHA_IDAC.SIT_CD        %TYPE       -- 현장코드
,   p_ACCD_SEQ              TQHA_IDAC.ACCD_SEQ      %TYPE       -- 사고순번
,   p_SEARCH_ACCD_YM_FR     TQHA_IDAC.ACCD_DT       %TYPE       -- 사고시작일자
,   p_SEARCH_ACCD_YM        TQHA_IDAC.ACCD_DT       %TYPE       -- 사고종료일자 
,   RTN_CURSOR              OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : QSE > 안전관리 > 안전서류관리 > 산재관리(현장/본사) 조회 

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2023/11/28 10:51:46                         최초생성
      1.1       2024/03/22 16:00:00 정우성                      새로 생성된 칼럼들 추가
      1.2       2024/03/25 16:00:00 정우성                      칼럼을 재해발생유형으로 변경
      1.3     2024/04/03 13:00:00 정우성                      사망/부상자수 칼럼 추가

    Q1 : 산재목록(현장)
    Q2 : 산재작성(현장)
    Q3 : 산재목록(본사)
    Q4 : 산재작성(본사)
    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리
    ---------------------------------------------------------------------------------------------------------------------------
    -- get_IndustAcciSiteLstList >> 산재목록(현장)
    IF (p_WRK_TP = 'Q1') THEN

       -- 현장 목록
        OPEN RTN_CURSOR FOR
        SELECT  A.SIT_CD                 --현장코드
	           ,A.ACCD_SEQ                 --사고순번
	           ,A.ACCD_DT                 --사고일자
	           ,A.ACCD_TIME                 --사고시간
	           ,TO_CHAR(TO_DATE(A.ACCD_DT||A.ACCD_TIME, 'YYYYMMDDHH24MI'), 'YYYY-MM-DD HH24:MI')  AS ACCD_DTM
	           ,A.DSVC                 --성명
	           ,A.DSVC_ADDR                 --주소_개인정보 암호화
	           ,A.DSVC_VNDR                 --소속회사
	           ,A.DSVC_HIRDT                 --입사일자
	           ,A.DSVC_RSDNNO                 --재해자_주민번호(개인정보 암호화)
	           ,A.DSVC_MP                 --재해자_휴대폰
	           ,A.DSVC_SEX                 --재해자_성별 ( 1 남성, 0 여성)
	           ,A.DSVC_NATL                 --재해자_국적
	           ,A.DSVC_STYQLF                 --재해자_체류자격
	           ,A.DSVC_JBCLS                 --재해자_직종
	           ,A.DSVC_SKND                 --재해자_동종근무경력
	           ,A.DSVC_EMP                 --재해자_고용형태
	           ,A.DSVC_119                 --119신고여부
	           ,A.DSVC_DAYOFF                 --휴일예상일수
	           ,A.IDAC_TP                 --산재유형(공통코드)  -> 재해발생유형으로 변경 ( 미사용);
	           ,A.ACCD_CONTX                 --대쉬보드의 발생내용으로 사용
	           ,A.INJR_XTNT                 --상해정도
	           ,A.ACCD_CSE                 --사고원인
	           ,A.ACCD_CPLN                 --사고대책
	           ,A.SITE_OMGR                 --현장소장
	           ,A.RT_SITE                 --과실비율 현장소장
	           ,A.CNST_TMGR                 --공사팀장
	           ,A.RT_CONT                 --과실비율 공사팀장
	           ,A.CNST_PSN                 --공사담당자
	           ,A.RT_PSN                 --과실비율 공사담당자
	           ,A.SAFT_MGR                 --안전관리자
	           ,A.RT_SAFE                 --과실비율 안전관리자
	           ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SITE_OMGR ) AS SITE_OMGR_NM     -- 현장소장명
	           ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.CNST_TMGR ) AS CNST_TMGR_NM     -- 공사팀장명
	           ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.CNST_PSN )  AS CNST_PSN_NM      -- 공사담당자명
	           ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SAFT_MGR )  AS SAFT_MGR_NM      -- 안전관리자명
	           ,A.CUST_CD                 --거래처코드
	           ,A.VNDR_SEQ                 --업체순번
	           ,A.RT_VNDR                 --과실비율 협력업체
	           ,A.TOP7_DISS                 --TOP7재해(미사용)
	           ,A.SERI_DISS                 --중대재해(미사용)
	           ,A.MAIN_CHK                 --주관사여부
	           ,A.BE_CAUSED                 --기인물
	           ,A.INJR_KIND                 --상해종류(질병명)
	           ,A.INJR_PART                 --상해부위(질병부위)
	           ,A.ACCD_WHO                 --누가
	           ,A.ACCD_WHERE                 --어디서
	           ,A.ACCD_WHAT                 --무엇을
	           ,A.ACCD_HOW                 --어떻게
	           ,A.ACCD_WHY                 --왜
	           ,A.DISS_DIV                 --재해구분,공통코드(QS050)
	           ,A.RMKS                 --비고
	           ,A.DSVC_INSURER                 --근재보험사
	           ,A.DSS_CNT                 --재해자수
	           ,A.DEAD_CNT                 --사망자수
	           ,A.INJ_CNT                 --부상자수
	           ,A.OCO_YN                 --당사여부
	           ,A.DIS_CD                 --발생형태코드
	           ,A.PHOTO_GRP1                 --첨부파일그룹사진1
	           ,A.PHOTO_DESC_1                 --사진설명1
	           ,A.PHOTO_GRP2                 --첨부파일그룹사진2
	           ,A.PHOTO_DESC_2                 --사진설명2
	           ,A.PHOTO_GRP3                 --첨부파일그룹사진3
	           ,A.PHOTO_DESC_3                 --사진설명3
	           ,A.PHOTO_GRP4                 --첨부파일그룹사진4
	           ,A.PHOTO_DESC_4                 --사진설명4
	           ,A.ATFL_GRP                 --첨부파일그룹
	           ,A.ATFL_GRP2                 --첨부파일그룹
--	           ,A.BZ_HQ                 --사업본부
	           ,FQHA_GET_TELNO(A.SITE_TEL_NO) AS SITE_TEL_NO --현장전화번호
	           ,A.EMP_CNT                 --근로자수
	           ,A.PROCRT                 --공정율
	           ,A.TOT_CNST_AMT                 --총공사금액
	           ,A.WTS_NM1                 --목격자1
	           ,A.WTS_NM2                 --목격자2
	           ,A.WTS_NM3                 --목격자3
	           ,A.SAFT_EDU_CMPL_DT                 --안전교육 이수일자
	           ,A.OCC_DIS_CNT                 --직업병수
	           ,A.IDRT_TECH                 --간접적원인_기술
	           ,A.IDRT_EDU                 --간접적원인_교육
	           ,A.IDRT_WRK                 --간접적원인_작업관리
	           ,A.DRT_UNSF_STATS                 --직접적원인_불안전상태(물적)
	           ,A.DRT_UNSF_ACT                 --직접적원인_불안전행동(인적)
	           ,A.DFT_DOC                 --기인물
	           ,A.RPT_DT                 --보고일자
	           ,A.ACP_DT                 --접수일자
	           ,A.MA_MATT                 --조치사항
	           ,A.MED_ORG                 --의료기관명
	           ,FQHA_GET_TELNO(A.MED_CADDR) AS MED_CADDR --의료기관 연락처
	           ,A.ETC_MATT                 --기타사항
	           ,A.DISS_TYPE
	           ,A.DSVC_AGE
	           ,A.DISS_DIV_ETC
	           ,A.APRV_NO                 --현장 결재번호
	           ,A.APRV_NO_GW                 --본사 결재번호
             , C.APRS_DIV           -- 산재명
             , D.DIS_NM             -- 세부산재명
             , NVL(F.CUST_NM, A.DSVC_VNDR)      AS CUST_NM          -- 거래처명
             , ''                   			AS OCO_NM           --당사명
             , TO_CHAR(A.IPT_DTM, 'YYYYMMDD')   AS IPT_DTM
             , E.APRV_STATS         -- 현장결재 결재상태
             , G.CD_NM                          AS APRV_STATS_NM    -- 현장결재 결재상태명             
          FROM TQHA_IDAC            A
             , TQHA_DISASTER_DIV    C
             , TQHA_DISASTER_CD     D
             , TQHA_APRV            E
             , TCOA_TRADE           F
             , TCOA_COMCODE         G
         WHERE 1=1
           AND A.SIT_CD         = p_SIT_CD
           AND A.ACCD_DT        BETWEEN NVL(p_SEARCH_ACCD_YM_FR,'19000101') AND p_SEARCH_ACCD_YM
           AND C.DIV_CD         = D.DIV_CD
           AND D.DIS_CD         = A.DIS_CD
           AND A.SIT_CD         = E.SIT_CD(+)
           AND A.APRV_NO        = E.APRV_NO (+)
           AND A.CUST_CD        = F.CUST_CD(+)
           AND E.APRV_STATS     = G.COM_CD(+)
           AND G.HRNK_CD(+)     = 'QS031'
         ORDER BY A.ACCD_DT DESC
        ;

    -- 본사 목록
    ELSIF (p_WRK_TP = 'Q2') THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD             -- 현장코드
             ,( SELECT CNST_NM FROM VQSZ_SITEINFO WHERE SIT_CD = A.SIT_CD )    AS SIT_NM       -- 현장명칭
             , A.ACCD_SEQ           -- 사고순번
             , A.ACCD_DT            -- 사고일자
             , A.ACCD_TIME          -- 사고시간
             , A.DSVC               -- 재해자명 (개인정보 암호화)
             , A.DSVC_ADDR          -- 재해자 주소 (개인정보 암호화)
             , A.DSVC_VNDR          -- 재해자 업체 및 직종 (개인정보 암호화)
             , A.DSVC_HIRDT         -- 재해자 취업일 (개인정보 암호화)
             , A.ACCD_CONTX         -- 사고경위
             , A.DIS_CD             -- 산재유형
             , C.APRS_DIV           -- 산재명
             , D.DIS_NM             -- 세부산재명
             , CASE A.MAIN_CHK WHEN '0'  THEN '비주관사' WHEN '1'  THEN '주관사' ELSE '선택되지않음' END AS MAIN_CHK        -- 주관사여부 (1:주관사, 0:비주관사)
             , A.MA_MATT            -- 조치사항
             , A.ACCD_CSE           -- 사고원인
             , A.ACCD_CPLN          -- 사고대책
             , A.PHOTO_GRP1         -- 사진첨부1
             , A.PHOTO_DESC_1       -- 사진설명1
             , A.PHOTO_GRP2         -- 사진첨부2
             , A.PHOTO_DESC_2       -- 사진설명2
             , A.ATFL_GRP           -- 첨부파일그룹
             , A.ATFL_GRP2          --첨부파일그룹
             , A.APRV_NO            -- 결재번호
             , A.CUST_CD            -- 거래처번호
             , A.VNDR_SEQ           -- 업체순번
             , A.OCO_YN             -- 재해자구분
             , A.DISS_TYPE
             , A.DSVC_AGE
             , A.DISS_DIV_ETC
             , NVL(F.CUST_NM, A.DSVC_VNDR)      AS CUST_NM          -- 거래처명
             , ''                   			AS OCO_NM           --당사명
             , TO_CHAR(A.IPT_DTM, 'YYYYMMDD')   AS IPT_DTM
             , E.APRV_STATS         -- 현장결재 결재상태
             , G.CD_NM                          AS APRV_STATS_NM    -- 현장결재 결재상태명
            ,( 
	            SELECT CD_NM
				FROM TCOA_COMCODE
				WHERE HRNK_CD = 'CO91'
				AND COM_CD = (SELECT APRV_STATS FROM TCOF_APPROVE WHERE APRV_NO = A.APRV_NO_GW)
			) AS APRV_STATS_GW 
          FROM TQHA_IDAC            A
             , TQHA_DISASTER_DIV    C
             , TQHA_DISASTER_CD     D
             , TQHA_APRV            E
             , TCOA_TRADE           F
             , TCOA_COMCODE         G
         WHERE 1=1
           AND A.SIT_CD         LIKE '%'||p_SIT_CD
           AND A.ACCD_DT        BETWEEN NVL(p_SEARCH_ACCD_YM_FR,'19000101') AND p_SEARCH_ACCD_YM
           AND C.DIV_CD         = D.DIV_CD
           AND D.DIS_CD         = A.DIS_CD
           AND A.SIT_CD         = E.SIT_CD(+)
           AND A.APRV_NO        = E.APRV_NO (+)
           AND A.CUST_CD        = F.CUST_CD(+)
           AND E.APRV_STATS     = G.COM_CD(+)
           AND G.HRNK_CD(+)     = 'QS031'
           --AND E.APRV_STATS = '4'
         ORDER BY A.ACCD_DT DESC
        ;        
        
    -- 상세
    ELSIF (p_WRK_TP = 'Q3') THEN

        OPEN RTN_CURSOR FOR
        SELECT  A.SIT_CD                 --현장코드
	           ,A.ACCD_SEQ                 --사고순번
	           ,A.ACCD_DT                 --사고일자
	           ,A.ACCD_TIME                 --사고시간
	           ,A.DSVC                 --성명
	           ,A.DSVC_ADDR                 --주소_개인정보 암호화
	           ,A.DSVC_VNDR                 --소속회사
	           ,A.DSVC_HIRDT                 --입사일자
	           ,A.DSVC_RSDNNO                 --재해자_주민번호(개인정보 암호화)
	           ,A.DSVC_MP                 --재해자_휴대폰
	           ,A.DSVC_SEX                 --재해자_성별 ( 1 남성, 0 여성)
	           ,A.DSVC_NATL                 --재해자_국적
	           ,A.DSVC_STYQLF                 --재해자_체류자격
	           ,A.DSVC_JBCLS                 --재해자_직종
	           ,A.DSVC_SKND                 --재해자_동종근무경력
	           ,A.DSVC_EMP                 --재해자_고용형태
	           ,A.DSVC_119                 --119신고여부
	           ,A.DSVC_DAYOFF                 --휴일예상일수
	           ,A.IDAC_TP                 --산재유형(공통코드)  -> 재해발생유형으로 변경 ( 미사용);
	           ,A.ACCD_CONTX                 --대쉬보드의 발생내용으로 사용
	           ,A.INJR_XTNT                 --상해정도
	           ,A.ACCD_CSE                 --사고원인
	           ,A.ACCD_CPLN                 --사고대책
	           ,A.SITE_OMGR                 --현장소장
	           ,A.RT_SITE                 --과실비율 현장소장
	           ,A.CNST_TMGR                 --공사팀장
	           ,A.RT_CONT                 --과실비율 공사팀장
	           ,A.CNST_PSN                 --공사담당자
	           ,A.RT_PSN                 --과실비율 공사담당자
	           ,A.SAFT_MGR                 --안전관리자
	           ,A.RT_SAFE                 --과실비율 안전관리자
	           ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SITE_OMGR ) AS SITE_OMGR_NM     -- 현장소장명
	           ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.CNST_TMGR ) AS CNST_TMGR_NM     -- 공사팀장명
	           ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.CNST_PSN )  AS CNST_PSN_NM      -- 공사담당자명
	           ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SAFT_MGR )  AS SAFT_MGR_NM      -- 안전관리자명
	           ,A.CUST_CD                 --거래처코드
	           ,A.VNDR_SEQ                 --업체순번
	           ,A.RT_VNDR                 --과실비율 협력업체
	           ,A.TOP7_DISS                 --TOP7재해(미사용)
	           ,A.SERI_DISS                 --중대재해(미사용)
	           ,DECODE(A.SERI_DISS,'1','중대','일반') AS SERI_DISS_NM
	           ,A.MAIN_CHK                 --주관사여부
	           ,A.BE_CAUSED                 --기인물
	           ,A.INJR_KIND                 --상해종류(질병명)
	           ,A.INJR_PART                 --상해부위(질병부위)
	           ,A.ACCD_WHO                 --누가
	           ,A.ACCD_WHERE                 --어디서
	           ,A.ACCD_WHAT                 --무엇을
	           ,A.ACCD_HOW                 --어떻게
	           ,A.ACCD_WHY                 --왜
	           ,A.DISS_DIV                 --재해구분,공통코드(QS050)
	           ,(SELECT CD_NM FROM TCOA_COMCODE WHERE HRNK_CD = 'QS050' AND COM_CD = A.DISS_DIV) AS DISS_DIV_NM
	           ,A.RMKS                 --비고
	           ,A.DSVC_INSURER                 --근재보험사
	           ,A.DSS_CNT                 --재해자수
	           ,A.DEAD_CNT                 --사망자수
	           ,A.INJ_CNT                 --부상자수
	           ,A.OCO_YN                 --당사여부
	           ,A.DIS_CD                 --발생형태코드	           
	           ,A.DIS_DESC
	           ,D.APRS_DIV              -- 산재명
               ,E.DIS_NM                -- 세부산재명
	           ,A.PHOTO_GRP1                 --첨부파일그룹사진1
	           ,A.PHOTO_DESC_1                 --사진설명1
	           ,A.PHOTO_GRP2                 --첨부파일그룹사진2
	           ,A.PHOTO_DESC_2                 --사진설명2
	           ,A.PHOTO_GRP3                 --첨부파일그룹사진3
	           ,A.PHOTO_DESC_3                 --사진설명3
	           ,A.PHOTO_GRP4                 --첨부파일그룹사진4
	           ,A.PHOTO_DESC_4                 --사진설명4
	           ,A.ATFL_GRP                 --첨부파일그룹
	           ,A.ATFL_GRP2          --첨부파일그룹
	           ,FQHA_GET_TELNO(A.SITE_TEL_NO) AS SITE_TEL_NO --현장전화번호
	           ,A.EMP_CNT                 --근로자수
	           ,A.PROCRT                 --공정율
	           ,A.TOT_CNST_AMT                 --총공사금액
	           ,A.WTS_NM1                 --목격자1
	           ,A.WTS_NM2                 --목격자2
	           ,A.WTS_NM3                 --목격자3
	           ,A.SAFT_EDU_CMPL_DT                 --안전교육 이수일자
	           ,A.OCC_DIS_CNT                 --직업병수
	           ,A.IDRT_TECH                 --간접적원인_기술
	           ,A.IDRT_EDU                 --간접적원인_교육
	           ,A.IDRT_WRK                 --간접적원인_작업관리
	           ,A.DRT_UNSF_STATS                 --직접적원인_불안전상태(물적)
	           ,A.DRT_UNSF_ACT                 --직접적원인_불안전행동(인적)
	           ,A.DFT_DOC                 --기인물
	           ,A.RPT_DT                 --보고일자
	           ,A.ACP_DT                 --접수일자
	           ,A.MA_MATT                 --조치사항
	           ,A.MED_ORG                 --의료기관명
	           ,FQHA_GET_TELNO(A.MED_CADDR) AS MED_CADDR --의료기관 연락처
	           ,A.ETC_MATT                 --기타사항
	           ,A.DISS_TYPE
	           ,(SELECT CD_NM FROM TCOA_COMCODE WHERE HRNK_CD = 'QS070' AND COM_CD = A.DISS_TYPE) AS DISS_TYPE_NM
	           ,A.DSVC_AGE
	           ,A.DISS_DIV_ETC
	           ,A.APRV_NO                 --현장 결재번호
	           ,A.APRV_NO_GW              --본사 결재번호
	           ,B.APRV_STATS             -- 현장결재 결재상태
	           ,( SELECT CNST_NM FROM VQSZ_SITEINFO WHERE SIT_CD = A.SIT_CD )    AS SIT_NM       -- 현장명칭
               , NVL(C.CUST_NM, A.DSVC_VNDR)                                     AS CUST_NM      -- 소속회사명
               , C.CUST_NM                                                       AS VNDR_NM      -- 협력업체
               ,TO_CHAR(A.IPT_DTM, 'YYYYMMDD') AS IPT_DTM
               ,CASE WHEN A.BZ_HQ IS NOT NULL THEN A.BZ_HQ
                ELSE (
	             	SELECT DEPT_NM AS TOP_DEPT_NM
					FROM THRZ_DEPT
					WHERE CONNECT_BY_ISLEAF = 1
					START WITH DEPT_CD = p_SIT_CD
					CONNECT BY PRIOR HRNK_DEPT_CD = DEPT_CD
		  	      )
		  	    END  AS BZ_HQ --사업본부
		  	   , (SELECT APRV_STATS FROM TCOF_APPROVE WHERE APRV_NO = A.APRV_NO_GW) AS APRV_STATS_GW
          FROM TQHA_IDAC    A
             , TQHA_APRV    B
             , TCOA_TRADE   C
             , TQHA_DISASTER_DIV   D
             , TQHA_DISASTER_CD    E
         WHERE A.SIT_CD         = B.SIT_CD (+)
           AND A.APRV_NO        = B.APRV_NO (+)
           AND A.CUST_CD        = C.CUST_CD(+)
           AND D.DIV_CD         = E.DIV_CD(+)
           AND E.DIS_CD         = A.DIS_CD(+)
           AND A.SIT_CD         = p_SIT_CD
           AND A.ACCD_SEQ       = p_ACCD_SEQ
           ;
        
    -- 본사결재용상세
    ELSIF (p_WRK_TP = 'Q4') THEN

        OPEN RTN_CURSOR FOR
        SELECT  A.SIT_CD                   --현장코드
	           ,A.ACCD_SEQ                 --사고순번
	           ,A.APRV_NO_GW AS APRV_NO    --본사 결재번호
		  	   ,F.APRV_NO_GW AS APRV_NO_GW
		  	   ,F.APRV_STATS AS APRV_STATS
          FROM TQHA_IDAC    A
             , TCOF_APPROVE F
         WHERE A.APRV_NO_GW     = F.APRV_NO(+)
           AND A.SIT_CD         = p_SIT_CD
           AND A.ACCD_SEQ       = p_ACCD_SEQ
           ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
            
END ;
/

-- PQHA_LAB_AREC_Q
DROP PROCEDURE "PQHA_LAB_AREC_Q";
CREATE PROCEDURE "PQHA_LAB_AREC_Q" (
    p_WRK_TP                IN VARCHAR2 DEFAULT 'Q'         -- FLAG(Q)
,   p_SIT_CD                IN VARCHAR2                     -- 현장
,   p_SEARCH_CONF_YM        IN VARCHAR2                     -- 년월
,   p_CONF_SEQ              IN VARCHAR2                     -- 노사회의순번
,   RTN_CURSOR              OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
    COPYRIGHT:    HUMAN PLUS
    PROCEDURE:    [PQHA_LAB_AREC_Q] PROCEDRE
    설명     :    [QSE > 안전관리 > 안전서류관리 > 노사협의체목록  조회] 프로시저

     개정일자                      변경내용요약                                 관련근거
    ---------------------------------------------------------------------------------------------------------------------------
     2023-11-28   HUMANPLUS        신규
     2023/03/06    정우성            협의체 코드 추가
    ***************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009 ; --ERROR 코드
    ERR_MSG        VARCHAR2(200)   ; --ERROR Message
    USER_EXCEPTION EXCEPTION       ;

BEGIN
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리
    ---------------------------------------------------------------------------------------------------------------------------

    -- 노사협의체목록 조회
    IF p_WRK_TP = 'Q' THEN
        --DBMS_OUTPUT.PUT_LINE('PQHA_LAB_AREC_Q 노사협의체목록 조회');

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD             -- 현장코드
             , A.CONF_SEQ           -- 회의순번
             , A.CONF_DT            -- 회의일자
             , A.CONF_STR_TIME      -- 회의시작시간
             , A.CONF_END_TIME      -- 회의종료시간
             , A.CONF_PLC           -- 회의장소
             , A.CONF_PRTR          -- 회의참석자
             , A.THME               -- 주제
             , A.DECD_MATT          -- 의결사항
             ---2023/03/06    (정우성) 협의체 코드(명)/기타사항 추가
             , A.AREC_CD            -- 협의체 코드
             , C.AREC_NM            -- 협의체명
             , A.ETC_MATT           -- 기타사항
             -------------------------------------
             , A.APRV_NO            -- 결재번호
             , D.CD_NM  AS APRV_STATS_NM  -- 결재진행상태
             , B.APRV_STATS         -- 결재상태
             , TO_CHAR(TO_DATE(A.CONF_DT, 'YYYYMMDD'), 'day') AS DAY_OF_WEEK --요일
          FROM TQHA_LAB_AREC        A
          LEFT JOIN TQHA_APRV       B ON A.SIT_CD       = B.SIT_CD
                                     AND A.APRV_NO      = B.APRV_NO
          ---2023/03/04    (정우성) 협의체 코드 추가
          LEFT JOIN  TQHA_AREC_CD   C ON C.AREC_CD      = A.AREC_CD
          LEFT JOIN  TCOA_COMCODE   D ON D.COM_CD       = B.APRV_STATS
                                     AND D.HRNK_CD      = 'QS031'
          -------------------------------------
         WHERE A.SIT_CD = p_SIT_CD
           AND (SUBSTR(A.CONF_DT,1,6) = p_SEARCH_CONF_YM OR NVL(p_SEARCH_CONF_YM, 0) = 0 )
         ORDER BY CONF_DT DESC
        ;

    ELSIF p_WRK_TP = 'Q1' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD             -- 현장코드
             , A.CONF_SEQ           -- 노사회의순번
             , A.CONF_DT            -- 회의일자
             , A.CONF_STR_TIME      -- 회의시작시간
             , A.CONF_END_TIME      -- 회의종료시간
             , A.CONF_PLC           -- 회의장소
             , A.CONF_PRTR          -- 회의참석자
             , A.THME               -- 회의주제
             , A.DECD_MATT          -- 의결사항
             ---2023/03/06    (정우성) 협의체 코드(명)/기타사항 추가
             , A.AREC_CD            -- 협의체 코드
             , C.AREC_NM            -- 협의체명
             , A.ETC_MATT           -- 기타사항
             -------------------------------------
             , A.PHOTO_GRP1         -- 사진1
             , A.PHOTO_DESC_1       -- 사진설명1
             , A.PHOTO_GRP2         -- 사진2
             , A.PHOTO_DESC_2       -- 사진설명2
             , A.ATFL_GRP           -- 첨부파일그룹
             , A.APRV_NO            -- 결재번호
             , B.APRV_STATS         -- 결재상태
             , '▶ 결재상태 : ' || NVL(( SELECT CD_NM FROM TCOA_COMCODE WHERE HRNK_CD = 'QS031' AND COM_CD = B.APRV_STATS ), '-') AS APRV_STATS_NM -- 결재상태명
          FROM TQHA_LAB_AREC        A
          LEFT JOIN TQHA_APRV       B ON A.SIT_CD = B.SIT_CD
                                     AND A.APRV_NO = B.APRV_NO
          ---2023/03/04    (정우성) 협의체 코드 추가
            LEFT JOIN  TQHA_AREC_CD C ON C.AREC_CD = A.AREC_CD
          -------------------------------------
         WHERE A.SIT_CD     = p_SIT_CD
           AND A.CONF_SEQ   = p_CONF_SEQ
        ;

    END IF;


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END ;
/

-- PQHA_LAB_AREC_S
DROP PROCEDURE "PQHA_LAB_AREC_S";
CREATE PROCEDURE "PQHA_LAB_AREC_S" (
    p_WRK_TP                VARCHAR2 :='U'                                  -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID                VARCHAR2                                        -- 사용자 ID 
,   p_WRK_IP                VARCHAR2                                        -- 사용자 IP 
,   p_SIT_CD                TQHA_LAB_AREC.SIT_CD                %TYPE       -- 현장코드
,   p_CONF_SEQ              TQHA_LAB_AREC.CONF_SEQ              %TYPE       -- 회의순번
,   p_CONF_DT               TQHA_LAB_AREC.CONF_DT               %TYPE       -- 회의일자
,   p_CONF_STR_TIME         TQHA_LAB_AREC.CONF_STR_TIME         %TYPE       -- 회의시작시간
,   p_CONF_END_TIME         TQHA_LAB_AREC.CONF_END_TIME         %TYPE       -- 회의종료시간
,   p_CONF_PLC              TQHA_LAB_AREC.CONF_PLC              %TYPE       -- 회의장소
,   p_CONF_PRTR             TQHA_LAB_AREC.CONF_PRTR             %TYPE       -- 회의참석자
,   p_THME                  TQHA_LAB_AREC.THME                  %TYPE       -- 주제
,   p_DECD_MATT             TQHA_LAB_AREC.DECD_MATT             %TYPE       -- 의결사항
--2023/03/06 (정우성) 협의체 코드,기타사항 추가---
,   p_AREC_CD               TQHA_LAB_AREC.AREC_CD               %TYPE       -- 협의체 코드
,   p_ETC_MATT              TQHA_LAB_AREC.ETC_MATT              %TYPE       -- 기타사항
---------------------------------------------
,   p_PHOTO_GRP1            TQHA_LAB_AREC.PHOTO_GRP1            %TYPE       -- 첨부파일그룹사진1
,   p_PHOTO_DESC_1          TQHA_LAB_AREC.PHOTO_DESC_1          %TYPE       -- 사진설명1
,   p_PHOTO_GRP2            TQHA_LAB_AREC.PHOTO_GRP2            %TYPE       -- 첨부파일그룹사진2
,   p_PHOTO_DESC_2          TQHA_LAB_AREC.PHOTO_DESC_2          %TYPE       -- 사진설명2
,   p_ATFL_GRP              TQHA_LAB_AREC.ATFL_GRP              %TYPE       -- 첨부파일그룹
,   p_APRV_NO               TQHA_LAB_AREC.APRV_NO               %TYPE       -- 결재번호
,   p_RTN_CONF_SEQ          OUT VARCHAR2                                    -- 리턴변수(회의순번)
)
IS 
    /**************************************************************************************************************************
      Purpose : 협의체 회의록 저장

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2021/10/26 19:36:28                         최초생성
      1.1      2023/03/06              정우성                  협의체 코드,기타사항 추가
    **************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_CONF_SEQ          TQHA_LAB_AREC.CONF_SEQ%TYPE ;             -- 순번 변수 선언

    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL AND p_WRK_TP <> 'I' )  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CONF_SEQ IS NULL AND p_WRK_TP <> 'I' )  THEN
        ERR_MSG := '회의순번는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;
    IF (p_AREC_CD IS NULL  )  THEN
        ERR_MSG := '협의체코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;   

    ---------------------------------------------------------------------
    -- 결재상태 체크
    SELECT MAX(T2.APRV_STATS)
         , MAX(T3.CD_NM )
      INTO v_APRV_STATS
         , v_APRV_STATS_NM
      FROM TQHA_LAB_AREC        T1
      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
                                  AND T1.APRV_NO    = T2.APRV_NO
      LEFT JOIN TCOA_COMCODE    T3 ON T2.APRV_STATS = T3.COM_CD 
                                  AND T3.HRNK_CD    = 'QS031'
     WHERE T1.SIT_CD    = p_SIT_CD
       AND T1.CONF_SEQ  = p_CONF_SEQ
    ;

    IF v_APRV_STATS IN ('2', '4') THEN
        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN

        DELETE 
          FROM TQHA_LAB_AREC
         WHERE SIT_CD       = p_SIT_CD         -- 현장코드
           AND CONF_SEQ     = p_CONF_SEQ       -- 회의순번
        ;

        v_CONF_SEQ := p_CONF_SEQ;

    ELSIF (p_WRK_TP ='U') THEN

        UPDATE TQHA_LAB_AREC
           SET CONF_DT              = p_CONF_DT                 -- 회의일자
             , CONF_STR_TIME        = p_CONF_STR_TIME           -- 회의시작시간
             , CONF_END_TIME        = p_CONF_END_TIME           -- 회의종료시간
             , CONF_PLC             = p_CONF_PLC                -- 회의장소
             , CONF_PRTR            = p_CONF_PRTR               -- 회의참석자
             , THME                 = p_THME                    -- 주제
             , DECD_MATT            = p_DECD_MATT               -- 의결사항
             --2023/03/06 (정우성) 협의체 코드,기타사항 추가---
             , AREC_CD              = p_AREC_CD                 -- 협의체 코드
             , ETC_MATT             = p_ETC_MATT                -- 기타사항
              ---------------------------------------------
             , PHOTO_GRP1           = p_PHOTO_GRP1              -- 첨부파일그룹사진1
             , PHOTO_DESC_1         = p_PHOTO_DESC_1            -- 사진설명1
             , PHOTO_GRP2           = p_PHOTO_GRP2              -- 첨부파일그룹사진2
             , PHOTO_DESC_2         = p_PHOTO_DESC_2            -- 사진설명2
             , ATFL_GRP             = p_ATFL_GRP                -- 첨부파일그룹
             , APRV_NO              = p_APRV_NO                 -- 결재번호
             , UPD_ID               = p_WRK_ID                  -- 수정ID 
             , UPD_DTM              = SYSDATE()                 -- 수정일시
             , UPD_IP               = p_WRK_IP                  -- 수정IP
         WHERE SIT_CD               = p_SIT_CD                  -- 현장코드
           AND CONF_SEQ             = p_CONF_SEQ                -- 회의순번
        ;

        v_CONF_SEQ := p_CONF_SEQ;

    ELSE 
        -- 노사협의체순번 생성
        SELECT NVL( (MAX(CONF_SEQ)+1),'1' ) 
          INTO v_CONF_SEQ
          FROM TQHA_LAB_AREC
         WHERE SIT_CD   = p_SIT_CD         --현장코드
        ;
        -- 노사협의체순번 생성 완료    

        INSERT 
          INTO TQHA_LAB_AREC
             ( SIT_CD                   -- 현장코드
             , CONF_SEQ                 -- 회의순번
             , CONF_DT                  -- 회의일자
             , CONF_STR_TIME            -- 회의시작시간
             , CONF_END_TIME            -- 회의종료시간
             , CONF_PLC                 -- 회의장소
             , CONF_PRTR                -- 회의참석자
             , THME                     -- 주제
             , DECD_MATT                -- 의결사항
             --2023/03/06 (정우성) 협의체 코드,기타사항 추가---
             , AREC_CD                  -- 협의체 코드
             , ETC_MATT                 -- 기타사항
             ---------------------------------------------
             ,PHOTO_GRP1                -- 첨부파일그룹사진1
             ,PHOTO_DESC_1              -- 사진설명1
             ,PHOTO_GRP2                -- 첨부파일그룹사진2
             ,PHOTO_DESC_2              -- 사진설명2
             ,ATFL_GRP                  -- 첨부파일그룹
             ,APRV_NO                   -- 결재번호
             ,IPT_ID                    -- 입력ID
             ,IPT_DTM                   -- 입력일시
             ,IPT_IP                    -- 입력IP
             ,UPD_ID                    -- 수정ID
             ,UPD_DTM                   -- 수정일시
             ,UPD_IP                    -- 수정IP
             )
        VALUES 
             ( p_SIT_CD                 -- 현장코드
             , v_CONF_SEQ               -- 회의순번
             , p_CONF_DT                -- 회의일자
             , p_CONF_STR_TIME          -- 회의시작시간
             , p_CONF_END_TIME          -- 회의종료시간
             , p_CONF_PLC               -- 회의장소
             , p_CONF_PRTR              -- 회의참석자
             , p_THME                   -- 주제
             , p_DECD_MATT              -- 의결사항
             --2023/03/06 (정우성) 협의체 코드,기타사항 추가---
             , p_AREC_CD                -- 협의체 코드
             , p_ETC_MATT               -- 기타사항
             ---------------------------------------------
             , p_PHOTO_GRP1             -- 첨부파일그룹사진1
             , p_PHOTO_DESC_1           -- 사진설명1
             , p_PHOTO_GRP2             -- 첨부파일그룹사진2
             , p_PHOTO_DESC_2           -- 사진설명2
             , p_ATFL_GRP               -- 첨부파일그룹
             , p_APRV_NO                -- 결재번호
             , p_WRK_ID                 -- 입력ID 
             , SYSDATE()                -- 입력일시
             , p_WRK_IP                 -- 입력IP
             , p_WRK_ID                 -- 수정ID
             , SYSDATE()                -- 수정일시
             , p_WRK_IP                 -- 수정IP
             )
        ;

    END IF;

    p_RTN_CONF_SEQ := v_CONF_SEQ;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END ;
/

-- PQHA_LBR_CHK_ITM_S
DROP PROCEDURE "PQHA_LBR_CHK_ITM_S";
CREATE PROCEDURE "PQHA_LBR_CHK_ITM_S" (
    p_WRK_TP                VARCHAR2 :='U'                                  -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID                VARCHAR2                                        -- 사용자 ID 
,   p_WRK_IP                VARCHAR2                                        -- 사용자 IP 
,   p_SIT_CD                TQHA_LBR_CHK_ITM.SIT_CD             %TYPE       -- 현장코드
,   p_CHK_SEQ               TQHA_LBR_CHK_ITM.CHK_SEQ            %TYPE       -- 점검순번
,   p_CHK_CD                TQHA_LBR_CHK_ITM.CHK_CD             %TYPE       -- 노사합동점검표 구분(QS027) 1 개인보호구 적정지급 
,   p_CHK_MATT              TQHA_LBR_CHK_ITM.CHK_MATT           %TYPE       -- 지적사항
,   p_MA_RSLT               TQHA_LBR_CHK_ITM.MA_RSLT            %TYPE       -- 조치결과
,   p_IMPRV_DT              TQHA_LBR_CHK_ITM.IMPRV_DT           %TYPE       -- 개선일자
,   p_PHOTO_GRP1            TQHA_LBR_CHK_ITM.PHOTO_GRP1         %TYPE       -- 첨부파일그룹사진1
,   p_PHOTO_DESC_1          TQHA_LBR_CHK_ITM.PHOTO_DESC_1       %TYPE       -- 사진설명1
,   p_PHOTO_GRP2            TQHA_LBR_CHK_ITM.PHOTO_GRP2         %TYPE       -- 개선일자
,   p_PHOTO_DESC_2          TQHA_LBR_CHK_ITM.PHOTO_DESC_2       %TYPE       -- 사진설명2
) 
IS 
    /**************************************************************************************************************************
      Purpose : 점검내용 저장

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2021/10/28 11:18:44                         최초생성

    **************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;
    v_CHK_CD            TQHA_LBR_CHK_ITM.CHK_CD%TYPE ;  -- 순번 변수 선언

    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CHK_SEQ IS NULL)  THEN
        ERR_MSG := '점검순번는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

--    IF (p_CHK_CD IS NULL)  THEN
--        ERR_MSG := '노사합동점검표는(은) 필수 입력사항 입니다.';
--        RAISE USER_EXCEPTION;
--    END IF;
    
    ---------------------------------------------------------------------
    -- 결재상태 체크
    SELECT MAX(T2.APRV_STATS)
         , MAX(T3.CD_NM )
      INTO v_APRV_STATS
         , v_APRV_STATS_NM
      FROM TQHA_LBR_CHK         T1
      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
                                  AND T1.APRV_NO    = T2.APRV_NO
      LEFT JOIN TCOA_COMCODE    T3 ON T2.APRV_STATS = T3.COM_CD 
                                  AND T3.HRNK_CD    = 'QS031'
     WHERE T1.SIT_CD    = p_SIT_CD
       AND T1.CHK_SEQ   = p_CHK_SEQ
    ;
    
    IF v_APRV_STATS IN ('2', '4') THEN
        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------

       -- 순번 생성
    SELECT NVL(MAX(CHK_CD), 0) +1     --노사합동점검표 구분(QS027) 1 개인보호구 적정지급 
          INTO v_CHK_CD
       FROM TQHA_LBR_CHK_ITM
      WHERE SIT_CD  = p_SIT_CD      -- 현장코드
        AND CHK_SEQ = p_CHK_SEQ     -- 점검순번
    ;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN
    
        DELETE 
          FROM TQHA_LBR_CHK_ITM
         WHERE SIT_CD   = p_SIT_CD      -- 현장코드
           AND CHK_SEQ  = p_CHK_SEQ     -- 점검순번
           AND CHK_CD   = p_CHK_CD      -- 노사합동점검표 구분(QS027) 1 개인보호구 적정지급 
        ;

    ELSIF (p_WRK_TP ='U') THEN
    
        UPDATE TQHA_LBR_CHK_ITM
           SET CHK_MATT         = p_CHK_MATT            -- 지적사항
             , MA_RSLT          = p_MA_RSLT             -- 조치결과
             , IMPRV_DT         = p_IMPRV_DT            -- 개선일자
             , PHOTO_GRP1       = p_PHOTO_GRP1          -- 첨부파일그룹사진1
             , PHOTO_DESC_1     = p_PHOTO_DESC_1        -- 사진설명1
             , PHOTO_GRP2       = p_PHOTO_GRP2          -- 첨부파일그룹사진2
             , PHOTO_DESC_2     = p_PHOTO_DESC_2        -- 사진설명2
             , UPD_ID           = p_WRK_ID              -- 수정ID 
             , UPD_DTM          = SYSDATE()             -- 수정일시
             , UPD_IP           = p_WRK_IP              -- 수정IP
         WHERE SIT_CD           = p_SIT_CD              -- 현장코드
           AND CHK_SEQ          = p_CHK_SEQ             -- 점검순번
           AND CHK_CD           = p_CHK_CD              -- 노사합동점검표 구분(QS027) 1 개인보호구 적정지급 
        ;
        
    ELSE 

        INSERT 
          INTO TQHA_LBR_CHK_ITM
             ( SIT_CD               -- 현장코드
             , CHK_SEQ              -- 점검순번
             , CHK_CD               -- 노사합동점검표 구분(QS027) 1 개인보호구 적정지급 
             , CHK_MATT             -- 지적사항
             , MA_RSLT              -- 조치결과
             , IMPRV_DT             -- 개선일자
             , PHOTO_GRP1           -- 첨부파일그룹사진1
             , PHOTO_DESC_1         -- 사진설명1
             , PHOTO_GRP2           -- 첨부파일그룹사진2
             , PHOTO_DESC_2         -- 사진설명2
             , IPT_ID               -- 입력ID
             , IPT_DTM              -- 입력일시
             , IPT_IP               -- 입력IP
             , UPD_ID               -- 수정ID
             , UPD_DTM              -- 수정일시
             , UPD_IP               -- 수정IP
             )
        VALUES 
             ( p_SIT_CD             -- 현장코드
             , p_CHK_SEQ            -- 점검순번
             , v_CHK_CD             -- 노사합동점검표 구분(QS027) 1 개인보호구 적정지급 
             , p_CHK_MATT           -- 지적사항
             , p_MA_RSLT            -- 조치결과
             , p_IMPRV_DT           -- 개선일자
             , p_PHOTO_GRP1         -- 첨부파일그룹사진1
             , p_PHOTO_DESC_1       -- 사진설명1
             , p_PHOTO_GRP2         -- 첨부파일그룹사진2
             , p_PHOTO_DESC_2       -- 사진설명2
             , p_WRK_ID             -- 입력ID 
             , SYSDATE()            -- 입력일시
             , p_WRK_IP             -- 입력IP
             , p_WRK_ID             -- 수정ID
             , SYSDATE()            -- 수정일시
             , p_WRK_IP             -- 수정IP
             )
        ;
        
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHA_LBR_CHK_Q
DROP PROCEDURE "PQHA_LBR_CHK_Q";
CREATE PROCEDURE "PQHA_LBR_CHK_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'         -- FLAG(Q)
,   p_SIT_CD            IN VARCHAR2                     -- 현장
,   p_SEARCH_CHK_YM     IN VARCHAR2                     -- 년월
,   p_CHK_SEQ           IN VARCHAR2                     -- 점검순번
,   RTN_CURSOR          OUT SYS_REFCURSOR
) 
IS
    /**************************************************************************************************************************
    COPYRIGHT:    HUMAN PLUS
    PROCEDURE:    [PQHA_LBR_CHK_Q] PROCEDRE
    설명     :    [QSE > 안전관리 > 안전서류관리 > 노사합동점검관리 목록  조회] 프로시저

     개정일자                      변경내용요약                                 관련근거
    ---------------------------------------------------------------------------------------------------------------------------
     2023-11-28   HUMANPLUS        신규
    ***************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009 ; --ERROR 코드
    ERR_MSG        VARCHAR2(200)   ; --ERROR Message
    USER_EXCEPTION EXCEPTION       ;

BEGIN
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리
    ---------------------------------------------------------------------------------------------------------------------------

    -- 노사합동점검관리 목록 조회
    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                 -- 현장코드
             , A.CHK_SEQ                -- 점검순번
             , A.CHK_DT                 -- 점검일자
             , A.LBR_PSN                -- 근로자
             , A.LBR_USR                -- 사용자
             , A.IMPTC_MATT             -- 중요사항
             , A.CORR_RSLT              -- 시정조치결과
             , A.ETC_MATT               -- 기타사항
             , A.SAFT_OPIN              -- 안전관리자 의견
             , A.SITE_OPIN              -- 현장소장 의견
             , A.PHOTO_GRP1             -- 첨부사진 1
             , A.PHOTO_DESC_1           -- 첨부사진 명칭1
             , A.PHOTO_GRP2             -- 첨부사진 2
             , A.PHOTO_DESC_2           -- 첨부사진 명칭2
             , A.ATFL_GRP               -- 첨부파일 그룹
             , A.APRV_NO                -- 공통코드 QS031 결재번호
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = B.APRV_STATS AND HRNK_CD = 'QS031') AS APRV_STATS_NM  -- 결재진행상태
             , B.APRV_STATS
          FROM TQHA_LBR_CHK     A
          LEFT JOIN TQHA_APRV   B ON A.SIT_CD   = B.SIT_CD
                                 AND A.APRV_NO  = B.APRV_NO
         WHERE A.SIT_CD = p_SIT_CD
           AND (SUBSTR(A.CHK_DT, 1, 6) = p_SEARCH_CHK_YM OR NVL(p_SEARCH_CHK_YM, 0) = 0)
         ORDER BY A.CHK_DT DESC
        ;

    ELSIF p_WRK_TP = 'Q1' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                 -- 현장코드
             , A.CHK_SEQ                -- 점검순번
             , A.CHK_DT                 -- 점검일자
             , A.LBR_PSN                -- 근로자
             , A.LBR_USR                -- 사용자
             , A.IMPTC_MATT             -- 중요사항
             , A.CORR_RSLT              -- 시정조치결과
             , A.ETC_MATT               -- 기타사항
             , A.SAFT_OPIN              -- 안전관리자 의견
             , A.SITE_OPIN              -- 현장소장 의견
             , A.PHOTO_GRP1             -- 첨부사진 1
             , A.PHOTO_DESC_1           -- 첨부사진 명칭1
             , A.PHOTO_GRP2             -- 첨부사진 2
             , A.PHOTO_DESC_2           -- 첨부사진 명칭2
             , A.ATFL_GRP               -- 첨부파일 그룹
             , A.APRV_NO                -- 공통코드 QS031 결재번호
             , B.APRV_STATS             -- 결재상태
             , '▶ 결재상태 : ' || NVL(( SELECT CD_NM FROM TCOA_COMCODE WHERE HRNK_CD = 'QS031' AND COM_CD = B.APRV_STATS ), '-') AS APRV_STATS_NM -- 결재상태명
          FROM TQHA_LBR_CHK A
          LEFT JOIN TQHA_APRV B
            ON A.SIT_CD     = B.SIT_CD
           AND A.APRV_NO    = B.APRV_NO
         WHERE A.SIT_CD     = p_SIT_CD
           AND A.CHK_SEQ    = p_CHK_SEQ
        ;

    ELSIF p_WRK_TP = 'Q2' THEN

        OPEN RTN_CURSOR FOR
        SELECT B.SIT_CD                 -- 현장코드
             , B.CHK_SEQ                -- 점검순번
             , B.CHK_CD                 -- 점검코드(공통코드 QS027)
             , B.CHK_MATT               -- 지적사항
             , B.MA_RSLT                -- 조치결과
             , B.IMPRV_DT               -- 개선일자
             , B.PHOTO_GRP1             -- 첨부파일그룹사진1
             , B.PHOTO_DESC_1           -- 사진설명1
             , B.PHOTO_GRP2             -- 첨부파일그룹사진2
             , B.PHOTO_DESC_2           -- 사진설명2
          FROM TQHA_LBR_CHK A
         INNER JOIN TQHA_LBR_CHK_ITM B
            ON A.SIT_CD = B.SIT_CD
           AND A.CHK_SEQ = B.CHK_SEQ
         WHERE B.SIT_CD = p_SIT_CD
           AND B.CHK_SEQ = p_CHK_SEQ
        ;

    END IF;


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END ;
/

-- PQHA_LBR_CHK_S
DROP PROCEDURE "PQHA_LBR_CHK_S";
CREATE PROCEDURE "PQHA_LBR_CHK_S" (
    p_WRK_TP                VARCHAR2 :='U'                              -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID                VARCHAR2                                    -- 사용자 ID
,   p_WRK_IP                VARCHAR2                                    -- 사용자 IP
,   p_SIT_CD                TQHA_LBR_CHK.SIT_CD             %TYPE       -- 현장코드
,   p_CHK_SEQ               TQHA_LBR_CHK.CHK_SEQ            %TYPE       -- 점검순번
,   p_CHK_DT                TQHA_LBR_CHK.CHK_DT             %TYPE       -- 점검일자
,   p_LBR_PSN               TQHA_LBR_CHK.LBR_PSN            %TYPE       -- 근로자
,   p_LBR_USR               TQHA_LBR_CHK.LBR_USR            %TYPE       -- 사용자
,   p_IMPTC_MATT            TQHA_LBR_CHK.IMPTC_MATT         %TYPE       -- 중요사항
,   p_CORR_RSLT             TQHA_LBR_CHK.CORR_RSLT          %TYPE       -- 시정조치결과
,   p_ETC_MATT              TQHA_LBR_CHK.ETC_MATT           %TYPE       -- 기타사항
,   p_SAFT_OPIN             TQHA_LBR_CHK.SAFT_OPIN          %TYPE       -- 안전관리자 의견
,   p_SITE_OPIN             TQHA_LBR_CHK.SITE_OPIN          %TYPE       -- 현장소장 의견
,   p_PHOTO_GRP1            TQHA_LBR_CHK.PHOTO_GRP1         %TYPE       -- 첨부파일그룹사진1
,   p_PHOTO_DESC_1          TQHA_LBR_CHK.PHOTO_DESC_1       %TYPE       -- 사진설명1
,   p_PHOTO_GRP2            TQHA_LBR_CHK.PHOTO_GRP2         %TYPE       -- 첨부파일그룹사진2
,   p_PHOTO_DESC_2          TQHA_LBR_CHK.PHOTO_DESC_2       %TYPE       -- 사진설명2
,   p_ATFL_GRP              TQHA_LBR_CHK.ATFL_GRP           %TYPE       -- 첨부파일그룹
,   p_APRV_NO               TQHA_LBR_CHK.APRV_NO            %TYPE       -- 결재번호
,   p_RTN_CHK_SEQ           OUT VARCHAR2)                               -- 리턴변수(점검순번)
IS 
    /**************************************************************************************************************************
      Purpose : 노사합동점검 저장

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2021/10/28 11:15:01                         최초생성

    **************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_CHK_SEQ           TQHA_LBR_CHK.CHK_SEQ%TYPE ;     -- 순번 변수 선언
    v_cnt               INTEGER;                        -- 하위 테이블 코드 존재 여부

    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CHK_SEQ IS NULL AND p_WRK_TP <> 'I')  THEN
        ERR_MSG := '점검순번는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CHK_DT IS NULL)  THEN
        ERR_MSG := '점검일자는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------
    -- 결재상태 체크
    SELECT MAX(T2.APRV_STATS)
         , MAX(T3.CD_NM )
      INTO v_APRV_STATS
         , v_APRV_STATS_NM
      FROM TQHA_LBR_CHK         T1
      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
                                  AND T1.APRV_NO    = T2.APRV_NO
      LEFT JOIN TCOA_COMCODE    T3 ON T2.APRV_STATS = T3.COM_CD
                                  AND T3.HRNK_CD    = 'QS031'
     WHERE T1.SIT_CD    = p_SIT_CD
       AND T1.CHK_SEQ   = p_CHK_SEQ
    ;

    IF v_APRV_STATS IN ('2', '4') THEN
        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------
    --  하위 노사합동점검ㅍ표 존재 여부 확인
    IF p_WRK_TP = 'D' THEN

        SELECT nvl(COUNT(CHK_CD),0)
          INTO v_cnt
          FROM TQHA_LBR_CHK_ITM
         WHERE SIT_CD = p_SIT_CD
           AND CHK_SEQ = p_CHK_SEQ
        ;

         -- 노사합동점검표  Validation
        IF v_cnt > 0 THEN
            ERR_MSG := '점검항목 해당일자  "' || p_CHK_DT || '" 은(는) 하위 노사합동점검표 데이타가 존재합니다. 하위 노사합동점검표 데이타를 전부 삭제해야 삭제할 수 있습니다. ';
            RAISE USER_EXCEPTION;
        END IF;

    END IF;
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN

        DELETE
          FROM TQHA_LBR_CHK
         WHERE SIT_CD = p_SIT_CD        -- 현장코드
           AND CHK_SEQ = p_CHK_SEQ      -- 점검순번
        ;

        v_CHK_SEQ := p_CHK_SEQ;

    ELSIF (p_WRK_TP ='U') THEN

        UPDATE TQHA_LBR_CHK
           SET CHK_DT               = p_CHK_DT              --점검일자
             , LBR_PSN              = p_LBR_PSN             --근로자
             , LBR_USR              = p_LBR_USR             --사용자
             , IMPTC_MATT           = p_IMPTC_MATT          --중요사항
             , CORR_RSLT            = p_CORR_RSLT           --시정조치결과
             , ETC_MATT             = p_ETC_MATT            --기타사항
             , SAFT_OPIN            = p_SAFT_OPIN           --안전관리자 의견
             , SITE_OPIN            = p_SITE_OPIN           --현장소장 의견
             , PHOTO_GRP1           = p_PHOTO_GRP1          --첨부파일그룹사진1
             , PHOTO_DESC_1         = p_PHOTO_DESC_1        --사진설명1
             , PHOTO_GRP2           = p_PHOTO_GRP2          --첨부파일그룹사진2
             , PHOTO_DESC_2         = p_PHOTO_DESC_2        --사진설명2
             , ATFL_GRP             = p_ATFL_GRP            --첨부파일그룹
             , APRV_NO              = p_APRV_NO             --결재번호
             , UPD_ID               = p_WRK_ID              --수정ID
             , UPD_DTM              = SYSDATE()             --수정일시
             , UPD_IP               = p_WRK_IP              --수정IP
         WHERE SIT_CD               = p_SIT_CD              --현장코드
           AND CHK_SEQ              = p_CHK_SEQ             --점검순번
        ;

        v_CHK_SEQ := p_CHK_SEQ;

    ELSE

        -- 합동점검순번 생성
        SELECT NVL( (MAX(CHK_SEQ)+1),'1' )
          INTO v_CHK_SEQ
          FROM TQHA_LBR_CHK
         WHERE SIT_CD = p_SIT_CD;         --현장코드

        --
        INSERT
          INTO TQHA_LBR_CHK
             ( SIT_CD                   -- 현장코드
             , CHK_SEQ                  -- 점검순번
             , CHK_DT                   -- 점검일자
             , LBR_PSN                  -- 근로자
             , LBR_USR                  -- 사용자
             , IMPTC_MATT               -- 중요사항
             , CORR_RSLT                -- 시정조치결과
             , ETC_MATT                 -- 기타사항
             , SAFT_OPIN                -- 안전관리자 의견
             , SITE_OPIN                -- 현장소장 의견
             , PHOTO_GRP1               -- 첨부파일그룹사진1
             , PHOTO_DESC_1             -- 사진설명1
             , PHOTO_GRP2               -- 첨부파일그룹사진2
             , PHOTO_DESC_2             -- 사진설명2
             , ATFL_GRP                 -- 첨부파일그룹
             , APRV_NO                  -- 결재번호
             , IPT_ID                   -- 입력ID
             , IPT_DTM                  -- 입력일시
             , IPT_IP                   -- 입력IP
             , UPD_ID                   -- 수정ID
             , UPD_DTM                  -- 수정일시
             , UPD_IP                   -- 수정IP
             )
        VALUES
             ( p_SIT_CD                 -- 현장코드
             , v_CHK_SEQ                -- 점검순번
             , p_CHK_DT                 -- 점검일자
             , p_LBR_PSN                -- 근로자
             , p_LBR_USR                -- 사용자
             , p_IMPTC_MATT             -- 중요사항
             , p_CORR_RSLT              -- 시정조치결과
             , p_ETC_MATT               -- 기타사항
             , p_SAFT_OPIN              -- 안전관리자 의견
             , p_SITE_OPIN              -- 현장소장 의견
             , p_PHOTO_GRP1             -- 첨부파일그룹사진1
             , p_PHOTO_DESC_1           -- 사진설명1
             , p_PHOTO_GRP2             -- 첨부파일그룹사진2
             , p_PHOTO_DESC_2           -- 사진설명2
             , p_ATFL_GRP               -- 첨부파일그룹
             , p_APRV_NO                -- 결재번호
             , p_WRK_ID                 -- 입력ID
             , SYSDATE()                -- 입력일시
             , p_WRK_IP                 -- 입력IP
             , p_WRK_ID                 -- 수정ID
             , SYSDATE()                -- 수정일시
             , p_WRK_IP                 -- 수정IP
             )
        ;

        -- 점검표 생성
        INSERT
          INTO TQHA_LBR_CHK_ITM
             ( SIT_CD                   -- 현장코드
             , CHK_SEQ                  -- 점검순번
             , CHK_CD                   -- 노사합동점검표 구분(QS027) 1 개인보호구 적정지급
             , IPT_ID                   -- 입력ID
             , IPT_DTM                  -- 입력일시
             , IPT_IP                   -- 입력IP
             , UPD_ID                   -- 수정ID
             , UPD_DTM                  -- 수정일시
             , UPD_IP                   -- 수정IP
             )
        VALUES
             ( p_SIT_CD                 -- 현장코드
             ,v_CHK_SEQ                 -- 점검순번
             ,1                         -- 노사합동점검표 구분(QS027) 1 개인보호구 적정지급
             ,p_WRK_ID                  -- 입력ID
             ,SYSDATE()                 -- 입력일시
             ,p_WRK_IP                  -- 입력IP
             ,p_WRK_ID                  -- 수정ID
             ,SYSDATE()                 -- 수정일시
             ,p_WRK_IP                  -- 수정IP
             )
        ;

    END IF;

    p_RTN_CHK_SEQ := v_CHK_SEQ;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
            
END ;
/

-- PQHA_MEET_DRFT_OTHER_Q
DROP PROCEDURE "PQHA_MEET_DRFT_OTHER_Q";
CREATE PROCEDURE "PQHA_MEET_DRFT_OTHER_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'         -- FLAG
,   p_SIT_CD            IN VARCHAR2                     -- 현장코드
,   p_PLN_YM            IN VARCHAR2                     -- 계획연월
,   p_PLN_DGR           IN VARCHAR2                     -- 계획차수
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [위험성평가회의 ] PROCEDRE 

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2026/02/09                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    -- 
    IF p_WRK_TP = 'Q1' THEN

        -- 그리드 조회 : 위험성평가 회의록 작성목록 - 협력업체목록
        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                   --현장코드
             , A.PLN_YM                   --계획년월
             , A.PLN_DGR                  --계획차수
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.PLN_DGR AND HRNK_CD = 'QS005') AS PLN_DGR_NM  -- 계획차수명칭
             , A.CUST_CD                  --협력업체코드
             , A.VNDR_SEQ                 --협력업체차수
             , B.CUST_NM                  --협력업체명칭
             , A.SBM_YN                   --평가서제출여부
             , DECODE(NVL(A.SBM_YN,0), '1', '제출', '작성중') AS SBM_NM -- 제출여부명칭
             , A.SBM_DT                   --평가서제출일자
             , A.MNG_SUPR                 --관리감독자
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.MNG_SUPR ) AS MNG_SUPR_NM -- 관리감독자명
             , A.MNG_APRV_STATS           --관리감독자 승인상태(1승인, 2반려)
             , DECODE(NVL(A.SBM_YN,0), '1', DECODE(NVL(A.MNG_APRV_STATS,0), '1', '승인완료 ', DECODE(NVL(A.MNG_APRV_STATS,0), '2', '반려 ', '진행중')), '0', DECODE(NVL(A.MNG_APRV_STATS,0), '2', '반려 ', ''), '' ) AS MNG_APRV_STATS_NM -- 관리상태명칭
             , A.MNG_APRV_DT              --관리감독자 승인일자
             , A.SAFT_MGR                 --안전관리자
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SAFT_MGR ) AS SAFT_MGR_NM -- 안전관리자명
             , A.SAFT_APRV_STATS          --안전관리자 승인상태(1승인 2반려)
             , DECODE(NVL(A.MNG_APRV_STATS,0), '1', DECODE(NVL(A.SAFT_APRV_STATS,0), '1', '승인완료 ', DECODE(NVL(A.SAFT_APRV_STATS,0), '2', '반려 ', '진행중')), '0', DECODE(NVL(A.SAFT_APRV_STATS,0), '1','승인', '2', '반려 ', ''), '' ) AS SAFT_APRV_STATS_NM -- 안전상태명칭
             , A.SAFT_APRV_DT             --안전관리자 승인일자
             , A.SITE_OMGR                --현장소장
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SITE_OMGR ) AS SITE_OMGR_NM -- 현장소장명
             , A.SITE_APRV_STATS          --현장소장 승인상태(1승인, 2반려)
             , DECODE(NVL(A.SAFT_APRV_STATS,0), '1', DECODE(NVL(A.SITE_APRV_STATS,0), '1', '승인완료 ', DECODE(NVL(A.SITE_APRV_STATS,0), '2', '반려 ', '진행중')), '0', DECODE(NVL(A.SITE_APRV_STATS,0), '2', '반려 ', ''), '' ) AS SITE_APRV_STATS_NM -- 소장상태명칭
             , A.SITE_APRV_DT             --현장소장 승인일자
             , A.VNDR_WRK_NM
          FROM TQHA_RISK_VNDR A
             , VQSZ_TRADE B
         WHERE A.CUST_CD    = B.CUST_CD 
           AND A.SIT_CD     = p_SIT_CD
           AND A.PLN_YM     = p_PLN_YM
           AND A.PLN_DGR    = p_PLN_DGR
           AND A.OBJ_YN     = '1'
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_MEET_DRFT_OTHER_Q;
/

-- PQHA_MMEDUPLAN_Q
DROP PROCEDURE "PQHA_MMEDUPLAN_Q";
CREATE PROCEDURE "PQHA_MMEDUPLAN_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'                     -- FLAG
,   p_SIT_CD            IN TQHA_MMEDUPLAN.SIT_CD    %TYPE           -- 현장코드
,   p_YM                IN VARCHAR2                                 -- 조회년월
,   p_STR_DT            IN VARCHAR2                                 -- 조회시작일
,   p_END_DT            IN VARCHAR2                                 -- 조회종료일
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [안전보건활동계획 조회] PROCEDRE (QSE > 안전보건계획 > 안전보건활동계획 )

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      XXXX/XX/XX                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------
    -- 안전보건활동계획 목록 조회.
    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
        SELECT AA.SIT_CD
             , AA.DIV
             , AA.STR_DT
             , AA.END_DT
             , AA.CTS
             , AA.DIV_NM
             , '[' || AA. DIV_NM || '] ' || AA.CTS AS LABEL
             , AA.ACY_EDU_SEQ
             , NVL((
                   SELECT CHRC_VAL_1
                     FROM TCOA_COMCODE
                    WHERE 1=1
                      AND USE_YN    = '1'
                      AND HRNK_CD   = 'QSC01'
                      AND COM_CD    = AA.DIV
               ), '') AS COLOR
          FROM (SELECT SIT_CD
                     , DIV
                     , (SELECT CD_NM
                          FROM TCOA_COMCODE
                         WHERE COM_CD = DIV
                       ) AS DIV_NM
                     , STR_DT
                     , END_DT
                     , CTS
                     , ACY_EDU_SEQ
                  FROM TQHA_MMEDUPLAN
                 WHERE SIT_CD      = p_SIT_CD
                   AND STR_DT      LIKE p_YM || '%'
                 GROUP BY SIT_CD, ACY_EDU_SEQ, DIV , STR_DT, END_DT, CTS
                 ORDER BY SIT_CD, STR_DT, END_DT, DIV
               ) AA
        ;

    -------------------------------------------------------------------------------------------------------------------------
    -- 안전보건활동현황 목록 조회.
    ELSIF p_WRK_TP = 'Q2' THEN

        OPEN RTN_CURSOR FOR
        SELECT MP.SIT_CD                -- 현장코드
             , MP.STR_DT                -- 시작일자
             , MP.END_DT                -- 종료일자
             , MP.DIV                   -- 교육,활동
             , MP.CTS                   -- 내용
             , MP.RMKS                  -- 비고
             , CC.CD_NM                 -- 구분명
             , SI.SIT_NM                -- 현장명
          FROM TQHA_MMEDUPLAN MP
              ,TCMZ_SIT SI
              ,TCOA_COMCODE CC
         WHERE MP.SIT_CD        = NVL(p_SIT_CD, MP.SIT_CD)
           AND MP.SIT_CD        = SI.SIT_CD
           AND CC.HRNK_CD       = 'QSC01'
           AND MP.DIV           = CC.COM_CD
           AND SUBSTR(REPLACE(STR_DT,'-',''),0,6) >= REPLACE(p_STR_DT,'-','')
           AND SUBSTR(REPLACE(END_DT,'-',''),0,6) <= REPLACE(p_END_DT,'-','')
         ORDER BY STR_DT DESC, SIT_CD ASC
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_MMEDUPLAN_Q;
/

-- PQHA_MOBILE_EDU_S
DROP PROCEDURE "PQHA_MOBILE_EDU_S";
CREATE PROCEDURE "PQHA_MOBILE_EDU_S" (
   					 		 p_WRK_TP  VARCHAR2 :='U'                                     -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
                            ,p_WRK_ID  VARCHAR2                                           -- 사용자 ID 
                            ,p_WRK_IP  VARCHAR2                                           -- 사용자 IP 
                            ,p_SIT_CD TQHA_EDU.SIT_CD%TYPE                                -- 현장코드
                            ,p_EDU_SEQ TQHA_EDU.EDU_SEQ%TYPE                              -- 교육순번
                            ,p_PHOTO_GRP1 TQHA_EDU.PHOTO_GRP1%TYPE                        -- 첨부파일그룹사진1
                            ,p_PHOTO_DESC_1 TQHA_EDU.PHOTO_DESC_1%TYPE                    -- 사진설명1
                            ,p_PHOTO_GRP2 TQHA_EDU.PHOTO_GRP2%TYPE                        -- 첨부파일그룹사진2
                            ,p_PHOTO_DESC_2 TQHA_EDU.PHOTO_DESC_2%TYPE                    -- 사진설명2
                            ,p_PHOTO_GRP3 TQHA_EDU.PHOTO_GRP3%TYPE                        -- 첨부파일그룹사진3
                            ,p_PHOTO_DESC_3 TQHA_EDU.PHOTO_DESC_3%TYPE                    -- 사진설명3
)
IS
    /**************************************************************************************************************************
      Purpose : 교육일지 저장
 
      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/07/22 14:29:08 최준원                    최초생성

    **************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL AND p_WRK_TP <> 'I')  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

--    IF (p_EDU_SEQ IS NULL AND p_WRK_TP <> 'I')  THEN
--        ERR_MSG := '교육순번는(은) 필수 입력사항 입니다.';
--        RAISE USER_EXCEPTION;
--    END IF;

    ---------------------------------------------------------------------
    -- 결재상태 체크
    SELECT MAX(T2.APRV_STATS)
         , MAX(T3.CD_NM )
      INTO v_APRV_STATS
         , v_APRV_STATS_NM
      FROM TQHA_EDU             T1
      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
                                  AND T1.APRV_NO    = T2.APRV_NO
      LEFT JOIN TCOA_COMCODE    T3 ON T2.APRV_STATS = T3.COM_CD
                                  AND T3.HRNK_CD    = 'QS031'
     WHERE T1.SIT_CD    = p_SIT_CD
       AND T1.EDU_SEQ   = p_EDU_SEQ
    ;

    IF v_APRV_STATS IN ('2', '4') THEN
        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='U') THEN

        UPDATE TQHA_EDU
           SET PHOTO_GRP1           = p_PHOTO_GRP1              --첨부파일그룹사진1
              ,PHOTO_DESC_1         = p_PHOTO_DESC_1            --사진설명1
              ,PHOTO_GRP2           = p_PHOTO_GRP2              --첨부파일그룹사진2
              ,PHOTO_DESC_2         = p_PHOTO_DESC_2            --사진설명2
              ,PHOTO_GRP3           = p_PHOTO_GRP3              --첨부파일그룹사진3
              ,PHOTO_DESC_3         = p_PHOTO_DESC_3            --사진설명3
              ,UPD_ID               = p_WRK_ID                  --수정ID 
              ,UPD_DTM              = SYSDATE()                 --수정일시
              ,UPD_IP               = p_WRK_IP                  --수정IP
         WHERE SIT_CD  = p_SIT_CD         --현장코드
           AND EDU_SEQ = p_EDU_SEQ        --교육순번
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END ;
/

-- PQHA_NCR_REP_Q
DROP PROCEDURE "PQHA_NCR_REP_Q";
CREATE PROCEDURE "PQHA_NCR_REP_Q" (
    p_WRK_TP                    IN VARCHAR2 DEFAULT 'Q'     -- FLAG (Q:ERP 부적합보고서, Q1:ERP 부적합보고서 작정, B:B2B부적합보고서, B1:B2B 부적합보고서 작성)
,   p_SIT_CD                    IN VARCHAR2
,   p_SEARCH_PUBC_YM            IN VARCHAR2
,   p_SEARCH_VNDR_MA_YN         IN VARCHAR2
,   p_NCR_DOC_NO                IN VARCHAR2                 -- 부적합문서번호
,   p_CUST_CD                   IN VARCHAR2    
,   p_VNDR_SEQ                  IN VARCHAR2    
,   RTN_CURSOR                  OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [평가항목 조회] PROCEDRE (QSE > 안전관리 > 중점점검관리 > 부적합보고서  )

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2023/12/06                                 최초생성  

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                       -- 현장코드
             , A.VNDR_MA_YN                    -- 업체조치 여부(공통코드 QS025)
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = VNDR_MA_YN AND HRNK_CD = 'QS025') AS VNDR_MA_YN_NM  -- 조치여부명
             /*, A.NCR_TTL                       -- 부적합 제목*/
             , A.NCR_DOC_NO                    -- 부적합문서번호
             , A.PUBC_DT                       -- 발행일자
             , A.NCR_WRTR                      -- 발행자
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.NCR_WRTR ) AS NCR_WRTR_NM     -- 발행자 명칭
             , A.CUST_CD                       -- 업체코드
             , A.VNDR_SEQ                      -- 업체순번
             , CASE WHEN A.DIRECT_YN = '1' THEN '중흥'
                    ELSE ( SELECT CUST_NM FROM VQSZ_TRADE WHERE CUST_CD = A.CUST_CD )
               END AS VNDR_NM -- 업체명 (22.07.05 수정)
             , A.CTP_CD                        -- 공종코드
             , ( SELECT CTP_NM FROM TQHA_CTP  WHERE CTP_CD = A.CTP_CD ) AS CTP_NM  -- 공종명칭
             , A.NCR_LOC                       -- 발생위치
             , A.MA_DDLN_DT                    -- 조치기한일자
             , A.NCR_CTS                       -- 부적합내용
             , A.NCR_MATT                      -- 요구사항
             , A.VNDR_PRVN_CPLN                -- 업체재발방지 대책
             , A.NCR_CRT_DIV                   -- 부적합구분 (1:부적합, 2:안전점검, 3:추가위험)
             , CASE WHEN A.NCR_CRT_DIV = '1' THEN '부적합보고서'
                    WHEN A.NCR_CRT_DIV = '2' THEN '일일안전점검'
                    WHEN A.NCR_CRT_DIV = '3' THEN '추가위험발굴'
                END AS NCR_CRT_DIV_NM -- 부적합구분명
             , A.NCR_PHOTO_GRP1                -- 부적합내용 그룹사진1
             , A.NCR_PHOTO_DESC_1              -- 사진설명1
             , A.NCR_PHOTO_GRP2                -- 부적합내용 그룹사진2
             , A.NCR_PHOTO_DESC_2              -- 사진설명2
             , A.VNDR_PHOTO_GRP1               -- 조치내용 그룹사진1
             , A.VNDR_PHOTO_DESC_1             -- 사진설명1
             , A.VNDR_PHOTO_GRP2               -- 조치내용 그룹사진2
             , A.VNDR_PHOTO_DESC_2             -- 사진설명2
          FROM TQHA_NCR_REP A
         WHERE A.SIT_CD = p_SIT_CD
           AND (SUBSTR(A.PUBC_DT,1,6) = p_SEARCH_PUBC_YM OR NVL(p_SEARCH_PUBC_YM, 0) = 0 )
           AND (A.VNDR_MA_YN = p_SEARCH_VNDR_MA_YN OR NVL(p_SEARCH_VNDR_MA_YN, 0) = 0 )
         ORDER 
            BY A.PUBC_DT DESC
             , A.NCR_SEQ DESC
        ;

    ELSIF p_WRK_TP = 'Q1' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                     -- 현장코드
             , A.NCR_DOC_NO                 -- 부적합문서번호
             , A.NCR_SEQ                    -- 년도별일련번호
             , A.PUBC_DT                    -- 발행일자
             /*, A.NCR_TTL                  -- 부적합제목*/
             , A.MA_DDLN_DT                 -- 조치기한일자
             , A.CUST_CD                    -- 협력업체코드
             , A.VNDR_SEQ                   -- 업체순번
             , CASE WHEN A.DIRECT_YN = '1' THEN '휴먼플러스 건설'
                    ELSE ( SELECT CUST_NM FROM VQSZ_TRADE WHERE CUST_CD = A.CUST_CD )
               END AS VNDR_NM -- 업체명 (22.07.05 수정)
             , B.VNDR_PSN_NM                -- 업체담당자명
             , B.VNDR_PSN_CADDR AS VNDR_PSN_CADDR -- 업체담당자연락처
             , A.CTP_CD                     -- 공종코드
             , ( SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD ) AS CTP_NM  -- 공종명
             , A.NCR_LOC                    -- 발생위치
             , A.NCR_MATT                   -- 요구사항
             , A.NCR_CTS                    -- 부적합내용
             , A.NCR_PHOTO_GRP1             -- 부적합내용 그룹사진1
             , A.NCR_PHOTO_DESC_1           -- 사진설명1
             , A.NCR_PHOTO_GRP2             -- 부적합내용 그룹사진2
             , A.NCR_PHOTO_DESC_2           -- 사진설명2
             , A.NCR_WRTR                   -- 작성자ID
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.NCR_WRTR ) AS NCR_WRTR_NM     -- 작성자명
             , A.VNDR_NOTI_YN               -- 업체통보여부(관리자->업체)
             , A.VNDR_NOTI_DT               -- 업체통보일자
             , A.VNDR_MA_TTL                -- 업체조치제목
             , A.VNDR_PRVN_CPLN             -- 업체재발방지대책
             , A.VNDR_MA_DT                 -- 업체조치일자
             , A.VNDR_MA_YN                 -- 조치여부
             , A.VNDR_MA_CTS                -- 업체조치내용
             , A.VNDR_MA_PSN                -- 업체조치자
             , DECODE((SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.VNDR_MA_PSN), '', A.VNDR_MA_PSN, (SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.VNDR_MA_PSN)) AS VNDR_MA_PSN_NM  -- 업체조치자명
             , A.VNDR_PHOTO_GRP1            -- 조치내용 그룹사진1
             , A.VNDR_PHOTO_DESC_1          -- 사진설명1
             , A.VNDR_PHOTO_GRP2            -- 조치내용 그룹사진2
             , A.VNDR_PHOTO_DESC_2          -- 사진설명2
             , A.VNDR_APRV_YN               -- 승인여부
             , A.VNDR_APRV_DT               -- 업체승인요청일자
             , A.MGR_NOTI_YN                -- 관리자발송여부(업체->관리자)
             , A.MGR_APRV_YN                -- 관리자승인여부
             , A.MGR_APRV_DT                -- 관리자승인일자
             , A.NCR_CRT_DIV                -- 부적합구분 (1:부적합, 2:안전점검, 3:추가위험)
             , A.DIRECT_YN                  -- 직영공사 체크여부(22.07.05 추가)
             , CASE WHEN A.NCR_CRT_DIV = '1' THEN '[부적합보고서에서 작성] '
                    WHEN A.NCR_CRT_DIV = '2' THEN '[일일안전점검에서 작성] '
                    WHEN A.NCR_CRT_DIV = '3' THEN '[추가위험발굴에서 작성] '
                    ELSE '' 
               END
               || ' ▶ 상태 : ' ||
               CASE WHEN A.MGR_APRV_YN IN ('1', '2') 
                        THEN CASE WHEN A.MGR_APRV_YN = '1' THEN '관리자 승인'
                                  ELSE '관리자 반려'
                             END
                    ELSE CASE WHEN VNDR_APRV_YN = '1' THEN '업체승인요청중'
                              ELSE CASE WHEN VNDR_NOTI_YN = '1' THEN '업체통지완료'
                                        ELSE '-'
                                   END
                         END
               END
               AS STATS_NM
          FROM TQHA_NCR_REP A
             , TQHA_VNDR B
         WHERE A.SIT_CD         = B.SIT_CD (+)
           AND A.CUST_CD        = B.CUST_CD (+)
           AND A.VNDR_SEQ       = B.VNDR_SEQ (+)
           AND A.SIT_CD         = p_SIT_CD
           AND A.NCR_DOC_NO     = p_NCR_DOC_NO
         ORDER 
            BY A.PUBC_DT DESC
             , A.NCR_SEQ DESC
        ;

    ELSIF p_WRK_TP = 'B' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                         -- 현장코드
             , A.VNDR_MA_YN                     -- 업체조치 여부(공통코드 QS025)
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = VNDR_MA_YN AND HRNK_CD = 'QS025') AS VNDR_MA_YN_NM  -- 조치여부명
             /*, A.NCR_TTL                      -- 부적합 제목*/
             , A.NCR_DOC_NO                     -- 부적합문서번호
             , A.PUBC_DT                        -- 발행일자
             , A.NCR_WRTR                       -- 발행자
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.NCR_WRTR ) AS NCR_WRTR_NM     -- 발행자 명칭
             , A.CUST_CD                        -- 업체코드
             , A.VNDR_SEQ                       -- 업체순번
             , ( SELECT CUST_NM FROM VQSZ_TRADE  WHERE CUST_CD = A.CUST_CD ) AS VNDR_NM  -- 업체명칭
             , A.CTP_CD                         -- 공종코드
             , ( SELECT CTP_NM FROM TQHA_CTP  WHERE CTP_CD = A.CTP_CD ) AS CTP_NM  -- 공종명칭
             , A.NCR_LOC                        -- 발생위치
             , A.MA_DDLN_DT                     -- 조치기한일자
             , A.NCR_CTS                        -- 부적합내용
             , A.NCR_MATT                       -- 요구사항
             , A.VNDR_PRVN_CPLN                 -- 업체재발방지 대책
             , A.NCR_CRT_DIV                    -- 부적합구분 (1:부적합, 2:안전점검, 3:추가위험)
             , A.NCR_PHOTO_GRP1                 -- 부적합내용 그룹사진1
             , A.NCR_PHOTO_DESC_1               -- 사진설명1
             , A.NCR_PHOTO_GRP2                 -- 부적합내용 그룹사진2
             , A.NCR_PHOTO_DESC_2               -- 사진설명2
             , A.VNDR_PHOTO_GRP1                -- 조치내용 그룹사진1
             , A.VNDR_PHOTO_DESC_1              -- 사진설명1
             , A.VNDR_PHOTO_GRP2                -- 조치내용 그룹사진2
             , A.VNDR_PHOTO_DESC_2              -- 사진설명2
          FROM TQHA_NCR_REP A
         WHERE A.SIT_CD             = p_SIT_CD
           AND A.CUST_CD            = p_CUST_CD
           AND A.VNDR_SEQ           = p_VNDR_SEQ
           AND ( SUBSTR(A.PUBC_DT,1,6) = p_SEARCH_PUBC_YM OR NVL(p_SEARCH_PUBC_YM, 0) = 0 )
           AND ( A.VNDR_MA_YN = p_SEARCH_VNDR_MA_YN OR NVL(p_SEARCH_VNDR_MA_YN, 0) = 0 )
         ORDER 
            BY A.PUBC_DT DESC
             , A.NCR_SEQ DESC
        ;

    ELSIF p_WRK_TP = 'B1' THEN    

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                     -- 현장코드
             , A.NCR_DOC_NO                 -- 부적합문서번호
             , A.NCR_SEQ                    -- 년도별일련번호
             , A.PUBC_DT                    -- 발행일자
             /*, A.NCR_TTL                  -- 부적합제목*/
             , A.MA_DDLN_DT                 -- 조치기한일자
             , A.CUST_CD                    -- 협력업체코드
             , A.VNDR_SEQ                   -- 업체순번
             , ( SELECT CUST_NM FROM VQSZ_TRADE WHERE CUST_CD = A.CUST_CD ) AS VNDR_NM   -- 협력업체명
             , B.VNDR_PSN_NM                -- 업체담당자명
             -- , sys.pkg_crypto_dec.decrypt(B.VNDR_PSN_CADDR) VNDR_PSN_CADDR -- 업체담당자연락처
             , B.VNDR_PSN_CADDR             -- 업체담당자연락처
             , A.CTP_CD                     -- 공종코드
             , ( SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD ) AS CTP_NM  -- 공종명
             , A.NCR_LOC                    -- 발생위치
             , A.NCR_MATT                   -- 요구사항
             , A.NCR_CTS                    -- 부적합내용
             , A.NCR_PHOTO_GRP1             -- 부적합내용 그룹사진1
             , A.NCR_PHOTO_DESC_1           -- 사진설명1
             , A.NCR_PHOTO_GRP2             -- 부적합내용 그룹사진2
             , A.NCR_PHOTO_DESC_2           -- 사진설명2
             , A.NCR_WRTR                   -- 작성자ID
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.NCR_WRTR ) AS NCR_WRTR_NM     -- 작성자명
             , A.VNDR_NOTI_YN               -- 업체통보여부(관리자->업체)
             , A.VNDR_NOTI_DT               -- 업체통보일자
             , A.VNDR_MA_TTL                -- 업체조치제목
             , A.VNDR_PRVN_CPLN             -- 업체재발방지대책
             , A.VNDR_MA_DT                 -- 업체조치일자
             , A.VNDR_MA_YN                 -- 조치여부
             , A.VNDR_MA_CTS                -- 업체조치내용
             , A.VNDR_MA_PSN                -- 업체조치자
             , DECODE((SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.VNDR_MA_PSN), '', A.VNDR_MA_PSN, (SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.VNDR_MA_PSN)) AS VNDR_MA_PSN_NM -- 업체조치자명
             , A.VNDR_PHOTO_GRP1            -- 조치내용 그룹사진1
             , A.VNDR_PHOTO_DESC_1          -- 사진설명1
             , A.VNDR_PHOTO_GRP2            -- 조치내용 그룹사진2
             , A.VNDR_PHOTO_DESC_2          -- 사진설명2
             , A.VNDR_APRV_YN               -- 승인여부
             , A.VNDR_APRV_DT               -- 업체승인요청일자
             , A.MGR_NOTI_YN                -- 관리자발송여부(업체->관리자)
             , A.MGR_APRV_YN                -- 관리자승인여부
             , A.MGR_APRV_DT                -- 관리자승인일자
             , A.NCR_CRT_DIV                -- 부적합구분 (1:부적합, 2:안전점검, 3:추가위험)
             , CASE WHEN A.NCR_CRT_DIV = '1' THEN '[부적합보고서에서 작성] '
                    WHEN A.NCR_CRT_DIV = '2' THEN '[일일안전점검에서 작성] '
                    WHEN A.NCR_CRT_DIV = '3' THEN '[추가위험발굴에서 작성] '
                    ELSE '' 
               END
               || ' ▶ 상태 : ' ||
               CASE WHEN A.MGR_APRV_YN IN ('1', '2') 
                        THEN CASE WHEN A.MGR_APRV_YN = '1' THEN '관리자 승인'
                                  ELSE '관리자 반려'
                             END
                    ELSE CASE WHEN VNDR_APRV_YN = '1' THEN '승인요청중'
                              ELSE '-'
                         END
               END
               AS STATS_NM
          FROM TQHA_NCR_REP A
             , TQHA_VNDR B
         WHERE A.SIT_CD         = p_SIT_CD
           AND A.NCR_DOC_NO     = p_NCR_DOC_NO
           AND A.CUST_CD        = p_CUST_CD
           AND A.VNDR_SEQ       = p_VNDR_SEQ
           AND A.SIT_CD         = B.SIT_CD
           AND A.CUST_CD        = B.CUST_CD
           AND A.VNDR_SEQ       = B.VNDR_SEQ
         ORDER 
            BY A.PUBC_DT DESC
             , A.NCR_SEQ DESC
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_NCR_REP_Q;
/

-- PQHA_RISKPLAN_Q
DROP PROCEDURE "PQHA_RISKPLAN_Q";
CREATE PROCEDURE "PQHA_RISKPLAN_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'     -- FLAG(Q: 조회)
,   p_SIT_CD            IN VARCHAR2                 -- 현장코드
,   p_SEARCH_SIT_CD     IN VARCHAR2                 -- 현장코드
,   p_SEARCH_FST_DIV    IN VARCHAR2                 -- 최초여부
,   p_SEARCH_PLN_DGR    IN VARCHAR2                 -- 차수
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [위험성평가계획 목록 조회] PROCEDRE (QSE > 안전관리 > 위험성평가(최초/연간) > 위험성평가 계획수립 )

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2023/12/04                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

   IF p_WRK_TP = 'Q' THEN

        -- SELECT  쿼리
        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                                                                                                 -- 현장코드
             , A.FST_DIV                                                                                                -- 최초구분(공통코드 QS001)
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.FST_DIV AND HRNK_CD = 'QS001')     AS FST_DIV_NM       -- 최초여부
             , A.PLN_DGR                                                                                                -- 계획차수(공통코드 QS005)
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.PLN_DGR AND HRNK_CD = 'QS005')     AS PLN_DGR_NM       -- 차수
             , A.RISK_APRS_DT                                                                                           -- 위험성평가일자
             , A.APRV_PSN                                                                                               -- 결재자
             , A.APRV_NO                                                                                                -- 결재번호
             , A.ATFL_GRP                                                                                               -- 첨부파일그룹
             , B.APRV_STATS                                                                                             -- 결재상태(공통코드 QS031)
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = B.APRV_STATS AND HRNK_CD = 'QS031')  AS APRV_STATS_NM    -- 결재상태
             /*, B.SAFT_MGR_DT        -- 안전관리자 결재일자*/
             /*, B.SITE_OMGR_DT       -- 현장소장 결재일자*/
          FROM TQHA_RISKPLAN    A
          LEFT JOIN TQHA_APRV   B ON A.SIT_CD    = B.SIT_CD
                                 AND A.APRV_NO   = B.APRV_NO
         WHERE A.SIT_CD = p_SIT_CD
        ;

    ELSIF p_WRK_TP = 'Q1' THEN

        -- SELECT  쿼리
        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                                                                                             -- 현장코드
             , A.FST_DIV                                                                                            -- 최초구분(공통코드 QS001)
             , A.PLN_DGR                                                                                            -- 계획차수(공통코드 QS005)
             , A.CTP_CD                                                                                             -- 공종코드
             , ( SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD )                          AS CTP_NM           -- 공종명칭
             , A.UNT_CD                                                                                             -- 단위코드
             , ( SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD ) AS UNT_NM           -- 단위명칭
             , A.CHK_ITM_CD                                                                                         -- 위험요인항목코드
             , A.CHK_ITM_NM                                                                                         -- 위험요인항목명칭
             , A.RISK_FREQ                                                                                          -- 위험빈도(공통코드 QS003)
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.RISK_FREQ AND HRNK_CD = 'QS003') AS RISK_FREQ_NM   -- 빈도명
             , A.RISK_APRV                                                                                          -- 위험강도(공통코드 QS004)
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.RISK_APRV AND HRNK_CD = 'QS004') AS RISK_APRV_NM   -- 강도명
             , A.RISK_CRIT                                                                                          -- 위험성레벨(공통코드 QS063)
             , A.RISK_GRD                                                                                           -- 위험등급(공통코드 QS024)
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.RISK_GRD AND HRNK_CD = 'QS024') AS RISK_GRD_NM     -- 위험등급
             , A.PRRT_REG                                                                                           -- 중점등록(공통코드 QS002)
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.PRRT_REG AND HRNK_CD = 'QS002') AS PRRT_REG_NM     -- 중점등록
             , A.IMPRV_CPLN                                                                                         -- 개선대책
             , A.MA_CNFR                                                                                            -- 확인자(안전관리자)
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.MA_CNFR ) AS MA_CNFR_NM                          -- 확인자성명
             , A.DISS_SHP                                                                                           -- 재해형태(QS036)
          FROM TQHA_RISKPLAN_D A
         WHERE SIT_CD = p_SEARCH_SIT_CD
           AND FST_DIV = p_SEARCH_FST_DIV
           AND PLN_DGR = p_SEARCH_PLN_DGR
        ;

    END IF;


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_RISKPLAN_Q;
/

-- PQHA_RISK_CHK_AGO_Q
DROP PROCEDURE "PQHA_RISK_CHK_AGO_Q";
CREATE PROCEDURE "PQHA_RISK_CHK_AGO_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'         -- FLAG
,   p_SIT_CD            IN VARCHAR2                     -- 현장코드
,   p_PLN_YM            IN VARCHAR2                     -- 계획년월
,   p_PLN_DGR           IN VARCHAR2                     -- 계획차수
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [위험성평가회의 - 이전차수 조회] PROCEDRE 

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2026/01/28                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message 
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    -- 
    IF p_WRK_TP = 'Q1' THEN

        OPEN RTN_CURSOR FOR
        -- 전회 계획회차
        SELECT T1.PLN_YM              AS PRE_PLN_YM
             , T1.PLN_DGR             AS PRE_PLN_DGR
             , T1.PLN_DGR || '차'     AS  PRE_PLN_DGR_NM 
             , T1.APRS_STR_DT         AS PRE_APRS_STR_DT    -- 평가시작일자
             , T1.APRS_END_DT         AS PRE_APRS_END_DT    -- 평가종료일자
          FROM TQHB_RISK_DGR    T1
         WHERE T1.SIT_CD        = p_SIT_CD
           AND T1.PLN_YM || T1.PLN_DGR < p_PLN_YM || p_PLN_DGR
         ORDER 
            BY T1.PLN_YM DESC
             , T1.PLN_DGR DESC
         FETCH NEXT 1 ROWS ONLY 
        ;

     ---------------------------------------------------------------------------------------
     ELSIF p_WRK_TP = 'Q2' THEN

        OPEN RTN_CURSOR FOR
        WITH 
		-- 1. 기본 점검 및 위험요인 데이터
		BASE_DATA AS (
		    SELECT T1.SIT_CD
		         , T1.ODAY_CHK_DT
		         , T2.CUST_CD
		         , T2.VNDR_SEQ
		         , T2.CTP_CD
		         , T2.UNT_CD
		         , T2.CHK_ITM_CD
		         , T2.ODAY_CHK_RSLT
		         , T2.NCR_DOC_NO
		         , T2.PHOTO_GRP1
		         , T2.PHOTO_DESC_1
		         , T2.PHOTO_GRP2
		         , T2.PHOTO_DESC_2
		         , T3.CUST_NM
		         , T4.IMPRV_CPLN
		         , R.CHK_ITM_NM
		      FROM TQHB_DAYSAFE_DT T1
		      
		      -- T1 - T2 조인
		      JOIN TQHB_DAYSAFE_CHKLST T2 ON T1.SIT_CD      = T2.SIT_CD 
		                                 AND T1.ODAY_CHK_DT = T2.ODAY_CHK_DT
		                                 AND T1.PLN_YM      = T2.PLN_YM 
		                                 AND T1.PLN_DGR     = T2.PLN_DGR 
		                                 AND T1.RISK_GRD    = T2.RISK_GRD
		                                 
		      -- T2 - T4 조인 (중점개선대책)
		      JOIN TQHB_RISK_CHK       T4 ON T2.SIT_CD      = T4.SIT_CD
		                                 AND T2.PLN_YM      = T4.PLN_YM
		                                 AND T2.PLN_DGR     = T4.PLN_DGR
		                                 AND T2.CUST_CD     = T4.CUST_CD
		                                 AND T2.VNDR_SEQ    = T4.VNDR_SEQ
		                                 AND T2.CTP_CD      = T4.CTP_CD
		                                 AND T2.UNT_CD      = T4.UNT_CD
		                                 AND T2.CHK_ITM_CD  = T4.CHK_ITM_CD
		                                 AND T2.RISK_GRD    = T4.RISK_GRD
		                                 
		      -- T2 - R 조인 (위험요인항목명)
		      LEFT JOIN TQHB_RISK_LST   R ON T2.SIT_CD      = R.SIT_CD
		                                 AND T2.PLN_YM      = R.PLN_YM
		                                 AND T2.PLN_DGR     = R.PLN_DGR
		                                 AND T2.CUST_CD     = R.CUST_CD
		                                 AND T2.VNDR_SEQ    = R.VNDR_SEQ
		                                 AND T2.CTP_CD      = R.CTP_CD
		                                 AND T2.UNT_CD      = R.UNT_CD
		                                 AND T2.CHK_ITM_CD  = R.CHK_ITM_CD
		                                 AND T2.RISK_GRD    = R.RISK_GRD
		                                 
		      LEFT JOIN VQSZ_TRADE     T3 ON T2.CUST_CD     = T3.CUST_CD
		      
		     WHERE T1.SIT_CD   = p_SIT_CD
		       AND T1.PLN_YM   = p_PLN_YM
		       AND T1.PLN_DGR  = p_PLN_DGR
		      -- AND T1.RISK_GRD = 'QS0900201' -- 조인 조건에 따라 T2, T4, R에도 자동 적용됨
		),
		
		-- 2. NCR 관련 매핑 정보 정리
		NCR_DATA AS (
		    SELECT ST1.SIT_CD
		         , ST1.NCR_DOC_NO
		         , '* ' || REGEXP_REPLACE(ST2.ODAY_CHK_DT, '([0-9]{4})([0-9]{2})([0-9]{2})', '\1-\2-\3')
		           || '/' || ST1.NCR_CTS 
		           || '/' || ST1.VNDR_MA_CTS AS CTS       
		         , ST1.VNDR_PHOTO_GRP1
		         , ST1.VNDR_PHOTO_DESC_1
		         , ST1.VNDR_PHOTO_GRP2
		         , ST1.VNDR_PHOTO_DESC_2
		      FROM TQHA_NCR_REP ST1
		      JOIN (
		            SELECT SIT_CD
		                 , NCR_DOC_NO
		                 , MAX(ODAY_CHK_DT) AS ODAY_CHK_DT
		              FROM TQHB_DAYSAFE_CHKLST
		             WHERE SIT_CD   = p_SIT_CD
		               AND PLN_YM   = p_PLN_YM
		               AND PLN_DGR  = p_PLN_DGR
		               AND RISK_GRD = 'QS0900201'
		             GROUP BY SIT_CD, NCR_DOC_NO
		      ) ST2 ON ST1.SIT_CD     = ST2.SIT_CD
		           AND ST1.NCR_DOC_NO = ST2.NCR_DOC_NO
		     WHERE ST1.SIT_CD = p_SIT_CD
		       AND (ST1.NCR_CTS IS NOT NULL OR ST1.VNDR_MA_CTS IS NOT NULL)
		)
		
		-- 3. 메인 집계 조회
		SELECT B.CUST_CD
		     , B.VNDR_SEQ
		     , B.CTP_CD
		     , B.UNT_CD
		     , B.CHK_ITM_CD
		     , MAX(B.CHK_ITM_NM)                                                                           AS CHK_ITM_NM
		     , MAX(B.CUST_NM)                                                                              AS CUST_NM
		     , MAX(B.IMPRV_CPLN)                                                                           AS IMPRV_CPLN
		     
		     -- 건수 통계 (양호 / 미흡 / 해당없음)
		     , TO_CHAR(COUNT(CASE WHEN B.ODAY_CHK_RSLT = '2' THEN 1 END)) || '/' ||
		       TO_CHAR(COUNT(CASE WHEN B.ODAY_CHK_RSLT IN ('2', '3') THEN 1 END))                         AS SUCC_CNT
		     
		     , TO_CHAR(COUNT(CASE WHEN B.ODAY_CHK_RSLT = '3' THEN 1 END)) || '/' ||
		       TO_CHAR(COUNT(CASE WHEN B.ODAY_CHK_RSLT IN ('2', '3') THEN 1 END))                         AS FAIL_CNT
		     
		     , TO_CHAR(COUNT(CASE WHEN B.ODAY_CHK_RSLT = '1' THEN 1 END)) || '/' ||
		       TO_CHAR(COUNT(CASE WHEN B.ODAY_CHK_RSLT IN ('1', '2', '3') THEN 1 END))                    AS NA_CNT
		     
		     -- 달성률 계산
		     , TO_CHAR(
		           CASE WHEN COUNT(CASE WHEN B.ODAY_CHK_RSLT IN ('2', '3') THEN 1 END) = 0 THEN 0
		                ELSE COUNT(CASE WHEN B.ODAY_CHK_RSLT = '2' THEN 1 END) 
		                   / COUNT(CASE WHEN B.ODAY_CHK_RSLT IN ('2', '3') THEN 1 END) * 100
		           END, 'FM990'
		       )                                                                                           AS SUCC_RATE
		       
		     -- 사유/내용 목록
		     , LISTAGG(N.CTS, CHR(10)) WITHIN GROUP (ORDER BY B.ODAY_CHK_DT)                               AS CAUS_DESC
		     
		     -- NCR 발행 여부에 따른 사진 정보 분기 처리
		     , CASE WHEN MAX(B.NCR_DOC_NO) IS NULL 
		            THEN MAX(B.PHOTO_GRP1) KEEP (DENSE_RANK LAST ORDER BY B.ODAY_CHK_DT) 
		            ELSE MAX(N.VNDR_PHOTO_GRP1) KEEP (DENSE_RANK LAST ORDER BY N.NCR_DOC_NO)
		       END                                                                                          AS PHOTO_GRP1
		       
		     , CASE WHEN MAX(B.NCR_DOC_NO) IS NULL 
		            THEN MAX(B.PHOTO_DESC_1) KEEP (DENSE_RANK LAST ORDER BY B.ODAY_CHK_DT) 
		            ELSE MAX(N.VNDR_PHOTO_DESC_1) KEEP (DENSE_RANK LAST ORDER BY N.NCR_DOC_NO)
		       END                                                                                          AS PHOTO_DESC_1
		       
		     , CASE WHEN MAX(B.NCR_DOC_NO) IS NULL 
		            THEN MAX(B.PHOTO_GRP2) KEEP (DENSE_RANK LAST ORDER BY B.ODAY_CHK_DT) 
		            ELSE MAX(N.VNDR_PHOTO_GRP2) KEEP (DENSE_RANK LAST ORDER BY N.NCR_DOC_NO)
		       END                                                                                          AS PHOTO_GRP2
		       
		     , CASE WHEN MAX(B.NCR_DOC_NO) IS NULL 
		            THEN MAX(B.PHOTO_DESC_2) KEEP (DENSE_RANK LAST ORDER BY B.ODAY_CHK_DT) 
		            ELSE MAX(N.VNDR_PHOTO_DESC_2) KEEP (DENSE_RANK LAST ORDER BY N.NCR_DOC_NO)
		       END                                                                                          AS PHOTO_DESC_2
		
		  FROM BASE_DATA B
		  LEFT JOIN NCR_DATA N ON B.SIT_CD     = N.SIT_CD
		                      AND B.NCR_DOC_NO = N.NCR_DOC_NO
		
		 GROUP BY 
		       B.CUST_CD
		     , B.VNDR_SEQ
		     , B.CTP_CD
		     , B.UNT_CD
		     , B.CHK_ITM_CD
		    ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_RISK_CHK_AGO_Q;
/

-- PQHA_RISK_CHK_B1
DROP PROCEDURE "PQHA_RISK_CHK_B1";
CREATE PROCEDURE "PQHA_RISK_CHK_B1" ( -- 위험성평가 차수 승인
    p_WRK_TP            VARCHAR2 :='S'                          -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE, S : 승인처리)
,   p_WRK_ID            VARCHAR2                                -- 사용자 ID
,   p_WRK_IP            VARCHAR2                                -- 사용자 IP
,   p_SIT_CD            TQHA_RISK_CHK.SIT_CD        %TYPE       -- 현장코드
,   p_PLN_YM            TQHA_RISK_CHK.PLN_YM        %TYPE       -- 계획년월
,   p_PLN_DGR           TQHA_RISK_CHK.PLN_DGR       %TYPE       -- 회자
,   p_CUST_CD           TQHA_RISK_CHK.CUST_CD       %TYPE       -- 업체코드
,   p_VNDR_SEQ          TQHA_RISK_CHK.VNDR_SEQ      %TYPE       -- 업체순번
,   p_USR_ID            TQHA_RISK_CHK.MA_CNFR       %TYPE       -- 사번
,   p_RTN_BTN           OUT VARCHAR2                            -- 리턴값 (승인여부)
,   p_RTN_MNG_DIV       OUT VARCHAR2                            -- 리턴값 (관리자/안전/소장)
)
IS
    /**************************************************************************************************************************
      Purpose : 위험성평가 평가서제출 승인처리 

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2021/12/13 12:48:42                         최초생성

    **************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message 
    USER_EXCEPTION EXCEPTION;


    v_MGR_APRV      VARCHAR2(1) ;   -- 관리감독자 승인여부
    v_SAFT_APRV     VARCHAR2(1) ;   -- 안전감독자 승인여부
    v_SITE_APRV     VARCHAR2(1) ;   -- 현장소장 승인여부

    v_CTP_CNT       INTEGER;                -- 공종담당자 여부
    v_MGR_CNT       INTEGER;                -- 관리감독자 여부
    v_SAFT_CNT      INTEGER;                -- 안전관리자 여부
    v_SITE_CNT      INTEGER;                -- 현장소장 여부

    v_RTN_BTN VARCHAR2(1)       := 'F' ;    -- 리턴 초기값
    v_RTN_MNG_DIV VARCHAR2(10)  := 'N' ;    -- 리턴 상태 초기값 ( 관리자 MGR : 관리자, SAFT : 안전관리자, SITE : 현장소장 )


BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    -- 승인 할 데이터가 있는지 체크
    SELECT nvl(MNG_APRV_STATS,0)            -- 관리감독자 승인여부
         , nvl(SAFT_APRV_STATS,0)           -- 안전관리자 승인여부
         , nvl(SITE_APRV_STATS,0)           -- 현장소장 승인여부
      INTO v_MGR_APRV                       -- 관리감독자 승인여부
         , v_SAFT_APRV                      -- 안전관리자 승인여부
         , v_SITE_APRV                      -- 현장소장 승인여부
      FROM TQHA_RISK_VNDR
     WHERE SIT_CD       = p_SIT_CD          -- 변수 (현장코드)
       AND PLN_YM       = p_PLN_YM          -- 회자년월
       AND PLN_DGR      = p_PLN_DGR         -- 차수구분코드(QS005) 1 1차,2 2차
       AND CUST_CD      = p_CUST_CD         -- 협력업체코드
       AND VNDR_SEQ     = p_VNDR_SEQ        -- 업체순번
    ;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP = 'S') THEN    -- 승인처리
        --------------------------------------------------------
        -- 관리자 승인 전 단계
        IF (v_MGR_APRV = '0') THEN

            -- 관리자가 승인 권한이 있는지 체크
            SELECT nvl(COUNT(CUST_CD),0)
              INTO v_MGR_CNT
              FROM TQHA_VNDR
             WHERE SIT_CD       = p_SIT_CD          -- 변수 (현장코드)
               AND CUST_CD      = p_CUST_CD         -- 변수 (업체코드)
               AND VNDR_SEQ     = p_VNDR_SEQ        -- 변수 (업체차수)
               AND ( MGR_1 IN (p_USR_ID) OR MGR_2 IN (p_USR_ID) OR MGR_3 IN (p_USR_ID) )  -- 변수 (사번)
            ;
            -- 숭인권한이 있음
            IF v_MGR_CNT > 0 then
                v_RTN_BTN := 'T';
                v_RTN_MNG_DIV := 'MGR';
            ELSE
                -- 공종별 담당자 권한 체크
                SELECT NVL(COUNT(CHK_ITM_CD), 0)
                  INTO v_CTP_CNT
                  FROM TQHA_RISK_CHK
                 WHERE SIT_CD       = p_SIT_CD          -- 현장코드
                   AND PLN_YM       =  p_PLN_YM         -- 계획년월
                   AND PLN_DGR      = p_PLN_DGR         -- 차수구분코드(QS005) 1 1차,2 2차
                   AND CUST_CD      = p_CUST_CD         -- 업체순번
                   AND VNDR_SEQ     = p_VNDR_SEQ        -- 업체순번
                   AND MA_CNFR      IN (p_USR_ID)
                ;

                -- 숭인권한이 있음
                IF v_CTP_CNT > 0 then
                    v_RTN_BTN      := 'T';
                    v_RTN_MNG_DIV  := 'MGR';
                END IF;
            END IF;
        END IF;

        --------------------------------------------------------
        -- 관리자 승인 후 단계
        IF (v_MGR_APRV = '1' AND v_SAFT_APRV = '0' ) THEN     -- 관리자 승인 후 AND 안전관리자 승인 전

            /*
            -- 안전관리자 승인 권한이 있는지 체크
            SELECT  nvl(COUNT(JB_CD),0)
              INTO v_SAFT_CNT
              FROM  ( -- 조직도에서 직무코드가 안전관리자인 경우
                     SELECT   DEPT_CD   -- 현장코드
                           , USR_ID    -- 사용자 id
                           , JB_CD     -- 직무코드
                      FROM TCOZ_USR_INFO
                     WHERE DEPT_CD = p_SIT_CD       -- 변수(현장코드)
                     AND  JB_CD IN ('B37E01','CM0135','CM0136','CM0137') ) A
             WHERE A.DEPT_CD = p_SIT_CD   -- 변수 (현장코드)
               AND A.USR_ID = p_USR_ID     -- 변수 (사용자id)
                  ;
            */

            -- 안전관리자 승인 권한이 있는지 체크
            SELECT nvl(COUNT(JB_CD),0)
              INTO v_SAFT_CNT
              FROM (
                    -- 2026.01.20 주석
                    -- 조직도에서 직무코드가 안전관리자인 경우
                    --SELECT   DEPT_CD   -- 현장코드
                    --        , USR_ID    -- 사용자 id
                    --        , JB_CD     -- 직무코드
                    --  FROM TCOZ_USR_INFO
                    -- WHERE DEPT_CD = p_SIT_CD       -- 변수(현장코드)
                    --   AND  JB_CD IN ('B37E01','CM0135','CM0136','CM0137')
                    -- UNION   -- 2020/5/18 일 겸직정보 추가
                    -- SELECT DEPT_CD   -- 현장코드
                    --       , USR_ID    -- 사용자 id
                    --       , JB_CD     -- 직무코드
                    --   FROM TCOZ_SBJB_INFO
                    --  WHERE DEPT_CD = p_SIT_CD
                    --    AND JB_CD IN ('B37E01','CM0135','CM0136','CM0137')

                   SELECT SIT_CD    AS DEPT_CD
                         , EMPE_NO    AS USR_ID
                         , JB_CD      AS JB_CD
                      FROM TQHA_SITENAM
                     WHERE SIT_CD = p_SIT_CD
                       AND EMPE_NO = p_USR_ID
                       AND JB_CD IN ('QS07702')  -- 안전관리자, 안전총괄
                   ) A
             WHERE A.DEPT_CD = p_SIT_CD   -- 변수 (현장코드)
               AND A.USR_ID = p_USR_ID     -- 변수 (사용자id)
            ;

            -- 관리자가 승인 권한이 있는지 체크
            IF v_SAFT_CNT > 0 then
                v_RTN_BTN       := 'T';
                v_RTN_MNG_DIV   := 'SAFT';
            END IF;

        END IF;

        --------------------------------------------------------
        -- 안전관리자 승인 후 단계
        IF (v_MGR_APRV = '1' AND v_SAFT_APRV = '1') THEN

            -- 현장소장 승인 권한이 있는지 체크
            SELECT nvl(COUNT(JB_CD),0)
              INTO v_SITE_CNT
              FROM (
                   -- 2026.01.20 주석
                   -- 조직도에서 직무코드가 안전관리자인 경우
                    --SELECT   DEPT_CD   -- 현장코드
                    --      , USR_ID    -- 사용자 id
                    --      , JB_CD     -- 직무코드
                    -- FROM TCOZ_USR_INFO
                    --WHERE DEPT_CD = p_SIT_CD   -- 변수(현장코드)
                    --AND  JB_CD IN ('B37F01')
                    SELECT SIT_CD      AS DEPT_CD
                         , EMPE_NO     AS USR_ID
                         , DTY_CD      AS JB_CD
                      FROM TQHA_SITENAM
                     WHERE SIT_CD   = p_SIT_CD
                       AND DTY_CD   IN ('B37F01')       -- 현장소장
                   ) A
             WHERE A.DEPT_CD    = p_SIT_CD     -- 변수 (현장코드)
               AND A.USR_ID     = p_USR_ID     -- 변수 (사용자id)
            ;

            -- 현장소장 승인 권한이 있는지 체크
            IF v_SITE_CNT > 0 then
               v_RTN_BTN        := 'T';
               v_RTN_MNG_DIV    := 'SITE';
            END IF;

        END IF;

        -- 현장소장 승인 후 단계
        --IF (v_SITE_APRV <> '0' ) THEN

        -- 2026.01.27 수정. 소장 반려됐을 경우엔 무조건 F, N 으로 넘어감.
        IF (v_SITE_APRV = '1' ) THEN
               v_RTN_BTN        := 'F';
               v_RTN_MNG_DIV    := 'N';
        END IF;

        p_RTN_BTN       := v_RTN_BTN ;
        p_RTN_MNG_DIV   := v_RTN_MNG_DIV ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_RISK_CHK_B1;
/

-- PQHA_RISK_CHK_Q
DROP PROCEDURE "PQHA_RISK_CHK_Q";
CREATE PROCEDURE "PQHA_RISK_CHK_Q" (  
    p_WRK_TP                IN VARCHAR2 DEFAULT 'Q'             -- FLAG
,   p_SIT_CD                IN VARCHAR2
,   p_SEARCH_SIT_CD         IN VARCHAR2
,   p_SEARCH_VNDR_CD        IN VARCHAR2
,   p_SEARCH_VNDR_SEQ       IN VARCHAR2
,   p_SEARCH_PLN_YM         IN VARCHAR2
,   p_SEARCH_PLN_DGR        IN VARCHAR2
,   p_CUST_CD               IN VARCHAR2
,   p_VNDR_SEQ              IN VARCHAR2
,   RTN_CURSOR              OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [평가항목 조회] PROCEDRE (QSE > 안전관리 > 위험성평가(수시) > 진행관리  )

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2023/12/07                                 최초생성  

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION; 

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                                     -- 현장코드
             , A.PLN_YM                                     -- 계획년월
             , A.PLN_DGR                                    -- 계획차수
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.PLN_DGR AND HRNK_CD = 'QS005') AS PLN_DGR_NM  -- 계획차수 
             , A.APRS_STR_DT                                -- 평가시작일자
             , A.APRS_END_DT                                -- 평가종료일자
             , A.VNDR_CMPL_DT                               -- 업체작성완료일자
             , (SELECT CASE MIN(NVL(SITE_APRV_STATS,0)) WHEN '0' THEN ''
                                                        WHEN '1' THEN  MAX(SITE_APRV_DT) END FIN_DT
                   FROM TQHA_RISK_VNDR 
                  WHERE SIT_CD      = A.SIT_CD              -- 현장코드 변수
                    AND PLN_YM      = A.PLN_YM              -- 변수 ( 년월)
                    AND PLN_DGR     = A.PLN_DGR             -- 변수 ( 차수)
                    AND OBJ_YN      = '1' )  AS FINAL_DT    -- 최종승인일자
             , A.CONF_SCH_DT                                -- 회의예정일자
             , A.PLN_YM || A.PLN_DGR    AS FOCUS            -- 포커스용
             , A.APRV_NO                                    -- 결재번호
             , B.APRV_STATS                                 -- 결재상태
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE HRNK_CD = 'QS031' AND COM_CD = B.APRV_STATS ) AS APRV_STATS_NM -- 결재상태명
          FROM TQHA_RISK_DGR A      
              ,TQHA_APRV B
         WHERE A.SIT_CD     = p_SIT_CD
           AND A.SIT_CD     = B.SIT_CD (+)
           AND A.APRV_NO    = B.APRV_NO (+)
         ORDER BY A.PLN_YM DESC, A.PLN_DGR DESC
        ;

    ------------------------------------------------------------------------------
    ELSIF p_WRK_TP = 'Q1' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                     -- 현장코드
             , A.PLN_YM                     -- 계획년월
             , A.PLN_DGR                    -- 계획차수
             , A.CUST_CD                    -- 협력업체코드
             , B.CUST_NM AS VNDR_NM         -- 협력업체명
             , A.VNDR_SEQ                   -- 협력업체순번
             , A.CTP_CD                     -- 공종코드
             , C.CTP_NM                     -- 공종명
             , A.UNT_CD                     -- 단위코드
             , D.UNT_NM                     -- 단위명
             , A.CHK_ITM_CD                 -- 위험요인항목코드
             , A.CHK_ITM_NM                 -- 위험요인항목명
             , A.CHK_LOC                    -- 점검장소
             , A.DISS_SHP                   -- 재해형태(공통코드 QS036)
             , A.RISK_FREQ                  -- 위험빈도(공통코드 QS003)
             , A.RISK_APRV                  -- 위험강도(공통코드 QS004)
             , A.RISK_CRIT   	            -- 위험성레벨(QS063)
             , A.RISK_GRD                   -- 위험등급(공통코드 QS024)
             , A.PRRT_REG                   -- 중점등록(공통코드 QS002)             
             , A.RISK_FREQ2                  -- 위험빈도(공통코드 QS003)
             , A.RISK_APRV2                  -- 위험강도(공통코드 QS004)
             , A.RISK_CRIT2   	            -- 위험성레벨(QS063)
             , A.RISK_GRD2                   -- 위험등급(공통코드 QS024)             
             , A.RISK_FREQ3                  -- 위험빈도(공통코드 QS003)
             , A.RISK_APRV3                  -- 위험강도(공통코드 QS004)
             , A.RISK_CRIT3   	            -- 위험성레벨(QS063)
             , A.RISK_GRD3                   -- 위험등급(공통코드 QS024)             
             , A.RISK_FREQ4                  -- 위험빈도(공통코드 QS003)
             , A.RISK_APRV4                  -- 위험강도(공통코드 QS004)
             , A.RISK_CRIT4   	            -- 위험성레벨(QS063)
             , A.RISK_GRD4                   -- 위험등급(공통코드 QS024)             
             , A.RISK_FREQ5                  -- 위험빈도(공통코드 QS003)
             , A.RISK_APRV5                  -- 위험강도(공통코드 QS004)
             , A.RISK_CRIT5   	            -- 위험성레벨(QS063)
             , A.RISK_GRD5                   -- 위험등급(공통코드 QS024)             
             , A.RISK_FREQ6                  -- 위험빈도(공통코드 QS003)
             , A.RISK_APRV6                  -- 위험강도(공통코드 QS004)
             , A.RISK_CRIT6   	            -- 위험성레벨(QS063)
             , A.RISK_GRD6                   -- 위험등급(공통코드 QS024)    
             , A.MNG_SUPR
             , A.MGR_OPIN                 --관리자의견
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.MNG_SUPR ) AS MNG_SUPR_NM  -- 관리감독자성명           
             , A.SAFT_MGR                 --안전관리자
             , A.SAFT_OPIN                 --안전의견
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SAFT_MGR ) AS SAFT_MGR_NM  -- 안전관리자성명           
             , A.SITE_OMGR                 --현장소장
             , A.SITE_OPIN                 --현장소장의견
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SITE_OMGR ) AS SITE_OMGR_NM -- 현장소장성명
             , A.IMPRV_CPLN             -- 개선대책
             , A.WRK_PSNNO              -- 작업인원
             , A.MA_PSN                 -- 조치자(업체)
             , A.MA_CNFR                -- 확인자(안전관리자)
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.MA_CNFR ) AS MA_CNFR_NM        -- 확인자성명
             , A.WRK_STR_DT                  -- 작업시작일자
             , A.WRK_END_DT                  -- 작업종료일자
             , A.IMPRV_STR_DT                -- 개선시작일자
             , A.IMPRV_END_DT                -- 개선종료일자
             , A.CHK_LOC                     -- 점검위치
             ,(SELECT DECODE(COUNT(1),0,'중흥','협력사') FROM TQHA_VNDR WHERE SIT_CD = A.SIT_CD AND VNDR_PSN_ID = A.IPT_ID) AS REG_DIV
             , A.VNDR_WRK_NM
             , A.VNDR_WRK_OPIN
          FROM TQHA_RISK_CHK   A
             , VQSZ_TRADE       B 
             , TQHA_CTP         C
             , TQHA_CTPUNT      D
             , TCOZ_USR_INFO    E
         WHERE A.CUST_CD        = B.CUST_CD
           AND A.CTP_CD         = C.CTP_CD
           AND A.CTP_CD         = D.CTP_CD
           AND A.UNT_CD         = D.UNT_CD
           AND A.MA_CNFR        = E.USR_ID
           AND A.SIT_CD         = p_SEARCH_SIT_CD
           AND A.PLN_YM         = p_SEARCH_PLN_YM
           AND A.PLN_DGR        = p_SEARCH_PLN_DGR
           AND A.CUST_CD LIKE p_SEARCH_VNDR_CD ||'%'
           AND A.VNDR_SEQ LIKE p_SEARCH_VNDR_SEQ ||'%'
           AND (NVL(p_CUST_CD, '*') = '*' OR A.CUST_CD = p_CUST_CD)
        ;

    ------------------------------------------------------------------------------
    ELSIF p_WRK_TP = 'Q2' THEN

        OPEN RTN_CURSOR FOR
        SELECT SIT_CD           -- 현장코드
             , PLN_YM           -- 계획년월
             , PLN_DGR          -- 계획차수
             , CUST_CD          -- 협력업체코드
             , VNDR_SEQ         -- 협력업체차수
          FROM TQHA_RISK_VNDR
         WHERE SIT_CD       = p_SEARCH_SIT_CD
           AND PLN_YM       = p_SEARCH_PLN_YM
           AND PLN_DGR      = p_SEARCH_PLN_DGR
           AND CUST_CD      = p_CUST_CD
           AND VNDR_SEQ     = p_VNDR_SEQ
           AND OBJ_YN       = '1'   -- 대상유무
        ;

    ------------------------------------------------------------------------------
    ELSIF p_WRK_TP = 'Q3' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD             -- 현장코드
             , A.PLN_YM             -- 계획년월
             , A.PLN_DGR            -- 계획차수
             , A.CONF_DT            -- 회의일자
             , A.CONF_PLC           -- 회의장소
             , A.AM_NOTICE          -- 공지사항
             , A.AREC_CTS           -- 회의록내용
             , A.AREC_ATFL_GRP      -- 회의록첨부파일그룹
             , A.PHOTO_GRP1         -- 회의록사진1
             , A.PHOTO_DESC_1       -- 회의록사진설명1
             , A.PHOTO_GRP2         -- 회의록사진2
             , A.PHOTO_DESC_2       -- 회의록사진설명2
             , (SELECT COUNT(SIT_CD) FROM TQHA_ASSLOG_CIRC 
                                      WHERE SIT_CD      = A.SIT_CD 
                                        AND PLN_YM      = A.PLN_YM 
                                        AND PLN_DGR     = A.PLN_DGR
                                        AND PRTR_YN     = '1'
               )                                                        AS PRTR_NO      -- 참석인원
             , (SELECT COUNT(SIT_CD) FROM TQHA_ASSLOG_CIRC 
                                      WHERE SIT_CD      = A.SIT_CD 
                                        AND PLN_YM      = A.PLN_YM 
                                        AND PLN_DGR     = A.PLN_DGR
                                        AND PRTR_YN     = '1'
                                        AND CO_DIV_CD   = '1'
               )                                                        AS PRTR_NO1     -- 당사참석인원
             , (SELECT COUNT(SIT_CD) FROM TQHA_ASSLOG_CIRC 
                                      WHERE SIT_CD      = A.SIT_CD 
                                        AND PLN_YM      = A.PLN_YM 
                                        AND PLN_DGR     = A.PLN_DGR
                                        AND PRTR_YN     = '1'
                                        AND CO_DIV_CD   = '2'
               )                                                        AS PRTR_NO2     -- 협력회사참석인원
          FROM TQHB_RISK_DGR A
         WHERE 1=1
           AND A.SIT_CD     = p_SEARCH_SIT_CD
           AND A.PLN_YM     = p_SEARCH_PLN_YM
           AND A.PLN_DGR    = p_SEARCH_PLN_DGR
        ;
        
    ELSIF p_WRK_TP = 'Q4' THEN
        -- 금회추전계획
        OPEN RTN_CURSOR FOR
        WITH BASE_DATA AS (
		    SELECT A.SIT_CD                 -- 현장코드
		          ,A.PLN_YM                 -- 계획년월
		          ,A.PLN_DGR                -- 차수구분코드(QS005) 1 1차, 2 2차
		          ,A.CUST_CD                -- 협력업체코드
		          ,A.VNDR_SEQ               -- 협력업체순번
		          ,(SELECT CUST_NM FROM VQSZ_TRADE WHERE CUST_CD = A.CUST_CD) AS CUST_NM
		          ,A.CTP_CD                 -- 공종코드
		          ,A.UNT_CD                 -- 단위코드
		          ,(SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD) AS CTP_NM
		          ,(SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD) AS UNT_NM
		          ,A.CHK_ITM_CD             -- 점검항목코드
		          ,A.CHK_ITM_SEQ            -- 점검항목 정열순서
		          ,A.CHK_ITM_NM             -- 점검항목명
		          ,A.CHK_LOC                -- 점검위치
		          ,A.DISS_SHP                -- 재해형태(QS036)
		          ,A.IMPRV_CPLN             -- 개선대책 (TQHB_RISK_LST)
		          ,A.WRK_PSNNO              -- 작업인원
		          ,A.ITM_ADD_YN             -- 기존 : 0, 추가 : 1
		          -- TQHB_RISK_LST 기본 위험성 점수 및 의견 (최종점수 행용)
		          ,A.RISK_CRIT   AS LST_RISK_CRIT
		          ,A.RISK_CRIT2  AS LST_RISK_CRIT2
		          ,A.MGR_OPIN    AS LST_MGR_OPIN
		          
		          -- [TQHB_RISK_NAM 명단 컬럼]
		          ,B.EMPE_NO                -- 사원번호
		          ,B.APRS_NAMSEQ            -- 점검자 정열순서
		          ,B.CO_DIV_CD              -- 회사구분코드
		          ,B.JB_CD                  -- 직무/직급코드
		          ,NVL((SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = B.JB_CD AND HRNK_CD = 'QS077' AND USE_YN = '1'), '') AS JB_NM
		          ,CASE WHEN B.CO_DIV_CD = '1' THEN (SELECT USR_NM FROM TCOZ_USR_INFO WHERE EMPNO = B.EMPE_NO) 
		                                            || '/' || NVL((SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = B.JB_CD AND HRNK_CD = 'QS077' AND USE_YN = '1'), '')
		                WHEN B.CO_DIV_CD = '2' THEN (SELECT PNM FROM TQHB_VNDRNAM WHERE SIT_CD = A.SIT_CD AND CUST_CD = A.CUST_CD AND VNDR_SEQ = A.VNDR_SEQ AND EMPE_NO = B.EMPE_NO) 
		                                            || '/' || NVL((SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = B.JB_CD AND HRNK_CD = 'QS077' AND USE_YN = '1'), '')
		           END AS USR_NM
		           
		          -- [TQHB_RISK_CHK 실제 작성자 본인의 점수만 매핑 (미입력자는 NULL)]
		          ,TO_NUMBER(C.RISK_FREQ)  AS RISK_FREQ   
		          ,TO_NUMBER(C.RISK_APRV)  AS RISK_APRV   
		          ,TO_NUMBER(C.RISK_CRIT)  AS RISK_CRIT   
		          ,C.RISK_GRD                            
		          ,TO_NUMBER(C.RISK_FREQ2) AS RISK_FREQ2  
		          ,TO_NUMBER(C.RISK_APRV2) AS RISK_APRV2  
		          ,TO_NUMBER(C.RISK_CRIT2) AS RISK_CRIT2  
		          ,C.RISK_GRD2                            
		          ,C.MGR_OPIN               
		          ,C.SBM_DT                 
		          ,C.SBM_YN                 
		      FROM TQHB_RISK_LST A
		      -- 1. 해당 조건의 전체 점검자 명단 조인
		      INNER JOIN TQHB_RISK_NAM B
		        ON A.SIT_CD   = B.SIT_CD
		       AND A.PLN_YM   = B.PLN_YM
		       AND A.PLN_DGR  = B.PLN_DGR
		       AND A.CUST_CD  = B.CUST_CD
		       AND A.VNDR_SEQ = B.VNDR_SEQ
		      -- 2. 실제 점수를 작성했는지 확인하여 LEFT JOIN
		      LEFT JOIN TQHB_RISK_CHK C
		        ON A.SIT_CD     = C.SIT_CD
		       AND A.PLN_YM     = C.PLN_YM
		       AND A.PLN_DGR    = C.PLN_DGR
		       AND A.CUST_CD    = C.CUST_CD
		       AND A.VNDR_SEQ   = C.VNDR_SEQ
		       AND A.CTP_CD     = C.CTP_CD
		       AND A.UNT_CD     = C.UNT_CD
		       AND A.CHK_ITM_CD = C.CHK_ITM_CD
		       AND B.EMPE_NO    = C.EMPE_NO
		     WHERE A.SIT_CD   = p_SEARCH_SIT_CD                      -- 현장코드
		       AND A.PLN_YM   = p_SEARCH_PLN_YM                      -- 계획년월
		       AND A.PLN_DGR  = p_SEARCH_PLN_DGR                     -- 차수구분코드
		),
		SUMMARY_DATA AS (
		    -- 1. 원래 조회 데이터 (업체/점검자별 상세)
		    SELECT SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CUST_NM
		          ,CTP_CD, UNT_CD, CTP_NM, UNT_NM, CHK_ITM_CD, CHK_ITM_SEQ, CHK_ITM_NM
		          ,CHK_LOC, DISS_SHP, IMPRV_CPLN, WRK_PSNNO, ITM_ADD_YN
		          ,1 AS ROW_DIV
		          ,APRS_NAMSEQ
		          ,EMPE_NO
		          ,CO_DIV_CD
		          ,JB_CD
		          ,JB_NM
		          ,SBM_YN
		          ,USR_NM
		          ,TO_CHAR(RISK_FREQ)  AS RISK_FREQ
		          ,TO_CHAR(RISK_APRV)  AS RISK_APRV
		          ,TO_CHAR(RISK_CRIT)  AS RISK_CRIT
		          ,TO_CHAR(RISK_CRIT2) AS RISK_CRIT2
		          ,MGR_OPIN
		      FROM BASE_DATA
		
		    UNION ALL
		
		    -- 2. 평균점수 행 (각 업체/위험요인 항목별 평균)
		    SELECT SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CUST_NM
		          ,CTP_CD, UNT_CD, CTP_NM, UNT_NM, CHK_ITM_CD, CHK_ITM_SEQ, CHK_ITM_NM
		          ,CHK_LOC, DISS_SHP, IMPRV_CPLN, WRK_PSNNO, ITM_ADD_YN
		          ,2 AS ROW_DIV
		          ,998 AS APRS_NAMSEQ
		          ,NULL AS EMPE_NO
		          ,NULL AS CO_DIV_CD
		          ,NULL AS JB_CD
		          ,NULL AS JB_NM
		          ,NULL AS SBM_YN
		          ,'평균점수' AS USR_NM
		          ,NULL AS RISK_FREQ
		          ,NULL AS RISK_APRV
		          ,TO_CHAR(ROUND(AVG(RISK_CRIT), 1))  AS RISK_CRIT  -- 위험성 평균
		          ,TO_CHAR(ROUND(AVG(RISK_CRIT2), 1)) AS RISK_CRIT2 -- 개선후 위험성 평균
		          ,NULL AS MGR_OPIN
		      FROM BASE_DATA
		     GROUP BY SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CUST_NM
		             ,CTP_CD, UNT_CD, CTP_NM, UNT_NM, CHK_ITM_CD, CHK_ITM_SEQ, CHK_ITM_NM
		             ,CHK_LOC, DISS_SHP, IMPRV_CPLN, WRK_PSNNO, ITM_ADD_YN
		
		    UNION ALL
		
		    -- 3. 최종점수 행 (BASE_DATA에서 직접 집계)
		    SELECT SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CUST_NM
		          ,CTP_CD, UNT_CD, CTP_NM, UNT_NM, CHK_ITM_CD, CHK_ITM_SEQ, CHK_ITM_NM
		          ,CHK_LOC, DISS_SHP, IMPRV_CPLN, WRK_PSNNO, ITM_ADD_YN
		          ,3 AS ROW_DIV
		          ,999 AS APRS_NAMSEQ
		          ,NULL AS EMPE_NO
		          ,NULL AS CO_DIV_CD
		          ,NULL AS JB_CD
		          ,NULL AS JB_NM
		          ,NULL AS SBM_YN
		          ,'최종점수' AS USR_NM
		          ,NULL AS RISK_FREQ
		          ,NULL AS RISK_APRV
		          ,TO_CHAR(MAX(LST_RISK_CRIT))  AS RISK_CRIT   -- TQHB_RISK_LST의 위험성 점수
		          ,TO_CHAR(MAX(LST_RISK_CRIT2)) AS RISK_CRIT2  -- TQHB_RISK_LST의 개선후 위험성 점수
		          ,MAX(LST_MGR_OPIN)            AS MGR_OPIN
		      FROM BASE_DATA
		     GROUP BY SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CUST_NM
		             ,CTP_CD, UNT_CD, CTP_NM, UNT_NM, CHK_ITM_CD, CHK_ITM_SEQ, CHK_ITM_NM
		             ,CHK_LOC, DISS_SHP, IMPRV_CPLN, WRK_PSNNO, ITM_ADD_YN
		)
		SELECT S.SIT_CD
		      ,S.PLN_YM
		      ,S.PLN_DGR
		      ,S.CUST_CD
		      ,S.VNDR_SEQ
		      ,S.CUST_NM
		      ,S.CTP_CD
		      ,S.UNT_CD
		      ,S.CTP_NM
		      ,S.UNT_NM
		      ,S.CHK_ITM_CD
		      ,S.CHK_ITM_SEQ
		      ,S.CHK_ITM_NM
		      ,S.CHK_LOC
		      ,S.DISS_SHP
		      ,S.IMPRV_CPLN
		      ,S.WRK_PSNNO
		      ,S.ITM_ADD_YN
		      ,S.RISK_FREQ      -- 빈도
		      ,S.RISK_APRV      -- 강도
		      ,S.RISK_CRIT      -- 위험성
		      ,S.RISK_CRIT2     -- 개선후 위험성
		      ,S.MGR_OPIN
		      ,S.EMPE_NO
		      ,S.APRS_NAMSEQ
		      ,S.CO_DIV_CD
		      ,S.JB_CD
		      ,S.JB_NM          -- 직급명
		      ,S.USR_NM         -- 사용자명/직급명
		      ,S.SBM_YN  
		      ,V.SBM_YN AS VNDR_SBM_YN  -- 업체별 제출 여부 (LEFT JOIN)
		  FROM SUMMARY_DATA S
		  LEFT JOIN TQHB_RISK_VNDR V
		    ON S.SIT_CD   = V.SIT_CD
		   AND S.PLN_YM   = V.PLN_YM
		   AND S.PLN_DGR  = V.PLN_DGR
		   AND S.CUST_CD  = V.CUST_CD
		   AND S.VNDR_SEQ = V.VNDR_SEQ
		 ORDER BY S.CUST_CD
		        , S.VNDR_SEQ
		        , S.CTP_CD
		        , S.UNT_CD
		        , S.CHK_ITM_CD
		        , S.DISS_SHP
		        , S.ROW_DIV
		        , S.APRS_NAMSEQ
    
        ;

    END IF;


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_RISK_CHK_Q;
/

-- PQHA_RISK_CHK_S
DROP PROCEDURE "PQHA_RISK_CHK_S";
CREATE PROCEDURE "PQHA_RISK_CHK_S" (
    p_WRK_TP                VARCHAR2 :='U'                                      -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID                VARCHAR2                                            -- 사용자 ID
,   p_WRK_IP                VARCHAR2                                            -- 사용자 IP
,   p_SIT_CD                TQHA_RISK_CHK.SIT_CD                %TYPE           -- 현장코드
,   p_PLN_YM                TQHA_RISK_CHK.PLN_YM                %TYPE           -- 계획년월
,   p_PLN_DGR               TQHA_RISK_CHK.PLN_DGR               %TYPE           -- 차수구분코드(QS005) 1 1차,2 2차
,   p_CUST_CD               TQHA_RISK_CHK.CUST_CD               %TYPE           -- 협력업체코드
,   p_VNDR_SEQ              TQHA_RISK_CHK.VNDR_SEQ              %TYPE           -- 업체순번
,   p_CTP_CD                TQHA_RISK_CHK.CTP_CD                %TYPE           -- 공종코드
,   p_UNT_CD                TQHA_RISK_CHK.UNT_CD                %TYPE           -- 단위코드
,   p_CHK_ITM_CD            TQHA_RISK_CHK.CHK_ITM_CD            %TYPE           -- 점검항목코드
,   p_CHK_ITM_NM            TQHA_RISK_CHK.CHK_ITM_NM            %TYPE           -- 점검항목명 
,   p_CHK_LOC               TQHA_RISK_CHK.CHK_LOC               %TYPE           -- 점점위치
,   p_DISS_SHP              TQHA_RISK_CHK.DISS_SHP              %TYPE           -- 재해형태(QS036)
,   p_RISK_FREQ             TQHA_RISK_CHK.RISK_FREQ             %TYPE           -- 빈도레벨(QS003) 
,   p_RISK_APRV             TQHA_RISK_CHK.RISK_APRV             %TYPE           -- 강도레벨(QS004) 
,   p_RISK_CRIT             TQHA_RISK_CHK.RISK_CRIT             %TYPE           -- 위험성레벨(QS063) 
,   p_RISK_GRD              TQHA_RISK_CHK.RISK_GRD              %TYPE           -- 위험등급(QS024) 
,   p_PRRT_REG              TQHA_RISK_CHK.PRRT_REG              %TYPE           -- 중점등록(QS002) O, X 
,   p_RISK_FREQ2            TQHA_RISK_CHK.RISK_FREQ             %TYPE           -- 빈도레벨(QS003) 
,   p_RISK_APRV2            TQHA_RISK_CHK.RISK_APRV             %TYPE           -- 강도레벨(QS004) 
,   p_RISK_CRIT2            TQHA_RISK_CHK.RISK_CRIT             %TYPE           -- 위험성레벨(QS063) 
,   p_RISK_GRD2             TQHA_RISK_CHK.RISK_GRD              %TYPE           -- 위험등급(QS024) 
,   p_RISK_FREQ3            TQHA_RISK_CHK.RISK_FREQ             %TYPE           -- 빈도레벨(QS003) 
,   p_RISK_APRV3            TQHA_RISK_CHK.RISK_APRV             %TYPE           -- 강도레벨(QS004) 
,   p_RISK_CRIT3            TQHA_RISK_CHK.RISK_CRIT             %TYPE           -- 위험성레벨(QS063) 
,   p_RISK_GRD3             TQHA_RISK_CHK.RISK_GRD              %TYPE           -- 위험등급(QS024) 
,   p_RISK_FREQ4            TQHA_RISK_CHK.RISK_FREQ             %TYPE           -- 빈도레벨(QS003) 
,   p_RISK_APRV4            TQHA_RISK_CHK.RISK_APRV             %TYPE           -- 강도레벨(QS004) 
,   p_RISK_CRIT4            TQHA_RISK_CHK.RISK_CRIT             %TYPE           -- 위험성레벨(QS063) 
,   p_RISK_GRD4             TQHA_RISK_CHK.RISK_GRD              %TYPE           -- 위험등급(QS024) 
,   p_RISK_FREQ5            TQHA_RISK_CHK.RISK_FREQ             %TYPE           -- 빈도레벨(QS003) 
,   p_RISK_APRV5            TQHA_RISK_CHK.RISK_APRV             %TYPE           -- 강도레벨(QS004) 
,   p_RISK_CRIT5            TQHA_RISK_CHK.RISK_CRIT             %TYPE           -- 위험성레벨(QS063) 
,   p_RISK_GRD5             TQHA_RISK_CHK.RISK_GRD              %TYPE           -- 위험등급(QS024) 
,   p_RISK_FREQ6            TQHA_RISK_CHK.RISK_FREQ             %TYPE           -- 빈도레벨(QS003) 
,   p_RISK_APRV6            TQHA_RISK_CHK.RISK_APRV             %TYPE           -- 강도레벨(QS004) 
,   p_RISK_CRIT6            TQHA_RISK_CHK.RISK_CRIT             %TYPE           -- 위험성레벨(QS063) 
,   p_RISK_GRD6             TQHA_RISK_CHK.RISK_GRD              %TYPE           -- 위험등급(QS024)
,   p_MNG_SUPR              TQHA_RISK_CHK.MNG_SUPR              %TYPE           -- 관리감독자명
,   p_MGR_OPIN              TQHA_RISK_CHK.MGR_OPIN              %TYPE           -- 관리자의견
,   p_SAFT_MGR              TQHA_RISK_CHK.SAFT_MGR              %TYPE           -- 안전관리자명
,   p_SAFT_OPIN             TQHA_RISK_CHK.SAFT_OPIN             %TYPE           -- 안전의견
,   p_SITE_OMGR             TQHA_RISK_CHK.SITE_OMGR             %TYPE           -- 현장소장명
,   p_SITE_OPIN             TQHA_RISK_CHK.SITE_OPIN             %TYPE           -- 현장소장의견
,   p_IMPRV_CPLN            TQHA_RISK_CHK.IMPRV_CPLN            %TYPE           -- 개선대책
,   p_WRK_PSNNO             TQHA_RISK_CHK.WRK_PSNNO             %TYPE           -- 작업인원
,   p_MA_PSN                TQHA_RISK_CHK.MA_PSN                %TYPE           -- 조치자(업체)
,   p_MA_CNFR               TQHA_RISK_CHK.MA_CNFR               %TYPE           -- 확인자
,   p_WRK_STR_DT            TQHA_RISK_CHK.WRK_STR_DT            %TYPE           -- 작업시작일자
,   p_WRK_END_DT            TQHA_RISK_CHK.WRK_END_DT            %TYPE           -- 작업종료일자
,   p_IMPRV_STR_DT          TQHA_RISK_CHK.IMPRV_STR_DT          %TYPE           -- 개선시작일자
,   p_IMPRV_END_DT          TQHA_RISK_CHK.IMPRV_END_DT          %TYPE           -- 개선종료일자
,   p_VNDR_WRK_NM           TQHA_RISK_CHK.VNDR_WRK_NM           %TYPE           -- 근로자대표명
,   p_VNDR_WRK_OPIN         TQHA_RISK_CHK.VNDR_WRK_OPIN         %TYPE           -- 근로자대표의견
)
IS
    /**************************************************************************************************************************
      Purpose :

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2021/11/22 16:44:41                         최초생성

    **************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_CNT           NUMBER;


BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_YM IS NULL)  THEN
        ERR_MSG := '계획년월는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_DGR IS NULL)  THEN
        ERR_MSG := '차수구분코드(QS005) 1 1차,2 2차는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CUST_CD IS NULL)  THEN
        ERR_MSG := '협력업체코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_VNDR_SEQ IS NULL)  THEN
        ERR_MSG := '업체순번는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CTP_CD IS NULL)  THEN
        ERR_MSG := '공종코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_UNT_CD IS NULL)  THEN
        ERR_MSG := '단위코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CHK_ITM_CD IS NULL)  THEN
        ERR_MSG := '점검항목코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN

        DELETE
          FROM TQHA_RISK_CHK
         WHERE SIT_CD           = p_SIT_CD          -- 현장코드
           AND PLN_YM           = p_PLN_YM          -- 계획년월
           AND PLN_DGR          = p_PLN_DGR         -- 차수구분코드(QS005) 1 1차,2 2차
           AND CUST_CD          = p_CUST_CD         -- 협력업체코드
           AND VNDR_SEQ         = p_VNDR_SEQ        -- 업체순번
           AND CTP_CD           = p_CTP_CD          -- 공종코드
           AND UNT_CD           = p_UNT_CD          -- 단위코드
           AND CHK_ITM_CD       = p_CHK_ITM_CD      -- 점검항목코드
        ;

    ---------------------------------------------------------------------------------
    ELSIF (p_WRK_TP ='U') THEN

        UPDATE TQHA_RISK_CHK
           SET DISS_SHP             = p_DISS_SHP            -- 재해형태(QS036)
             , RISK_FREQ            = p_RISK_FREQ           -- 빈도레벨(QS003) 
             , RISK_APRV            = p_RISK_APRV           -- 강도레벨(QS004) 
             , RISK_CRIT            = p_RISK_CRIT           -- 위험성레벨(QS063)
             , RISK_GRD             = p_RISK_GRD            -- 위험등급(QS024) 
             , PRRT_REG             = p_PRRT_REG            -- 중점등록(QS002) O, X             
             , RISK_FREQ2           = p_RISK_FREQ2           -- 빈도레벨(QS003) 
             , RISK_APRV2           = p_RISK_APRV2           -- 강도레벨(QS004) 
             , RISK_CRIT2           = p_RISK_CRIT2           -- 위험성레벨(QS063)
             , RISK_GRD2            = p_RISK_GRD2            -- 위험등급(QS024)              
             , RISK_FREQ3           = p_RISK_FREQ3           -- 빈도레벨(QS003) 
             , RISK_APRV3           = p_RISK_APRV3           -- 강도레벨(QS004) 
             , RISK_CRIT3           = p_RISK_CRIT3           -- 위험성레벨(QS063)
             , RISK_GRD3            = p_RISK_GRD3            -- 위험등급(QS024)              
             , RISK_FREQ4           = p_RISK_FREQ4           -- 빈도레벨(QS003) 
             , RISK_APRV4           = p_RISK_APRV4           -- 강도레벨(QS004) 
             , RISK_CRIT4           = p_RISK_CRIT4           -- 위험성레벨(QS063)
             , RISK_GRD4            = p_RISK_GRD4            -- 위험등급(QS024)              
             , RISK_FREQ5           = p_RISK_FREQ5           -- 빈도레벨(QS003) 
             , RISK_APRV5           = p_RISK_APRV5           -- 강도레벨(QS004) 
             , RISK_CRIT5           = p_RISK_CRIT5           -- 위험성레벨(QS063)
             , RISK_GRD5            = p_RISK_GRD5            -- 위험등급(QS024)              
             , RISK_FREQ6           = p_RISK_FREQ6           -- 빈도레벨(QS003) 
             , RISK_APRV6           = p_RISK_APRV6           -- 강도레벨(QS004) 
             , RISK_CRIT6           = p_RISK_CRIT6           -- 위험성레벨(QS063)
             , RISK_GRD6            = p_RISK_GRD6            -- 위험등급(QS024)             
             , MNG_SUPR            = p_MNG_SUPR            -- 관리감독자명
             , MGR_OPIN            = p_MGR_OPIN            -- 관리자의견
             , SAFT_MGR            = p_SAFT_MGR            -- 안전관리자명
             , SAFT_OPIN            = p_SAFT_OPIN            -- 안전의견
             , SITE_OMGR            = p_SITE_OMGR            -- 현장소장명
             , SITE_OPIN            = p_SITE_OPIN            -- 현장소장의견             
             , IMPRV_CPLN           = p_IMPRV_CPLN          -- 개선대책
             , WRK_PSNNO            = p_WRK_PSNNO           -- 작업인원
             , MA_PSN               = p_MA_PSN              -- 조치자(업체)
             , MA_CNFR              = p_MA_CNFR             -- 확인자
             , WRK_STR_DT           = p_WRK_STR_DT          -- 작업시작일자
             , WRK_END_DT           = p_WRK_END_DT          -- 작업종료일자
             , IMPRV_STR_DT         = p_IMPRV_STR_DT        -- 개선시작일자
             , IMPRV_END_DT         = p_IMPRV_END_DT        -- 개선종료일자
             , CHK_ITM_NM           = p_CHK_ITM_NM          -- 점검항목명
             , CHK_LOC              = p_CHK_LOC             -- 점검위치
             , VNDR_WRK_NM			= (SELECT VNDR_WRK_NM FROM TQHA_VNDR WHERE SIT_CD = p_SIT_CD AND CUST_CD = p_CUST_CD AND VNDR_SEQ = p_VNDR_SEQ)
             , VNDR_WRK_OPIN		= p_VNDR_WRK_OPIN
             , UPD_ID               = p_WRK_ID              -- 수정ID
             , UPD_DTM              = SYSDATE()             -- 수정일시
             , UPD_IP               = p_WRK_IP              -- 수정IP
         WHERE SIT_CD               = p_SIT_CD              -- 현장코드
           AND PLN_YM               = p_PLN_YM              -- 계획년월
           AND PLN_DGR              = p_PLN_DGR             -- 차수구분코드(QS005) 1 1차,2 2차
           AND CUST_CD              = p_CUST_CD             -- 협력업체코드
           AND VNDR_SEQ             = p_VNDR_SEQ            -- 업체순번
           AND CTP_CD               = p_CTP_CD              -- 공종코드
           AND UNT_CD               = p_UNT_CD              -- 단위코드
           AND CHK_ITM_CD           = p_CHK_ITM_CD          -- 점검항목코드
        ;

    ---------------------------------------------------------------------------------
    ELSE

        SELECT COUNT(1)
          INTO v_CNT
          FROM TQHA_RISK_CHK
         WHERE SIT_CD       = p_SIT_CD
           AND PLN_YM       = p_PLN_YM
           AND PLN_DGR      = p_PLN_DGR
           AND CUST_CD      = p_CUST_CD
           AND VNDR_SEQ     = p_VNDR_SEQ
           AND CTP_CD       = p_CTP_CD
           AND UNT_CD       = p_UNT_CD
           AND CHK_ITM_CD   = p_CHK_ITM_CD
        ;

        IF v_CNT > 0 THEN
            ERR_MSG := '중복되는 점검항목이 존재합니다.';
            RAISE USER_EXCEPTION;
        END IF;

        INSERT 
          INTO TQHA_RISK_CHK
             ( SIT_CD                   -- 현장코드
             , PLN_YM                   -- 계획년월
             , PLN_DGR                  -- 차수구분코드(QS005)
             , CUST_CD                  -- 협력업체코드
             , VNDR_SEQ                 -- 업체순번
             , CTP_CD                   -- 공종코드
             , UNT_CD                   -- 단위코드
             , CHK_ITM_CD               -- 점검항목코드
             , DISS_SHP                 -- 재해형태(QS036)
             , RISK_FREQ                -- 빈도레벨(QS003) 
             , RISK_APRV                -- 강도레벨(QS004) 
             , RISK_CRIT                -- 위험성레벨(QS063)
             , RISK_GRD                 -- 위험등급(QS024) 
             , PRRT_REG                 -- 중점등록(QS002) O, X             
             , RISK_FREQ2                -- 빈도레벨(QS003) 
             , RISK_APRV2                -- 강도레벨(QS004) 
             , RISK_CRIT2                -- 위험성레벨(QS063)
             , RISK_GRD2                 -- 위험등급(QS024)              
             , RISK_FREQ3                -- 빈도레벨(QS003) 
             , RISK_APRV3                -- 강도레벨(QS004) 
             , RISK_CRIT3                -- 위험성레벨(QS063)
             , RISK_GRD3                 -- 위험등급(QS024)              
             , RISK_FREQ4                -- 빈도레벨(QS003) 
             , RISK_APRV4                -- 강도레벨(QS004) 
             , RISK_CRIT4                -- 위험성레벨(QS063)
             , RISK_GRD4                 -- 위험등급(QS024)              
             , RISK_FREQ5                -- 빈도레벨(QS003) 
             , RISK_APRV5                -- 강도레벨(QS004) 
             , RISK_CRIT5                -- 위험성레벨(QS063)
             , RISK_GRD5                 -- 위험등급(QS024)              
             , RISK_FREQ6                -- 빈도레벨(QS003) 
             , RISK_APRV6                -- 강도레벨(QS004) 
             , RISK_CRIT6                -- 위험성레벨(QS063)
             , RISK_GRD6                 -- 위험등급(QS024)
             , IMPRV_CPLN               -- 개선대책             
             , MNG_SUPR                   -- 관리감독자명
             , MGR_OPIN                   -- 관리자의견
             , SAFT_MGR                   -- 안전관리자명
             , SAFT_OPIN                    -- 안전의견
             , SITE_OMGR                    -- 현장소장명
             , SITE_OPIN                    -- 현장소장의견  
             , WRK_PSNNO                -- 작업인원
             , MA_PSN                   -- 조치자(업체)
             , MA_CNFR                  -- 확인자
             , WRK_STR_DT               -- 작업시작일자
             , WRK_END_DT               -- 작업종료일자
             , IMPRV_STR_DT             -- 개선시작일자
             , IMPRV_END_DT             -- 개선종료일자
             , CHK_ITM_NM               -- 점검항목명
             , CHK_LOC                  -- 점검위치
             , IPT_ID                   -- 입력ID
             , IPT_DTM                  -- 입력일시
             , IPT_IP                   -- 입력IP
             , UPD_ID                   -- 수정ID
             , UPD_DTM                  -- 수정일시
             , UPD_IP                   -- 수정IP
             )
        VALUES 
             ( p_SIT_CD                 -- 현장코드
             , p_PLN_YM                 -- 계획년월
             , p_PLN_DGR                -- 차수구분코드(QS005)
             , p_CUST_CD                -- 협력업체코드
             , p_VNDR_SEQ               -- 업체순번
             , p_CTP_CD                 -- 공종코드
             , p_UNT_CD                 -- 단위코드
             , p_CHK_ITM_CD             -- 점검항목코드
             , p_DISS_SHP               -- 재해형태(QS036)
             , p_RISK_FREQ              -- 빈도레벨(QS003) 
             , p_RISK_APRV              -- 강도레벨(QS004) 
             , p_RISK_CRIT              -- 위험성레벨(QS063)
             , p_RISK_GRD               -- 위험등급(QS024)        
             , p_PRRT_REG               -- 중점등록(QS002) O, X     
             , p_RISK_FREQ2              -- 빈도레벨(QS003) 
             , p_RISK_APRV2              -- 강도레벨(QS004) 
             , p_RISK_CRIT2              -- 위험성레벨(QS063)
             , p_RISK_GRD2               -- 위험등급(QS024)              
             , p_RISK_FREQ3              -- 빈도레벨(QS003) 
             , p_RISK_APRV3              -- 강도레벨(QS004) 
             , p_RISK_CRIT3              -- 위험성레벨(QS063)
             , p_RISK_GRD3               -- 위험등급(QS024)              
             , p_RISK_FREQ4              -- 빈도레벨(QS003) 
             , p_RISK_APRV4              -- 강도레벨(QS004) 
             , p_RISK_CRIT4              -- 위험성레벨(QS063)
             , p_RISK_GRD4               -- 위험등급(QS024)              
             , p_RISK_FREQ5              -- 빈도레벨(QS003) 
             , p_RISK_APRV5              -- 강도레벨(QS004) 
             , p_RISK_CRIT5              -- 위험성레벨(QS063)
             , p_RISK_GRD5               -- 위험등급(QS024)              
             , p_RISK_FREQ6              -- 빈도레벨(QS003) 
             , p_RISK_APRV6              -- 강도레벨(QS004) 
             , p_RISK_CRIT6              -- 위험성레벨(QS063)
             , p_RISK_GRD6               -- 위험등급(QS024)
             , p_IMPRV_CPLN             -- 개선대책 
             , p_MNG_SUPR                -- 관리감독자명
             , p_MGR_OPIN                -- 관리자의견
             , p_SAFT_MGR                -- 안전관리자명
             , p_SAFT_OPIN                -- 안전의견
             , p_SITE_OMGR                -- 현장소장명
             , p_SITE_OPIN                -- 현장소장의견
             , p_WRK_PSNNO              -- 작업인원
             , p_MA_PSN                 -- 조치자(업체)
             , p_MA_CNFR                -- 확인자
             , p_WRK_STR_DT             -- 작업시작일자
             , p_WRK_END_DT             -- 작업종료일자
             , p_IMPRV_STR_DT           -- 개선시작일자
             , p_IMPRV_END_DT           -- 개선종료일자
             , p_CHK_ITM_NM             -- 점검항목명
             , p_CHK_LOC                -- 점검위치
             , p_WRK_ID                 -- 입력ID
             , SYSDATE()                -- 입력일시
             , p_WRK_IP                 -- 입력IP
             , p_WRK_ID                 -- 수정ID
             , SYSDATE()                -- 수정일시
             , p_WRK_IP                 -- 수정IP
             )
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHA_RISK_DGR_Q
DROP PROCEDURE "PQHA_RISK_DGR_Q";
CREATE PROCEDURE "PQHA_RISK_DGR_Q" (  
    p_WRK_TP        IN VARCHAR2 DEFAULT 'Q'         -- FLAG(Q: 조회)
,   p_SIT_CD        IN VARCHAR2                     -- 현장코드
,   RTN_CURSOR      OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [위험성평가일정 조회] 

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2023/12/04                                 최초생성  

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                                         -- 현장코드
             , A.PLN_YM                                         -- 계획년월
             , A.PLN_DGR                                        -- 계획차수
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.PLN_DGR AND HRNK_CD = 'QS005' ) AS PLN_DGR_NM -- 계획차수명
             , A.APRS_STR_DT                                    -- 평가시작일자
             , A.APRS_END_DT                                    -- 평가종료일자
             , A.VNDR_CMPL_DT                                   -- 업체작성완료일자
             , ( SELECT CASE MIN(NVL(SITE_APRV_STATS,0)) 
                             WHEN '0' THEN ''
                             WHEN '1' THEN MAX(SITE_APRV_DT) 
                              END FIN_DT
                   FROM TQHA_RISK_VNDR 
                  WHERE SIT_CD      = A.SIT_CD      -- 현장코드 변수
                    AND PLN_YM      = A.PLN_YM      -- 변수 ( 년월)
                    AND PLN_DGR     = A.PLN_DGR     -- 변수 ( 차수)
                    AND OBJ_YN      = '1' )     AS FINAL_DT     -- 최종승인일자
             , A.CONF_SCH_DT                                    -- 회의예정일자
          FROM TQHA_RISK_DGR A
         WHERE A.SIT_CD = p_SIT_CD
         ORDER BY A.PLN_YM DESC, A.PLN_DGR DESC
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END PQHA_RISK_DGR_Q;
/

-- PQHA_RISK_DGR_S
DROP PROCEDURE "PQHA_RISK_DGR_S";
CREATE PROCEDURE "PQHA_RISK_DGR_S" (
    p_WRK_TP            VARCHAR2 :='U'                          -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID            VARCHAR2                                -- 사용자 ID 
,   p_WRK_IP            VARCHAR2                                -- 사용자 IP 
,   p_SIT_CD            TQHA_RISK_DGR.SIT_CD%TYPE               -- 현장코드
,   p_PLN_YM            TQHA_RISK_DGR.PLN_YM%TYPE               -- 계획년월
,   p_PLN_DGR           TQHA_RISK_DGR.PLN_DGR%TYPE              -- 차수구분코드(QS005) 1 1차,2 2차
,   p_APRS_STR_DT       TQHA_RISK_DGR.APRS_STR_DT%TYPE          -- 평가시작일자
,   p_APRS_END_DT       TQHA_RISK_DGR.APRS_END_DT%TYPE          -- 평가종료일자
,   p_VNDR_CMPL_DT      TQHA_RISK_DGR.VNDR_CMPL_DT%TYPE         -- 업체작성완료일자
,   p_CONF_SCH_DT       TQHA_RISK_DGR.CONF_SCH_DT%TYPE          -- 회의예정일자 
)
IS 
    /**************************************************************************************************************************
      Purpose : 

      REVISIONS 
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2021/10/27 14:12:51                         최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;         -- ERROR 코드
    ERR_MSG        VARCHAR2(200);           -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_cnt               INTEGER;            -- 위험성 평가 일정 하위데이타 존재 여부

    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_YM IS NULL  AND p_WRK_TP <> 'I')  THEN
        ERR_MSG := '계획년월는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_DGR IS NULL)  THEN
        ERR_MSG := '차수구분코드는(은) 필수 입력사항 입니다.'; 
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------
    -- 결재상태 체크
    SELECT MAX(T2.APRV_STATS)
         , MAX(T3.CD_NM )
      INTO v_APRV_STATS
         , v_APRV_STATS_NM
      FROM TQHA_RISK_DGR        T1
      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
                                  AND T1.APRV_NO    = T2.APRV_NO
      LEFT JOIN TCOA_COMCODE    T3 ON T2.APRV_STATS = T3.COM_CD 
                                  AND T3.HRNK_CD    = 'QS031'
     WHERE T1.SIT_CD    = p_SIT_CD
       AND T1.PLN_YM    = p_PLN_YM
       AND T1.PLN_DGR   = p_PLN_DGR
    ;

    IF v_APRV_STATS IN ('2', '4') THEN
        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------
    --  위험성 평가 일정 하위데이타 존재 여부
    IF p_WRK_TP = 'D' THEN

       SELECT NVL(COUNT(CUST_CD),0) 
         INTO v_cnt
         FROM TQHA_RISK_VNDR
        WHERE SIT_CD = p_SIT_CD
          AND PLN_YM = p_PLN_YM
          AND PLN_DGR = p_PLN_DGR ;

         -- 평가 대상업체 졵재여부 Validation
        IF v_cnt > 0 THEN
           ERR_MSG := '계획년월 "' || p_PLN_YM || '" 차수 "' || p_PLN_DGR || '"은(는) 하위 데이타가 존재하여 삭제할 수 없습니다. ';
           RAISE USER_EXCEPTION;
        END IF;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN

        DELETE 
          FROM TQHA_RISK_DGR
         WHERE SIT_CD   = p_SIT_CD          -- 현장코드
           AND PLN_YM   = p_PLN_YM          -- 계획년월
           AND PLN_DGR  = p_PLN_DGR         -- 차수구분코드(QS005) 1 1차,2 2차
        ;

    ----------------------------------------------------------------------------------------------------
    ELSIF (p_WRK_TP ='U') THEN

        UPDATE TQHA_RISK_DGR
           SET APRS_STR_DT      = p_APRS_STR_DT     -- 평가시작일자
             , APRS_END_DT      = p_APRS_END_DT     -- 평가종료일자
             , VNDR_CMPL_DT     = p_VNDR_CMPL_DT    -- 업체작성완료일자
             , CONF_SCH_DT      = p_CONF_SCH_DT     -- 회의예정일자
             , UPD_ID           = p_WRK_ID          -- 수정ID 
             , UPD_DTM          = SYSDATE()         -- 수정일시
             , UPD_IP           = p_WRK_IP          -- 수정IP
         WHERE SIT_CD           = p_SIT_CD          -- 현장코드
           AND PLN_YM           = p_PLN_YM          -- 계획년월
           AND PLN_DGR          = p_PLN_DGR         -- 차수구분코드(QS005) 1 1차,2 2차
        ;

    ----------------------------------------------------------------------------------------------------
    ELSE 

        INSERT 
          INTO TQHA_RISK_DGR
             ( SIT_CD               -- 현장코드
             , PLN_YM               -- 계획년월
             , PLN_DGR              -- 차수구분코드(QS005) 1 1차,2 2차
             , APRS_STR_DT          -- 평가시작일자
             , APRS_END_DT          -- 평가종료일자
             , VNDR_CMPL_DT         -- 업체작성완료일자
             , CONF_SCH_DT          -- 회의예정일자
             , IPT_ID               -- 입력ID
             , IPT_DTM              -- 입력일시
             , IPT_IP               -- 입력IP
             , UPD_ID               -- 수정ID
             , UPD_DTM              -- 수정일시
             , UPD_IP               -- 수정IP
             )
        VALUES 
             ( p_SIT_CD             -- 현장코드
             , P_PLN_YM             -- 계획년월
             , p_PLN_DGR            -- 차수구분코드(QS005) 1 1차,2 2차
             , p_APRS_STR_DT        -- 평가시작일자
             , p_APRS_END_DT        -- 평가종료일자
             , p_VNDR_CMPL_DT       -- 업체작성완료일자
             , p_CONF_SCH_DT        -- 회의예정일자
             , p_WRK_ID             -- 입력ID 
             , SYSDATE()            -- 입력일시
             , p_WRK_IP             -- 입력IP
             , p_WRK_ID             -- 수정ID
             , SYSDATE()            -- 수정일시
             , p_WRK_IP             -- 수정IP
             )
        ;

        -- 해당하는 협력업체
        MERGE 
          INTO TQHA_RISK_VNDR T
         USING (
                SELECT A.CUST_CD
                     , A.VNDR_SEQ
                  FROM TQHA_VNDR      A
                     , TQHA_RISK_VNDR B
                 WHERE A.SIT_CD = p_SIT_CD
                   AND ((TO_DATE(A.VNDR_STR_DT, 'YYYYMMDD') <= TO_DATE(p_APRS_STR_DT, 'YYYYMMDD') 
                         AND TO_DATE(A.VNDR_END_DT, 'YYYYMMDD') >= TO_DATE(p_APRS_END_DT, 'YYYYMMDD')) 
                          OR NVL(B.OBJ_YN, 0) = 1)
                   AND A.SIT_CD     = B.SIT_CD(+)
                   AND A.CUST_CD    = B.CUST_CD(+)
                   AND A.VNDR_SEQ   = B.VNDR_SEQ(+)
                   AND B.PLN_YM(+)  = p_PLN_YM
                   AND B.PLN_DGR(+) = p_PLN_DGR
               ) S
        ON (
                T.SIT_CD   = p_SIT_CD   
            AND T.PLN_YM   = p_PLN_YM   
            AND T.PLN_DGR  = p_PLN_DGR  
            AND T.CUST_CD  = S.CUST_CD  
            AND T.VNDR_SEQ = S.VNDR_SEQ
           )
        WHEN MATCHED THEN
            UPDATE 
               SET T.OBJ_YN     = '1'
                 , T.UPD_ID     = p_WRK_ID
                 , T.UPD_DTM    = SYSDATE
                 , T.UPD_IP     = p_WRK_IP
        WHEN NOT MATCHED THEN
            INSERT 
                 ( SIT_CD
                 , PLN_YM
                 , PLN_DGR
                 , CUST_CD
                 , VNDR_SEQ
                 , OBJ_YN
                 , VNDR_NOTI_YN
                 , IPT_ID
                 , IPT_DTM
                 , IPT_IP
                 , UPD_ID
                 , UPD_DTM
                 , UPD_IP
                 )
            VALUES 
                 ( p_SIT_CD
                 , p_PLN_YM
                 , p_PLN_DGR
                 , S.CUST_CD
                 , S.VNDR_SEQ
                 , '1'
                 , '0'
                 , p_WRK_ID
                 , SYSDATE
                 , p_WRK_IP
                 , p_WRK_ID
                 , SYSDATE
                 , p_WRK_IP
                 )
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END ;
/

-- PQHA_RISK_ITM_LIST_OTHER_Q
DROP PROCEDURE "PQHA_RISK_ITM_LIST_OTHER_Q";
CREATE PROCEDURE "PQHA_RISK_ITM_LIST_OTHER_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'         -- FLAG
,   p_SIT_CD            IN VARCHAR2                     -- 현장코드
,   p_PLN_YM            IN VARCHAR2                     -- 계획연월
,   p_PLN_DGR           IN VARCHAR2                     -- 계획차수
,   p_CUST_CD           IN VARCHAR2                     -- 업체코드
,   p_VNDR_SEQ          IN VARCHAR2                     -- 업체순번
,   p_CTP_CD            IN VARCHAR2                     -- 공종코드
,   p_UNT_CD            IN VARCHAR2                     -- 단위코드
,   p_DIFF_SIT_CD       IN VARCHAR2                     -- 타현장코드
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [위험성평가작성/검토] PROCEDRE 

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2026/02/09                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    -- 
    IF p_WRK_TP = 'Q1' THEN

        -- 그리드 조회 : 위험성평가 승인관리 - 협력업체
        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                   --현장코드
             , A.PLN_YM                   --계획년월 
             , A.PLN_DGR                  --계획차수
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.PLN_DGR AND HRNK_CD = 'QS005') AS PLN_DGR_NM  -- 계획차수명칭
             , A.CUST_CD                  --협력업체코드
             , A.VNDR_SEQ                 --협력업체차수
             , B.CUST_NM                  --협력업체명칭
             , A.SBM_YN                   --평가서제출여부
             , DECODE(NVL(A.SBM_YN,0), '1', '제출', '작성중') AS SBM_NM -- 제출여부명칭
             , A.SBM_DT                   --평가서제출일자
             , A.MNG_SUPR                 --관리감독자
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.MNG_SUPR ) AS MNG_SUPR_NM -- 관리감독자명
             , A.MNG_APRV_STATS           --관리감독자 승인상태(1승인, 2반려)
             , DECODE(NVL(A.SBM_YN,0), '1', DECODE(NVL(A.MNG_APRV_STATS,0), '1', '승인완료 ', DECODE(NVL(A.MNG_APRV_STATS,0), '2', '반려 ', '진행중')), '0', DECODE(NVL(A.MNG_APRV_STATS,0), '2', '반려 ', ''), '' ) AS MNG_APRV_STATS_NM -- 관리상태명칭                
             , A.MNG_APRV_DT              --관리감독자 승인일자
             , A.SAFT_MGR                 --안전관리자
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SAFT_MGR ) AS SAFT_MGR_NM -- 안전관리자명
             , A.SAFT_APRV_STATS          --안전관리자 승인상태(1승인 2반려)
             , DECODE(NVL(A.MNG_APRV_STATS,0), '1', DECODE(NVL(A.SAFT_APRV_STATS,0), '1', '승인완료 ', DECODE(NVL(A.SAFT_APRV_STATS,0), '2', '반려 ', '진행중')), '0', DECODE(NVL(A.SAFT_APRV_STATS,0), '1','승인', '2', '반려 ', ''), '' ) AS SAFT_APRV_STATS_NM -- 안전상태명칭
             , A.SAFT_APRV_DT             --안전관리자 승인일자
             , A.SITE_OMGR                --현장소장
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SITE_OMGR ) AS SITE_OMGR_NM -- 현장소장명
             , A.SITE_APRV_STATS          --현장소장 승인상태(1승인, 2반려)
             , DECODE(NVL(A.SAFT_APRV_STATS,0), '1', DECODE(NVL(A.SITE_APRV_STATS,0), '1', '승인완료 ', DECODE(NVL(A.SITE_APRV_STATS,0), '2', '반려 ', '진행중')), '0', DECODE(NVL(A.SITE_APRV_STATS,0), '2', '반려 ', ''), '' ) AS SITE_APRV_STATS_NM -- 소장상태명칭                
             , A.SITE_APRV_DT             --현장소장 승인일자
             , A.CUST_CD                  --협력업체코드
             , A.VNDR_WRK_NM
          FROM TQHA_RISK_VNDR A
             , VQSZ_TRADE B
         WHERE A.CUST_CD        = B.CUST_CD
           AND A.SIT_CD         = p_SIT_CD
           AND A.PLN_YM         = p_PLN_YM
           AND A.PLN_DGR        = p_PLN_DGR
           AND A.OBJ_YN         = '1'
        ;

    ---------------------------------------------------------------------------------------
    ELSIF p_WRK_TP = 'Q2' THEN

        -- 그리드 조회 : 위험성평가 승인관리 - 위험성평가서 항목
        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                     -- 현장코드
             , A.PLN_YM                      -- 계획년월
             , A.PLN_DGR                     -- 계획차수
             , A.CUST_CD                     -- 협력업체코드
             , A.VNDR_SEQ                    -- 협력업체차수
             , A.CTP_CD                      -- 공종코드
             , ( SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD ) AS CTP_NM           -- 공종명칭
             , A.UNT_CD                      -- 단위코드
             , ( SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD ) AS UNT_NM           -- 단위명칭
             , A.CHK_ITM_CD                  -- 위험요인항목코드
             , A.CHK_ITM_NM                  -- 위험요인항목명칭
             , A.PRRT_REG               -- 중점등록(공통코드 QS002)             
             , A.DISS_SHP               -- 재해형태(공통코드 QS036)
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.PRRT_REG AND HRNK_CD = 'QS002') AS PRRT_REG_NM  -- 중점등록
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.DISS_SHP AND HRNK_CD = 'QS036') AS DISS_SHP_NM  -- 재해형태             
             , A.RISK_FREQ              -- 위험빈도(공통코드 QS003)             
             , A.RISK_APRV              -- 위험강도(공통코드 QS004)             
             , A.RISK_CRIT              -- 위험성(공통코드 QS063)
             , A.RISK_GRD               -- 위험등급(공통코드 QS024)             
             , A.RISK_FREQ2              -- 위험빈도(공통코드 QS003)             
             , A.RISK_APRV2              -- 위험강도(공통코드 QS004)             
             , A.RISK_CRIT2              -- 위험성(공통코드 QS063)
             , A.RISK_GRD2               -- 위험등급(공통코드 QS024)             
             , A.RISK_FREQ3              -- 위험빈도(공통코드 QS003)             
             , A.RISK_APRV3              -- 위험강도(공통코드 QS004)             
             , A.RISK_CRIT3              -- 위험성(공통코드 QS063)
             , A.RISK_GRD3               -- 위험등급(공통코드 QS024)             
             , A.RISK_FREQ4              -- 위험빈도(공통코드 QS003)             
             , A.RISK_APRV4              -- 위험강도(공통코드 QS004)             
             , A.RISK_CRIT4              -- 위험성(공통코드 QS063)
             , A.RISK_GRD4               -- 위험등급(공통코드 QS024)             
             , A.RISK_FREQ5              -- 위험빈도(공통코드 QS003)             
             , A.RISK_APRV5              -- 위험강도(공통코드 QS004)             
             , A.RISK_CRIT5              -- 위험성(공통코드 QS063)
             , A.RISK_GRD5               -- 위험등급(공통코드 QS024)             
             , A.RISK_FREQ6              -- 위험빈도(공통코드 QS003)             
             , A.RISK_APRV6              -- 위험강도(공통코드 QS004)             
             , A.RISK_CRIT6              -- 위험성(공통코드 QS063)
             , A.RISK_GRD6               -- 위험등급(공통코드 QS024)
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.RISK_FREQ AND HRNK_CD = 'QS003') AS RISK_FREQ_NM  -- 빈도명
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.RISK_APRV AND HRNK_CD = 'QS004') AS RISK_APRV_NM  -- 강도명
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.RISK_CRIT AND HRNK_CD = 'QS063') AS RISK_CRIT_NM  -- 위험성
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.RISK_GRD  AND HRNK_CD = 'QS024') AS RISK_GRD_NM  -- 위험등급
             , A.MNG_SUPR
             , A.MGR_OPIN                 --관리자의견
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.MNG_SUPR ) AS MNG_SUPR_NM  -- 관리감독자성명           
             , A.SAFT_MGR                 --안전관리자
             , A.SAFT_OPIN                 --안전의견
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SAFT_MGR ) AS SAFT_MGR_NM  -- 안전관리자성명           
             , A.SITE_OMGR                 --현장소장
             , A.SITE_OPIN                 --현장소장의견
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SITE_OMGR ) AS SITE_OMGR_NM -- 현장소장성명
             , A.IMPRV_CPLN             -- 개선대책
             , A.WRK_PSNNO              -- 작업인원
             , A.MA_PSN                 -- 조치자(업체)
             , A.MA_CNFR                -- 확인자(안전관리자)
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.MA_CNFR ) AS MA_CNFR_NM        -- 확인자성명
             , A.WRK_STR_DT                  -- 작업시작일자
             , A.WRK_END_DT                  -- 작업종료일자
             , A.IMPRV_STR_DT                -- 개선시작일자
             , A.IMPRV_END_DT                -- 개선종료일자
             , A.CHK_LOC                     -- 점검위치
             ,(SELECT DECODE(COUNT(1),0,'중흥','협력사') FROM TQHA_VNDR WHERE SIT_CD = A.SIT_CD AND VNDR_PSN_ID = A.IPT_ID) AS REG_DIV
          FROM TQHA_RISK_CHK A
         WHERE A.SIT_CD         = p_SIT_CD
           AND A.PLN_YM         = p_PLN_YM
           AND A.PLN_DGR        = p_PLN_DGR
           AND A.CUST_CD        = p_CUST_CD
           AND A.VNDR_SEQ       = p_VNDR_SEQ
         ORDER 
            BY A.CTP_CD                      -- 공종코드
             , A.UNT_CD
             , A.CHK_ITM_CD
        ;

    ---------------------------------------------------------------------------------------
    ELSIF p_WRK_TP = 'Q3' THEN

        -- 그리드 조회 : 위험성평가 승인관리 - 검토의견
        OPEN RTN_CURSOR FOR
        SELECT SIT_CD          -- 현장코드
             , PLN_YM           -- 계획년월
             , PLN_DGR          -- 계획차수
             , CUST_CD          -- 협력업체코드
             , VNDR_SEQ         -- 협력업체차수
             , MNG_SUPR         -- 관리자ID
             , MNG_APRV_DT      -- 관리자승인일자
             , MNG_APRV_STATS   -- 관리자승인상태
             , SAFT_MGR         -- 안전관리자ID
             , SAFT_APRV_DT     -- 안전관리자승인일자
             , SAFT_APRV_STATS  -- 안전관리자승인상태
             , SITE_OMGR        -- 현장소장ID
             , SITE_APRV_DT     -- 현장소장승인일자
             , SITE_APRV_STATS  -- 현장소장승인상태
             , CHK_ATFL_GRP     -- 첨부파일그룹
             , SBM_YN           -- 평가서제출여부
             , SBM_DT           -- 평가서제출일자
             , (SELECT VNDR_PSN_CADDR
                FROM TQHA_VNDR
                WHERE CUST_CD = A.CUST_CD
                  AND SIT_CD = A.SIT_CD
                  AND VNDR_SEQ = A.VNDR_SEQ) AS RCV_TEL_NO -- 담당자 연락처
             , '▶ 상태 : ' ||
               CASE WHEN SITE_APRV_STATS IN ('1', '2') THEN
                         CASE WHEN SITE_APRV_STATS = '1' THEN '현장소장-승인'
                              ELSE '현장소장-반려'
                         END
                    ELSE CASE WHEN SAFT_APRV_STATS IN ('1', '2') THEN
                                   CASE WHEN SAFT_APRV_STATS = '1' THEN '안전관리자-승인'
                                        ELSE '안전관리자-반려'
                                   END
                              ELSE CASE WHEN MNG_APRV_STATS IN ('1', '2') THEN
                                             CASE WHEN MNG_APRV_STATS = '1' THEN '관리자-승인'
                                                  ELSE '관리자-반려'
                                             END
                                        ELSE CASE WHEN SBM_YN = '1' THEN '제출'
                                                  ELSE '미제출'
                                             END
                                   END
                         END
               END              AS STATS_NM
             ,VNDR_WRK_NM
          FROM TQHA_RISK_VNDR A
         WHERE A.SIT_CD         = p_SIT_CD
           AND A.PLN_YM         = p_PLN_YM
           AND A.PLN_DGR        = p_PLN_DGR
           AND A.CUST_CD        = p_CUST_CD
           AND A.VNDR_SEQ       = p_VNDR_SEQ
           AND A.OBJ_YN         = '1'
        ;

    ---------------------------------------------------------------------------------------
    ELSIF p_WRK_TP = 'Q4' THEN

        -- Q4   그리드 조회 : 위험요인항목추가 - 공종별 단위작업
        OPEN RTN_CURSOR FOR
        SELECT A.CTP_CD   -- 상위공종코드
             , A.UNT_CD   -- 단위작업코드
             , A.CTP_NM   -- 단위작업명칭
             , A.USE_YN
             , A."Level"
          FROM ( SELECT CTP_CD         -- 공종코드
                      , ' ' AS UNT_CD  -- 단위작업코드
                      , CTP_NM         -- 공종명칭
                      , USE_YN         -- 공종 사용유무
                      , '1' AS "Level" -- 레벨1
                   FROM TQHA_CTP
                  WHERE USE_YN = '1'
                  UNION ALL
                 SELECT CTP_CD          -- 상위공종코드
                      , UNT_CD          -- 단위작업코드
                      , UNT_NM          -- 단위작업명칭
                      , USE_YN          -- 단위작업사용유무
                      , '2'  AS "Level" -- 레벨 2
                   FROM TQHA_CTPUNT 
                  WHERE USE_YN = '1') A
         ORDER 
            BY A.CTP_CD
             , A.UNT_CD ASC
        ;

     ---------------------------------------------------------------------------------------
    ELSIF p_WRK_TP = 'Q5' THEN

        -- Q5   그리드 조회 : 위험요인항목추가 - 위험요인항목
        OPEN RTN_CURSOR FOR
        SELECT A.CTP_CD      -- 상위공종코드
             , ( SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD ) AS CTP_NM    -- 공종명칭
             , A.UNT_CD      -- 단위작업코드
             , ( SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD ) AS UNT_NM    -- 단위명칭
             , A.CHK_ITM_CD  -- 위험요인항목코드
             , A.CHK_ITM_NM  -- 위험요인항목명칭
             , A.RISK_FREQ   -- 빈도레벨(QS003)
             , A.RISK_APRV   -- 강도레벨(QS004)
             , A.RISK_CRIT   -- 위험성(공통코드 QS063)
             , A.RISK_GRD    -- 위험등급(QS024)
             , A.PRRT_REG    -- 중점등록(QS002)
             , A.IMPRV_CPLN  -- 개선대책
             , A.USE_YN      -- 단위작업사용유무
             , A.CUST_CD     -- 업체코드
             , A.USR_DEFN_YN -- 사용자정의 구분
             , A.DISS_SHP    -- 재해형태(QS036)
             , A.SIT_CD
          FROM TQHA_CTPUNT_CHKITM A
         WHERE A.USR_DEFN_YN    = '0'
           AND A.CTP_CD         = p_CTP_CD
           AND A.UNT_CD         = p_UNT_CD
        ;

     ---------------------------------------------------------------------------------------
    ELSIF p_WRK_TP = 'Q6' THEN

        -- Q6   그리드 조회 : 위험요인항목추가 - 사용자정의 위험요인항목
        OPEN RTN_CURSOR FOR
        SELECT A.CTP_CD      -- 상위공종코드
             , ( SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD ) AS CTP_NM    -- 공종명칭
             , A.UNT_CD      -- 단위작업코드
             , ( SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD ) AS UNT_NM    -- 단위명칭
             , A.CHK_ITM_CD  -- 위험요인항목코드
             , A.CHK_ITM_NM  -- 위험요인항목명칭
             , A.RISK_FREQ   -- 빈도레벨(QS003)
             , A.RISK_APRV   -- 강도레벨(QS004)
             , A.RISK_CRIT   -- 위험성(공통코드 QS063)
             , A.RISK_GRD    -- 위험등급(QS024)
             , A.PRRT_REG    -- 중점등록(QS002)
             , A.IMPRV_CPLN  -- 개선대책
             , A.USE_YN      -- 단위작업사용유무
             , A.CUST_CD     -- 업체코드
             , A.USR_DEFN_YN -- 사용자정의 구분
             , A.DISS_SHP    -- 재해형태(QS036)
             , A.SIT_CD      -- 현장코드
          FROM TQHA_CTPUNT_CHKITM A
         WHERE A.USR_DEFN_YN    = '1'
           AND A.CTP_CD         = p_CTP_CD
           AND A.UNT_CD         = p_UNT_CD
           AND (NVL(p_CUST_CD, '*') = '*' OR A.CUST_CD        = p_CUST_CD)
           /** AND A.SIT_CD    = p_SIT_CD */
        ;

     ---------------------------------------------------------------------------------------
    ELSIF p_WRK_TP = 'Q7' THEN

        -- Q7   그리드 조회 : 위험요인항목추가 - 타현장 위험요인항목
        OPEN RTN_CURSOR FOR
          SELECT A.SIT_CD                     -- 현장코드
             , A.PLN_YM                      -- 계획년월
             , A.PLN_DGR                     -- 계획차수
             , A.CUST_CD                     -- 협력업체코드
             , A.VNDR_SEQ                    -- 협력업체차수
             , A.CTP_CD                      -- 공종코드
             , ( SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD ) AS CTP_NM           -- 공종명칭
             , A.UNT_CD                      -- 단위코드
             , ( SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD ) AS UNT_NM           -- 단위명칭
             , A.CHK_ITM_CD                  -- 위험요인항목코드
             , A.CHK_ITM_NM                  -- 위험요인항목명칭
             , A.PRRT_REG               -- 중점등록(공통코드 QS002)             
             , A.DISS_SHP               -- 재해형태(공통코드 QS036)
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.PRRT_REG AND HRNK_CD = 'QS002') AS PRRT_REG_NM  -- 중점등록
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.DISS_SHP AND HRNK_CD = 'QS036') AS DISS_SHP_NM  -- 재해형태             
             , A.RISK_FREQ              -- 위험빈도(공통코드 QS003)             
             , A.RISK_APRV              -- 위험강도(공통코드 QS004)             
             , A.RISK_CRIT              -- 위험성(공통코드 QS063)
             , A.RISK_GRD               -- 위험등급(공통코드 QS024)             
             , A.RISK_FREQ2              -- 위험빈도(공통코드 QS003)             
             , A.RISK_APRV2              -- 위험강도(공통코드 QS004)             
             , A.RISK_CRIT2              -- 위험성(공통코드 QS063)
             , A.RISK_GRD2               -- 위험등급(공통코드 QS024)             
             , A.RISK_FREQ3              -- 위험빈도(공통코드 QS003)             
             , A.RISK_APRV3              -- 위험강도(공통코드 QS004)             
             , A.RISK_CRIT3              -- 위험성(공통코드 QS063)
             , A.RISK_GRD3               -- 위험등급(공통코드 QS024)             
             , A.RISK_FREQ4              -- 위험빈도(공통코드 QS003)             
             , A.RISK_APRV4              -- 위험강도(공통코드 QS004)             
             , A.RISK_CRIT4              -- 위험성(공통코드 QS063)
             , A.RISK_GRD4               -- 위험등급(공통코드 QS024)             
             , A.RISK_FREQ5              -- 위험빈도(공통코드 QS003)             
             , A.RISK_APRV5              -- 위험강도(공통코드 QS004)             
             , A.RISK_CRIT5              -- 위험성(공통코드 QS063)
             , A.RISK_GRD5               -- 위험등급(공통코드 QS024)             
             , A.RISK_FREQ6              -- 위험빈도(공통코드 QS003)             
             , A.RISK_APRV6              -- 위험강도(공통코드 QS004)             
             , A.RISK_CRIT6              -- 위험성(공통코드 QS063)
             , A.RISK_GRD6               -- 위험등급(공통코드 QS024)
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.RISK_FREQ AND HRNK_CD = 'QS003') AS RISK_FREQ_NM  -- 빈도명
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.RISK_APRV AND HRNK_CD = 'QS004') AS RISK_APRV_NM  -- 강도명
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.RISK_CRIT AND HRNK_CD = 'QS063') AS RISK_CRIT_NM  -- 위험성
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.RISK_GRD  AND HRNK_CD = 'QS024') AS RISK_GRD_NM  -- 위험등급
             , A.MNG_SUPR
             , A.MGR_OPIN                 --관리자의견
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.MNG_SUPR ) AS MNG_SUPR_NM  -- 관리감독자성명           
             , A.SAFT_MGR                 --안전관리자
             , A.SAFT_OPIN                 --안전의견
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SAFT_MGR ) AS SAFT_MGR_NM  -- 안전관리자성명           
             , A.SITE_OMGR                 --현장소장
             , A.SITE_OPIN                 --현장소장의견
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SITE_OMGR ) AS SITE_OMGR_NM -- 현장소장성명
             , A.IMPRV_CPLN             -- 개선대책
             , A.WRK_PSNNO              -- 작업인원
             , A.MA_PSN                 -- 조치자(업체)
             , A.MA_CNFR                -- 확인자(안전관리자)
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.MA_CNFR ) AS MA_CNFR_NM        -- 확인자성명
             , A.WRK_STR_DT                  -- 작업시작일자
             , A.WRK_END_DT                  -- 작업종료일자
             , A.IMPRV_STR_DT                -- 개선시작일자
             , A.IMPRV_END_DT                -- 개선종료일자
             , A.CHK_LOC                     -- 점검위치
             ,(SELECT DECODE(COUNT(1),0,'중흥','협력사') FROM TQHA_VNDR WHERE SIT_CD = A.SIT_CD AND VNDR_PSN_ID = A.IPT_ID) AS REG_DIV
          FROM TQHA_RISK_CHK A
         WHERE A.CTP_CD         = p_CTP_CD
           AND A.UNT_CD         = p_UNT_CD
           AND A.SIT_CD         NOT IN(p_SIT_CD)
           AND (NVL(p_DIFF_SIT_CD, '*') = '*' OR A.SIT_CD = p_DIFF_SIT_CD)
           AND (NVL(p_PLN_YM, '*') = '*' OR A.PLN_YM = p_PLN_YM)
           AND (NVL(p_PLN_DGR, '*') = '*' OR A.PLN_DGR = p_PLN_DGR)
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_RISK_ITM_LIST_OTHER_Q;
/

-- PQHA_RISK_PLAN_OTHER_Q
DROP PROCEDURE "PQHA_RISK_PLAN_OTHER_Q";
CREATE PROCEDURE "PQHA_RISK_PLAN_OTHER_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'         -- FLAG
,   p_SIT_CD            IN VARCHAR2                     -- 현장코드
,   p_CTP_CD            IN VARCHAR2                     -- 상위공종코드
,   p_UNT_CD            IN VARCHAR2                     -- 단위작업코드
,   p_FST_DIV           IN VARCHAR2                     -- 최초구분
,   p_PLN_DGR           IN VARCHAR2                     -- 계획차수
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [최초 위험성평가계획] PROCEDRE 

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2026/02/05                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    -- 
    IF p_WRK_TP = 'Q1' THEN

        -- 위험요인항목추가 - 공종
        OPEN RTN_CURSOR FOR
        SELECT A.CTP_DIV
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.CTP_DIV AND HRNK_CD = 'QS035') AS CTP_DIV_NM       -- 공종구분명
             , A.CTP_CD                                                                                             -- 공종코드
             , A.CTP_NM                                                                                             -- 공종명칭
          FROM TQHA_CTP A
         ORDER BY A.CTP_DIV, A.CTP_CD
        ;

    ---------------------------------------------------------------------------------------
    ELSIF p_WRK_TP = 'Q2' THEN

        -- 위험요인항목추가 - 공종별 단위작업
        OPEN RTN_CURSOR FOR
        SELECT CTP_CD         -- 상위공종코드
             , UNT_CD         -- 단위작업코드
             , UNT_NM         -- 단위작업명칭
             , USE_YN         -- 단위작업사용유무
          FROM TQHA_CTPUNT
         WHERE CTP_CD = p_CTP_CD
        ;

    ---------------------------------------------------------------------------------------
    ELSIF p_WRK_TP = 'Q3' THEN

        -- 위험요인항목추가 - 사용자정의 위험요인항목
        OPEN RTN_CURSOR FOR
        SELECT CTP_CD               -- 상위공종코드
             , ( SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD )                          AS CTP_NM   -- 공종명칭
             , UNT_CD               -- 단위작업코드
             , ( SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD ) AS UNT_NM   -- 단위명칭
             , CHK_ITM_CD           -- 위험요인항목코드
             , CHK_ITM_NM           -- 위험요인항목명칭
             , CUST_CD              -- 업체코드  
             , USE_YN               -- 단위작업사용유무
             , USR_DEFN_YN          -- 사용자정의유무
             , RISK_FREQ            -- 빈도레벨(QS003)
             , RISK_APRV            -- 강도레벨(QS004)
             , RISK_CRIT            -- 위험성레벨(QS063)
             , RISK_GRD             -- 위험레벨(QS004)
             , PRRT_REG             -- 중점등록(QS003)
             , IMPRV_CPLN           -- 개선대책
             , DISS_SHP             -- 재해형태(QS036)
             , SIT_CD               -- 현장코드
          FROM TQHA_CTPUNT_CHKITM A
         WHERE CTP_CD       = p_CTP_CD
           AND UNT_CD       = p_UNT_CD
           AND USR_DEFN_YN  = '1'      -- 사용자 정의컬럼인 경우
           -- AND CUST_CD = {CUST_CD} 
           AND SIT_CD       = p_SIT_CD
        ;

    ---------------------------------------------------------------------------------------
    ELSIF p_WRK_TP = 'Q4' THEN

        -- 위험성평가계획 결재번호
        OPEN RTN_CURSOR FOR
        SELECT A.APRV_NO
             , B.APRV_STATS
          FROM TQHA_RISKPLAN    A
          LEFT JOIN TQHA_APRV   B ON A.SIT_CD   = B.SIT_CD
                                 AND A.APRV_NO  = B.APRV_NO
         WHERE A.SIT_CD     = p_SIT_CD
           AND A.FST_DIV    = p_FST_DIV
           AND A.PLN_DGR    = p_PLN_DGR
        ;

    ---------------------------------------------------------------------------------------
    ELSIF p_WRK_TP = 'Q5' THEN

        -- 위험성평가계획 결재번호
        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                                                                                             -- 현장코드
             , A.FST_DIV                                                                                            -- 최초구분(공통코드 QS001)
             , A.PLN_DGR                                                                                            -- 계획차수(공통코드 QS005)
             , A.CTP_CD                                                                                             -- 공종코드
             , ( SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD )                              AS CTP_NM       -- 공종명칭
             , A.UNT_CD                                                                                             -- 단위코드
             , ( SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD )     AS UNT_NM       -- 단위명칭
             , A.CHK_ITM_CD                                                                                         -- 위험요인항목코드
             , A.CHK_ITM_NM                                                                                         -- 위험요인항목명칭
             , A.RISK_FREQ                                                                                          -- 위험빈도(공통코드 QS003)
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.RISK_FREQ AND HRNK_CD = 'QS003')   AS RISK_FREQ_NM -- 빈도명
             , A.RISK_APRV                                                                                          -- 위험강도(공통코드 QS004)
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.RISK_APRV AND HRNK_CD = 'QS004')   AS RISK_APRV_NM -- 강도명
             , A.RISK_CRIT        																				    -- 위험성레벨(QS063)
             , A.RISK_GRD                                                                                           -- 위험등급(공통코드 QS024)
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.RISK_GRD AND HRNK_CD = 'QS024')    AS RISK_GRD_NM  -- 위험등급
             , A.PRRT_REG                                                                                           -- 중점등록(공통코드 QS002)
             , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.PRRT_REG AND HRNK_CD = 'QS002')    AS PRRT_REG_NM  -- 중점등록
             , A.IMPRV_CPLN                                                                                         -- 개선대책
             , A.MA_CNFR                                                                                            -- 확인자(안전관리자)
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.MA_CNFR ) AS MA_CNFR_NM                          -- 확인자성명
             , A.DISS_SHP                                                                                           -- 재해형태(QS036)
          FROM TQHA_RISKPLAN_D A
         WHERE SIT_CD   = p_SIT_CD          -- DIFF_SIT_CD  타현장
           AND FST_DIV  = p_FST_DIV         -- DIFF_FST_DIV
           AND PLN_DGR  = p_PLN_DGR         -- DIFF_PLN_DGR
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_RISK_PLAN_OTHER_Q;
/

-- PQHA_RISK_SCHD_MNG_CO_Q
DROP PROCEDURE "PQHA_RISK_SCHD_MNG_CO_Q";
CREATE PROCEDURE "PQHA_RISK_SCHD_MNG_CO_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'             -- FLAG(Q: 현장평가, Q1:본사평가)
,   p_SIT_CD            IN VARCHAR2                         -- 현장코드
,   p_CUST_CD           IN VARCHAR2                         -- 고객코드
,   p_VNDR_SEQ          IN VARCHAR2                         -- 업체순번
,   p_PLN_YM            IN VARCHAR2                         -- 계획년월
,   p_PLN_DGR           IN VARCHAR2                         -- 계획차수
,   p_CTP_CD            IN VARCHAR2                         -- 공종코드 
,   p_UNT_CD            IN VARCHAR2                         -- 단위코드
,   RTN_CURSOR       OUT SYS_REFCURSOR
) 
IS

    /**************************************************************************************************************************
      Purpose : 파트너 위험성평가등록 

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2026/02/27                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    -- 그리드 조회 : 위험성평가 목록 (현장)
    IF p_WRK_TP = 'Q1' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                  --현장코드
             , A.PLN_YM                   --계획년월
             , A.PLN_DGR                  --계획차수
             ,( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.PLN_DGR AND HRNK_CD = 'QS005') AS PLN_DGR_NM  -- 계획차수명칭
             , B.APRS_STR_DT              --평가시작일
             , B.APRS_END_DT              --평가종료일
             , B.VNDR_CMPL_DT             --업체작성완료일자
             , B.CONF_SCH_DT              --회의예정일자
             , A.SITE_APRV_DT AS FINAL_DT --최종승인일자
             , A.SBM_YN                   --평가서제출여부
             , DECODE(NVL(A.SBM_YN,0), '1', '제출', '작성중') AS SBM_NM -- 제출여부명칭
             , A.SBM_DT                   --평가서제출일자
             , A.MNG_SUPR                 --관리감독자
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.MNG_SUPR ) AS MNG_SUPR_NM -- 관리감독자명
             , A.MNG_APRV_STATS           --관리감독자 승인상태(1승인, 2반려)
             , DECODE(NVL(A.SBM_YN,0), '1', DECODE(NVL(A.MNG_APRV_STATS,0), '1', '승인완료 ', DECODE(NVL(A.MNG_APRV_STATS,0), '2', '반려 ', '진행중')), '0', DECODE(NVL(A.MNG_APRV_STATS,0), '2', '반려 ', ''), '' ) AS MNG_APRV_STATS_NM -- 관리상태명칭
             , A.MNG_APRV_DT              --관리감독자 승인일자
             , A.SAFT_MGR                 --안전관리자
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SAFT_MGR ) AS SAFT_MGR_NM -- 안전관리자명
             , A.SAFT_APRV_STATS          --안전관리자 승인상태(1승인 2반려)
             , DECODE(NVL(A.MNG_APRV_STATS,0), '1', DECODE(NVL(A.SAFT_APRV_STATS,0), '1', '승인완료 ', DECODE(NVL(A.SAFT_APRV_STATS,0), '2', '반려 ', '진행중')), '0', DECODE(NVL(A.SAFT_APRV_STATS,0), '1','승인', '2', '반려 ', ''), '' ) AS SAFT_APRV_STATS_NM -- 안전상태명칭
             , A.SAFT_APRV_DT             --안전관리자 승인일자
             , A.SITE_OMGR                --현장소장
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SITE_OMGR ) AS SITE_OMGR_NM -- 현장소장명
             , A.SITE_APRV_STATS          --현장소장 승인상태(1승인, 2반려)
             , DECODE(NVL(A.SAFT_APRV_STATS,0), '1', DECODE(NVL(A.SITE_APRV_STATS,0), '1', '승인완료 ', DECODE(NVL(A.SITE_APRV_STATS,0), '2', '반려 ', '진행중')), '0', DECODE(NVL(A.SITE_APRV_STATS,0), '2', '반려 ', ''), '' ) AS SITE_APRV_STATS_NM -- 소장상태명칭
             , A.SITE_APRV_DT             --현장소장 승인일자
             , A.CUST_CD                  --협력업체코드
             , ( SELECT CUST_NM FROM VQSZ_TRADE WHERE CUST_CD = A.CUST_CD ) AS VNDR_NM --협력업체명
             , A.VNDR_SEQ                 --협력업체차수
             , A.CHK_ATFL_GRP             --첨부파일그룹
             , '▶ 상태 : ' ||
               CASE WHEN SITE_APRV_STATS IN ('1', '2') THEN
                         CASE WHEN SITE_APRV_STATS = '1' THEN '현장소장-승인'
                              ELSE '현장소장-반려'
                         END
                    ELSE CASE WHEN SAFT_APRV_STATS IN ('1', '2') THEN
                                   CASE WHEN SAFT_APRV_STATS = '1' THEN '안전관리자-승인'
                                        ELSE '안전관리자-반려'
                                   END
                              ELSE CASE WHEN MNG_APRV_STATS IN ('1', '2') THEN
                                             CASE WHEN MNG_APRV_STATS = '1' THEN '관리자-승인'
                                                  ELSE '관리자-반려'
                                             END
                                        ELSE CASE WHEN SBM_YN = '1' THEN '제출'
                                                  ELSE '미제출'
                                             END
                                   END
                         END
               END              AS STATS_NM
          FROM TQHA_RISK_VNDR A
             , TQHA_RISK_DGR B
         WHERE A.SIT_CD         =  B.SIT_CD
           AND A.PLN_YM         = B.PLN_YM
           AND A.PLN_DGR        = B.PLN_DGR
           AND A.SIT_CD         = p_SIT_CD
           AND A.CUST_CD        = p_CUST_CD
           AND A.VNDR_SEQ       = p_VNDR_SEQ
           AND A.OBJ_YN         = '1'           -- 대상유무
           AND (NVL(p_PLN_YM, '*') = '*'     OR A.PLN_YM     = p_PLN_YM)
           AND (NVL(p_PLN_DGR, '*') = '*'    OR A.PLN_DGR    = p_PLN_DGR)
         ORDER BY A.PLN_YM DESC, A.PLN_DGR DESC
        ;

    -- 그리드 조회 : 위험성평가 목록 (본사)
    ELSIF p_WRK_TP = 'Q1_H' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                  --현장코드
             , A.PLN_YM                   --계획년월
             , A.PLN_DGR                  --계획차수
             ,( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.PLN_DGR AND HRNK_CD = 'QS005') AS PLN_DGR_NM  -- 계획차수명칭
             , B.APRS_STR_DT              --평가시작일
             , B.APRS_END_DT              --평가종료일
             , B.VNDR_CMPL_DT             --업체작성완료일자
             , B.CONF_SCH_DT              --회의예정일자
             , A.SITE_APRV_DT AS FINAL_DT --최종승인일자
             , A.SBM_YN                   --평가서제출여부
             , DECODE(NVL(A.SBM_YN,0), '1', '제출', '작성중') AS SBM_NM -- 제출여부명칭
             , A.SBM_DT                   --평가서제출일자
             , A.MNG_SUPR                 --관리감독자
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.MNG_SUPR ) AS MNG_SUPR_NM -- 관리감독자명
             , A.MNG_APRV_STATS           --관리감독자 승인상태(1승인, 2반려)
             , DECODE(NVL(A.SBM_YN,0), '1', DECODE(NVL(A.MNG_APRV_STATS,0), '1', '승인완료 ', DECODE(NVL(A.MNG_APRV_STATS,0), '2', '반려 ', '진행중')), '0', DECODE(NVL(A.MNG_APRV_STATS,0), '2', '반려 ', ''), '' ) AS MNG_APRV_STATS_NM -- 관리상태명칭
             , A.MNG_APRV_DT              --관리감독자 승인일자
             , A.SAFT_MGR                 --안전관리자
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SAFT_MGR ) AS SAFT_MGR_NM -- 안전관리자명
             , A.SAFT_APRV_STATS          --안전관리자 승인상태(1승인 2반려)
             , DECODE(NVL(A.MNG_APRV_STATS,0), '1', DECODE(NVL(A.SAFT_APRV_STATS,0), '1', '승인완료 ', DECODE(NVL(A.SAFT_APRV_STATS,0), '2', '반려 ', '진행중')), '0', DECODE(NVL(A.SAFT_APRV_STATS,0), '1','승인', '2', '반려 ', ''), '' ) AS SAFT_APRV_STATS_NM -- 안전상태명칭
             , A.SAFT_APRV_DT             --안전관리자 승인일자
             , A.SITE_OMGR                --현장소장
             , ( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SITE_OMGR ) AS SITE_OMGR_NM -- 현장소장명
             , A.SITE_APRV_STATS          --현장소장 승인상태(1승인, 2반려)
             , DECODE(NVL(A.SAFT_APRV_STATS,0), '1', DECODE(NVL(A.SITE_APRV_STATS,0), '1', '승인완료 ', DECODE(NVL(A.SITE_APRV_STATS,0), '2', '반려 ', '진행중')), '0', DECODE(NVL(A.SITE_APRV_STATS,0), '2', '반려 ', ''), '' ) AS SITE_APRV_STATS_NM -- 소장상태명칭
             , A.SITE_APRV_DT             --현장소장 승인일자
             , A.CUST_CD                  --협력업체코드
             , ( SELECT CUST_NM FROM VQSZ_TRADE WHERE CUST_CD = A.CUST_CD ) AS VNDR_NM --협력업체명
             , A.VNDR_SEQ                 --협력업체차수
             , A.CHK_ATFL_GRP             --첨부파일그룹
             , '▶ 상태 : ' ||
               CASE WHEN SITE_APRV_STATS IN ('1', '2') THEN
                         CASE WHEN SITE_APRV_STATS = '1' THEN '현장소장-승인'
                              ELSE '현장소장-반려'
                         END
                    ELSE CASE WHEN SAFT_APRV_STATS IN ('1', '2') THEN
                                   CASE WHEN SAFT_APRV_STATS = '1' THEN '안전관리자-승인'
                                        ELSE '안전관리자-반려'
                                   END
                              ELSE CASE WHEN MNG_APRV_STATS IN ('1', '2') THEN
                                             CASE WHEN MNG_APRV_STATS = '1' THEN '관리자-승인'
                                                  ELSE '관리자-반려'
                                             END
                                        ELSE CASE WHEN SBM_YN = '1' THEN '제출'
                                                  ELSE '미제출'
                                             END
                                   END
                         END
               END              AS STATS_NM 
          FROM TQHA_RISK_VNDR A
             , TQHA_RISK_DGR B
         WHERE A.SIT_CD         =  B.SIT_CD
           AND A.PLN_YM         = B.PLN_YM
           AND A.PLN_DGR        = B.PLN_DGR
           AND A.SIT_CD         = p_SIT_CD
           AND A.OBJ_YN         = '1'           -- 대상유무
           AND (NVL(p_PLN_YM, '*') = '*'     OR A.PLN_YM     = p_PLN_YM)
           AND (NVL(p_PLN_DGR, '*') = '*'    OR A.PLN_DGR    = p_PLN_DGR)
         ORDER BY A.PLN_YM DESC, A.PLN_DGR DESC
        ;
    --------------------------------------------------------------------------------
    -- 그리드 조회 : 위험성평가 작성
    ELSIF p_WRK_TP = 'Q2' THEN

        OPEN RTN_CURSOR FOR
        SELECT 
            A.SIT_CD          -- 현장코드
           ,A.PLN_YM                 --계획년월
           ,A.PLN_DGR                 --차수구분코드(QS005) 1 1차,2 2차
           ,A.CUST_CD                 --협력업체코드
           ,A.VNDR_SEQ                 --업체순번
           ,A.CTP_CD           -- 공종코드
           ,( SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD ) AS CTP_NM    -- 공종명칭
           ,A.UNT_CD           -- 단위코드
           ,( SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD ) AS UNT_NM    -- 단위명칭
           ,A.CHK_ITM_CD                 --점검항목코드
           ,A.CHK_ITM_NM                 --점검항목명
           ,A.CHK_LOC                 --점검위치
           ,A.DISS_SHP                 --재해형태(QS036)
           ,A.RISK_FREQ                 --빈도레벨(QS003)
           ,A.RISK_APRV                 --강도레벨(QS004)
           ,A.RISK_CRIT                 --위험성레벨(QS063)
           ,A.RISK_GRD                 --위험등급(QS024)
           ,A.PRRT_REG                 --중점등록(QS002) O, X
           ,A.IMPRV_CPLN                 --개선대책
           ,A.RISK_FREQ2                 --빈도레벨(QS003)
           ,A.RISK_APRV2                 --강도레벨(QS004)
           ,A.RISK_CRIT2                 --위험성레벨(QS063)
           ,A.RISK_GRD2                 --위험등급(QS024)
           ,A.MNG_SUPR                 --관리감독자
           ,A.MGR_OPIN                 --관리자의견
           ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.MNG_SUPR ) AS MNG_SUPR_NM  -- 관리감독자성명
           ,A.RISK_FREQ3                 --빈도레벨(QS003)
           ,A.RISK_APRV3                 --강도레벨(QS004)
           ,A.RISK_CRIT3                 --위험성레벨(QS063)
           ,A.RISK_GRD3                 --위험등급(QS024)
           ,A.SAFT_MGR                 --안전관리자
           ,A.SAFT_OPIN                 --안전의견
           ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SAFT_MGR ) AS SAFT_MGR_NM  -- 안전관리자성명
           ,A.RISK_FREQ4                 --빈도레벨(QS003)
           ,A.RISK_APRV4                 --강도레벨(QS004)
           ,A.RISK_CRIT4                 --위험성레벨(QS063)
           ,A.RISK_GRD4                 --위험등급(QS024)
           ,A.SITE_OMGR                 --현장소장
           ,A.SITE_OPIN                 --현장소장의견
           ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SITE_OMGR ) AS SITE_OMGR_NM -- 현장소장성명
           ,A.RISK_FREQ5                 --빈도레벨(QS003)
           ,A.RISK_APRV5                 --강도레벨(QS004)
           ,A.RISK_CRIT5                 --위험성레벨(QS063)
           ,A.RISK_GRD5                 --위험등급(QS024)
           ,A.RISK_FREQ6                 --빈도레벨(QS003)
           ,A.RISK_APRV6                 --강도레벨(QS004)
           ,A.RISK_CRIT6                 --위험성레벨(QS063)
           ,A.RISK_GRD6                 --위험등급(QS024)
           ,A.WRK_PSNNO                 --작업인원
           ,A.MA_PSN                 --조치자
           ,A.MA_CNFR                 --확인자
           ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.MA_CNFR ) AS MA_CNFR_NM  -- 확인자성명
           ,A.WRK_STR_DT                 --작업시작일자
           ,A.WRK_END_DT                 --작업종료일자
           ,A.IMPRV_STR_DT                 --개선시작일자
           ,A.IMPRV_END_DT                 --개선종료일자
           ,(SELECT DECODE(COUNT(1),0,'중흥','협력사') FROM TQHA_VNDR WHERE SIT_CD = A.SIT_CD AND VNDR_PSN_ID = A.IPT_ID) AS REG_DIV
          FROM TQHA_RISK_CHK A
         WHERE A.SIT_CD     = p_SIT_CD
           AND A.PLN_YM     = p_PLN_YM
           AND A.PLN_DGR    = p_PLN_DGR
           AND A.CUST_CD    = p_CUST_CD
           AND A.VNDR_SEQ   = p_VNDR_SEQ
        ;

    --------------------------------------------------------------------------------
    -- 그리드 조회 : 위험요인항목 추가 - 공종별 단위작업 리스트 (트리)
    ELSIF p_WRK_TP = 'Q3' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.CTP_CD   -- 상위공종코드
             , A.UNT_CD   -- 단위작업코드
             , A.CTP_NM   -- 단위작업명칭
             , A.USE_YN
             , A."Level"
          FROM ( SELECT CTP_CD         -- 공종코드
                      , ' ' AS UNT_CD  -- 단위작업코드
                      , CTP_NM         -- 공종명칭
                      , USE_YN         -- 공종 사용유무
                      , '1' AS "Level" -- 레벨1
                   FROM TQHA_CTP
                  WHERE USE_YN = '1'
                  UNION ALL
                 SELECT CTP_CD          -- 상위공종코드
                      , UNT_CD          -- 단위작업코드
                      , UNT_NM          -- 단위작업명칭
                      , USE_YN          -- 단위작업사용유무
                      , '2'  AS "Level" -- 레벨 2
                   FROM TQHA_CTPUNT 
                  WHERE USE_YN = '1') A
         ORDER BY A.CTP_CD, A.UNT_CD ASC
        ;

    --------------------------------------------------------------------------------
    -- 그리드 조회 : 위험요인항목 추가 - 위험요인항목
    ELSIF p_WRK_TP = 'Q4' THEN

        OPEN RTN_CURSOR FOR

        SELECT A.CTP_CD      -- 상위공종코드
             , ( SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD ) AS CTP_NM    -- 공종명칭
             , A.UNT_CD      -- 단위작업코드
             , ( SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD ) AS UNT_NM    -- 단위명칭
             , A.CHK_ITM_CD  -- 점검항목코드
             , A.CHK_ITM_NM  -- 점검항목명칭
             , A.RISK_FREQ   -- 빈도레벨(QS003)
             , A.RISK_APRV   -- 강도레벨(QS004)
             , A.RISK_CRIT   -- 위험성(공통코드 QS063)
             , A.RISK_GRD    -- 위험등급(QS024)
             , A.PRRT_REG    -- 중점등록(QS002)
             , A.IMPRV_CPLN  -- 개선대책
             , A.USE_YN      -- 단위작업사용유무
             , A.CUST_CD     -- 업체코드
             , A.USR_DEFN_YN -- 사용자정의 구분
             , A.DISS_SHP    -- 재해형태(QS036)
          FROM TQHA_CTPUNT_CHKITM A
         WHERE A.USR_DEFN_YN    = '0'
           AND A.CTP_CD         = p_CTP_CD
           AND A.UNT_CD         = p_UNT_CD
        ;

    --------------------------------------------------------------------------------
    -- 그리드 조회 : 위험요인항목 추가 - 사용자정의 위험요인항목 
    ELSIF p_WRK_TP = 'Q5' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.CTP_CD      -- 상위공종코드
             , ( SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD ) AS CTP_NM    -- 공종명칭
             , A.UNT_CD      -- 단위작업코드
             , ( SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD ) AS UNT_NM    -- 단위명칭
             , A.CHK_ITM_CD  -- 점검항목코드
             , A.CHK_ITM_NM  -- 점검항목명칭
             , A.RISK_FREQ   -- 빈도레벨(QS003)
             , A.RISK_APRV   -- 강도레벨(QS004)
             , A.RISK_CRIT   -- 위험성(공통코드 QS063)
             , A.RISK_GRD    -- 위험등급(QS024)
             , A.PRRT_REG    -- 중점등록(QS002)
             , A.IMPRV_CPLN  -- 개선대책
             , A.USE_YN      -- 단위작업사용유무
             , A.CUST_CD     -- 업체코드
             , A.USR_DEFN_YN -- 사용자정의 구분
             , A.DISS_SHP    -- 재해형태(QS036)
          FROM TQHA_CTPUNT_CHKITM A
         WHERE A.USR_DEFN_YN = '1'
           AND A.CTP_CD     = p_CTP_CD
           AND A.UNT_CD     = p_UNT_CD
           AND A.CUST_CD    = p_CUST_CD
        ;

    --------------------------------------------------------------------------------
    -- 위험성평가 평가서제출 여부 조회
    ELSIF p_WRK_TP = 'Q6' THEN

        OPEN RTN_CURSOR FOR
        SELECT SBM_YN
             , MNG_APRV_STATS
          FROM TQHA_RISK_VNDR
         WHERE SIT_CD       = p_SIT_CD
           AND PLN_DGR      = p_PLN_DGR
           AND PLN_YM       = p_PLN_YM
           AND CUST_CD      = p_CUST_CD
           AND VNDR_SEQ     = p_VNDR_SEQ
        ;

    --------------------------------------------------------------------------------
    -- 전회차복사 목록 조회
    ELSIF p_WRK_TP = 'Q7' THEN

        OPEN RTN_CURSOR FOR
        SELECT 
            A.SIT_CD          -- 현장코드
           ,A.PLN_YM                 --계획년월
           ,A.PLN_DGR                 --차수구분코드(QS005) 1 1차,2 2차
           ,A.CUST_CD                 --협력업체코드
           ,A.VNDR_SEQ                 --업체순번
           ,A.CTP_CD           -- 공종코드
           ,( SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD ) AS CTP_NM    -- 공종명칭
           ,A.UNT_CD           -- 단위코드
           ,( SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD ) AS UNT_NM    -- 단위명칭
           ,A.CHK_ITM_CD                 --점검항목코드
           ,A.CHK_ITM_NM                 --점검항목명
           ,A.CHK_LOC                 --점검위치
           ,A.DISS_SHP                 --재해형태(QS036)
           ,A.RISK_FREQ                 --빈도레벨(QS003)
           ,A.RISK_APRV                 --강도레벨(QS004)
           ,A.RISK_CRIT                 --위험성레벨(QS063)
           ,A.RISK_GRD                 --위험등급(QS024)
           ,A.PRRT_REG                 --중점등록(QS002) O, X
           ,A.IMPRV_CPLN                 --개선대책
           ,A.RISK_FREQ2                 --빈도레벨(QS003)
           ,A.RISK_APRV2                 --강도레벨(QS004)
           ,A.RISK_CRIT2                 --위험성레벨(QS063)
           ,A.RISK_GRD2                 --위험등급(QS024)
           ,A.MNG_SUPR                 --관리감독자
           ,A.MGR_OPIN                 --관리자의견
           ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.MNG_SUPR ) AS MNG_SUPR_NM  -- 관리감독자성명
           ,A.RISK_FREQ3                 --빈도레벨(QS003)
           ,A.RISK_APRV3                 --강도레벨(QS004)
           ,A.RISK_CRIT3                 --위험성레벨(QS063)
           ,A.RISK_GRD3                 --위험등급(QS024)
           ,A.SAFT_MGR                 --안전관리자
           ,A.SAFT_OPIN                 --안전의견
           ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SAFT_MGR ) AS SAFT_MGR_NM  -- 안전관리자성명
           ,A.RISK_FREQ4                 --빈도레벨(QS003)
           ,A.RISK_APRV4                 --강도레벨(QS004)
           ,A.RISK_CRIT4                 --위험성레벨(QS063)
           ,A.RISK_GRD4                 --위험등급(QS024)
           ,A.SITE_OMGR                 --현장소장
           ,A.SITE_OPIN                 --현장소장의견
           ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SITE_OMGR ) AS SITE_OMGR_NM -- 현장소장성명
           ,A.RISK_FREQ5                 --빈도레벨(QS003)
           ,A.RISK_APRV5                 --강도레벨(QS004)
           ,A.RISK_CRIT5                 --위험성레벨(QS063)
           ,A.RISK_GRD5                 --위험등급(QS024)
           ,A.RISK_FREQ6                 --빈도레벨(QS003)
           ,A.RISK_APRV6                 --강도레벨(QS004)
           ,A.RISK_CRIT6                 --위험성레벨(QS063)
           ,A.RISK_GRD6                 --위험등급(QS024)
           ,A.WRK_PSNNO                 --작업인원
           ,A.MA_PSN                 --조치자
           ,A.MA_CNFR                 --확인자
           ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.MA_CNFR ) AS MA_CNFR_NM  -- 확인자성명
           ,A.WRK_STR_DT                 --작업시작일자
           ,A.WRK_END_DT                 --작업종료일자
           ,A.IMPRV_STR_DT                 --개선시작일자
           ,A.IMPRV_END_DT                 --개선종료일자
           ,(SELECT DECODE(COUNT(1),0,'중흥','협력사') FROM TQHA_VNDR WHERE SIT_CD = A.SIT_CD AND VNDR_PSN_ID = A.IPT_ID) AS REG_DIV
          FROM TQHA_RISK_CHK A
         WHERE A.SIT_CD     = p_SIT_CD
           AND A.PLN_YM     = p_PLN_YM
           AND A.PLN_DGR    = p_PLN_DGR
           AND A.CUST_CD    = p_CUST_CD
           AND A.VNDR_SEQ   = p_VNDR_SEQ
           AND A.PRRT_REG   <>  '1'
        ;

    --------------------------------------------------------------------------------
    -- SMS 처리 ( 협력업체 평가서 제출 )
    ELSIF p_WRK_TP = 'Q8' THEN

        OPEN RTN_CURSOR FOR
        -- SMS 처리 ( 협력업체 평가서 제출 )
       --SELECT A.SIT_CD, A.PLN_YM, A.PLN_DGR, A.CUST_CD, A.VNDR_SEQ, A.MA_CNFR, REPLACE(B.MP_NO, '-', '') MP_NO
       ---- REPLACE(SYS.PKG_CRYPTO_DEC.DECRYPT(B.MP_NO), '-', '') MP_NO
       --FROM ( -- 협력업체 위험성평가 제출 시 확인자 리스트
       --        SELECT SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, MA_CNFR
       --        FROM TQHA_RISK_CHK
       --        WHERE SIT_CD = {SIT_CD}      -- 변수(현장)
       --          AND PLN_YM = {PLN_YM}        -- 변수(평가년월)
       --          AND PLN_DGR = {PLN_DGR}      -- 변수(차수)
       --          AND CUST_CD = {CUST_CD}      -- 변수(업체코드)
       --          AND VNDR_SEQ = {VNDR_SEQ}    -- 변수(업체순번)
       --        GROUP BY SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, MA_CNFR
       --    ) A,
       --    TCOZ_USR_INFO B
       --WHERE A.SIT_CD = B.DEPT_CD
       -- AND A.MA_CNFR = B.USR_ID
        SELECT A.SIT_CD
             , A.PLN_YM
             , A.PLN_DGR
             , A.CUST_CD
             , A.VNDR_SEQ
             , C.MGR_1                      AS MA_CNFR
             , REPLACE(B.MP_NO, '-', '')    AS MP_NO
             -- REPLACE(SYS.PKG_CRYPTO_DEC.DECRYPT(B.MP_NO), '-', '') MP_NO
          FROM (-- 협력업체 위험성평가 제출 시 확인자 리스트
                SELECT SIT_CD
                     , PLN_YM
                     , PLN_DGR
                     , CUST_CD
                     , VNDR_SEQ
                  FROM TQHA_RISK_CHK
                 WHERE SIT_CD   = p_SIT_CD     -- 변수(현장)
                   AND PLN_YM   = p_PLN_YM        -- 변수(평가년월)
                   AND PLN_DGR  = p_PLN_DGR     -- 변수(차수)
                   AND CUST_CD  = p_CUST_CD
                   AND VNDR_SEQ = p_VNDR_SEQ
                 GROUP 
                    BY SIT_CD
                     , PLN_YM
                     , PLN_DGR
                     , CUST_CD
                     , VNDR_SEQ
               ) A
               JOIN (
                               SELECT SIT_CD, MGR_1 FROM TQHA_VNDR WHERE SIT_CD = P_SIT_CD AND CUST_CD = p_CUST_CD AND VNDR_SEQ = p_VNDR_SEQ AND NVL(MGR_1, '*') != '*'
                     UNION ALL SELECT SIT_CD, MGR_2 FROM TQHA_VNDR WHERE SIT_CD = P_SIT_CD AND CUST_CD = p_CUST_CD AND VNDR_SEQ = p_VNDR_SEQ AND NVL(MGR_2, '*') != '*'
                     UNION ALL SELECT SIT_CD, MGR_3 FROM TQHA_VNDR WHERE SIT_CD = P_SIT_CD AND CUST_CD = p_CUST_CD AND VNDR_SEQ = p_VNDR_SEQ AND NVL(MGR_3, '*') != '*'
                    ) C  ON A.SIT_CD = C.SIT_CD
               JOIN TCOZ_USR_INFO B ON C.SIT_CD = B.DEPT_CD
                                   AND C.MGR_1  = B.USR_ID
        ;

    END IF;


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_RISK_SCHD_MNG_CO_Q ;
/

-- PQHA_SAFECOST_APRV_ATFL_S
DROP PROCEDURE "PQHA_SAFECOST_APRV_ATFL_S";
CREATE PROCEDURE "PQHA_SAFECOST_APRV_ATFL_S" (
    p_WRK_TP            VARCHAR2 :='U'      -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID            VARCHAR2            -- 사용자 ID 
,   p_WRK_IP            VARCHAR2            -- 사용자 IP 
,   p_SIT_CD            VARCHAR2            -- 현장코드
,   p_APRV_DIV          VARCHAR2            -- 결재구분
,   p_APRV_YM           VARCHAR2            -- 결재년월
,   p_ATFL_GRP          VARCHAR2            -- 첨부파일
)
IS 
    /**************************************************************************************************************************
      Purpose : 

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/02/12                                   최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_APRV_DIV IS NULL)  THEN
        ERR_MSG := '결재구분은 필수 입력사항 입니다.'; 
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_APRV_YM IS NULL)  THEN
        ERR_MSG := '결재년월은 필수 입력사항 입니다.'; 
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------
    -- 결재상태 체크
    SELECT MAX(T2.APRV_STATS)
         , MAX(T3.CD_NM )
      INTO v_APRV_STATS
         , v_APRV_STATS_NM
      FROM TQHA_SAFECOST_APRV   T1
      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
                                  AND T1.APRV_NO    = T2.APRV_NO
      LEFT JOIN TCOA_COMCODE    T3 ON T2.APRV_STATS = T3.COM_CD 
                                  AND T3.HRNK_CD    = 'QS031'
     WHERE T1.SIT_CD    = p_SIT_CD
       AND T1.APRV_DIV  = '2'       -- 월별실적.
       AND T1.APRV_YM   = p_APRV_YM
    ;

    IF v_APRV_STATS IN ('2', '4') THEN
        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------

    ----------------------------------------------------------------------------------------------------
    -- 월별실적관리) : 첨부파일 저장 .
    IF (p_WRK_TP ='U') THEN

        MERGE 
          INTO TQHA_SAFECOST_APRV A
        USING DUAL
        ON (    A.SIT_CD        = p_SIT_CD
            AND A.APRV_DIV      = p_APRV_DIV
            AND A.APRV_YM       = p_APRV_YM
           )
        WHEN MATCHED THEN
            UPDATE
               SET ATFL_GRP     = p_ATFL_GRP
                 , UPD_ID       = p_WRK_ID
                 , UPD_DTM      = SYSDATE
                 , UPD_IP       = p_WRK_IP
        WHEN NOT MATCHED THEN
            INSERT 
                 ( SIT_CD
                 , APRV_DIV
                 , APRV_YM
                 , ATFL_GRP
                 , IPT_ID
                 , IPT_DTM
                 , IPT_IP
                 )
            VALUES 
                 ( p_SIT_CD
                 , p_APRV_DIV
                 , p_APRV_YM
                 , p_ATFL_GRP
                 , p_WRK_ID
                 , SYSDATE
                 , p_WRK_IP
                 )
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHA_SAFECOST_ARSLT_CO_DIV_Q
DROP PROCEDURE "PQHA_SAFECOST_ARSLT_CO_DIV_Q";
CREATE PROCEDURE "PQHA_SAFECOST_ARSLT_CO_DIV_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'             -- FLAG(Q: 현장평가, Q1:본사평가)
,   p_SIT_CD            IN VARCHAR2
,   p_ITM_DIV           IN VARCHAR2                         -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
,   p_RLV_YM            IN VARCHAR2                         -- 변수(년월)
,   p_CUST_CD           IN VARCHAR2                         -- 변수 (업체코드)
,   p_VNDR_SEQ          IN VARCHAR2                         -- 변수 (업체순번)
,   RTN_CURSOR       OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : 산업안전보건관리비 : 협력업체 항목별 사용내역 조회

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2026/02/26                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    -- 협력업체 매월 사용실적 조회 ( 1 안전보건관리자 입금 )
    IF p_ITM_DIV = '01' THEN

        OPEN RTN_CURSOR FOR
        SELECT SIT_CD               -- 현장코드
             , ITM_DIV              -- 항목구분 (공통코드 QS026)
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
             , RLV_YM               -- 해당년월
             , USE_SEQ              -- 사용순번
             , BLN_18               -- 소속
             , PNM_18               -- 성명
             , PRCR_DT_18           -- 선임일자
             , USE_AMT              -- 사용금액(지급금액)
             , USE_DT               -- 사용일자(지급일자)
             , USE_DTLS             -- 사용내역(지급내역)
             , RMKS                 -- 비고
             , GRP_PHOTO_1          -- 첨부파일그룹1
             , PHOTO_DESC_1         -- 사진설명1
             , CUST_CD              -- 업체코드
             , VNDR_SEQ             -- 업체순번
             , DLV_VNDR             -- 납품업체
             , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
             , GRP_PHOTO_2          -- 첨부파일그룹2
             , PHOTO_DESC_2         -- 사진설명2
             , USE_UPRC             -- 사용단가
             , USE_QNT              -- 사용수량
          FROM TQHA_SAFECOST_ARSLT_CO
         WHERE SIT_CD       = p_SIT_CD      -- 변수(현장코드)
           AND ITM_DIV      = p_ITM_DIV     -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
           AND RLV_YM       = p_RLV_YM      -- 변수(년월)
           AND CUST_CD      = p_CUST_CD     -- 변수 (업체코드)
           AND VNDR_SEQ     = p_VNDR_SEQ    -- 변수 (업체순번)
         ORDER BY ITM_DIV, USE_DT
        ;

    --------------------------------------------------------------------------------
    -- 협력업체 매월 사용실적 조회 ( 2 안전시설비 )
    ELSIF p_ITM_DIV = '02' THEN

        OPEN RTN_CURSOR FOR
        SELECT SIT_CD               -- 현장코드
             , ITM_DIV              -- 항목구분 (공통코드 QS026)
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
             , RLV_YM               -- 해당년월
             , USE_SEQ              -- 사용순번
             , USE_DT               -- 사용일자
             , USE_UNT              -- 사용단위
             , USE_QNT              -- 사용수량
             , LCST_UPRC_2          -- 노무비단가
             , MCST_UPRC_2          -- 자재비단가
             , USE_UPRC             -- 사용단가 계(노무비단가 + 자재비단가)
             , USE_AMT              -- 사용금액
             , USE_DTLS             -- 사용내역(지급내역)
             , RMKS                 -- 비고
             , GRP_PHOTO_1          -- 첨부파일그룹1
             , PHOTO_DESC_1         -- 사진설명1
             , CUST_CD              -- 업체코드
             , VNDR_SEQ             -- 업체순번
             , DLV_VNDR             -- 납품업체
             , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
             , GRP_PHOTO_2          -- 첨부파일그룹2
             , PHOTO_DESC_2         -- 사진설명2
          FROM TQHA_SAFECOST_ARSLT_CO
         WHERE SIT_CD       = p_SIT_CD      -- 변수(현장코드)
           AND ITM_DIV      = p_ITM_DIV     -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
           AND RLV_YM       = p_RLV_YM      -- 변수(년월)
           AND CUST_CD      = p_CUST_CD     -- 변수 (업체코드)
           AND VNDR_SEQ     = p_VNDR_SEQ    -- 변수 (업체순번)
         ORDER BY ITM_DIV, USE_DT
        ;

    --------------------------------------------------------------------------------
    -- 협력업체 매월 사용실적 조회 ( 3 보호구 )
    ELSIF p_ITM_DIV = '03' THEN

        OPEN RTN_CURSOR FOR
        SELECT SIT_CD               -- 현장코드
             , ITM_DIV              -- 항목구분 (공통코드 QS026)
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
             , RLV_YM               -- 해당년월
             , USE_SEQ              -- 사용순번
             , PLN_UPRC_39          -- 계획단가
             , PLN_QNT_39           -- 계획수량
             , PLN_AMT_39           -- 계획금액
             , USE_DT               -- 사용일자
             , USE_UPRC             -- 사용단가
             , USE_QNT              -- 사용수량
             , USE_AMT              -- 사용금액
             , USE_DTLS             -- 사용내역(지급내역)
             , RMKS                 -- 비고
             , GRP_PHOTO_1          -- 첨부파일그룹1
             , PHOTO_DESC_1         -- 사진설명1
             , CUST_CD              -- 업체코드
             , VNDR_SEQ             -- 업체순번
             , DLV_VNDR             -- 납품업체
             , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
             , GRP_PHOTO_2          -- 첨부파일그룹2
             , PHOTO_DESC_2         -- 사진설명2
          FROM TQHA_SAFECOST_ARSLT_CO
         WHERE SIT_CD       = p_SIT_CD        -- 변수(현장코드)
           AND ITM_DIV      = p_ITM_DIV       -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
           AND RLV_YM       = p_RLV_YM        -- 변수(년월)
           AND CUST_CD      = p_CUST_CD       -- 변수 (업체코드)
           AND VNDR_SEQ     = p_VNDR_SEQ      -- 변수 (업체순번)
         ORDER BY ITM_DIV, USE_DT
        ;

    --------------------------------------------------------------------------------
    -- 협력업체 매월 사용실적 조회 ( 4 안전보건진단비 )
    ELSIF p_ITM_DIV = '04' THEN

        OPEN RTN_CURSOR FOR
        SELECT SIT_CD               -- 현장코드
             , ITM_DIV              -- 항목구분 (공통코드 QS026)
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
             , RLV_YM               -- 해당년월
             , USE_SEQ              -- 사용순번
             , DGS_ORG_4            -- 진단기관
             , USE_DT               -- 사용일자
             , USE_AMT              -- 사용금액(소요비용)
             , USE_DTLS             -- 사용내역(지급내역)
             , RMKS                 -- 비고
             , GRP_PHOTO_1          -- 첨부파일그룹1
             , PHOTO_DESC_1         -- 사진설명1
             , CUST_CD              -- 업체코드
             , VNDR_SEQ             -- 업체순번
             , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
             , GRP_PHOTO_2          -- 첨부파일그룹2
             , PHOTO_DESC_2         -- 사진설명2
             , USE_UPRC             -- 사용단가
             , USE_QNT              -- 사용수량
          FROM TQHA_SAFECOST_ARSLT_CO
         WHERE SIT_CD       = p_SIT_CD      -- 변수(현장코드)
           AND ITM_DIV      = p_ITM_DIV     -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
           AND RLV_YM       = p_RLV_YM      -- 변수(년월)
           AND CUST_CD      = p_CUST_CD     -- 변수 (업체코드)
           AND VNDR_SEQ     = p_VNDR_SEQ    -- 변수 (업체순번)
         ORDER BY ITM_DIV, USE_DT
        ;

    --------------------------------------------------------------------------------
    -- 협력업체 매월 사용실적 조회 ( 5 안전보건교육비 )
    ELSIF p_ITM_DIV = '05' THEN

        OPEN RTN_CURSOR FOR
        SELECT SIT_CD               -- 현장코드
             , ITM_DIV              -- 항목구분 (공통코드 QS026)
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
             , RLV_YM               -- 해당년월
             , USE_SEQ              -- 사용순번
             , EDU_ATTL5            -- 교육과목
             , EDU_SPNC_5           -- 교육주관
             , USE_DT               -- 사용일자(교육일)
             , PRTC_PSNNO_56        -- 참가인원(숫자)
             , USE_AMT              -- 사용금액(소요경비)
             , RMKS                 -- 비고
             , GRP_PHOTO_1          -- 첨부파일그룹1
             , PHOTO_DESC_1         -- 사진설명1
             , CUST_CD              -- 업체코드
             , VNDR_SEQ             -- 업체순번
             , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
             , GRP_PHOTO_2          -- 첨부파일그룹2
             , PHOTO_DESC_2         -- 사진설명2
             , USE_UPRC             -- 사용단가
             , USE_QNT              -- 사용수량
          FROM TQHA_SAFECOST_ARSLT_CO
         WHERE SIT_CD       = p_SIT_CD       -- 변수(현장코드)
           AND ITM_DIV      = p_ITM_DIV      -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
           AND RLV_YM       = p_RLV_YM       -- 변수(년월)
           AND CUST_CD      = p_CUST_CD      -- 변수 (업체코드)
           AND VNDR_SEQ     = p_VNDR_SEQ     -- 변수 (업체순번)
         ORDER BY ITM_DIV, USE_DT
        ;

    --------------------------------------------------------------------------------
    -- 협력업체 매월 사용실적 조회 ( 6 근로자 건강장해예방비 )
    ELSIF p_ITM_DIV = '06' THEN

        OPEN RTN_CURSOR FOR
        SELECT SIT_CD               -- 현장코드
             , ITM_DIV              -- 항목구분 (공통코드 QS026)
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
             , RLV_YM               -- 해당년월
             , USE_SEQ              -- 사용순번
             , USE_DT               -- 사용일자
             , DGS_HOSP6            -- 진단병원
             , PRTC_PSNNO_56        -- 참가인원
             , USE_AMT              -- 사용금액(소요경비)
             , RMKS                 -- 비고
             , GRP_PHOTO_1          -- 첨부파일그룹1
             , PHOTO_DESC_1         -- 사진설명1
             , CUST_CD              -- 업체코드
             , VNDR_SEQ             -- 업체순번
             , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
             , GRP_PHOTO_2          -- 첨부파일그룹2
             , PHOTO_DESC_2         -- 사진설명2
             , USE_UPRC             -- 사용단가
             , USE_QNT              -- 사용수량
          FROM TQHA_SAFECOST_ARSLT_CO
         WHERE SIT_CD       = p_SIT_CD       -- 변수(현장코드)
           AND ITM_DIV      = p_ITM_DIV      -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
           AND RLV_YM       = p_RLV_YM       -- 변수(년월)
           AND CUST_CD      = p_CUST_CD      -- 변수 (업체코드)
           AND VNDR_SEQ     = p_VNDR_SEQ     -- 변수 (업체순번)
         ORDER BY ITM_DIV, USE_DT
        ;

    --------------------------------------------------------------------------------
    -- 협력업체 매월 사용실적 조회 (9 위험성평가 등에 따른 소요비용)
    ELSIF p_ITM_DIV = '09' THEN

        OPEN RTN_CURSOR FOR
        SELECT SIT_CD               -- 현장코드
             , ITM_DIV              -- 항목구분 (공통코드 QS026)
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
             , RLV_YM               -- 해당년월
             , USE_SEQ              -- 사용순번
             , USE_DT               -- 사용일자
             , DGS_HOSP6            -- 진단병원
             , PRTC_PSNNO_56        -- 참가인원
             , USE_AMT              -- 사용금액(소요경비)
             , RMKS                 -- 비고
             , GRP_PHOTO_1          -- 첨부파일그룹1
             , PHOTO_DESC_1         -- 사진설명1
             , CUST_CD              -- 업체코드
             , VNDR_SEQ             -- 업체순번
             , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
             , GRP_PHOTO_2          -- 첨부파일그룹2
             , PHOTO_DESC_2         -- 사진설명2
             , USE_UPRC             -- 사용단가
             , USE_QNT              -- 사용수량
             , USE_DTLS             -- 품명/규격
             , ITM_9                -- 지급내역
             , DLV_VNDR             -- 거래납품업체
          FROM TQHA_SAFECOST_ARSLT_CO
         WHERE SIT_CD       = p_SIT_CD          -- 변수(현장코드)
           AND ITM_DIV      = p_ITM_DIV         -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
           AND RLV_YM       = p_RLV_YM          -- 변수(년월)
           AND CUST_CD      = p_CUST_CD         -- 변수 (업체코드)
           AND VNDR_SEQ     = p_VNDR_SEQ        -- 변수 (업체순번)
         ORDER BY ITM_DIV, USE_DT
        ;

    END IF;


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_SAFECOST_ARSLT_CO_DIV_Q ;
/

-- PQHA_SAFECOST_ARSLT_CO_S
DROP PROCEDURE "PQHA_SAFECOST_ARSLT_CO_S";
CREATE PROCEDURE "PQHA_SAFECOST_ARSLT_CO_S" 
                            (p_WRK_TP  VARCHAR2 :='U'                                     -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
                            ,p_WRK_ID  VARCHAR2                                           -- 사용자 ID 
                            ,p_WRK_IP  VARCHAR2                                           -- 사용자 IP 
                            ,p_SIT_CD 		 TQHA_SAFECOST_ARSLT_CO.SIT_CD%TYPE           -- 현장코드 
                            ,p_ITM_DIV 		 TQHA_SAFECOST_ARSLT_CO.ITM_DIV%TYPE          -- 안전관리비 예산구분(QS026) 1 안전인건비 
                            ,p_CUST_CD 		 TQHA_SAFECOST_ARSLT_CO.CUST_CD%TYPE          -- 협력업체코드
                            ,p_VNDR_SEQ 	 TQHA_SAFECOST_ARSLT_CO.VNDR_SEQ%TYPE         -- 업체순번
                            ,p_RLV_YM 		 TQHA_SAFECOST_ARSLT_CO.RLV_YM%TYPE           -- 해당년월
                            ,p_USE_DT 		 TQHA_SAFECOST_ARSLT_CO.USE_DT%TYPE           -- 사용일자
                            ,p_USE_SEQ 		 TQHA_SAFECOST_ARSLT_CO.USE_SEQ%TYPE          -- 사용순번
                            ,p_USE_DTLS 	 TQHA_SAFECOST_ARSLT_CO.USE_DTLS%TYPE         -- 사용내역
                            ,p_USE_UNT 		 TQHA_SAFECOST_ARSLT_CO.USE_UNT%TYPE          -- 사용단위                            
                            ,p_USE_QNT 		 TQHA_SAFECOST_ARSLT_CO.USE_QNT%TYPE          -- 사용수량
                            ,p_USE_UPRC 	 TQHA_SAFECOST_ARSLT_CO.USE_UPRC%TYPE         -- 사용단가
                            ,p_USE_AMT 		 TQHA_SAFECOST_ARSLT_CO.USE_AMT%TYPE          -- 사용금액
                            ,p_GRP_PHOTO_1   TQHA_SAFECOST_ARSLT_CO.GRP_PHOTO_1%TYPE      -- 첨부파일그룹사진1
                            ,p_PHOTO_DESC_1  TQHA_SAFECOST_ARSLT_CO.PHOTO_DESC_1%TYPE     -- 사진설명1
                            ,p_RMKS 		 TQHA_SAFECOST_ARSLT_CO.RMKS%TYPE             -- 비고
                            ,p_BLN_18        TQHA_SAFECOST_ARSLT.PNM_18%TYPE              -- 소속 
					        ,p_PNM_18        TQHA_SAFECOST_ARSLT.PNM_18%TYPE              -- 성명
					        ,p_PRCR_DT_18     TQHA_SAFECOST_ARSLT.PRCR_DT_18%TYPE         -- 선임일자 
--					        ,p_LCST_UPRC_2   TQHA_SAFECOST_ARSLT.LCST_UPRC_2%TYPE         -- 노무비단가 24.08.09 주석처리
--					        ,p_MCST_UPRC_2   TQHA_SAFECOST_ARSLT.MCST_UPRC_2%TYPE         -- 자재비단가 24.08.09 주석처리 
					        ,p_PLN_UPRC_39   TQHA_SAFECOST_ARSLT.PLN_UPRC_39%TYPE         -- 계획단가
					        ,p_PLN_QNT_39    TQHA_SAFECOST_ARSLT.PLN_QNT_39%TYPE          -- 계획수량
					        ,p_PLN_AMT_39    TQHA_SAFECOST_ARSLT.PLN_AMT_39%TYPE          -- 계획금액
					        ,p_DGS_ORG_4     TQHA_SAFECOST_ARSLT.DGS_ORG_4%TYPE           -- 진단기관
					        ,p_EDU_ATTL5     TQHA_SAFECOST_ARSLT.EDU_ATTL5%TYPE           -- 교육과목
					        ,p_EDU_SPNC_5    TQHA_SAFECOST_ARSLT.EDU_SPNC_5%TYPE          -- 교육주관
					        ,p_PRTC_PSNNO_56 TQHA_SAFECOST_ARSLT.PRTC_PSNNO_56%TYPE       -- 참가인원
					        ,p_DGS_HOSP6     TQHA_SAFECOST_ARSLT.DGS_HOSP6%TYPE           -- 진단병원
					        ,p_GUI_ATTL7     TQHA_SAFECOST_ARSLT.GUI_ATTL7%TYPE           -- 지도항목
					        ,p_GUI_ORG7      TQHA_SAFECOST_ARSLT.GUI_ORG7%TYPE            -- 지도기관
					        ,p_DTY_8         TQHA_SAFECOST_ARSLT.DTY_8%TYPE               -- 직책
					        ,p_DTY_DT8       TQHA_SAFECOST_ARSLT.DTY_DT8%TYPE             -- 보직일자
					        ,p_ITM_9         TQHA_SAFECOST_ARSLT.ITM_9%TYPE               -- 품목명
					        ,p_SAFE_DT9      TQHA_SAFECOST_ARSLT.SAFE_DT9%TYPE            -- 위험결정일자
					        ,p_LAB_DT9       TQHA_SAFECOST_ARSLT.LAB_DT9%TYPE             -- 노사결정일자
					        ,p_DLV_VNDR      TQHA_SAFECOST_ARSLT.DLV_VNDR%TYPE            -- 납품업체
					        ,p_GRP_PHOTO_2   TQHA_SAFECOST_ARSLT_CO.GRP_PHOTO_2%TYPE      -- 첨부파일그룹사진2
                            ,p_PHOTO_DESC_2  TQHA_SAFECOST_ARSLT_CO.PHOTO_DESC_2%TYPE     -- 사진설명2
					        )
                            
IS 
    /**************************************************************************************************************************
      Purpose : 협력업체 월별 실적 저장

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2021/12/09 14:05:48                         최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_USE_SEQ TQHA_SAFECOST_ARSLT_CO.USE_SEQ%TYPE ;          -- 산업안전보건관리비 순번 변수 선언
    v_CNT  TQHA_SAFECOST_ARSLT_CO.USE_SEQ%TYPE ;             -- 월별 집계 테이블 존재 여부 체크 
BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_ITM_DIV IS NULL)  THEN
        ERR_MSG := '안전관리비 예산구분(QS026) 1 안전인건비 는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CUST_CD IS NULL)  THEN
        ERR_MSG := '협력업체코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_VNDR_SEQ IS NULL)  THEN
        ERR_MSG := '업체순번는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_RLV_YM IS NULL)  THEN
        ERR_MSG := '해당년월는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_USE_DT IS NULL)  THEN
        ERR_MSG := '사용일자는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_USE_SEQ IS NULL AND p_WRK_TP <> 'I')  THEN
        ERR_MSG := '사용순번는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN
        DELETE 
          FROM TQHA_SAFECOST_ARSLT_CO
         WHERE SIT_CD = p_SIT_CD         --현장코드
           AND ITM_DIV = p_ITM_DIV         --안전관리비 예산구분(QS026) 1 안전인건비 
           AND CUST_CD = p_CUST_CD         --협력업체코드
           AND VNDR_SEQ = p_VNDR_SEQ        --업체순번
           AND RLV_YM = p_RLV_YM          --해당년월
           AND USE_DT = p_USE_DT          --사용일자
           AND USE_SEQ = p_USE_SEQ;        --사용순번

    ELSIF (p_WRK_TP ='U') THEN

        UPDATE TQHA_SAFECOST_ARSLT_CO
           SET USE_DTLS             = p_USE_DTLS                --사용내역
              ,USE_UNT              = p_USE_UNT                 --사용단위           
              ,USE_QNT              = p_USE_QNT                 --사용수량
              ,USE_UPRC             = p_USE_UPRC                --사용단가
              ,USE_AMT              = p_USE_AMT                 --사용금액
              ,GRP_PHOTO_1          = p_GRP_PHOTO_1             --첨부파일그룹사진1
              ,PHOTO_DESC_1         = p_PHOTO_DESC_1            --사진설명1
              ,RMKS                 = p_RMKS                    --비고
              ,BLN_18               = p_BLN_18             -- 소속 
	          ,PNM_18               = p_PNM_18             -- 성명
	          ,PRCR_DT_18           = p_PRCR_DT_18         -- 선임일자 
--	          ,LCST_UPRC_2          = p_LCST_UPRC_2        -- 노무비단가 24.08.09 주석처리
--	          ,MCST_UPRC_2          = p_MCST_UPRC_2        -- 자재비단가 24.08.09 주석처리  
	          ,PLN_UPRC_39          = p_PLN_UPRC_39        -- 계획단가
	          ,PLN_QNT_39           = p_PLN_QNT_39         -- 계획수량
	          ,PLN_AMT_39           = p_PLN_AMT_39         -- 계획금액
	          ,DGS_ORG_4            = p_DGS_ORG_4          -- 진단기관
	          ,EDU_ATTL5            = p_EDU_ATTL5          -- 교육과목
	          ,EDU_SPNC_5           = p_EDU_SPNC_5         -- 교육주관
	          ,PRTC_PSNNO_56        = p_PRTC_PSNNO_56      -- 참가인원
	          ,DGS_HOSP6            = p_DGS_HOSP6          -- 진단병원
	          ,GUI_ATTL7            = p_GUI_ATTL7          -- 지도항목
	          ,GUI_ORG7             = p_GUI_ORG7           -- 지도기관
	          ,DTY_8                = p_DTY_8              -- 직책
	          ,DTY_DT8              = p_DTY_DT8            -- 보직일자
	          ,ITM_9                = p_ITM_9              -- 품목명	          
	          ,SAFE_DT9             = p_SAFE_DT9           -- 위험결정일자
	          ,LAB_DT9              = p_LAB_DT9            -- 노사결정일자
	          ,DLV_VNDR				= p_DLV_VNDR		   -- 납품업체
	          ,GRP_PHOTO_2          = p_GRP_PHOTO_2             --첨부파일그룹사진2
              ,PHOTO_DESC_2         = p_PHOTO_DESC_2            --사진설명2
              ,UPD_ID               = p_WRK_ID                  --수정ID 
              ,UPD_DTM              = SYSDATE()                 --수정일시
              ,UPD_IP               = p_WRK_IP                  --수정IP
         WHERE SIT_CD = p_SIT_CD         --현장코드
           AND ITM_DIV = p_ITM_DIV         --안전관리비 예산구분(QS026) 1 안전인건비 
           AND CUST_CD = p_CUST_CD         --협력업체코드
           AND VNDR_SEQ = p_VNDR_SEQ        --업체순번
           AND RLV_YM = p_RLV_YM          --해당년월
           AND USE_DT = p_USE_DT          --사용일자
           AND USE_SEQ = p_USE_SEQ;        --사용순번
    ELSE 
         -- 산업안전보건관리비 순번 생성 
        SELECT NVL( (MAX(USE_SEQ)+1),'1' ) 
          INTO v_USE_SEQ
          FROM TQHA_SAFECOST_ARSLT_CO
         WHERE SIT_CD = p_SIT_CD        --현장코드
           AND ITM_DIV = p_ITM_DIV        --안전관리비 예산구분(QS026) 1 안전인건비 
           AND CUST_CD = p_CUST_CD        --협력업체코드
           AND VNDR_SEQ = p_VNDR_SEQ      --업체순번           
           AND RLV_YM = p_RLV_YM          --해당년월
           AND USE_DT = p_USE_DT  ;       --사용일자
        --   
        INSERT INTO TQHA_SAFECOST_ARSLT_CO
                   ( SIT_CD                 --현장코드
                    ,ITM_DIV                 --안전관리비 예산구분(QS026) 1 안전인건비 
                    ,CUST_CD                 --협력업체코드
                    ,VNDR_SEQ                --업체순번
                    ,RLV_YM                  --해당년월
                    ,USE_DT                  --사용일자
                    ,USE_SEQ                 --사용순번
                    ,USE_DTLS                --사용내역
                    ,USE_UNT                 --사용단위                    
                    ,USE_QNT                 --사용수량
                    ,USE_UPRC                --사용단가
                    ,USE_AMT                 --사용금액
                    ,GRP_PHOTO_1             --첨부파일그룹사진1
                    ,PHOTO_DESC_1            --사진설명1
                    ,RMKS                    --비고
		            ,BLN_18                  -- 소속 
			        ,PNM_18                  -- 성명
			        ,PRCR_DT_18               -- 선임일자 
--			        ,LCST_UPRC_2             -- 노무비단가 24.08.09 주석처리
--			        ,MCST_UPRC_2             -- 자재비단가 24.08.09 주석처리 
			        ,PLN_UPRC_39             -- 계획단가
			        ,PLN_QNT_39              -- 계획수량
			        ,PLN_AMT_39              -- 계획금액
			        ,DGS_ORG_4               -- 진단기관
			        ,EDU_ATTL5               -- 교육과목
			        ,EDU_SPNC_5              -- 교육주관
			        ,PRTC_PSNNO_56           -- 참가인원
			        ,DGS_HOSP6               -- 진단병원
			        ,GUI_ATTL7               -- 지도항목
			        ,GUI_ORG7                -- 지도기관
			        ,DTY_8                   -- 직책
			        ,DTY_DT8                 -- 보직일자
	                ,ITM_9                   -- 품목명			        
			        ,SAFE_DT9                -- 위험결정일자
			        ,LAB_DT9                 -- 노사결정일자
			        ,DLV_VNDR				 -- 납품업체
			        ,GRP_PHOTO_2             --첨부파일그룹사진2
                    ,PHOTO_DESC_2            --사진설명2
                    ,IPT_ID                  --입력ID
                    ,IPT_DTM                 --입력일시
                    ,IPT_IP                  --입력IP
                    ,UPD_ID                  --수정ID
                    ,UPD_DTM                 --수정일시
                    ,UPD_IP)                 --수정IP
             VALUES (p_SIT_CD               --현장코드
                    ,p_ITM_DIV               --안전관리비 예산구분(QS026) 1 안전인건비 
                    ,p_CUST_CD               --협력업체코드
                    ,p_VNDR_SEQ              --업체순번
                    ,p_RLV_YM                --해당년월
                    ,p_USE_DT                --사용일자
                    ,v_USE_SEQ               --사용순번
                    ,p_USE_DTLS              --사용내역
                    ,p_USE_UNT               --사용단위                    
                    ,p_USE_QNT               --사용수량
                    ,p_USE_UPRC              --사용단가
                    ,p_USE_AMT               --사용금액
                    ,p_GRP_PHOTO_1           --첨부파일그룹사진1
                    ,SUBSTRB(p_USE_DT||','||v_USE_SEQ||','||p_USE_DTLS ,0, 100)        --사진설명1
                    ,p_RMKS                  --비고
	                ,p_BLN_18                -- 소속 
		            ,p_PNM_18                -- 성명
		            ,p_PRCR_DT_18            -- 선임일자 
--		            ,p_LCST_UPRC_2           -- 노무비단가 24.08.09 주석처리
--		            ,p_MCST_UPRC_2           -- 자재비단가 24.08.09 주석처리
		            ,p_PLN_UPRC_39           -- 계획단가
		            ,p_PLN_QNT_39            -- 계획수량
		            ,p_PLN_AMT_39            -- 계획금액
		            ,p_DGS_ORG_4             -- 진단기관
		            ,p_EDU_ATTL5             -- 교육과목
		            ,p_EDU_SPNC_5            -- 교육주관
		            ,p_PRTC_PSNNO_56         -- 참가인원
		            ,p_DGS_HOSP6             -- 진단병원
		            ,p_GUI_ATTL7             -- 지도항목
		            ,p_GUI_ORG7              -- 지도기관
		            ,p_DTY_8                 -- 직책
			        ,p_DTY_DT8               -- 보직일자
	                ,p_ITM_9                 -- 품목명			        		            
		            ,p_SAFE_DT9              -- 위험결정일자
		            ,p_LAB_DT9               -- 노사결정일자
		            ,p_DLV_VNDR				 -- 납품업체
		            ,p_GRP_PHOTO_2           --첨부파일그룹사진2
                    ,SUBSTRB(p_USE_DT||','||v_USE_SEQ||','||p_USE_DTLS ,0, 100)        --사진설명2
                    ,p_WRK_ID                --입력ID 
                    ,SYSDATE()               --입력일시
                    ,p_WRK_IP                --입력IP
                    ,p_WRK_ID                --수정ID
                    ,SYSDATE()               --수정일시
                    ,p_WRK_IP);              --수정IP

    END IF;


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHA_SAFECOST_ARSLT_Q
DROP PROCEDURE "PQHA_SAFECOST_ARSLT_Q";
CREATE PROCEDURE "PQHA_SAFECOST_ARSLT_Q" (
    p_WRK_TP                IN VARCHAR2 DEFAULT 'Q'             -- FLAG(Q: 현장평가, Q1:본사평가)
,   p_SIT_CD                IN VARCHAR2
,   p_ITM_DIV               IN VARCHAR2
,   p_RLV_YM                IN VARCHAR2
,   p_SEARCH_STR_YM         IN VARCHAR2
,   RTN_CURSOR              OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [평가항목 조회] PROCEDRE (QSE > 안전관리 > 산업안전보건관리비 > 월별실적관리  )

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2023/12/05                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    IF p_WRK_TP = 'Q' THEN

        IF (p_ITM_DIV = NULL) OR (p_ITM_DIV = '') THEN

            OPEN RTN_CURSOR FOR
            SELECT SIT_CD               -- 현장코드
                 , ITM_DIV              -- 항목구분 (공통코드 QS026)
                 , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
                 , RLV_YM               -- 해당년월
                 , USE_DT               -- 사용일자
                 , USE_SEQ              -- 사용순번
                 , USE_DTLS             -- 사용내역
                 , USE_UNT              -- 사용단위
                 , USE_QNT              -- 사용수량
                 , USE_UPRC             -- 사용단가
                 , USE_AMT              -- 사용금액
                 , RMKS                 -- 비고
                 , GRP_PHOTO_1          -- 첨부파일그룹1
                 , PHOTO_DESC_1         -- 사진설명1
                 , (SELECT B.APRV_STATS
                      FROM TQHA_SAFECOST_APRV   A
                         , TQHA_APRV            B
                     WHERE A.APRV_NO        = B.APRV_NO
                       AND A.SIT_CD         = p_SIT_CD
                       AND A.SIT_CD         = B.SIT_CD
                       AND A.APRV_DIV       = '2'
                       AND A.APRV_YM        = p_SEARCH_STR_YM
                   ) AS APRV_STATS
                 , DLV_VNDR             -- 납품업체
              FROM TQHA_SAFECOST_ARSLT
             WHERE SIT_CD       = p_SIT_CD              -- 변수(현장코드)
               AND RLV_YM       = p_SEARCH_STR_YM       -- 변수(년월)
             ORDER BY ITM_DIV
            ;

        ELSIF p_ITM_DIV = '01' THEN

            OPEN RTN_CURSOR FOR
            SELECT SIT_CD               -- 현장코드
                 , ITM_DIV              -- 항목구분 (공통코드 QS026)
                 , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
                 , RLV_YM               -- 해당년월
                 , USE_SEQ              -- 사용순번
                 , BLN_18               -- 소속
                 , PNM_18               -- 성명
                 , PRCR_DT_18           -- 선임일자
                 , USE_AMT              -- 사용금액(지급금액)
                 , USE_DT               -- 사용일자(지급일자)
                 , USE_DTLS             -- 사용내역(지급내역)
                 , RMKS                 -- 비고
                 , GRP_PHOTO_1          -- 첨부파일그룹1
                 , PHOTO_DESC_1         -- 사진설명1
                 , DLV_VNDR             -- 납품업체
                 , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
                 , GRP_PHOTO_2          -- 첨부파일그룹2
                 , PHOTO_DESC_2         -- 사진설명2
                 , USE_UPRC             -- 사용단가
                 , USE_QNT              -- 사용수량
              FROM TQHA_SAFECOST_ARSLT
             WHERE SIT_CD           = p_SIT_CD          -- 변수(현장코드)
               AND ITM_DIV          = p_ITM_DIV         -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
               AND RLV_YM           = p_RLV_YM          -- 변수(년월)
             ORDER BY ITM_DIV, USE_DT
            ;

        ELSIF p_ITM_DIV = '02' THEN

            OPEN RTN_CURSOR FOR
            -- 당사 매월 사용실적 조회 ( 2 안전시설비 )
            SELECT SIT_CD               -- 현장코드
                 , ITM_DIV              -- 항목구분 (공통코드 QS026)
                 , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
                 , RLV_YM               -- 해당년월
                 , USE_SEQ              -- 사용순번
                 , USE_DT               -- 사용일자
                 , USE_UNT              -- 사용단위
                 , USE_QNT              -- 사용수량
--               , LCST_UPRC_2          -- 노무비단가(24.08.09 주석처리)
--               , MCST_UPRC_2          -- 자재비단가(24.08.09 주석처리)
                 , USE_UPRC             -- 사용단가 계
                 , USE_AMT              -- 사용금액
                 , USE_DTLS             -- 사용내역(지급내역)
                 , RMKS                 -- 비고
                 , GRP_PHOTO_1          -- 첨부파일그룹1
                 , PHOTO_DESC_1         -- 사진설명1
                 , DLV_VNDR             -- 납품업체
                 , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
                 , GRP_PHOTO_2          -- 첨부파일그룹2
                 , PHOTO_DESC_2         -- 사진설명2
              FROM TQHA_SAFECOST_ARSLT
             WHERE SIT_CD               = p_SIT_CD          -- 변수(현장코드)
               AND ITM_DIV              = p_ITM_DIV         -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
               AND RLV_YM               = p_RLV_YM          -- 변수(년월)
             ORDER BY ITM_DIV, USE_DT
            ;

        ELSIF p_ITM_DIV = '03' THEN

            OPEN RTN_CURSOR FOR
            -- 당사 매월 사용실적 조회 ( 3 보호구 )
            SELECT SIT_CD               -- 현장코드
                 , ITM_DIV              -- 항목구분 (공통코드 QS026)
                 , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
                 , RLV_YM               -- 해당년월
                 , USE_SEQ              -- 사용순번
                 , PLN_UPRC_39          -- 계획단가
                 , PLN_QNT_39           -- 계획수량
                 , PLN_AMT_39           -- 계획금액
                 , USE_DT               -- 사용일자
                 , USE_UPRC             -- 사용단가
                 , USE_QNT              -- 사용수량
                 , USE_AMT              -- 사용금액
                 , USE_DTLS             -- 사용내역(지급내역)
                 , RMKS                 -- 비고
                 , GRP_PHOTO_1          -- 첨부파일그룹1
                 , PHOTO_DESC_1         -- 사진설명1
                 , DLV_VNDR             -- 납품업체
                 , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
                 , GRP_PHOTO_2          -- 첨부파일그룹2
                 , PHOTO_DESC_2         -- 사진설명2
              FROM TQHA_SAFECOST_ARSLT
             WHERE SIT_CD           = p_SIT_CD          -- 변수(현장코드)
               AND ITM_DIV          = p_ITM_DIV         -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
               AND RLV_YM           = p_RLV_YM          -- 변수(년월)
             ORDER BY ITM_DIV, USE_DT
            ;

        ELSIF p_ITM_DIV = '04' THEN

            OPEN RTN_CURSOR FOR
            -- 당사 매월 사용실적 조회 ( 4 안전보건진단비 )
            SELECT SIT_CD               -- 현장코드
                 , ITM_DIV              -- 항목구분 (공통코드 QS026)
                 , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
                 , RLV_YM               -- 해당년월
                 , USE_SEQ              -- 사용순번
                 , DGS_ORG_4            -- 진단기관
                 , USE_DT               -- 사용일자
                 , USE_AMT              -- 사용금액(소요비용)
                 , USE_DTLS             -- 사용내역(지급내역)
                 , RMKS                 -- 비고
                 , GRP_PHOTO_1          -- 첨부파일그룹1
                 , PHOTO_DESC_1         -- 사진설명1
                 , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
                 , GRP_PHOTO_2          -- 첨부파일그룹2
                 , PHOTO_DESC_2         -- 사진설명2
                 , USE_UPRC             -- 사용단가
                 , USE_QNT              -- 사용수량
              FROM TQHA_SAFECOST_ARSLT
             WHERE SIT_CD           = p_SIT_CD          -- 변수(현장코드)
               AND ITM_DIV          = p_ITM_DIV         -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
               AND RLV_YM           = p_RLV_YM          -- 변수(년월)
             ORDER BY ITM_DIV, USE_DT
            ;

        ELSIF p_ITM_DIV = '05' THEN

            OPEN RTN_CURSOR FOR
            -- 당사 매월 사용실적 조회 ( 5 안전보건교육비 )
            SELECT SIT_CD               -- 현장코드
                 , ITM_DIV              -- 항목구분 (공통코드 QS026)
                 , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
                 , RLV_YM               -- 해당년월
                 , USE_SEQ              -- 사용순번
                 , EDU_ATTL5            -- 교육과목
                 , EDU_SPNC_5           -- 교육주관
                 , USE_DT               -- 사용일자(교육일)
                 , PRTC_PSNNO_56        -- 참가인원(숫자)
                 , USE_AMT              -- 사용금액(소요경비)
                 , RMKS                 -- 비고
                 , GRP_PHOTO_1          -- 첨부파일그룹1
                 , PHOTO_DESC_1         -- 사진설명1
                 , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
                 , GRP_PHOTO_2          -- 첨부파일그룹2
                 , PHOTO_DESC_2         -- 사진설명2
                 , USE_UPRC             -- 사용단가
                 , USE_QNT              -- 사용수량
              FROM TQHA_SAFECOST_ARSLT
             WHERE SIT_CD           = p_SIT_CD          -- 변수(현장코드)
               AND ITM_DIV          = p_ITM_DIV         -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
               AND RLV_YM           = p_RLV_YM          -- 변수(년월)
             ORDER BY ITM_DIV, USE_DT
            ;

        ELSIF p_ITM_DIV = '06' THEN

            OPEN RTN_CURSOR FOR
            -- 당사 매월 사용실적 조회 ( 6 근로자 건강장해예방비 )
            SELECT SIT_CD               -- 현장코드
                 , ITM_DIV              -- 항목구분 (공통코드 QS026)
                 , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
                 , RLV_YM               -- 해당년월
                 , USE_SEQ              -- 사용순번
                 , USE_DT               -- 사용일자
                 , DGS_HOSP6            -- 진단병원
                 , PRTC_PSNNO_56        -- 참가인원
                 , USE_AMT              -- 사용금액(소요경비)
                 , RMKS                 -- 비고
                 , GRP_PHOTO_1          -- 첨부파일그룹1
                 , PHOTO_DESC_1         -- 사진설명1
                 , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
                 , GRP_PHOTO_2          -- 첨부파일그룹2
                 , PHOTO_DESC_2         -- 사진설명2
                 , USE_UPRC             -- 사용단가
                 , USE_QNT              -- 사용수량
              FROM TQHA_SAFECOST_ARSLT
             WHERE SIT_CD           = p_SIT_CD          -- 변수(현장코드)
               AND ITM_DIV          = p_ITM_DIV         -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
               AND RLV_YM           = p_RLV_YM          -- 변수(년월)
             ORDER BY ITM_DIV, USE_DT
            ;

        ELSIF p_ITM_DIV = '07' THEN

            OPEN RTN_CURSOR FOR
            -- 당사 매월 사용실적 조회 ( 7 기술지도비 )
            SELECT SIT_CD               -- 현장코드
                 , ITM_DIV              -- 항목구분 (공통코드 QS026)
                 , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
                 , RLV_YM               -- 해당년월
                 , USE_SEQ              -- 사용순번
                 , GUI_ATTL7            -- 지도항목
                 , GUI_ORG7             -- 지도기관
                 , USE_DT               -- 사용일자(점검일)
                 , USE_AMT              -- 사용금액(소요경비)
                 , RMKS                 -- 비고
                 , GRP_PHOTO_1          -- 첨부파일그룹1
                 , PHOTO_DESC_1         -- 사진설명1
                 , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
                 , GRP_PHOTO_2          -- 첨부파일그룹2
                 , PHOTO_DESC_2         -- 사진설명2
                 , USE_UPRC             -- 사용단가
                 , USE_QNT              -- 사용수량
              FROM TQHA_SAFECOST_ARSLT
             WHERE SIT_CD           = p_SIT_CD          -- 변수(현장코드)
               AND ITM_DIV          = p_ITM_DIV         -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
               AND RLV_YM           = p_RLV_YM          -- 변수(년월)
             ORDER BY ITM_DIV, USE_DT
            ;

        ELSIF p_ITM_DIV = '08' THEN

            OPEN RTN_CURSOR FOR
             -- 당사 매월 사용실적 조회 ( 8 본사전담조직 8-2 사용내역)
            SELECT SIT_CD               -- 현장코드
                 , ITM_DIV              -- 항목구분 (공통코드 QS026)
                 , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
                 , RLV_YM               -- 해당년월
                 , USE_SEQ              -- 사용순번
                 , BLN_18               -- 소속
                 , DTY_8                -- 직책
                 , PNM_18               -- 성명
                 , DTY_DT8              -- 보직일자
                 , USE_AMT              -- 사용금액(지급액)
                 , USE_DT               -- 사용일자(지급일)
                 , RMKS                 -- 비고
                 , GRP_PHOTO_1          -- 첨부파일그룹1
                 , PHOTO_DESC_1         -- 사진설명1
                 , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
                 , GRP_PHOTO_2          -- 첨부파일그룹2
                 , PHOTO_DESC_2         -- 사진설명2
              FROM TQHA_SAFECOST_ARSLT
             WHERE SIT_CD           = p_SIT_CD          -- 변수(현장코드)
               AND ITM_DIV          = p_ITM_DIV         -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
               AND RLV_YM           = p_RLV_YM          -- 변수(년월)
             ORDER BY ITM_DIV, USE_DT
            ;

        ELSIF p_ITM_DIV = '09' THEN

            OPEN RTN_CURSOR FOR
            -- 당사 매월 사용실적 조회 (9 위험성평가 등에 따른 소요비용)
            SELECT SIT_CD               -- 현장코드
                 , ITM_DIV              -- 항목구분 (공통코드 QS026)
                 , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
                 , RLV_YM               -- 해당년월
                 , USE_SEQ              -- 사용순번
                 , ITM_9                -- 품목명
                 , SAFE_DT9             -- 위험결정일자
                 , LAB_DT9              -- 노사결정일자
                   , PLN_UPRC_39        -- 계획단가
                   , PLN_QNT_39         -- 계획수량
                   , PLN_AMT_39         -- 계획금액
                 , USE_DT               -- 사용일자
                 , USE_UPRC             -- 사용단가
                 , USE_QNT              -- 사용수량
                 , USE_AMT              -- 사용금액
                 , USE_DTLS             -- 사용내역(지급내역)
                 , RMKS                 -- 비고
                 , GRP_PHOTO_1          -- 첨부파일그룹1
                 , PHOTO_DESC_1         -- 사진설명1
                 , DLV_VNDR             -- 납품업체
                 , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
                 , GRP_PHOTO_2          -- 첨부파일그룹2
                 , PHOTO_DESC_2         -- 사진설명2
              FROM TQHA_SAFECOST_ARSLT
             WHERE SIT_CD           = p_SIT_CD          -- 변수(현장코드)
               AND ITM_DIV          = p_ITM_DIV         -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
               AND RLV_YM           = p_RLV_YM          -- 변수(년월)
             ORDER BY ITM_DIV, USE_DT
            ;

        END IF;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_SAFECOST_ARSLT_Q;
/

-- PQHA_SAFECOST_ARSLT_S
DROP PROCEDURE "PQHA_SAFECOST_ARSLT_S";
CREATE PROCEDURE "PQHA_SAFECOST_ARSLT_S" (
    p_WRK_TP                    VARCHAR2 :='U'                                          -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID                    VARCHAR2                                                -- 사용자 ID
,   p_WRK_IP                    VARCHAR2                                                -- 사용자 IP
,   p_SIT_CD                    TQHA_SAFECOST_ARSLT.SIT_CD              %TYPE           -- 현장코드
,   p_ITM_DIV                   TQHA_SAFECOST_ARSLT.ITM_DIV             %TYPE           -- 안전관리비 예산구분(QS026) 1 안전인건비
,   p_RLV_YM                    TQHA_SAFECOST_ARSLT.RLV_YM              %TYPE           -- 해당년월
,   p_USE_DT                    TQHA_SAFECOST_ARSLT.USE_DT              %TYPE           -- 사용일자
,   p_USE_SEQ                   TQHA_SAFECOST_ARSLT.USE_SEQ             %TYPE           -- 사용순번
,   p_USE_DTLS                  TQHA_SAFECOST_ARSLT.USE_DTLS            %TYPE           -- 사용내역
,   p_USE_UNT                   TQHA_SAFECOST_ARSLT.USE_UNT             %TYPE           -- 사용단위
,   p_USE_QNT                   TQHA_SAFECOST_ARSLT.USE_QNT             %TYPE           -- 사용수량
,   p_USE_UPRC                  TQHA_SAFECOST_ARSLT.USE_UPRC            %TYPE           -- 사용단가
,   p_USE_AMT                   TQHA_SAFECOST_ARSLT.USE_AMT             %TYPE           -- 사용금액
,   p_RMKS                      TQHA_SAFECOST_ARSLT.RMKS                %TYPE           -- 비고
,   p_GRP_PHOTO_1               TQHA_SAFECOST_ARSLT.GRP_PHOTO_1         %TYPE           -- 첨부파일그룹사진1
,   p_PHOTO_DESC_1              TQHA_SAFECOST_ARSLT.PHOTO_DESC_1        %TYPE           -- 사진설명1
,   p_BLN_18                    TQHA_SAFECOST_ARSLT.PNM_18              %TYPE           -- 소속
,   p_PNM_18                    TQHA_SAFECOST_ARSLT.PNM_18              %TYPE           -- 성명
,   p_PRCR_DT_18                TQHA_SAFECOST_ARSLT.PRCR_DT_18          %TYPE           -- 선임일자
--, p_LCST_UPRC_2               TQHA_SAFECOST_ARSLT.LCST_UPRC_2         %TYPE           -- 노무비단가 24.08.09 주석처리
--, p_MCST_UPRC_2               TQHA_SAFECOST_ARSLT.MCST_UPRC_2         %TYPE           -- 자재비단가 24.08.09 주석처리
,   p_PLN_UPRC_39               TQHA_SAFECOST_ARSLT.PLN_UPRC_39         %TYPE           -- 계획단가
,   p_PLN_QNT_39                TQHA_SAFECOST_ARSLT.PLN_QNT_39          %TYPE           -- 계획수량
,   p_PLN_AMT_39                TQHA_SAFECOST_ARSLT.PLN_AMT_39          %TYPE           -- 계획금액
,   p_DGS_ORG_4                 TQHA_SAFECOST_ARSLT.DGS_ORG_4           %TYPE           -- 진단기관
,   p_EDU_ATTL5                 TQHA_SAFECOST_ARSLT.EDU_ATTL5           %TYPE           -- 교육과목
,   p_EDU_SPNC_5                TQHA_SAFECOST_ARSLT.EDU_SPNC_5          %TYPE           -- 교육주관
,   p_PRTC_PSNNO_56             TQHA_SAFECOST_ARSLT.PRTC_PSNNO_56       %TYPE           -- 참가인원
,   p_DGS_HOSP6                 TQHA_SAFECOST_ARSLT.DGS_HOSP6           %TYPE           -- 진단병원
,   p_GUI_ATTL7                 TQHA_SAFECOST_ARSLT.GUI_ATTL7           %TYPE           -- 지도항목
,   p_GUI_ORG7                  TQHA_SAFECOST_ARSLT.GUI_ORG7            %TYPE           -- 지도기관
,   p_DTY_8                     TQHA_SAFECOST_ARSLT.DTY_8               %TYPE           -- 직책
,   p_DTY_DT8                   TQHA_SAFECOST_ARSLT.DTY_DT8             %TYPE           -- 보직일자
,   p_ITM_9                     TQHA_SAFECOST_ARSLT.ITM_9               %TYPE           -- 품목명
,   p_SAFE_DT9                  TQHA_SAFECOST_ARSLT.SAFE_DT9            %TYPE           -- 위험결정일자
,   p_LAB_DT9                   TQHA_SAFECOST_ARSLT.LAB_DT9             %TYPE           -- 노사결정일자
,   p_DLV_VNDR                  TQHA_SAFECOST_ARSLT.DLV_VNDR            %TYPE           -- 납품업체
,   p_GRP_PHOTO_2               TQHA_SAFECOST_ARSLT.GRP_PHOTO_2         %TYPE           -- 첨부파일그룹사진2
,   p_PHOTO_DESC_2              TQHA_SAFECOST_ARSLT.PHOTO_DESC_2        %TYPE           -- 사진설명2
)
IS
    /**************************************************************************************************************************
      Purpose : 당사 월별 실적 저장

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2021/12/09 14:03:44                         최초생성

    **************************************************************************************************************************/



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_USE_SEQ TQHA_SAFECOST_ARSLT.USE_SEQ%TYPE ;             -- 산업안전보건관리비 순번 변수 선언

    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_ITM_DIV IS NULL AND p_WRK_TP <> 'B')  THEN
        ERR_MSG := '안전관리비 예산구분(QS026) 1 안전인건비 는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_RLV_YM IS NULL AND p_WRK_TP <> 'B')  THEN
        ERR_MSG := '해당년월는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_USE_DT IS NULL AND p_WRK_TP <> 'B')  THEN
        ERR_MSG := '사용일자는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_USE_SEQ IS NULL AND p_WRK_TP <> 'I' AND p_WRK_TP <> 'B')  THEN
        ERR_MSG := '사용순번는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------
    -- 결재상태 체크
    SELECT MAX(T2.APRV_STATS)
         , MAX(T3.CD_NM )
      INTO v_APRV_STATS
         , v_APRV_STATS_NM
      FROM TQHA_SAFECOST_APRV   T1
      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
                                  AND T1.APRV_NO    = T2.APRV_NO
      LEFT JOIN TCOA_COMCODE    T3 ON T2.APRV_STATS = T3.COM_CD
                                  AND T3.HRNK_CD    = 'QS031'
     WHERE T1.SIT_CD    = p_SIT_CD
       AND T1.APRV_DIV  = '2'       -- 월별실적.
       AND T1.APRV_YM   = p_RLV_YM
    ;

    IF v_APRV_STATS IN ('2', '4') THEN
        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN

        DELETE
          FROM TQHA_SAFECOST_ARSLT
         WHERE SIT_CD       = p_SIT_CD          -- 현장코드
           AND ITM_DIV      = p_ITM_DIV         -- 안전관리비 예산구분(QS026) 1 안전인건비
           AND RLV_YM       = p_RLV_YM          -- 해당년월
           AND USE_DT       = p_USE_DT          -- 사용일자
           AND USE_SEQ      = p_USE_SEQ         -- 사용순번
        ;

    ELSIF (p_WRK_TP ='U') THEN

        UPDATE TQHA_SAFECOST_ARSLT
           SET USE_DTLS             = p_USE_DTLS                -- 사용내역
             , USE_UNT              = p_USE_UNT                 -- 사용단위
             , USE_QNT              = p_USE_QNT                 -- 사용수량
             , USE_UPRC             = p_USE_UPRC                -- 사용단가
             , USE_AMT              = p_USE_AMT                 -- 사용금액
             , RMKS                 = p_RMKS                    -- 비고
             , GRP_PHOTO_1          = p_GRP_PHOTO_1             -- 첨부파일그룹사진1
             , PHOTO_DESC_1         = p_PHOTO_DESC_1            -- 사진설명1
             , BLN_18               = p_BLN_18                  -- 소속
             , PNM_18               = p_PNM_18                  -- 성명
             , PRCR_DT_18           = p_PRCR_DT_18              -- 선임일자
--           , LCST_UPRC_2          = p_LCST_UPRC_2             -- 노무비단가 24.08.09 주석처리
--           , MCST_UPRC_2          = p_MCST_UPRC_2             -- 자재비단가 24.08.09 주석처리
             , PLN_UPRC_39          = p_PLN_UPRC_39             -- 계획단가
             , PLN_QNT_39           = p_PLN_QNT_39              -- 계획수량
             , PLN_AMT_39           = p_PLN_AMT_39              -- 계획금액
             , DGS_ORG_4            = p_DGS_ORG_4               -- 진단기관
             , EDU_ATTL5            = p_EDU_ATTL5               -- 교육과목
             , EDU_SPNC_5           = p_EDU_SPNC_5              -- 교육주관
             , PRTC_PSNNO_56        = p_PRTC_PSNNO_56           -- 참가인원
             , DGS_HOSP6            = p_DGS_HOSP6               -- 진단병원
             , GUI_ATTL7            = p_GUI_ATTL7               -- 지도항목
             , GUI_ORG7             = p_GUI_ORG7                -- 지도기관
             , DTY_8                = p_DTY_8                   -- 직책
             , DTY_DT8              = p_DTY_DT8                 -- 보직일자
             , ITM_9                = p_ITM_9                   -- 품목명
             , SAFE_DT9             = p_SAFE_DT9                -- 위험결정일자
             , LAB_DT9              = p_LAB_DT9                 -- 노사결정일자
             , DLV_VNDR             = p_DLV_VNDR                -- 납품업체
             , GRP_PHOTO_2          = p_GRP_PHOTO_2             -- 첨부파일그룹사진2
             , PHOTO_DESC_2         = p_PHOTO_DESC_2            -- 사진설명2
             , UPD_ID               = p_WRK_ID                  -- 수정ID
             , UPD_DTM              = SYSDATE()                 -- 수정일시
             , UPD_IP               = p_WRK_IP                  -- 수정IP
         WHERE SIT_CD               = p_SIT_CD                  -- 현장코드
           AND ITM_DIV              = p_ITM_DIV                 -- 안전관리비 예산구분(QS026) 1 안전인건비
           AND RLV_YM               = p_RLV_YM                  -- 해당년월
           AND USE_DT               = p_USE_DT                  -- 사용일자
           AND USE_SEQ              = p_USE_SEQ                 -- 사용순번
        ;

    ELSE

        -- 산업안전보건관리비 순번 생성
        SELECT NVL( (MAX(USE_SEQ)+1),'1' )
          INTO v_USE_SEQ
          FROM TQHA_SAFECOST_ARSLT
         WHERE SIT_CD       = p_SIT_CD          -- 현장코드
           AND ITM_DIV      = p_ITM_DIV         -- 안전관리비 예산구분(QS026) 1 안전인건비
           AND RLV_YM       = p_RLV_YM          -- 해당년월
           AND USE_DT       = p_USE_DT          -- 사용일자
        ;
        --

        INSERT 
          INTO TQHA_SAFECOST_ARSLT
             ( SIT_CD                   -- 현장코드
             , ITM_DIV                  -- 안전관리비 예산구분(QS026) 1 안전인건비
             , RLV_YM                   -- 해당년월
             , USE_DT                   -- 사용일자
             , USE_SEQ                  -- 사용순번
             , USE_DTLS                 -- 사용내역
             , USE_UNT                  -- 사용단위
             , USE_QNT                  -- 사용수량
             , USE_UPRC                 -- 사용단가
             , USE_AMT                  -- 사용금액
             , RMKS                     -- 비고
             , GRP_PHOTO_1              -- 첨부파일그룹사진1
             , PHOTO_DESC_1             -- 사진설명1
             , BLN_18                   -- 소속
             , PNM_18                   -- 성명
             , PRCR_DT_18               -- 선임일자
--           , LCST_UPRC_2              -- 노무비단가 24.08.09 주석처리
--           , MCST_UPRC_2              -- 자재비단가 24.08.09 주석처리
             , PLN_UPRC_39              -- 계획단가
             , PLN_QNT_39               -- 계획수량
             , PLN_AMT_39               -- 계획금액
             , DGS_ORG_4                -- 진단기관
             , EDU_ATTL5                -- 교육과목
             , EDU_SPNC_5               -- 교육주관
             , PRTC_PSNNO_56            -- 참가인원
             , DGS_HOSP6                -- 진단병원
             , GUI_ATTL7                -- 지도항목
             , GUI_ORG7                 -- 지도기관
             , DTY_8                    -- 직책
             , DTY_DT8                  -- 보직일자
             , ITM_9                    -- 품목명
             , SAFE_DT9                 -- 위험결정일자
             , LAB_DT9                  -- 노사결정일자
             , DLV_VNDR                 -- 납품업체
             , GRP_PHOTO_2              -- 첨부파일그룹사진2
             , PHOTO_DESC_2             -- 사진설명2
             , IPT_ID                   -- 입력ID
             , IPT_DTM                  -- 입력일시
             , IPT_IP                   -- 입력IP
             , UPD_ID                   -- 수정ID
             , UPD_DTM                  -- 수정일시
             , UPD_IP                   -- 수정IP
             )
        VALUES 
             ( p_SIT_CD                 -- 현장코드
             , p_ITM_DIV                -- 안전관리비 예산구분(QS026) 1 안전인건비
             , p_RLV_YM                 -- 해당년월
             , p_USE_DT                 -- 사용일자
             , v_USE_SEQ                -- 사용순번
             , p_USE_DTLS               -- 사용내역
             , p_USE_UNT                -- 사용단위
             , p_USE_QNT                -- 사용수량
             , p_USE_UPRC               -- 사용단가
             , p_USE_AMT                -- 사용금액
             , p_RMKS                   -- 비고
             , p_GRP_PHOTO_1            -- 첨부파일그룹사진1
             , SUBSTRB(p_USE_DT||','||v_USE_SEQ||','||p_USE_DTLS ,0, 100)          --사진설명1
             , p_BLN_18                 -- 소속
             , p_PNM_18                 -- 성명
             , p_PRCR_DT_18             -- 선임일자
--           , p_LCST_UPRC_2            -- 노무비단가 24.08.09 주석처리
--           , p_MCST_UPRC_2            -- 자재비단가 24.08.09 주석처리
             , p_PLN_UPRC_39            -- 계획단가
             , p_PLN_QNT_39             -- 계획수량
             , p_PLN_AMT_39             -- 계획금액
             , p_DGS_ORG_4              -- 진단기관
             , p_EDU_ATTL5              -- 교육과목
             , p_EDU_SPNC_5             -- 교육주관
             , p_PRTC_PSNNO_56          -- 참가인원
             , p_DGS_HOSP6              -- 진단병원
             , p_GUI_ATTL7              -- 지도항목
             , p_GUI_ORG7               -- 지도기관
             , p_DTY_8                  -- 직책
             , p_DTY_DT8                -- 보직일자
             , p_ITM_9                  -- 품목명
             , p_SAFE_DT9               -- 위험결정일자
             , p_LAB_DT9                -- 노사결정일자
             , p_DLV_VNDR               -- 납품업체
             , p_GRP_PHOTO_2            -- 첨부파일그룹사진1
             , SUBSTRB(p_USE_DT||','||v_USE_SEQ||','||p_USE_DTLS ,0, 100)          --사진설명2
             , p_WRK_ID                 -- 입력ID
             , SYSDATE()                -- 입력일시
             , p_WRK_IP                 -- 입력IP
             , p_WRK_ID                 -- 수정ID
             , SYSDATE()                -- 수정일시
             , p_WRK_IP                 -- 수정IP
             )
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END ;
/

-- PQHA_SAFECOST_BGTYM_B
DROP PROCEDURE "PQHA_SAFECOST_BGTYM_B";
CREATE PROCEDURE "PQHA_SAFECOST_BGTYM_B" 
                            (p_WRK_TP  VARCHAR2 :='U'                  -- UPDATE FLAG
                            ,p_WRK_ID  VARCHAR2                                           -- 사용자 ID 
                            ,p_WRK_IP  VARCHAR2                                           -- 사용자 IP 
                            ,p_SIT_CD 		VARCHAR2                   -- 현장코드
                            ,p_STR_DT		VARCHAR2                   -- 시작일자 
                            ,p_END_DT 		VARCHAR2)                  -- 종료일자
IS 
    /**************************************************************************************************************************
      Purpose : 예산 생성

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2024/05/08 14:05:17                         최초생성
    **************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;


BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_STR_DT IS NULL)  THEN
        ERR_MSG := '공사 시작일자는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

       IF (p_END_DT IS NULL)  THEN
        ERR_MSG := '공사 종료일자는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='B') THEN  -- 자동생성 ( 배치 )
       --  9대항목별 전체예산 추가  TQHA_SAFECOST_BGT
		MERGE INTO TQHA_SAFECOST_BGT T
		USING ( -- -- 공통코드에 등록된 안전관리비 항목
				    SELECT p_SIT_CD AS SIT_CD  -- p_SIT_CD                           -- 변수 (현장코드)
				           , COM_CD 
				           , CD_NM
					  FROM TCOA_COMCODE
					 WHERE HRNK_CD = 'QS026'   -- 상위코드가 'QS026'
					   AND USE_YN = '1'        -- 사용여부
					ORDER BY COM_CD			
		       ) S
		   ON (T.SIT_CD = S.SIT_CD AND T.ITM_DIV = S.COM_CD )
		WHEN MATCHED
			THEN UPDATE SET
		           T.WHL_EBGT_BGT  = 0                           -- 전체실행예산
		         , T.UPD_ID        = p_WRK_ID                    --수정ID
				 , T.UPD_DTM       = SYSDATE()                   --수정일시
				 , T.UPD_IP        = p_WRK_IP                    --수정IP
		WHEN NOT MATCHED
			THEN INSERT ( SIT_CD                         --현장코드 
			            , ITM_DIV                        --항목구분
			            , WHL_EBGT_BGT                   --전체실행예산
			            , T.IPT_ID                       --입력ID 
					    , T.IPT_DTM                      --입력일시
					    , T.IPT_IP)                      --입력IP
			     VALUES ( S.SIT_CD                          --현장코드 
			            , S.COM_CD                          --항목구분
			            , 0                                 --전체실행예산
                        , p_WRK_ID                          --입력ID 
				        , SYSDATE()                         --입력일시
				        , p_WRK_IP);                        --입력IP

          -- 9대항목별 월별예산 TQHA_SAFECOST_BGTYM

        BEGIN
            FOR SAFE_TBGT IN (  -- 시작일자부터 종료일자까지의 해당월을 생성
								SELECT to_char(ADD_MONTHS(Sdate, LEVEL-1), 'yyyymm') AS RLV_YM
								  FROM (
									     SELECT TO_DATE (p_STR_DT, 'YYYYMMDD') AS sdate, TO_DATE (p_END_DT, 'YYYYMMDD') AS Edate
										   FROM DUAL  
									   )
								CONNECT BY LEVEL <=  months_between(Edate+1, Sdate) 								       )                         
            LOOP

                   --9대항목별 월별예산 TQHA_SAFECOST_BGTYM
					MERGE INTO TQHA_SAFECOST_BGTYM  T
					USING ( -- -- 공통코드에 등록된 안전관리비 항목
							    SELECT p_SIT_CD AS SIT_CD  -- p_SIT_CD                           -- 변수 (현장코드)
							           , COM_CD 
								  FROM TCOA_COMCODE
								 WHERE HRNK_CD = 'QS026'   -- 상위코드가 'QS026'
								   AND USE_YN = '1'        -- 사용여부
								ORDER BY COM_CD			
					       )  S
					   ON (T.SIT_CD = S.SIT_CD AND T.ITM_DIV = S.COM_CD AND T.RLV_YM = SAFE_TBGT.RLV_YM)
					WHEN MATCHED
						THEN UPDATE SET
					           T.BYM_EBGT_BGT  = 0                           -- 월별실행예산
					         , T.CHG_EBGT_BGT  = 0                           -- 변경실행예산			           
					         , T.UPD_ID        = p_WRK_ID                    --수정ID
							 , T.UPD_DTM       = SYSDATE()                   --수정일시
							 , T.UPD_IP        = p_WRK_IP                    --수정IP
					WHEN NOT MATCHED
						THEN INSERT ( SIT_CD                         --현장코드 
						            , ITM_DIV                        --항목구분
						            , RLV_YM                         --해당년월
						            , BYM_EBGT_BGT                   --월별실행예산
						            , CHG_EBGT_BGT                   --변경실행예산			            
						            , T.IPT_ID                       --입력ID 
								    , T.IPT_DTM                      --입력일시
								    , T.IPT_IP)                      --입력IP
						     VALUES ( S.SIT_CD                          --현장코드 
						            , S.COM_CD                          --항목구분
						            , SAFE_TBGT.RLV_YM                  --해당년월
						            , 0                                 --월별실행예산
						            , 0                                 --변경실행예산			            
                                    , p_WRK_ID                          --입력ID 
							        , SYSDATE()                         --입력일시
							        , p_WRK_IP);                        --입력IP  
						    ---------------------------------------------------------------------------------------------------------------------------------------------------
            END LOOP;

        END;


    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHA_SAFECOST_BGTYM_CHG_BGT_S
DROP PROCEDURE "PQHA_SAFECOST_BGTYM_CHG_BGT_S";
CREATE PROCEDURE "PQHA_SAFECOST_BGTYM_CHG_BGT_S" (
    p_WRK_TP            VARCHAR2 :='U'      -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID            VARCHAR2            -- 사용자 ID 
,   p_WRK_IP            VARCHAR2            -- 사용자 IP 
,   p_SIT_CD            VARCHAR2            -- 현장코드
,   p_ITM_DIV           VARCHAR2            -- 안전관리비 예산구분(QS026) 1 안전인건비 
,   p_RLV_YM            VARCHAR2            -- 해당년월
,   p_CHG_EBGT_BGT      NUMBER              -- 변경실행예산
)
IS 
    /**************************************************************************************************************************
      Purpose : 

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/02/12                                   최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_ITM_DIV IS NULL)  THEN
        ERR_MSG := '안전관리비 예산구분은 필수 입력사항 입니다.'; 
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_RLV_YM IS NULL)  THEN
        ERR_MSG := '년월은 필수 입력사항 입니다.'; 
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------
    -- 결재상태 체크
    SELECT MAX(T2.APRV_STATS)
         , MAX(T3.CD_NM )
      INTO v_APRV_STATS
         , v_APRV_STATS_NM
      FROM TQHA_SAFECOST_APRV   T1
      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
                                  AND T1.APRV_NO    = T2.APRV_NO
      LEFT JOIN TCOA_COMCODE    T3 ON T2.APRV_STATS = T3.COM_CD 
                                  AND T3.HRNK_CD    = 'QS031'
     WHERE T1.SIT_CD    = p_SIT_CD
       AND T1.APRV_DIV  = '2'       -- 월별실적.
       AND T1.APRV_YM   = p_RLV_YM
    ;

    IF v_APRV_STATS IN ('2', '4') THEN
        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------

    ----------------------------------------------------------------------------------------------------
    -- 안전관리비 월별예산 : 변경실행예산 저장 .
    IF (p_WRK_TP ='U') THEN

        MERGE INTO TQHA_SAFECOST_BGTYM
            USING DUAL
        ON (    SIT_CD  = p_SIT_CD 
            AND ITM_DIV = p_ITM_DIV 
            AND RLV_YM  = p_RLV_YM)
        WHEN MATCHED THEN
            UPDATE 
               SET CHG_EBGT_BGT = p_CHG_EBGT_BGT
                 , UPD_ID       = p_WRK_ID
                 , UPD_DTM      = SYSDATE
                 , UPD_IP       = p_WRK_IP
        WHEN NOT MATCHED THEN
            INSERT (SIT_CD, ITM_DIV, RLV_YM, IPT_ID, IPT_DTM, IPT_IP, UPD_ID, UPD_DTM, UPD_IP, CHG_EBGT_BGT)
            VALUES (p_SIT_CD, p_ITM_DIV, p_RLV_YM, p_WRK_ID, SYSDATE, p_WRK_IP, p_WRK_ID, SYSDATE, p_WRK_IP, p_CHG_EBGT_BGT)
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHA_SAFECOST_BGTYM_Q
DROP PROCEDURE "PQHA_SAFECOST_BGTYM_Q";
CREATE PROCEDURE "PQHA_SAFECOST_BGTYM_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'             -- FLAG(Q: 현장평가, Q1:본사평가)
,   p_SIT_CD            IN VARCHAR2
,   p_SEARCH_STR_YM     IN VARCHAR2
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [평가항목 조회] PROCEDRE (QSE > 안전관리 > 산업안전보건관리비 > 월별실적관리  )

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2023/12/05                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                                                                                                                                 -- 현장코드
             , (SELECT APRV_NO  FROM TQHA_SAFECOST_APRV WHERE SIT_CD = p_SIT_CD AND APRV_DIV = '2' AND APRV_YM = p_SEARCH_STR_YM)   AS APRV_NO          -- 추가
             , (SELECT ATFL_GRP FROM TQHA_SAFECOST_APRV WHERE SIT_CD = p_SIT_CD AND APRV_DIV = '2' AND APRV_YM = p_SEARCH_STR_YM)   AS ATFL_GRP         -- 추가
--             , (SELECT B.APRV_STATS
--                FROM TQHA_SAFECOST_APRV A,
--                     TQHA_APRV B
--                WHERE A.APRV_NO = B.APRV_NO
--                  AND A.SIT_CD = B.SIT_CD
--                  AND A.SIT_CD = p_SIT_CD
--                  AND A.APRV_DIV = '2'
--                  AND A.APRV_YM = p_SEARCH_STR_YM)                                                                                AS APRV_STATS       -- 결재상태 추가
             , Z.APRV_STATS
             , '▶ 결재상태 : ' || NVL(( SELECT CD_NM FROM TCOA_COMCODE WHERE HRNK_CD = 'QS031' AND COM_CD = Z.APRV_STATS ), '-')    AS APRV_STATS_NM    -- 결재상태명
             , A.ITM_DIV                                                                                                                                -- 항목구분 (공통코드 QS026)
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.ITM_DIV AND HRNK_CD = 'QS026')                                      AS ITM_DIV_NM
             , NVL(A.CHG_EBGT_BGT, 0)                                                                                               AS CHG_EBGT_BGT     -- 변경 실행예산
             , (NVL(C.C_USE_AMT, 0) + NVL(C1.C_USE_AMT, 0)) - (NVL(B.T_USE_AMT, 0) + NVL(B1.T_USE_AMT, 0))                          AS P_USE_AMT        -- 전월 사용금액 ( 당사 + 협력업체)
             , (NVL(B.T_USE_AMT, 0) + NVL(B1.T_USE_AMT, 0))                                                                         AS T_USE_AMT        -- 당월 사용금액 ( 당사 + 협력업체)
             , (NVL(C.C_USE_AMT, 0) + NVL(C1.C_USE_AMT, 0))                                                                         AS C_USE_AMT        -- 누계 사용금액 ( 당사 + 협력업체)
             , (NVL(A.CHG_EBGT_BGT, 0) - (NVL(C.C_USE_AMT, 0) + NVL(C1.C_USE_AMT, 0)))                                              AS REMAIN_ALL       -- 전체잔액
             , ROUND( ((NVL(C.C_USE_AMT, 0) + NVL(C1.C_USE_AMT, 0))) / DECODE(A.CHG_EBGT_BGT, 0, NULL, A.CHG_EBGT_BGT) * 100 * 100) / 100  AS USE_RATE  -- 사용율
             , RLV_YM
          FROM TQHA_SAFECOST_BGTYM A
             , (  -- 당사 당월 사용금액   
                  SELECT SIT_CD
                       , ITM_DIV
                       , NVL(SUM(USE_AMT), 0)     AS T_USE_AMT        -- 당월 사용금액
                    FROM TQHA_SAFECOST_ARSLT
                   WHERE SIT_CD                   = p_SIT_CD          -- 변수 (현장코드)
                     AND SUBSTR(RLV_YM, 1, 6)     = p_SEARCH_STR_YM   -- 변수 (년도)
                   GROUP BY SIT_CD, ITM_DIV
                   ORDER BY SIT_CD, ITM_DIV
               ) B
             , (  -- 업체 당월 사용금액
                  SELECT A.SIT_CD                                     -- 현장코드
                      , ITM_DIV                           
                      , NVL(SUM(USE_AMT), 0)      AS T_USE_AMT        -- 업체 당월 금액
                   FROM TQHA_SAFECOST_ARSLT_CO    A
                      , TQHA_SAFECOST_MMARSLT_CO  B
                  WHERE A.SIT_CD                  = p_SIT_CD          -- 변수 (현장코드)
                    AND SUBSTR(A.RLV_YM, 1, 6)    = p_SEARCH_STR_YM   -- 변수 (년도)
                    AND A.SIT_CD                  = B.SIT_CD(+)
                    AND A.CUST_CD                 = B.CUST_CD(+)
                    AND A.VNDR_SEQ                = B.VNDR_SEQ(+)
                    AND A.RLV_YM                  = B.RLV_YM(+)
                    AND B.SITE_APRV_YN            = '1'
                  GROUP BY A.SIT_CD, ITM_DIV
               ) B1
             , (  -- 당사 누계 사용금액
                  SELECT SIT_CD
                       , ITM_DIV
                       , NVL(SUM(USE_AMT), 0)     AS C_USE_AMT        -- 누계 사용금액
                    FROM TQHA_SAFECOST_ARSLT
                   WHERE SIT_CD = p_SIT_CD                            -- 변수 (현장코드)
                     AND SUBSTR(RLV_YM, 1, 6) <= p_SEARCH_STR_YM      -- 변수 (년도)
                   GROUP BY SIT_CD, ITM_DIV
                   ORDER BY SIT_CD, ITM_DIV
               ) C
             , (  -- 업체 누계 사용금액
                  SELECT A.SIT_CD                                     -- 현장코드
                      , ITM_DIV                                       --
                      , NVL(SUM(USE_AMT), 0)      AS C_USE_AMT        -- 업체 당월 금액
                   FROM TQHA_SAFECOST_ARSLT_CO    A
                      , TQHA_SAFECOST_MMARSLT_CO  B
                  WHERE A.SIT_CD                  = p_SIT_CD          -- 변수 (현장코드)
                    AND SUBSTR(A.RLV_YM, 1, 6)    <= p_SEARCH_STR_YM  -- 변수 (년도)
                    AND A.SIT_CD                  = B.SIT_CD(+)
                    AND A.CUST_CD                 = B.CUST_CD(+)
                    AND A.VNDR_SEQ                = B.VNDR_SEQ(+)
                    AND A.RLV_YM                  = B.RLV_YM(+)
                    AND B.SITE_APRV_YN            = '1'
                  GROUP BY A.SIT_CD, ITM_DIV
               ) C1
             , TQHA_SAFECOST_APRV X
             , TQHA_APRV          Z
         WHERE A.SIT_CD                 = p_SIT_CD              -- 변수 (현장코드)
           AND SUBSTR(A.RLV_YM, 1, 6)   = p_SEARCH_STR_YM -- 변수 (년월)
           AND A.SIT_CD                 = B.SIT_CD(+)
           AND A.SIT_CD                 = C.SIT_CD(+)
           AND A.SIT_CD                 = B1.SIT_CD(+)
           AND A.SIT_CD                 = C1.SIT_CD(+)
           AND A.ITM_DIV                = B.ITM_DIV(+)
           AND A.ITM_DIV                = C.ITM_DIV(+)
           AND A.ITM_DIV                = B1.ITM_DIV(+)
           AND A.ITM_DIV                = C1.ITM_DIV(+)
           AND A.SIT_CD                 = X.SIT_CD(+)
           AND SUBSTR(A.RLV_YM, 1, 6)   = X.APRV_YM(+)
           AND X.APRV_DIV(+)            = '2'
           AND X.SIT_CD                 = Z.SIT_CD(+)
           AND X.APRV_NO                = Z.APRV_NO(+)
         ORDER BY A.ITM_DIV
        ;

    --------------------------------------------------------------------------------
    -- get_SafeCostDuration
    ELSIF p_WRK_TP = 'Q2' THEN

        OPEN RTN_CURSOR FOR
        SELECT MIN(RLV_YM)  AS RLV_YM_MIN
             , MAX(RLV_YM)  AS RLV_YM_MAX
          FROM TQHA_SAFECOST_BGTYM
         WHERE SIT_CD   = p_SIT_CD
        ;

    --------------------------------------------------------------------------------
    -- 당사 당월 사용금액
    ELSIF p_WRK_TP = 'Q3' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD
		     , A.ITM_DIV
		     , CC.CD_NM AS ITM_DIV_NM
		
		     /* =========================
		        당사
		        ========================= */
		     , NVL(C.C_USE_AMT,0) - NVL(B.T_USE_AMT,0)             AS OWN_P_USE_AMT    -- 전월누계
		     , NVL(B.T_USE_AMT,0)                                  AS OWN_T_USE_AMT      -- 당월
		     , NVL(C.C_USE_AMT,0)                                  AS OWN_C_USE_AMT      -- 누계
		
		     /* =========================
		        협력사
		        ========================= */
		     , NVL(E.C_USE_AMT,0) - NVL(D.T_USE_AMT,0)             AS CO_P_USE_AMT     -- 전월누계
		     , NVL(D.T_USE_AMT,0)                                  AS CO_T_USE_AMT       -- 당월
		     , NVL(E.C_USE_AMT,0)                                  AS CO_C_USE_AMT       -- 누계
		
		FROM TQHA_SAFECOST_BGTYM A
		
		/* =========================
		   당사 당월
		   ========================= */
		LEFT JOIN (
		    SELECT SIT_CD
		         , ITM_DIV
		         , SUM(USE_AMT) AS T_USE_AMT
		      FROM TQHA_SAFECOST_ARSLT
		     WHERE SIT_CD = p_SIT_CD
		       AND SUBSTR(RLV_YM,1,6) = p_SEARCH_STR_YM
		     GROUP BY SIT_CD
		            , ITM_DIV
		) B
		ON A.SIT_CD = B.SIT_CD
		AND A.ITM_DIV = B.ITM_DIV
		
		/* =========================
		   당사 누계
		   ========================= */
		LEFT JOIN (
		    SELECT SIT_CD
		         , ITM_DIV
		         , SUM(USE_AMT) AS C_USE_AMT
		      FROM TQHA_SAFECOST_ARSLT
		     WHERE SIT_CD = p_SIT_CD
		       AND SUBSTR(RLV_YM,1,6) <= p_SEARCH_STR_YM
		     GROUP BY SIT_CD
		            , ITM_DIV
		) C
		ON A.SIT_CD = C.SIT_CD
		AND A.ITM_DIV = C.ITM_DIV
		
		/* =========================
		   협력사 당월
		   ========================= */
		LEFT JOIN (
		    SELECT SIT_CD
		         , ITM_DIV
		         , SUM(USE_AMT) AS T_USE_AMT
		      FROM TQHA_SAFECOST_ARSLT_CO
		     WHERE SIT_CD = p_SIT_CD
		       AND RLV_YM = p_SEARCH_STR_YM
		     GROUP BY SIT_CD
		            , ITM_DIV
		) D
		ON A.SIT_CD = D.SIT_CD
		AND A.ITM_DIV = D.ITM_DIV
		
		/* =========================
		   협력사 누계
		   ========================= */
		LEFT JOIN (
		    SELECT SIT_CD
		         , ITM_DIV
		         , SUM(USE_AMT) AS C_USE_AMT
		      FROM TQHA_SAFECOST_ARSLT_CO
		     WHERE SIT_CD = p_SIT_CD
		       AND RLV_YM <= p_SEARCH_STR_YM
		     GROUP BY SIT_CD
		            , ITM_DIV
		) E
		ON A.SIT_CD = E.SIT_CD
		AND A.ITM_DIV = E.ITM_DIV
		
		/* 항목명 */
		LEFT JOIN TCOA_COMCODE CC
		       ON CC.HRNK_CD = 'QS026'
		      AND CC.COM_CD  = A.ITM_DIV
		
		WHERE A.SIT_CD = p_SIT_CD
		  AND SUBSTR(A.RLV_YM,1,6) = p_SEARCH_STR_YM
		
		ORDER BY A.ITM_DIV;
        
        
        /*
        --  당사 월별 실적관리
        SELECT A.SIT_CD                                                                                         -- 현장코드
             , A.ITM_DIV                                                                                        -- 항목구분 (공통코드 QS026)
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.ITM_DIV AND HRNK_CD = 'QS026')  AS ITM_DIV_NM
             , NVL(B.T_USE_AMT, 0)                                                              AS T_USE_AMT    -- 당월 사용금액
             , NVL(C.C_USE_AMT, 0)                                                              AS C_USE_AMT    -- 누계 사용금액
          FROM TQHA_SAFECOST_BGTYM A
             , (-- 당월 사용금액
                SELECT SIT_CD                                       -- 현장코드
                     , ITM_DIV                                      -- 항목구분 (공통코드 QS026)
                     , NVL(SUM(USE_AMT), 0)     AS T_USE_AMT        -- 당월 사용금액
                  FROM TQHA_SAFECOST_ARSLT
                 WHERE SIT_CD                  = p_SIT_CD           -- 변수(현장코드)
                   -- AND ITM_DIV              = '02'               -- 변수(항목구분 공통코드 QS026)
                   AND SUBSTR(RLV_YM, 1, 6)    = p_SEARCH_STR_YM    -- 변수(년월)
                 GROUP BY SIT_CD, ITM_DIV
               ) B
             , (-- 누계 사용금액
                SELECT SIT_CD
                     , ITM_DIV
                     , NVL(SUM(USE_AMT), 0)     AS C_USE_AMT        -- 누계 사용금액
                  FROM TQHA_SAFECOST_ARSLT
                 WHERE SIT_CD                  = p_SIT_CD           -- 변수 (현장코드)
                   AND SUBSTR(RLV_YM, 1, 6)    <= p_SEARCH_STR_YM   -- 변수 (년도)
                 GROUP BY SIT_CD, ITM_DIV
                 ORDER BY SIT_CD, ITM_DIV
               ) C
         WHERE A.SIT_CD                 = p_SIT_CD              -- 변수 (현장코드)
           AND SUBSTR(A.RLV_YM, 1, 6)   = p_SEARCH_STR_YM       -- 변수 (년월)
           AND A.SIT_CD                 = B.SIT_CD(+)
           AND A.SIT_CD                 = C.SIT_CD(+)
           AND A.ITM_DIV                = B.ITM_DIV(+)
           AND A.ITM_DIV                = C.ITM_DIV(+)
         ORDER BY A.ITM_DIV
        ;
		*/
    --------------------------------------------------------------------------------
    -- 업체별 당월 사용금액
    ELSIF p_WRK_TP = 'Q4' THEN

        OPEN RTN_CURSOR FOR
        SELECT (SELECT CUST_NM FROM VQSZ_TRADE WHERE CUST_CD = A.CUST_CD)   AS CUST_NM      -- 업체명
             , A.SIT_CD                                                                     -- 현장코드
             , A.CUST_CD                                                                    -- 업체코드
             , (SELECT CUST_NM FROM VQSZ_TRADE WHERE CUST_CD = A.CUST_CD)   AS COP_VNDR_NM  -- 업체명
             , A.VNDR_SEQ                                                                   -- CUST_NM
             , A.RLV_YM                                                                     -- 년월
             , B.T_USE_AMT                                                                  -- 당월금액
             , C.C_USE_AMT                                                                  -- 누계금액
             , (C.C_USE_AMT - B.T_USE_AMT)   AS  P_USE_AMT                                    -- 전원누계금액
             , NVL(A.VNDR_APRV_YN, 0)                                       AS VNDR_APRV_YN -- 업체승인요청여부
             , A.VNDR_APRV_DT                                                               -- 업체승인일자
             , NVL(A.SITE_APRV_YN, 0)                                       AS SITE_APRV_YN -- 현장승인여부
             , A.SITE_APRV_DT                                                               -- 현장승인일자
          FROM TQHA_SAFECOST_MMARSLT_CO A
             , ( -- 당월 금액
                SELECT SIT_CD                                   -- 현장코드
                     , CUST_CD                                  -- 업체코드
                     , VNDR_SEQ                                 -- 업체순번
                     , RLV_YM                                   -- 해당년월
                     , NVL(SUM(USE_AMT), 0) AS T_USE_AMT        -- 당월 금액
                  FROM TQHA_SAFECOST_ARSLT_CO
                 WHERE SIT_CD      = p_SIT_CD                   -- 변수 (현장코드)
                   AND RLV_YM      = p_SEARCH_STR_YM            -- 변수 (해당년월)
                 GROUP BY SIT_CD, CUST_CD, VNDR_SEQ, RLV_YM
               ) B
             , ( -- 누계 금액
                SELECT SIT_CD                                   -- 현장코드
                     , CUST_CD                                  -- 업체코드
                     , VNDR_SEQ                                 -- 업체순번
                     , NVL(SUM(USE_AMT), 0) C_USE_AMT           -- 누계 금액
                  FROM TQHA_SAFECOST_ARSLT_CO
                 WHERE SIT_CD       = p_SIT_CD                  -- 변수 (현장코드)
                   AND RLV_YM       <= p_SEARCH_STR_YM          -- 변수 (해당년월)
                 GROUP BY SIT_CD, CUST_CD, VNDR_SEQ
               ) C
         WHERE A.SIT_CD     = p_SIT_CD          -- 변수 (현장코드)
           AND A.RLV_YM     = p_SEARCH_STR_YM   -- 변수 (해당년월)
           AND A.SIT_CD     = B.SIT_CD(+)
           AND A.SIT_CD     = C.SIT_CD(+)
           AND A.CUST_CD    = B.CUST_CD(+)
           AND A.CUST_CD    = C.CUST_CD(+)
           AND A.VNDR_SEQ   = B.VNDR_SEQ(+)
           AND A.VNDR_SEQ   = C.VNDR_SEQ(+)
        ;

    END IF;


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_SAFECOST_BGTYM_Q;
/

-- PQHA_SAFECOST_BGTYM_S
DROP PROCEDURE "PQHA_SAFECOST_BGTYM_S";
CREATE PROCEDURE "PQHA_SAFECOST_BGTYM_S" (
    p_WRK_TP                VARCHAR2 :='U'                                      -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE, B:배치성 일괄삭제)
,   p_WRK_ID                VARCHAR2                                            -- 사용자 ID
,   p_WRK_IP                VARCHAR2                                            -- 사용자 IP
,   p_SIT_CD                TQHA_SAFECOST_BGTYM.SIT_CD              %TYPE       -- 현장코드
,   p_ITM_DIV               TQHA_SAFECOST_BGTYM.ITM_DIV             %TYPE       -- 안전관리비 예산구분(QS026) 1 안전인건비
,   p_RLV_YM                TQHA_SAFECOST_BGTYM.RLV_YM              %TYPE       -- 해당년월
,   p_BYM_EBGT_BGT          TQHA_SAFECOST_BGTYM.BYM_EBGT_BGT        %TYPE       -- 월별실행예산
--, p_CHG_EBGT_BGT          TQHA_SAFECOST_BGTYM.CHG_EBGT_BGT        %TYPE       -- 변경실행예산(22/04/01 추가)
)
IS
    /**************************************************************************************************************************
      Purpose : 안전관리 월별 예산 저장

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2021/11/09 18:25:17                         최초생성
      2.0     2022/04/01 18:25:17                         변경 실해예산 추가(월별)
    **************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;


BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_ITM_DIV IS NULL AND p_WRK_TP <> 'B')  THEN
        ERR_MSG := '안전관리비 예산구분(QS026) 1 안전인건비 는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_RLV_YM IS NULL AND p_WRK_TP <> 'B')  THEN
        ERR_MSG := '해당년월는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN

        DELETE
          FROM TQHA_SAFECOST_BGTYM
         WHERE SIT_CD       = p_SIT_CD          -- 현장코드
           AND ITM_DIV      = p_ITM_DIV         -- 안전관리비 예산구분(QS026) 1 안전인건비
           AND RLV_YM       = p_RLV_YM          -- 해당년월
        ;

    ELSIF (p_WRK_TP ='U') THEN

        UPDATE TQHA_SAFECOST_BGTYM
           SET BYM_EBGT_BGT     = p_BYM_EBGT_BGT        -- 월별실행예산
             , UPD_ID           = p_WRK_ID              -- 수정ID
             , UPD_DTM          = SYSDATE()             -- 수정일시
             , UPD_IP           = p_WRK_IP              -- 수정IP
         WHERE SIT_CD           = p_SIT_CD              -- 현장코드
           AND ITM_DIV          = p_ITM_DIV             -- 안전관리비 예산구분(QS026) 1 안전인건비
           AND RLV_YM           = p_RLV_YM              -- 해당년월
        ;

    ELSIF (p_WRK_TP ='B') THEN

        DELETE
          FROM TQHA_SAFECOST_BGTYM
         WHERE SIT_CD = p_SIT_CD        -- 현장코드
        ;

    ELSE

        INSERT 
          INTO TQHA_SAFECOST_BGTYM
             ( SIT_CD               -- 현장코드
             , ITM_DIV              -- 안전관리비 예산구분(QS026) 1 안전인건비
             , RLV_YM               -- 해당년월
             , BYM_EBGT_BGT         -- 월별실행예산
--           , CHG_EBGT_BGT         --  변경실행예산(22/04/01 추가)
             , IPT_ID               -- 입력ID
             , IPT_DTM              -- 입력일시
             , IPT_IP               -- 입력IP
             , UPD_ID               -- 수정ID
             , UPD_DTM              -- 수정일시
             , UPD_IP               -- 수정IP
             )
        VALUES 
             ( p_SIT_CD             -- 현장코드
             , p_ITM_DIV            -- 안전관리비 예산구분(QS026) 1 안전인건비
             , p_RLV_YM             -- 해당년월
             , p_BYM_EBGT_BGT       -- 월별실행예산
--           , p_CHG_EBGT_BGT       -- 변경실행예산(22/04/01 추가)
             , p_WRK_ID             -- 입력ID
             , SYSDATE()            -- 입력일시
             , p_WRK_IP             -- 입력IP
             , p_WRK_ID             -- 수정ID
             , SYSDATE()            -- 수정일시
             , p_WRK_IP             -- 수정IP
             )
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END ;
/

-- PQHA_SAFECOST_BGT_S
DROP PROCEDURE "PQHA_SAFECOST_BGT_S";
CREATE PROCEDURE "PQHA_SAFECOST_BGT_S" (
    p_WRK_TP            VARCHAR2 :='U'                                  -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE, B:배치성 일괄삭제)
,   p_WRK_ID            VARCHAR2                                        -- 사용자 ID
,   p_WRK_IP            VARCHAR2                                        -- 사용자 IP
,   p_SIT_CD            TQHA_SAFECOST_BGT.SIT_CD            %TYPE       -- 현장코드
,   p_ITM_DIV           TQHA_SAFECOST_BGT.ITM_DIV           %TYPE       -- 안전관리비 예산구분(QS026) 1 안전인건비
,   p_BGT_ATFL_GRP      TQHA_SAFECOST_BGT.BGT_ATFL_GRP      %TYPE       -- 첨부파일 그룹
,   p_WHL_EBGT_BGT      TQHA_SAFECOST_BGT.WHL_EBGT_BGT      %TYPE       -- 전체실행예산
)
IS
    /**************************************************************************************************************************
      Purpose : 안전관리 전체 예산 저장

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2021/11/09 18:22:09                         최초생성

    **************************************************************************************************************************/



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_CNT_APRV  INTEGER := 0;   -- 결재 상태 체크
BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_ITM_DIV IS NULL AND p_WRK_TP <> 'B')  THEN
        ERR_MSG := '안전관리비 예산구분(QS026) 1 안전인건비 는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------

    --2023/12/05  전자결재 상태확인(미확정)
--        SELECT NVL(MAX(1),0) INTO v_CNT_APRV
--          FROM DUAL
--         WHERE EXISTS (SELECT 1
--                      FROM TQHA_SAFECOST_APRV A, TCOA_APPROVE B
--                     WHERE A.SIT_CD = p_SIT_CD         --현장코드
--                       AND A.APRV_DIV = '1'              --1: 예산, 2 월별실적
--                       AND A.APRV_NO = B.APRV_NO(+)
--                       AND B.APRV_STATS IN ('CO0101','CO0104')  -- 진행중, 완료
--                      );
--
--     IF v_CNT_APRV > 0   THEN
--         ERR_MSG := '전자결재가 상신되어 진행중이거나 완료되어 수정할 수 없습니다.';
--         RAISE USER_EXCEPTION;
--     END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN

        DELETE
          FROM TQHA_SAFECOST_BGT
         WHERE SIT_CD       = p_SIT_CD          -- 현장코드
           AND ITM_DIV      = p_ITM_DIV         -- 안전관리비 예산구분(QS026) 1 안전인건비
        ;

    ELSIF (p_WRK_TP ='U') THEN

        UPDATE TQHA_SAFECOST_BGT
           SET WHL_EBGT_BGT         = p_WHL_EBGT_BGT    --전체실행예산
             , BGT_ATFL_GRP         = p_BGT_ATFL_GRP    -- 첨부파일 그룹
             , UPD_ID               = p_WRK_ID          --수정ID
             , UPD_DTM              = SYSDATE()         --수정일시
             , UPD_IP               = p_WRK_IP          --수정IP
         WHERE SIT_CD               = p_SIT_CD          --현장코드
           AND ITM_DIV              = p_ITM_DIV         --안전관리비 예산구분(QS026) 1 안전인건비
        ;

    ELSIF (p_WRK_TP ='B') THEN

        DELETE
          FROM TQHA_SAFECOST_BGT
         WHERE SIT_CD = p_SIT_CD         --현장코드
        ;

    ELSIF p_WRK_TP = 'I' THEN

        INSERT 
          INTO TQHA_SAFECOST_BGT
             ( SIT_CD               -- 현장코드
             , ITM_DIV              -- 안전관리비 예산구분(QS026) 1 안전인건비
             , WHL_EBGT_BGT         -- 전체실행예산
             , BGT_ATFL_GRP         -- 첨부파일 그룹
             , IPT_ID               -- 입력ID
             , IPT_DTM              -- 입력일시
             , IPT_IP               -- 입력IP
             , UPD_ID               -- 수정ID
             , UPD_DTM              -- 수정일시
             , UPD_IP               -- 수정IP
             )
        VALUES 
             ( p_SIT_CD             -- 현장코드
             , p_ITM_DIV            -- 안전관리비 예산구분(QS026) 1 안전인건비
             , p_WHL_EBGT_BGT       -- 전체실행예산
             , p_BGT_ATFL_GRP       -- 첨부파일 그룹
             , p_WRK_ID             -- 입력ID
             , SYSDATE()            -- 입력일시
             , p_WRK_IP             -- 입력IP
             , p_WRK_ID             -- 수정ID
             , SYSDATE()            -- 수정일시
             , p_WRK_IP             -- 수정IP
             )
        ;

    ELSIF p_WRK_TP = 'ATFL' THEN

        UPDATE TQHA_SAFECOST_BGT
           SET BGT_ATFL_GRP = p_BGT_ATFL_GRP
             , UPD_ID       = p_WRK_ID
             , UPD_IP       = p_WRK_IP
             , UPD_DTM      = SYSDATE
         WHERE SIT_CD       = p_SIT_CD
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END ;
/

-- PQHA_SAFECOST_MMARSLT_CO_W
DROP PROCEDURE "PQHA_SAFECOST_MMARSLT_CO_W";
CREATE PROCEDURE "PQHA_SAFECOST_MMARSLT_CO_W" (
    p_WRK_TP            VARCHAR2 :='U'                                          -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID            VARCHAR2                                                -- 사용자 ID
,   p_WRK_IP            VARCHAR2                                                -- 사용자 IP
,   p_SIT_CD            TQHA_SAFECOST_MMARSLT_CO.SIT_CD         %TYPE           -- 현장코드
,   p_CUST_CD           TQHA_SAFECOST_MMARSLT_CO.CUST_CD        %TYPE           -- 협력업체코드
,   p_VNDR_SEQ          TQHA_SAFECOST_MMARSLT_CO.VNDR_SEQ       %TYPE           -- 업체순번
,   p_RLV_YM            TQHA_SAFECOST_MMARSLT_CO.RLV_YM         %TYPE           -- 해당년월
,   p_RSTOR_RSN         TQHA_SAFECOST_MMARSLT_CO.RSTOR_RSN      %TYPE           -- 반려사유
)
IS
    /**************************************************************************************************************************
      Purpose : 협력업체 월별 실적 (APRV) : 승인, (RSTOR) : 반려, (REQ) : 승인요청, (CNC) : 승인취소

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2024/07/20 13:09:15                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_VNDR_APRV_YN      VARCHAR2(1);        -- 업체 승인요청 1, 미요청 0
    v_SITE_APRV_YN      VARCHAR2(1);        -- 승인 1 , 반려 2
    v_APRV_YN           VARCHAR2(1);        -- 결재상신,결재완료 1, 그외 0

    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;
    IF (p_CUST_CD IS NULL)  THEN
        ERR_MSG := '거래처코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;
    IF (p_VNDR_SEQ IS NULL)  THEN
        ERR_MSG := '거래처순번는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;
    IF (p_RLV_YM IS NULL)  THEN
        ERR_MSG := '년월는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------
    -- 결재상태 체크
    SELECT MAX(T2.APRV_STATS)
         , MAX(T3.CD_NM )
      INTO v_APRV_STATS
         , v_APRV_STATS_NM
      FROM TQHA_SAFECOST_APRV   T1
      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
                                  AND T1.APRV_NO    = T2.APRV_NO
      LEFT JOIN TCOA_COMCODE    T3 ON T2.APRV_STATS = T3.COM_CD
                                  AND T3.HRNK_CD    = 'QS031'
     WHERE T1.SIT_CD    = p_SIT_CD
       AND T1.APRV_DIV  = '2'       -- 월별실적.
       AND T1.APRV_YM   = p_RLV_YM
    ;

    IF v_APRV_STATS IN ('2', '4') THEN
        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------
    -- 상태값 체크 -- VNDR_APRV_YN (업체 승인요청 1, 미요청 0) , SITE_APRV_YN ( 승인 1 , 반려 2)
    SELECT nvl(max(VNDR_APRV_YN),0)
         , nvl(max(SITE_APRV_YN),0)
      INTO v_VNDR_APRV_YN             -- 업체 승인요청 1, 미요청 0
         , v_SITE_APRV_YN             -- 승인 1 , 반려 2
      FROM TQHA_SAFECOST_MMARSLT_CO
     WHERE SIT_CD    = p_SIT_CD           --현장코드
       AND CUST_CD   = p_CUST_CD          --협력업체코드
       AND VNDR_SEQ  = p_VNDR_SEQ         --업체순번
       AND RLV_YM    = p_RLV_YM           --해당년월
    ;

    SELECT CASE WHEN NVL(MAX(B.APRV_STATS),'0') IN ('2','4') THEN 1
                ELSE 0
           END
      INTO v_APRV_YN
      FROM TQHA_SAFECOST_APRV   A
         , TQHA_APRV            B
     WHERE A.APRV_NO        = B.APRV_NO
       AND A.SIT_CD         = B.SIT_CD 
       AND A.SIT_CD         = p_SIT_CD
       AND A.APRV_DIV       = '2'
       AND A.APRV_YM        = p_RLV_YM
    ;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    --  승인
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='APRV') THEN

        UPDATE TQHA_SAFECOST_MMARSLT_CO
           SET SITE_APRV_YN     = '1'                               -- 승인 1, 반려 2
             -- 20240930 반려사유 추가
             , RSTOR_RSN        = NULL                              -- 반려사유
             ----------------
             , SITE_APRV_DT     = TO_CHAR(SYSDATE(), 'YYYYMMDD')    -- 현장승인일자
             , UPD_ID           = p_WRK_ID                          -- 수정ID
             , UPD_DTM          = SYSDATE                           -- 수정일시
             , UPD_IP           = p_WRK_IP                          -- 수정IP
         WHERE SIT_CD           = p_SIT_CD                          -- 현장코드
           AND CUST_CD          = p_CUST_CD                         -- 협력업체코드
           AND VNDR_SEQ         = p_VNDR_SEQ                        -- 업체순번
           AND RLV_YM           = p_RLV_YM                          -- 해당년월
        ;

    ---------------------------------------------------------------------------------------------------------------------------
    -- 반려
    ---------------------------------------------------------------------------------------------------------------------------
    ELSIF (p_WRK_TP ='RSTOR') THEN
    
	    DELETE 
	    FROM TQHA_SAFECOST_MMARSLT_CO
	    WHERE SIT_CD           = p_SIT_CD              -- 현장코드
          AND CUST_CD          = p_CUST_CD             -- 협력업체코드
          AND VNDR_SEQ         = p_VNDR_SEQ            -- 업체순번
          AND RLV_YM           = p_RLV_YM              -- 해당년월
        ;

    /*
        UPDATE TQHA_SAFECOST_MMARSLT_CO
           SET SITE_APRV_YN     = '2'                   -- 승인 1, 반려 2
             , VNDR_APRV_YN     = '0'                   -- 승인요청 1 미요청 0
             -- 20240930 반려사유 추가
             , RSTOR_RSN        = p_RSTOR_RSN           -- 반려사유
             ----------------
             , SITE_APRV_DT     = NULL                  -- 현장승인일자
             , UPD_ID           = p_WRK_ID              -- 수정ID
             , UPD_DTM          = SYSDATE               -- 수정일시
             , UPD_IP           = p_WRK_IP              -- 수정IP
         WHERE SIT_CD           = p_SIT_CD              -- 현장코드
           AND CUST_CD          = p_CUST_CD             -- 협력업체코드
           AND VNDR_SEQ         = p_VNDR_SEQ            -- 업체순번
           AND RLV_YM           = p_RLV_YM              -- 해당년월
        ;
	*/
    ---------------------------------------------------------------------------------------------------------------------------
    -- 승인요청(협력업체용)
    ---------------------------------------------------------------------------------------------------------------------------
    ELSIF (p_WRK_TP ='REQ') THEN

        IF(v_APRV_YN = '1') THEN
            ERR_MSG := '해당년월 ("' || p_RLV_YM || '")은 결재 완료되어 승인요청이 불가합니다.  ';
            RAISE USER_EXCEPTION;
        END IF;

        MERGE
          INTO TQHA_SAFECOST_MMARSLT_CO
        USING DUAL
        ON (    SIT_CD      = p_SIT_CD           -- 현장코드
            AND CUST_CD     = p_CUST_CD          -- 협력업체코드
            AND VNDR_SEQ    = p_VNDR_SEQ         -- 업체순번
            AND RLV_YM      = p_RLV_YM           -- 해당년월
           )
        WHEN MATCHED THEN
            UPDATE
               SET VNDR_APRV_YN         = '1'                               -- 승인요청 1, 미요청 0
                 -- 20240930 반려사유 추가
                 , RSTOR_RSN            = NULL                              -- 반려사유
                 ----------------
                 , VNDR_APRV_DT         = TO_CHAR(SYSDATE(), 'YYYYMMDD')    -- 업체승인요청일자
                 , UPD_ID               = p_WRK_ID                          -- 수정ID
                 , UPD_DTM              = SYSDATE                           -- 수정일시
                 , UPD_IP               = p_WRK_IP                          -- 수정IP
        WHEN NOT MATCHED THEN
            INSERT
                 ( SIT_CD                   -- 현장코드
                 , CUST_CD                  -- 협력업체코드
                 , VNDR_SEQ                 -- 업체순번
                 , RLV_YM                   -- 해당년월
                 -- 20240930 반려사유 추가
                 , RSTOR_RSN                -- 반려사유
                   ----------------
                 , VNDR_APRV_YN             -- 승인요청 1, 미요청 0
                 , IPT_ID                   -- 수정ID
                 , IPT_DTM                  -- 수정일시
                 , IPT_IP                   -- 수정IP
                 , VNDR_APRV_DT             -- 업체승인요청일자
                 )
            VALUES
                 ( p_SIT_CD                 -- 현장코드
                 , p_CUST_CD                -- 협력업체코드
                 , p_VNDR_SEQ               -- 업체순번
                 , p_RLV_YM                 -- 해당년월
                 -- 20240930 반려사유 추가
                 , p_RSTOR_RSN              -- 반려사유
                   ----------------
                 , '1'                      -- 승인요청 1, 미요청 0
                 , p_WRK_ID                 -- 수정ID
                 , SYSDATE                  -- 수정일시
                 , p_WRK_IP                 -- 수정IP
                 , TO_CHAR(SYSDATE(), 'YYYYMMDD')    --업체승인요청일자
                 )
            ;

    ---------------------------------------------------------------------------------------------------------------------------
    -- 승인취소(협력업체용)
    ---------------------------------------------------------------------------------------------------------------------------
    ELSIF (p_WRK_TP ='CNC') THEN

        -- 20240921 추가 , 승인이 완료되었는데 승인취소 불가 체크
        IF ( v_SITE_APRV_YN = '1' OR  v_SITE_APRV_YN = '2' ) THEN
           ERR_MSG := '해당년월 ("' || p_RLV_YM || '")은 승인 OR 반려 처리가 완료되어 취소가 불가합니다.  ';
           RAISE USER_EXCEPTION;
        END IF;
        -----------------------------------------
		/*
        UPDATE TQHA_SAFECOST_MMARSLT_CO
           SET VNDR_APRV_YN         = '0'               -- 승인요청 1 미요청 0
             , VNDR_APRV_DT         = NULL              -- 업체승인요청일자
              -- 20240930 반려사유 추가
             , RSTOR_RSN            = NULL              -- 반려사유
             ----------------
             , UPD_ID               = p_WRK_ID          -- 수정ID
             , UPD_DTM              = SYSDATE           -- 수정일시
             , UPD_IP               = p_WRK_IP          -- 수정IP
         WHERE SIT_CD               = p_SIT_CD          -- 현장코드
           AND CUST_CD              = p_CUST_CD         -- 협력업체코드
           AND VNDR_SEQ             = p_VNDR_SEQ        -- 업체순번
           AND RLV_YM               = p_RLV_YM          -- 해당년월
        ;
		*/
        DELETE 
	    FROM TQHA_SAFECOST_MMARSLT_CO
	    WHERE SIT_CD           = p_SIT_CD              -- 현장코드
          AND CUST_CD          = p_CUST_CD             -- 협력업체코드
          AND VNDR_SEQ         = p_VNDR_SEQ            -- 업체순번
          AND RLV_YM           = p_RLV_YM              -- 해당년월
        ;
        
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_SAFECOST_MMARSLT_CO_W;
/

-- PQHA_SAFECOST_REG_CO_Q
DROP PROCEDURE "PQHA_SAFECOST_REG_CO_Q";
CREATE PROCEDURE "PQHA_SAFECOST_REG_CO_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'             -- FLAG(Q: 현장평가, Q1:본사평가)
,   p_SIT_CD            IN VARCHAR2
,   p_CUST_CD           IN VARCHAR2
,   p_VNDR_SEQ          IN VARCHAR2
,   p_RLV_YM            IN VARCHAR2
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [평가항목 조회] PROCEDRE (QSE > 안전관리 > 산업안전보건관리비 > 업체별 현황  )

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2023/12/05                                 최초생성

    **************************************************************************************************************************/
 
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
        SELECT (SELECT CUST_NM FROM VQSZ_TRADE WHERE CUST_CD = A.CUST_CD)       AS CUST_NM          -- 업체명
             , A.SIT_CD                                                                             -- 현장코드
             , A.CUST_CD                                                                            -- 업체코드
             , A.VNDR_SEQ                                                                           -- 업체순번
             , A.VNDR_NM                                                                            -- 공사명
             , E.SAFT_CONT_AMT     AS SAFT_AMT                                                      -- 외주 계약금액 중 안전관리비 금액
             , NVL(B.T_USE_AMT, 0) AS T_USE_AMT                                                     -- 당월금액
             , NVL(C.C_USE_AMT, 0) AS C_USE_AMT                                                     -- 누계금액
             , D.VNDR_APRV_YN                                                                       -- 업체 승인요청 여부
             , D.SITE_APRV_YN                                                                       -- 업체 승인 여부
             , NVL(E.SAFT_CONT_AMT ,0) - NVL(C.C_USE_AMT, 0) AS REMAIN                              -- 잔여금액
             , DECODE(NVL(D.VNDR_APRV_YN, 0), '1', '승인요청', '승인 미요청')   AS VNDR_APRV_YN_NM  -- 요청상태
             , DECODE(NVL(D.SITE_APRV_YN, 0), '1', '승인',
                      DECODE(NVL(D.SITE_APRV_YN, 0), '2', '반려', '진행 중'))   AS SITE_APRV_YN_NM  -- 요청상태
             , D.RLV_YM                                                                             -- 해당년월
             , A.CONT_SUM_AMT                                                                       -- 계약긍맥
             , ATFL_GRP
             , D.RSTOR_RSN                                                      AS RSTOR_RSN_S      -- 반려사유
             , A.VNDR_PSN_CADDR                                                                     -- 담당자연락처
             , F.APRV_STATS
             , '▶ 사용실적 : ' || CASE WHEN D.SITE_APRV_YN = '1' THEN '승인'
                                    WHEN D.SITE_APRV_YN = '2' THEN '반려'
                                    ELSE CASE WHEN D.VNDR_APRV_YN = '1' THEN '승인요청'
                                              ELSE '승인 미요청'
                                         END
                               END
             || ' ▶ 결재상태 : ' || NVL(( SELECT CD_NM FROM TCOA_COMCODE WHERE HRNK_CD = 'QS031' AND COM_CD = F.APRV_STATS ), '-') AS STATS_NM -- 결재상태명
             , '▶ 사용실적 : ' || CASE WHEN D.SITE_APRV_YN = '1' THEN '승인'
                                    WHEN D.SITE_APRV_YN = '2' THEN '반려'
                                    ELSE CASE WHEN D.VNDR_APRV_YN = '1' THEN '승인요청'
                                              ELSE '승인 미요청'
                                         END
                               END                                              AS STATS_NM_CO      -- 결재상태명
          FROM TQHA_VNDR A
             , ( -- 당월 금액
                SELECT SIT_CD                            -- 현장코드
                     , CUST_CD                           -- 업체코드
                     , VNDR_SEQ                          -- 업체순번
                     , RLV_YM                            -- 해당년월
                     , NVL(SUM(USE_AMT), 0) AS T_USE_AMT -- 당월 금액
                  FROM TQHA_SAFECOST_ARSLT_CO
                 WHERE SIT_CD       = p_SIT_CD          --현장코드
                   AND CUST_CD      = p_CUST_CD         --업체코드
                   AND VNDR_SEQ     = p_VNDR_SEQ        --업체순번
                   AND RLV_YM       = p_RLV_YM          --해당년월
                 GROUP BY SIT_CD, CUST_CD, VNDR_SEQ, RLV_YM
               ) B
             , (-- 누계 금액
                SELECT SIT_CD                           -- 현장코드
                     , CUST_CD                          -- 업체코드
                     , VNDR_SEQ                         -- 업체순번
                     , NVL(SUM(USE_AMT), 0) C_USE_AMT   -- 누계 금액
                  FROM TQHA_SAFECOST_ARSLT_CO
                 WHERE SIT_CD       = p_SIT_CD          -- 현장코드
                   AND CUST_CD      = p_CUST_CD         -- 업체코드
                   AND VNDR_SEQ     = p_VNDR_SEQ        -- 업체순번
                   AND RLV_YM   <   = p_RLV_YM          -- 해당년월
                 GROUP BY SIT_CD, CUST_CD, VNDR_SEQ
               ) C
             , ( -- 협력업체 안전관리비 사용 승인요청/ 승인여부
                SELECT SIT_CD                                   -- 현장코드
                     , CUST_CD                                  -- 업체코드
                     , VNDR_SEQ                                 -- 업체순번
                     , RLV_YM                                   -- 년월
                     , NVL(VNDR_APRV_YN, 0) AS VNDR_APRV_YN     -- 업체승인요청여부
                     , VNDR_APRV_DT                             -- 업체승인일자
                     , NVL(SITE_APRV_YN, 0) AS SITE_APRV_YN     -- 현장승인여부
                     , SITE_APRV_DT                             -- 현장승인일자
                     , ATFL_GRP
                     , RSTOR_RSN                                -- 반려사유
                  FROM TQHA_SAFECOST_MMARSLT_CO
                 WHERE SIT_CD       = p_SIT_CD                  --현장코드
                   AND CUST_CD      = p_CUST_CD                 --업체코드
                   AND VNDR_SEQ     = p_VNDR_SEQ                --업체순번
                   AND RLV_YM       = p_RLV_YM                  --해당년월
               ) D
             , (-- 20240906 추가 업체 계약별 안전관리비 금액
                SELECT SIT_CD
                     , CONT_NO
                     , CUST_CD
                     , SAFT_CONT_AMT      -- 계약업체(안전관리비 금액)
                  FROM FCMZ_SAFT_DEFC_IF('SM',  p_SIT_CD )
               ) E
             , (
                SELECT A.SIT_CD, B.APRV_STATS
                  FROM TQHA_SAFECOST_APRV A
                     , TQHA_APRV B
                 WHERE A.APRV_NO        = B.APRV_NO
                   AND A.SIT_CD         = B.SIT_CD
                   AND A.SIT_CD         = p_SIT_CD
                   AND A.APRV_DIV       = '2'
                   AND A.APRV_YM        = p_RLV_YM
               ) F
         WHERE A.SIT_CD         = p_SIT_CD          --현장코드
           AND A.CUST_CD        = p_CUST_CD         --업체코드
           AND A.VNDR_SEQ       = p_VNDR_SEQ        --업체순번
           AND A.SIT_CD         = B.SIT_CD(+)
           AND A.SIT_CD         = C.SIT_CD(+)
           AND A.SIT_CD         = D.SIT_CD(+)
           AND A.SIT_CD         = E.SIT_CD(+)
           AND A.CUST_CD        = E.CUST_CD(+)
           AND A.ORD_NO         = E.CONT_NO(+)      -- 계약번호(발주번호)
           AND A.SIT_CD         = F.SIT_CD(+)
        ;

    END IF;


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_SAFECOST_REG_CO_Q;
/

-- PQHA_SAFE_COST_REQ_CO_Q
DROP PROCEDURE "PQHA_SAFE_COST_REQ_CO_Q";
CREATE PROCEDURE "PQHA_SAFE_COST_REQ_CO_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'             -- FLAG(Q: 현장평가, Q1:본사평가)
,   p_SIT_CD            IN VARCHAR2                         -- 현장코드
,   p_ITM_DIV           IN VARCHAR2                         -- 안전항목
,   p_RLV_YM            IN VARCHAR2                         -- 해당년월
,   p_CUST_CD           IN VARCHAR2                         -- 고객코드
,   p_VNDR_SEQ          IN VARCHAR2                         -- 업체순번
,   RTN_CURSOR       OUT SYS_REFCURSOR
)
IS

    /**************************************************************************************************************************
      Purpose : 산업안전보건관리비

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2026/03/03                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    -- 협력업체 매월 사용실적 조회 ( 1 안전보건관리자 입금 )
    IF p_ITM_DIV = '01' THEN

        OPEN RTN_CURSOR FOR
        SELECT SIT_CD      -- 현장코드
             , ITM_DIV      -- 항목구분 (공통코드 QS026)
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
             , RLV_YM       -- 해당년월
             , USE_SEQ      -- 사용순번
             , BLN_18       -- 소속
             , PNM_18       -- 성명
             , PRCR_DT_18   -- 선임일자
             , USE_AMT      -- 사용금액(지급금액)
             , USE_DT       -- 사용일자(지급일자)
             , USE_DTLS     -- 사용내역(지급내역)
             , RMKS         -- 비고
             , GRP_PHOTO_1  -- 첨부파일그룹1
             , PHOTO_DESC_1 -- 사진설명1
             , CUST_CD      -- 업체코드
             , VNDR_SEQ     -- 업체순번
             , DLV_VNDR     -- 납품업체
             , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
             , GRP_PHOTO_2  -- 첨부파일그룹2
             , PHOTO_DESC_2 -- 사진설명2
             , USE_QNT      -- 수량
             , USE_UPRC     -- 단가
          FROM TQHA_SAFECOST_ARSLT_CO
         WHERE SIT_CD       = p_SIT_CD        -- 변수(현장코드)
           AND ITM_DIV      = p_ITM_DIV       -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
           AND RLV_YM       = p_RLV_YM        -- 변수(년월)
           AND CUST_CD      = p_CUST_CD       -- 변수 (업체코드)
           AND VNDR_SEQ     = p_VNDR_SEQ      -- 변수 (업체순번)
         ORDER BY ITM_DIV, USE_DT
        ;

    --------------------------------------------------------------------------------
    -- 협력업체 매월 사용실적 조회 ( 2 안전시설비 )
    ELSIF p_ITM_DIV = '02' THEN

        OPEN RTN_CURSOR FOR
        SELECT SIT_CD       -- 현장코드
             , ITM_DIV      -- 항목구분 (공통코드 QS026)
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
             , RLV_YM       -- 해당년월
             , USE_SEQ      -- 사용순번
             , USE_DT       -- 사용일자
             , USE_UNT      -- 사용단위
             , USE_QNT      -- 사용수량
             , USE_UPRC     -- 사용단가 계(노무비단가 + 자재비단가)
             , USE_AMT      -- 사용금액
             , USE_DTLS     -- 사용내역(지급내역)
             , RMKS         -- 비고
             , GRP_PHOTO_1  -- 첨부파일그룹1
             , PHOTO_DESC_1 -- 사진설명1
             , CUST_CD      -- 업체코드
             , VNDR_SEQ     -- 업체순번
             , DLV_VNDR     -- 납품업체
             , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
             , GRP_PHOTO_2  -- 첨부파일그룹2
             , PHOTO_DESC_2 -- 사진설명2
          FROM TQHA_SAFECOST_ARSLT_CO
         WHERE SIT_CD       = p_SIT_CD     -- 변수(현장코드)
           AND ITM_DIV      = p_ITM_DIV    -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
           AND RLV_YM       = p_RLV_YM     -- 변수(년월)
           AND CUST_CD      = p_CUST_CD    -- 변수 (업체코드)
           AND VNDR_SEQ     = p_VNDR_SEQ   -- 변수 (업체순번)
         ORDER BY ITM_DIV, USE_DT
        ;

    --------------------------------------------------------------------------------
    -- 협력업체 매월 사용실적 조회 ( 3 보호구 )
    ELSIF p_ITM_DIV = '03' THEN

        OPEN RTN_CURSOR FOR
        SELECT SIT_CD      -- 현장코드
                 , ITM_DIV      -- 항목구분 (공통코드 QS026)
                 , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
                 , RLV_YM       -- 해당년월
                 , USE_SEQ      -- 사용순번
                 , PLN_UPRC_39  -- 계획단가
                 , PLN_QNT_39   -- 계획수량
                 , PLN_AMT_39   -- 계획금액
                 , USE_DT       -- 사용일자
                 , USE_UPRC     -- 사용단가
                 , USE_QNT      -- 사용수량
                 , USE_AMT      -- 사용금액
                 , USE_DTLS     -- 사용내역(지급내역)
                 , RMKS         -- 비고
                 , GRP_PHOTO_1  -- 첨부파일그룹1
                 , PHOTO_DESC_1 -- 사진설명1
                 , CUST_CD      -- 업체코드
                 , VNDR_SEQ     -- 업체순번
                 , DLV_VNDR     -- 납품업체
                 , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
                 , GRP_PHOTO_2  -- 첨부파일그룹2
                 , PHOTO_DESC_2 -- 사진설명2
            FROM TQHA_SAFECOST_ARSLT_CO
            WHERE SIT_CD   = p_SIT_CD      -- 변수(현장코드)
              AND ITM_DIV  = p_ITM_DIV     -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
              AND RLV_YM   = p_RLV_YM      -- 변수(년월)
              AND CUST_CD  = p_CUST_CD     -- 변수 (업체코드)
              AND VNDR_SEQ = p_VNDR_SEQ    -- 변수 (업체순번)
            ORDER BY ITM_DIV, USE_DT
        ;

    --------------------------------------------------------------------------------
    -- 협력업체 매월 사용실적 조회 ( 4 안전보건진단비 )
    ELSIF p_ITM_DIV = '04' THEN

        OPEN RTN_CURSOR FOR
        SELECT SIT_CD       -- 현장코드
             , ITM_DIV      -- 항목구분 (공통코드 QS026)
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
             , RLV_YM       -- 해당년월
             , USE_SEQ      -- 사용순번
             , DGS_ORG_4    -- 진단기관
             , USE_DT       -- 사용일자
             , USE_AMT      -- 사용금액(소요비용)
             , USE_DTLS     -- 사용내역(지급내역)
             , RMKS         -- 비고
             , GRP_PHOTO_1  -- 첨부파일그룹1
             , PHOTO_DESC_1 -- 사진설명1
             , CUST_CD      -- 업체코드
             , VNDR_SEQ     -- 업체순번
             , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
             , GRP_PHOTO_2  -- 첨부파일그룹2
             , PHOTO_DESC_2 -- 사진설명2
             , USE_UPRC     -- 사용단가
             , USE_QNT      -- 사용수량
          FROM TQHA_SAFECOST_ARSLT_CO
         WHERE SIT_CD       = p_SIT_CD    -- 변수(현장코드)
           AND ITM_DIV      = p_ITM_DIV   -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
           AND RLV_YM       = p_RLV_YM    -- 변수(년월)
           AND CUST_CD      = p_CUST_CD   -- 변수 (업체코드)
           AND VNDR_SEQ     = p_VNDR_SEQ  -- 변수 (업체순번)
         ORDER BY ITM_DIV, USE_DT
        ;

    --------------------------------------------------------------------------------
    -- 협력업체 매월 사용실적 조회 ( 5 안전보건교육비 )
    ELSIF p_ITM_DIV = '05' THEN

        OPEN RTN_CURSOR FOR
        SELECT SIT_CD      -- 현장코드
             , ITM_DIV      -- 항목구분 (공통코드 QS026)
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
             , RLV_YM       -- 해당년월
             , USE_SEQ      -- 사용순번
             , EDU_ATTL5    -- 교육과목
             , EDU_SPNC_5   -- 교육주관
             , USE_DT       -- 사용일자(교육일)
             , PRTC_PSNNO_56   -- 참가인원(숫자)
             , USE_AMT      -- 사용금액(소요경비)
             , RMKS         -- 비고
             , GRP_PHOTO_1  -- 첨부파일그룹1
             , PHOTO_DESC_1 -- 사진설명1
             , CUST_CD      -- 업체코드
             , VNDR_SEQ     -- 업체순번
             , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
             , GRP_PHOTO_2  -- 첨부파일그룹2
             , PHOTO_DESC_2 -- 사진설명2
             , USE_UPRC     -- 사용단가
             , USE_QNT      -- 사용수량
          FROM TQHA_SAFECOST_ARSLT_CO
         WHERE SIT_CD       = p_SIT_CD          -- 변수(현장코드)
           AND ITM_DIV      = p_ITM_DIV         -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
           AND RLV_YM       = p_RLV_YM          -- 변수(년월)
           AND CUST_CD      = p_CUST_CD         -- 변수 (업체코드)
           AND VNDR_SEQ     = p_VNDR_SEQ        -- 변수 (업체순번)
         ORDER BY ITM_DIV, USE_DT
        ;

    --------------------------------------------------------------------------------
    -- 협력업체 매월 사용실적 조회 ( 6 근로자 건강장해예방비 )
    ELSIF p_ITM_DIV = '06' THEN

        OPEN RTN_CURSOR FOR
        SELECT SIT_CD       -- 현장코드
             , ITM_DIV      -- 항목구분 (공통코드 QS026)
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
             , RLV_YM       -- 해당년월
             , USE_SEQ      -- 사용순번
             , USE_DT       -- 사용일자
             , DGS_HOSP6      -- 진단병원
             , PRTC_PSNNO_56  -- 참가인원
             , USE_AMT      -- 사용금액(소요경비)
             , RMKS         -- 비고
             , GRP_PHOTO_1  -- 첨부파일그룹1
             , PHOTO_DESC_1 -- 사진설명1
             , CUST_CD      -- 업체코드
             , VNDR_SEQ     -- 업체순번
             , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
             , GRP_PHOTO_2  -- 첨부파일그룹2
             , PHOTO_DESC_2 -- 사진설명2
             , USE_UPRC     -- 사용단가
             , USE_QNT      -- 사용수량
          FROM TQHA_SAFECOST_ARSLT_CO
         WHERE SIT_CD       = p_SIT_CD          -- 변수(현장코드)
           AND ITM_DIV      = p_ITM_DIV         -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
           AND RLV_YM       = p_RLV_YM          -- 변수(년월)
           AND CUST_CD      = p_CUST_CD         -- 변수 (업체코드)
           AND VNDR_SEQ     = p_VNDR_SEQ        -- 변수 (업체순번)
         ORDER BY ITM_DIV, USE_DT
        ;
    --------------------------------------------------------------------------------
    -- 협력업체 매월 사용실적 조회 (9 위험성평가 등에 따른 소요비용)
    ELSIF p_ITM_DIV = '09' THEN

        OPEN RTN_CURSOR FOR
        SELECT SIT_CD         -- 현장코드
             , ITM_DIV        -- 항목구분 (공통코드 QS026)
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = ITM_DIV AND HRNK_CD = 'QS026') AS ITM_DIV_NM
             , RLV_YM         -- 해당년월
             , USE_SEQ        -- 사용순번
             , USE_DT         -- 사용일자
             , DGS_HOSP6      -- 진단병원
             , PRTC_PSNNO_56  -- 참가인원
             , USE_AMT        -- 사용금액(소요경비)
             , RMKS           -- 비고
             , GRP_PHOTO_1    -- 첨부파일그룹1
             , PHOTO_DESC_1   -- 사진설명1
             , CUST_CD        -- 업체코드
             , VNDR_SEQ       -- 업체순번
             , CASE WHEN (SELECT COUNT(*) FROM TCOZ_ATFL WHERE ATFL_GRP = GRP_PHOTO_1 OR ATFL_GRP = GRP_PHOTO_2) > 0 THEN 'O' ELSE 'X' END AS ATFL_GRP_YN
             , GRP_PHOTO_2    -- 첨부파일그룹2
             , PHOTO_DESC_2   -- 사진설명2
             , USE_UPRC       -- 사용단가
             , USE_QNT        -- 사용수량
             , USE_DTLS       -- 품명/규격
             , ITM_9          -- 지급내역
             , DLV_VNDR       -- 거래납품업체
          FROM TQHA_SAFECOST_ARSLT_CO
         WHERE SIT_CD       = p_SIT_CD          -- 변수(현장코드)
           AND ITM_DIV      = p_ITM_DIV         -- 안전 9대항목  01 안전보건관리자 입금 02 안전시설비 03 보호구 04 안전보건진단비 05 안전보건 교육비 06 근조자 건강장해예방비  07기술지도비 08 본사점담조직  09 위험성평가에 다른 소모비용
           AND RLV_YM       = p_RLV_YM          -- 변수(년월)
           AND CUST_CD      = p_CUST_CD         -- 변수 (업체코드)
           AND VNDR_SEQ     = p_VNDR_SEQ        -- 변수 (업체순번)
         ORDER BY ITM_DIV, USE_DT
        ;

    END IF;


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_SAFE_COST_REQ_CO_Q ;
/

-- PQHA_SAFE_PERREQ_B1
DROP PROCEDURE "PQHA_SAFE_PERREQ_B1";
CREATE PROCEDURE "PQHA_SAFE_PERREQ_B1" ( -- 안전허가작업 승인
    p_WRK_TP                VARCHAR2 :='S'                                  -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE, S : 승인처리)
,   p_WRK_ID                VARCHAR2                                        -- 사용자 ID
,   p_WRK_IP                VARCHAR2                                        -- 사용자 IP
,   p_SIT_CD                TQHA_SAFE_PERREQ.SIT_CD             %TYPE       -- 현장코드
,   p_REQ_SEQ               TQHA_SAFE_PERREQ.REQ_SEQ            %TYPE       -- 요청순번
,   p_USR_ID                TQHA_SAFE_PERREQ.WRK_CHR_PSN        %TYPE       -- 사번
,   p_RTN_BTN               OUT VARCHAR2                                    -- 리턴값 (안전관리자, 현장소장 승인여부)
,   p_RTN_MNG_DIV           OUT VARCHAR2                                    -- 리턴값 (관리자/안전/소장)
)
IS
    /**************************************************************************************************************************
      Purpose : 안전허가작업 승인

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2022/1/4 12:48:42                         최초생성

    **************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_MGR_APRV      VARCHAR2(1) ;   -- 관리감독자 승인여부
    v_SAFT_APRV     VARCHAR2(1) ;   -- 안전감독자 승인여부
    v_SITE_APRV     VARCHAR2(1) ;   -- 현장소장 승인여부

    v_MGR_CNT       INTEGER;     -- 관리감독자 여부
    v_SAFT_CNT      INTEGER;     -- 안전관리자 여부
    v_SITE_CNT      INTEGER;     -- 현장소장 여부


    v_RTN_BTN VARCHAR2(1) := 'F' ;       -- 리턴 초기값 (관리감독자, 안전관리자, 현장소장)
    v_RTN_MNG_DIV VARCHAR2(10) := 'N' ;  -- 리턴 상태 초기값 ( 관리자 MGR : 관리자, SAFT : 안전관리자, SITE : 현장소장 )


BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
         -- 안전작업허가에서 승읜 할 데이터가 있는지 체크
        SELECT nvl(MNG_APRV_STATS,0)            -- 관리감독자 승인여부
             , nvl(SAFT_APRV_STATS,0)           -- 안전관리자 승인여부
             , nvl(SITE_APRV_STATS,0)           -- 현장소장 승인여부
          INTO v_MGR_APRV                       -- 관리감독자 승인여부
             , v_SAFT_APRV                      -- 안전관리자 승인여부
             , v_SITE_APRV                      -- 현장소장 승인여부
          FROM TQHA_SAFE_PERREQ
         WHERE SIT_CD       = p_SIT_CD          -- 변수 (현장코드)
           AND REQ_SEQ      = p_REQ_SEQ         -- 변수 (요청순번 )
        ;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP = 'S') THEN    -- 승인처리

        -- 관리자 승인 전 단계
        IF (v_MGR_APRV = '0') THEN

            -- 관리자가 승인 권한이 있는지 체크
            SELECT nvl(COUNT(MNG_SUPR),0)
              INTO v_MGR_CNT
              FROM TQHA_SAFE_PERREQ
             WHERE SIT_CD       = p_SIT_CD          -- 변수 (현장코드)
               AND REQ_SEQ      = p_REQ_SEQ         -- 변수 (요청순번 )
               AND MNG_SUPR     = p_USR_ID          -- 변수 (사번)
            ;

            -- 숭인권한이 있음
            IF v_MGR_CNT > 0 then
                v_RTN_BTN       := 'T';
                v_RTN_MNG_DIV   := 'MGR';
            END IF;

        END IF;

        -- 관리자 승인 후 단계
        IF (v_MGR_APRV = '1' AND v_SAFT_APRV = '0' ) THEN     -- 관리자 승인 후 AND 안전관리자 승인 전

            /*
            -- 안전관리자 승인 권한이 있는지 체크
            SELECT  nvl(COUNT(JB_CD),0)
              INTO v_SAFT_CNT
              FROM  ( -- 조직도에서 직무코드가 안전관리자인 경우
                     SELECT   DEPT_CD   -- 현장코드
                           , USR_ID    -- 사용자 id
                           , JB_CD     -- 직무코드
                      FROM TCOZ_USR_INFO
                     WHERE DEPT_CD = p_SIT_CD       -- 변수(현장코드)
                     AND  JB_CD IN ('B37E01','CM0135','CM0136','CM0137') ) A
             WHERE A.DEPT_CD = p_SIT_CD   -- 변수 (현장코드)
               AND A.USR_ID = p_USR_ID     -- 변수 (사용자id)
                  ;
            */

            -- 안전관리자 승인 권한이 있는지 체크
            SELECT  nvl(COUNT(JB_CD),0)
              INTO v_SAFT_CNT
              FROM (
                    -- 2026.01.20 주석처리
                    -- 조직도에서 직무코드가 안전관리자인 경우
                    --SELECT   DEPT_CD   -- 현장코드
                    --        , USR_ID    -- 사용자 id
                    --        , JB_CD     -- 직무코드
                    --  FROM TCOZ_USR_INFO
                    -- WHERE DEPT_CD = p_SIT_CD       -- 변수(현장코드)
                    --   AND  JB_CD IN ('B37E01','CM0135','CM0136','CM0137')
                    -- UNION   -- 2020/5/18 일 겸직정보 추가
                    -- SELECT DEPT_CD   -- 현장코드
                    --       , USR_ID    -- 사용자 id
                    --       , JB_CD     -- 직무코드
                    --   FROM TCOZ_SBJB_INFO
                    --  WHERE DEPT_CD = p_SIT_CD
                    --    AND JB_CD IN ('B37E01','CM0135','CM0136','CM0137')

                    SELECT SIT_CD    AS DEPT_CD
                         , EMPE_NO    AS USR_ID
                         , JB_CD      AS JB_CD
                      FROM TQHA_SITENAM
                     WHERE SIT_CD = p_SIT_CD
                       AND EMPE_NO = p_USR_ID
                       AND JB_CD IN ('QS07702')  -- 안전관리자, 안전총괄
                    ) A
             WHERE A.DEPT_CD    = p_SIT_CD      -- 변수 (현장코드)
               AND A.USR_ID     = p_USR_ID      -- 변수 (사용자id)
            ;

            -- 안전관리자가 승인 권한이 있는지 체크
            IF v_SAFT_CNT > 0 then
                v_RTN_BTN       := 'T';
                v_RTN_MNG_DIV   := 'SAFT';
            END IF;

        END IF;

        -- 안전관리자 승인 후 단계
        IF (v_MGR_APRV = '1' AND v_SAFT_APRV = '1') THEN

            -- 현장소장 승인 권한이 있는지 체크
            SELECT nvl(COUNT(JB_CD),0)
              INTO v_SITE_CNT
              FROM (
                    -- 2026.01.20 주석처리
                    -- 조직도에서 직무코드가 안전관리자인 경우
                    --                    SELECT   DEPT_CD   -- 현장코드
                    --                          , USR_ID    -- 사용자 id
                    --                          , JB_CD     -- 직무코드
                    --                     FROM TCOZ_USR_INFO
                    --                    WHERE DEPT_CD = p_SIT_CD   -- 변수(현장코드)
                    --                    AND  JB_CD IN ('B37F01')
                    SELECT SIT_CD       AS DEPT_CD
                         , EMPE_NO      AS USR_ID
                         , DTY_CD       AS JB_CD
                      FROM TQHA_SITENAM
                     WHERE SIT_CD = p_SIT_CD
                       AND DTY_CD IN ('B37F01')       -- 현장소장
                   ) A
             WHERE A.DEPT_CD    = p_SIT_CD      -- 변수 (현장코드)
               AND A.USR_ID     = p_USR_ID      -- 변수 (사용자id)
            ;

            -- 현장소장 승인 권한이 있는지 체크
            IF v_SITE_CNT > 0 then
                v_RTN_BTN       := 'T';
                v_RTN_MNG_DIV   := 'SITE';
            END IF;

        END IF;

       -- 현장소장 승인 후 단계
        IF (v_SITE_APRV <> '0' ) THEN
            v_RTN_BTN       := 'F';
            v_RTN_MNG_DIV   := 'N';
        END IF;

        p_RTN_BTN := v_RTN_BTN ;
        p_RTN_MNG_DIV := v_RTN_MNG_DIV ;

    END IF;


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_SAFE_PERREQ_B1;
/

-- PQHA_SITECURST_Q
DROP PROCEDURE "PQHA_SITECURST_Q";
CREATE PROCEDURE "PQHA_SITECURST_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'        -- FLAG
,   p_SAFT_TERR_CD      IN VARCHAR2                     -- 안전지역구분
,   p_PRGS_STATS        IN VARCHAR2                     -- 진행상태
,   p_SIT_CD            IN VARCHAR2                     -- 현장코드
,   RTN_CURSOR          OUT SYS_REFCURSOR 
)
IS
    /**************************************************************************************************************************
      Purpose : [현장기준정보 조회] PROCEDRE (QSE > 기준정보 > 현장기준정보  )

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      XXXX/XX/XX                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;
 
BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
        SELECT AAA.*
          FROM (
                SELECT FCOZ_GET_CD_NM(AA.PRGS_STATS, 'CMZ008')              AS PRGS_STATS_NM            --진행상태명
                     , AA.PRGS_STATS
                     , K.SIT_TERR                                           AS SAFT_TERR_CD
                     , (SELECT CD_NM
                          FROM TCOA_COMCODE
                         WHERE HRNK_CD  = 'QSZ05'
                           AND COM_CD   = K.SIT_TERR
                       )                                                    AS SAFT_TERR_NM             --지역구분(CO11)
                     , (SELECT SRT_SO
                          FROM TCOA_COMCODE
                         WHERE HRNK_CD  = 'QSZ05'
                           AND COM_CD   = K.SIT_TERR
                       )                                                    AS SRT_SO
                     , AA.MNG_DEPT_CD                                       AS MNG_DEPT_CD              --관리부서(CMZ003)
                     , E.CD_NM                                              AS MNG_DEPT_NM              --관리부서명
                     , AA.SIT_NM                                                                        --현장명
                     , AA.SIT_CD                                                                        --현장코드
                     , NVL(Z.OCO_UNTKSO_SUM_AMT,0)                          AS SKAT_AMT                 --최종당사계약합계금액(수주)
                     , CASE WHEN AA.CNST_STR_DT IS NULL OR AA.CNST_END_DT IS NULL THEN NULL
                            ELSE TO_CHAR(TO_DATE(AA.CNST_STR_DT, 'YYYYMMDD'), 'YYYY-MM-DD') || ' ~ ' || TO_CHAR(TO_DATE(AA.CNST_END_DT, 'YYYYMMDD'), 'YYYY-MM-DD')
                        END                                                 AS CNST_DT                  --공사기간
                     , H.CD_NM                                              AS CNST_NO_ROW_FRML_NM      --공사종류명
                     , TO_CHAR(CASE WHEN NVL(Z.TOT_UNTK_SPLCM_AMT,0) = 0
                                    THEN 0
                                    ELSE ROUND(NVL(Z.OCO_UNTK_SPLCM_AMT,0) * 1.0 /
                                         NVL(Z.TOT_UNTK_SPLCM_AMT,0) * 100, 2)
                               END, 'FM999,999,990.00')                     AS ERT                      --지분율(공사)
                     , DECODE(FQHA_GETLMYN_BY_SITECD(AA.SIT_CD),'Y','1','0') AS LM_YN
                  FROM TCMZ_SIT AA
                  LEFT JOIN TQHA_SAFT_SIT   K ON AA.SIT_CD  = K.SIT_CD
                  LEFT JOIN TCOA_COMCODE    E ON E.COM_CD   = AA.MNG_DEPT_CD
                                          AND E.HRNK_CD     = 'CMZ003'      --관리부서
                  LEFT JOIN TCOA_COMCODE    H ON H.COM_CD   = AA.CNST_KND
                                          AND H.HRNK_CD     = 'CMZ005'      --공사종류
                  LEFT JOIN TCMZ_SIT_CONT   Z ON Z.SIT_CD   = AA.SIT_CD
                 WHERE 1=1
                   AND (NVL(p_SAFT_TERR_CD, '-') = '-' OR K.SIT_TERR    = p_SAFT_TERR_CD)
                   AND (NVL(p_PRGS_STATS, '-')   = '-' OR AA.PRGS_STATS = p_PRGS_STATS)
               ) AAA
         ORDER
            BY AAA.SRT_SO
             , AAA.SAFT_TERR_NM
             , AAA.SIT_NM
        ;

    -------------------------------------------------------------------------------------------------------------------------
    -- 상세 화면의 폼 조회.
    ELSIF p_WRK_TP = 'Q2' THEN

        OPEN RTN_CURSOR FOR
        SELECT AA.SIT_CD                                                                                --현장코드
             , AA.PRGS_STATS                                                AS PRGS_STATS_CD            --진행상태코드
             , FQHA_GET_CDNM_BY_COMCD(AA.PRGS_STATS)              		    AS PRGS_STATS_NM            --진행상태명
             , H.CD_NM                                                      AS CNST_NO_ROW_FRML_NM      --공사종류명
             , TO_CHAR(CASE WHEN NVL(Z.TOT_UNTK_SPLCM_AMT,0) = 0
                            THEN 0
                            ELSE ROUND(NVL(Z.OCO_UNTK_SPLCM_AMT,0) * 1.0 /
                                 NVL(Z.TOT_UNTK_SPLCM_AMT,0) * 100, 2)
                       END, 'FM999,999,990.00')                             AS ERT                      --지분율(공사)
             , K.SAFT_ZP_CD                                                                             --안전우편번호
             , K.SAFT_ADDR_1                                                                            --안전주소1
             , K.SAFT_ADDR_2                                                                            --안전주소2
             , AA.CNST_TP                                                   AS CNST_TP_1                --공사유형1(SA110_7자리)
             , (SELECT CD_NM
                  FROM TCOA_COMCODE
                 WHERE HRNK_CD  = 'CMZ007'
                   AND COM_CD   = AA.CNST_TP
               )                                                            AS CNST_TP_1_NM
             , NVL(Z.OCO_UNTK_SPLSO_AMT,0)                                  AS OCO_SPLPRC_AMT           --최종당사계약공급가금액(수주))
             , NULL                                                         AS CNST_TEAM_CD             --시공팀코드
             , NULL                                                         AS CNST_TEAM_NM             --시공팀명
             , AA.MNG_DEPT_CD                                               AS MNG_DEPT_CD              --관리부서(CMZ003)
             , E.CD_NM                                                      AS MNG_DEPT_NM              --관리부서명
             , (SELECT LISTAGG(B.CUST_NM, ', ') WITHIN GROUP (ORDER BY B.CUST_NM) AS CUST_LIST
                  FROM TCMZ_SIT_CLIENT A
                       JOIN TCOA_TRADE   B ON B.CUST_CD = A.CUST_CD
                 WHERE A.SIT_CD = AA.SIT_CD
                   AND A.ORDPLC_DIV = '1010'    -- 발주처구분이 발주처
                 GROUP BY A.SIT_CD
               )                                                            AS ORDPLC_NM                --발주처명
             , K.SIT_TERR                                                   AS SAFT_TERR_CD             --안전지역코드
             , CASE WHEN AA.CNST_STR_DT IS NULL OR AA.CNST_END_DT IS NULL THEN NULL
                    ELSE REGEXP_REPLACE(AA.CNST_STR_DT, '([0-9]{4})([0-9]{2})([0-9]{2})', '\1-\2-\3')
                         || ' ~ ' || 
                         REGEXP_REPLACE(AA.CNST_END_DT, '([0-9]{4})([0-9]{2})([0-9]{2})', '\1-\2-\3')
                END                                                         AS CNST_DT                  --공사기간
             , CASE WHEN AA.SCNST_DT IS NULL OR AA.CCNST_DT IS NULL THEN NULL
                    --ELSE AA.SCNST_DT || ' ~ ' || AA.CCNST_DT
                    ELSE REGEXP_REPLACE(AA.SCNST_DT, '([0-9]{4})([0-9]{2})([0-9]{2})', '\1-\2-\3')
                         || ' ~ ' || 
                         REGEXP_REPLACE(AA.CCNST_DT, '([0-9]{4})([0-9]{2})([0-9]{2})', '\1-\2-\3')
                END                                                         AS RCNST_DT                 --착준공일자
             , AA.TEL_NO                                                                                --현장전화번호
             , C.SAFT_UNTK_AMT                                              AS SAFT_MNG_AMT             --도급안전관리비. 최종내역도급기준 산업안전관리비 금액
          FROM TCMZ_SIT AA
          LEFT JOIN TQHA_SAFT_SIT   K ON AA.SIT_CD  = K.SIT_CD
          LEFT JOIN TCOA_COMCODE    E ON E.COM_CD   = AA.MNG_DEPT_CD
                                     AND E.HRNK_CD  = 'CMZ003'      --관리부서
          LEFT JOIN TCOA_COMCODE    H ON H.COM_CD   = AA.CNST_KND
                                     AND H.HRNK_CD  = 'CMZ005'      --공사종류
          LEFT JOIN TCMZ_SIT_CONT   Z ON Z.SIT_CD   = AA.SIT_CD
          LEFT JOIN FCMZ_SAFT_DEFC_IF('SAFT', p_SIT_CD) C ON AA.SIT_CD = C.SIT_CD
         WHERE AA.SIT_CD = p_SIT_CD
        ;

    -------------------------------------------------------------------------------------------------------------------------
    -- 현장직원 목록 조회.
    ELSIF p_WRK_TP = 'Q3' THEN

        OPEN RTN_CURSOR FOR
        SELECT AA.SIT_CD
             , AA.EMPE_NO
             , AA.PNM
             , (
                SELECT JBPOS_NM FROM TCOZ_USR_INFO
                 WHERE 1=1
                   AND USR_ID = AA.EMPE_NO
               ) AS JIKGUB_NM
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = BB.JBPOS_CD AND HRNK_CD = 'HRZ0ED' AND USE_YN = '1') AS JBPOS_NM
             , AA.DTY_CD
             , AA.DTY_NM
             , AA.TEL_NO
             --, PKG_XX1.DEC_VARCHAR2_SEL(AA.CELPH , 10 , 'SSN' , 'TQSZ_SITENAM' ,'CELPH') AS CELPH
             --, PKG_XX1.DEC_VARCHAR2_SEL(AA.EMAIL , 10 , 'SSN' , 'TQSZ_SITENAM' ,'EMAIL') AS EMAIL
             , AA.CELPH
             , AA.EMAIL
             , AA.ATCH_EN
             , AA.USE_YN
             , AA.ATFL_GRP
             , '' AS ATFL_STS
             , BB.USR_KND
             , CASE WHEN BB.USR_KND = 'QS' THEN '외부'
                     ELSE ''
                END AS USR_KND_NM
             --, '/file/previewPhotoQS/'|| AA.EMPE_NO || '/s' AS SPICT_PATH     --  인장정보
             , ''                                               AS SPICT_PATH     --  인장정보
             --, (
             --    SELECT COUNT(1)
             --    FROM TQSB_RSKEVLNAM
             --    WHERE SIT_CD = AA.SIT_CD
             --     AND EMPE_NO = AA.EMPE_NO
             --  ) AS IS_ON_TQSB
             --, (
             --    SELECT COUNT(1)
             --    FROM TQSN_CK_DD
             --    WHERE SIT_CD = AA.SIT_CD
             --     AND ODAY_SAFT_CHR_PSN_EMPNO = AA.EMPE_NO
             --  ) AS IS_ON_TQSN_D
             --, (
             --    SELECT COUNT(1)
             --    FROM TQSN_CK_DD
             --    WHERE SIT_CD = AA.SIT_CD
             --     AND SAFT_HLCR_MGR_EMPNO = AA.EMPE_NO
             --  ) AS IS_ON_TQSN_S
          FROM TQHA_SITENAM AA
             , TCOZ_USR_INFO BB
         WHERE 1=1
           AND AA.SIT_CD    = BB.DEPT_CD (+)
           AND AA.EMPE_NO   = BB.USR_ID (+)
           AND AA.SIT_CD    = p_SIT_CD
         ORDER
            BY BB.USR_KND DESC, AA.PNM, AA.DTY_CD
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_SITECURST_Q;
/

-- PQHA_SITEMA_NAM_Q
DROP PROCEDURE "PQHA_SITEMA_NAM_Q";
CREATE PROCEDURE "PQHA_SITEMA_NAM_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'        -- FLAG
,   p_SIT_CD            IN VARCHAR2                     -- 현장코드
,   p_EMPE_NO           IN VARCHAR2                     -- 
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [현장직원 조회] PROCEDRE (QSE > 기준정보 > 현장기준정보  )

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      XXXX/XX/XX                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------
    -- 현장직원 목록 조회.
    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
        SELECT AA.SIT_CD
             , AA.EMPE_NO
             , AA.PNM
             , (
                SELECT JBPOS_NM FROM TCOZ_USR_INFO
                 WHERE 1=1
                   AND USR_ID = AA.EMPE_NO
               ) AS JBPOS_NM
             --, (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = BB.JBPOS_CD AND HRNK_CD = 'HRZ0ED' AND USE_YN = '1') AS JBPOS_NM
             , AA.DTY_CD
             , AA.DTY_NM
             , AA.TEL_NO
             --, PKG_XX1.DEC_VARCHAR2_SEL(AA.CELPH , 10 , 'SSN' , 'TQSZ_SITENAM' ,'CELPH') AS CELPH
             --, PKG_XX1.DEC_VARCHAR2_SEL(AA.EMAIL , 10 , 'SSN' , 'TQSZ_SITENAM' ,'EMAIL') AS EMAIL
             , AA.CELPH
             , AA.EMAIL
             , AA.ATCH_EN
             , AA.USE_YN
             , AA.ATFL_GRP
             , '' AS ATFL_STS
             , BB.USR_KND
             , CASE WHEN BB.USR_KND = 'QS' THEN '외부'
                     ELSE ''
                END AS USR_KND_NM
             --, '/file/previewPhotoQS/'|| AA.EMPE_NO || '/s' AS SPICT_PATH     --  인장정보
             , ''                                               AS SPICT_PATH     --  인장정보
             , NVL(CO_DIV_CD, '1') AS CO_DIV_CD            -- 회사구분코드
             , AA.WRK_STR_DT
             , AA.WRK_END_DT
             , AA.JB_CD
          FROM TQHA_SITENAM AA
             , TCOZ_USR_INFO BB
         WHERE 1=1
           AND AA.SIT_CD    = BB.DEPT_CD (+)
           AND AA.EMPE_NO   = BB.USR_ID (+)
           AND AA.SIT_CD    = p_SIT_CD
           AND AA.EMPE_NO   = p_EMPE_NO
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_SITEMA_NAM_Q;
/

-- PQHA_SITEMA_Q
DROP PROCEDURE "PQHA_SITEMA_Q";
CREATE PROCEDURE "PQHA_SITEMA_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'         -- FLAG
,   p_SIT_CD            IN VARCHAR2                     -- 현장코드
,   p_CHK_DIV           IN VARCHAR2                     -- 체크구분
,   p_CHK_DGR           IN VARCHAR2                     -- 체크일자
,   p_STR_DT            IN VARCHAR2                     -- 체크시작일자
,   p_END_DT            IN VARCHAR2                     -- 체크종료일자
,   RTN_CURSOR          OUT SYS_REFCURSOR 
)
IS
    /**************************************************************************************************************************
      Purpose : [조치결과등록 조회] PROCEDRE (QSE > 재해예방관리 > 조치결과등록 )

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      XXXX/XX/XX                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                 -- 현장코드
             , A.CHK_DT
             , A.CHK_DIV                -- 공통코드 : QSZ03
             , A.CHK_DGR                 -- 점검일자
             , A.ERR_SEQ                -- 지적순번
             , A.DIV_1                  -- 안전 > 공통코드 : QSM02, 환경 > 공통코드 : QSM03
             , A.DIV_2                  -- 안전 > 공통코드 : QSM02, 환경 > 공통코드 : QSM03
             , A.DIV_3                  -- 공통코드 : QSK03
             , (
                SELECT CD_NM
                  FROM TCOA_COMCODE
                 WHERE COM_CD = A.DIV_1
               ) AS DIV_1_NM 
             , (
                SELECT CD_NM
                  FROM TCOA_COMCODE
                 WHERE COM_CD = A.DIV_2
               ) AS DIV_2_NM
             , (
                SELECT CD_NM
                  FROM TCOA_COMCODE
                 WHERE COM_CD = A.DIV_3
               ) AS DIV_3_NM
             , A.CHK_ELMT               -- 지적부위
             , A.CHK_MATT               -- 지적사항
             , A.CSE                    -- 원인
             , A.CPLN_MA_SHM            -- 대책조치방안
             , A.INSP_EMPNO             -- 점검자
             , A.INSP_NM               -- 점검자성명
             , A.MA_DT                  -- 조치일자
             , A.MA_MATT                -- 조치사항
             , A.MA_PSN_EMPNO           -- 조치자/담당직원
             ,(SELECT USR_NM FROM TCOZ_USR_INFO WHERE EMPNO = A.MA_PSN_EMPNO) AS MA_PSN_NM
             --, A.MA_PSN_NM             -- 조치자성명
             , A.CUST_CD                -- 협력회사
             , A.CUST_NM                -- 거래처명
             , A.ATFL_GRP               -- 첨부문서
             , A.ATFL_GRP2              -- 조치전 사진
             , A.PHOTO_DESC_2           -- 조치전 사진내용
             , A.ATFL_GRP3              -- 조치후 사진
             , A.PHOTO_DESC_3           -- 조치후 사진내용
             , B.PRGS_STATS_CD2 AS PRGS_STATS_CD --전자결재상태
             , B.QUARTER
             , B.CLOSE_YN
	         , DECODE(B.CLOSE_YN,'1','마감','') AS CLOSE_YN_NM
          FROM TQHA_HOCHKRPT_ERR    A
             , TQHA_HOCHKRPT        B
         WHERE A.SIT_CD         = B.SIT_CD
           AND A.CHK_DIV        = B.CHK_DIV
           AND A.CHK_DGR        = B.CHK_DGR
           AND A.SIT_CD         = p_SIT_CD
           AND A.CHK_DIV        = p_CHK_DIV
           AND A.CHK_DGR        = p_CHK_DGR
         ORDER BY ERR_SEQ
        ;


    ------------------------------------------------------------------------------------------------
    ELSIF p_WRK_TP = 'Q2' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD
             , FQHA_GETDEPTNM_BY_DEPTCD(A.SIT_CD) AS SIT_NM
             , CHK_DIV
             , CHK_DT
             , CHK_DGR
             , MA_DT
             , SIT_OMGR_EMPNO
             ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.INSP_EMPNO ) AS INSP_NM   			  -- 점검자
		     ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SIT_OMGR_EMPNO ) AS SIT_OMGR_EMPNO_NM   -- 점검자
	         ,( SELECT USR_NM FROM TCOZ_USR_INFO WHERE USR_ID = A.SAFT_MGR )  AS SAFT_MGR_NM   		  -- 안전관리자명	
             , INSP_BLN
             , INSP_EMPNO
             , ORDPLC
             , CNST_STR_DD ||' ~ '|| CNST_END_DD AS    CNST_STR_DD
             , CNST_END_DD
             , CNST_AMT
             , PROCRT
             , CNST_SCAL
             , WRK_MATT
             , MBOT_PSNNO
             , ATFL_GRP
             , A.PRGS_STATS_CD2
             , (
                SELECT CD_NM
                  FROM TCOA_COMCODE
                 WHERE HRNK_CD = 'QS031'
                   AND COM_CD = C.APRV_STATS
               ) AS PRGS_STATS_CD2_NM
             , (
                   A.SIT_CD
                || CHK_DIV
                || CHK_DGR
               ) AS ROWKEY
             , APRV_NO2
             , A.QUARTER
             , A.CLOSE_YN
	         , DECODE(A.CLOSE_YN,'1','마감','') AS CLOSE_YN_NM
          FROM TQHA_HOCHKRPT A
             , TCOA_COMCODE B
             , TQHA_APRV    C
         WHERE A.SIT_CD     = NVL(p_SIT_CD, A.SIT_CD)
           AND A.CHK_DIV    = NVL(p_CHK_DIV, CHK_DIV)
           AND A.CHK_DIV    = B.COM_CD
           AND REPLACE(CHK_DT,'-','') BETWEEN REPLACE(NVL(p_STR_DT, CHK_DT),'-','')
                                          AND REPLACE(NVL(p_END_DT, CHK_DT),'-','')
           AND A.APRV_NO2   = C.APRV_NO(+)
           AND A.SIT_CD     = C.SIT_CD(+)
         ORDER BY CHK_DT DESC,SIT_CD ASC 
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_SITEMA_Q;
/

-- PQHA_SITENAM_Q
DROP PROCEDURE "PQHA_SITENAM_Q";
CREATE PROCEDURE "PQHA_SITENAM_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'        -- FLAG
,   p_SIT_CD            IN VARCHAR2                     -- 현장코드
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [현장직원 조회] PROCEDRE (QSE > 기준정보 > 현장기준정보  )

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      XXXX/XX/XX                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------
    -- 현장직원 목록 조회.
    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
        SELECT AA.SIT_CD
             , AA.EMPE_NO
             , AA.PNM
             , (
                SELECT JBPOS_NM FROM TCOZ_USR_INFO
                 WHERE 1=1
                   AND USR_ID = AA.EMPE_NO
               ) AS JBPOS_NM
             --, (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = BB.JBPOS_CD AND HRNK_CD = 'HRZ0ED' AND USE_YN = '1') AS JBPOS_NM
             , AA.DTY_CD
             , AA.DTY_NM
             , AA.TEL_NO
             --, PKG_XX1.DEC_VARCHAR2_SEL(AA.CELPH , 10 , 'SSN' , 'TQSZ_SITENAM' ,'CELPH') AS CELPH
             --, PKG_XX1.DEC_VARCHAR2_SEL(AA.EMAIL , 10 , 'SSN' , 'TQSZ_SITENAM' ,'EMAIL') AS EMAIL
             , AA.CELPH
             , AA.EMAIL
             , AA.ATCH_EN
             , AA.USE_YN
             , AA.ATFL_GRP
             , '' AS ATFL_STS
             , BB.USR_KND
             , CASE WHEN BB.USR_KND = 'QS' THEN '외부'
                     ELSE ''
                END AS USR_KND_NM
             --, '/file/previewPhotoQS/'|| AA.EMPE_NO || '/s' AS SPICT_PATH     --  인장정보
             , ''                                               AS SPICT_PATH     --  인장정보
             , NVL(CO_DIV_CD, '1') AS CO_DIV_CD            -- 회사구분코드
             , AA.WRK_STR_DT
             , AA.WRK_END_DT
             , AA.JB_CD
             ,(SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = AA.JB_CD AND HRNK_CD = 'QS077' AND USE_YN = '1') AS JB_NM
          FROM TQHA_SITENAM AA
             , TCOZ_USR_INFO BB
         WHERE 1=1
           AND AA.SIT_CD    = BB.DEPT_CD (+)
           AND AA.EMPE_NO   = BB.USR_ID (+)
           AND AA.SIT_CD    = p_SIT_CD
         ORDER
            BY AA.CO_DIV_CD, BB.USR_KND DESC, AA.PNM, AA.DTY_CD
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_SITENAM_Q;
/

-- PQHA_SITENAM_S
DROP PROCEDURE "PQHA_SITENAM_S";
CREATE PROCEDURE "PQHA_SITENAM_S" (
    p_WRK_TP        VARCHAR2 :='U'                      -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID        VARCHAR2                            -- 사용자 ID
,   p_WRK_IP        VARCHAR2                            -- 사용자 IP
,   p_SIT_CD        TQHA_SITENAM.SIT_CD     %TYPE       -- 현장코드
,   p_EMPE_NO       TQHA_SITENAM.EMPE_NO    %TYPE       -- 사원번호
,   p_PNM           TQHA_SITENAM.PNM        %TYPE       -- 성명
,   p_DTY_CD        TQHA_SITENAM.DTY_CD     %TYPE       -- 직책코드
,   p_DTY_NM        TQHA_SITENAM.DTY_NM     %TYPE       -- 직책명
,   p_TEL_NO        TQHA_SITENAM.TEL_NO     %TYPE       -- 전화번호
,   p_CELPH         VARCHAR2                            -- 핸드폰
,   p_EMAIL         VARCHAR2                            -- 이메일
,   p_WRK_STR_DT    TQHA_SITENAM.WRK_STR_DT %TYPE       -- 근무시작일자
,   p_WRK_END_DT    TQHA_SITENAM.WRK_END_DT %TYPE       -- 근무종료일자
,   p_USE_YN        TQHA_SITENAM.USE_YN     %TYPE       -- 사용여부
,   p_ATCH_EN       TQHA_SITENAM.ATCH_EN    %TYPE       -- 싸인유무
,   p_ATFL_GRP      TQHA_SITENAM.ATFL_GRP   %TYPE       -- 첨부파일그룹
,   p_CO_DIV_CD     VARCHAR2                            -- 회사구분코드
,   p_JB_CD         VARCHAR2                            -- 직무
)
IS
    /**************************************************************************************************************************
      Purpose :

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2019/04/15 13:26:30                         최초생성

    /**************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR(200);             -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    v_COUNT02           NUMBER :=0;              --  현장소장 인원수

    p_UPD_ID  VARCHAR2(30);
    p_UPD_DTM DATE;
    p_UPD_IP  VARCHAR2(30);
    p_IPT_ID  VARCHAR2(30);
    p_IPT_DTM DATE;
    p_IPT_IP  VARCHAR2(30);

BEGIN
    IF p_WRK_TP = 'I' THEN
        p_IPT_ID  := p_WRK_ID;
        p_IPT_DTM := SYSDATE();
        p_IPT_IP  := p_WRK_IP;
        p_UPD_ID  := p_WRK_ID;
        p_UPD_DTM := SYSDATE();
        p_UPD_IP  := p_WRK_IP;
    ELSE
        p_UPD_ID  := p_WRK_ID;
        p_UPD_DTM := SYSDATE();
        p_UPD_IP  := p_WRK_IP;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_EMPE_NO IS NULL)  THEN
        ERR_MSG := '사원번호는 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN

        DELETE
          FROM TQHA_SITENAM
         WHERE SIT_CD   = p_SIT_CD         --현장코드
           AND EMPE_NO  = p_EMPE_NO        --사원번호
        ;

    ---------------------------------------------------------------------------------------------------------
    ELSIF (p_WRK_TP ='U') THEN

        --현장소장 인원 확인
        IF (p_JB_CD ='QS07703') THEN
            SELECT COUNT(1)
           INTO v_COUNT02
           FROM TQHA_SITENAM
          WHERE 1=1
            AND SIT_CD  = p_SIT_CD
            AND JB_CD   = p_JB_CD
            AND EMPE_NO != p_EMPE_NO;

            IF (v_COUNT02 > 0) THEN
                ERR_MSG := '이미 현장소장이 존재합니다.';
                RAISE USER_EXCEPTION;
            END IF;
        END IF;

        UPDATE TQHA_SITENAM
           SET PNM                  = p_PNM                     --성명
              ,DTY_CD               = p_DTY_CD                  --직책코드
              ,DTY_NM               = p_DTY_NM                  --직책명
              ,TEL_NO               = p_TEL_NO                  --전화번호
              ,CELPH                = p_CELPH 
              -- (SELECT xx1.enc_varchar2_ins(p_CELPH, 10 , 'SSN','','' ) FROM DUAL)  --핸드폰
              ,EMAIL                = p_EMAIL --(SELECT xx1.enc_varchar2_ins(p_EMAIL, 10 , 'SSN','','' ) FROM DUAL)  --이메일
              ,WRK_STR_DT           = p_WRK_STR_DT              --근무시작일자
              ,WRK_END_DT           = p_WRK_END_DT              --근무종료일자
              ,USE_YN               = p_USE_YN                  --사용여부
              ,ATCH_EN              = p_ATCH_EN                 --싸인유무
              ,ATFL_GRP             = p_ATFL_GRP                --첨부파일그룹
              ,CO_DIV_CD            = p_CO_DIV_CD               --회사구분코드
              ,JB_CD                = p_JB_CD
              ,UPD_ID               = p_UPD_ID                  --최종수정ID
              ,UPD_DTM              = p_UPD_DTM                 --최종수정일시
              ,UPD_IP               = p_UPD_IP                  --최종수정IP
         WHERE SIT_CD               = p_SIT_CD                  --현장코드
           AND EMPE_NO              = p_EMPE_NO                 --사원번호
        ;

--        
--        UPDATE TCOZ_USR_INFO
--           SET USE_YN               = p_USE_YN                  --사용여부
--              ,JB_CD                = p_DTY_CD                  --직책코드
--              ,JB_NM                = p_DTY_NM                  --직책명
--              ,UPD_ID               = p_UPD_ID                  --최종수정ID
--              ,UPD_DTM              = p_UPD_DTM                 --최종수정일시
--              ,UPD_IP               = p_UPD_IP                  --최종수정IP
--         WHERE USR_ID               = p_EMPE_NO                 --사원번호
--        ;
--        
        
    ---------------------------------------------------------------------------------------------------------
    -- 첨부파일 저장
    ELSIF  (p_WRK_TP ='U2') THEN

        UPDATE TQHA_SITENAM
           SET ATFL_GRP     = p_ATFL_GRP        --첨부파일그룹
             , UPD_ID       = p_UPD_ID          --최종수정ID
             , UPD_DTM      = p_UPD_DTM         --최종수정일시
             , UPD_IP       = p_UPD_IP          --최종수정IP
         WHERE SIT_CD       = p_SIT_CD          --현장코드
           AND EMPE_NO      = p_EMPE_NO         --사원번호
        ;

    ---------------------------------------------------------------------------------------------------------
    ELSE
        INSERT 
          INTO TQHA_SITENAM
             ( SIT_CD                   --현장코드
             , EMPE_NO                  --사원번호
             , PNM                      --성명
             , DTY_CD                   --직책코드
             , DTY_NM                   --직책명
             , TEL_NO                   --전화번호
             , CELPH                    --핸드폰
             , EMAIL                    --이메일
             , WRK_STR_DT               --근무시작일자
             , WRK_END_DT               --근무종료일자
             , USE_YN                   --사용여부
             , ATCH_EN                  --싸인유무
             , ATFL_GRP                 --첨부파일그룹
             , CO_DIV_CD                --회사구분코드
             , JB_CD
             , IPT_ID                   --신규입력ID
             , IPT_DTM                  --신규입력일시
             , IPT_IP                   --신규입력IP
             , UPD_ID                   --최종수정ID
             , UPD_DTM                  --최종수정일시
             , UPD_IP)                  --최종수정IP
        VALUES 
             ( p_SIT_CD                 --현장코드
             , p_EMPE_NO                --사원번호
             , p_PNM                    --성명
             , p_DTY_CD                 --직책코드
             , p_DTY_NM                 --직책명
             , p_TEL_NO                 --전화번호
             , p_CELPH --(SELECT xx1.enc_varchar2_ins(p_CELPH, 10 , 'SSN','','' ) FROM DUAL)                 --핸드폰
--                    ,PKG_XX1.ENC_VARCHAR2_INS(p_CELPH , 10 , 'SSN' , 'TQHA_SITENAM' ,'CELPH')
             , p_EMAIL -- (SELECT xx1.enc_varchar2_ins(p_EMAIL, 10 , 'SSN','','' ) FROM DUAL)                 --이메일
--                    ,PKG_XX1.ENC_VARCHAR2_INS(p_EMAIL , 10 , 'SSN' , 'TQHA_SITENAM' ,'EMAIL')
             , p_WRK_STR_DT             --근무시작일자
             , p_WRK_END_DT             --근무종료일자
             , p_USE_YN                 --사용여부
             , p_ATCH_EN                --싸인유무
             , p_ATFL_GRP               --첨부파일그룹
             , p_CO_DIV_CD              --회사구분코드
             , p_JB_CD
             , p_IPT_ID                 --신규입력ID
             , p_IPT_DTM                --신규입력일시
             , p_IPT_IP                 --신규입력IP
             , p_UPD_ID                 --최종수정ID
             , p_UPD_DTM                --최종수정일시
             , p_UPD_IP)                --최종수정IP
        ;
--    
--	    UPDATE TCOZ_USR_INFO
--           SET USE_YN               = p_USE_YN                  --사용여부
--              ,JB_CD                = p_DTY_CD                  --직책코드
--              ,JB_NM                = p_DTY_NM                  --직책명
--              ,UPD_ID               = p_UPD_ID                  --최종수정ID
--              ,UPD_DTM              = p_UPD_DTM                 --최종수정일시
--              ,UPD_IP               = p_UPD_IP                  --최종수정IP
--         WHERE USR_ID               = p_EMPE_NO                 --사원번호
--        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END;
/

-- PQHA_VIEW_REQ_Q
DROP PROCEDURE "PQHA_VIEW_REQ_Q";
CREATE PROCEDURE "PQHA_VIEW_REQ_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'         -- FLAG
,   p_APL_SEQ           IN NUMBER                       -- 신청순번
,   p_APL_STATS         IN VARCHAR2                     -- 신청상태
,   p_REQ_NM            IN VARCHAR2                     -- 신청자
,   p_REQ_STR_DD        IN VARCHAR2                     -- 신청일
,   p_REQ_END_DD        IN VARCHAR2                     -- 신청일
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [자료실 열람] PROCEDRE 

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2026/02/19                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    -- 폼 조회 : 열람신청 내역 조회
    IF p_WRK_TP = 'Q1' THEN

        OPEN RTN_CURSOR FOR
        SELECT APL_SEQ
             , REQ_USR_ID
             , TO_CHAR(APL_DTM, 'YYYY-MM-DD')   AS APL_DTM
             , READ_STR_DD
             , READ_END_DD
             , APL_STATS
             , RSTOR_CTS
             , T2.USR_NM    AS REG_NM
             , T3.CD_NM     AS APL_STATS_NM
          FROM TQHA_VIEW_REQ        T1
               JOIN TCOZ_USR_INFO   T2 ON T1.REQ_USR_ID = T2.USR_ID
          LEFT JOIN TCOA_COMCODE    T3 ON T1.APL_STATS  = T3.COM_CD
                                      AND T3.HRNK_CD = 'QS061'
         WHERE APL_SEQ  = p_APL_SEQ
        ;

    ---------------------------------------------------------------------------------------
    -- 그리드 조회 : 열람신청 리스트 조회
    ELSIF p_WRK_TP = 'Q2' THEN

        OPEN RTN_CURSOR FOR
        SELECT APL_SEQ
             , REQ_USR_ID
             , TO_CHAR(APL_DTM, 'YYYYMMDD')   AS APL_DTM
             , READ_STR_DD
             , READ_END_DD
             , APL_STATS
             , RSTOR_CTS
             , T2.USR_NM        AS REQ_USR_NM
          FROM TQHA_VIEW_REQ        T1
               JOIN TCOZ_USR_INFO   T2 ON T1.REQ_USR_ID = T2.USR_ID
         WHERE (NVL(p_APL_STATS, '*') = '*'     OR T1.APL_STATS = p_APL_STATS)
           AND (NVL(p_REQ_NM, '*') = '*'        OR T1.REQ_USR_ID = p_REQ_NM)
           AND (NVL(p_REQ_NM, '*') = '*'        OR T2.USR_NM LIKE  '%' || p_REQ_NM || '%')
           AND (NVL(p_REQ_STR_DD, '*') = '*'    OR T1.APL_DTM >= TO_DATE(p_REQ_STR_DD, 'YYYYMMDD'))
           AND (NVL(p_REQ_END_DD, '*') = '*'    OR T1.APL_DTM <  TO_DATE(p_REQ_END_DD, 'YYYYMMDD') + 1)
         ORDER BY APL_DTM DESC
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_VIEW_REQ_Q;
/

-- PQHA_WEEK_WORK_LOG_Q
DROP PROCEDURE "PQHA_WEEK_WORK_LOG_Q";
CREATE PROCEDURE "PQHA_WEEK_WORK_LOG_Q" 
(
      p_WRK_TP  VARCHAR2 DEFAULT 'Q'                                                       -- FLAG( Q: SELECT )
     ,p_SIT_CD TQHA_WEEK_WORK_LOG.SIT_CD%TYPE                                              -- 현장코드
     ,p_RPTING_STR_DT TQHA_WEEK_WORK_LOG.RPTING_DT%TYPE                                    -- 보고시작일자
     ,p_RPTING_END_DT TQHA_WEEK_WORK_LOG.RPTING_DT%TYPE                                    -- 보고종료일자
     ,p_WEK_STR_DT TQHA_WEEK_WORK_LOG.WEK_STR_DT%TYPE                                    -- 주간시작일자
     ,p_WEK_END_DT TQHA_WEEK_WORK_LOG.WEK_END_DT%TYPE                                    -- 주간종료일자
     ,RTN_CURSOR OUT SYS_REFCURSOR
)
IS 
    /**************************************************************************************************************************
      Purpose : 
 
      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/05/13 15:30:36                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;


BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리
    ---------------------------------------------------------------------------------------------------------------------------

    OPEN RTN_CURSOR FOR
    SELECT  A.SIT_CD                 --현장코드
          --, ( SELECT SIT_NM FROM TCMZ_SIT WHERE SIT_CD = A.SIT_CD ) AS SIT_NM -- 현장명칭
		   ,( SELECT DEPT_NM FROM TCOZ_DEPT_INFO WHERE DEPT_CD = A.SIT_CD ) AS SIT_NM -- 현장명칭
           ,A.RPTING_DT                 --보고일자
           ,A.WEK_STR_DT                 --주간시작일자
           ,A.WEK_END_DT                 --주간종료일자
           ,A.SCNST_DT                 --착공일자
           ,A.CCNST_DT                 --준공일자
           ,A.TOT_PROCRT                 --총공정율
           ,A.TOT_DISS_CNT                 --총재해건수
           ,A.DEAD_CNT                 --사망건수
           ,A.INJ_CNT                 --부상건수
           ,A.MAIN_CTP_DTLS                 --주요공종내역
           ,A.APRP_SAFT_MCHR_AMT                 --계상안전관리비금액
           ,A.SAFT_MCHR_USE_AMT                 --안전관리비사용금액
           ,A.SAFT_MCHR_USE_RATE                 --안전관리비사용율
           ,A.PHOTO_GRP1                 --첨부파일그룹사진1
           ,A.PHOTO_DESC_1                 --사진설명1
           ,A.PHOTO_LOC_1                 --사진설명1
           ,A.PHOTO_GRP2                 --첨부파일그룹사진2
           ,A.PHOTO_DESC_2                 --사진설명2
           ,A.PHOTO_LOC_2                 --사진설명1
           ,A.PHOTO_GRP3                 --첨부파일그룹사진2
           ,A.PHOTO_DESC_3                 --사진설명2
           ,A.PHOTO_LOC_3                 --사진설명1
           ,A.PHOTO_GRP4                 --첨부파일그룹사진2
           ,A.PHOTO_DESC_4                 --사진설명2
           ,A.PHOTO_LOC_4                 --사진설명1
           ,A.PHOTO_GRP5                 --첨부파일그룹사진2
           ,A.PHOTO_DESC_5                 --사진설명2
           ,A.PHOTO_LOC_5                 --사진설명1
           ,A.PHOTO_GRP6                 --첨부파일그룹사진2
           ,A.PHOTO_DESC_6                 --사진설명2
           ,A.PHOTO_LOC_6                 --사진설명1
           ,A.ETC_MATT                 --기타사항
           ,A.GF_YN                 --갱폼설치여부
           ,A.GF_INST_CNT                 --갱폼설치개수
           ,A.GF_DMT_CNT                 --갱폼해체개수
           ,A.TCRN_INST_YN                 --타워크레인설치여부
           ,A.TCRN_INST_CNT                 --타워크레인설치개수
           ,A.TCRN_DMT_CNT                 --타워크레인해체개수
           ,A.HST_INST_YN                 --호이스트설치여부
           ,A.HST_INST_CNT                 --호이스트설치개수
           ,A.HST_DMT_CNT                 --호이스트해체개수
           ,A.ETC_INST_MATT
           ,A.APRV_NO                 --결재번호
           ,B.APRV_STATS  AS  APRV_STATS              --결재번호
           , NVL(( SELECT CD_NM FROM TCOA_COMCODE WHERE HRNK_CD = 'QS031' AND COM_CD = B.APRV_STATS ), '-') AS APRV_STATS_NM -- 결재상태명
      FROM TQHA_WEEK_WORK_LOG A
      LEFT JOIN TQHA_APRV B ON A.SIT_CD = B.SIT_CD
                            AND A.APRV_NO = B.APRV_NO
    WHERE A.SIT_CD = p_SIT_CD                     --현장코드
      AND (A.RPTING_DT BETWEEN NVL(p_RPTING_STR_DT, '19000101') AND NVL(p_RPTING_END_DT, '99991231'))
      OR (A.WEK_STR_DT >= NVL(p_WEK_STR_DT, '19000101') AND A.WEK_END_DT <= NVL(p_WEK_END_DT, '19000101'))
      
    ORDER BY A.SIT_CD, A.RPTING_DT DESC 
           ;


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHA_WEEK_WORK_LOG_REG_Q
DROP PROCEDURE "PQHA_WEEK_WORK_LOG_REG_Q";
CREATE PROCEDURE "PQHA_WEEK_WORK_LOG_REG_Q" 
(
      p_WRK_TP  VARCHAR2 DEFAULT 'Q'                                                       -- FLAG( Q: SELECT )
     ,p_SIT_CD TQHA_WEEK_WORK_LOG.SIT_CD%TYPE                                              -- 현장코드
     ,p_RPTING_DT TQHA_WEEK_WORK_LOG.RPTING_DT%TYPE                                    	   -- 보고시작일자
     ,RTN_CURSOR OUT SYS_REFCURSOR
)
IS 
    /**************************************************************************************************************************
      Purpose : 

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/05/13 15:30:36                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;


BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리
    ---------------------------------------------------------------------------------------------------------------------------

    OPEN RTN_CURSOR FOR
    SELECT  A.SIT_CD                 --현장코드
          , ( SELECT SIT_NM FROM TCMZ_SIT WHERE SIT_CD = A.SIT_CD ) AS SIT_NM -- 현장명칭
           ,A.RPTING_DT                 --보고일자
           ,A.WEK_STR_DT                 --주간시작일자
           ,A.WEK_END_DT                 --주간종료일자
           ,A.SCNST_DT                 --착공일자
           ,A.CCNST_DT                 --준공일자
           ,A.TOT_PROCRT                 --총공정율
           ,A.TOT_DISS_CNT                 --총재해건수
           ,A.DEAD_CNT                 --사망건수
           ,A.INJ_CNT                 --부상건수
           ,A.MAIN_CTP_DTLS                 --주요공종내역
           ,A.APRP_SAFT_MCHR_AMT                 --계상안전관리비금액
           ,A.SAFT_MCHR_USE_AMT                 --안전관리비사용금액
           ,A.SAFT_MCHR_USE_RATE                 --안전관리비사용율
           ,A.PHOTO_GRP1                 --첨부파일그룹사진1
           ,A.PHOTO_DESC_1                 --사진설명1
           ,A.PHOTO_LOC_1                 --사진설명1
           ,A.PHOTO_GRP2                 --첨부파일그룹사진2
           ,A.PHOTO_DESC_2                 --사진설명2
           ,A.PHOTO_LOC_2                 --사진설명1
           ,A.PHOTO_GRP3                 --첨부파일그룹사진2
           ,A.PHOTO_DESC_3                 --사진설명2
           ,A.PHOTO_LOC_3                 --사진설명1
           ,A.PHOTO_GRP4                 --첨부파일그룹사진2
           ,A.PHOTO_DESC_4                 --사진설명2
           ,A.PHOTO_LOC_4                 --사진설명1
           ,A.PHOTO_GRP5                 --첨부파일그룹사진2
           ,A.PHOTO_DESC_5                 --사진설명2
           ,A.PHOTO_LOC_5                 --사진설명1
           ,A.PHOTO_GRP6                 --첨부파일그룹사진2
           ,A.PHOTO_DESC_6                 --사진설명2
           ,A.PHOTO_LOC_6                 --사진설명1
           ,A.ETC_MATT                 --기타사항
           ,A.GF_YN                 --갱폼설치여부
           ,A.GF_INST_CNT                 --갱폼설치개수
           ,A.GF_DMT_CNT                 --갱폼해체개수
           ,A.TCRN_INST_YN                 --타워크레인설치여부
           ,A.TCRN_INST_CNT                 --타워크레인설치개수
           ,A.TCRN_DMT_CNT                 --타워크레인해체개수
           ,A.HST_INST_YN                 --호이스트설치여부
           ,A.HST_INST_CNT                 --호이스트설치개수
           ,A.HST_DMT_CNT                 --호이스트해체개수
           ,A.ETC_INST_MATT                
           ,A.APRV_NO                 --결재번호
           ,B.APRV_STATS  AS  APRV_STATS              --결재번호
           , '▶ 결재상태 : ' || NVL(( SELECT CD_NM FROM TCOA_COMCODE WHERE HRNK_CD = 'QS031' AND COM_CD = B.APRV_STATS ), '-') AS APRV_STATS_NM -- 결재상태명
      FROM TQHA_WEEK_WORK_LOG A
      LEFT JOIN TQHA_APRV B ON A.SIT_CD = B.SIT_CD
                            AND A.APRV_NO = B.APRV_NO
    WHERE A.SIT_CD = p_SIT_CD
      AND A.RPTING_DT = p_RPTING_DT;


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHA_YYTRGARSLTSEQ_Q
DROP PROCEDURE "PQHA_YYTRGARSLTSEQ_Q";
CREATE PROCEDURE "PQHA_YYTRGARSLTSEQ_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'                     -- FLAG
,   p_SIT_CD            IN TQHA_YYTRGARSLTSEQ.SIT_CD    %TYPE       -- 현장코드
,   p_EMPE_NO           IN VARCHAR2                                 --
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [안전보건목표/실적 차수 조회] PROCEDRE (QSE > 안전보건목표/실적 > 안전보건실적 )

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      XXXX/XX/XX                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------
    -- 실적차수 목록 조회.
    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
        SELECT AQ.SIT_CD                                    -- 현장코드
             , AQ.TRG_YY                                    -- 목표년도
             , AQ.TRG_DGR                                   -- 목표차수
             , AQ.ARSLT_DGR                                 -- 실적차수
             , AQ.STR_DT                                    -- 시작일자
             , AQ.END_DT                                    -- 종료일자
             , AQ.RMKS                                      -- 비고
             --, AQ.APRV_STATS                                -- 결재상태
             , C.APRV_STATS
             , (SELECT CD_NM
                  FROM TCOA_COMCODE
                 WHERE HRNK_CD = 'QS031'  --'QSZ14'
                   AND COM_CD = C.APRV_STATS
               ) AS APRV_STATS_NM
             , AQ.APRV_NO                   AS ELAP_SEQ     -- 결재번호
             , AQ.TRG_YY || '-'  || AQ.TRG_DGR AS TRG_YY_DGR
             , AQ.TRG_YY || '-'  || AQ.TRG_DGR ||  '-'  || AQ.ARSLT_DGR AS TRG_YY_ARSLT_DGR
             , (SELECT COUNT(1)
                  FROM TQHA_YYTRGARSLT
                 WHERE SIT_CD = AQ.SIT_CD
                   AND TRG_YY = AQ.TRG_YY
                   AND TRG_DGR = AQ.TRG_DGR
                   AND ARSLT_DGR =  AQ.ARSLT_DGR
               )                            AS DTLCOUNT
             --, (
             --   SELECT APRV_DIV
             --     FROM TQSZ_APRVRVW
             --    WHERE SIT_CD = AQ.SIT_CD
             --      AND ELAP_SEQ = AQ.APRV_NO
             --      AND EMPE_NO = {EMPE_NO}
             --  ) AS APRV_DIV
          FROM TQHA_YYTRGARSLTSEQ AQ
              ,TQHA_YYTRGPLNSEQ PQ
              ,TQHA_APRV        C
         WHERE AQ.SIT_CD    = p_SIT_CD
           AND AQ.TRG_YY    = PQ.TRG_YY
           AND AQ.SIT_CD    = PQ.SIT_CD
           AND AQ.TRG_DGR   = PQ.TRG_DGR
           AND AQ.SIT_CD    = C.SIT_CD(+)
           AND AQ.APRV_NO   = C.APRV_NO(+)
         ORDER BY AQ.TRG_YY DESC, AQ.TRG_DGR DESC, AQ.ARSLT_DGR DESC
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_YYTRGARSLTSEQ_Q;
/

-- PQHA_YYTRGARSLTSEQ_S
DROP PROCEDURE "PQHA_YYTRGARSLTSEQ_S";
CREATE PROCEDURE "PQHA_YYTRGARSLTSEQ_S" (
    p_WRK_TP            VARCHAR2 :='U'                                  -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID            VARCHAR2                                        -- 사용자 ID
,   p_WRK_IP            VARCHAR2                                        -- 사용자 IP
,   p_SIT_CD            TQHA_YYTRGARSLTSEQ.SIT_CD           %TYPE       -- 현장코드
,   p_TRG_YY            TQHA_YYTRGARSLTSEQ.TRG_YY           %TYPE       -- 목표년도
,   p_TRG_DGR           TQHA_YYTRGARSLTSEQ.TRG_DGR          %TYPE       -- 목표차수
,   p_ARSLT_DGR         TQHA_YYTRGARSLTSEQ.ARSLT_DGR        %TYPE       -- 실적차수
,   p_STR_DT            TQHA_YYTRGARSLTSEQ.STR_DT           %TYPE       -- 시작일자
,   p_END_DT            TQHA_YYTRGARSLTSEQ.END_DT           %TYPE       -- 종료일자
,   p_RMKS              TQHA_YYTRGARSLTSEQ.RMKS             %TYPE       -- 비고
,   p_APRV_STATS        TQHA_YYTRGARSLTSEQ.APRV_STATS       %TYPE       -- 결재상태
,   p_APRV_NO           TQHA_YYTRGARSLTSEQ.APRV_NO          %TYPE       -- 결재번호
)
IS
    /**************************************************************************************************************************
      Purpose :

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2019/04/23 10:08:09                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR(200);             -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    p_UPD_ID            VARCHAR2(30);
    p_UPD_DTM           DATE;
    p_UPD_IP            VARCHAR2(30);
    p_IPT_ID            VARCHAR2(30);
    p_IPT_DTM           DATE;
    p_IPT_IP            VARCHAR2(30);

    v_cnt               INTEGER;

    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);

BEGIN
    IF p_WRK_TP = 'I' THEN
        p_IPT_ID  := p_WRK_ID;
        p_IPT_DTM := SYSDATE();
        p_IPT_IP  := p_WRK_IP;
        p_UPD_ID  := p_WRK_ID;
        p_UPD_DTM := SYSDATE();
        p_UPD_IP  := p_WRK_IP;
    ELSE
        p_UPD_ID  := p_WRK_ID;
        p_UPD_DTM := SYSDATE();
        p_UPD_IP  := p_WRK_IP;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_TRG_YY IS NULL)  THEN
        ERR_MSG := '목표년도는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_TRG_DGR IS NULL)  THEN
        ERR_MSG := '목표차수는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;
    /*
    IF (p_ARSLT_DGR IS NULL)  THEN
        ERR_MSG := '실적차수는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;
    */

    ---------------------------------------------------------------------
    -- 결재상태 체크
    SELECT MAX(T2.APRV_STATS)
         , MAX(T3.CD_NM )
      INTO v_APRV_STATS
         , v_APRV_STATS_NM
      FROM TQHA_YYTRGARSLTSEQ   T1
      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
                                  AND T1.APRV_NO    = T2.APRV_NO
      LEFT JOIN TCOA_COMCODE    T3 ON T2.APRV_STATS = T3.COM_CD 
                                  AND T3.HRNK_CD    = 'QS031'
     WHERE T1.SIT_CD    = p_SIT_CD
       AND T1.TRG_YY    = p_TRG_YY
       AND T1.TRG_DGR   = p_TRG_DGR
       AND T1.ARSLT_DGR = p_ARSLT_DGR
    ;

    IF v_APRV_STATS IN ('2', '4') THEN
        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF p_WRK_TP ='I' THEN

        SELECT COUNT(A.TRG_DGR) INTO v_cnt
          FROM TQHA_YYTRGPLN A, TQHA_YYTRGPLNSEQ B
         WHERE B.SIT_CD         = p_SIT_CD
           AND B.TRG_DGR        = p_TRG_DGR
           AND B.TRG_YY         = p_TRG_YY
           AND A.SIT_CD         = B.SIT_CD
           AND A.TRG_DGR        = B.TRG_DGR
           AND A.TRG_YY         = B.TRG_YY
        ;

        IF (v_cnt = 0)  THEN
            ERR_MSG := '해당 차수에 대한 안전보건계획이 미등록 되어있습니다.';
            RAISE USER_EXCEPTION;
        END IF;

        SELECT COUNT(1)
          INTO v_cnt
          FROM TQHA_YYTRGARSLTSEQ B
         WHERE B.SIT_CD      = p_SIT_CD
           AND B.TRG_YY      = p_TRG_YY  
           AND B.TRG_DGR     = p_TRG_DGR
           AND B.ARSLT_DGR   = p_ARSLT_DGR
        ;

        IF (v_cnt > 0)  THEN
            ERR_MSG := '중복되는 차수입니다.';
            RAISE USER_EXCEPTION;
        END IF;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN

        DELETE
          FROM TQHA_YYTRGARSLTSEQ
         WHERE SIT_CD       = p_SIT_CD          -- 현장코드
           AND TRG_YY       = p_TRG_YY          -- 목표년도
           AND TRG_DGR      = p_TRG_DGR         -- 목표차수
           AND ARSLT_DGR    = p_ARSLT_DGR       -- 실적차수
        ;

        DELETE
          FROM TQHA_YYTRGARSLT
         WHERE SIT_CD       = p_SIT_CD
           AND TRG_YY       = p_TRG_YY
           AND TRG_DGR      = p_TRG_DGR
           AND ARSLT_DGR    = p_ARSLT_DGR
        ;

    -----------------------------------------------------------------
    ELSIF (p_WRK_TP ='U') THEN

        UPDATE TQHA_YYTRGARSLTSEQ
           SET STR_DT           = p_STR_DT          -- 시작일자
             , END_DT           = p_END_DT          -- 종료일자
             , RMKS             = p_RMKS            -- 비고
             -- ,APRV_STATS     = p_APRV_STATS      -- 결재상태
             , APRV_NO          = p_APRV_NO         -- 결재번호
             , UPD_ID           = p_UPD_ID          -- 최종수정ID
             , UPD_DTM          = p_UPD_DTM         -- 최종수정일시
             , UPD_IP           = p_UPD_IP          -- 최종수정IP
         WHERE SIT_CD           = p_SIT_CD          -- 현장코드
           AND TRG_YY           = p_TRG_YY          -- 목표년도
           AND TRG_DGR          = p_TRG_DGR         -- 목표차수
           AND ARSLT_DGR        = p_ARSLT_DGR       -- 실적차수
        ;

    ELSIF(p_WRK_TP ='I')  THEN

        INSERT 
          INTO TQHA_YYTRGARSLTSEQ
             ( SIT_CD           -- 현장코드
             , TRG_YY           -- 목표년도
             , TRG_DGR          -- 목표차수
             , ARSLT_DGR        -- 실적차수
             , STR_DT           -- 시작일자
             , END_DT           -- 종료일자
             , RMKS             -- 비고
             , APRV_STATS       -- 결재상태
             , APRV_NO          -- 결재번호
             , IPT_ID           -- 신규입력ID
             , IPT_DTM          -- 신규입력일시
             , IPT_IP           -- 신규입력IP
             , UPD_ID           -- 최종수정ID
             , UPD_DTM          -- 최종수정일시
             , UPD_IP           -- 최종수정IP
             )
        VALUES 
             ( p_SIT_CD         -- 현장코드
             , p_TRG_YY         -- 목표년도
             , p_TRG_DGR        -- 목표차수
             , p_ARSLT_DGR      -- 실적차수
             , p_STR_DT         -- 시작일자
             , p_END_DT         -- 종료일자
             , p_RMKS           -- 비고
             , ''               -- 결재상태        'QSZ1410'
             , p_APRV_NO        -- 결재번호
             , p_IPT_ID         -- 신규입력ID
             , p_IPT_DTM        -- 신규입력일시
             , p_IPT_IP         -- 신규입력IP
             , p_UPD_ID         -- 최종수정ID
             , p_UPD_DTM        -- 최종수정일시
             , p_UPD_IP         -- 최종수정IP
             )
        ;

        --  계획내역복사
        PQHA_YYTRGARSLTCHK_S(
              p_SIT_CD
            , p_TRG_YY
            , p_TRG_DGR
            , p_ARSLT_DGR
        );

    END IF;


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END;
/

-- PQHA_YYTRGARSLT_ATFL_S
DROP PROCEDURE "PQHA_YYTRGARSLT_ATFL_S";
CREATE PROCEDURE "PQHA_YYTRGARSLT_ATFL_S" (
    p_WRK_TP            VARCHAR2 :='U'                                  -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID            VARCHAR2                                        -- 사용자 ID
,   p_WRK_IP            VARCHAR2                                        -- 사용자 IP
,   p_SIT_CD            TQHA_YYTRGARSLT.SIT_CD              %TYPE       -- 현장코드
,   p_TRG_YY            TQHA_YYTRGARSLT.TRG_YY              %TYPE       -- 목표년도
,   p_TRG_DGR           TQHA_YYTRGARSLT.TRG_DGR             %TYPE       -- 목표차수
,   p_ARSLT_DGR         TQHA_YYTRGARSLT.ARSLT_DGR           %TYPE       -- 실적차수
,   p_DRV_ARSLT_SEQ     TQHA_YYTRGARSLT.DRV_ARSLT_SEQ       %TYPE       -- 추진실적순번
,   p_ATFL_GRP          TQHA_YYTRGARSLT.ATFL_GRP            %TYPE       -- 첨부파일그룹
)
IS
    /**************************************************************************************************************************
      Purpose :

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2019/04/22 13:37:11                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR(200);             -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    p_UPD_ID            VARCHAR2(30);
    p_UPD_DTM           DATE;
    p_UPD_IP            VARCHAR2(30);
    p_IPT_ID            VARCHAR2(30);
    p_IPT_DTM           DATE;
    p_IPT_IP            VARCHAR2(30);

    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);

BEGIN
    IF p_WRK_TP = 'I' THEN
        p_IPT_ID  := p_WRK_ID;
        p_IPT_DTM := SYSDATE();
        p_IPT_IP  := p_WRK_IP;
        p_UPD_ID  := p_WRK_ID;
        p_UPD_DTM := SYSDATE();
        p_UPD_IP  := p_WRK_IP;
    ELSE
        p_UPD_ID  := p_WRK_ID;
        p_UPD_DTM := SYSDATE();
        p_UPD_IP  := p_WRK_IP;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_TRG_YY IS NULL)  THEN
        ERR_MSG := '목표년도는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_TRG_DGR IS NULL)  THEN
        ERR_MSG := '목표차수는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_ARSLT_DGR IS NULL)  THEN
        ERR_MSG := '실적차수는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_DRV_ARSLT_SEQ IS NULL)  THEN
        ERR_MSG := '추진실적순번는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------
    -- 결재상태 체크
    SELECT MAX(T2.APRV_STATS)
         , MAX(T3.CD_NM )
      INTO v_APRV_STATS
         , v_APRV_STATS_NM
      FROM TQHA_YYTRGARSLTSEQ   T1
      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
                                  AND T1.APRV_NO    = T2.APRV_NO
      LEFT JOIN TCOA_COMCODE    T3 ON T2.APRV_STATS = T3.COM_CD 
                                  AND T3.HRNK_CD    = 'QS031'
     WHERE T1.SIT_CD    = p_SIT_CD
       AND T1.TRG_YY    = p_TRG_YY
       AND T1.TRG_DGR   = p_TRG_DGR
       AND T1.ARSLT_DGR = p_ARSLT_DGR
    ;

    IF v_APRV_STATS IN ('2', '4') THEN
        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
        UPDATE TQHA_YYTRGARSLT
           SET ATFL_GRP         = p_ATFL_GRP            --첨부파일그룹
             , UPD_ID           = p_UPD_ID              --최종수정ID
             , UPD_DTM          = p_UPD_DTM             --최종수정일시
             , UPD_IP           = p_UPD_IP              --최종수정IP
         WHERE SIT_CD           = p_SIT_CD              --현장코드
           AND TRG_YY           = p_TRG_YY              --목표년도
           AND TRG_DGR          = p_TRG_DGR             --목표차수
           AND ARSLT_DGR        = p_ARSLT_DGR           --실적차수
           AND DRV_ARSLT_SEQ    = p_DRV_ARSLT_SEQ       --추진실적순번
        ;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END;
/

-- PQHA_YYTRGARSLT_Q
DROP PROCEDURE "PQHA_YYTRGARSLT_Q";
CREATE PROCEDURE "PQHA_YYTRGARSLT_Q" ( 
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'                     -- FLAG
,   p_SIT_CD            IN TQHA_YYTRGARSLT.SIT_CD       %TYPE       -- 현장코드
,   p_TRG_YY            IN TQHA_YYTRGARSLT.TRG_YY       %TYPE       -- 목표년도
,   p_TRG_DGR           IN TQHA_YYTRGARSLT.TRG_DGR      %TYPE       -- 목표차수
,   p_ARSLT_DGR         IN TQHA_YYTRGARSLT.ARSLT_DGR    %TYPE       -- 실적차수
,   p_EMPE_NO           IN VARCHAR2                                 -- 
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS 
    /**************************************************************************************************************************
      Purpose : [안전보건목표/실적 조회] PROCEDRE (QSE > 안전보건목표/실적 > 안전보건실적 )

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      XXXX/XX/XX                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------
    -- 안전보건목표/실적 목록 조회.
    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
        SELECT YR.SIT_CD                -- 현장코드
             , YR.TRG_YY                -- 목표년도
             , YR.TRG_DGR               -- 목표차수
             , YR.ARSLT_DGR             -- 실적차수
             , YR.DRV_ARSLT_SEQ         -- 추진실적순번
             , YR.ARSLT_TRG             -- 실적목표치
             , YR.ARSLT_ACHV_RATE       -- 실적달성율
             , YR.ARSLT_FAIL_CSE        -- 실적미달성원인
             , YR.ARSLT_IMPRV_MATT      -- 실적개선사항
             , YR.ARSLT_RMKS            -- 실적비고
             , YR.ATFL_GRP              -- 첨부파일그룹
             , YT.DRV_TRG               -- 추진목표
             , YT.PRTCL_DRV_PLN         -- 세부추진계획
             , FQSE_GET_AFTL_CNT(YR.ATFL_GRP) AS AFTL_CNT
          FROM TQHA_YYTRGARSLT YR
              ,TQHA_YYTRGPLN YT
         WHERE YR.SIT_CD        = p_SIT_CD
           AND YR.TRG_YY        = p_TRG_YY
           AND YR.TRG_DGR       = p_TRG_DGR
           AND YR.ARSLT_DGR     = p_ARSLT_DGR
           AND YR.SIT_CD        = YT.SIT_CD
           AND YR.TRG_DGR       = YT.TRG_DGR
           AND YR.TRG_YY        = YT.TRG_YY
           AND YR.DRV_ARSLT_SEQ = YT.DRV_TRG_SEQ
         ORDER BY YR.DRV_ARSLT_SEQ
        ;

    -------------------------------------------------------------------------------------------------------------------------
    -- 안전보건목표/실적 폼  조회.
    ELSIF p_WRK_TP = 'Q2' THEN

        OPEN RTN_CURSOR FOR
        SELECT CC.SIT_CD
             , CC.SIT_NM
             , CC.TRG_YY
             , CC.TRG_DGR
             , CC.ARSLT_DGR
             , CC.STR_DT
             , CC.END_DT
             , CC.ELAP_SEQ
             , CC.APRV_STATS
             , CC.APRV_NO
             , '▶ 결재상태 : ' ||
               NVL((SELECT CD_NM 
                      FROM TCOA_COMCODE 
                     WHERE HRNK_CD = 'QS031'    -- 'QSZ14' 
                       AND COM_CD = CC.APRV_STATS
                   ), '-')                                        AS APRV_STATS_NM
             --, (
             --   SELECT APRV_DIV
             --     FROM TQSZ_APRVRVW
             --    WHERE SIT_CD = CC.SIT_CD
             --      AND ELAP_SEQ = CC.ELAP_SEQ
             --      AND EMPE_NO = {EMPE_NO}
             --  ) AS APRV_DIV
          FROM (SELECT MAX(YY_TRG_ARSLT)
                     , MAX(SIT_CD)  KEEP(DENSE_RANK FIRST ORDER BY YY_TRG_ARSLT DESC)       AS SIT_CD
                     , MAX(SIT_NM)  KEEP(DENSE_RANK FIRST ORDER BY YY_TRG_ARSLT DESC)       AS SIT_NM
                     , MAX(TRG_YY)  KEEP(DENSE_RANK FIRST ORDER BY YY_TRG_ARSLT DESC)       AS TRG_YY
                     , MAX(TRG_DGR) KEEP(DENSE_RANK FIRST ORDER BY YY_TRG_ARSLT DESC)       AS TRG_DGR
                     , MAX(ARSLT_DGR) KEEP(DENSE_RANK FIRST ORDER BY YY_TRG_ARSLT DESC)     AS ARSLT_DGR
                     , MAX(STR_DT)  KEEP(DENSE_RANK FIRST ORDER BY YY_TRG_ARSLT DESC)       AS STR_DT
                     , MAX(END_DT)  KEEP(DENSE_RANK FIRST ORDER BY YY_TRG_ARSLT DESC)       AS END_DT
                     , MAX(ELAP_SEQ)  KEEP(DENSE_RANK FIRST ORDER BY YY_TRG_ARSLT DESC)     AS ELAP_SEQ
                     , MAX(APRV_STATS)  KEEP(DENSE_RANK FIRST ORDER BY YY_TRG_ARSLT DESC)   AS APRV_STATS
                     , MAX(APRV_NO)  KEEP(DENSE_RANK FIRST ORDER BY YY_TRG_ARSLT DESC)     AS APRV_NO
                  FROM (SELECT A.SIT_CD                                                 AS SIT_CD
                             , FQHA_GETDEPTNM_BY_DEPTCD(A.SIT_CD)            		    AS SIT_NM
                             , A.TRG_YY                                                 AS TRG_YY
                             , A.TRG_DGR                                                AS TRG_DGR
                             , A.ARSLT_DGR                                              AS ARSLT_DGR
                             , A.STR_DT                                                 AS STR_DT
                             , A.END_DT                                                 AS END_DT
                             , NVL(A.APRV_NO, -1)                                       AS ELAP_SEQ
                             --, A.APRV_STATS                                             AS APRV_STATS
                             , C.APRV_STATS                                             AS APRV_STATS
                             , (A.TRG_YY || '/' || A.TRG_DGR || '/' || A.ARSLT_DGR)     AS YY_TRG_ARSLT
                             , NVL(A.APRV_NO, -1)                                       AS APRV_NO
                          FROM TQHA_YYTRGARSLTSEQ A 
                             , TQHA_YYTRGPLNSEQ     B
                             , TQHA_APRV            C
                         WHERE A.SIT_CD     = p_SIT_CD
                           AND A.SIT_CD     = B.SIT_CD
                           AND A.SIT_CD     = B.SIT_CD
                           AND A.TRG_YY     = B.TRG_YY
                           AND A.TRG_DGR    = B.TRG_DGR
                           AND A.SIT_CD     = C.SIT_CD(+)
                           AND A.APRV_NO    = C.APRV_NO(+)
                       )
               ) CC
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_YYTRGARSLT_Q;
/

-- PQHA_YYTRGARSLT_S
DROP PROCEDURE "PQHA_YYTRGARSLT_S";
CREATE PROCEDURE "PQHA_YYTRGARSLT_S" (
    p_WRK_TP                    VARCHAR2 :='U'                                      -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID                    VARCHAR2                                            -- 사용자 ID
,   p_WRK_IP                    VARCHAR2                                            -- 사용자 IP
,   p_SIT_CD                    TQHA_YYTRGARSLT.SIT_CD              %TYPE           -- 현장코드
,   p_TRG_YY                    TQHA_YYTRGARSLT.TRG_YY              %TYPE           -- 목표년도
,   p_TRG_DGR                   TQHA_YYTRGARSLT.TRG_DGR             %TYPE           -- 목표차수
,   p_ARSLT_DGR                 TQHA_YYTRGARSLT.ARSLT_DGR           %TYPE           -- 실적차수
,   p_DRV_ARSLT_SEQ             TQHA_YYTRGARSLT.DRV_ARSLT_SEQ       %TYPE           -- 추진실적순번
,   p_ARSLT_TRG                 TQHA_YYTRGARSLT.ARSLT_TRG           %TYPE           -- 실적목표치
,   p_ARSLT_ACHV_RATE           TQHA_YYTRGARSLT.ARSLT_ACHV_RATE     %TYPE           -- 실적달성율
,   p_ARSLT_FAIL_CSE            TQHA_YYTRGARSLT.ARSLT_FAIL_CSE      %TYPE           -- 실적미달성원인
,   p_ARSLT_IMPRV_MATT          TQHA_YYTRGARSLT.ARSLT_IMPRV_MATT    %TYPE           -- 실적개선사항
,   p_ARSLT_RMKS                TQHA_YYTRGARSLT.ARSLT_RMKS          %TYPE           -- 실적비고
,   p_ATFL_GRP                  TQHA_YYTRGARSLT.ATFL_GRP            %TYPE           -- 첨부파일그룹
)
IS
    /**************************************************************************************************************************
      Purpose :

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2019/04/22 13:37:11                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR(200);             -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    p_UPD_ID            VARCHAR2(30);
    p_UPD_DTM           DATE;
    p_UPD_IP            VARCHAR2(30);
    p_IPT_ID            VARCHAR2(30);
    p_IPT_DTM           DATE;
    p_IPT_IP            VARCHAR2(30);

    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);

BEGIN
    IF p_WRK_TP = 'I' THEN
        p_IPT_ID  := p_WRK_ID;
        p_IPT_DTM := SYSDATE();
        p_IPT_IP  := p_WRK_IP;
        p_UPD_ID  := p_WRK_ID;
        p_UPD_DTM := SYSDATE();
        p_UPD_IP  := p_WRK_IP;
    ELSE
        p_UPD_ID  := p_WRK_ID;
        p_UPD_DTM := SYSDATE();
        p_UPD_IP  := p_WRK_IP;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_TRG_YY IS NULL)  THEN
        ERR_MSG := '목표년도는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_TRG_DGR IS NULL)  THEN
        ERR_MSG := '목표차수는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_ARSLT_DGR IS NULL)  THEN
        ERR_MSG := '실적차수는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_DRV_ARSLT_SEQ IS NULL)  THEN
        ERR_MSG := '추진실적순번는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------
    -- 결재상태 체크
    SELECT MAX(T2.APRV_STATS)
         , MAX(T3.CD_NM )
      INTO v_APRV_STATS
         , v_APRV_STATS_NM
      FROM TQHA_YYTRGARSLTSEQ   T1
      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
                                  AND T1.APRV_NO    = T2.APRV_NO
      LEFT JOIN TCOA_COMCODE    T3 ON T2.APRV_STATS = T3.COM_CD 
                                  AND T3.HRNK_CD    = 'QS031'
     WHERE T1.SIT_CD    = p_SIT_CD
       AND T1.TRG_YY    = p_TRG_YY
       AND T1.TRG_DGR   = p_TRG_DGR
       AND T1.ARSLT_DGR = p_ARSLT_DGR
    ;

    IF v_APRV_STATS IN ('2', '4') THEN
        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='U') THEN
        UPDATE TQHA_YYTRGARSLT
           SET ARSLT_TRG            = p_ARSLT_TRG               --실적목표치
             , ARSLT_ACHV_RATE      = p_ARSLT_ACHV_RATE         --실적달성율
             , ARSLT_FAIL_CSE       = p_ARSLT_FAIL_CSE          --실적미달성원인
             , ARSLT_IMPRV_MATT     = p_ARSLT_IMPRV_MATT        --실적개선사항
             , ARSLT_RMKS           = p_ARSLT_RMKS              --실적비고
             -- ,ATFL_GRP           = p_ATFL_GRP                --첨부파일그룹
             , UPD_ID               = p_UPD_ID                  --최종수정ID
             , UPD_DTM              = p_UPD_DTM                 --최종수정일시
             , UPD_IP               = p_UPD_IP                  --최종수정IP
         WHERE SIT_CD               = p_SIT_CD                  --현장코드
           AND TRG_YY               = p_TRG_YY                  --목표년도
           AND TRG_DGR              = p_TRG_DGR                 --목표차수
           AND ARSLT_DGR            = p_ARSLT_DGR               --실적차수
           AND DRV_ARSLT_SEQ        = p_DRV_ARSLT_SEQ           --추진실적순번
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END;
/

-- PQHA_YYTRGPLNCHR_STF_S
DROP PROCEDURE "PQHA_YYTRGPLNCHR_STF_S";
CREATE PROCEDURE "PQHA_YYTRGPLNCHR_STF_S" (
    p_WRK_TP            VARCHAR2 :='U'                                  -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID            VARCHAR2                                        -- 사용자 ID
,   p_WRK_IP            VARCHAR2                                        -- 사용자 IP
,   p_ASSIGNED_YN       VARCHAR2                                        -- 선택여부
,   p_SIT_CD            TQHA_YYTRGPLNCHR.SIT_CD          %TYPE          -- 현장코드
,   p_TRG_YY            TQHA_YYTRGPLNCHR.TRG_YY          %TYPE          -- 목표년도
,   p_TRG_DGR           TQHA_YYTRGPLNCHR.TRG_DGR         %TYPE          -- 목표차수
,   p_DRV_TRG_SEQ       TQHA_YYTRGPLNCHR.DRV_TRG_SEQ     %TYPE          -- 추진목표순번
,   p_EMPE_NO           TQHA_YYTRGPLNCHR.EMPE_NO         %TYPE          -- 사원번호
,   p_PNM               TQHA_YYTRGPLNCHR.PNM             %TYPE          -- 성명
,   p_DTY               TQHA_YYTRGPLNCHR.DTY             %TYPE          -- 직책
,   p_SGN_YN            TQHA_YYTRGPLNCHR.SGN_YN          %TYPE          -- 서명여부
,   p_SGN_DT            TQHA_YYTRGPLNCHR.SGN_DT          %TYPE          -- 서명일자
)
IS
    /**************************************************************************************************************************
      Purpose :

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2019/04/18 14:10:43                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR(200);             -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    p_UPD_ID            VARCHAR2(30);
    p_UPD_DTM           DATE;
    p_UPD_IP            VARCHAR2(30);
    p_IPT_ID            VARCHAR2(30);
    p_IPT_DTM           DATE;
    p_IPT_IP            VARCHAR2(30);

    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);

BEGIN
    IF p_WRK_TP = 'I' THEN
        p_IPT_ID  := p_WRK_ID;
        p_IPT_DTM := SYSDATE();
        p_IPT_IP  := p_WRK_IP;
        p_UPD_ID  := p_WRK_ID;
        p_UPD_DTM := SYSDATE();
        p_UPD_IP  := p_WRK_IP;
    ELSE
        p_UPD_ID  := p_WRK_ID;
        p_UPD_DTM := SYSDATE();
        p_UPD_IP  := p_WRK_IP;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_TRG_YY IS NULL)  THEN
        ERR_MSG := '계획년도는 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_TRG_DGR IS NULL)  THEN
        ERR_MSG := '계획차수는 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_DRV_TRG_SEQ IS NULL)  THEN
        ERR_MSG := '추진목표순번은 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PNM IS NULL)  THEN
        ERR_MSG := '성명은 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------
    -- 결재상태 체크
    SELECT MAX(T2.APRV_STATS)
         , MAX(T3.CD_NM )
      INTO v_APRV_STATS
         , v_APRV_STATS_NM
      FROM TQHA_YYTRGPLNSEQ     T1
      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
                                  AND T1.APRV_NO    = T2.APRV_NO
      LEFT JOIN TCOA_COMCODE    T3 ON T2.APRV_STATS = T3.COM_CD 
                                  AND T3.HRNK_CD    = 'QS031'
     WHERE T1.SIT_CD    = p_SIT_CD
       AND T1.TRG_YY    = p_TRG_YY
       AND T1.TRG_DGR   = p_TRG_DGR
    ;

    IF v_APRV_STATS IN ('2', '4') THEN
        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
        RAISE USER_EXCEPTION;
    END IF;

--    IF (p_SGN_YN IS NULL)  THEN
--        ERR_MSG := '서명여부는 필수 입력사항 입니다.';
--        RAISE USER_EXCEPTION;
--    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_ASSIGNED_YN ='0') THEN

        DELETE
          FROM TQHA_YYTRGPLNCHR
         WHERE SIT_CD           = p_SIT_CD           -- 현장코드
           AND TRG_YY           = p_TRG_YY           -- 목표년도
           AND TRG_DGR          = p_TRG_DGR          -- 목표차수
           AND DRV_TRG_SEQ      = p_DRV_TRG_SEQ      -- 추진목표순번
           AND EMPE_NO          = p_EMPE_NO          -- 사번
        ;

    -----------------------------------------------------------------------------------
    ELSE

        INSERT 
          INTO TQHA_YYTRGPLNCHR
             ( SIT_CD               -- 현장코드
             , TRG_YY               -- 목표년도
             , TRG_DGR              -- 목표차수
             , DRV_TRG_SEQ          -- 추진목표순번
             , EMPE_NO              -- 사원번호
             , PNM                  -- 성명
             , DTY                  -- 직책
             , SGN_YN               -- 서명여부
             , SGN_DT               -- 서명일자
             , IPT_ID               -- 신규입력ID
             , IPT_DTM              -- 신규입력일시
             , IPT_IP               -- 신규입력IP
             , UPD_ID               -- 최종수정ID
             , UPD_DTM              -- 최종수정일시
             , UPD_IP               -- 최종수정IP
             )
        VALUES 
             ( p_SIT_CD             -- 현장코드
             , p_TRG_YY             -- 목표년도
             , p_TRG_DGR            -- 목표차수
             , p_DRV_TRG_SEQ        -- 추진목표순번
             , p_EMPE_NO            -- 사원번호
             , p_PNM                -- 성명
             , p_DTY                -- 직책
             , p_SGN_YN             -- 서명여부
             , p_SGN_DT             -- 서명일자
             , p_IPT_ID             -- 신규입력ID
             , p_IPT_DTM            -- 신규입력일시
             , p_IPT_IP             -- 신규입력IP
             , p_UPD_ID             -- 최종수정ID
             , p_UPD_DTM            -- 최종수정일시
             , p_UPD_IP             -- 최종수정IP
             )
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END;
/

-- PQHA_YYTRGPLNSEQ_Q
DROP PROCEDURE "PQHA_YYTRGPLNSEQ_Q";
CREATE PROCEDURE "PQHA_YYTRGPLNSEQ_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'                 -- FLAG
,   p_SIT_CD            IN VARCHAR2                             -- 현장코드
,   p_TRG_YY            IN TQHA_YYTRGPLN.TRG_YY     %TYPE       -- 목표년도
,   p_TRG_DGR           IN TQHA_YYTRGPLN.TRG_DGR    %TYPE       -- 목표차수
,   RTN_CURSOR          OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [안전보건목표 계획차수 조회] PROCEDRE (안전 > 안전보건목표/실적 > 안전보건목표  )

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      XXXX/XX/XX                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    ------------------------------------------------------------------------------------------------
    -- 차수데이터
    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
        SELECT BB.*
               --, FQSE_GETAPRVS_STATUS('qsa/yyTrgPlan', BB.SIT_CD, BB.TRG_YY, BB.TRG_DGR) AS APRV_CNT
          FROM (SELECT AA.SIT_CD                                    -- 현장코드
                     , AA.TRG_YY                                    -- 목표년도
                     , AA.TRG_DGR                                   -- 목표차수
                     , AA.STR_DT                                    -- 시작일자
                     , AA.END_DT                                    -- 종료일자
                     , AA.RMKS                                      -- 비고
                     , C.APRV_STATS                                -- 결재상태
                     , (SELECT CD_NM
                          FROM TCOA_COMCODE
                         WHERE HRNK_CD = 'QS031'    -- 'QSZ14'
                           AND COM_CD = C.APRV_STATS
                       )                                        AS APRV_STATS_NM
                     , ((SELECT COUNT(1)
                           FROM TQHA_YYTRGPLN
                          WHERE SIT_CD = AA.SIT_CD
                            AND TRG_YY = AA.TRG_YY
                            AND TRG_DGR = AA.TRG_DGR
                        )
                        +
                        (SELECT COUNT(1)
                           FROM TQHA_YYTRGARSLT
                          WHERE SIT_CD = AA.SIT_CD
                            AND TRG_YY = AA.TRG_YY
                            AND TRG_DGR = AA.TRG_DGR
                        )
                       )                                        AS DTL_COUNT         --차수의 사용건수
                     , AA.TRG_YY ||  LPAD(AA.TRG_DGR, 2, '0')   AS TRG_YY_DGR
                  FROM TQHA_YYTRGPLNSEQ AA
                     , TQHA_APRV        C
                 WHERE 1=1
                   AND AA.SIT_CD    = p_SIT_CD
                   AND AA.SIT_CD    = C.SIT_CD(+)
                   AND AA.APRV_NO   = C.APRV_NO(+)
               ) BB
         ORDER
            BY BB.TRG_YY_DGR DESC
        ;

    ------------------------------------------------------------------------------------------------
    -- 최신차수데이터
    ELSIF p_WRK_TP = 'Q2' THEN

        OPEN RTN_CURSOR FOR
        SELECT AAA.*
             , C.APRV_STATS
             , '▶ 결재상태 : ' ||
              NVL((SELECT CD_NM
                      FROM TCOA_COMCODE
                     WHERE HRNK_CD = 'QS031'    -- 'QSZ14'
                       AND COM_CD = C.APRV_STATS
                   ), '-')                                        AS APRV_STATS_NM
             --, FQSE_GETAPRVS_STATUS('qsa/yyTrgPlan', {SIT_CD}, AAA.TRG_YY, AAA.TRG_DGR) AS APRV_CNT
          FROM (SELECT MAX(SIT_CD)  AS SIT_CD
                     , MAX(YY_DGR)  AS YY_DGR
                     , MAX(TRG_YY)  KEEP(DENSE_RANK FIRST ORDER BY YY_DGR DESC) AS TRG_YY
                     , MAX(TRG_DGR) KEEP(DENSE_RANK FIRST ORDER BY YY_DGR DESC) AS TRG_DGR
                     , MAX(STR_DT)  KEEP(DENSE_RANK FIRST ORDER BY YY_DGR DESC) AS STR_DT
                     , MAX(END_DT)  KEEP(DENSE_RANK FIRST ORDER BY YY_DGR DESC) AS END_DT
                     , MAX(APRV_NO)  KEEP(DENSE_RANK FIRST ORDER BY YY_DGR DESC) AS APRV_NO
                  FROM (SELECT AA.SIT_CD                        -- 현장코드
                             , AA.TRG_YY                        -- 목표년도
                             , AA.TRG_DGR                       -- 목표차수
                             , AA.STR_DT
                             , AA.END_DT
                             , (AA.TRG_YY || '/' || AA.TRG_DGR)         AS YY_DGR
                             , AA.APRV_NO
                          FROM TQHA_YYTRGPLNSEQ AA
                         WHERE SIT_CD = p_SIT_CD
                      )
               ) AAA
          LEFT JOIN TQHA_APRV C ON AAA.SIT_CD   = C.SIT_CD
                               AND AAA.APRV_NO  = C.APRV_NO
        ;

    ------------------------------------------------------------------------------------------------
    -- 결재정보 조회
    ELSIF p_WRK_TP = 'Q3' THEN

        OPEN RTN_CURSOR FOR
        SELECT AA.SIT_CD               -- 현장코드
             , AA.TRG_YY                -- 교육일자
             , AA.TRG_DGR                -- 교육일자
             , AA.APRV_NO               -- 결재번호
             , C.APRV_STATS            -- 공통코드 QSF02
             , '▶ 결재상태 : ' ||
                  NVL((SELECT CD_NM
                          FROM TCOA_COMCODE
                         WHERE HRNK_CD = 'QS031'    -- 'QSZ14'
                           AND COM_CD = C.APRV_STATS
                       ), '-')                                        AS APRV_STATS_NM
             --, (
             --    SELECT APRV_DIV
             --      FROM TQSZ_APRVRVW
             --     WHERE SIT_CD = AA.SIT_CD
             --       AND ELAP_SEQ = AA.APRV_NO
             --       AND EMPE_NO = {EMPE_NO}
             --  ) AS APRV_DIV
              --, FQSE_GETAPRVS_STATUS('qsa/yyTrgPlan', {SIT_CD}, AA.TRG_YY, AA.TRG_DGR) AS APRV_CNT
          FROM TQHA_YYTRGPLNSEQ AA
             , TQHA_APRV        C
         WHERE AA.SIT_CD    = p_SIT_CD
           AND AA.TRG_YY    = p_TRG_YY
           AND AA.TRG_DGR   = p_TRG_DGR
           AND AA.SIT_CD    = C.SIT_CD(+)
           AND AA.APRV_NO   = C.APRV_NO(+)
        ;

    ------------------------------------------------------------------------------------------------
    -- 안전보건실적 화면에서 차수 조회
    ELSIF p_WRK_TP = 'Q4' THEN

        OPEN RTN_CURSOR FOR
        SELECT '|' || LISTAGG(TRG_YY_DGR, '|') WITHIN GROUP (ORDER BY BB.OB_TRG_YY_DGR DESC) AS TRG_YY_DGR
          FROM (SELECT AA.SIT_CD             -- 현장코드
                     , AA.TRG_YY              -- 목표년도
                     , AA.TRG_DGR             -- 목표차수
                     , AA.TRG_YY ||  LPAD(AA.TRG_DGR, 2, '0') AS OB_TRG_YY_DGR
                     , AA.TRG_YY || '-'  || AA.TRG_DGR AS TRG_YY_DGR
                  FROM TQHA_YYTRGPLNSEQ AA
                     , TQHA_APRV        C
                 WHERE AA.SIT_CD        = p_SIT_CD
                   AND AA.SIT_CD        = C.SIT_CD(+)
                   AND AA.APRV_NO       = C.APRV_NO(+)
                 --AND AA.APRV_STATS    = 'QSZ1490'
                   AND C.APRV_STATS     = '4'      -- 결재완료
               ) BB
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHA_YYTRGPLNSEQ_Q;
/

-- PQHA_YYTRGPLN_S
DROP PROCEDURE "PQHA_YYTRGPLN_S";
CREATE PROCEDURE "PQHA_YYTRGPLN_S" (
    p_WRK_TP            VARCHAR2 :='U'                                  -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
,   p_WRK_ID            VARCHAR2                                        -- 사용자 ID
,   p_WRK_IP            VARCHAR2                                        -- 사용자 IP
,   p_SIT_CD            TQHA_YYTRGPLN.SIT_CD                %TYPE       -- 현장코드
,   p_TRG_YY            TQHA_YYTRGPLN.TRG_YY                %TYPE       -- 목표년도
,   p_TRG_DGR           TQHA_YYTRGPLN.TRG_DGR               %TYPE       -- 목표차수
,   p_DRV_TRG_SEQ       TQHA_YYTRGPLN.DRV_TRG_SEQ           %TYPE       -- 추진목표순번
,   p_DRV_TRG_DIV       TQHA_YYTRGPLN.DRV_TRG_DIV           %TYPE       -- 추진목표구분
,   p_DRV_TRG           TQHA_YYTRGPLN.DRV_TRG               %TYPE       -- 추진목표
,   p_PRTCL_DRV_PLN     TQHA_YYTRGPLN.PRTCL_DRV_PLN         %TYPE       -- 세부추진계획
,   p_ACHV_TRG          TQHA_YYTRGPLN.ACHV_TRG              %TYPE       -- 달성목표치
,   p_ACHV_STR_DD       TQHA_YYTRGPLN.ACHV_STR_DD           %TYPE       -- 달성시작일
,   p_ACHV_END_DD       TQHA_YYTRGPLN.ACHV_END_DD           %TYPE       -- 달성종료일
)
IS
    /**************************************************************************************************************************
      Purpose :

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2019/04/18 09:44:58                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR(200);             -- ERROR Message
    USER_EXCEPTION EXCEPTION;

    p_UPD_ID            VARCHAR2(30);
    p_UPD_DTM           DATE;
    p_UPD_IP            VARCHAR2(30);
    p_IPT_ID            VARCHAR2(30);
    p_IPT_DTM           DATE;
    p_IPT_IP            VARCHAR2(30);

    v_APRV_STATS        VARCHAR2(20);
    v_APRV_STATS_NM     VARCHAR2(50);

BEGIN
    IF p_WRK_TP = 'I' THEN
        p_IPT_ID  := p_WRK_ID;
        p_IPT_DTM := SYSDATE();
        p_IPT_IP  := p_WRK_IP;
        p_UPD_ID  := p_WRK_ID;
        p_UPD_DTM := SYSDATE();
        p_UPD_IP  := p_WRK_IP;
    ELSE
        p_UPD_ID  := p_WRK_ID;
        p_UPD_DTM := SYSDATE();
        p_UPD_IP  := p_WRK_IP;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_TRG_YY IS NULL)  THEN
        ERR_MSG := '계획년도는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_TRG_DGR IS NULL)  THEN
        ERR_MSG := '계획차수는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------
    -- 결재상태 체크
    SELECT MAX(T2.APRV_STATS)
         , MAX(T3.CD_NM )
      INTO v_APRV_STATS
         , v_APRV_STATS_NM
      FROM TQHA_YYTRGPLNSEQ     T1
      LEFT JOIN TQHA_APRV       T2 ON T1.SIT_CD     = T2.SIT_CD
                                  AND T1.APRV_NO    = T2.APRV_NO
      LEFT JOIN TCOA_COMCODE    T3 ON T2.APRV_STATS = T3.COM_CD 
                                  AND T3.HRNK_CD    = 'QS031'
     WHERE T1.SIT_CD    = p_SIT_CD
       AND T1.TRG_YY    = p_TRG_YY
       AND T1.TRG_DGR   = p_TRG_DGR
    ;

    IF v_APRV_STATS IN ('2', '4') THEN
        ERR_MSG := '결재상태 [' || v_APRV_STATS_NM || ']인 데이터는 수정 불가합니다.';
        RAISE USER_EXCEPTION;
    END IF;

--    IF (p_DRV_TRG_SEQ IS NULL)  THEN
--        ERR_MSG := '추진목표순번는(은) 필수 입력사항 입니다.';
--        RAISE USER_EXCEPTION;
--    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN
        DELETE
          FROM TQHA_YYTRGPLN
         WHERE SIT_CD           = p_SIT_CD          -- 현장코드
           AND TRG_YY           = p_TRG_YY          -- 목표년도
           AND TRG_DGR          = p_TRG_DGR         -- 목표차수
           AND DRV_TRG_SEQ      = p_DRV_TRG_SEQ     -- 추진목표순번
        ;

    -------------------------------------------------------------------------------------
    ELSIF (p_WRK_TP ='U') THEN

        UPDATE TQHA_YYTRGPLN
           SET DRV_TRG_DIV          = p_DRV_TRG_DIV         -- 추진목표구분
             , DRV_TRG              = p_DRV_TRG             -- 추진목표
             , PRTCL_DRV_PLN        = p_PRTCL_DRV_PLN       -- 세부추진계획
             , ACHV_TRG             = p_ACHV_TRG            -- 달성목표치
             , ACHV_STR_DD          = p_ACHV_STR_DD         -- 달성시작일
             , ACHV_END_DD          = p_ACHV_END_DD         -- 달성종료일
             , UPD_ID               = p_UPD_ID              -- 최종수정ID
             , UPD_DTM              = p_UPD_DTM             -- 최종수정일시
             , UPD_IP               = p_UPD_IP              -- 최종수정IP
         WHERE SIT_CD               = p_SIT_CD              -- 현장코드
           AND TRG_YY               = p_TRG_YY              -- 목표년도
           AND TRG_DGR              = p_TRG_DGR             -- 목표차수
           AND DRV_TRG_SEQ          = p_DRV_TRG_SEQ         -- 추진목표순번
        ;

    -------------------------------------------------------------------------------------
    ELSE
        INSERT 
          INTO TQHA_YYTRGPLN
             ( SIT_CD               -- 현장코드
             , TRG_YY               -- 목표년도
             , TRG_DGR              -- 목표차수
             , DRV_TRG_SEQ          -- 추진목표순번
             , DRV_TRG_DIV          -- 추진목표구분
             , DRV_TRG              -- 추진목표
             , PRTCL_DRV_PLN        -- 세부추진계획
             , ACHV_TRG             -- 달성목표치
             , ACHV_STR_DD          -- 달성시작일
             , ACHV_END_DD          -- 달성종료일
             , IPT_ID               -- 신규입력ID
             , IPT_DTM              -- 신규입력일시
             , IPT_IP               -- 신규입력IP
             , UPD_ID               -- 최종수정ID
             , UPD_DTM              -- 최종수정일시
             , UPD_IP               -- 최종수정IP
             )
        VALUES 
             ( p_SIT_CD             -- 현장코드
             , p_TRG_YY             -- 목표년도
             , p_TRG_DGR            -- 목표차수
             , (SELECT NVL(MAX(DRV_TRG_SEQ), 0) + 1
                  FROM TQHA_YYTRGPLN
                 WHERE 1=1
                   AND SIT_CD   = p_SIT_CD
                   AND TRG_YY   = p_TRG_YY
                   AND TRG_DGR  = p_TRG_DGR
               )                    -- 추진목표순번
             , p_DRV_TRG_DIV        -- 추진목표구분
             , p_DRV_TRG            -- 추진목표
             , p_PRTCL_DRV_PLN      -- 세부추진계획
             , p_ACHV_TRG           -- 달성목표치
             , p_ACHV_STR_DD        -- 달성시작일
             , p_ACHV_END_DD        -- 달성종료일
             , p_IPT_ID             -- 신규입력ID
             , p_IPT_DTM            -- 신규입력일시
             , p_IPT_IP             -- 신규입력IP
             , p_UPD_ID             -- 최종수정ID
             , p_UPD_DTM            -- 최종수정일시
             , p_UPD_IP             -- 최종수정IP
             )
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END;
/

-- PQHB_DAYSAFE_CHKLST_S
DROP PROCEDURE "PQHB_DAYSAFE_CHKLST_S";
CREATE PROCEDURE "PQHB_DAYSAFE_CHKLST_S" 
                            (p_WRK_TP  VARCHAR2 :='U'                                     -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
                            ,p_WRK_ID  VARCHAR2                                           -- 사용자 ID 
                            ,p_WRK_IP  VARCHAR2                                           -- 사용자 IP 
                            ,p_SIT_CD TQHB_DAYSAFE_CHKLST.SIT_CD%TYPE                     -- 현장코드
                            ,p_PLN_YM TQHB_DAYSAFE_CHKLST.PLN_YM%TYPE                     -- 계획년월
                            ,p_PLN_DGR TQHB_DAYSAFE_CHKLST.PLN_DGR%TYPE                   -- 차수구분코드(QS005) 1 1차,2 2차
                            ,p_CUST_CD TQHB_DAYSAFE_CHKLST.CUST_CD%TYPE                   -- 협력업체코드
                            ,p_VNDR_SEQ TQHB_DAYSAFE_CHKLST.VNDR_SEQ%TYPE                -- 업체순번
                            ,p_CTP_CD TQHB_DAYSAFE_CHKLST.CTP_CD%TYPE                     -- 공종코드
                            ,p_UNT_CD TQHB_DAYSAFE_CHKLST.UNT_CD%TYPE                     -- 단위코드
                            ,p_CHK_ITM_CD TQHB_DAYSAFE_CHKLST.CHK_ITM_CD%TYPE             -- 점검항목코드
                            ,p_ODAY_CHK_DT TQHB_DAYSAFE_CHKLST.ODAY_CHK_DT%TYPE           -- 일일점검일자
                            ,p_RISK_GRD TQHB_DAYSAFE_CHKLST.RISK_GRD%TYPE                 -- 위험등급(QS09002) 작성
                            ,p_CHK_ITM_SEQ TQHB_DAYSAFE_CHKLST.CHK_ITM_SEQ%TYPE           -- 점검항목 정열순서
                            ,p_ODAY_CHK_RSLT TQHB_DAYSAFE_CHKLST.ODAY_CHK_RSLT%TYPE       -- 점검결과(QS006) 1 N/A,2 완료(유지),3 불량
                            ,p_ODAY_CHK_OPIN TQHB_DAYSAFE_CHKLST.ODAY_CHK_OPIN%TYPE       -- 일일안전책임자 점검의견
                            ,p_EMPE_NO TQHB_DAYSAFE_CHKLST.EMPE_NO%TYPE                   -- 일일안전책임자 사번
                            ,p_PHOTO_GRP1 TQHB_DAYSAFE_CHKLST.PHOTO_GRP1%TYPE             -- 첨부파일그룹사진1
                            ,p_PHOTO_DESC_1 TQHB_DAYSAFE_CHKLST.PHOTO_DESC_1%TYPE         -- 사진설명1
                            ,p_PHOTO_GRP2 TQHB_DAYSAFE_CHKLST.PHOTO_GRP2%TYPE             -- 첨부파일그룹사진2
                            ,p_PHOTO_DESC_2 TQHB_DAYSAFE_CHKLST.PHOTO_DESC_2%TYPE         -- 사진설명2
                            ,p_NCR_PUBC_YN TQHB_DAYSAFE_CHKLST.NCR_PUBC_YN%TYPE           -- 발행 1, 미발행 0
                            ,p_NCR_DOC_NO TQHB_DAYSAFE_CHKLST.NCR_DOC_NO%TYPE             -- 부적합문서번호
                            ,p_MA_DDLN_DT TQHB_DAYSAFE_CHKLST.MA_DDLN_DT%TYPE             -- 조치기한일자
                            ,p_VNDR_NOTI_YN TQHB_DAYSAFE_CHKLST.VNDR_NOTI_YN%TYPE         -- 발송 1 미발송0
                            ,p_VNDR_SEND_DT TQHB_DAYSAFE_CHKLST.VNDR_SEND_DT%TYPE         -- 업체발송일자
                            ,p_VNDR_MA_YN TQHB_DAYSAFE_CHKLST.VNDR_MA_YN%TYPE             -- 조치구분(QS007) 1 조치, 0 미조치
                            ,p_VNDR_MA_DT TQHB_DAYSAFE_CHKLST.VNDR_MA_DT%TYPE             -- 업체조치일자
                            ,p_NCR_LOC VARCHAR2    -- 발생위치 
                            ,p_CHK_ITM_NM VARCHAR2
                            )
                            
IS 
    /**************************************************************************************************************************
      Purpose : 

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/09/10 14:13:42                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

	v_SEQ NUMBER;
	v_EMPE_NO VARCHAR2(20);
	v_OUT VARCHAR2(20);
	v_OLD_NCR_DOC_NO VARCHAR2(20);
	v_VNDR_APRV_YN VARCHAR2(1);
	v_MGR_APRV_YN VARCHAR2(1);
	
BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_YM IS NULL)  THEN
        ERR_MSG := '계획년월는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_DGR IS NULL)  THEN
        ERR_MSG := '차수구분코드(QS005) 1 1차,2 2차는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CUST_CD IS NULL)  THEN
        ERR_MSG := '협력업체코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CTP_CD IS NULL)  THEN
        ERR_MSG := '공종코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_UNT_CD IS NULL)  THEN
        ERR_MSG := '단위코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CHK_ITM_CD IS NULL)  THEN
        ERR_MSG := '점검항목코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_ODAY_CHK_DT IS NULL)  THEN
        ERR_MSG := '일일점검일자는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_RISK_GRD IS NULL)  THEN
        ERR_MSG := '위험등급(QS09002) 작성는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_VNDR_SEQ IS NULL)  THEN
        ERR_MSG := '업체순번는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------

        -- 2025.02.02 부적합보고서 승인 상태 체크하여, 업체 승인 요청시 또는 관리자 승인시엔 불량에서 다른걸로 변경하지 못하게 막아야 함.
        SELECT NVL(MAX(NCR_DOC_NO), '*')
          INTO v_OLD_NCR_DOC_NO
          FROM TQHB_DAYSAFE_CHKLST
         WHERE SIT_CD       = p_SIT_CD          --현장코드
           AND PLN_YM       = p_PLN_YM          --계획년월
           AND PLN_DGR      = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
           AND CUST_CD      = p_CUST_CD         --공종코드
           AND VNDR_SEQ     = p_VNDR_SEQ        --공종코드
           AND CTP_CD       = p_CTP_CD          --공종코드
           AND UNT_CD       = p_UNT_CD          --단위코드
           AND CHK_ITM_CD   = p_CHK_ITM_CD      --점검항목코드
           AND ODAY_CHK_DT  = p_ODAY_CHK_DT     --일일점검일자
           AND RISK_GRD     = p_RISK_GRD
        ;

        IF v_OLD_NCR_DOC_NO != '*' THEN
            SELECT VNDR_APRV_YN
                 , MGR_APRV_YN
              INTO v_VNDR_APRV_YN
                 , v_MGR_APRV_YN
              FROM TQHA_NCR_REP
             WHERE SIT_CD       = p_SIT_CD
               AND NCR_DOC_NO   = v_OLD_NCR_DOC_NO
            ;

            IF v_MGR_APRV_YN = '1' THEN
                ERR_MSG := '부적합보고서 관리자가 승인한 상태여서 변경할 수 없습니다.'
                        || CHR(10) || '관리자 반려 후, 업체 승인요청취소 후에 변경 가능합니다. ';
                RAISE USER_EXCEPTION;
            END IF;

            IF v_VNDR_APRV_YN = '1' THEN
                ERR_MSG := '부적합보고서 업체 승인요청중이어서 변경할 수 없습니다.'
                        || CHR(10) || '승인요청 취소 후 변경 가능합니다 ';
                RAISE USER_EXCEPTION;
            END IF;

        END IF;

        
     SELECT MAX(EMPE_NO) INTO v_EMPE_NO 
      FROM TQHB_DAYSAFE_CHKLST
     WHERE SIT_CD = p_SIT_CD          --현장코드
       AND PLN_YM = p_PLN_YM          --계획년월
       AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
       AND CUST_CD = p_CUST_CD         --협력업체코드
       AND CTP_CD = p_CTP_CD          --공종코드
       AND UNT_CD = p_UNT_CD          --단위코드
       AND CHK_ITM_CD = p_CHK_ITM_CD      --점검항목코드
       AND ODAY_CHK_DT = p_ODAY_CHK_DT     --일일점검일자
       AND RISK_GRD = p_RISK_GRD        --위험등급(QS09002) 작성
       AND VNDR_SEQ = p_VNDR_SEQ;       --업체순번
           
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN
        DELETE 
          FROM TQHB_DAYSAFE_CHKLST
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND PLN_YM = p_PLN_YM          --계획년월
           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
           AND CUST_CD = p_CUST_CD         --협력업체코드
           AND CTP_CD = p_CTP_CD          --공종코드
           AND UNT_CD = p_UNT_CD          --단위코드
           AND CHK_ITM_CD = p_CHK_ITM_CD      --점검항목코드
           AND ODAY_CHK_DT = p_ODAY_CHK_DT     --일일점검일자
           AND RISK_GRD = p_RISK_GRD        --위험등급(QS09002) 작성
           AND VNDR_SEQ = p_VNDR_SEQ;       --업체순번

    ELSIF (p_WRK_TP ='U') THEN
        UPDATE TQHB_DAYSAFE_CHKLST
           SET CHK_ITM_SEQ          = p_CHK_ITM_SEQ             --점검항목 정열순서
              ,ODAY_CHK_RSLT        = p_ODAY_CHK_RSLT           --점검결과(QS006) 1 N/A,2 완료(유지),3 불량
              ,ODAY_CHK_OPIN        = p_ODAY_CHK_OPIN           --일일안전책임자 점검의견
              ,EMPE_NO              = p_WRK_ID                  --일일안전책임자 사번
              ,PHOTO_GRP1           = p_PHOTO_GRP1              --첨부파일그룹사진1
              ,PHOTO_DESC_1         = p_PHOTO_DESC_1            --사진설명1
              ,PHOTO_GRP2           = p_PHOTO_GRP2              --첨부파일그룹사진2
              ,PHOTO_DESC_2         = p_PHOTO_DESC_2            --사진설명2
--              ,NCR_PUBC_YN          = p_NCR_PUBC_YN             --발행 1, 미발행 0
--              ,NCR_DOC_NO           = v_OLD_NCR_DOC_NO              --부적합문서번호
--              ,MA_DDLN_DT           = p_MA_DDLN_DT              --조치기한일자
--              ,VNDR_NOTI_YN         = p_VNDR_NOTI_YN            --발송 1 미발송0
--              ,VNDR_SEND_DT         = p_VNDR_SEND_DT            --업체발송일자
--              ,VNDR_MA_YN           = p_VNDR_MA_YN              --조치구분(QS007) 1 조치, 0 미조치
--              ,VNDR_MA_DT           = p_VNDR_MA_DT              --업체조치일자
              ,UPD_ID               = p_WRK_ID                  --수정ID 
              ,UPD_DTM              = SYSDATE()                 --수정일시
              ,UPD_IP               = p_WRK_IP                  --수정IP
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND PLN_YM = p_PLN_YM          --계획년월
           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
           AND CUST_CD = p_CUST_CD         --협력업체코드
           AND CTP_CD = p_CTP_CD          --공종코드
           AND UNT_CD = p_UNT_CD          --단위코드
           AND CHK_ITM_CD = p_CHK_ITM_CD      --점검항목코드
           AND ODAY_CHK_DT = p_ODAY_CHK_DT     --일일점검일자
           AND RISK_GRD = p_RISK_GRD        --위험등급(QS09002) 작성
           AND VNDR_SEQ = p_VNDR_SEQ;       --업체순번
                      
           
         SELECT NVL(MAX(EMPE_NO_SEQ), 0)
          INTO v_SEQ
          FROM TQHB_DAYSAFE_NAM
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND PLN_YM = p_PLN_YM          --계획년월
           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
           AND ODAY_CHK_DT = p_ODAY_CHK_DT     --일일점검일자
           AND EMPE_NO = v_EMPE_NO
           AND RISK_GRD = p_RISK_GRD       --위험등급(QS09002) 작성
         ;
           
         -- 안전책임자 변경    
         UPDATE TQHB_DAYSAFE_NAM
         SET EMPE_NO = p_WRK_ID
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND PLN_YM = p_PLN_YM          --계획년월
           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
           AND ODAY_CHK_DT = p_ODAY_CHK_DT     --일일점검일자
           AND EMPE_NO = v_EMPE_NO
           AND EMPE_NO_SEQ = v_SEQ
           AND RISK_GRD = p_RISK_GRD;       --위험등급(QS09002) 작성
           
         -- 부적합 보고서
         IF (p_ODAY_CHK_RSLT = '3' AND v_OLD_NCR_DOC_NO = '*' ) THEN
           		PQHA_NCR_REP_S(
				    'I'                        -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
				,   p_WRK_ID                        -- 사용자 ID 
				,   p_WRK_IP                        -- 사용자 IP 
				,   p_SIT_CD                        -- 현장코드
				,   NULL                    -- 부적합문서번호
				,   NULL                       -- 년도별일련번호
				,   TO_CHAR(SYSDATE(),'YYYYMMDD')                       -- 발행일자
				,   TO_CHAR(SYSDATE()+3,'YYYYMMDD')                     -- 조치기한일자
				,   p_CUST_CD                       -- 협력업체코드
				,   p_VNDR_SEQ                      -- 업체순번
				,   p_CTP_CD                        -- 공종코드
				,   p_NCR_LOC                       -- 발생위치
				,   p_ODAY_CHK_OPIN                 -- 요구사항
				,   p_CHK_ITM_NM                    -- 부적합내용 
				,   p_PHOTO_GRP1                -- 첨부파일그룹사진1
				,   p_PHOTO_DESC_1              -- 사진설명1 
				,   p_PHOTO_GRP2                -- 첨부파일그룹사진2
				,   p_PHOTO_DESC_2              -- 사진설명2
				,   NULL                      -- 작성자
				,   NULL                  -- 발송 1 미발송 0
				,   NULL                  -- 업체통보일자
				,   NULL                   -- 업체조치제목
				,   NULL                -- 업체재발방지대책
				,   NULL                    -- 업체조치일자
				,   '2'                    -- NCR조치(QS025) 1 조치, 2 미조치
				,   NULL                   -- 업체조치내용
				,   NULL                   -- 업체조치자
				,   NULL               -- 업체조치그룹사진1
				,   NULL             -- 업체사진설명1
				,   NULL               -- 업체조치그룹사진2
				,   NULL             -- 업체사진설명2
				,   NULL                  -- 승인요청 1 미요청 0
				,   NULL                  -- 업체승인요청일자
				,   NULL                   -- 발송Y (SMS)
				,   NULL                   -- 승인 1, 반려 2
				,   NULL                   -- 관리자승인일자
				,   NULL                   -- 부적합생성구분  1, 부적합, 2 안전점검, 3 추가위험
				,   '0'                     -- 직영여부
				,   v_OUT
				);
           
	           UPDATE TQHB_DAYSAFE_CHKLST
		           SET NCR_DOC_NO           = v_OUT              --부적합문서번호
		              ,NCR_PUBC_YN          = '1'
		              ,UPD_ID               = p_WRK_ID                  --수정ID 
		              ,UPD_DTM              = SYSDATE()                 --수정일시
		              ,UPD_IP               = p_WRK_IP                  --수정IP
		         WHERE SIT_CD = p_SIT_CD          --현장코드
		           AND PLN_YM = p_PLN_YM          --계획년월
		           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
		           AND CUST_CD = p_CUST_CD         --협력업체코드
		           AND CTP_CD = p_CTP_CD          --공종코드
		           AND UNT_CD = p_UNT_CD          --단위코드
		           AND CHK_ITM_CD = p_CHK_ITM_CD      --점검항목코드
		           AND ODAY_CHK_DT = p_ODAY_CHK_DT     --일일점검일자
		           AND RISK_GRD = p_RISK_GRD        --위험등급(QS09002) 작성
		           AND VNDR_SEQ = p_VNDR_SEQ;       --업체순번
           
           -- 부적합 보고서
           ELSIF (p_ODAY_CHK_RSLT != '3' AND v_OLD_NCR_DOC_NO != '*') THEN
           		
	            DELETE 
		          FROM TQHA_NCR_REP
		         WHERE SIT_CD       = p_SIT_CD          -- 현장코드
		           AND NCR_DOC_NO   = v_OLD_NCR_DOC_NO  -- 부적합문서번호
		        ;
           
	           UPDATE TQHB_DAYSAFE_CHKLST
		           SET NCR_DOC_NO           = NULL              --부적합문서번호
		              ,NCR_PUBC_YN          = '0'
		              ,UPD_ID               = p_WRK_ID                  --수정ID 
		              ,UPD_DTM              = SYSDATE()                 --수정일시
		              ,UPD_IP               = p_WRK_IP                  --수정IP
		         WHERE SIT_CD = p_SIT_CD          --현장코드
		           AND PLN_YM = p_PLN_YM          --계획년월
		           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
		           AND CUST_CD = p_CUST_CD         --협력업체코드
		           AND CTP_CD = p_CTP_CD          --공종코드
		           AND UNT_CD = p_UNT_CD          --단위코드
		           AND CHK_ITM_CD = p_CHK_ITM_CD      --점검항목코드
		           AND ODAY_CHK_DT = p_ODAY_CHK_DT     --일일점검일자
		           AND RISK_GRD = p_RISK_GRD        --위험등급(QS09002) 작성
		           AND VNDR_SEQ = p_VNDR_SEQ;       --업체순번
           
           END IF;
           
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END PQHB_DAYSAFE_CHKLST_S;
/

-- PQHB_DAYSAFE_DT_S
DROP PROCEDURE "PQHB_DAYSAFE_DT_S";
CREATE PROCEDURE "PQHB_DAYSAFE_DT_S"
                            (p_WRK_TP  VARCHAR2 :='U'                                     -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
                            ,p_WRK_ID  VARCHAR2                                           -- 사용자 ID 
                            ,p_WRK_IP  VARCHAR2                                           -- 사용자 IP 
                            ,p_SIT_CD TQHB_DAYSAFE_DT.SIT_CD%TYPE                         -- 현장코드
                            ,p_PLN_YM TQHB_DAYSAFE_DT.PLN_YM%TYPE                         -- 계획년월
                            ,p_PLN_DGR TQHB_DAYSAFE_DT.PLN_DGR%TYPE                       -- 차수구분코드(QS005) 1 1차,2 2차
                            ,p_ODAY_CHK_DT TQHB_DAYSAFE_DT.ODAY_CHK_DT%TYPE               -- 일일점검일자
                            ,p_RISK_GRD TQHB_DAYSAFE_DT.RISK_GRD%TYPE                     -- 위험등급(QS09002) 작성
                            ,p_EMPE_NO_SAFT TQHB_DAYSAFE_DT.EMPE_NO_SAFT%TYPE             -- 일일안전책임자 사원번호
                            ,p_SAFT_MGR_YN TQHB_DAYSAFE_DT.SAFT_MGR_YN%TYPE               -- 일일안전책임자(승인1 미승인0)
                            ,p_SAFT_MGR_DT TQHB_DAYSAFE_DT.SAFT_MGR_DT%TYPE               -- 일일안전책임자 승인/반려일자
                            ,p_EMPE_NO_OMGR TQHB_DAYSAFE_DT.EMPE_NO_OMGR%TYPE             -- 현장소장 사원번호
                            ,p_SITE_OMGR_YN TQHB_DAYSAFE_DT.SITE_OMGR_YN%TYPE             -- 현장소장(승인1 미승인0)
                            ,p_SITE_OMGR_DT TQHB_DAYSAFE_DT.SITE_OMGR_DT%TYPE             -- 현장소장 승인/반려일자
                            ,p_MGR_OPIN TQHB_DAYSAFE_DT.SITE_OMGR_OPIN%TYPE)        -- 현장소장 승인/반려의견
IS 
    /**************************************************************************************************************************
      Purpose : 

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/09/10 17:16:30                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;


BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_YM IS NULL)  THEN
        ERR_MSG := '계획년월는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_DGR IS NULL)  THEN
        ERR_MSG := '차수구분코드(QS005) 1 1차,2 2차는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_ODAY_CHK_DT IS NULL)  THEN
        ERR_MSG := '일일점검일자는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_RISK_GRD IS NULL)  THEN
        ERR_MSG := '위험등급(QS09002) 작성는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='W1') THEN
        UPDATE TQHB_DAYSAFE_DT
           SET EMPE_NO_SAFT         = p_WRK_ID            --일일안전책임자 사원번호
              ,SAFT_MGR_YN          = p_SAFT_MGR_YN             --일일안전책임자(승인1 미승인0)
              ,SAFT_MGR_DT          = TO_CHAR(SYSDATE(),'YYYYMMDD')             --일일안전책임자 승인/반려일자
              ,SAFT_MGR_OPIN        = p_MGR_OPIN           --일일안전책임자 승인/반려의견
              ,UPD_ID               = p_WRK_ID                  --수정ID 
              ,UPD_DTM              = SYSDATE()                 --수정일시
              ,UPD_IP               = p_WRK_IP                  --수정IP
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND PLN_YM = p_PLN_YM          --계획년월
           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
           AND ODAY_CHK_DT = p_ODAY_CHK_DT     --일일점검일자
           AND RISK_GRD = p_RISK_GRD;       --위험등급(QS09002) 작성

    ELSIF (p_WRK_TP ='W2') THEN
        UPDATE TQHB_DAYSAFE_DT
           SET EMPE_NO_OMGR         = p_WRK_ID              --현장소장 사원번호
              ,SITE_OMGR_YN         = p_SITE_OMGR_YN            --현장소장(승인1 미승인0)
              ,SITE_OMGR_DT         = TO_CHAR(SYSDATE(),'YYYYMMDD')            --현장소장 승인/반려일자
              ,SITE_OMGR_OPIN       = p_MGR_OPIN          --현장소장 승인/반려의견
              ,UPD_ID               = p_WRK_ID                  --수정ID 
              ,UPD_DTM              = SYSDATE()                 --수정일시
              ,UPD_IP               = p_WRK_IP                  --수정IP
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND PLN_YM = p_PLN_YM          --계획년월
           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
           AND ODAY_CHK_DT = p_ODAY_CHK_DT     --일일점검일자
           AND RISK_GRD = p_RISK_GRD;       --위험등급(QS09002) 작성
           
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHB_DAYSAFE_DT_W
DROP PROCEDURE "PQHB_DAYSAFE_DT_W";
CREATE PROCEDURE "PQHB_DAYSAFE_DT_W"
                            (p_WRK_TP  VARCHAR2 :='U'                                     -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
                            ,p_WRK_ID  VARCHAR2                                           -- 사용자 ID 
                            ,p_WRK_IP  VARCHAR2                                           -- 사용자 IP 
                            ,p_SIT_CD TQHB_DAYSAFE_DT.SIT_CD%TYPE                         -- 현장코드
                            ,p_PLN_YM TQHB_DAYSAFE_DT.PLN_YM%TYPE                         -- 계획년월
                            ,p_PLN_DGR TQHB_DAYSAFE_DT.PLN_DGR%TYPE                       -- 차수구분코드(QS005)
                            ,p_APRS_STR_DT VARCHAR2
                            ,p_APRS_END_DT VARCHAR2
                            )
IS 
    /**************************************************************************************************************************
      Purpose : 
 
      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/09/04 17:04:01                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

	v_CNT NUMBER;
BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_YM IS NULL)  THEN
        ERR_MSG := '계획년월는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_DGR IS NULL)  THEN
        ERR_MSG := '차수구분코드(QS005) 는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;
    
    IF (p_APRS_STR_DT IS NULL OR p_APRS_END_DT IS NULL)  THEN
        ERR_MSG := '평가기간은 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------
  
	SELECT COUNT(1) INTO v_CNT
	FROM TQHB_DAYSAFE_CHKLST
	WHERE 1=1
	AND SIT_CD  = p_SIT_CD
    AND PLN_YM  = p_PLN_YM
    AND PLN_DGR = p_PLN_DGR
    AND EMPE_NO IS NOT NULL
    ;
    
    IF (v_CNT > 0)  THEN
        ERR_MSG := '이미 점검이 시작되어 진행할 수 없습니다.';
        RAISE USER_EXCEPTION;
    END IF;
  
    
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    
  
    -- 점검자 초기화
    DELETE FROM TQHB_DAYSAFE_NAM
    WHERE 1=1
	AND SIT_CD  = p_SIT_CD
    AND PLN_YM  = p_PLN_YM
    AND PLN_DGR = p_PLN_DGR;
    
    -- 점검자체크 초기화
    DELETE FROM TQHB_DAYSAFE_CHKLST
    WHERE 1=1
	AND SIT_CD  = p_SIT_CD
    AND PLN_YM  = p_PLN_YM
    AND PLN_DGR = p_PLN_DGR;
    
    -- 점검일자 초기화
    DELETE FROM TQHB_DAYSAFE_DT
    WHERE 1=1
	AND SIT_CD  = p_SIT_CD
    AND PLN_YM  = p_PLN_YM
    AND PLN_DGR = p_PLN_DGR;
    
    
    --중점점검 일자
    INSERT INTO TQHB_DAYSAFE_DT (
	     SIT_CD
	    ,PLN_YM
	    ,PLN_DGR
	    ,ODAY_CHK_DT
	    ,RISK_GRD
	    ,IPT_ID                  --입력ID
	    ,IPT_DTM                 --입력일시
	    ,IPT_IP                  --입력IP
	    ,UPD_ID                  --수정ID
	    ,UPD_DTM                 --수정일시
	    ,UPD_IP                  --수정IP
	)
	SELECT  p_SIT_CD
	       ,p_PLN_YM
	       ,p_PLN_DGR
	       ,TO_CHAR(TO_DATE(p_APRS_STR_DT, 'YYYYMMDD') + LEVEL - 1, 'YYYYMMDD')
	       ,'QS0900201'
	       ,p_WRK_ID                --입력ID 
           ,SYSDATE()               --입력일시
           ,p_WRK_IP                --입력IP
           ,p_WRK_ID                --수정ID
           ,SYSDATE()               --수정일시
           ,p_WRK_IP              --수정IP
	  FROM DUAL
	CONNECT BY LEVEL <= (TO_DATE(p_APRS_END_DT, 'YYYYMMDD') - TO_DATE(p_APRS_STR_DT, 'YYYYMMDD') + 1);

   --일상점검 일자
   INSERT INTO TQHB_DAYSAFE_DT (
	     SIT_CD
	    ,PLN_YM
	    ,PLN_DGR
	    ,ODAY_CHK_DT
	    ,RISK_GRD
	    ,IPT_ID                  --입력ID
	    ,IPT_DTM                 --입력일시
	    ,IPT_IP                  --입력IP
	    ,UPD_ID                  --수정ID
	    ,UPD_DTM                 --수정일시
	    ,UPD_IP                  --수정IP
	)
	SELECT  p_SIT_CD
	       ,p_PLN_YM
	       ,p_PLN_DGR
	       ,TO_CHAR(TO_DATE(p_APRS_STR_DT, 'YYYYMMDD') + LEVEL - 1, 'YYYYMMDD')
	       ,'QS0900202'
	       ,p_WRK_ID                --입력ID 
           ,SYSDATE()               --입력일시
           ,p_WRK_IP                --입력IP
           ,p_WRK_ID                --수정ID
           ,SYSDATE()               --수정일시
           ,p_WRK_IP              --수정IP
	  FROM DUAL
	CONNECT BY LEVEL <= (TO_DATE(p_APRS_END_DT, 'YYYYMMDD') - TO_DATE(p_APRS_STR_DT, 'YYYYMMDD') + 1);
   
    
   -- 위험요인 체크리스트 추가
   INSERT INTO TQHB_DAYSAFE_CHKLST
	(
	     SIT_CD
	    ,PLN_YM
	    ,PLN_DGR
	    ,CUST_CD
	    ,VNDR_SEQ
	    ,CTP_CD
	    ,UNT_CD
	    ,CHK_ITM_CD
	    ,ODAY_CHK_DT
	    ,RISK_GRD
	    ,IPT_ID                  --입력ID
	    ,IPT_DTM                 --입력일시
	    ,IPT_IP                  --입력IP
	    ,UPD_ID                  --수정ID
	    ,UPD_DTM                 --수정일시
	    ,UPD_IP                  --수정IP
	)
	SELECT
	     R.SIT_CD
	    ,R.PLN_YM
	    ,R.PLN_DGR
	    ,R.CUST_CD
	    ,R.VNDR_SEQ
	    ,R.CTP_CD
	    ,R.UNT_CD
	    ,R.CHK_ITM_CD
	    ,D.ODAY_CHK_DT
	    ,D.RISK_GRD
	    ,p_WRK_ID                --입력ID 
        ,SYSDATE()               --입력일시
        ,p_WRK_IP                --입력IP
        ,p_WRK_ID                --수정ID
        ,SYSDATE()               --수정일시
        ,p_WRK_IP              --수정IP
	FROM TQHB_RISK_LST R
	JOIN TQHB_DAYSAFE_DT D
	  ON D.SIT_CD  = R.SIT_CD
	 AND D.PLN_YM  = R.PLN_YM
	 AND D.PLN_DGR = R.PLN_DGR
	 AND D.RISK_GRD = R.RISK_GRD
	WHERE D.SIT_CD      = P_SIT_CD
	  AND D.PLN_YM      = P_PLN_YM
	  AND D.PLN_DGR     = P_PLN_DGR
	  AND R.RISK_GRD != 'QS0900203'
	  ORDER BY 
	    R.SIT_CD,
	    R.PLN_YM,
	    R.PLN_DGR,
	    R.CUST_CD,
	    R.VNDR_SEQ,
	    R.CTP_CD,
	    R.UNT_CD,
	    R.CHK_ITM_CD,
	    D.ODAY_CHK_DT,
	    D.RISK_GRD
	  ;
   

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHB_DAYSAFE_NAM_S
DROP PROCEDURE "PQHB_DAYSAFE_NAM_S";
CREATE PROCEDURE "PQHB_DAYSAFE_NAM_S"
                            (p_WRK_TP  VARCHAR2 :='U'                                     -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
                            ,p_WRK_ID  VARCHAR2                                           -- 사용자 ID 
                            ,p_WRK_IP  VARCHAR2                                           -- 사용자 IP 
                            ,p_SIT_CD TQHB_DAYSAFE_NAM.SIT_CD%TYPE                        -- 현장코드
                            ,p_PLN_YM TQHB_DAYSAFE_NAM.PLN_YM%TYPE                        -- 계획년월
                            ,p_PLN_DGR TQHB_DAYSAFE_NAM.PLN_DGR%TYPE                      -- 차수구분코드(QS005) 1 1차,2 2차
                            ,p_ODAY_CHK_DT TQHB_DAYSAFE_NAM.ODAY_CHK_DT%TYPE              -- 일일점검일자
                            ,p_EMPE_NO_SEQ TQHB_DAYSAFE_NAM.EMPE_NO_SEQ%TYPE              -- 일일안전책임자 순번
                            ,p_RISK_GRD TQHB_DAYSAFE_NAM.RISK_GRD%TYPE                    -- 위험등급(QS09002) 작성
                            ,p_EMPE_NO TQHB_DAYSAFE_NAM.EMPE_NO%TYPE)                     -- 일일안전책임자 사번
IS 
    /**************************************************************************************************************************
      Purpose : 

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/09/07 18:35:50                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

	v_SEQ              NUMBER := 0;
BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_YM IS NULL)  THEN
        ERR_MSG := '계획년월는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_DGR IS NULL)  THEN
        ERR_MSG := '차수구분코드(QS005) 1 1차,2 2차는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_ODAY_CHK_DT IS NULL)  THEN
        ERR_MSG := '일일점검일자는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_RISK_GRD IS NULL)  THEN
        ERR_MSG := '위험등급(QS09002) 작성는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN
        DELETE 
          FROM TQHB_DAYSAFE_NAM
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND PLN_YM = p_PLN_YM          --계획년월
           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
           AND ODAY_CHK_DT = p_ODAY_CHK_DT     --일일점검일자
--           AND EMPE_NO_SEQ = p_EMPE_NO_SEQ     --일일안전책임자 순번
           AND RISK_GRD = p_RISK_GRD;       --위험등급(QS09002) 작성

    ELSE 
    
	    SELECT NVL(MAX(EMPE_NO_SEQ), 0) + 1
          INTO v_SEQ
          FROM TQHB_DAYSAFE_NAM
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND PLN_YM = p_PLN_YM          --계획년월
           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
           AND ODAY_CHK_DT = p_ODAY_CHK_DT     --일일점검일자
           AND RISK_GRD = p_RISK_GRD       --위험등급(QS09002) 작성
        ;
        INSERT INTO TQHB_DAYSAFE_NAM
                   ( SIT_CD                  --현장코드
                    ,PLN_YM                  --계획년월
                    ,PLN_DGR                 --차수구분코드(QS005) 1 1차,2 2차
                    ,ODAY_CHK_DT             --일일점검일자
                    ,EMPE_NO_SEQ             --일일안전책임자 순번
                    ,RISK_GRD                --위험등급(QS09002) 작성
                    ,EMPE_NO                 --일일안전책임자 사번
                    ,IPT_ID                  --입력ID
                    ,IPT_DTM                 --입력일시
                    ,IPT_IP                  --입력IP
                    ,UPD_ID                  --수정ID
                    ,UPD_DTM                 --수정일시
                    ,UPD_IP                  --수정IP
                    )
             VALUES (p_SIT_CD                --현장코드
                    ,p_PLN_YM                --계획년월
                    ,p_PLN_DGR               --차수구분코드(QS005) 1 1차,2 2차
                    ,p_ODAY_CHK_DT           --일일점검일자
                    ,v_SEQ                   --일일안전책임자 순번
                    ,p_RISK_GRD              --위험등급(QS09002) 작성
                    ,p_EMPE_NO               --일일안전책임자 사번
                    ,p_WRK_ID                --입력ID 
                    ,SYSDATE()               --입력일시
                    ,p_WRK_IP                --입력IP
                    ,p_WRK_ID                --수정ID
                    ,SYSDATE()               --수정일시
                    ,p_WRK_IP);              --수정IP
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHB_RISK_CHK_Q
DROP PROCEDURE "PQHB_RISK_CHK_Q";
CREATE PROCEDURE "PQHB_RISK_CHK_Q"
(
      p_WRK_TP  VARCHAR2 DEFAULT 'Q'                                                       -- FLAG( Q: SELECT )
     ,p_SIT_CD TQHB_RISK_CHK.SIT_CD%TYPE                                                  -- 현장코드
     ,p_PLN_YM TQHB_RISK_CHK.PLN_YM%TYPE                                                  -- 계획년월
     ,p_PLN_DGR TQHB_RISK_CHK.PLN_DGR%TYPE                                                -- 차수구분코드(QS005) 1 1차,2 2차
     ,p_CUST_CD TQHB_RISK_CHK.CUST_CD%TYPE                                                -- 협력업체코드
     ,p_VNDR_SEQ TQHB_RISK_CHK.VNDR_SEQ%TYPE                                              -- 업체순번     
     ,RTN_CURSOR OUT SYS_REFCURSOR
)
IS 
    /**************************************************************************************************************************
      Purpose : 

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/08/27 14:47:26                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;


BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리
    ---------------------------------------------------------------------------------------------------------------------------

    OPEN RTN_CURSOR FOR
    WITH BASE_DATA AS (
    SELECT A.SIT_CD                 -- 현장코드
          ,A.PLN_YM                 -- 계획년월
          ,A.PLN_DGR                -- 차수구분코드(QS005) 1 1차,2 2차
          ,A.CUST_CD                -- 협력업체코드
          ,A.VNDR_SEQ               -- 협력업체순번
          ,(SELECT CUST_NM FROM VQSZ_TRADE WHERE CUST_CD = A.CUST_CD) AS CUST_NM
          ,A.CTP_CD                 -- 공종코드
          ,A.UNT_CD                 -- 단위코드
          ,(SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD) AS CTP_NM
          ,(SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD) AS UNT_NM
          ,A.CHK_ITM_CD             -- 점검항목코드
          ,A.CHK_ITM_SEQ            -- 점검항목 정열순서
          ,A.CHK_ITM_NM             -- 점검항목명
          ,A.CHK_LOC                -- 점검위치
          ,A.DISS_SHP                -- 재해형태(QS036)
          ,A.IMPRV_CPLN             -- 개선대책 (TQHB_RISK_LST)
          ,A.WRK_PSNNO              -- 작업인원
          ,A.ITM_ADD_YN             -- 기존 : 0, 추가 : 1
          -- [TQHB_RISK_NAM 명단 컬럼]
          ,B.EMPE_NO                -- 사원번호
          ,B.APRS_NAMSEQ            -- 점검자 정열순서
          ,B.CO_DIV_CD              -- 회사구분코드
          ,B.JB_CD                  -- 직무/직급코드
          ,NVL((SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = B.JB_CD AND HRNK_CD = 'QS077' AND USE_YN = '1'), '') AS JB_NM
          ,CASE WHEN B.CO_DIV_CD = '1' THEN (SELECT USR_NM FROM TCOZ_USR_INFO WHERE EMPNO = B.EMPE_NO) 
                                            || '/' || NVL((SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = B.JB_CD AND HRNK_CD = 'QS077' AND USE_YN = '1'), '')
                WHEN B.CO_DIV_CD = '2' THEN (SELECT PNM FROM TQHB_VNDRNAM WHERE SIT_CD = A.SIT_CD AND CUST_CD = A.CUST_CD AND VNDR_SEQ = A.VNDR_SEQ AND EMPE_NO = B.EMPE_NO) 
                                            || '/' || NVL((SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = B.JB_CD AND HRNK_CD = 'QS077' AND USE_YN = '1'), '')
           END AS USR_NM
           
          -- [TQHB_RISK_CHK 실제 작성자 본인의 점수만 매핑 (미입력자는 NULL)]
          ,TO_NUMBER(C.RISK_FREQ)  AS RISK_FREQ   
          ,TO_NUMBER(C.RISK_APRV)  AS RISK_APRV   
          ,TO_NUMBER(C.RISK_CRIT)  AS RISK_CRIT   
          ,C.RISK_GRD                            
          ,TO_NUMBER(C.RISK_FREQ2) AS RISK_FREQ2  
          ,TO_NUMBER(C.RISK_APRV2) AS RISK_APRV2  
          ,TO_NUMBER(C.RISK_CRIT2) AS RISK_CRIT2  
          ,C.RISK_GRD2                            
          ,C.MGR_OPIN               
          ,C.SBM_DT                 
          ,C.SBM_YN                 
      FROM TQHB_RISK_LST A
      -- 1. 해당 조건의 전체 점검자 명단 조인 (점검자 명단 N개 생성)
      INNER JOIN TQHB_RISK_NAM B
        ON A.SIT_CD   = B.SIT_CD
       AND A.PLN_YM   = B.PLN_YM
       AND A.PLN_DGR  = B.PLN_DGR
       AND A.CUST_CD  = B.CUST_CD
       AND A.VNDR_SEQ = B.VNDR_SEQ
      -- 2. 해당 점검자가 실제 점수를 작성했는지 사원번호(EMPE_NO)까지 확인하여 LEFT JOIN
      LEFT JOIN TQHB_RISK_CHK C
        ON A.SIT_CD     = C.SIT_CD
       AND A.PLN_YM     = C.PLN_YM
       AND A.PLN_DGR    = C.PLN_DGR
       AND A.CUST_CD    = C.CUST_CD
       AND A.VNDR_SEQ   = C.VNDR_SEQ
       AND A.CTP_CD     = C.CTP_CD
       AND A.UNT_CD     = C.UNT_CD
       AND A.CHK_ITM_CD = C.CHK_ITM_CD
       AND B.EMPE_NO    = C.EMPE_NO  -- ★ 본인이 작성한 점수만 매핑
     WHERE A.SIT_CD   = p_SIT_CD                      -- 현장코드
	   AND A.PLN_YM   = p_PLN_YM                      -- 계획년월
	   AND A.PLN_DGR  = p_PLN_DGR                     -- 차수구분코드(QS005) 1 1차,2 2차
	   AND A.CUST_CD  = p_CUST_CD                     -- 협력업체코드
	   AND A.VNDR_SEQ = p_VNDR_SEQ                    -- 협력업체순번
	),
	SUMMARY_DATA AS (
	    -- 1. 원래 조회 데이터 (의도된 카티전 곱/다건 출력 유지)
	    SELECT SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CUST_NM
	          ,CTP_CD, UNT_CD, CTP_NM, UNT_NM, CHK_ITM_CD, CHK_ITM_SEQ, CHK_ITM_NM
	          ,CHK_LOC, DISS_SHP, IMPRV_CPLN, WRK_PSNNO, ITM_ADD_YN
	          ,1 AS ROW_DIV
	          ,APRS_NAMSEQ
	          ,EMPE_NO
	          ,CO_DIV_CD
	          ,JB_CD
	          ,JB_NM
	          ,SBM_YN
	          ,USR_NM
	          ,TO_CHAR(RISK_FREQ)  AS RISK_FREQ
	          ,TO_CHAR(RISK_APRV)  AS RISK_APRV
	          ,TO_CHAR(RISK_CRIT)  AS RISK_CRIT
	          ,TO_CHAR(RISK_CRIT2) AS RISK_CRIT2
	          ,MGR_OPIN
	      FROM BASE_DATA
	
	    UNION ALL
	
	    -- 2. 평균점수 행 (각 위험요인 항목별 평균)
	    SELECT SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CUST_NM
	          ,CTP_CD, UNT_CD, CTP_NM, UNT_NM, CHK_ITM_CD, CHK_ITM_SEQ, CHK_ITM_NM
	          ,CHK_LOC, DISS_SHP, IMPRV_CPLN, WRK_PSNNO, ITM_ADD_YN
	          ,2 AS ROW_DIV
	          ,998 AS APRS_NAMSEQ
	          ,NULL AS EMPE_NO
	          ,NULL AS CO_DIV_CD
	          ,NULL AS JB_CD
	          ,NULL AS JB_NM
	          ,NULL AS SBM_YN
	          ,'평균점수' AS USR_NM
	          ,NULL AS RISK_FREQ
	          ,NULL AS RISK_APRV
	          ,TO_CHAR(ROUND(AVG(RISK_CRIT), 1))  AS RISK_CRIT  -- 위험성 평균
	          ,TO_CHAR(ROUND(AVG(RISK_CRIT2), 1)) AS RISK_CRIT2 -- 개선후 위험성 평균
	          ,NULL AS MGR_OPIN
	      FROM BASE_DATA
	     GROUP BY SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CUST_NM
	             ,CTP_CD, UNT_CD, CTP_NM, UNT_NM, CHK_ITM_CD, CHK_ITM_SEQ, CHK_ITM_NM
	             ,CHK_LOC, DISS_SHP, IMPRV_CPLN, WRK_PSNNO, ITM_ADD_YN
	
	    UNION ALL
	
	    -- 3. 최종점수 행 (각 위험요인 항목별 최종)
	    SELECT SIT_CD
	          ,PLN_YM
	          ,PLN_DGR
	          ,CUST_CD
	          ,VNDR_SEQ
	          ,(SELECT CUST_NM FROM VQSZ_TRADE WHERE CUST_CD = A.CUST_CD) AS CUST_NM
	          ,CTP_CD
	          ,UNT_CD
	          ,(SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD) AS CTP_NM
	          ,(SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD) AS UNT_NM
	          ,CHK_ITM_CD
	          ,CHK_ITM_SEQ
	          ,CHK_ITM_NM
	          ,CHK_LOC
	          ,DISS_SHP
	          ,IMPRV_CPLN
	          ,WRK_PSNNO
	          ,ITM_ADD_YN
	          ,3 AS ROW_DIV
	          ,999 AS APRS_NAMSEQ
	          ,NULL AS EMPE_NO
	          ,NULL AS CO_DIV_CD
	          ,NULL AS JB_CD
	          ,NULL AS JB_NM
	          ,NULL AS SBM_YN
	          ,'최종점수' AS USR_NM
	          ,NULL AS RISK_FREQ
	          ,NULL AS RISK_APRV
	          ,TO_CHAR(RISK_CRIT)  AS RISK_CRIT   -- TQHB_RISK_LST의 위험성 점수
	          ,TO_CHAR(RISK_CRIT2) AS RISK_CRIT2  -- TQHB_RISK_LST의 개선후 위험성 점수
	          ,MGR_OPIN
	      FROM TQHB_RISK_LST A
	      WHERE SIT_CD   = p_SIT_CD                      -- 현장코드
	 	    AND PLN_YM   = p_PLN_YM                      -- 계획년월
	   	    AND PLN_DGR  = p_PLN_DGR                     -- 차수구분코드(QS005) 1 1차,2 2차
	   	  	AND CUST_CD  = p_CUST_CD                     -- 협력업체코드
	   		AND VNDR_SEQ = p_VNDR_SEQ                    -- 협력업체순번
	)
	SELECT SIT_CD
	      ,PLN_YM
	      ,PLN_DGR
	      ,CUST_CD
	      ,VNDR_SEQ
	      ,CUST_NM
	      ,CTP_CD
	      ,UNT_CD
	      ,CTP_NM
	      ,UNT_NM
	      ,CHK_ITM_CD
	      ,CHK_ITM_SEQ
	      ,CHK_ITM_NM
	      ,CHK_LOC
	      ,DISS_SHP
	      ,IMPRV_CPLN
	      ,WRK_PSNNO
	      ,ITM_ADD_YN
	      ,RISK_FREQ      -- 빈도 (평균행에는 평균값 표시)
	      ,RISK_APRV      -- 강도 (평균행에는 평균값 표시)
	      ,RISK_CRIT      -- 위험성 (평균/최종행에 표시)
	      ,RISK_CRIT2     -- 개선후 위험성 (평균/최종행에 표시)
	      ,MGR_OPIN
	      ,EMPE_NO
	      ,APRS_NAMSEQ
	      ,CO_DIV_CD
	      ,JB_CD
	      ,JB_NM          -- 직급명
	      ,USR_NM         -- 사용자명/직급명
          ,SBM_YN  
          ,(
          		SELECT SBM_YN
				FROM TQHB_RISK_VNDR
				WHERE 1=1
				AND SIT_CD        = p_SIT_CD
				AND PLN_YM        = p_PLN_YM
				AND PLN_DGR       = p_PLN_DGR
				AND CUST_CD       = p_CUST_CD
				AND VNDR_SEQ      = p_VNDR_SEQ 
           ) AS VNDR_SBM_YN
	  FROM SUMMARY_DATA
	 ORDER BY CTP_CD, UNT_CD, CHK_ITM_CD, DISS_SHP, ROW_DIV, APRS_NAMSEQ
 ;
    
    
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHB_RISK_CHK_S
DROP PROCEDURE "PQHB_RISK_CHK_S";
CREATE PROCEDURE "PQHB_RISK_CHK_S"
                            (p_WRK_TP  VARCHAR2 :='U'                                     -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
                            ,p_WRK_ID  VARCHAR2                                           -- 사용자 ID 
                            ,p_WRK_IP  VARCHAR2                                           -- 사용자 IP 
                            ,p_SIT_CD TQHB_RISK_CHK.SIT_CD%TYPE                           -- 현장코드
                            ,p_PLN_YM TQHB_RISK_CHK.PLN_YM%TYPE                           -- 계획년월
                            ,p_PLN_DGR TQHB_RISK_CHK.PLN_DGR%TYPE                         -- 차수구분코드(QS005) 1 1차,2 2차
                            ,p_CUST_CD TQHB_RISK_CHK.CUST_CD%TYPE                         -- 협력업체코드
                            ,p_VNDR_SEQ TQHB_RISK_CHK.VNDR_SEQ%TYPE                       -- 업체순번
                            ,p_CTP_CD TQHB_RISK_CHK.CTP_CD%TYPE                           -- 공종코드
                            ,p_UNT_CD TQHB_RISK_CHK.UNT_CD%TYPE                           -- 단위코드
                            ,p_CHK_ITM_CD TQHB_RISK_CHK.CHK_ITM_CD%TYPE                   -- 점검항목코드
                            ,p_EMPE_NO TQHB_RISK_CHK.EMPE_NO%TYPE                         -- 사원번호
                            ,p_APRS_NAMSEQ TQHB_RISK_CHK.APRS_NAMSEQ%TYPE                 -- 점검자 정열순서
                            ,p_RISK_FREQ TQHB_RISK_CHK.RISK_FREQ%TYPE                     -- 빈도(QS09003) 작성
                            ,p_RISK_APRV TQHB_RISK_CHK.RISK_APRV%TYPE                     -- 강도(QS09004) 작성
                            ,p_RISK_CRIT TQHB_RISK_CHK.RISK_CRIT%TYPE                     -- 위험성(QS09001) 작성
                            ,p_RISK_GRD TQHB_RISK_CHK.RISK_GRD%TYPE                       -- 위험등급(QS09002) 작성
                            ,p_IMPRV_CPLN TQHB_RISK_CHK.IMPRV_CPLN%TYPE                   -- 개선대책
                            ,p_RISK_FREQ2 TQHB_RISK_CHK.RISK_FREQ2%TYPE                   -- 개선후_빈도(QS09003) 작성
                            ,p_RISK_APRV2 TQHB_RISK_CHK.RISK_APRV2%TYPE                   -- 개선후_강도(QS09004) 작성
                            ,p_RISK_CRIT2 TQHB_RISK_CHK.RISK_CRIT2%TYPE                   -- 개선후_위험성(QS09001) 작성
                            ,p_RISK_GRD2 TQHB_RISK_CHK.RISK_GRD2%TYPE                     -- 개선후_위험등급(QS09002) 작성
                            ,p_DTY_CD TQHB_RISK_CHK.DTY_CD%TYPE                           -- 직책코드
                            ,p_MGR_OPIN TQHB_RISK_CHK.MGR_OPIN%TYPE                       -- 관리자의견
                            ,p_SBM_DT TQHB_RISK_CHK.SBM_DT%TYPE                           -- 제출일자
                            ,p_SBM_YN TQHB_RISK_CHK.SBM_YN%TYPE                           -- 제출1 미제출0
                            )
IS 
    /**************************************************************************************************************************
      Purpose : 

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/08/27 14:48:50                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

	v_CNT NUMBER;
    v_WRK_TP VARCHAR2(1);
BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_YM IS NULL)  THEN
        ERR_MSG := '계획년월는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_DGR IS NULL)  THEN
        ERR_MSG := '차수구분코드(QS005) 1 1차,2 2차는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CUST_CD IS NULL)  THEN
        ERR_MSG := '협력업체코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CTP_CD IS NULL)  THEN
        ERR_MSG := '공종코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_UNT_CD IS NULL)  THEN
        ERR_MSG := '단위코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CHK_ITM_CD IS NULL)  THEN
        ERR_MSG := '점검항목코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;
--
--    IF (p_EMPE_NO IS NULL)  THEN
--        ERR_MSG := '사원번호는(은) 필수 입력사항 입니다.';
--        RAISE USER_EXCEPTION;
--    END IF;

    IF (p_VNDR_SEQ IS NULL)  THEN
        ERR_MSG := '업체순번는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------
    -- TQHB_RISK_CHK 점수등록
    IF (p_EMPE_NO IS NOT NULL)  THEN
    
		SELECT COUNT(1) INTO v_CNT
	          FROM TQHB_RISK_CHK
	         WHERE SIT_CD = p_SIT_CD          --현장코드
	           AND PLN_YM = p_PLN_YM          --계획년월
	           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
	           AND CUST_CD = p_CUST_CD         --협력업체코드
	           AND VNDR_SEQ = p_VNDR_SEQ       --업체순번
	           AND CTP_CD = p_CTP_CD          --공종코드
	           AND UNT_CD = p_UNT_CD          --단위코드
	           AND CHK_ITM_CD = p_CHK_ITM_CD      --점검항목코드
	           AND EMPE_NO = p_EMPE_NO;         --사원번호
	    
		IF (v_CNT > 0)  THEN
	        v_WRK_TP := 'U';
	    ELSE
	    	v_WRK_TP := 'I';
	    END IF;
		
	    ---------------------------------------------------------------------------------------------------------------------------
	    -- ▩▩ [ 4. Business Process ]
	    ---------------------------------------------------------------------------------------------------------------------------
	    IF (v_WRK_TP ='D') THEN
	        DELETE 
	          FROM TQHB_RISK_CHK
	         WHERE SIT_CD = p_SIT_CD          --현장코드
	           AND PLN_YM = p_PLN_YM          --계획년월
	           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
	           AND CUST_CD = p_CUST_CD         --협력업체코드
	           AND VNDR_SEQ = p_VNDR_SEQ       --업체순번
	           AND CTP_CD = p_CTP_CD          --공종코드
	           AND UNT_CD = p_UNT_CD          --단위코드
	           AND CHK_ITM_CD = p_CHK_ITM_CD      --점검항목코드
	           AND EMPE_NO = p_EMPE_NO         --사원번호
	           ;
	
	    ELSIF (v_WRK_TP ='U') THEN
	        UPDATE TQHB_RISK_CHK
	           SET RISK_FREQ            = p_RISK_FREQ               --빈도(QS09003) 작성
	              ,RISK_APRV            = p_RISK_APRV               --강도(QS09004) 작성
	              ,RISK_CRIT            = p_RISK_CRIT               --위험성(QS09001) 작성
	              ,RISK_GRD             = CASE 
											    WHEN TRUNC(TO_NUMBER(p_RISK_CRIT)) BETWEEN 1 AND 5   THEN 'QS0900203'
											    WHEN TRUNC(TO_NUMBER(p_RISK_CRIT)) BETWEEN 6 AND 12  THEN 'QS0900202'
											    WHEN TRUNC(TO_NUMBER(p_RISK_CRIT)) BETWEEN 13 AND 99 THEN 'QS0900201'
											    ELSE NULL
											END
	              ,IMPRV_CPLN           = p_IMPRV_CPLN              --개선대책
	              ,RISK_FREQ2           = p_RISK_FREQ2              --개선후_빈도(QS09003) 작성
	              ,RISK_APRV2           = p_RISK_APRV2              --개선후_강도(QS09004) 작성
	              ,RISK_CRIT2           = p_RISK_CRIT2              --개선후_위험성(QS09001) 작성
	              ,RISK_GRD2            = p_RISK_GRD2               --개선후_위험등급(QS09002) 작성
	              ,MGR_OPIN             = p_MGR_OPIN                --관리자의견
	              ,UPD_ID               = p_WRK_ID                  --수정ID 
	              ,UPD_DTM              = SYSDATE()                 --수정일시
	              ,UPD_IP               = p_WRK_IP                  --수정IP
	         WHERE SIT_CD = p_SIT_CD          --현장코드
	           AND PLN_YM = p_PLN_YM          --계획년월
	           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
	           AND CUST_CD = p_CUST_CD         --협력업체코드
	           AND VNDR_SEQ = p_VNDR_SEQ       --업체순번
	           AND CTP_CD = p_CTP_CD          --공종코드
	           AND UNT_CD = p_UNT_CD          --단위코드
	           AND CHK_ITM_CD = p_CHK_ITM_CD      --점검항목코드
	           AND EMPE_NO = p_EMPE_NO         --사원번호
	           ;
	    
	    ELSE 
	        INSERT INTO TQHB_RISK_CHK
	                   ( SIT_CD                  --현장코드
	                    ,PLN_YM                  --계획년월
	                    ,PLN_DGR                 --차수구분코드(QS005) 1 1차,2 2차
	                    ,CUST_CD                 --협력업체코드
	                    ,VNDR_SEQ                --업체순번
	                    ,CTP_CD                  --공종코드
	                    ,UNT_CD                  --단위코드
	                    ,CHK_ITM_CD              --점검항목코드
	                    ,EMPE_NO                 --사원번호
	                    ,APRS_NAMSEQ             --점검자 정열순서
	                    ,RISK_FREQ               --빈도(QS09003) 작성
	                    ,RISK_APRV               --강도(QS09004) 작성
	                    ,RISK_CRIT               --위험성(QS09001) 작성
	                    ,RISK_GRD                --위험등급(QS09002) 작성
	                    ,IMPRV_CPLN              --개선대책
	                    ,RISK_FREQ2              --개선후_빈도(QS09003) 작성
	                    ,RISK_APRV2              --개선후_강도(QS09004) 작성
	                    ,RISK_CRIT2              --개선후_위험성(QS09001) 작성
	                    ,RISK_GRD2               --개선후_위험등급(QS09002) 작성
	                    ,DTY_CD                  --직책코드
	                    ,MGR_OPIN                --관리자의견
	                    ,SBM_DT                  --제출일자
	                    ,SBM_YN                  --제출1 미제출0
	                    ,IPT_ID                  --입력ID
	                    ,IPT_DTM                 --입력일시
	                    ,IPT_IP                  --입력IP
	                    ,UPD_ID                  --수정ID
	                    ,UPD_DTM                 --수정일시
	                    ,UPD_IP                  --수정IP
						)
	             VALUES (p_SIT_CD                --현장코드
	                    ,p_PLN_YM                --계획년월
	                    ,p_PLN_DGR               --차수구분코드(QS005) 1 1차,2 2차
	                    ,p_CUST_CD               --협력업체코드
	                    ,p_VNDR_SEQ              --업체순번
	                    ,p_CTP_CD                --공종코드
	                    ,p_UNT_CD                --단위코드
	                    ,p_CHK_ITM_CD            --점검항목코드
	                    ,p_EMPE_NO               --사원번호
	                    ,p_APRS_NAMSEQ           --점검자 정열순서
	                    ,p_RISK_FREQ             --빈도(QS09003) 작성
	                    ,p_RISK_APRV             --강도(QS09004) 작성
	                    ,p_RISK_CRIT             --위험성(QS09001) 작성
	                    ,CASE 
						    WHEN TRUNC(TO_NUMBER(p_RISK_CRIT)) BETWEEN 1 AND 5   THEN 'QS0900203'
						    WHEN TRUNC(TO_NUMBER(p_RISK_CRIT)) BETWEEN 6 AND 12  THEN 'QS0900202'
						    WHEN TRUNC(TO_NUMBER(p_RISK_CRIT)) BETWEEN 13 AND 99 THEN 'QS0900201'
						    ELSE NULL
						END
	                    ,p_IMPRV_CPLN            --개선대책
	                    ,p_RISK_FREQ2            --개선후_빈도(QS09003) 작성
	                    ,p_RISK_APRV2            --개선후_강도(QS09004) 작성
	                    ,p_RISK_CRIT2            --개선후_위험성(QS09001) 작성
	                    ,p_RISK_GRD2             --개선후_위험등급(QS09002) 작성
	                    ,p_DTY_CD                --직책코드
	                    ,p_MGR_OPIN              --관리자의견
	                    ,p_SBM_DT                --제출일자
	                    ,p_SBM_YN                --제출1 미제출0
	                    ,p_WRK_ID                --입력ID 
	                    ,SYSDATE()               --입력일시
	                    ,p_WRK_IP                --입력IP
	                    ,p_WRK_ID                --수정ID
	                    ,SYSDATE()               --수정일시
	                    ,p_WRK_IP);              --수정IP
	    END IF;
	    
	    --최종점수 자동등록
	    MERGE INTO TQHB_RISK_LST T
			USING (
			    SELECT SIT_CD
			          ,PLN_YM
			          ,PLN_DGR
			          ,CUST_CD
			          ,VNDR_SEQ
			          ,CTP_CD
			          ,UNT_CD
			          ,CHK_ITM_CD
			          ,ROUND(AVG(TO_NUMBER(RISK_FREQ)), 1)  AS AVG_RISK_FREQ
			          ,ROUND(AVG(TO_NUMBER(RISK_APRV)), 1)  AS AVG_RISK_APRV
			          ,ROUND(AVG(TO_NUMBER(RISK_CRIT)), 1)  AS AVG_RISK_CRIT
			          ,ROUND(AVG(TO_NUMBER(RISK_CRIT2)), 1) AS AVG_RISK_CRIT2
			      FROM TQHB_RISK_CHK
			     WHERE SIT_CD     = p_SIT_CD
			       AND PLN_YM     = p_PLN_YM
			       AND PLN_DGR    = p_PLN_DGR
			       AND CUST_CD    = p_CUST_CD
			       AND VNDR_SEQ   = p_VNDR_SEQ
			       AND CTP_CD     = p_CTP_CD
			       AND UNT_CD     = p_UNT_CD
			       AND CHK_ITM_CD = p_CHK_ITM_CD
			     GROUP BY SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, CTP_CD, UNT_CD, CHK_ITM_CD
			) S
			ON (
			       T.SIT_CD     = S.SIT_CD
			   AND T.PLN_YM     = S.PLN_YM
			   AND T.PLN_DGR    = S.PLN_DGR
			   AND T.CUST_CD    = S.CUST_CD
			   AND T.VNDR_SEQ   = S.VNDR_SEQ
			   AND T.CTP_CD     = S.CTP_CD
			   AND T.UNT_CD     = S.UNT_CD
			   AND T.CHK_ITM_CD = S.CHK_ITM_CD
			)
			WHEN MATCHED THEN
			UPDATE SET 
			    T.RISK_CRIT  = TO_CHAR(S.AVG_RISK_CRIT),
			    T.RISK_CRIT2 = TO_CHAR(S.AVG_RISK_CRIT2),
			    T.RISK_FREQ  = TO_CHAR(S.AVG_RISK_FREQ),
			    T.RISK_APRV  = TO_CHAR(S.AVG_RISK_APRV),
			    T.RISK_GRD   = CASE 
								    WHEN TRUNC(TO_NUMBER(S.AVG_RISK_CRIT)) BETWEEN 1 AND 5   THEN 'QS0900203'
								    WHEN TRUNC(TO_NUMBER(S.AVG_RISK_CRIT)) BETWEEN 6 AND 12  THEN 'QS0900202'
								    WHEN TRUNC(TO_NUMBER(S.AVG_RISK_CRIT)) BETWEEN 13 AND 99 THEN 'QS0900201'
								    ELSE NULL
								END
			    ;
    
    ELSE 
    	--최종점수 수동등록
    	UPDATE TQHB_RISK_LST
           SET 
               RISK_CRIT            = p_RISK_CRIT               --확정_위험성(QS09001) 작성
              ,RISK_CRIT2           = p_RISK_CRIT2              --확정_개선 후 위험성(QS09001) 작성
              ,RISK_GRD   			= CASE 
									    WHEN TRUNC(TO_NUMBER(p_RISK_CRIT)) BETWEEN 1 AND 5   THEN 'QS0900203'
									    WHEN TRUNC(TO_NUMBER(p_RISK_CRIT)) BETWEEN 6 AND 12  THEN 'QS0900202'
									    WHEN TRUNC(TO_NUMBER(p_RISK_CRIT)) BETWEEN 13 AND 99 THEN 'QS0900201'
									    ELSE NULL
									END
              ,MGR_OPIN             = p_MGR_OPIN                --검토의견
              ,UPD_ID               = p_WRK_ID                  --수정ID 
              ,UPD_DTM              = SYSDATE()                 --수정일시
              ,UPD_IP               = p_WRK_IP                  --수정IP 
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND PLN_YM = p_PLN_YM          --계획년월
           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
           AND CUST_CD = p_CUST_CD         --협력업체코드
           AND VNDR_SEQ = p_VNDR_SEQ         --협력업체순번
           AND CTP_CD = p_CTP_CD          --공종코드
           AND UNT_CD = p_UNT_CD          --단위코드
           AND CHK_ITM_CD = p_CHK_ITM_CD;     --점검항목코드
    
    END IF;
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHB_RISK_CHK_W
DROP PROCEDURE "PQHB_RISK_CHK_W";
CREATE PROCEDURE "PQHB_RISK_CHK_W"
                            (p_WRK_TP  VARCHAR2 :='U'                                     -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
                            ,p_WRK_ID  VARCHAR2                                           -- 사용자 ID 
                            ,p_WRK_IP  VARCHAR2                                           -- 사용자 IP 
                            ,p_SIT_CD TQHB_RISK_CHK.SIT_CD%TYPE                           -- 현장코드
                            ,p_PLN_YM TQHB_RISK_CHK.PLN_YM%TYPE                           -- 계획년월
                            ,p_PLN_DGR TQHB_RISK_CHK.PLN_DGR%TYPE                         -- 차수구분코드(QS005) 1 1차,2 2차
                            ,p_CUST_CD TQHB_RISK_CHK.CUST_CD%TYPE                         -- 협력업체코드
                            ,p_VNDR_SEQ TQHB_RISK_CHK.VNDR_SEQ%TYPE                       -- 업체순번
                            ,p_EMPE_NO TQHB_RISK_CHK.EMPE_NO%TYPE                         -- 사원번호
                            ,p_SBM_YN TQHB_RISK_CHK.SBM_YN%TYPE                           -- 제출1 미제출0
                            )
IS 
    /**************************************************************************************************************************
      Purpose : 제출/취소

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/08/27 14:48:50                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

	v_CNT  NUMBER;
	v_CNT2 NUMBER;
	v_CNT3 NUMBER;
    v_WRK_TP VARCHAR2(1);
	
BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_YM IS NULL)  THEN
        ERR_MSG := '계획년월는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_DGR IS NULL)  THEN
        ERR_MSG := '차수구분코드(QS005) 1 1차,2 2차는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CUST_CD IS NULL)  THEN
        ERR_MSG := '협력업체코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_EMPE_NO IS NULL)  THEN
        ERR_MSG := '사원번호는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_VNDR_SEQ IS NULL)  THEN
        ERR_MSG := '업체순번는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------
    
    SELECT COUNT(1) INTO v_CNT
	  FROM TQHB_RISK_CHK
	 WHERE SIT_CD = p_SIT_CD          --현장코드
	   AND PLN_YM = p_PLN_YM          --계획년월
	   AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
	   AND CUST_CD = p_CUST_CD         --협력업체코드
	   AND VNDR_SEQ = p_VNDR_SEQ         
	   AND EMPE_NO = p_EMPE_NO         
	   AND ( RISK_CRIT IS NULL  OR RISK_CRIT = '0'  OR TO_NUMBER(NVL(RISK_CRIT, '0')) = 0
	      OR RISK_CRIT2 IS NULL OR RISK_CRIT2 = '0' OR TO_NUMBER(NVL(RISK_CRIT2, '0')) = 0 )
	      ;
    
    IF (v_CNT > 0)  THEN
        ERR_MSG := '입력하지 않은 점수가 있어 진행할 수 없습니다.';
        RAISE USER_EXCEPTION;
    END IF;
    
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    
    UPDATE TQHB_RISK_CHK
           SET SBM_YN               = p_SBM_YN                  --제출1 미제출0
              ,SBM_DT               = DECODE(p_SBM_YN,'1', TO_CHAR(SYSDATE,'YYYYMMDD'), '') --제출일자 
              ,UPD_ID               = p_WRK_ID                  --수정ID 
              ,UPD_DTM              = SYSDATE()                 --수정일시
              ,UPD_IP               = p_WRK_IP                  --수정IP
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND PLN_YM = p_PLN_YM          --계획년월
           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
           AND CUST_CD = p_CUST_CD         --협력업체코드
           AND VNDR_SEQ = p_VNDR_SEQ       --업체순번
           AND EMPE_NO = p_EMPE_NO         --사원번호
    ;
    
    
     SELECT COUNT(1) INTO v_CNT2
      FROM TQHB_RISK_CHK
     WHERE SIT_CD = p_SIT_CD          --현장코드
       AND PLN_YM = p_PLN_YM          --계획년월
       AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
       AND CUST_CD = p_CUST_CD         --협력업체코드
       AND VNDR_SEQ = p_VNDR_SEQ         --공종코드
       AND (SBM_YN IS NULL OR SBM_YN != '1')
       ;
    
     
	  SELECT NAM.CNT - CHK.CNT INTO v_CNT3
	  FROM (
	        /* TQHB_RISK_CHK 그룹화 카운트 */
	        SELECT COUNT(1) AS CNT
	          FROM (
	                SELECT SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, EMPE_NO
	                  FROM TQHB_RISK_CHK
	                 WHERE SIT_CD   = p_SIT_CD
	                   AND PLN_YM   = p_PLN_YM
	                   AND PLN_DGR  = p_PLN_DGR
	                   AND CUST_CD  = p_CUST_CD
	                   AND VNDR_SEQ = p_VNDR_SEQ
	                 GROUP BY SIT_CD, PLN_YM, PLN_DGR, CUST_CD, VNDR_SEQ, EMPE_NO
	               )
	       ) CHK,
	       (
	        /* TQHB_RISK_NAM 전체 카운트 */
	        SELECT COUNT(1) AS CNT
	          FROM TQHB_RISK_NAM
	         WHERE SIT_CD   = p_SIT_CD
	           AND PLN_YM   = p_PLN_YM
	           AND PLN_DGR  = p_PLN_DGR
	           AND CUST_CD  = p_CUST_CD
	           AND VNDR_SEQ = p_VNDR_SEQ
	       ) NAM;
     
	  
     IF (v_CNT3 = 0 AND v_CNT2 <= 0)  THEN
         UPDATE TQHB_RISK_VNDR
           SET SBM_YN               = p_SBM_YN                  --제출1 미제출0
              ,SBM_DT               = DECODE(p_SBM_YN,'1', TO_CHAR(SYSDATE,'YYYYMMDD'), '') --제출일자
              ,UPD_ID               = p_WRK_ID                  --수정ID 
              ,UPD_DTM              = SYSDATE()                 --수정일시
              ,UPD_IP               = p_WRK_IP                  --수정IP
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND PLN_YM = p_PLN_YM          --계획년월
           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
           AND CUST_CD = p_CUST_CD         --협력업체코드
           AND VNDR_SEQ = p_VNDR_SEQ         --공종코드           
	    ;
     
     ELSE
     
     	UPDATE TQHB_RISK_VNDR
           SET SBM_YN               = ''
              ,SBM_DT               = ''
              ,UPD_ID               = p_WRK_ID                  --수정ID 
              ,UPD_DTM              = SYSDATE()                 --수정일시
              ,UPD_IP               = p_WRK_IP                  --수정IP
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND PLN_YM = p_PLN_YM          --계획년월
           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
           AND CUST_CD = p_CUST_CD         --협력업체코드
           AND VNDR_SEQ = p_VNDR_SEQ         --공종코드           
	    ;
     END IF;
	    
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHB_RISK_DGR_Q
DROP PROCEDURE "PQHB_RISK_DGR_Q";
CREATE PROCEDURE "PQHB_RISK_DGR_Q" (  
						     p_WRK_TP  VARCHAR2 :='Q'                                     -- 
                            ,p_WRK_ID  VARCHAR2                                           -- 사용자 ID 
                            ,p_WRK_IP  VARCHAR2                                           -- 사용자 IP 
							,p_SIT_CD TQHB_RISK_DGR.SIT_CD%TYPE                           -- 현장코드
                            ,p_PLN_YM TQHB_RISK_DGR.PLN_YM%TYPE                           -- 계획년월
                            ,p_PLN_DGR TQHB_RISK_DGR.PLN_DGR%TYPE                         -- 차수구분코드(QS005) 1 1차,2 2차
							,RTN_CURSOR      OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [위험성평가차수 조회] 

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2023/12/04                                 최초생성  

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR 
        SELECT  
		        SIT_CD
		       ,PLN_YM                 --계획년월
		       ,PLN_DGR                 --차수구분코드(QS005) 1 1차,2 2차
		       , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.PLN_DGR AND HRNK_CD = 'QS005' ) AS PLN_DGR_NM -- 계획차수명
		       ,APRS_STR_DT                 --평가시작일자
		       ,APRS_END_DT                 --평가종료일자
		       ,VNDR_CMPL_DT                 --업체작성완료일자
		       ,CONF_SCH_DT                 --회의예정일자
		       ,AREC_CTS                 --회의록내용
		       ,AREC_ATFL_GRP                 --회의록첨부파일그룹
		       ,PHOTO_GRP1                 --첨부파일그룹사진1
		       ,PHOTO_DESC_1                 --사진설명1
		       ,PHOTO_GRP2                 --첨부파일그룹사진2
		       ,PHOTO_DESC_2                 --사진설명2
		       ,CONF_DT                 --회의일자
		       ,CONF_PLC                 --회의장소
		       ,AM_NOTICE                 --공지사항
		       ,AREC_NAM                 --회의명
		       ,EMPE_NO_SAFT                 --안전관리자 사원번호
		       ,SAFT_MGR_YN                 --안전관리자(승인1 미승인0)
		       ,SAFT_MGR_DT                 --안전관리자 승인/반려일자
		       ,DECODE(SAFT_MGR_YN,'1',SAFT_MGR_DT,'') AS SAFT_MGR_DT_NM
		       ,SAFT_MGR_OPIN                 --안전관리자 승인/반려의견
		       ,EMPE_NO_OMGR                 --현장소장 사원번호
		       ,SITE_OMGR_YN                 --현장소장(승인1 미승인0)
		       ,SITE_OMGR_DT                 --현장소장 승인/반려일자
		       ,DECODE(SITE_OMGR_YN,'1',SITE_OMGR_DT,'') AS SITE_OMGR_DT_NM
		       ,SITE_OMGR_OPIN                 --현장소장 승인/반려의견
		       ,DECODE(SITE_OMGR_YN,'1','승인','') AS SITE_OMGR_YN_NM
		       ,(SELECT LISTAGG(CUST_CD, ',') WITHIN GROUP (ORDER BY CUST_CD)
		         FROM TQHB_RISK_VNDR
		         WHERE SIT_CD = A.SIT_CD
		         AND PLN_YM = A.PLN_YM
		         AND PLN_DGR = A.PLN_DGR
		        ) AS CUST_CD_LIST
		 FROM TQHB_RISK_DGR A
         WHERE A.SIT_CD = p_SIT_CD
         ORDER BY A.PLN_YM DESC, A.PLN_DGR DESC
        ;
                
    ELSIF p_WRK_TP = 'Q2' THEN

        OPEN RTN_CURSOR FOR 
        SELECT  
        	    SIT_CD
	           ,PLN_YM                 --계획년월
	           ,PLN_DGR                 --차수구분코드(QS005) 1 1차,2 2차
	           , ( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.PLN_DGR AND HRNK_CD = 'QS005' ) AS PLN_DGR_NM -- 계획차수명
	           ,APRS_STR_DT                 --평가시작일자
	           ,APRS_END_DT                 --평가종료일자
	           ,TO_CHAR(TO_DATE(APRS_STR_DT,'YYYYMMDD'),'YYYY-MM-dd') AS APRS_STR_DT_NM
	           ,TO_CHAR(TO_DATE(APRS_END_DT,'YYYYMMDD'),'YYYY-MM-dd') AS APRS_END_DT_NM
	           ,VNDR_CMPL_DT                 --업체작성완료일자
	           ,CONF_SCH_DT                 --회의예정일자
	           ,AREC_CTS                 --회의록내용
	           ,AREC_ATFL_GRP                 --회의록첨부파일그룹
	           ,PHOTO_GRP1                 --첨부파일그룹사진1
	           ,PHOTO_DESC_1                 --사진설명1
	           ,PHOTO_GRP2                 --첨부파일그룹사진2
	           ,PHOTO_DESC_2                 --사진설명2
	           ,TO_CHAR(TO_DATE(APRS_END_DT,'YYYYMMDD'),'YYYY-MM-dd') AS CONF_DT
	           ,CONF_PLC                 --회의장소
	           ,AM_NOTICE                 --공지사항
	           ,AREC_NAM                 --회의명
	           ,EMPE_NO_SAFT                 --안전관리자 사원번호
	           ,SAFT_MGR_YN                 --안전관리자(승인1 미승인0)
	           ,SAFT_MGR_DT                 --안전관리자 승인/반려일자
	           ,SAFT_MGR_OPIN                 --안전관리자 승인/반려의견
	           ,EMPE_NO_OMGR                 --현장소장 사원번호
	           ,SITE_OMGR_YN                 --현장소장(승인1 미승인0)
	           ,SITE_OMGR_DT                 --현장소장 승인/반려일자
	           ,SITE_OMGR_OPIN                 --현장소장 승인/반려의견
	           ,DECODE(SITE_OMGR_YN,'1','승인','') AS SITE_OMGR_YN_NM
	           ,SUBSTR(PLN_YM, 1, 4) || '년 ' || SUBSTR(PLN_YM, 5, 2) || '월 ' || PLN_DGR || '차 위험성평가' AS AREC_DGR
	           ,(
	           		 SELECT JB_CD
					  FROM TQHA_SITENAM
					 WHERE 1=1
					   AND SIT_CD    = A.SIT_CD
					   AND EMPE_NO   = p_WRK_ID
	            ) AS JB_CD
	            ,(
	            	SELECT CASE 
				         WHEN COUNT(*) > 0 AND COUNT(*) = COUNT(CASE WHEN SBM_YN = '1' THEN 1 END) 
				         THEN '1' -- 전체가 1임
				         ELSE '0' -- 1이 아닌 값이 섞여 있거나 데이터가 없음
				       END AS ALL_SBM_YN
				  FROM TQHB_RISK_VNDR
				 WHERE SIT_CD = A.SIT_CD          
				   AND PLN_YM = A.PLN_YM          
				   AND PLN_DGR = A.PLN_DGR
	            ) AS VNDR_SBM_YN
          FROM TQHB_RISK_DGR A
         WHERE A.SIT_CD = p_SIT_CD
           AND A.PLN_YM = p_PLN_YM
           AND A.PLN_DGR = p_PLN_DGR
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END PQHB_RISK_DGR_Q;
/

-- PQHB_RISK_LST_S
DROP PROCEDURE "PQHB_RISK_LST_S";
CREATE PROCEDURE "PQHB_RISK_LST_S"
                            (p_WRK_TP  VARCHAR2 :='U'                                     -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
                            ,p_WRK_ID  VARCHAR2                                           -- 사용자 ID 
                            ,p_WRK_IP  VARCHAR2                                           -- 사용자 IP 
                            ,p_SIT_CD TQHB_RISK_LST.SIT_CD%TYPE                           -- 현장코드
                            ,p_PLN_YM TQHB_RISK_LST.PLN_YM%TYPE                           -- 계획년월
                            ,p_PLN_DGR TQHB_RISK_LST.PLN_DGR%TYPE                         -- 차수구분코드(QS005) 1 1차,2 2차
                            ,p_CUST_CD TQHB_RISK_LST.CUST_CD%TYPE                         -- 협력업체코드
                            ,p_VNDR_SEQ TQHB_RISK_LST.VNDR_SEQ%TYPE                       -- 업체순번
                            ,p_CTP_CD TQHB_RISK_LST.CTP_CD%TYPE                           -- 공종코드
                            ,p_UNT_CD TQHB_RISK_LST.UNT_CD%TYPE                           -- 단위코드
                            ,p_CHK_ITM_CD TQHB_RISK_LST.CHK_ITM_CD%TYPE                   -- 점검항목코드
                            ,p_CHK_ITM_SEQ TQHB_RISK_LST.CHK_ITM_SEQ%TYPE                 -- 점검항목 정열순서
                            ,p_CHK_ITM_NM TQHB_RISK_LST.CHK_ITM_NM%TYPE                   -- 점검항목명
                            ,p_CHK_LOC TQHB_RISK_LST.CHK_LOC%TYPE                         -- 점검위치
                            ,p_DISS_SHP TQHB_RISK_LST.DISS_SHP%TYPE                       -- 재해형태(QS036)
                            ,p_RISK_FREQ TQHB_RISK_LST.RISK_FREQ%TYPE                     -- 확정_빈도(QS09003) 작성
                            ,p_RISK_APRV TQHB_RISK_LST.RISK_APRV%TYPE                     -- 확정_강도(QS09004) 작성
                            ,p_RISK_CRIT TQHB_RISK_LST.RISK_CRIT%TYPE                     -- 확정_위험성(QS09001) 작성
                            ,p_RISK_GRD TQHB_RISK_LST.RISK_GRD%TYPE                       -- 확정_위험등급(QS09002) 작성
                            ,p_IMPRV_CPLN TQHB_RISK_LST.IMPRV_CPLN%TYPE                   -- 개선대책
                            ,p_WRK_PSNNO TQHB_RISK_LST.WRK_PSNNO%TYPE                     -- 작업인원
                            ,p_ITM_ADD_YN TQHB_RISK_LST.ITM_ADD_YN%TYPE)                  -- 기존 : 0, 추가 : 1
IS 
    /**************************************************************************************************************************
      Purpose : 위험성평가표작성 저장

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/08/03 08:52:39                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;


BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_YM IS NULL)  THEN
        ERR_MSG := '계획년월는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_DGR IS NULL)  THEN
        ERR_MSG := '차수구분코드(QS005) 1 1차,2 2차는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CUST_CD IS NULL)  THEN
        ERR_MSG := '협력업체코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_UNT_CD IS NULL)  THEN
        ERR_MSG := '단위코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CHK_ITM_CD IS NULL)  THEN
        ERR_MSG := '점검항목코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN
        DELETE 
          FROM TQHB_RISK_LST
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND PLN_YM = p_PLN_YM          --계획년월
           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
           AND CUST_CD = p_CUST_CD         --협력업체코드
           AND VNDR_SEQ = p_VNDR_SEQ         --협력업체순번
           AND CTP_CD = p_CTP_CD          --공종코드
           AND UNT_CD = p_UNT_CD          --단위코드
           AND CHK_ITM_CD = p_CHK_ITM_CD;     --점검항목코드

    ELSIF (p_WRK_TP ='U') THEN
        UPDATE TQHB_RISK_LST
           SET CHK_ITM_SEQ          = p_CHK_ITM_SEQ             --점검항목 정열순서
              ,CHK_ITM_NM           = p_CHK_ITM_NM              --점검항목명
              ,CHK_LOC              = p_CHK_LOC                 --점검위치
              ,DISS_SHP             = p_DISS_SHP                --재해형태(QS036)
              ,IMPRV_CPLN           = p_IMPRV_CPLN              --개선대책
              ,WRK_PSNNO            = p_WRK_PSNNO               --작업인원
              ,ITM_ADD_YN           = p_ITM_ADD_YN              --기존 : 0, 추가 : 1
              ,UPD_ID               = p_WRK_ID                  --수정ID 
              ,UPD_DTM              = SYSDATE()                 --수정일시
              ,UPD_IP               = p_WRK_IP                  --수정IP
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND PLN_YM = p_PLN_YM          --계획년월
           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
           AND CUST_CD = p_CUST_CD         --협력업체코드
           AND VNDR_SEQ = p_VNDR_SEQ         --협력업체순번
           AND CTP_CD = p_CTP_CD          --공종코드
           AND UNT_CD = p_UNT_CD          --단위코드
           AND CHK_ITM_CD = p_CHK_ITM_CD;     --점검항목코드
    ELSE 
        INSERT INTO TQHB_RISK_LST
                   ( SIT_CD                  --현장코드
                    ,PLN_YM                  --계획년월
                    ,PLN_DGR                 --차수구분코드(QS005) 1 1차,2 2차
                    ,CUST_CD                 --협력업체코드
                    ,VNDR_SEQ
                    ,CTP_CD                  --공종코드
                    ,UNT_CD                  --단위코드
                    ,CHK_ITM_CD              --점검항목코드
                    ,CHK_ITM_SEQ             --점검항목 정열순서
                    ,CHK_ITM_NM              --점검항목명
                    ,CHK_LOC                 --점검위치
                    ,DISS_SHP                --재해형태(QS036)
                    ,RISK_FREQ               --확정_빈도(QS09003) 작성
                    ,RISK_APRV               --확정_강도(QS09004) 작성
                    ,RISK_CRIT               --확정_위험성(QS09001) 작성
                    ,RISK_GRD                --확정_위험등급(QS09002) 작성
                    ,IMPRV_CPLN              --개선대책
                    ,WRK_PSNNO               --작업인원
                    ,ITM_ADD_YN              --기존 : 0, 추가 : 1
                    ,IPT_ID                  --입력ID
                    ,IPT_DTM                 --입력일시
                    ,IPT_IP                  --입력IP
                    ,UPD_ID                  --수정ID
                    ,UPD_DTM                 --수정일시
                    ,UPD_IP                  --수정IP
                    )
             VALUES (p_SIT_CD                --현장코드
                    ,p_PLN_YM                --계획년월
                    ,p_PLN_DGR               --차수구분코드(QS005) 1 1차,2 2차
                    ,p_CUST_CD               --협력업체코드
                    ,p_VNDR_SEQ
                    ,p_CTP_CD                --공종코드
                    ,p_UNT_CD                --단위코드
                    ,p_CHK_ITM_CD            --점검항목코드
                    ,p_CHK_ITM_SEQ           --점검항목 정열순서
                    ,p_CHK_ITM_NM            --점검항목명
                    ,p_CHK_LOC               --점검위치
                    ,p_DISS_SHP              --재해형태(QS036)
                    ,p_RISK_FREQ             --확정_빈도(QS09003) 작성
                    ,p_RISK_APRV             --확정_강도(QS09004) 작성
                    ,p_RISK_CRIT             --확정_위험성(QS09001) 작성
                    ,p_RISK_GRD              --확정_위험등급(QS09002) 작성
                    ,p_IMPRV_CPLN            --개선대책
                    ,p_WRK_PSNNO             --작업인원
                    ,p_ITM_ADD_YN            --기존 : 0, 추가 : 1
                    ,p_WRK_ID                --입력ID 
                    ,SYSDATE()               --입력일시
                    ,p_WRK_IP                --입력IP
                    ,p_WRK_ID                --수정ID
                    ,SYSDATE()               --수정일시
                    ,p_WRK_IP);              --수정IP
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHB_RISK_NAM_Q
DROP PROCEDURE "PQHB_RISK_NAM_Q";
CREATE PROCEDURE "PQHB_RISK_NAM_Q"
(
      p_WRK_TP  VARCHAR2 DEFAULT 'Q'                                                       -- FLAG( Q: SELECT )
     ,p_SIT_CD TQHB_RISK_NAM.SIT_CD%TYPE                                                  -- 현장코드
     ,p_PLN_YM TQHB_RISK_NAM.PLN_YM%TYPE                                                  -- 계획년월
     ,p_PLN_DGR TQHB_RISK_NAM.PLN_DGR%TYPE                                                -- 차수구분코드(QS005) 1 1차,2 2차
     ,p_CUST_CD TQHB_RISK_NAM.CUST_CD%TYPE                                                -- 협력업체코드
     ,p_EMPE_NO TQHB_RISK_NAM.EMPE_NO%TYPE                                                -- 사원번호
     ,p_VNDR_SEQ VARCHAR2                                                                 -- 업체순번
     ,RTN_CURSOR OUT SYS_REFCURSOR
)
IS 
    /**************************************************************************************************************************
      Purpose : 위험성평가 평가자 - 조회

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/07/29 16:08:42                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;


BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------
	
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리
    ---------------------------------------------------------------------------------------------------------------------------

    OPEN RTN_CURSOR FOR
    SELECT  A.SIT_CD                 --현장코드
           ,A.PLN_YM                 --계획년월
           ,A.PLN_DGR                 --차수구분코드(QS005) 1 1차,2 2차
           ,A.CUST_CD                 --협력업체코드
           ,A.VNDR_SEQ
           ,A.EMPE_NO                 --사원번호
           , CASE WHEN CO_DIV_CD = '1' THEN (SELECT USR_NM FROM TCOZ_USR_INFO WHERE EMPNO = A.EMPE_NO)
                  WHEN CO_DIV_CD = '2' THEN B.PNM
             END AS USR_NM
           ,A.APRS_NAMSEQ             --정열순서
           ,A.DTY_CD                 --직책코드
           , CASE WHEN CO_DIV_CD = '1' THEN FHRZ_GETCDNAME(A.DTY_CD, 'HRZ0EF')
                  WHEN CO_DIV_CD = '2' THEN B.DTY_NM
             END AS DTY_NM
           ,A.CO_DIV_CD
           ,A.JB_CD
           , NVL((SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.JB_CD AND HRNK_CD = 'QS077' AND USE_YN = '1'),'') AS JB_NM
           ,(
           		SELECT COUNT(1)
		          FROM TQHB_RISK_CHK
		         WHERE SIT_CD = A.SIT_CD
		           AND PLN_YM = A.PLN_YM
		           AND PLN_DGR = A.PLN_DGR
		           AND CUST_CD = A.CUST_CD
		           AND VNDR_SEQ = A.VNDR_SEQ
		           AND EMPE_NO = A.EMPE_NO
		           AND SBM_YN = '1'
            ) AS SBM_CNT
      FROM TQHB_RISK_NAM A,
           (
           	 SELECT *
			  FROM TQHB_VNDRNAM
			 WHERE 1=1
			   AND SIT_CD    = p_SIT_CD
			   AND CUST_CD   = p_CUST_CD
			   AND VNDR_SEQ  = p_VNDR_SEQ
           ) B
    WHERE 1=1
      AND A.EMPE_NO = B.EMPE_NO(+)
      AND A.SIT_CD = p_SIT_CD                     --현장코드
      AND A.PLN_YM = p_PLN_YM                     --계획년월
      AND A.PLN_DGR = p_PLN_DGR                     --차수구분코드(QS005) 1 1차,2 2차
      AND A.CUST_CD = p_CUST_CD                     --협력업체코드
      AND A.VNDR_SEQ = p_VNDR_SEQ                     
    ORDER BY A.APRS_NAMSEQ
    ;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHB_RISK_SCHD_MNG_CO_Q
DROP PROCEDURE "PQHB_RISK_SCHD_MNG_CO_Q";
CREATE PROCEDURE "PQHB_RISK_SCHD_MNG_CO_Q" (
    p_WRK_TP            IN VARCHAR2 DEFAULT 'Q'             -- FLAG(Q: 현장평가, Q1:본사평가)
,   p_SIT_CD            IN VARCHAR2                         -- 현장코드
,   p_CUST_CD           IN VARCHAR2                         -- 고객코드
,   p_VNDR_SEQ          IN VARCHAR2                         -- 업체순번
,   p_PLN_YM            IN VARCHAR2                         -- 계획년월
,   p_PLN_DGR           IN VARCHAR2                         -- 계획차수
,   p_CTP_CD            IN VARCHAR2                         -- 공종코드 
,   p_UNT_CD            IN VARCHAR2                         -- 단위코드
,   RTN_CURSOR       OUT SYS_REFCURSOR
) 
IS

    /**************************************************************************************************************************
      Purpose : 파트너 위험성평가등록 

      REVISIONS
      Ver      Date               Author                  Description
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      2026/02/27                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    -- 그리드 조회 : 위험성평가 목록 (현장)
    IF p_WRK_TP = 'Q1' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                  --현장코드
             , A.PLN_YM                   --계획년월
             , A.PLN_DGR                  --계획차수
             ,( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.PLN_DGR AND HRNK_CD = 'QS005') AS PLN_DGR_NM  -- 계획차수명칭
             , B.APRS_STR_DT              --평가시작일
             , B.APRS_END_DT              --평가종료일
             , B.VNDR_CMPL_DT             --업체작성완료일자
             , B.CONF_SCH_DT              --회의예정일자
             , A.SBM_YN                   --평가서제출여부
             , DECODE(NVL(A.SBM_YN,0), '1', '제출', '작성중') AS SBM_NM -- 제출여부명칭
             , A.SBM_DT                   --평가서제출일자
             , A.CUST_CD                  --협력업체코드
             , ( SELECT CUST_NM FROM VQSZ_TRADE WHERE CUST_CD = A.CUST_CD ) AS VNDR_NM --협력업체명
             , A.VNDR_SEQ                 --협력업체차수
             , A.CHK_ATFL_GRP             --첨부파일그룹
          FROM TQHB_RISK_VNDR A
             , TQHB_RISK_DGR B
         WHERE A.SIT_CD         =  B.SIT_CD
           AND A.PLN_YM         = B.PLN_YM
           AND A.PLN_DGR        = B.PLN_DGR
           AND A.SIT_CD         = p_SIT_CD
           AND A.CUST_CD        = p_CUST_CD
           AND A.VNDR_SEQ       = p_VNDR_SEQ
           AND A.OBJ_YN         = '1'           -- 대상유무
           AND (NVL(p_PLN_YM, '*') = '*'     OR A.PLN_YM     = p_PLN_YM)
           AND (NVL(p_PLN_DGR, '*') = '*'    OR A.PLN_DGR    = p_PLN_DGR)
         ORDER BY A.PLN_YM DESC, A.PLN_DGR DESC
        ;

    -- 그리드 조회 : 위험성평가 목록 (본사)
    ELSIF p_WRK_TP = 'Q1_H' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD                  --현장코드
             , A.PLN_YM                   --계획년월
             , A.PLN_DGR                  --계획차수
             ,( SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.PLN_DGR AND HRNK_CD = 'QS005') AS PLN_DGR_NM  -- 계획차수명칭
             , B.APRS_STR_DT              --평가시작일
             , B.APRS_END_DT              --평가종료일
             , B.VNDR_CMPL_DT             --업체작성완료일자
             , B.CONF_SCH_DT              --회의예정일자
             , A.SBM_YN                   --평가서제출여부
             , DECODE(NVL(A.SBM_YN,0), '1', '제출', '작성중') AS SBM_NM -- 제출여부명칭
             , A.SBM_DT                   --평가서제출일자
             , A.CUST_CD                  --협력업체코드
             , ( SELECT CUST_NM FROM VQSZ_TRADE WHERE CUST_CD = A.CUST_CD ) AS VNDR_NM --협력업체명
             , A.VNDR_SEQ                 --협력업체차수
             , A.CHK_ATFL_GRP             --첨부파일그룹
          FROM TQHB_RISK_VNDR A
             , TQHB_RISK_DGR B
         WHERE A.SIT_CD         =  B.SIT_CD
           AND A.PLN_YM         = B.PLN_YM
           AND A.PLN_DGR        = B.PLN_DGR 
           AND A.SIT_CD         = p_SIT_CD
           AND A.OBJ_YN         = '1'           -- 대상유무
           AND (NVL(p_PLN_YM, '*') = '*'     OR A.PLN_YM     = p_PLN_YM)
           AND (NVL(p_PLN_DGR, '*') = '*'    OR A.PLN_DGR    = p_PLN_DGR)
         ORDER BY A.PLN_YM DESC, A.PLN_DGR DESC
        ;
    --------------------------------------------------------------------------------
    -- 그리드 조회 : 위험성평가 작성
    ELSIF p_WRK_TP = 'Q2' THEN

        OPEN RTN_CURSOR FOR
        SELECT 
            SIT_CD                 --현장코드
           ,PLN_YM                 --계획년월
           ,PLN_DGR                 --차수구분코드(QS005) 1 1차,2 2차
           ,CTP_CD           -- 공종코드
           ,( SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD ) AS CTP_NM    -- 공종명칭
           ,UNT_CD           -- 단위코드
           ,( SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD ) AS UNT_NM    -- 단위명칭
           ,CHK_ITM_CD                 --점검항목코드
           ,EMPE_NO                 --사원번호
           ,APRS_NAMSEQ                 --점검자 정열순서
           ,RISK_FREQ                 --빈도(QS09003) 작성
           ,RISK_APRV                 --강도(QS09004) 작성
           ,RISK_CRIT                 --위험성(QS09001) 작성
           ,RISK_GRD                 --위험등급(QS09002) 작성
           ,IMPRV_CPLN                 --개선대책
           ,RISK_FREQ2                 --개선후_빈도(QS09003) 작성
           ,RISK_APRV2                 --개선후_강도(QS09004) 작성
           ,RISK_CRIT2                 --개선후_위험성(QS09001) 작성
           ,RISK_GRD2                 --개선후_위험등급(QS09002) 작성
           ,DTY_CD                 --직책코드
           ,MGR_OPIN                 --관리자의견
           ,SBM_DT                 --제출일자
           ,SBM_YN                 --제출1 미제출0
           ,VNDR_SEQ                 --업체순번
           ,(SELECT DECODE(COUNT(1),0,'중흥','협력사') FROM TQHA_VNDR WHERE SIT_CD = A.SIT_CD AND VNDR_PSN_ID = A.IPT_ID) AS REG_DIV
          FROM TQHB_RISK_CHK A
         WHERE A.SIT_CD     = p_SIT_CD
           AND A.PLN_YM     = p_PLN_YM
           AND A.PLN_DGR    = p_PLN_DGR
           AND A.CUST_CD    = p_CUST_CD
           AND A.VNDR_SEQ   = p_VNDR_SEQ
        ;

    --------------------------------------------------------------------------------
    -- 그리드 조회 : 위험요인항목 추가 - 공종별 단위작업 리스트 (트리)
    ELSIF p_WRK_TP = 'Q3' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.CTP_CD   -- 상위공종코드
             , A.UNT_CD   -- 단위작업코드
             , A.CTP_NM   -- 단위작업명칭
             , A.USE_YN
             , A."Level"
          FROM ( SELECT CTP_CD         -- 공종코드
                      , ' ' AS UNT_CD  -- 단위작업코드
                      , CTP_NM         -- 공종명칭
                      , USE_YN         -- 공종 사용유무
                      , '1' AS "Level" -- 레벨1
                   FROM TQHA_CTP
                  WHERE USE_YN = '1'
                  UNION ALL
                 SELECT CTP_CD          -- 상위공종코드
                      , UNT_CD          -- 단위작업코드
                      , UNT_NM          -- 단위작업명칭
                      , USE_YN          -- 단위작업사용유무
                      , '2'  AS "Level" -- 레벨 2
                   FROM TQHA_CTPUNT 
                  WHERE USE_YN = '1') A
         ORDER BY A.CTP_CD, A.UNT_CD ASC
        ;

    --------------------------------------------------------------------------------
    -- 그리드 조회 : 위험요인항목 추가 - 위험요인항목
    ELSIF p_WRK_TP = 'Q4' THEN

        OPEN RTN_CURSOR FOR

        SELECT A.CTP_CD      -- 상위공종코드
             , ( SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD ) AS CTP_NM    -- 공종명칭
             , A.UNT_CD      -- 단위작업코드
             , ( SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD ) AS UNT_NM    -- 단위명칭
             , A.CHK_ITM_CD  -- 점검항목코드
             , A.CHK_ITM_NM  -- 점검항목명칭
             , A.RISK_FREQ   -- 빈도레벨(QS003)
             , A.RISK_APRV   -- 강도레벨(QS004)  
             , A.RISK_CRIT   -- 위험성(공통코드 QS063)
             , A.RISK_GRD    -- 위험등급(QS024)
             , A.IMPRV_CPLN  -- 개선대책
             , A.USE_YN      -- 단위작업사용유무
             , A.CUST_CD     -- 업체코드
             , A.USR_DEFN_YN -- 사용자정의 구분
             , A.DISS_SHP    -- 재해형태(QS036)
          FROM TQHB_CTPUNT_CHKITM A
         WHERE A.USR_DEFN_YN    = '0'
           AND A.CTP_CD         = p_CTP_CD
           AND A.UNT_CD         = p_UNT_CD
        ;

    --------------------------------------------------------------------------------
    -- 그리드 조회 : 위험요인항목 추가 - 사용자정의 위험요인항목 
    ELSIF p_WRK_TP = 'Q5' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.CTP_CD      -- 상위공종코드
             , ( SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD ) AS CTP_NM    -- 공종명칭
             , A.UNT_CD      -- 단위작업코드
             , ( SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD ) AS UNT_NM    -- 단위명칭
             , A.CHK_ITM_CD  -- 점검항목코드
             , A.CHK_ITM_NM  -- 점검항목명칭
             , A.RISK_FREQ   -- 빈도레벨(QS003)
             , A.RISK_APRV   -- 강도레벨(QS004)
             , A.RISK_CRIT   -- 위험성(공통코드 QS063)
             , A.RISK_GRD    -- 위험등급(QS024)
             , A.IMPRV_CPLN  -- 개선대책
             , A.USE_YN      -- 단위작업사용유무
             , A.CUST_CD     -- 업체코드
             , A.USR_DEFN_YN -- 사용자정의 구분
             , A.DISS_SHP    -- 재해형태(QS036)
          FROM TQHB_CTPUNT_CHKITM A
         WHERE A.USR_DEFN_YN = '1'
           AND A.CTP_CD     = p_CTP_CD
           AND A.UNT_CD     = p_UNT_CD
           AND A.CUST_CD    = p_CUST_CD
        ;

    --------------------------------------------------------------------------------
    -- 위험성평가 평가서제출 여부 조회
    ELSIF p_WRK_TP = 'Q6' THEN

        OPEN RTN_CURSOR FOR
        SELECT SBM_YN
             --, MNG_APRV_STATS
          FROM TQHB_RISK_VNDR
         WHERE SIT_CD       = p_SIT_CD
           AND PLN_DGR      = p_PLN_DGR
           AND PLN_YM       = p_PLN_YM
           AND CUST_CD      = p_CUST_CD
           AND VNDR_SEQ     = p_VNDR_SEQ
        ;

    --------------------------------------------------------------------------------
    -- 전회차복사 목록 조회
    ELSIF p_WRK_TP = 'Q7' THEN

        OPEN RTN_CURSOR FOR
         SELECT  SIT_CD                 --현장코드
	           ,PLN_YM                 --계획년월
	           ,PLN_DGR                 --차수구분코드(QS005) 1 1차,2 2차
	           ,CUST_CD                 --협력업체코드
	           ,VNDR_SEQ                 --업체순번
	           ,CTP_CD           -- 공종코드
	           ,( SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD ) AS CTP_NM    -- 공종명칭
	           ,UNT_CD           -- 단위코드
	           ,( SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD ) AS UNT_NM    -- 단위명칭
	           ,CHK_ITM_CD                 --점검항목코드
	           ,CHK_ITM_SEQ                 --점검항목 정열순서
	           ,CHK_ITM_NM                 --점검항목명
	           ,CHK_LOC                 --점검위치
	           ,DISS_SHP                 --재해형태(QS036)
	           ,RISK_FREQ                 --확정_빈도(QS09003) 작성
	           ,RISK_APRV                 --확정_강도(QS09004) 작성
	           ,RISK_CRIT                 --확정_위험성(QS09001) 작성
	           ,RISK_GRD                 --확정_위험등급(QS09002) 작성
	           ,IMPRV_CPLN                 --개선대책
	           ,WRK_PSNNO                 --작업인원
	           ,ITM_ADD_YN                 --기존 : 0, 추가 : 1         
	           ,(SELECT DECODE(COUNT(1),0,'중흥','협력사') FROM TQHA_VNDR WHERE SIT_CD = A.SIT_CD AND VNDR_PSN_ID = A.IPT_ID) AS REG_DIV  
	      	FROM TQHB_RISK_LST A
	         WHERE A.SIT_CD     = p_SIT_CD
	           AND A.PLN_YM     = p_PLN_YM
	           AND A.PLN_DGR    = p_PLN_DGR
	           AND A.CUST_CD    = p_CUST_CD
	           AND A.VNDR_SEQ   = p_VNDR_SEQ
        ;

    --------------------------------------------------------------------------------
    -- SMS 처리 ( 협력업체 평가서 제출 )
    ELSIF p_WRK_TP = 'Q8' THEN

        OPEN RTN_CURSOR FOR
        SELECT A.SIT_CD
             , A.PLN_YM
             , A.PLN_DGR
             , A.CUST_CD
             , A.VNDR_SEQ
             , C.MGR_1                      AS MA_CNFR
             , REPLACE(B.MP_NO, '-', '')    AS MP_NO
             -- REPLACE(SYS.PKG_CRYPTO_DEC.DECRYPT(B.MP_NO), '-', '') MP_NO
          FROM (-- 협력업체 위험성평가 제출 시 확인자 리스트
                SELECT SIT_CD
                     , PLN_YM
                     , PLN_DGR
                     , CUST_CD
                     , VNDR_SEQ
                  FROM TQHB_RISK_CHK
                 WHERE SIT_CD   = p_SIT_CD     -- 변수(현장)
                   AND PLN_YM   = p_PLN_YM        -- 변수(평가년월)
                   AND PLN_DGR  = p_PLN_DGR     -- 변수(차수)
                   AND CUST_CD  = p_CUST_CD
                   AND VNDR_SEQ = p_VNDR_SEQ
                 GROUP 
                    BY SIT_CD
                     , PLN_YM
                     , PLN_DGR
                     , CUST_CD
                     , VNDR_SEQ
               ) A
               JOIN (
                               SELECT SIT_CD, MGR_1 FROM TQHA_VNDR WHERE SIT_CD = P_SIT_CD AND CUST_CD = p_CUST_CD AND VNDR_SEQ = p_VNDR_SEQ AND NVL(MGR_1, '*') != '*'
                     UNION ALL SELECT SIT_CD, MGR_2 FROM TQHA_VNDR WHERE SIT_CD = P_SIT_CD AND CUST_CD = p_CUST_CD AND VNDR_SEQ = p_VNDR_SEQ AND NVL(MGR_2, '*') != '*'
                     UNION ALL SELECT SIT_CD, MGR_3 FROM TQHA_VNDR WHERE SIT_CD = P_SIT_CD AND CUST_CD = p_CUST_CD AND VNDR_SEQ = p_VNDR_SEQ AND NVL(MGR_3, '*') != '*'
                    ) C  ON A.SIT_CD = C.SIT_CD
               JOIN TCOZ_USR_INFO B ON C.SIT_CD = B.DEPT_CD
                                   AND C.MGR_1  = B.USR_ID
        ;

    END IF;


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHB_RISK_SCHD_MNG_CO_Q ;
/

-- PQHB_RISK_USER_LIST_Q
DROP PROCEDURE "PQHB_RISK_USER_LIST_Q";
CREATE PROCEDURE "PQHB_RISK_USER_LIST_Q" (
      p_WRK_TP  VARCHAR2 DEFAULT 'Q'                                                       -- FLAG( Q: SELECT )
     ,p_SIT_CD  VARCHAR2                                                  -- 현장코드
     ,p_CUST_CD VARCHAR2                                                 -- 협력업체코드
     ,p_VNDR_SEQ VARCHAR2                                                 -- 협력업체코드
     ,RTN_CURSOR OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : 위험성평가 사용자 리스트 조회

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      XXXX/XX/XX                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------
    
    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
	        SELECT A.SIT_CD
			     , A.EMPE_NO
			     , A.PNM
			     , A.DTY_CD
			     , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.DTY_CD AND HRNK_CD = 'HRZ0EF' AND USE_YN = '1') AS DTY_NM
			     , A.TEL_NO
			     , A.CELPH
			     , A.EMAIL
			     , '중흥' AS CUST_NM
			     , ( SELECT DEPT_NM FROM TCOZ_DEPT_INFO WHERE DEPT_CD = A.SIT_CD ) AS SIT_NM -- 현장명칭			     , NULL AS VNDR_SEQ
			     , '1' AS CO_DIV_CD
			     , A.JB_CD
			     , NVL((SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.JB_CD AND HRNK_CD = 'QS077' AND USE_YN = '1'),'') AS JB_NM
			  FROM TQHA_SITENAM A
			 WHERE 1=1
			   AND A.SIT_CD    = p_SIT_CD
			UNION ALL 
			SELECT A.SIT_CD
			     , A.EMPE_NO
			     , A.PNM
			     , A.DTY_CD
			     , A.DTY_NM
			     , A.TEL_NO
			     , A.CELPH
			     , A.EMAIL
			     , ( SELECT CUST_NM FROM VQSZ_TRADE WHERE CUST_CD = A.CUST_CD ) AS CUST_NM   -- 업체명
			     , ( SELECT DEPT_NM FROM TCOZ_DEPT_INFO WHERE DEPT_CD = A.SIT_CD ) AS SIT_NM -- 현장명칭
			     , '2' AS CO_DIV_CD
			     , A.JB_CD
			     , NVL((SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = A.JB_CD AND HRNK_CD = 'QS077' AND USE_YN = '1'),'') AS JB_NM
			  FROM TQHB_VNDRNAM A
			 WHERE 1=1
			   AND A.SIT_CD    = p_SIT_CD
			   AND A.CUST_CD   = p_CUST_CD
			   AND A.VNDR_SEQ   = p_VNDR_SEQ
			 ORDER BY CO_DIV_CD, SIT_CD, CUST_NM, PNM
	     ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHB_RISK_USER_LIST_Q;
/

-- PQHB_SAFT_MNG_ASSIGN_Q
DROP PROCEDURE "PQHB_SAFT_MNG_ASSIGN_Q";
CREATE PROCEDURE "PQHB_SAFT_MNG_ASSIGN_Q"
(
      p_WRK_TP  VARCHAR2 DEFAULT 'Q'                                                       -- FLAG( Q: SELECT )
     ,p_SIT_CD TQHB_DAYSAFE_NAM.SIT_CD%TYPE                                               -- 현장코드
     ,p_PLN_YM TQHB_DAYSAFE_NAM.PLN_YM%TYPE                                               -- 계획년월
     ,p_PLN_DGR TQHB_DAYSAFE_NAM.PLN_DGR%TYPE                                             -- 차수구분코드(QS005) 1 1차,2 2차
     ,p_ODAY_CHK_DT TQHB_DAYSAFE_NAM.ODAY_CHK_DT%TYPE                                     -- 일일점검일자
     ,p_RISK_GRD TQHB_DAYSAFE_NAM.RISK_GRD%TYPE                                           -- 위험등급(QS09002) 작성
     ,p_EMPE_NO_SEQ TQHB_DAYSAFE_NAM.EMPE_NO_SEQ%TYPE                                       -- 일일안전책임자 순번
     ,p_EMPE_NO TQHB_DAYSAFE_NAM.EMPE_NO%TYPE                                     			  -- 일일안전책임자
     ,RTN_CURSOR OUT SYS_REFCURSOR
) 
IS 
    /**************************************************************************************************************************
      Purpose : 

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/09/04 16:09:44                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;


BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리
    ---------------------------------------------------------------------------------------------------------------------------
    
	-- 그리드 헤더 조회   
	 IF p_WRK_TP = 'Q1' THEN
	
	    OPEN RTN_CURSOR FOR
		    SELECT ROW_NUMBER() OVER(ORDER BY ODAY_CHK_DT) AS COL_SEQ
			     , ODAY_CHK_DT
			     , TO_CHAR(TO_DATE(ODAY_CHK_DT,'YYYYMMDD'),'MM/DD')
			       || CHR(10)
			       || '('
			       || TO_CHAR(TO_DATE(ODAY_CHK_DT,'YYYYMMDD'),'DY','NLS_DATE_LANGUAGE=KOREAN')
			       || ')' AS HDR_NM
			     , MIN(SUBSTR(ODAY_CHK_DT, -2)) OVER() AS MIN_CHK_DAY
			     , MAX(SUBSTR(ODAY_CHK_DT, -2)) OVER() AS MAX_CHK_DAY
			FROM (
			    SELECT DISTINCT ODAY_CHK_DT
			    FROM TQHB_DAYSAFE_DT
			    WHERE SIT_CD  = p_SIT_CD
			      AND PLN_YM  = p_PLN_YM
			      AND PLN_DGR = p_PLN_DGR
			)
			ORDER BY ODAY_CHK_DT;
	    
	    /*
			SELECT ROW_NUMBER() OVER(ORDER BY ODAY_CHK_DT) AS COL_SEQ
			     , ODAY_CHK_DT
			     , TO_CHAR(TO_DATE(ODAY_CHK_DT,'YYYYMMDD'),'MM/DD')
			       || CHR(10)
			       || '('
			       || TO_CHAR(TO_DATE(ODAY_CHK_DT,'YYYYMMDD'),'DY','NLS_DATE_LANGUAGE=KOREAN')
			       || ')' AS HDR_NM
			     , TO_NUMBER(SUBSTR(ODAY_CHK_DT, -2)) AS CHK_DAY
			FROM (
			    SELECT DISTINCT ODAY_CHK_DT
			    FROM TQHB_DAYSAFE_DT
			    WHERE SIT_CD  = p_SIT_CD
			      AND PLN_YM  = p_PLN_YM
			      AND PLN_DGR = p_PLN_DGR
			)
			ORDER BY ODAY_CHK_DT;
		*/		 
	    
	-- 중점 그리드 데이터 조회
	ELSIF p_WRK_TP = 'Q2' THEN
	
	    OPEN RTN_CURSOR FOR
		WITH DT_MAIN AS (
		    -- 1. TQHB_DAYSAFE_DT 메인: 점검 일자 목록 및 해당 월의 최대 점검일(MAX_DAY) 추출
		    SELECT DISTINCT 
		           ODAY_CHK_DT,
		           MAX(TO_NUMBER(SUBSTR(ODAY_CHK_DT, 7, 2))) OVER() AS MAX_DAY
		      FROM TQHB_DAYSAFE_DT
		     WHERE SIT_CD = p_SIT_CD
		       AND PLN_YM = p_PLN_YM
		       AND PLN_DGR = p_PLN_DGR
		       AND RISK_GRD = 'QS0900201'
		)
		SELECT 
		       (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = S.JB_CD AND HRNK_CD = 'QS077' AND USE_YN = '1') AS JB_NM,
		       S.PNM,
		       S.EMPE_NO,
		       'QS0900201' AS RISK_GRD, 
		       MAX(CASE WHEN D.DAY_DD = '01' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_1,
		       MAX(CASE WHEN D.DAY_DD = '02' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_2,
		       MAX(CASE WHEN D.DAY_DD = '03' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_3,
		       MAX(CASE WHEN D.DAY_DD = '04' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_4,
		       MAX(CASE WHEN D.DAY_DD = '05' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_5,
		       MAX(CASE WHEN D.DAY_DD = '06' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_6,
		       MAX(CASE WHEN D.DAY_DD = '07' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_7,
		       MAX(CASE WHEN D.DAY_DD = '08' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_8,
		       MAX(CASE WHEN D.DAY_DD = '09' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_9,
		       MAX(CASE WHEN D.DAY_DD = '10' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_10,
		       MAX(CASE WHEN D.DAY_DD = '11' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_11,
		       MAX(CASE WHEN D.DAY_DD = '12' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_12,
		       MAX(CASE WHEN D.DAY_DD = '13' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_13,
		       MAX(CASE WHEN D.DAY_DD = '14' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_14,
		       MAX(CASE WHEN D.DAY_DD = '15' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_15,
		       MAX(CASE WHEN D.DAY_DD = '16' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_16,
		       MAX(CASE WHEN D.DAY_DD = '17' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_17,
		       MAX(CASE WHEN D.DAY_DD = '18' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_18,
		       MAX(CASE WHEN D.DAY_DD = '19' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_19,
		       MAX(CASE WHEN D.DAY_DD = '20' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_20,
		       MAX(CASE WHEN D.DAY_DD = '21' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_21,
		       MAX(CASE WHEN D.DAY_DD = '22' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_22,
		       MAX(CASE WHEN D.DAY_DD = '23' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_23,
		       MAX(CASE WHEN D.DAY_DD = '24' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_24,
		       MAX(CASE WHEN D.DAY_DD = '25' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_25,
		       MAX(CASE WHEN D.DAY_DD = '26' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_26,
		       MAX(CASE WHEN D.DAY_DD = '27' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_27,
		       MAX(CASE WHEN D.DAY_DD = '28' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_28,
		       MAX(CASE WHEN D.DAY_DD = '29' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_29,
		       MAX(CASE WHEN D.DAY_DD = '30' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_30,
		       MAX(CASE WHEN D.DAY_DD = '31' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_31,		       
		       MAX(CASE WHEN D.DAY_DD = '01' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_1,		       
		       MAX(CASE WHEN D.DAY_DD = '02' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_2,
		       MAX(CASE WHEN D.DAY_DD = '03' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_3,
		       MAX(CASE WHEN D.DAY_DD = '04' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_4,
		       MAX(CASE WHEN D.DAY_DD = '05' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_5,
		       MAX(CASE WHEN D.DAY_DD = '06' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_6,
		       MAX(CASE WHEN D.DAY_DD = '07' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_7,
		       MAX(CASE WHEN D.DAY_DD = '08' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_8,
		       MAX(CASE WHEN D.DAY_DD = '09' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_9,
		       MAX(CASE WHEN D.DAY_DD = '10' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_10,
		       MAX(CASE WHEN D.DAY_DD = '11' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_11,
		       MAX(CASE WHEN D.DAY_DD = '12' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_12,
		       MAX(CASE WHEN D.DAY_DD = '13' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_13,
		       MAX(CASE WHEN D.DAY_DD = '14' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_14,
		       MAX(CASE WHEN D.DAY_DD = '15' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_15,
		       MAX(CASE WHEN D.DAY_DD = '16' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_16,
		       MAX(CASE WHEN D.DAY_DD = '17' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_17,
		       MAX(CASE WHEN D.DAY_DD = '18' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_18,
		       MAX(CASE WHEN D.DAY_DD = '19' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_19,
		       MAX(CASE WHEN D.DAY_DD = '20' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_20,
		       MAX(CASE WHEN D.DAY_DD = '21' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_21,
		       MAX(CASE WHEN D.DAY_DD = '22' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_22,
		       MAX(CASE WHEN D.DAY_DD = '23' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_23,
		       MAX(CASE WHEN D.DAY_DD = '24' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_24,
		       MAX(CASE WHEN D.DAY_DD = '25' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_25,
		       MAX(CASE WHEN D.DAY_DD = '26' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_26,
		       MAX(CASE WHEN D.DAY_DD = '27' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_27,
		       MAX(CASE WHEN D.DAY_DD = '28' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_28,
		       MAX(CASE WHEN D.DAY_DD = '29' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_29,
		       MAX(CASE WHEN D.DAY_DD = '30' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_30,
		       MAX(CASE WHEN D.DAY_DD = '31' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_31
		  FROM TQHA_SITENAM S
		  LEFT JOIN (
		        SELECT ODAY_CHK_DT,
		               SUBSTR(ODAY_CHK_DT, 7, 2) AS DAY_DD,
		               MAX_DAY
		          FROM DT_MAIN
		  ) D ON 1 = 1
		  LEFT JOIN TQHB_DAYSAFE_NAM N
		         ON S.SIT_CD = N.SIT_CD
		        AND S.EMPE_NO = N.EMPE_NO
		        AND D.ODAY_CHK_DT = N.ODAY_CHK_DT
		        AND N.PLN_YM = p_PLN_YM
		        AND N.PLN_DGR = p_PLN_DGR
		        AND N.RISK_GRD = 'QS0900201'
		 WHERE S.SIT_CD = p_SIT_CD
		   AND S.USE_YN = '1'
		   AND S.JB_CD IS NOT NULL
		 GROUP BY S.JB_CD, S.PNM, S.EMPE_NO
		 ORDER BY JB_NM, S.PNM
		 ;
	    
	 -- 일상 그리드 데이터 조회
	ELSIF p_WRK_TP = 'Q3' THEN
	
	    OPEN RTN_CURSOR FOR
		WITH DT_MAIN AS (
		    -- 1. TQHB_DAYSAFE_DT 메인: 점검 일자 목록 및 해당 월의 최대 점검일(MAX_DAY) 추출
		    SELECT DISTINCT 
		           ODAY_CHK_DT,
		           MAX(TO_NUMBER(SUBSTR(ODAY_CHK_DT, 7, 2))) OVER() AS MAX_DAY
		      FROM TQHB_DAYSAFE_DT
		     WHERE SIT_CD = p_SIT_CD
		       AND PLN_YM = p_PLN_YM
		       AND PLN_DGR = p_PLN_DGR
		       AND RISK_GRD = 'QS0900202'
		)
		SELECT 
		       (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = S.JB_CD AND HRNK_CD = 'QS077' AND USE_YN = '1') AS JB_NM,
		       S.PNM,
		       S.EMPE_NO,
		       'QS0900202' AS RISK_GRD, 
		       MAX(CASE WHEN D.DAY_DD = '01' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_1,
		       MAX(CASE WHEN D.DAY_DD = '02' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_2,
		       MAX(CASE WHEN D.DAY_DD = '03' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_3,
		       MAX(CASE WHEN D.DAY_DD = '04' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_4,
		       MAX(CASE WHEN D.DAY_DD = '05' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_5,
		       MAX(CASE WHEN D.DAY_DD = '06' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_6,
		       MAX(CASE WHEN D.DAY_DD = '07' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_7,
		       MAX(CASE WHEN D.DAY_DD = '08' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_8,
		       MAX(CASE WHEN D.DAY_DD = '09' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_9,
		       MAX(CASE WHEN D.DAY_DD = '10' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_10,
		       MAX(CASE WHEN D.DAY_DD = '11' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_11,
		       MAX(CASE WHEN D.DAY_DD = '12' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_12,
		       MAX(CASE WHEN D.DAY_DD = '13' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_13,
		       MAX(CASE WHEN D.DAY_DD = '14' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_14,
		       MAX(CASE WHEN D.DAY_DD = '15' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_15,
		       MAX(CASE WHEN D.DAY_DD = '16' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_16,
		       MAX(CASE WHEN D.DAY_DD = '17' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_17,
		       MAX(CASE WHEN D.DAY_DD = '18' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_18,
		       MAX(CASE WHEN D.DAY_DD = '19' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_19,
		       MAX(CASE WHEN D.DAY_DD = '20' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_20,
		       MAX(CASE WHEN D.DAY_DD = '21' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_21,
		       MAX(CASE WHEN D.DAY_DD = '22' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_22,
		       MAX(CASE WHEN D.DAY_DD = '23' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_23,
		       MAX(CASE WHEN D.DAY_DD = '24' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_24,
		       MAX(CASE WHEN D.DAY_DD = '25' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_25,
		       MAX(CASE WHEN D.DAY_DD = '26' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_26,
		       MAX(CASE WHEN D.DAY_DD = '27' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_27,
		       MAX(CASE WHEN D.DAY_DD = '28' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_28,
		       MAX(CASE WHEN D.DAY_DD = '29' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_29,
		       MAX(CASE WHEN D.DAY_DD = '30' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_30,
		       MAX(CASE WHEN D.DAY_DD = '31' THEN CASE WHEN N.EMPE_NO IS NOT NULL THEN '1' ELSE NULL END END) AS D_31,
		       MAX(CASE WHEN D.DAY_DD = '01' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_1,		       
		       MAX(CASE WHEN D.DAY_DD = '02' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_2,
		       MAX(CASE WHEN D.DAY_DD = '03' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_3,
		       MAX(CASE WHEN D.DAY_DD = '04' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_4,
		       MAX(CASE WHEN D.DAY_DD = '05' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_5,
		       MAX(CASE WHEN D.DAY_DD = '06' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_6,
		       MAX(CASE WHEN D.DAY_DD = '07' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_7,
		       MAX(CASE WHEN D.DAY_DD = '08' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_8,
		       MAX(CASE WHEN D.DAY_DD = '09' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_9,
		       MAX(CASE WHEN D.DAY_DD = '10' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_10,
		       MAX(CASE WHEN D.DAY_DD = '11' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_11,
		       MAX(CASE WHEN D.DAY_DD = '12' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_12,
		       MAX(CASE WHEN D.DAY_DD = '13' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_13,
		       MAX(CASE WHEN D.DAY_DD = '14' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_14,
		       MAX(CASE WHEN D.DAY_DD = '15' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_15,
		       MAX(CASE WHEN D.DAY_DD = '16' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_16,
		       MAX(CASE WHEN D.DAY_DD = '17' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_17,
		       MAX(CASE WHEN D.DAY_DD = '18' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_18,
		       MAX(CASE WHEN D.DAY_DD = '19' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_19,
		       MAX(CASE WHEN D.DAY_DD = '20' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_20,
		       MAX(CASE WHEN D.DAY_DD = '21' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_21,
		       MAX(CASE WHEN D.DAY_DD = '22' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_22,
		       MAX(CASE WHEN D.DAY_DD = '23' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_23,
		       MAX(CASE WHEN D.DAY_DD = '24' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_24,
		       MAX(CASE WHEN D.DAY_DD = '25' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_25,
		       MAX(CASE WHEN D.DAY_DD = '26' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_26,
		       MAX(CASE WHEN D.DAY_DD = '27' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_27,
		       MAX(CASE WHEN D.DAY_DD = '28' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_28,
		       MAX(CASE WHEN D.DAY_DD = '29' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_29,
		       MAX(CASE WHEN D.DAY_DD = '30' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_30,
		       MAX(CASE WHEN D.DAY_DD = '31' THEN D.ODAY_CHK_DT ELSE NULL END) AS DD_31
		  FROM TQHA_SITENAM S
		  LEFT JOIN (
		        SELECT ODAY_CHK_DT,
		               SUBSTR(ODAY_CHK_DT, 7, 2) AS DAY_DD,
		               MAX_DAY
		          FROM DT_MAIN
		  ) D ON 1 = 1
		  LEFT JOIN TQHB_DAYSAFE_NAM N
		         ON S.SIT_CD = N.SIT_CD
		        AND S.EMPE_NO = N.EMPE_NO
		        AND D.ODAY_CHK_DT = N.ODAY_CHK_DT
		        AND N.PLN_YM = p_PLN_YM
		        AND N.PLN_DGR = p_PLN_DGR
		        AND N.RISK_GRD = 'QS0900202'
		 WHERE S.SIT_CD = p_SIT_CD
		   AND S.USE_YN = '1'
		   AND S.JB_CD IS NOT NULL
		 GROUP BY S.JB_CD, S.PNM, S.EMPE_NO
		 ORDER BY JB_NM, S.PNM
		 ;
	 
	  -- 점검항목별 안전책임자 조회
	ELSIF p_WRK_TP = 'Q4' THEN
	
	    OPEN RTN_CURSOR FOR
		 SELECT A.SIT_CD                 --현장코드
		       ,A.PLN_YM                 --계획년월
		       ,A.PLN_DGR                 --차수구분코드(QS005) 1 1차,2 2차
		       ,A.CUST_CD                 --협력업체코드
		       ,A.VNDR_SEQ
		       ,(SELECT CUST_NM FROM VQSZ_TRADE WHERE CUST_CD = A.CUST_CD) AS CUST_NM  --업체명
		       ,A.CTP_CD                 --공종코드
		       ,A.UNT_CD                 --단위코드
		       ,(SELECT CTP_NM FROM TQHA_CTP WHERE CTP_CD = A.CTP_CD) AS CTP_NM
		       ,(SELECT UNT_NM FROM TQHA_CTPUNT WHERE CTP_CD = A.CTP_CD AND UNT_CD = A.UNT_CD) AS UNT_NM
		       ,A.CHK_ITM_CD                 --점검항목코드
		       ,A.ODAY_CHK_DT
		       ,A.RISK_GRD
		       ,A.EMPE_NO
		       ,(SELECT USR_NM FROM TCOZ_USR_INFO WHERE EMPNO = A.EMPE_NO) AS USR_NM
		       ,B.CHK_ITM_NM                 --점검항목명
		       ,B.IMPRV_CPLN                 --개선대책
		       ,B.CHK_LOC
    	       ,B.WRK_PSNNO
		  FROM TQHB_DAYSAFE_CHKLST A,
		       TQHB_RISK_LST B
		WHERE 1=1
		   AND A.SIT_CD = B.SIT_CD                     --현장코드
		   AND A.PLN_YM = B.PLN_YM                     --계획년월
		   AND A.PLN_DGR = B.PLN_DGR                   --차수구분코드(QS005) 1 1차,2 2차
		   AND A.CUST_CD = B.CUST_CD
		   AND A.CTP_CD = B.CTP_CD
		   AND A.UNT_CD = B.UNT_CD
		   AND A.CHK_ITM_CD = B.CHK_ITM_CD
		   AND A.SIT_CD = p_SIT_CD                    --현장코드
		   AND A.PLN_YM = p_PLN_YM                     --계획년월
		   AND A.PLN_DGR = p_PLN_DGR                     --차수구분코드(QS005) 1 1차,2 2차
		   AND A.RISK_GRD = p_RISK_GRD
		   AND A.ODAY_CHK_DT = p_ODAY_CHK_DT
		ORDER BY A.SIT_CD, A.PLN_YM, A.PLN_DGR, A.CUST_CD, A.UNT_CD, A.CHK_ITM_CD 
	   		;
	    
	 END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHB_SAFT_MNG_ASSIGN_S
DROP PROCEDURE "PQHB_SAFT_MNG_ASSIGN_S";
CREATE PROCEDURE "PQHB_SAFT_MNG_ASSIGN_S"
                            (p_WRK_TP  VARCHAR2 :='U'                                     -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
                            ,p_WRK_ID  VARCHAR2                                           -- 사용자 ID 
                            ,p_WRK_IP  VARCHAR2                                           -- 사용자 IP 
                            ,p_SIT_CD TQHB_DAYSAFE_CHKLST.SIT_CD%TYPE                     -- 현장코드
                            ,p_PLN_YM TQHB_DAYSAFE_CHKLST.PLN_YM%TYPE                     -- 계획년월
                            ,p_PLN_DGR TQHB_DAYSAFE_CHKLST.PLN_DGR%TYPE                   -- 차수구분코드(QS005) 1 1차,2 2차
                            ,p_CUST_CD TQHB_DAYSAFE_CHKLST.CUST_CD%TYPE                   -- 협력업체코드
                            ,p_VNDR_SEQ TQHB_DAYSAFE_CHKLST.VNDR_SEQ%TYPE                 -- 업체순번
                            ,p_CTP_CD TQHB_DAYSAFE_CHKLST.CTP_CD%TYPE                     -- 공종코드
                            ,p_UNT_CD TQHB_DAYSAFE_CHKLST.UNT_CD%TYPE                     -- 단위코드
                            ,p_CHK_ITM_CD TQHB_DAYSAFE_CHKLST.CHK_ITM_CD%TYPE             -- 점검항목코드
                            ,p_ODAY_CHK_DT TQHB_DAYSAFE_CHKLST.ODAY_CHK_DT%TYPE           -- 일일점검일자
                            ,p_RISK_GRD TQHB_DAYSAFE_CHKLST.RISK_GRD%TYPE                 -- 위험등급(QS09002) 작성
                            ,p_CHK_ITM_SEQ TQHB_DAYSAFE_CHKLST.CHK_ITM_SEQ%TYPE           -- 점검항목 정열순서
                            ,p_ODAY_CHK_RSLT TQHB_DAYSAFE_CHKLST.ODAY_CHK_RSLT%TYPE       -- 점검결과(QS006) 1 N/A,2 완료(유지),3 불량
                            ,p_ODAY_CHK_OPIN TQHB_DAYSAFE_CHKLST.ODAY_CHK_OPIN%TYPE       -- 일일안전책임자 점검의견
                            ,p_EMPE_NO TQHB_DAYSAFE_CHKLST.EMPE_NO%TYPE                   -- 일일안전책임자 사번
                            ,p_PHOTO_GRP1 TQHB_DAYSAFE_CHKLST.PHOTO_GRP1%TYPE             -- 첨부파일그룹사진1
                            ,p_PHOTO_DESC_1 TQHB_DAYSAFE_CHKLST.PHOTO_DESC_1%TYPE         -- 사진설명1
                            ,p_PHOTO_GRP2 TQHB_DAYSAFE_CHKLST.PHOTO_GRP2%TYPE             -- 첨부파일그룹사진2
                            ,p_PHOTO_DESC_2 TQHB_DAYSAFE_CHKLST.PHOTO_DESC_2%TYPE         -- 사진설명2
                            ,p_NCR_PUBC_YN TQHB_DAYSAFE_CHKLST.NCR_PUBC_YN%TYPE           -- 발행 1, 미발행 0
                            ,p_NCR_DOC_NO TQHB_DAYSAFE_CHKLST.NCR_DOC_NO%TYPE             -- 부적합문서번호
                            ,p_MA_DDLN_DT TQHB_DAYSAFE_CHKLST.MA_DDLN_DT%TYPE             -- 조치기한일자
                            ,p_VNDR_NOTI_YN TQHB_DAYSAFE_CHKLST.VNDR_NOTI_YN%TYPE         -- 발송 1 미발송0
                            ,p_VNDR_SEND_DT TQHB_DAYSAFE_CHKLST.VNDR_SEND_DT%TYPE         -- 업체발송일자
                            ,p_VNDR_MA_YN TQHB_DAYSAFE_CHKLST.VNDR_MA_YN%TYPE             -- 조치구분(QS007) 1 조치, 0 미조치
                            ,p_VNDR_MA_DT TQHB_DAYSAFE_CHKLST.VNDR_MA_DT%TYPE             -- 업체조치일자
                            )
IS 
    /**************************************************************************************************************************
      Purpose : 

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/09/07 17:06:53                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;


BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_YM IS NULL)  THEN
        ERR_MSG := '계획년월는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_DGR IS NULL)  THEN
        ERR_MSG := '차수구분코드(QS005) 1 1차,2 2차는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CUST_CD IS NULL)  THEN
        ERR_MSG := '협력업체코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_VNDR_SEQ IS NULL)  THEN
        ERR_MSG := '업체순번는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;
    
    IF (p_CTP_CD IS NULL)  THEN
        ERR_MSG := '공종코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_UNT_CD IS NULL)  THEN
        ERR_MSG := '단위코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_CHK_ITM_CD IS NULL)  THEN
        ERR_MSG := '점검항목코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_ODAY_CHK_DT IS NULL)  THEN
        ERR_MSG := '일일점검일자는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_RISK_GRD IS NULL)  THEN
        ERR_MSG := '위험등급(QS09002) 작성는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------



    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_WRK_TP ='D') THEN
        DELETE 
          FROM TQHB_DAYSAFE_CHKLST
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND PLN_YM = p_PLN_YM          --계획년월
           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
           AND CUST_CD = p_CUST_CD         --협력업체코드
           AND CTP_CD = p_CTP_CD          --공종코드
           AND UNT_CD = p_UNT_CD          --단위코드
           AND CHK_ITM_CD = p_CHK_ITM_CD      --점검항목코드
           AND ODAY_CHK_DT = p_ODAY_CHK_DT     --일일점검일자
           AND RISK_GRD = p_RISK_GRD        --위험등급(QS09002) 작성
           AND VNDR_SEQ = p_VNDR_SEQ;       --업체순번

    ELSE 
        UPDATE TQHB_DAYSAFE_CHKLST
           SET CHK_ITM_SEQ          = p_CHK_ITM_SEQ             --점검항목 정열순서
              ,ODAY_CHK_RSLT        = p_ODAY_CHK_RSLT           --점검결과(QS006) 1 N/A,2 완료(유지),3 불량
              ,ODAY_CHK_OPIN        = p_ODAY_CHK_OPIN           --일일안전책임자 점검의견
              ,EMPE_NO              = p_EMPE_NO                 --일일안전책임자 사번
              ,PHOTO_GRP1           = p_PHOTO_GRP1              --첨부파일그룹사진1
              ,PHOTO_DESC_1         = p_PHOTO_DESC_1            --사진설명1
              ,PHOTO_GRP2           = p_PHOTO_GRP2              --첨부파일그룹사진2
              ,PHOTO_DESC_2         = p_PHOTO_DESC_2            --사진설명2
              ,NCR_PUBC_YN          = p_NCR_PUBC_YN             --발행 1, 미발행 0
              ,NCR_DOC_NO           = p_NCR_DOC_NO              --부적합문서번호
              ,MA_DDLN_DT           = p_MA_DDLN_DT              --조치기한일자
              ,VNDR_NOTI_YN         = p_VNDR_NOTI_YN            --발송 1 미발송0
              ,VNDR_SEND_DT         = p_VNDR_SEND_DT            --업체발송일자
              ,VNDR_MA_YN           = p_VNDR_MA_YN              --조치구분(QS007) 1 조치, 0 미조치
              ,VNDR_MA_DT           = p_VNDR_MA_DT              --업체조치일자
              ,UPD_ID               = p_WRK_ID                  --수정ID 
              ,UPD_DTM              = SYSDATE()                 --수정일시
              ,UPD_IP               = p_WRK_IP                  --수정IP
         WHERE SIT_CD = p_SIT_CD          --현장코드
           AND PLN_YM = p_PLN_YM          --계획년월
           AND PLN_DGR = p_PLN_DGR         --차수구분코드(QS005) 1 1차,2 2차
           AND CUST_CD = p_CUST_CD         --협력업체코드
           AND CTP_CD = p_CTP_CD          --공종코드
           AND UNT_CD = p_UNT_CD          --단위코드
           AND CHK_ITM_CD = p_CHK_ITM_CD      --점검항목코드
           AND ODAY_CHK_DT = p_ODAY_CHK_DT     --일일점검일자
           AND RISK_GRD = p_RISK_GRD        --위험등급(QS09002) 작성
           AND VNDR_SEQ = p_VNDR_SEQ;       --업체순번
           
	END IF;
    
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHB_SAFT_MNG_COPY_W
DROP PROCEDURE "PQHB_SAFT_MNG_COPY_W";
CREATE PROCEDURE "PQHB_SAFT_MNG_COPY_W"
                            (p_WRK_TP  VARCHAR2 :='U'                                     -- UPDATE FLAG( I: ISNERT, U:UPDATE, D:DELTE)
                            ,p_WRK_ID  VARCHAR2                                           -- 사용자 ID 
                            ,p_WRK_IP  VARCHAR2                                           -- 사용자 IP 
                            ,p_SIT_CD TQHB_DAYSAFE_CHKLST.SIT_CD%TYPE                     -- 현장코드
                            ,p_PLN_YM TQHB_DAYSAFE_CHKLST.PLN_YM%TYPE                     -- 계획년월
                            ,p_PLN_DGR TQHB_DAYSAFE_CHKLST.PLN_DGR%TYPE                   -- 차수구분코드(QS0
                            )
IS 
    /**************************************************************************************************************************
      Purpose : 

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  -------------------------------------------------------------
      1.0     2026/09/07 17:06:53                         최초생성

    /**************************************************************************************************************************/


    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE       NUMBER :=-20009;          -- ERROR 코드
    ERR_MSG        VARCHAR2(200);            -- ERROR Message
    USER_EXCEPTION EXCEPTION;

	v_ODAY_CHK_DT  VARCHAR2(8);
	
	v_CNT NUMBER;
BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 필수입력 필드  Check  ]
    ---------------------------------------------------------------------------------------------------------------------------
    IF (p_SIT_CD IS NULL)  THEN
        ERR_MSG := '현장코드는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_YM IS NULL)  THEN
        ERR_MSG := '계획년월는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    IF (p_PLN_DGR IS NULL)  THEN
        ERR_MSG := '차수구분코드(QS005) 1 1차,2 2차는(은) 필수 입력사항 입니다.';
        RAISE USER_EXCEPTION;
    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Process 선행조건 Check ]
    ---------------------------------------------------------------------------------------------------------------------------
	SELECT MIN(ODAY_CHK_DT)
	  INTO v_ODAY_CHK_DT
	  FROM TQHB_DAYSAFE_CHKLST
	 WHERE SIT_CD   = p_SIT_CD
	   AND PLN_YM   = p_PLN_YM
	   AND PLN_DGR  = p_PLN_DGR;
    
    
    SELECT COUNT(1) INTO v_CNT
      FROM TQHB_DAYSAFE_CHKLST
    WHERE SIT_CD = p_SIT_CD                     --현장코드
       AND PLN_YM = p_PLN_YM                     --계획년월
       AND PLN_DGR = p_PLN_DGR                     --차수구분코드(QS005) 1 1차,2 2차
       AND ODAY_CHK_RSLT IS NOT NULL 
    ;

	IF (v_CNT> 0)  THEN
        ERR_MSG := '점검내역이 존재하여 책임자 일괄복사를 할 수 없습니다.';
        RAISE USER_EXCEPTION;
    END IF;
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Business Process ]
    ---------------------------------------------------------------------------------------------------------------------------
   -- 중점점검
   MERGE INTO TQHB_DAYSAFE_CHKLST T
	USING (
	    SELECT *
	      FROM TQHB_DAYSAFE_CHKLST
	     WHERE SIT_CD      = p_SIT_CD
	       AND PLN_YM      = p_PLN_YM
	       AND PLN_DGR     = p_PLN_DGR
	       AND RISK_GRD    = 'QS0900201'
	       AND ODAY_CHK_DT = v_ODAY_CHK_DT
	) S
	ON (
	       T.SIT_CD     = S.SIT_CD
	   AND T.PLN_YM     = S.PLN_YM
	   AND T.PLN_DGR    = S.PLN_DGR
	   AND T.RISK_GRD   = S.RISK_GRD
	   AND T.CUST_CD    = S.CUST_CD
	   AND T.VNDR_SEQ   = S.VNDR_SEQ
	   AND T.CTP_CD     = S.CTP_CD
	   AND T.UNT_CD     = S.UNT_CD
	   AND T.CHK_ITM_CD = S.CHK_ITM_CD
	)
	WHEN MATCHED THEN
	UPDATE SET T.EMPE_NO = S.EMPE_NO
	WHERE T.ODAY_CHK_DT <> v_ODAY_CHK_DT;
   
   -- 일상점검
   MERGE INTO TQHB_DAYSAFE_CHKLST T
	USING (
	    SELECT *
	      FROM TQHB_DAYSAFE_CHKLST
	     WHERE SIT_CD      = p_SIT_CD
	       AND PLN_YM      = p_PLN_YM
	       AND PLN_DGR     = p_PLN_DGR
	       AND RISK_GRD    = 'QS0900202'
	       AND ODAY_CHK_DT = v_ODAY_CHK_DT
	) S
	ON (
	       T.SIT_CD     = S.SIT_CD
	   AND T.PLN_YM     = S.PLN_YM
	   AND T.PLN_DGR    = S.PLN_DGR
	   AND T.RISK_GRD   = S.RISK_GRD
	   AND T.CUST_CD    = S.CUST_CD
	   AND T.VNDR_SEQ   = S.VNDR_SEQ
	   AND T.CTP_CD     = S.CTP_CD
	   AND T.UNT_CD     = S.UNT_CD
	   AND T.CHK_ITM_CD = S.CHK_ITM_CD
	)
	WHEN MATCHED THEN
	UPDATE SET T.EMPE_NO = S.EMPE_NO
	WHERE T.ODAY_CHK_DT <> v_ODAY_CHK_DT;
   
	
   DELETE FROM TQHB_DAYSAFE_NAM
   WHERE   SIT_CD   = p_SIT_CD
	   AND PLN_YM   = p_PLN_YM
	   AND PLN_DGR  = p_PLN_DGR
	   AND ODAY_CHK_DT <> v_ODAY_CHK_DT
   ;
   
   INSERT INTO TQHB_DAYSAFE_NAM
	(
	    SIT_CD,
	    PLN_YM,
	    PLN_DGR,
	    ODAY_CHK_DT,
	    EMPE_NO_SEQ,
	    RISK_GRD,
	    EMPE_NO
	)
	SELECT
	    N.SIT_CD,
	    N.PLN_YM,
	    N.PLN_DGR,
	    D.ODAY_CHK_DT,   -- 날짜만 변경
	    N.EMPE_NO_SEQ,
	    N.RISK_GRD,
	    N.EMPE_NO
	FROM TQHB_DAYSAFE_NAM N
	JOIN TQHB_DAYSAFE_DT D
	  ON D.SIT_CD   = N.SIT_CD
	 AND D.PLN_YM   = N.PLN_YM
	 AND D.PLN_DGR  = N.PLN_DGR
	 AND D.RISK_GRD = N.RISK_GRD
	WHERE N.SIT_CD      = p_SIT_CD
	  AND N.PLN_YM      = p_PLN_YM
	  AND N.PLN_DGR     = p_PLN_DGR
	  AND N.ODAY_CHK_DT = v_ODAY_CHK_DT
	  AND D.ODAY_CHK_DT <> v_ODAY_CHK_DT
	ORDER BY ODAY_CHK_DT, EMPE_NO_SEQ
	;
    
    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 5. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
        WHEN OTHERS THEN 
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);
END ;
/

-- PQHB_VNDRNAM_Q
DROP PROCEDURE "PQHB_VNDRNAM_Q";
CREATE PROCEDURE "PQHB_VNDRNAM_Q" (
      p_WRK_TP  VARCHAR2 DEFAULT 'Q'                                                       -- FLAG( Q: SELECT )
     ,p_SIT_CD TQHB_VNDRNAM.SIT_CD%TYPE                                                   -- 현장코드
     ,p_CUST_CD TQHB_VNDRNAM.CUST_CD%TYPE                                                 -- 협력업체코드
     ,p_VNDR_SEQ TQHB_VNDRNAM.VNDR_SEQ%TYPE                                               -- 업체순번
     ,RTN_CURSOR          OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [협력업체직원 조회] PROCEDRE (QSE > 기준정보 > 현장기준정보  )

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      XXXX/XX/XX                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------
    -- 협력업체직원 목록 조회.
    IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
        SELECT AA.SIT_CD
 		     , AA.CUST_CD
			 , AA.VNDR_SEQ
             , AA.EMPE_NO
             --, AA.VNDR_PSN_PWD
             , AA.PNM
             , (
                SELECT JBPOS_NM FROM TCOZ_USR_INFO
                 WHERE 1=1
                   AND USR_ID = AA.EMPE_NO
               ) AS JIKGUB_NM
             , (SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = BB.JBPOS_CD AND HRNK_CD = 'HRZ0ED' AND USE_YN = '1') AS JBPOS_NM
             , AA.DTY_CD
             , AA.DTY_NM
             , AA.TEL_NO
             --, PKG_XX1.DEC_VARCHAR2_SEL(AA.CELPH , 10 , 'SSN' , 'TQSZ_SITENAM' ,'CELPH') AS CELPH
             --, PKG_XX1.DEC_VARCHAR2_SEL(AA.EMAIL , 10 , 'SSN' , 'TQSZ_SITENAM' ,'EMAIL') AS EMAIL
             , AA.CELPH
             , AA.EMAIL
             , AA.ATCH_EN
             , AA.USE_YN
             , AA.JB_CD
             , NVL((SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = AA.JB_CD AND HRNK_CD = 'QS077' AND USE_YN = '1'),'') AS JB_NM
          FROM TQHB_VNDRNAM AA
             , TCOZ_USR_INFO BB
         WHERE 1=1
           AND AA.SIT_CD    = BB.DEPT_CD (+)
           AND AA.EMPE_NO   = BB.USR_ID (+)
           AND AA.SIT_CD    = p_SIT_CD
           AND AA.CUST_CD   = p_CUST_CD
           AND AA.VNDR_SEQ  = p_VNDR_SEQ
         ORDER
            BY AA.PNM, AA.DTY_CD
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHB_VNDRNAM_Q;
/

-- PQHB_VNDR_NAM_INFO_Q
DROP PROCEDURE "PQHB_VNDR_NAM_INFO_Q";
CREATE PROCEDURE "PQHB_VNDR_NAM_INFO_Q" (
      p_WRK_TP  VARCHAR2 DEFAULT 'Q'                                                       -- FLAG( Q: SELECT )
     ,p_SIT_CD TQHB_VNDRNAM.SIT_CD%TYPE                                                   -- 현장코드
     ,p_CUST_CD TQHB_VNDRNAM.CUST_CD%TYPE                                                 -- 협력업체코드
     ,p_VNDR_SEQ TQHB_VNDRNAM.VNDR_SEQ%TYPE                                               -- 업체순번
     ,p_EMPE_NO TQHB_VNDRNAM.EMPE_NO%TYPE                                                 -- 사번
     ,RTN_CURSOR          OUT SYS_REFCURSOR
)
IS
    /**************************************************************************************************************************
      Purpose : [협력업체직원 조회] PROCEDRE (QSE > 기준정보 > 현장기준정보  )

      REVISIONS
      Ver      Date               Author                  Description 
      -------  -----------------  ----------------------  ---------------------------------------------------------------------
      1.0      XXXX/XX/XX                                 최초생성

    **************************************************************************************************************************/

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 1. 변수선언 ]
    ---------------------------------------------------------------------------------------------------------------------------
    ERR_CODE  NUMBER :=-20009; -- ERROR 코드
    ERR_MSG   VARCHAR(200);    -- ERROR Message
    USER_EXCEPTION EXCEPTION;

BEGIN

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 2. 수행전 Check Logic ]
    ---------------------------------------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 3. Business Logic 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------
    -- 본사	
	IF p_WRK_TP = 'Q' THEN

        OPEN RTN_CURSOR FOR
        SELECT AA.SIT_CD
             , AA.EMPE_NO
             , AA.PNM
             , AA.DTY_CD
             , AA.DTY_NM
             , AA.TEL_NO
             , AA.CELPH
             , AA.EMAIL
             , AA.USE_YN
             , AA.JB_CD
             ,(SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = AA.JB_CD AND HRNK_CD = 'QS077' AND USE_YN = '1') AS JB_NM
          FROM TQHA_SITENAM AA
         WHERE 1=1
           AND AA.SIT_CD    = p_SIT_CD
           AND AA.EMPE_NO   = p_EMPE_NO 
        ;
        
    -- 협력업체직원  조회.
    ELSIF p_WRK_TP = 'Q2' THEN

        OPEN RTN_CURSOR FOR
        SELECT AA.SIT_CD
 		     , AA.CUST_CD
			 , AA.VNDR_SEQ
             , AA.EMPE_NO
             , AA.PNM
             , AA.DTY_CD
             , AA.DTY_NM
             , AA.TEL_NO
             , AA.CELPH
             , AA.EMAIL
             , AA.ATCH_EN
             , AA.USE_YN
             , AA.JB_CD
             , NVL((SELECT CD_NM FROM TCOA_COMCODE WHERE COM_CD = AA.JB_CD AND HRNK_CD = 'QS077' AND USE_YN = '1'),'') AS JB_NM
          FROM TQHB_VNDRNAM AA
         WHERE 1=1
           AND AA.SIT_CD    = p_SIT_CD
           AND AA.CUST_CD   = p_CUST_CD
           AND AA.VNDR_SEQ  = p_VNDR_SEQ
           AND AA.EMPE_NO   = p_EMPE_NO 
        ;

    END IF;

    ---------------------------------------------------------------------------------------------------------------------------
    -- ▩▩ [ 4. Exception 처리 ]
    ---------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN USER_EXCEPTION THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,ERR_MSG);
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(ERR_CODE,SQLERRM);

END PQHB_VNDR_NAM_INFO_Q;
/

