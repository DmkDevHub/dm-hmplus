-- =============================================================================
-- A/S관리 테스트생성 화면 등록 (초안 · 미실행)
--
-- 목적  : 새 화면 pages/cs/asMngTest.js 를 「하자 > 하자 등록 및 처리 > AS관리」 아래
--         A/S관리(정렬 10)와 작업관리(정렬 20) 사이(정렬 15)에 등록함
-- 범위  : program · service · service_i18n(ko/en) · role_service(A/S관리 권한 복사)
--         테이블 추가 없음 — 업무 데이터는 기존 VPLUS40.TCSB_ACP_DTLS 등을 그대로 사용
-- 방식  : system_id·tenant_id 는 기존 A/S관리(cs_csChkMng) 행에서 복사하므로 치환값 불필요
--         모두 NOT EXISTS 가드 — 여러 번 실행해도 중복 없음
-- 방언  : PostgreSQL · MSSQL · Oracle 공통 구문("level" 은 따옴표 식별자, 기존 시드와 동일)
-- 실행  : 리드 확인 후 대상 DB(HMP 스키마)에 직접 실행. 신규 설치 시드 반영은 별도 판단
-- 되돌리기 : 파일 끝 ROLLBACK 절 참고
-- =============================================================================

-- 1) 프로그램
INSERT INTO program (program_id, system_id, biz_group_id, description, feature_module_id, handle_privacy_yn,
                     program_name, program_path, program_type, use_yn, ins_user_id, ins_datetime)
SELECT 'cs_asMngTest', p.system_id, p.biz_group_id, NULL, NULL, p.handle_privacy_yn,
       'A/S관리 테스트생성', 'cs/asMngTest', 'SCREEN', 'Y', 'module:erp', CURRENT_TIMESTAMP
  FROM program p
 WHERE p.program_id = 'cs_csChkMng'
   AND NOT EXISTS (SELECT 1 FROM program x WHERE x.system_id = p.system_id AND x.program_id = 'cs_asMngTest');

-- 2) 서비스(메뉴) — 상위 MENU_CS_REG_AS · 정렬 15 · PAGE_ID 파라미터 없음(AS 전용 화면)
INSERT INTO service (service_id, system_id, capability_condition, data_scope_org_type, icon, is_menu, is_public,
                     "level", link_url, log_exclude_yn, open_type, params, parent_service_id, popup_height,
                     popup_width, program_id, service_name, service_type, sort_order, use_yn, tenant_id,
                     mobile_mode, ins_user_id, ins_datetime)
SELECT 'cs_asMngTest', s.system_id, NULL, s.data_scope_org_type, NULL, 'Y', 'N',
       s."level", NULL, 'N', 'TAB', NULL, s.parent_service_id, NULL,
       NULL, 'cs_asMngTest', 'A/S관리 테스트생성', 'SCREEN', 15, 'Y', s.tenant_id,
       NULL, 'module:erp', CURRENT_TIMESTAMP
  FROM service s
 WHERE s.service_id = 'cs_csChkMng'
   AND NOT EXISTS (SELECT 1 FROM service x WHERE x.system_id = s.system_id AND x.service_id = 'cs_asMngTest');

-- 3) 서비스 다국어
INSERT INTO service_i18n (language, service_id, system_id, service_name, tenant_id, ins_user_id, ins_datetime)
SELECT 'ko', 'cs_asMngTest', s.system_id, 'A/S관리 테스트생성', s.tenant_id, 'module:erp', CURRENT_TIMESTAMP
  FROM service s
 WHERE s.service_id = 'cs_asMngTest'
   AND NOT EXISTS (SELECT 1 FROM service_i18n x WHERE x.system_id = s.system_id AND x.service_id = 'cs_asMngTest' AND x.language = 'ko');

INSERT INTO service_i18n (language, service_id, system_id, service_name, tenant_id, ins_user_id, ins_datetime)
SELECT 'en', 'cs_asMngTest', s.system_id, 'A/S Management (Test)', s.tenant_id, 'module:erp', CURRENT_TIMESTAMP
  FROM service s
 WHERE s.service_id = 'cs_asMngTest'
   AND NOT EXISTS (SELECT 1 FROM service_i18n x WHERE x.system_id = s.system_id AND x.service_id = 'cs_asMngTest' AND x.language = 'en');

-- 4) 역할 권한 — A/S관리(cs_csChkMng)에 부여된 역할·등급·허용항목을 그대로 복사
--    시드 기준 6개 역할: CS001 · CS002 · CS003(등급 2) · SYS_ADMIN · SYS_COMMON(등급 3) 외 운영 DB 에서 추가된 역할 포함
INSERT INTO role_service (role_id, service_id, system_id, allow_excel_export, allow_excel_import, allow_file_download,
                          allow_file_upload, allow_print, applicable_user_types, auth_level, data_scope,
                          scope_structure_type, use_yn, tenant_id, ins_user_id, ins_datetime)
SELECT r.role_id, 'cs_asMngTest', r.system_id, r.allow_excel_export, r.allow_excel_import, r.allow_file_download,
       r.allow_file_upload, r.allow_print, r.applicable_user_types, r.auth_level, r.data_scope,
       r.scope_structure_type, r.use_yn, r.tenant_id, 'module:erp', CURRENT_TIMESTAMP
  FROM role_service r
 WHERE r.service_id = 'cs_csChkMng'
   AND EXISTS (SELECT 1 FROM service s WHERE s.system_id = r.system_id AND s.service_id = 'cs_asMngTest')
   AND NOT EXISTS (SELECT 1 FROM role_service x
                    WHERE x.system_id = r.system_id AND x.role_id = r.role_id AND x.service_id = 'cs_asMngTest');

-- 확인
-- SELECT service_id, service_name, parent_service_id, sort_order FROM service WHERE parent_service_id = 'MENU_CS_REG_AS' ORDER BY sort_order;
-- SELECT role_id, auth_level FROM role_service WHERE service_id = 'cs_asMngTest';

-- =============================================================================
-- ROLLBACK (화면 폐기 시)
-- DELETE FROM role_service WHERE service_id = 'cs_asMngTest';
-- DELETE FROM service_i18n WHERE service_id = 'cs_asMngTest';
-- DELETE FROM service      WHERE service_id = 'cs_asMngTest';
-- DELETE FROM program      WHERE program_id = 'cs_asMngTest';
-- =============================================================================
