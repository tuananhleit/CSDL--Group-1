-- =============================================================================
-- FILE 15: TRIGGERS & FUNCTIONS
-- =============================================================================
-- Mô tả: Toàn bộ Trigger cưỡng chế quy tắc nghiệp vụ liên bảng,
--        tự động đồng bộ trạng thái IoT, bảo vệ an toàn tài chính ví,
--        và tối ưu hóa trải nghiệm khách hàng B2C & Walk-in.
-- =============================================================================


-- =============================================================================
-- TRIGGER 1: Kiểm tra khớp Loại xe <-> Loại chỗ khi mở PHIEN
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_check_loaixe_loaicho()
RETURNS TRIGGER AS $$
DECLARE
    v_loaixe  VARCHAR(20);
    v_loaicho VARCHAR(20);
BEGIN
    SELECT LoaiXe INTO v_loaixe FROM PHUONG_TIEN WHERE MaXe = NEW.MaXe;
    SELECT LoaiCho INTO v_loaicho FROM CHO_DO_XE WHERE MaCho = NEW.MaCho;

    IF v_loaixe = 'Motorbike_2W' AND v_loaicho = 'CarSlot' THEN
        RAISE EXCEPTION 'TRẢI NGHIỆM KHÁCH HÀNG: Xe máy 2 bánh không được đỗ tại ô đỗ ô tô (CarSlot)';
    END IF;
    IF v_loaixe = 'Car_4W' AND v_loaicho = 'MotorbikeSlot' THEN
        RAISE EXCEPTION 'TRẢI NGHIỆM KHÁCH HÀNG: Ô tô 4 bánh không được đỗ tại ô đỗ xe máy (MotorbikeSlot)';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Phien_CheckLoaiXe
    BEFORE INSERT OR UPDATE OF MaXe, MaCho ON PHIEN
    FOR EACH ROW
    EXECUTE FUNCTION fn_check_loaixe_loaicho();


-- =============================================================================
-- TRIGGER 2: Kiểm tra chỗ đỗ bảo trì khi Đặt chỗ / Mở phiên
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_check_cho_bao_tri()
RETURNS TRIGGER AS $$
DECLARE
    v_trangthai VARCHAR(20);
BEGIN
    SELECT TrangThaiCho INTO v_trangthai
    FROM CHO_DO_XE WHERE MaCho = NEW.MaCho;

    IF v_trangthai = 'Maintenance' THEN
        RAISE EXCEPTION 'Ô đỗ % đang bảo trì kỹ thuật, vui lòng chọn ô đỗ khác!', NEW.MaCho;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_DatCho_KiemTraBaoTri
    BEFORE INSERT OR UPDATE OF MaCho ON DAT_CHO
    FOR EACH ROW EXECUTE FUNCTION fn_check_cho_bao_tri();

CREATE TRIGGER TRG_Phien_KiemTraBaoTri
    BEFORE INSERT OR UPDATE OF MaCho ON PHIEN
    FOR EACH ROW EXECUTE FUNCTION fn_check_cho_bao_tri();


-- =============================================================================
-- TRIGGER 3: Kiểm tra điều kiện mở phiên & Số dư tối thiểu thân thiện
-- (Tài khoản phải Active, số dư ví >= ngưỡng tối thiểu của trạm (chỉ từ 20.000đ))
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_check_dieu_kien_mo_phien()
RETURNS TRIGGER AS $$
DECLARE
    v_trangthaitk   VARCHAR(20);
    v_loaikhach     VARCHAR(20);
    v_soduthucte    NUMERIC(12, 2);
    v_sodutoithieu  NUMERIC(12, 2);
BEGIN
    IF NEW.TrangThaiPhien <> 'Active' THEN
        RETURN NEW;
    END IF;

    SELECT kh.TrangThaiTK, kh.SoDuViDienTu, kh.LoaiKhach
    INTO   v_trangthaitk, v_soduthucte, v_loaikhach
    FROM   PHUONG_TIEN pt
    JOIN   KHACH_HANG kh ON pt.MaKH = kh.MaKH
    WHERE  pt.MaXe = NEW.MaXe;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Không tìm thấy phương tiện % để kiểm tra điều kiện mở phiên', NEW.MaXe;
    END IF;

    SELECT t.SoDuToiThieu INTO v_sodutoithieu
    FROM   CHO_DO_XE c
    JOIN   TRAM t ON c.MaTram = t.MaTram
    WHERE  c.MaCho = NEW.MaCho;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Không tìm thấy ô đỗ % để kiểm tra điều kiện mở phiên', NEW.MaCho;
    END IF;

    IF v_trangthaitk <> 'Active' THEN
        RAISE EXCEPTION 'Tài khoản khách hàng đang bị khóa, không thể mở phiên dịch vụ';
    END IF;

    -- Kiểm tra số dư cho khách hàng thành viên (Registered)
    -- Ngưỡng thân thiện (chỉ từ 20.000đ)
    IF v_loaikhach = 'Registered' THEN
        IF v_soduthucte < v_sodutoithieu THEN
            RAISE EXCEPTION 'Số dư ví (%.2f) chưa đạt mức tối thiểu mở phiên của trạm (%.2f). Vui lòng nạp thêm tiền!',
                v_soduthucte, v_sodutoithieu;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Phien_KiemTraDieuKienMo
    BEFORE INSERT OR UPDATE OF MaXe, MaCho, TrangThaiPhien ON PHIEN
    FOR EACH ROW EXECUTE FUNCTION fn_check_dieu_kien_mo_phien();


-- =============================================================================
-- TRIGGER 4: Kiểm tra trụ sạc & chuẩn kết nối trước khi sạc
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_check_tru_sac_truoc_khi_sac()
RETURNS TRIGGER AS $$
DECLARE
    v_trangthaitru VARCHAR(20);
    v_chuanketnoi  VARCHAR(30);
    v_chuansac_xe  VARCHAR(20);
    v_loaiphien    VARCHAR(20);
BEGIN
    -- Chỉ cưỡng chế khi đang bắt đầu/duy trì trạng thái Charging
    IF NEW.TrangThaiSac <> 'Charging' THEN
        RETURN NEW;
    END IF;

    SELECT p.LoaiPhien, pt.ChuanSac
    INTO   v_loaiphien, v_chuansac_xe
    FROM   PHIEN p
    JOIN   PHUONG_TIEN pt ON p.MaXe = pt.MaXe
    WHERE  p.MaPhien = NEW.MaPhien;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Không tìm thấy phiên % để kiểm tra chi tiết sạc', NEW.MaPhien;
    END IF;

    IF v_loaiphien <> 'ParkingAndCharging' THEN
        RAISE EXCEPTION 'Phiên % là ParkingOnly, không được tạo CHI_TIET_PHIEN_SAC', NEW.MaPhien;
    END IF;

    SELECT ts.TrangThaiTru, lts.ChuanKetNoi
    INTO   v_trangthaitru, v_chuanketnoi
    FROM   TRU_SAC ts
    JOIN   LOAI_TRU_SAC lts ON ts.MaLoaiTru = lts.MaLoaiTru
    WHERE  ts.MaTru = NEW.MaTru
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Không tìm thấy trụ sạc %', NEW.MaTru;
    END IF;

    IF v_trangthaitru <> 'Available' THEN
        RAISE EXCEPTION 'Trụ sạc % đang ở trạng thái %, chỉ cho phép Available để bắt đầu phiên sạc mới', NEW.MaTru, v_trangthaitru;
    END IF;

    -- Kiểm tra tương thích chuẩn súng sạc với cổng xe
    IF v_chuanketnoi <> 'Other' AND v_chuansac_xe <> 'Other' AND v_chuanketnoi <> v_chuansac_xe THEN
        RAISE EXCEPTION 'CẢNH BÁO TƯƠNG THÍCH: Chuẩn sạc xe (%) không khớp với súng sạc của trụ (%)!',
            v_chuansac_xe, v_chuanketnoi;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_PhienSac_KiemTraTru
    BEFORE INSERT OR UPDATE OF MaPhien, MaTru, TrangThaiSac ON CHI_TIET_PHIEN_SAC
    FOR EACH ROW EXECUTE FUNCTION fn_check_tru_sac_truoc_khi_sac();


-- =============================================================================
-- TRIGGER 5: Kiểm tra xe bị khóa nợ xấu khi Đặt chỗ / Mở phiên
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_check_xe_bi_khoa()
RETURNS TRIGGER AS $$
DECLARE
    v_bidenkhoa BOOLEAN;
BEGIN
    SELECT BiDenKhoa INTO v_bidenkhoa
    FROM PHUONG_TIEN WHERE MaXe = NEW.MaXe;

    IF v_bidenkhoa = TRUE THEN
        RAISE EXCEPTION 'Xe % đang có khoản nợ trước đó chưa thanh toán. Vui lòng thanh toán để mở khóa dịch vụ!', NEW.MaXe;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_DatCho_KiemTraKhoaDen
    BEFORE INSERT OR UPDATE OF MaXe ON DAT_CHO
    FOR EACH ROW EXECUTE FUNCTION fn_check_xe_bi_khoa();

CREATE TRIGGER TRG_Phien_KiemTraKhoaDen
    BEFORE INSERT OR UPDATE OF MaXe ON PHIEN
    FOR EACH ROW EXECUTE FUNCTION fn_check_xe_bi_khoa();


-- =============================================================================
-- TRIGGER 6: Kiểm tra tính nhất quán giữa PHIEN và DAT_CHO
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_check_phien_datcho_khop()
RETURNS TRIGGER AS $$
DECLARE
    v_maxe_datcho  VARCHAR(20);
    v_macho_datcho VARCHAR(20);
BEGIN
    IF NEW.MaDatCho IS NOT NULL THEN
        SELECT MaXe, MaCho INTO v_maxe_datcho, v_macho_datcho
        FROM DAT_CHO WHERE MaDatCho = NEW.MaDatCho;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Mã đặt chỗ % không tồn tại', NEW.MaDatCho;
        END IF;

        IF v_maxe_datcho <> NEW.MaXe THEN
            RAISE EXCEPTION 'Phương tiện mở phiên (%) không khớp với xe đã đặt chỗ (%)',
                NEW.MaXe, v_maxe_datcho;
        END IF;
        IF v_macho_datcho <> NEW.MaCho THEN
            RAISE EXCEPTION 'Ô đỗ mở phiên (%) không khớp với ô đỗ đã đặt chỗ (%)',
                NEW.MaCho, v_macho_datcho;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Phien_KiemTraDatChoKhop
    BEFORE INSERT OR UPDATE OF MaDatCho, MaXe, MaCho ON PHIEN
    FOR EACH ROW EXECUTE FUNCTION fn_check_phien_datcho_khop();


-- =============================================================================
-- TRIGGER 7: Kiểm tra loại xe <-> loại chỗ khi ĐẶT CHỖ
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_check_loaixe_loaicho_datcho()
RETURNS TRIGGER AS $$
DECLARE
    v_loaixe  VARCHAR(20);
    v_loaicho VARCHAR(20);
BEGIN
    SELECT LoaiXe INTO v_loaixe FROM PHUONG_TIEN WHERE MaXe = NEW.MaXe;
    SELECT LoaiCho INTO v_loaicho FROM CHO_DO_XE WHERE MaCho = NEW.MaCho;

    IF v_loaixe = 'Motorbike_2W' AND v_loaicho = 'CarSlot' THEN
        RAISE EXCEPTION 'Xe máy không được đặt chỗ ô tô (CarSlot)';
    END IF;
    IF v_loaixe = 'Car_4W' AND v_loaicho = 'MotorbikeSlot' THEN
        RAISE EXCEPTION 'Ô tô không được đặt chỗ xe máy (MotorbikeSlot)';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_DatCho_CheckLoaiXe
    BEFORE INSERT OR UPDATE OF MaXe, MaCho ON DAT_CHO
    FOR EACH ROW EXECUTE FUNCTION fn_check_loaixe_loaicho_datcho();


-- =============================================================================
-- TRIGGER 8: [TỰ ĐỘNG ĐỒNG BỘ TRẠNG THÁI] Giữa PHIEN và CHO_DO_XE
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_sync_trangthai_phien()
RETURNS TRIGGER AS $$
BEGIN
    -- Khi phiên Active -> Cập nhật chỗ đỗ Occupied
    IF NEW.TrangThaiPhien = 'Active' THEN
        UPDATE CHO_DO_XE
        SET TrangThaiCho = 'Occupied'
        WHERE MaCho = NEW.MaCho;

    -- Khi phiên Completed / Cancelled / Interrupted -> chỉ trả chỗ khi không còn phiên Active khác
    ELSIF NEW.TrangThaiPhien IN ('Completed', 'Cancelled', 'Interrupted') THEN
        UPDATE CHO_DO_XE
        SET TrangThaiCho = 'Available'
        WHERE MaCho = NEW.MaCho
          AND NOT EXISTS (
              SELECT 1
              FROM PHIEN p2
              WHERE p2.MaCho = NEW.MaCho
                AND p2.TrangThaiPhien = 'Active'
                AND p2.MaPhien <> NEW.MaPhien
          );

        UPDATE TRU_SAC ts
        SET TrangThaiTru = 'Available'
        WHERE ts.MaCho = NEW.MaCho
          AND NOT EXISTS (
              SELECT 1
              FROM PHIEN p2
              JOIN CHI_TIET_PHIEN_SAC ct2 ON ct2.MaPhien = p2.MaPhien
              WHERE p2.MaCho = NEW.MaCho
                AND p2.TrangThaiPhien = 'Active'
                AND ct2.TrangThaiSac = 'Charging'
                AND p2.MaPhien <> NEW.MaPhien
          );

        -- Nếu có liên kết đặt chỗ, tự động hoàn thành đặt chỗ
        IF NEW.MaDatCho IS NOT NULL THEN
            UPDATE DAT_CHO
            SET TrangThaiDatCho = 'Completed'
            WHERE MaDatCho = NEW.MaDatCho;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Phien_SyncTrangThai
    AFTER INSERT OR UPDATE OF TrangThaiPhien ON PHIEN
    FOR EACH ROW
    EXECUTE FUNCTION fn_sync_trangthai_phien();


-- =============================================================================
-- TRIGGER 9: [ĐỒNG BỘ TRẠNG THÁI TRỤ SẠC] từ CHI_TIET_PHIEN_SAC
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_sync_trangthai_tru_sac()
RETURNS TRIGGER AS $$
DECLARE
    v_trangthai_tru VARCHAR(20);
BEGIN
    SELECT TrangThaiTru
    INTO   v_trangthai_tru
    FROM   TRU_SAC
    WHERE  MaTru = NEW.MaTru
    FOR UPDATE;

    IF NEW.TrangThaiSac = 'Charging' THEN
        UPDATE TRU_SAC
        SET TrangThaiTru = 'Charging'
        WHERE MaTru = NEW.MaTru;
    ELSIF NEW.TrangThaiSac IN ('Completed', 'Interrupted', 'Suspended') THEN
        UPDATE TRU_SAC ts
        SET TrangThaiTru = 'Available'
        WHERE ts.MaTru = NEW.MaTru
          AND v_trangthai_tru <> 'Maintenance'
          AND v_trangthai_tru <> 'Faulted'
          AND NOT EXISTS (
              SELECT 1
              FROM CHI_TIET_PHIEN_SAC ct2
              WHERE ct2.MaTru = NEW.MaTru
                AND ct2.TrangThaiSac = 'Charging'
                AND ct2.MaPhien <> NEW.MaPhien
          );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_PhienSac_SyncTrangThaiTru
    AFTER INSERT OR UPDATE OF TrangThaiSac ON CHI_TIET_PHIEN_SAC
    FOR EACH ROW
    EXECUTE FUNCTION fn_sync_trangthai_tru_sac();


-- =============================================================================
-- TRIGGER 10: [TỰ ĐỘNG TÍNH THỜI GIAN ÂN HẠN] Cho phiên sạc
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_auto_calc_an_han()
RETURNS TRIGGER AS $$
DECLARE
    v_phutanhan INT;
BEGIN
    -- Khi kết thúc sạc mà chưa có thời gian hết ân hạn -> Tự động tính theo cấu hình trạm
    IF NEW.ThoiGianKetThucSac IS NOT NULL AND NEW.ThoiGianHetAnHan IS NULL THEN
        SELECT t.PhutAnHanSauSac INTO v_phutanhan
        FROM   PHIEN p
        JOIN   CHO_DO_XE c ON p.MaCho = c.MaCho
        JOIN   TRAM t ON c.MaTram = t.MaTram
        WHERE  p.MaPhien = NEW.MaPhien;

        NEW.ThoiGianHetAnHan := NEW.ThoiGianKetThucSac + (COALESCE(v_phutanhan, 15) || ' minutes')::INTERVAL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_PhienSac_AutoAnHan
    BEFORE INSERT OR UPDATE OF ThoiGianKetThucSac ON CHI_TIET_PHIEN_SAC
    FOR EACH ROW
    EXECUTE FUNCTION fn_auto_calc_an_han();


-- =============================================================================
-- TRIGGER 11: [BẢO VỆ TÍNH BẤT BIẾN CỦA SỔ CÁI VÍ]
-- Nghiêm cấm mọi hành vi UPDATE hoặc DELETE trên GIAO_DICH_VI
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_protect_wallet_ledger()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'AN TOÀN TÀI CHÍNH: Bảng GIAO_DICH_VI là sổ cái bất biến (Append-Only), nghiêm cấm sửa hoặc xóa dữ liệu!';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_GiaoDichVi_Protect
    BEFORE UPDATE OR DELETE ON GIAO_DICH_VI
    FOR EACH ROW
    EXECUTE FUNCTION fn_protect_wallet_ledger();
