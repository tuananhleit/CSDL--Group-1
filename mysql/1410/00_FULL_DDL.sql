-- =============================================================================
-- 1410 / 00_FULL_DDL.sql
-- =============================================================================
-- Mục tiêu:
--   Script điều phối triển khai bộ 1410 theo đúng thứ tự dependency trên PostgreSQL.
--
-- CÁCH CHẠY (khuyến nghị):
--   cd mysql/1410
--   psql -v ON_ERROR_STOP=1 -f 00_FULL_DDL.sql <ten_database>
--
-- Lưu ý:
--   - File này dùng lệnh \i của psql.
--   - Chỉ chạy trên database rỗng hoặc đã tự dọn schema trước đó.
-- =============================================================================

\i 01_KHACH_HANG.sql
\i 02_PHUONG_TIEN.sql
\i 03_QUAN_TRI_VIEN.sql
\i 04_TRAM.sql
\i 05_CHO_DO_XE.sql
\i 06_LOAI_TRU_SAC.sql
\i 07_TRU_SAC.sql
\i 08_BANG_GIA.sql
\i 09_DAT_CHO.sql
\i 10_PHIEN.sql
\i 11_CHI_TIET_PHIEN_SAC.sql
\i 12_CHI_TIET_PHI.sql
\i 13_HOA_DON.sql
\i 14_GIAO_DICH_VI.sql
\i 15_TRIGGERS.sql
\i 16_RBAC.sql
\i 17_PROCEDURES.sql
