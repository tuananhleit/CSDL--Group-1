SET NAMES utf8mb4;
USE smart_ev_parking;

DELIMITER $$

CREATE PROCEDURE sp_dong_bo_trang_thai_phien(
    IN p_ma_cho      VARCHAR(20),
    IN p_loai_phien  VARCHAR(20),
    IN p_trang_thai  VARCHAR(20),
    IN p_ma_dat_cho  VARCHAR(20)
)
BEGIN
    IF p_trang_thai = 'Active' THEN
        UPDATE CHO_DO_XE SET TrangThaiCho = 'Occupied'
        WHERE MaCho = p_ma_cho AND TrangThaiCho IN ('Available', 'Reserved');

        IF p_loai_phien = 'ParkingAndCharging' THEN
            UPDATE TRU_SAC SET TrangThaiTru = 'Charging'
            WHERE MaCho = p_ma_cho AND TrangThaiTru = 'Available';
        END IF;

    ELSEIF p_trang_thai IN ('Completed', 'Cancelled', 'Interrupted') THEN
        UPDATE CHO_DO_XE
        SET TrangThaiCho = CASE
            WHEN EXISTS (SELECT 1 FROM DAT_CHO d
                         WHERE d.MaCho = p_ma_cho
                           AND d.TrangThaiDatCho = 'Active'
                           AND d.MaDatCho <> COALESCE(p_ma_dat_cho, ''))
            THEN 'Reserved' ELSE 'Available' END
        WHERE MaCho = p_ma_cho AND TrangThaiCho = 'Occupied';

        UPDATE TRU_SAC SET TrangThaiTru = 'Available'
        WHERE MaCho = p_ma_cho AND TrangThaiTru = 'Charging';

        IF p_ma_dat_cho IS NOT NULL THEN
            UPDATE DAT_CHO SET TrangThaiDatCho = 'Completed' WHERE MaDatCho = p_ma_dat_cho;
        END IF;
    END IF;
END$$

CREATE FUNCTION fn_tinh_an_han(p_ma_phien VARCHAR(20), p_ket_thuc DATETIME)
RETURNS DATETIME
READS SQL DATA
BEGIN
    DECLARE v_phutanhan INT;

    SELECT t.PhutAnHanSauSac INTO v_phutanhan
    FROM   PHIEN p
    JOIN   CHO_DO_XE c ON p.MaCho = c.MaCho
    JOIN   TRAM t      ON c.MaTram = t.MaTram
    WHERE  p.MaPhien = p_ma_phien;

    RETURN DATE_ADD(p_ket_thuc, INTERVAL COALESCE(v_phutanhan, 15) MINUTE);
END$$

CREATE TRIGGER TRG_Phien_CheckLoaiXe
BEFORE INSERT ON PHIEN
FOR EACH ROW
BEGIN
    DECLARE v_loaixe  VARCHAR(20);
    DECLARE v_loaicho VARCHAR(20);

    SELECT LoaiXe  INTO v_loaixe  FROM PHUONG_TIEN WHERE MaXe  = NEW.MaXe;
    SELECT LoaiCho INTO v_loaicho FROM CHO_DO_XE   WHERE MaCho = NEW.MaCho;

    IF v_loaixe = 'Motorbike_2W' AND v_loaicho = 'CarSlot' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'TRẢI NGHIỆM KHÁCH HÀNG: Xe máy không được đỗ tại ô đỗ ô tô (CarSlot)';
    END IF;
    IF v_loaixe = 'Car_4W' AND v_loaicho = 'MotorbikeSlot' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'TRẢI NGHIỆM KHÁCH HÀNG: Ô tô không được đỗ tại ô đỗ xe máy (MotorbikeSlot)';
    END IF;
END$$

CREATE TRIGGER TRG_DatCho_CheckLoaiXe
BEFORE INSERT ON DAT_CHO
FOR EACH ROW
BEGIN
    DECLARE v_loaixe  VARCHAR(20);
    DECLARE v_loaicho VARCHAR(20);

    SELECT LoaiXe  INTO v_loaixe  FROM PHUONG_TIEN WHERE MaXe  = NEW.MaXe;
    SELECT LoaiCho INTO v_loaicho FROM CHO_DO_XE   WHERE MaCho = NEW.MaCho;

    IF v_loaixe = 'Motorbike_2W' AND v_loaicho = 'CarSlot' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Xe máy không được đặt chỗ ô tô (CarSlot)';
    END IF;
    IF v_loaixe = 'Car_4W' AND v_loaicho = 'MotorbikeSlot' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ô tô không được đặt chỗ xe máy (MotorbikeSlot)';
    END IF;
END$$

CREATE TRIGGER TRG_DatCho_KiemTraBaoTri
BEFORE INSERT ON DAT_CHO
FOR EACH ROW
BEGIN
    DECLARE v_msg VARCHAR(128);
    DECLARE v_trangthai VARCHAR(20);

    SELECT TrangThaiCho INTO v_trangthai FROM CHO_DO_XE WHERE MaCho = NEW.MaCho;

    IF v_trangthai = 'Maintenance' THEN
        SET v_msg = CONCAT('Ô đỗ ', NEW.MaCho, ' đang bảo trì kỹ thuật, vui lòng chọn ô khác!');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
END$$

CREATE TRIGGER TRG_Phien_KiemTraBaoTri
BEFORE INSERT ON PHIEN
FOR EACH ROW
BEGIN
    DECLARE v_msg VARCHAR(128);
    DECLARE v_trangthai VARCHAR(20);

    SELECT TrangThaiCho INTO v_trangthai FROM CHO_DO_XE WHERE MaCho = NEW.MaCho;

    IF v_trangthai = 'Maintenance' THEN
        SET v_msg = CONCAT('Ô đỗ ', NEW.MaCho, ' đang bảo trì kỹ thuật, vui lòng chọn ô khác!');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
END$$

CREATE TRIGGER TRG_DatCho_KiemTraKhoaDen
BEFORE INSERT ON DAT_CHO
FOR EACH ROW
BEGIN
    DECLARE v_msg VARCHAR(128);
    DECLARE v_bidenkhoa BOOLEAN;

    SELECT BiDenKhoa INTO v_bidenkhoa FROM PHUONG_TIEN WHERE MaXe = NEW.MaXe;

    IF v_bidenkhoa = TRUE THEN
        SET v_msg = CONCAT('Phương tiện ', NEW.MaXe, ' đang có khoản nợ chưa thanh toán');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
END$$

CREATE TRIGGER TRG_Phien_KiemTraDatChoKhop
BEFORE INSERT ON PHIEN
FOR EACH ROW
BEGIN
    DECLARE v_msg VARCHAR(128);
    DECLARE v_maxe_datcho  VARCHAR(20);
    DECLARE v_macho_datcho VARCHAR(20);
    DECLARE v_trangthai_datcho VARCHAR(20);

    IF NEW.MaDatCho IS NOT NULL THEN
        SELECT MaXe, MaCho, TrangThaiDatCho INTO v_maxe_datcho, v_macho_datcho, v_trangthai_datcho
        FROM DAT_CHO WHERE MaDatCho = NEW.MaDatCho;

        IF v_maxe_datcho <> NEW.MaXe THEN
            SET v_msg = CONCAT('Xe trong phiên (', NEW.MaXe, ') không khớp xe đặt chỗ (', v_maxe_datcho, ')');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
        END IF;
        IF v_macho_datcho <> NEW.MaCho THEN
            SET v_msg = CONCAT('Chỗ đỗ trong phiên (', NEW.MaCho, ') không khớp chỗ đặt (', v_macho_datcho, ')');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
        END IF;
        IF v_trangthai_datcho IN ('Cancelled', 'Expired') THEN
            SET v_msg = CONCAT('Đặt chỗ ', NEW.MaDatCho, ' đã bị hủy hoặc hết hạn');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
        END IF;
    END IF;
END$$

CREATE TRIGGER TRG_Phien_KiemTraDieuKienMo
BEFORE INSERT ON PHIEN
FOR EACH ROW
BEGIN
    DECLARE v_msg VARCHAR(128);
    DECLARE v_trangthaitk   VARCHAR(20);
    DECLARE v_loaikhach     VARCHAR(20);
    DECLARE v_soduthucte    DECIMAL(12, 2);
    DECLARE v_sodutoithieu  DECIMAL(12, 2);

    SELECT kh.TrangThaiTK, kh.SoDuViDienTu, kh.LoaiKhach
    INTO   v_trangthaitk, v_soduthucte, v_loaikhach
    FROM   PHUONG_TIEN pt
    JOIN   KHACH_HANG kh ON pt.MaKH = kh.MaKH
    WHERE  pt.MaXe = NEW.MaXe;

    SELECT t.SoDuToiThieu INTO v_sodutoithieu
    FROM   CHO_DO_XE c
    JOIN   TRAM t ON c.MaTram = t.MaTram
    WHERE  c.MaCho = NEW.MaCho;

    IF v_trangthaitk <> 'Active' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tài khoản khách hàng đang bị khóa';
    END IF;

    IF v_loaikhach = 'Registered' AND v_soduthucte < v_sodutoithieu THEN
        SET v_msg = CONCAT('Số dư ví (', v_soduthucte, ') chưa đạt mức tối thiểu mở phiên của trạm (', v_sodutoithieu, ')');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
END$$

CREATE TRIGGER TRG_Phien_KiemTraKhoaDen
BEFORE INSERT ON PHIEN
FOR EACH ROW
BEGIN
    DECLARE v_msg VARCHAR(128);
    DECLARE v_bidenkhoa BOOLEAN;

    SELECT BiDenKhoa INTO v_bidenkhoa FROM PHUONG_TIEN WHERE MaXe = NEW.MaXe;

    IF v_bidenkhoa = TRUE THEN
        SET v_msg = CONCAT('Phương tiện ', NEW.MaXe, ' đang có khoản nợ chưa thanh toán');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
END$$

CREATE TRIGGER TRG_PhienSac_KiemTraTru
BEFORE INSERT ON CHI_TIET_PHIEN_SAC
FOR EACH ROW
BEGIN
    DECLARE v_msg VARCHAR(128);
    DECLARE v_trangthaitru VARCHAR(20);
    DECLARE v_chuanketnoi  VARCHAR(30);
    DECLARE v_chuansac_xe  VARCHAR(20);
    DECLARE v_macho_tru    VARCHAR(20);
    DECLARE v_macho_phien  VARCHAR(20);

    SELECT ts.TrangThaiTru, lts.ChuanKetNoi, ts.MaCho
    INTO   v_trangthaitru, v_chuanketnoi, v_macho_tru
    FROM   TRU_SAC ts
    JOIN   LOAI_TRU_SAC lts ON ts.MaLoaiTru = lts.MaLoaiTru
    WHERE  ts.MaTru = NEW.MaTru;

    IF v_trangthaitru IN ('Faulted', 'Maintenance') THEN
        SET v_msg = CONCAT('Trụ sạc ', NEW.MaTru, ' đang bảo trì hoặc báo lỗi');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    SELECT pt.ChuanSac, p.MaCho INTO v_chuansac_xe, v_macho_phien
    FROM   PHIEN p
    JOIN   PHUONG_TIEN pt ON p.MaXe = pt.MaXe
    WHERE  p.MaPhien = NEW.MaPhien;

    IF v_macho_tru <> v_macho_phien THEN
        SET v_msg = CONCAT('Trụ sạc ', NEW.MaTru, ' không thuộc chỗ đỗ ', v_macho_phien, ' của phiên');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    IF v_chuanketnoi <> 'Other' AND v_chuansac_xe <> 'Other' AND v_chuanketnoi <> v_chuansac_xe THEN
        SET v_msg = CONCAT('Chuẩn sạc của xe (', v_chuansac_xe, ') không khớp với súng sạc (',
                                      v_chuanketnoi, ') của trụ ', NEW.MaTru);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
END$$

CREATE TRIGGER TRG_Phien_SyncTrangThai_Ins
AFTER INSERT ON PHIEN
FOR EACH ROW
BEGIN
    CALL sp_dong_bo_trang_thai_phien(NEW.MaCho, NEW.LoaiPhien, NEW.TrangThaiPhien, NEW.MaDatCho);
END$$

CREATE TRIGGER TRG_Phien_SyncTrangThai_Upd
AFTER UPDATE ON PHIEN
FOR EACH ROW
BEGIN
    IF NOT (OLD.TrangThaiPhien <=> NEW.TrangThaiPhien) THEN
        CALL sp_dong_bo_trang_thai_phien(NEW.MaCho, NEW.LoaiPhien, NEW.TrangThaiPhien, NEW.MaDatCho);
    END IF;
END$$

CREATE TRIGGER TRG_PhienSac_AutoAnHan_Ins
BEFORE INSERT ON CHI_TIET_PHIEN_SAC
FOR EACH ROW
BEGIN
    IF NEW.ThoiGianKetThucSac IS NOT NULL AND NEW.ThoiGianHetAnHan IS NULL THEN
        SET NEW.ThoiGianHetAnHan = fn_tinh_an_han(NEW.MaPhien, NEW.ThoiGianKetThucSac);
    END IF;
END$$

CREATE TRIGGER TRG_PhienSac_AutoAnHan_Upd
BEFORE UPDATE ON CHI_TIET_PHIEN_SAC
FOR EACH ROW
BEGIN
    IF NOT (OLD.ThoiGianKetThucSac <=> NEW.ThoiGianKetThucSac)
       AND NEW.ThoiGianKetThucSac IS NOT NULL AND NEW.ThoiGianHetAnHan IS NULL THEN
        SET NEW.ThoiGianHetAnHan = fn_tinh_an_han(NEW.MaPhien, NEW.ThoiGianKetThucSac);
    END IF;
END$$

CREATE TRIGGER TRG_GiaoDichVi_Protect_Upd
BEFORE UPDATE ON GIAO_DICH_VI
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'AN TOÀN TÀI CHÍNH: Bảng GIAO_DICH_VI là sổ cái bất biến (Append-Only), nghiêm cấm sửa hoặc xóa dữ liệu!';
END$$

CREATE TRIGGER TRG_GiaoDichVi_Protect_Del
BEFORE DELETE ON GIAO_DICH_VI
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'AN TOÀN TÀI CHÍNH: Bảng GIAO_DICH_VI là sổ cái bất biến (Append-Only), nghiêm cấm sửa hoặc xóa dữ liệu!';
END$$

CREATE TRIGGER TRG_DatCho_Reserve_Ins
AFTER INSERT ON DAT_CHO
FOR EACH ROW
BEGIN
    IF NEW.TrangThaiDatCho = 'Active' THEN
        UPDATE CHO_DO_XE
        SET    TrangThaiCho = 'Reserved'
        WHERE  MaCho = NEW.MaCho AND TrangThaiCho = 'Available';
    END IF;
END$$

CREATE TRIGGER TRG_DatCho_Release_Upd
AFTER UPDATE ON DAT_CHO
FOR EACH ROW
BEGIN
    IF OLD.TrangThaiDatCho = 'Active'
       AND NEW.TrangThaiDatCho IN ('Cancelled', 'Expired') THEN
        UPDATE CHO_DO_XE
        SET    TrangThaiCho = 'Available'
        WHERE  MaCho = NEW.MaCho AND TrangThaiCho = 'Reserved';
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE sp_kiem_tra_va_ngat_sac_tu_dong(
    IN p_ma_phien          VARCHAR(20),
    IN p_chi_so_cong_to    DECIMAL(10, 2),
    IN p_thoi_diem         DATETIME
)
sp_main: BEGIN
    DECLARE v_msg VARCHAR(128);
    DECLARE v_so_dong           INT DEFAULT 0;
    DECLARE v_chi_so_dau        DECIMAL(10, 2);
    DECLARE v_sokwh_dadung      DECIMAL(10, 2);
    DECLARE v_chiphi_hientai    DECIMAL(12, 2);
    DECLARE v_hanmuc_vnd        DECIMAL(12, 2);
    DECLARE v_hanmuc_kwh        DECIMAL(6, 2);
    DECLARE v_sodu_vi           DECIMAL(12, 2);
    DECLARE v_loaikhach         VARCHAR(20);
    DECLARE v_ma_xe             VARCHAR(20);
    DECLARE v_ma_loai_tru       VARCHAR(20);
    DECLARE v_bat_dau_sac       DATETIME;
    DECLARE v_thoi_diem         DATETIME;
    DECLARE v_so_phut           INT;
    DECLARE v_don_gia_phut      DECIMAL(10, 2);
    DECLARE v_trang_thai_sac    VARCHAR(20);

    SET v_thoi_diem = COALESCE(p_thoi_diem, CURRENT_TIMESTAMP);

    SELECT COUNT(*) INTO v_so_dong FROM CHI_TIET_PHIEN_SAC WHERE MaPhien = p_ma_phien;
    IF v_so_dong = 0 THEN
        SET v_msg = CONCAT('Phiên sạc ', p_ma_phien, ' không tồn tại');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    SELECT ct.ChiSoCongToDau, ct.HanMucSac_VND, ct.HanMucSac_kWh, ct.ThoiGianBatDauSac,
           ts.MaLoaiTru, p.MaXe, ct.TrangThaiSac
    INTO   v_chi_so_dau, v_hanmuc_vnd, v_hanmuc_kwh, v_bat_dau_sac,
           v_ma_loai_tru, v_ma_xe, v_trang_thai_sac
    FROM   CHI_TIET_PHIEN_SAC ct
    JOIN   PHIEN    p  ON ct.MaPhien = p.MaPhien
    JOIN   TRU_SAC  ts ON ct.MaTru   = ts.MaTru
    WHERE  ct.MaPhien = p_ma_phien;

    IF v_trang_thai_sac <> 'Charging' THEN
        SET v_msg = CONCAT('Phiên sạc ', p_ma_phien, ' không ở trạng thái đang sạc');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
    IF v_thoi_diem < v_bat_dau_sac OR p_chi_so_cong_to < v_chi_so_dau THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Thời điểm kiểm tra hoặc chỉ số công tơ nhỏ hơn giá trị lúc bắt đầu sạc';
    END IF;

    SET v_so_phut = GREATEST(0, TIMESTAMPDIFF(MINUTE, v_bat_dau_sac, v_thoi_diem));

    SELECT bg.DonGiaTheoPhut INTO v_don_gia_phut
    FROM   BANG_GIA bg
    WHERE  bg.LoaiGia   = 'Charging'
      AND  bg.MaLoaiTru = v_ma_loai_tru
      AND  TIME(v_thoi_diem) >= bg.GioBatDau
      AND  (TIME(v_thoi_diem) < bg.GioKetThuc OR bg.GioKetThuc = '23:59:59')
      AND  DATE(v_thoi_diem) >= bg.HieuLucTu
      AND  (bg.HieuLucDen IS NULL OR DATE(v_thoi_diem) <= bg.HieuLucDen)
    ORDER BY bg.HieuLucTu DESC
    LIMIT 1;

    IF v_don_gia_phut IS NULL THEN
        SET v_msg = CONCAT('Không có bảng giá sạc phù hợp cho loại trụ ', v_ma_loai_tru);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    SET v_sokwh_dadung   = GREATEST(0, p_chi_so_cong_to - v_chi_so_dau);
    SET v_chiphi_hientai = v_so_phut * v_don_gia_phut;

    SELECT kh.SoDuViDienTu, kh.LoaiKhach
    INTO   v_sodu_vi, v_loaikhach
    FROM   PHUONG_TIEN pt
    JOIN   KHACH_HANG kh ON pt.MaKH = kh.MaKH
    WHERE  pt.MaXe = v_ma_xe;

    IF v_hanmuc_vnd IS NOT NULL AND v_chiphi_hientai >= v_hanmuc_vnd THEN
        UPDATE CHI_TIET_PHIEN_SAC
        SET ChiSoCongToCuoi    = p_chi_so_cong_to,
            ThoiGianKetThucSac = v_thoi_diem,
            TrangThaiSac       = 'Completed',
            LyDoKetThuc        = 'AutoCutoff_LimitReached'
        WHERE MaPhien = p_ma_phien;
        LEAVE sp_main;
    END IF;

    IF v_hanmuc_kwh IS NOT NULL AND v_sokwh_dadung >= v_hanmuc_kwh THEN
        UPDATE CHI_TIET_PHIEN_SAC
        SET ChiSoCongToCuoi    = p_chi_so_cong_to,
            ThoiGianKetThucSac = v_thoi_diem,
            TrangThaiSac       = 'Completed',
            LyDoKetThuc        = 'AutoCutoff_LimitReached'
        WHERE MaPhien = p_ma_phien;
        LEAVE sp_main;
    END IF;

    IF v_loaikhach = 'Registered' AND (v_sodu_vi - v_chiphi_hientai) <= 5000.00 THEN
        UPDATE CHI_TIET_PHIEN_SAC
        SET ChiSoCongToCuoi    = p_chi_so_cong_to,
            ThoiGianKetThucSac = v_thoi_diem,
            TrangThaiSac       = 'Completed',
            LyDoKetThuc        = 'AutoCutoff_LowBalance'
        WHERE MaPhien = p_ma_phien;
        LEAVE sp_main;
    END IF;
END$$

CREATE PROCEDURE sp_thanh_toan_hoa_don_vi(
    IN p_ma_kh             VARCHAR(20),
    IN p_ma_hd             VARCHAR(20),
    IN p_idempotency_key   VARCHAR(100)
)
BEGIN
    DECLARE v_msg VARCHAR(128);
    DECLARE v_so_dong           INT DEFAULT 0;
    DECLARE v_soduthucte        DECIMAL(12, 2);
    DECLARE v_tongtien_hd       DECIMAL(12, 2);
    DECLARE v_trangthai_hd      VARCHAR(20);
    DECLARE v_ma_phien          VARCHAR(20);
    DECLARE v_ma_kh_hd          VARCHAR(20);
    DECLARE v_ma_gd             VARCHAR(20);
    DECLARE v_sodu_sau          DECIMAL(12, 2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_so_dong FROM KHACH_HANG WHERE MaKH = p_ma_kh;
    IF v_so_dong = 0 THEN
        SET v_msg = CONCAT('Khách hàng ', p_ma_kh, ' không tồn tại');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
    SELECT SoDuViDienTu INTO v_soduthucte FROM KHACH_HANG WHERE MaKH = p_ma_kh FOR UPDATE;

    SELECT hd.TongTien, hd.TrangThaiThanhToan, hd.MaPhien, pt.MaKH
    INTO   v_tongtien_hd, v_trangthai_hd, v_ma_phien, v_ma_kh_hd
    FROM   HOA_DON hd
    JOIN   PHIEN p        ON hd.MaPhien = p.MaPhien
    JOIN   PHUONG_TIEN pt ON p.MaXe     = pt.MaXe
    WHERE  hd.MaHD = p_ma_hd
    FOR UPDATE OF hd;

    IF v_trangthai_hd IS NULL THEN
        SET v_msg = CONCAT('Hóa đơn ', p_ma_hd, ' không tồn tại');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
    IF v_ma_kh_hd <> p_ma_kh THEN
        SET v_msg = CONCAT('Hóa đơn ', p_ma_hd, ' không thuộc khách hàng ', p_ma_kh);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
    IF v_trangthai_hd = 'Paid' THEN
        SET v_msg = CONCAT('Hóa đơn ', p_ma_hd, ' đã thanh toán!');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
    IF v_trangthai_hd = 'Refunded' THEN
        SET v_msg = CONCAT('Hóa đơn ', p_ma_hd, ' đã hoàn tiền, không thể thanh toán');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
    IF v_soduthucte < v_tongtien_hd THEN
        SET v_msg = CONCAT('Số dư ví (', v_soduthucte, ') không đủ thanh toán (', v_tongtien_hd, ')');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    IF v_tongtien_hd > 0 THEN
        SET v_sodu_sau = v_soduthucte - v_tongtien_hd;

        UPDATE KHACH_HANG SET SoDuViDienTu = v_sodu_sau WHERE MaKH = p_ma_kh;

        SET v_ma_gd = CONCAT('GD_PAY_', SUBSTRING(MD5(RAND()), 1, 8));
        INSERT INTO GIAO_DICH_VI (MaGD, MaKH, LoaiGD, SoTien, SoDuTruoc, SoDuSau, MaHD, MaGiaoDichDoiTac, GhiChu)
        VALUES (v_ma_gd, p_ma_kh, 'Payment', v_tongtien_hd, v_soduthucte, v_sodu_sau,
                p_ma_hd, p_idempotency_key, CONCAT('Thanh toán hóa đơn ', p_ma_hd));
    END IF;

    UPDATE HOA_DON
    SET TrangThaiThanhToan  = 'Paid',
        PhuongThucThanhToan = 'Wallet',
        NgayThanhToan       = CURRENT_TIMESTAMP
    WHERE MaHD = p_ma_hd;

    UPDATE PHIEN
    SET TrangThaiPhien = 'Completed',
        ThoiGianRa     = CURRENT_TIMESTAMP
    WHERE MaPhien = v_ma_phien;

    COMMIT;
END$$

CREATE PROCEDURE sp_thanh_toan_walkin_ngoai(
    IN p_ma_hd             VARCHAR(20),
    IN p_phuong_thuc       VARCHAR(30),
    IN p_ma_gd_ngoai       VARCHAR(100)
)
BEGIN
    DECLARE v_msg VARCHAR(128);
    DECLARE v_ma_phien          VARCHAR(20);
    DECLARE v_ma_kh             VARCHAR(20);
    DECLARE v_tong_tien         DECIMAL(12, 2);
    DECLARE v_trang_thai        VARCHAR(20);
    DECLARE v_sodu_hientai      DECIMAL(12, 2);
    DECLARE v_ma_gd             VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF COALESCE(p_phuong_thuc, '') NOT IN ('POS_Card', 'Dynamic_QR', 'Cash') THEN
        SET v_msg = CONCAT('Phương thức thanh toán trực tiếp không hợp lệ: ', COALESCE(p_phuong_thuc, 'NULL'));
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    SELECT hd.TongTien, hd.TrangThaiThanhToan, hd.MaPhien, pt.MaKH
    INTO   v_tong_tien, v_trang_thai, v_ma_phien, v_ma_kh
    FROM   HOA_DON hd
    JOIN   PHIEN p        ON hd.MaPhien = p.MaPhien
    JOIN   PHUONG_TIEN pt ON p.MaXe = pt.MaXe
    WHERE  hd.MaHD = p_ma_hd
    FOR UPDATE OF hd;

    IF v_trang_thai IS NULL THEN
        SET v_msg = CONCAT('Hóa đơn ', p_ma_hd, ' không tồn tại');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
    IF v_trang_thai = 'Paid' THEN
        SET v_msg = CONCAT('Hóa đơn ', p_ma_hd, ' đã thanh toán!');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
    IF v_trang_thai = 'Refunded' THEN
        SET v_msg = CONCAT('Hóa đơn ', p_ma_hd, ' đã hoàn tiền, không thể thanh toán');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    SELECT SoDuViDienTu INTO v_sodu_hientai FROM KHACH_HANG WHERE MaKH = v_ma_kh;

    UPDATE HOA_DON
    SET TrangThaiThanhToan  = 'Paid',
        PhuongThucThanhToan = p_phuong_thuc,
        MaGiaoDichNgoai     = p_ma_gd_ngoai,
        NgayThanhToan       = CURRENT_TIMESTAMP
    WHERE MaHD = p_ma_hd;

    IF v_tong_tien > 0 THEN
        SET v_ma_gd = CONCAT('GD_WALK_', SUBSTRING(MD5(RAND()), 1, 8));
        INSERT INTO GIAO_DICH_VI (MaGD, MaKH, LoaiGD, SoTien, SoDuTruoc, SoDuSau, MaHD, MaGiaoDichDoiTac, GhiChu)
        VALUES (v_ma_gd, v_ma_kh, 'DirectPayment', v_tong_tien, v_sodu_hientai, v_sodu_hientai,
                p_ma_hd, p_ma_gd_ngoai, CONCAT('Thanh toán trực tiếp (', p_phuong_thuc, ') cho ', p_ma_hd));
    END IF;

    UPDATE PHIEN
    SET TrangThaiPhien = 'Completed',
        ThoiGianRa     = CURRENT_TIMESTAMP
    WHERE MaPhien = v_ma_phien;

    COMMIT;
END$$

CREATE PROCEDURE sp_xu_ly_dat_cho_qua_han()
BEGIN
    DECLARE v_now DATETIME;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET v_now = CURRENT_TIMESTAMP;
    START TRANSACTION;

    UPDATE DAT_CHO d
    SET    d.TrangThaiDatCho = 'Expired'
    WHERE  d.TrangThaiDatCho = 'Active'
      AND  d.ThoiGianHetHan < v_now
      AND  NOT EXISTS (SELECT 1 FROM PHIEN p WHERE p.MaDatCho = d.MaDatCho);

    COMMIT;
END$$

DELIMITER ;
