-- =============================================================================
-- FILE 17: PROCEDURES - QUẢN LÝ VÍ & VẬN HÀNH AN TOÀN
-- =============================================================================
-- Mô tả: Các thủ tục Stored Procedures thân thiện người dùng:
--        - Tự động ngắt sạc khi chạm hạn mức mong muốn hoặc chạm trần số dư ví
--        - Thanh toán an toàn qua Ví (Row-level Lock FOR UPDATE chống Race Condition)
--        - Thanh toán tại barrier cổng ra bằng Dynamic QR cho khách vãng lai
--        - Tự động thu hồi ô đỗ khi đặt chỗ quá hạn
-- =============================================================================


-- =============================================================================
-- PROCEDURE 1: Kiểm tra công tơ & Tự động ngắt sạc (Real-time Auto Cut-off)
-- Mục đích: Khách không cần bị giam 500k; hệ thống chủ động ngắt dòng điện khi
--           đạt hạn mức khách cài (50k, 100k) hoặc khi chạm trần số dư ví.
-- =============================================================================
CREATE OR REPLACE PROCEDURE sp_kiem_tra_va_ngat_sac_tu_dong(
    p_ma_phien          VARCHAR(20),
    p_chi_so_cong_to    NUMERIC(10, 2),
    p_don_gia_kwh       NUMERIC(10, 2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_chi_so_dau        NUMERIC(10, 2);
    v_sokwh_dadung      NUMERIC(10, 2);
    v_chiphi_hientai    NUMERIC(12, 2);
    v_hanmuc_vnd        NUMERIC(12, 2);
    v_hanmuc_kwh        NUMERIC(6, 2);
    v_sodu_vi           NUMERIC(12, 2);
    v_loaikhach         VARCHAR(20);
    v_ma_xe             VARCHAR(20);
    v_ma_kh             VARCHAR(20);
BEGIN
    -- 1. Lấy thông tin phiên sạc
    SELECT ct.ChiSoCongToDau, ct.HanMucSac_VND, ct.HanMucSac_kWh, p.MaXe
    INTO   v_chi_so_dau, v_hanmuc_vnd, v_hanmuc_kwh, v_ma_xe
    FROM   CHI_TIET_PHIEN_SAC ct
    JOIN   PHIEN p ON ct.MaPhien = p.MaPhien
    WHERE  ct.MaPhien = p_ma_phien;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Phiên sạc % không tồn tại', p_ma_phien;
    END IF;

    -- 2. Tính số kWh và chi phí điện lũy kế đến thời điểm hiện tại
    v_sokwh_dadung   := GREATEST(0, p_chi_so_cong_to - v_chi_so_dau);
    v_chiphi_hientai := v_sokwh_dadung * COALESCE(p_don_gia_kwh, 3858.00);

    -- 3. Lấy số dư ví của khách
    SELECT kh.SoDuViDienTu, kh.LoaiKhach, kh.MaKH
    INTO   v_sodu_vi, v_loaikhach, v_ma_kh
    FROM   PHUONG_TIEN pt
    JOIN   KHACH_HANG kh ON pt.MaKH = kh.MaKH
    WHERE  pt.MaXe = v_ma_xe;

    -- 4. KIỂM TRA ĐIỀU KIỆN TỰ ĐỘNG NGẮT SẠC:
    -- Trường hợp A: Khách cài đặt hạn mức theo tiền (ví dụ: sạc 50.000đ)
    IF v_hanmuc_vnd IS NOT NULL AND v_chiphi_hientai >= v_hanmuc_vnd THEN
        UPDATE CHI_TIET_PHIEN_SAC
        SET ChiSoCongToCuoi    = p_chi_so_cong_to,
            ThoiGianKetThucSac = CURRENT_TIMESTAMP,
            TrangThaiSac       = 'Completed',
            LyDoKetThuc        = 'AutoCutoff_LimitReached'
        WHERE MaPhien = p_ma_phien;

        RAISE NOTICE 'Đã ngắt sạc phiên % do đạt hạn mức mong muốn (%.2f VND)', p_ma_phien, v_hanmuc_vnd;
        RETURN;
    END IF;

    -- Trường hợp B: Khách cài đặt hạn mức theo số kWh (ví dụ: sạc 10 kWh)
    IF v_hanmuc_kwh IS NOT NULL AND v_sokwh_dadung >= v_hanmuc_kwh THEN
        UPDATE CHI_TIET_PHIEN_SAC
        SET ChiSoCongToCuoi    = p_chi_so_cong_to,
            ThoiGianKetThucSac = CURRENT_TIMESTAMP,
            TrangThaiSac       = 'Completed',
            LyDoKetThuc        = 'AutoCutoff_LimitReached'
        WHERE MaPhien = p_ma_phien;

        RAISE NOTICE 'Đã ngắt sạc phiên % do đạt hạn mức kWh mong muốn (%.2f kWh)', p_ma_phien, v_hanmuc_kwh;
        RETURN;
    END IF;

    -- Trường hợp C: Khách sạc theo số dư ví (Ví còn bao nhiêu sạc bấy nhiêu)
    -- Khi tiền điện tiến sát số dư ví (chừa 5.000đ đệm an toàn) -> Ngắt sạc ngay
    IF v_loaikhach = 'Registered' AND (v_sodu_vi - v_chiphi_hientai) <= 5000.00 THEN
        UPDATE CHI_TIET_PHIEN_SAC
        SET ChiSoCongToCuoi    = p_chi_so_cong_to,
            ThoiGianKetThucSac = CURRENT_TIMESTAMP,
            TrangThaiSac       = 'Completed',
            LyDoKetThuc        = 'AutoCutoff_LowBalance'
        WHERE MaPhien = p_ma_phien;

        RAISE NOTICE 'Đã ngắt sạc an toàn phiên % do số dư ví chạm ngưỡng tối thiểu', p_ma_phien;
        RETURN;
    END IF;
END;
$$;


-- =============================================================================
-- PROCEDURE 2: Thanh toán Hóa đơn qua Ví điện tử (Dành cho Khách B2C)
-- Khóa dòng FOR UPDATE chống Race Condition, ghi sổ cái bất biến
-- =============================================================================
CREATE OR REPLACE PROCEDURE sp_thanh_toan_hoa_don_vi(
    p_ma_kh             VARCHAR(20),
    p_ma_hd             VARCHAR(20),
    p_idempotency_key   VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_soduthucte        NUMERIC(12, 2);
    v_tongtien_hd       NUMERIC(12, 2);
    v_trangthai_hd      VARCHAR(20);
    v_ma_phien          VARCHAR(20);
    v_ma_gd             VARCHAR(20);
    v_sodu_sau          NUMERIC(12, 2);
BEGIN
    -- 1. Khóa dòng khách hàng chống Race Condition
    SELECT SoDuViDienTu
    INTO   v_soduthucte
    FROM   KHACH_HANG
    WHERE  MaKH = p_ma_kh
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Khách hàng % không tồn tại', p_ma_kh;
    END IF;

    -- 2. Kiểm tra hóa đơn
    SELECT TongTien, TrangThaiThanhToan, MaPhien
    INTO   v_tongtien_hd, v_trangthai_hd, v_ma_phien
    FROM   HOA_DON
    WHERE  MaHD = p_ma_hd;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Hóa đơn % không tồn tại', p_ma_hd;
    END IF;

    IF v_trangthai_hd = 'Paid' THEN
        RAISE EXCEPTION 'Hóa đơn % đã được thanh toán trước đó!', p_ma_hd;
    END IF;

    IF v_soduthucte < v_tongtien_hd THEN
        RAISE EXCEPTION 'Số dư ví (%.2f) không đủ thanh toán tổng tiền hóa đơn (%.2f)',
            v_soduthucte, v_tongtien_hd;
    END IF;

    -- 3. Trừ tiền ví thực tế
    v_sodu_sau := v_soduthucte - v_tongtien_hd;

    UPDATE KHACH_HANG
    SET SoDuViDienTu = v_sodu_sau
    WHERE MaKH = p_ma_kh;

    -- 4. Ghi sổ cái bất biến (Append-Only)
    v_ma_gd := 'GD_PAY_' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8);

    INSERT INTO GIAO_DICH_VI (
        MaGD, MaKH, LoaiGD, SoTien, SoDuTruoc, SoDuSau,
        MaHD, MaGiaoDichDoiTac, GhiChu
    ) VALUES (
        v_ma_gd, p_ma_kh, 'Payment', v_tongtien_hd, v_soduthucte, v_sodu_sau,
        p_ma_hd, p_idempotency_key, 'Thanh toán hóa đơn ' || p_ma_hd
    );

    -- 5. Cập nhật hóa đơn
    UPDATE HOA_DON
    SET TrangThaiThanhToan  = 'Paid',
        PhuongThucThanhToan = 'Wallet',
        NgayThanhToan       = CURRENT_TIMESTAMP
    WHERE MaHD = p_ma_hd;

    -- 6. Hoàn tất phiên dịch vụ (Trigger TRG_Phien_SyncTrangThai sẽ tự động giải phóng ô đỗ/trụ sạc)
    UPDATE PHIEN
    SET TrangThaiPhien = 'Completed',
        ThoiGianRa     = CURRENT_TIMESTAMP
    WHERE MaPhien = v_ma_phien;

    RAISE NOTICE 'Thanh toán thành công hóa đơn %, số dư ví còn lại: %.2f', p_ma_hd, v_sodu_sau;
END;
$$;


-- =============================================================================
-- PROCEDURE 3: Thanh toán trực tiếp ngoài ví tại Barrier (Khách Vãng Lai Walk-in)
-- Quét Dynamic QR (VietQR), Quẹt thẻ POS hoặc Tiền mặt tại Kiosk/Barrier cổng ra
-- =============================================================================
CREATE OR REPLACE PROCEDURE sp_thanh_toan_walkin_ngoai(
    p_ma_hd             VARCHAR(20),
    p_phuong_thuc       VARCHAR(30),
    p_ma_gd_ngoai       VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ma_phien          VARCHAR(20);
    v_ma_kh             VARCHAR(20);
    v_tong_tien         NUMERIC(12, 2);
    v_trang_thai        VARCHAR(20);
    v_sodu_hientai      NUMERIC(12, 2);
    v_ma_gd             VARCHAR(20);
BEGIN
    SELECT hd.TongTien, hd.TrangThaiThanhToan, hd.MaPhien, pt.MaKH
    INTO   v_tong_tien, v_trang_thai, v_ma_phien, v_ma_kh
    FROM   HOA_DON hd
    JOIN   PHIEN p ON hd.MaPhien = p.MaPhien
    JOIN   PHUONG_TIEN pt ON p.MaXe = pt.MaXe
    WHERE  hd.MaHD = p_ma_hd;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Hóa đơn % không tồn tại', p_ma_hd;
    END IF;

    IF v_trang_thai = 'Paid' THEN
        RAISE EXCEPTION 'Hóa đơn % đã được thanh toán!', p_ma_hd;
    END IF;

    SELECT SoDuViDienTu INTO v_sodu_hientai FROM KHACH_HANG WHERE MaKH = v_ma_kh;

    -- 1. Cập nhật hóa đơn
    UPDATE HOA_DON
    SET TrangThaiThanhToan  = 'Paid',
        PhuongThucThanhToan = p_phuong_thuc,
        MaGiaoDichNgoai     = p_ma_gd_ngoai,
        NgayThanhToan       = CURRENT_TIMESTAMP
    WHERE MaHD = p_ma_hd;

    -- 2. Ghi sổ cái đối soát kế toán (DirectPayment, số dư ví không đổi)
    v_ma_gd := 'GD_WALK_' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8);

    INSERT INTO GIAO_DICH_VI (
        MaGD, MaKH, LoaiGD, SoTien, SoDuTruoc, SoDuSau,
        MaHD, MaGiaoDichDoiTac, GhiChu
    ) VALUES (
        v_ma_gd, v_ma_kh, 'DirectPayment', v_tong_tien, v_sodu_hientai, v_sodu_hientai,
        p_ma_hd, p_ma_gd_ngoai, 'Thanh toán trực tiếp (' || p_phuong_thuc || ') cho hóa đơn ' || p_ma_hd
    );

    -- 3. Đóng phiên (Trigger tự động giải phóng chỗ đỗ và kích hoạt barrier mở)
    UPDATE PHIEN
    SET TrangThaiPhien = 'Completed',
        ThoiGianRa     = CURRENT_TIMESTAMP
    WHERE MaPhien = v_ma_phien;

    RAISE NOTICE 'Thanh toán thành công cho khách vãng lai, mở barrier cho phiên %', v_ma_phien;
END;
$$;


-- =============================================================================
-- PROCEDURE 4: Xử lý Đặt chỗ quá hạn (No-Show Reaper)
-- Tự động giải phóng ô đỗ bị chiếm dụng ảo
-- =============================================================================
CREATE OR REPLACE PROCEDURE sp_xu_ly_dat_cho_qua_han()
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT MaDatCho, MaCho, TienCoc
        FROM   DAT_CHO
        WHERE  TrangThaiDatCho = 'Active'
          AND  ThoiGianHetHan < CURRENT_TIMESTAMP
    LOOP
        -- 1. Đánh dấu quá hạn
        UPDATE DAT_CHO
        SET TrangThaiDatCho = 'Expired'
        WHERE MaDatCho = r.MaDatCho;

        -- 2. Trả chỗ đỗ về trạng thái Available nếu không có xe nào đang đỗ thực tế
        UPDATE CHO_DO_XE
        SET TrangThaiCho = 'Available'
        WHERE MaCho = r.MaCho
          AND TrangThaiCho = 'Reserved';

        RAISE NOTICE 'Đã giải phóng ô đỗ % do đặt chỗ % quá hạn', r.MaCho, r.MaDatCho;
    END LOOP;
END;
$$;
