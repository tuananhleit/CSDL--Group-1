-- =============================================================================
-- FILE 19: BỘ 16 CA KIỂM THỬ HỆ THỐNG (TEST CASES)
-- Dự án: Quản lý trạm sạc và bãi đỗ xe điện trong thành phố thông minh
-- Nhóm: Group 01 - PTITHCM (Môn: Cơ sở dữ liệu - GV: Lê Hà Thành)
-- =============================================================================
-- HƯỚNG DẪN:
--   - Chạy từng ca kiểm thử trong MySQL Workbench hoặc mysql client để quan sát
--     kết quả và mã lỗi mong đợi.
--   - Các ca kiểm thử sửa đổi dữ liệu đều được bao bọc trong START TRANSACTION ... ROLLBACK
--     để không làm thay đổi trạng thái của bộ dữ liệu mẫu ban đầu.
-- =============================================================================

SET NAMES utf8mb4;
USE smart_ev_parking;

-- =============================================================================
-- TC1: Một xe không thể có hai phiên đang chạy (Active)
-- Mong đợi: ERROR 1062 (23000): Duplicate entry 'XE04' for key 'PHIEN.UQ_Phien_Active_Xe'
-- (Do xe XE04 đang có phiên P13 Active trên hệ thống)
-- =============================================================================
SELECT '--- DANG CHAY TC1 ---' AS Test_Case;
START TRANSACTION;
INSERT INTO PHIEN (MaPhien, MaXe, MaCho, LoaiPhien)
VALUES ('P90', 'XE04', 'CHO05', 'ParkingOnly');
ROLLBACK;

-- =============================================================================
-- TC2: Số dư ví không được âm
-- Mong đợi: ERROR 3819 (HY000): Check constraint 'CHK_KhachHang_SoDu' is violated.
-- =============================================================================
SELECT '--- DANG CHAY TC2 ---' AS Test_Case;
START TRANSACTION;
UPDATE KHACH_HANG SET SoDuViDienTu = -1 WHERE MaKH = 'KH01';
ROLLBACK;

-- =============================================================================
-- TC3: Giá sạc bắt buộc có loại trụ (LoaiGia = 'Charging' yêu cầu MaLoaiTru NOT NULL và LoaiCho IS NULL)
-- Mong đợi: ERROR 3819 (HY000): Check constraint 'CHK_LoaiGia_LoaiTru' is violated.
-- =============================================================================
SELECT '--- DANG CHAY TC3 ---' AS Test_Case;
START TRANSACTION;
INSERT INTO BANG_GIA (MaBangGia, LoaiGia, MaLoaiTru, LoaiCho, GioBatDau, GioKetThuc,
                      LaCaoDiem, DonGiaTheoPhut, HieuLucTu, MaQTV)
VALUES ('BG99', 'Charging', NULL, NULL, '06:00', '22:00', TRUE, 1000, '2026-11-01', 'QTV01');
ROLLBACK;

-- =============================================================================
-- TC4: Không mở phiên sạc trên trụ hỏng hoặc bảo trì
-- Mong đợi: ERROR 1644 (45000): Trụ sạc TS08 đang bảo trì hoặc báo lỗi
-- =============================================================================
SELECT '--- DANG CHAY TC4 ---' AS Test_Case;
START TRANSACTION;
INSERT INTO PHIEN (MaPhien, MaXe, MaCho, LoaiPhien)
VALUES ('P91', 'XE01', 'CHO11', 'ParkingAndCharging');
INSERT INTO CHI_TIET_PHIEN_SAC (MaPhien, MaTru, ThoiGianBatDauSac, ChiSoCongToDau)
VALUES ('P91', 'TS08', CURRENT_TIMESTAMP, 718);
ROLLBACK;

-- =============================================================================
-- TC5: Không đặt chỗ ở chỗ đang bảo trì (Maintenance)
-- Mong đợi: ERROR 1644 (45000): Ô đỗ CHO12 đang bảo trì kỹ thuật, vui lòng chọn ô khác!
-- =============================================================================
SELECT '--- DANG CHAY TC5 ---' AS Test_Case;
START TRANSACTION;
INSERT INTO DAT_CHO (MaDatCho, MaXe, MaCho, ThoiGianDat, ThoiGianHetHan)
VALUES ('DC90', 'XE01', 'CHO12', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL 30 MINUTE);
ROLLBACK;

-- =============================================================================
-- TC6: Xe máy không được đỗ ở ô đỗ ô tô (CarSlot)
-- Mong đợi: ERROR 1644 (45000): TRẢI NGHIỆM KHÁCH HÀNG: Xe máy không được đỗ tại ô đỗ ô tô (CarSlot)
-- =============================================================================
SELECT '--- DANG CHAY TC6 ---' AS Test_Case;
START TRANSACTION;
INSERT INTO PHIEN (MaPhien, MaXe, MaCho, LoaiPhien)
VALUES ('P92', 'XE10', 'CHO05', 'ParkingOnly');
ROLLBACK;

-- =============================================================================
-- TC7: Tài khoản bị khóa (Locked) không mở được phiên mới
-- Mong đợi: ERROR 1644 (45000): Tài khoản khách hàng đang bị khóa
-- =============================================================================
SELECT '--- DANG CHAY TC7 ---' AS Test_Case;
START TRANSACTION;
INSERT INTO PHIEN (MaPhien, MaXe, MaCho, LoaiPhien)
VALUES ('P93', 'XE08', 'CHO06', 'ParkingOnly');
ROLLBACK;

-- =============================================================================
-- TC8: Chuẩn súng sạc không khớp với cổng sạc của phương tiện
-- Mong đợi: ERROR 1644 (45000): Chuẩn sạc của xe (CCS2) không khớp với súng sạc (Type2) của trụ TS04
-- =============================================================================
SELECT '--- DANG CHAY TC8 ---' AS Test_Case;
START TRANSACTION;
INSERT INTO PHIEN (MaPhien, MaXe, MaCho, LoaiPhien)
VALUES ('P94', 'XE01', 'CHO06', 'ParkingAndCharging');
INSERT INTO CHI_TIET_PHIEN_SAC (MaPhien, MaTru, ThoiGianBatDauSac, ChiSoCongToDau)
VALUES ('P94', 'TS04', CURRENT_TIMESTAMP, 322);
ROLLBACK;

-- =============================================================================
-- TC9: Sổ cái ví bất biến (Append-Only) - cấm sửa hoặc xóa
-- Mong đợi: ERROR 1644 (45000): AN TOÀN TÀI CHÍNH: Bảng GIAO_DICH_VI là sổ cái bất biến (Append-Only), nghiêm cấm sửa hoặc xóa dữ liệu!
-- =============================================================================
SELECT '--- DANG CHAY TC9 ---' AS Test_Case;
START TRANSACTION;
UPDATE GIAO_DICH_VI SET SoTien = 1 WHERE MaGD = 'GD01';
ROLLBACK;

-- =============================================================================
-- TC10: Số dư trước/sau của giao dịch phải khớp với loại giao dịch
-- Mong đợi: ERROR 3819 (HY000): Check constraint 'CHK_GiaoDich_SoDu' is violated.
-- (Deposit 100k: 542k + 100k = 642k, nhập 600k là sai)
-- =============================================================================
SELECT '--- DANG CHAY TC10 ---' AS Test_Case;
START TRANSACTION;
INSERT INTO GIAO_DICH_VI (MaGD, MaKH, LoaiGD, SoTien, SoDuTruoc, SoDuSau)
VALUES ('GD90', 'KH01', 'Deposit', 100000, 542000, 600000);
ROLLBACK;

-- =============================================================================
-- TC11: Phiên mở từ đặt chỗ phải đúng xe đã đăng ký giữ chỗ
-- Mong đợi: ERROR 1644 (45000): Xe trong phiên (XE01) không khớp xe đặt chỗ (XE03)
-- =============================================================================
SELECT '--- DANG CHAY TC11 ---' AS Test_Case;
START TRANSACTION;
INSERT INTO PHIEN (MaPhien, MaXe, MaCho, MaDatCho, LoaiPhien)
VALUES ('P95', 'XE01', 'CHO05', 'DC01', 'ParkingOnly');
ROLLBACK;

-- =============================================================================
-- TC12: Thanh toán ví khi số dư không đủ
-- Mong đợi: ERROR 1644 (45000): Số dư ví (161000.00) không đủ thanh toán (205000.00)
-- =============================================================================
SELECT '--- DANG CHAY TC12 ---' AS Test_Case;
CALL sp_thanh_toan_hoa_don_vi('KH04', 'HD12', 'IDEM-DEMO-01');

-- =============================================================================
-- TC13: Không được thanh toán hóa đơn của khách hàng khác
-- Mong đợi: ERROR 1644 (45000): Hóa đơn HD12 không thuộc khách hàng KH01
-- =============================================================================
SELECT '--- DANG CHAY TC13 ---' AS Test_Case;
CALL sp_thanh_toan_hoa_don_vi('KH01', 'HD12', 'IDEM-DEMO-02');

-- =============================================================================
-- TC14: Đặt chỗ mới đưa trạng thái chỗ đỗ sang Reserved
-- Mong đợi: TrangThaiCho chuyển từ 'Available' sang 'Reserved' thành công
-- =============================================================================
SELECT '--- DANG CHAY TC14 ---' AS Test_Case;
START TRANSACTION;
INSERT INTO DAT_CHO (MaDatCho, MaXe, MaCho, ThoiGianDat, ThoiGianHetHan)
VALUES ('DC91', 'XE01', 'CHO05', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL 30 MINUTE);
SELECT MaCho, TrangThaiCho FROM CHO_DO_XE WHERE MaCho = 'CHO05';
ROLLBACK;

-- =============================================================================
-- TC15: Không mở phiên từ đặt chỗ đã hết hạn hoặc bị hủy
-- Mong đợi: ERROR 1644 (45000): Đặt chỗ DC05 đã bị hủy hoặc hết hạn
-- =============================================================================
SELECT '--- DANG CHAY TC15 ---' AS Test_Case;
START TRANSACTION;
INSERT INTO PHIEN (MaPhien, MaXe, MaCho, MaDatCho, LoaiPhien)
VALUES ('P96', 'XE01', 'CHO05', 'DC05', 'ParkingOnly');
ROLLBACK;

-- =============================================================================
-- TC16: Trụ sạc phải thuộc đúng chỗ đỗ của phiên
-- Mong đợi: ERROR 1644 (45000): Trụ sạc TS02 không thuộc chỗ đỗ CHO06 của phiên
-- =============================================================================
SELECT '--- DANG CHAY TC16 ---' AS Test_Case;
START TRANSACTION;
INSERT INTO PHIEN (MaPhien, MaXe, MaCho, LoaiPhien)
VALUES ('P97', 'XE01', 'CHO06', 'ParkingAndCharging');
INSERT INTO CHI_TIET_PHIEN_SAC (MaPhien, MaTru, ChiSoCongToDau, ThoiGianBatDauSac)
VALUES ('P97', 'TS02', 5060.00, CURRENT_TIMESTAMP);
ROLLBACK;
