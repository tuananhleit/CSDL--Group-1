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

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Không tìm thấy khách hàng cho phương tiện %', v_ma_xe;
    END IF;

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
    v_soduthucte           NUMERIC(12, 2);
    v_tongtien_hd          NUMERIC(12, 2);
    v_trangthai_hd         VARCHAR(20);
    v_ma_phien             VARCHAR(20);
    v_ma_gd                VARCHAR(20);
    v_sodu_sau             NUMERIC(12, 2);
    v_ma_kh_chu_hoa_don    VARCHAR(20);
    v_ma_hd_idempotent     VARCHAR(20);
BEGIN
    IF p_idempotency_key IS NULL OR BTRIM(p_idempotency_key) = '' THEN
        RAISE EXCEPTION 'Idempotency key là bắt buộc cho thanh toán ví';
    END IF;

    -- 1. Khóa dòng khách hàng chống Race Condition
    SELECT SoDuViDienTu
    INTO   v_soduthucte
    FROM   KHACH_HANG
    WHERE  MaKH = p_ma_kh
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Khách hàng % không tồn tại', p_ma_kh;
    END IF;

    -- 2. Kiểm tra hóa đơn + chủ sở hữu thực sự
    SELECT hd.TongTien, hd.TrangThaiThanhToan, hd.MaPhien, pt.MaKH
    INTO   v_tongtien_hd, v_trangthai_hd, v_ma_phien, v_ma_kh_chu_hoa_don
    FROM   HOA_DON hd
    JOIN   PHIEN p ON p.MaPhien = hd.MaPhien
    JOIN   PHUONG_TIEN pt ON pt.MaXe = p.MaXe
    WHERE  hd.MaHD = p_ma_hd
    FOR UPDATE OF hd;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Hóa đơn % không tồn tại', p_ma_hd;
    END IF;

    IF v_ma_kh_chu_hoa_don <> p_ma_kh THEN
        RAISE EXCEPTION 'Khách hàng % không phải chủ sở hữu hóa đơn %', p_ma_kh, p_ma_hd;
    END IF;

    -- 3. Idempotency thật sự: cùng key + cùng hóa đơn => thành công không trừ ví lần 2
    --    cùng key + hóa đơn khác => lỗi
    SELECT MaHD
    INTO   v_ma_hd_idempotent
    FROM   GIAO_DICH_VI
    WHERE  MaGiaoDichDoiTac = p_idempotency_key;

    IF FOUND THEN
        IF v_ma_hd_idempotent = p_ma_hd THEN
            RAISE NOTICE 'Retry idempotent cho key %, hóa đơn % đã xử lý trước đó. Không trừ ví lần hai.',
                p_idempotency_key, p_ma_hd;
            RETURN;
        END IF;

        RAISE EXCEPTION 'Idempotency key % đã được dùng cho hóa đơn khác (%)',
            p_idempotency_key, v_ma_hd_idempotent;
    END IF;

    IF v_trangthai_hd = 'Paid' THEN
        RAISE EXCEPTION 'Hóa đơn % đã được thanh toán trước đó!', p_ma_hd;
    END IF;

    IF v_soduthucte < v_tongtien_hd THEN
        RAISE EXCEPTION 'Số dư ví (%.2f) không đủ thanh toán tổng tiền hóa đơn (%.2f)',
            v_soduthucte, v_tongtien_hd;
    END IF;

    -- 4. Trừ tiền ví thực tế
    v_sodu_sau := v_soduthucte - v_tongtien_hd;

    UPDATE KHACH_HANG
    SET SoDuViDienTu = v_sodu_sau
    WHERE MaKH = p_ma_kh;

    -- 5. Ghi sổ cái bất biến (Append-Only)
    v_ma_gd := 'GD_PAY_' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8);

    INSERT INTO GIAO_DICH_VI (
        MaGD, MaKH, LoaiGD, SoTien, SoDuTruoc, SoDuSau,
        MaHD, MaGiaoDichDoiTac, GhiChu
    ) VALUES (
        v_ma_gd, p_ma_kh, 'Payment', v_tongtien_hd, v_soduthucte, v_sodu_sau,
        p_ma_hd, p_idempotency_key, 'Thanh toán hóa đơn ' || p_ma_hd
    );

    -- 6. Cập nhật hóa đơn
    UPDATE HOA_DON
    SET TrangThaiThanhToan  = 'Paid',
        PhuongThucThanhToan = 'Wallet',
        NgayThanhToan       = CURRENT_TIMESTAMP
    WHERE MaHD = p_ma_hd;

    -- 7. Hoàn tất phiên dịch vụ
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
    v_loai_khach        VARCHAR(20);
    v_tong_tien         NUMERIC(12, 2);
    v_trang_thai        VARCHAR(20);
    v_sodu_hientai      NUMERIC(12, 2);
    v_ma_gd             VARCHAR(20);
BEGIN
    IF p_phuong_thuc NOT IN ('POS_Card', 'Dynamic_QR', 'Cash') THEN
        RAISE EXCEPTION 'Walk-in chỉ hỗ trợ POS_Card, Dynamic_QR hoặc Cash. Giá trị nhận được: %', p_phuong_thuc;
    END IF;

    IF p_phuong_thuc IN ('POS_Card', 'Dynamic_QR')
       AND (p_ma_gd_ngoai IS NULL OR BTRIM(p_ma_gd_ngoai) = '') THEN
        RAISE EXCEPTION 'Phương thức % bắt buộc có mã giao dịch ngoài', p_phuong_thuc;
    END IF;

    SELECT hd.TongTien, hd.TrangThaiThanhToan, hd.MaPhien, pt.MaKH, kh.LoaiKhach
    INTO   v_tong_tien, v_trang_thai, v_ma_phien, v_ma_kh, v_loai_khach
    FROM   HOA_DON hd
    JOIN   PHIEN p ON hd.MaPhien = p.MaPhien
    JOIN   PHUONG_TIEN pt ON p.MaXe = pt.MaXe
    JOIN   KHACH_HANG kh ON kh.MaKH = pt.MaKH
    WHERE  hd.MaHD = p_ma_hd
    FOR UPDATE OF hd;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Hóa đơn % không tồn tại', p_ma_hd;
    END IF;

    IF v_loai_khach <> 'WalkIn' THEN
        RAISE EXCEPTION 'Hóa đơn % không thuộc khách WalkIn, không dùng thủ tục thanh toán ngoài ví', p_ma_hd;
    END IF;

    IF v_trang_thai = 'Paid' THEN
        RAISE EXCEPTION 'Hóa đơn % đã được thanh toán!', p_ma_hd;
    END IF;

    IF p_ma_gd_ngoai IS NOT NULL AND BTRIM(p_ma_gd_ngoai) <> '' THEN
        IF EXISTS (
            SELECT 1
            FROM HOA_DON
            WHERE MaGiaoDichNgoai = p_ma_gd_ngoai
              AND MaHD <> p_ma_hd
        ) THEN
            RAISE EXCEPTION 'Mã giao dịch ngoài % đã được dùng cho hóa đơn khác', p_ma_gd_ngoai;
        END IF;
    END IF;

    SELECT SoDuViDienTu INTO v_sodu_hientai FROM KHACH_HANG WHERE MaKH = v_ma_kh;

    -- 1. Cập nhật hóa đơn
    UPDATE HOA_DON
    SET TrangThaiThanhToan  = 'Paid',
        PhuongThucThanhToan = p_phuong_thuc,
        MaGiaoDichNgoai     = NULLIF(BTRIM(p_ma_gd_ngoai), ''),
        NgayThanhToan       = CURRENT_TIMESTAMP
    WHERE MaHD = p_ma_hd;

    -- 2. Ghi sổ cái đối soát kế toán (DirectPayment, số dư ví không đổi)
    v_ma_gd := 'GD_WALK_' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8);

    INSERT INTO GIAO_DICH_VI (
        MaGD, MaKH, LoaiGD, SoTien, SoDuTruoc, SoDuSau,
        MaHD, MaGiaoDichDoiTac, GhiChu
    ) VALUES (
        v_ma_gd, v_ma_kh, 'DirectPayment', v_tong_tien, v_sodu_hientai, v_sodu_hientai,
        p_ma_hd, NULLIF(BTRIM(p_ma_gd_ngoai), ''), 'Thanh toán trực tiếp (' || p_phuong_thuc || ') cho hóa đơn ' || p_ma_hd
    );

    -- 3. Đóng phiên
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
          AND TrangThaiCho = 'Reserved'
          AND NOT EXISTS (
              SELECT 1
              FROM PHIEN p
              WHERE p.MaCho = r.MaCho
                AND p.TrangThaiPhien = 'Active'
          );

        RAISE NOTICE 'Đã giải phóng ô đỗ % do đặt chỗ % quá hạn', r.MaCho, r.MaDatCho;
    END LOOP;
END;
$$;


-- =============================================================================
-- TEST SQL THAM KHẢO (chạy thủ công, không auto-run)
-- =============================================================================
-- 1) Sai chủ hóa đơn (phải báo lỗi)
-- CALL sp_thanh_toan_hoa_don_vi('KH_A', 'HD_CUA_KH_B', 'IDEMP_OWNER_001');
--
-- 2) Idempotency retry cùng key/cùng hóa đơn (lần 2 không trừ ví lần nữa)
-- CALL sp_thanh_toan_hoa_don_vi('KH001', 'HD001', 'IDEMP_OK_001');
-- CALL sp_thanh_toan_hoa_don_vi('KH001', 'HD001', 'IDEMP_OK_001');
--
-- 3) Idempotency cùng key/khác hóa đơn (phải báo lỗi)
-- CALL sp_thanh_toan_hoa_don_vi('KH001', 'HD001', 'IDEMP_COLLISION_001');
-- CALL sp_thanh_toan_hoa_don_vi('KH001', 'HD002', 'IDEMP_COLLISION_001');
--
-- 4) Trụ bận/Faulted/Maintenance không được mở sạc mới
-- INSERT INTO CHI_TIET_PHIEN_SAC(MaPhien, MaTru, ThoiGianBatDauSac, ChiSoCongToDau)
-- VALUES ('PH_NEW', 'TRU_DANG_CHARGING', CURRENT_TIMESTAMP, 100.00);
--
-- 5) Không cho ParkingOnly có CHI_TIET_PHIEN_SAC
-- INSERT INTO CHI_TIET_PHIEN_SAC(MaPhien, MaTru, ThoiGianBatDauSac, ChiSoCongToDau)
-- VALUES ('PH_PARK_ONLY', 'TRU01', CURRENT_TIMESTAMP, 100.00);
--
-- 6) Walk-in sai phương thức (Wallet) phải báo lỗi
-- CALL sp_thanh_toan_walkin_ngoai('HD_WALKIN_01', 'Wallet', 'EXT_001');
--
-- 7) Duplicate external reference phải báo lỗi
-- CALL sp_thanh_toan_walkin_ngoai('HD_WALKIN_01', 'POS_Card', 'EXT_DUP_01');
-- CALL sp_thanh_toan_walkin_ngoai('HD_WALKIN_02', 'POS_Card', 'EXT_DUP_01');
--
-- 8) Giải phóng tài nguyên: khi kết thúc 1 phiên nhưng còn phiên Active khác trên cùng tài nguyên
--    thì CHO_DO_XE/TRU_SAC không được chuyển Available sớm.
