-- =============================================================================
-- FILE 16: RBAC - Role-Based Access Control
-- =============================================================================
-- Mô tả: Phân quyền truy cập cho 3 nhóm người dùng trong mô hình B2C & Walk-in
-- =============================================================================

CREATE ROLE app_user_role;              -- Ứng dụng di động (Tài xế B2C)
CREATE ROLE station_operator_role;      -- Vận hành trạm / Nhân viên thu ngân Walk-in
CREATE ROLE sys_admin_role;             -- Quản trị hệ thống (Toàn quyền)

-- =============================================
-- app_user_role: Khách hàng (qua app di động)
-- =============================================
-- Xem thông tin trạm, chỗ đỗ, trụ sạc, bảng giá
GRANT SELECT ON TRAM, CHO_DO_XE, LOAI_TRU_SAC, TRU_SAC, BANG_GIA
    TO app_user_role;

-- Đặt chỗ, mở phiên, thêm chi tiết sạc
GRANT SELECT, INSERT ON DAT_CHO, PHIEN, CHI_TIET_PHIEN_SAC
    TO app_user_role;

-- Xem thông tin cá nhân, xe, hóa đơn, sổ cái ví
GRANT SELECT ON KHACH_HANG, PHUONG_TIEN, HOA_DON, GIAO_DICH_VI
    TO app_user_role;

-- Quyền gọi Procedure thanh toán ví & kiểm tra ngắt sạc tự động
GRANT EXECUTE ON PROCEDURE sp_thanh_toan_hoa_don_vi(VARCHAR, VARCHAR, VARCHAR)
    TO app_user_role;
GRANT EXECUTE ON PROCEDURE sp_kiem_tra_va_ngat_sac_tu_dong(VARCHAR, NUMERIC, NUMERIC)
    TO app_user_role;

-- =============================================
-- station_operator_role: Quản lý trạm & Thu ngân Walk-in
-- =============================================
-- Cập nhật trạng thái chỗ đỗ, trụ sạc, xe (cờ khóa đen nợ xấu)
GRANT SELECT, UPDATE ON CHO_DO_XE, TRU_SAC, PHUONG_TIEN
    TO station_operator_role;

-- Thiết lập và cập nhật bảng giá
GRANT SELECT, INSERT, UPDATE ON BANG_GIA
    TO station_operator_role;

-- Cập nhật hóa đơn và phiên
GRANT SELECT, UPDATE ON HOA_DON, PHIEN
    TO station_operator_role;

-- Xem thông tin khách hàng, phương tiện, giao dịch
GRANT SELECT ON KHACH_HANG, GIAO_DICH_VI
    TO station_operator_role;

-- Quyền thực hiện thanh toán cho khách vãng lai và quét đặt chỗ quá hạn
GRANT EXECUTE ON PROCEDURE sp_thanh_toan_walkin_ngoai(VARCHAR, VARCHAR, VARCHAR)
    TO station_operator_role;
GRANT EXECUTE ON PROCEDURE sp_xu_ly_dat_cho_qua_han()
    TO station_operator_role;
GRANT EXECUTE ON PROCEDURE sp_kiem_tra_va_ngat_sac_tu_dong(VARCHAR, NUMERIC, NUMERIC)
    TO station_operator_role;

-- =============================================
-- sys_admin_role: Quản trị hệ thống (toàn quyền)
-- =============================================
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public
    TO sys_admin_role;
GRANT ALL PRIVILEGES ON ALL ROUTINES IN SCHEMA public
    TO sys_admin_role;
