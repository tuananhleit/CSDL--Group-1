-- #############################################################################
-- #                                                                           #
-- #   FULL DDL SCRIPT — HỆ THỐNG QUẢN LÝ TRẠM SẠC & BÃI ĐỖ XE ĐIỆN             #
-- #   PHIÊN BẢN SME TOÀN DIỆN CHO KHÁCH HÀNG B2C VÀ WALK-IN                   #
-- #   TỐI ƯU TRẢI NGHIỆM KHÁCH HÀNG (CX) — TỰ ĐỘNG NGẮT SẠC THEO HẠN MỨC/VÍ   #
-- #                                                                           #
-- #############################################################################

-- =============================================================================
-- XÓA BẢNG CŨ (NẾU CÓ) THEO THỨ TỰ DEPENDENCY NGƯỢC
-- =============================================================================
DROP TABLE IF EXISTS GIAO_DICH_VI CASCADE;
DROP TABLE IF EXISTS HOA_DON CASCADE;
DROP TABLE IF EXISTS CHI_TIET_PHI CASCADE;
DROP TABLE IF EXISTS CHI_TIET_PHIEN_SAC CASCADE;
DROP TABLE IF EXISTS PHIEN CASCADE;
DROP TABLE IF EXISTS DAT_CHO CASCADE;
DROP TABLE IF EXISTS BANG_GIA CASCADE;
DROP TABLE IF EXISTS TRU_SAC CASCADE;
DROP TABLE IF EXISTS LOAI_TRU_SAC CASCADE;
DROP TABLE IF EXISTS CHO_DO_XE CASCADE;
DROP TABLE IF EXISTS TRAM CASCADE;
DROP TABLE IF EXISTS QUAN_TRI_VIEN CASCADE;
DROP TABLE IF EXISTS PHUONG_TIEN CASCADE;
DROP TABLE IF EXISTS KHACH_HANG CASCADE;


-- =============================================================================
-- TABLE 01: KHACH_HANG (Customer)
-- =============================================================================
CREATE TABLE KHACH_HANG (
    MaKH            VARCHAR(20)     PRIMARY KEY,
    HoTen           VARCHAR(100)    NOT NULL DEFAULT 'Khách Vãng Lai',
    SDT             VARCHAR(15)     UNIQUE,
    Email           VARCHAR(100)    UNIQUE,
    LoaiKhach       VARCHAR(20)     NOT NULL DEFAULT 'Registered'
        CHECK (LoaiKhach IN ('Registered', 'WalkIn')),
    SoDuViDienTu    NUMERIC(12, 2)  NOT NULL DEFAULT 0.00
        CHECK (SoDuViDienTu >= 0),
    TrangThaiTK     VARCHAR(20)     NOT NULL DEFAULT 'Active'
        CHECK (TrangThaiTK IN ('Active', 'Locked')),
    NgayDangKy      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT CHK_KhachHang_Reg CHECK (
        (LoaiKhach = 'Registered' AND (SDT IS NOT NULL OR Email IS NOT NULL))
        OR (LoaiKhach = 'WalkIn')
    )
);

CREATE INDEX IDX_KhachHang_SDT ON KHACH_HANG (SDT);
CREATE INDEX IDX_KhachHang_LoaiKhach ON KHACH_HANG (LoaiKhach);


-- =============================================================================
-- TABLE 02: PHUONG_TIEN (Vehicle)
-- =============================================================================
CREATE TABLE PHUONG_TIEN (
    MaXe                VARCHAR(20)     PRIMARY KEY,
    BienSo              VARCHAR(20)     NOT NULL UNIQUE,
    MaKH                VARCHAR(20)     NOT NULL
        REFERENCES KHACH_HANG(MaKH),
    LoaiXe              VARCHAR(20)     NOT NULL DEFAULT 'Car_4W'
        CHECK (LoaiXe IN ('Car_4W', 'Motorbike_2W')),
    ChuanSac            VARCHAR(20)     NOT NULL DEFAULT 'CCS2'
        CHECK (ChuanSac IN ('CCS2', 'Type2', 'GB_T', 'CHAdeMO', 'AC_Plug', 'Other')),
    HangXe              VARCHAR(50),
    CongSuatSacToiDa_kW NUMERIC(5, 2)  CHECK (CongSuatSacToiDa_kW > 0),
    BiDenKhoa           BOOLEAN         NOT NULL DEFAULT FALSE
);

CREATE INDEX IDX_PhuongTien_BienSo ON PHUONG_TIEN (BienSo);
CREATE INDEX IDX_PhuongTien_MaKH ON PHUONG_TIEN (MaKH);


-- =============================================================================
-- TABLE 03: QUAN_TRI_VIEN (Admin)
-- =============================================================================
CREATE TABLE QUAN_TRI_VIEN (
    MaQTV           VARCHAR(20)     PRIMARY KEY,
    HoTen           VARCHAR(100)    NOT NULL,
    Email           VARCHAR(100)    NOT NULL UNIQUE,
    VaiTro          VARCHAR(30)     NOT NULL DEFAULT 'StationManager'
        CHECK (VaiTro IN ('SuperAdmin', 'StationManager', 'Technician'))
);


-- =============================================================================
-- TABLE 04: TRAM (Station)
-- =============================================================================
CREATE TABLE TRAM (
    MaTram          VARCHAR(20)     PRIMARY KEY,
    TenTram         VARCHAR(100)    NOT NULL,
    DiaChi          TEXT            NOT NULL,
    ViDo            NUMERIC(9, 6),
    KinhDo          NUMERIC(9, 6),
    PhutAnHanSauSac INT             NOT NULL DEFAULT 15
        CHECK (PhutAnHanSauSac >= 0),
    SoDuToiThieu    NUMERIC(12, 2)  NOT NULL DEFAULT 20000.00
        CHECK (SoDuToiThieu >= 0),
    MaQTV           VARCHAR(20)     REFERENCES QUAN_TRI_VIEN(MaQTV)
);


-- =============================================================================
-- TABLE 05: CHO_DO_XE (Parking Slot)
-- =============================================================================
CREATE TABLE CHO_DO_XE (
    MaCho           VARCHAR(20)     PRIMARY KEY,
    MaTram          VARCHAR(20)     NOT NULL
        REFERENCES TRAM(MaTram),
    MaViTri         VARCHAR(20)     NOT NULL,
    LoaiCho         VARCHAR(20)     NOT NULL DEFAULT 'CarSlot'
        CHECK (LoaiCho IN ('CarSlot', 'MotorbikeSlot')),
    MoTaViTri       VARCHAR(100),
    TrangThaiCho    VARCHAR(20)     NOT NULL DEFAULT 'Available'
        CHECK (TrangThaiCho IN ('Available', 'Occupied', 'Reserved', 'Maintenance')),

    CONSTRAINT UQ_Tram_ViTri UNIQUE (MaTram, MaViTri)
);

CREATE INDEX IDX_ChoDoXe_Tram_TrangThai ON CHO_DO_XE (MaTram, TrangThaiCho);


-- =============================================================================
-- TABLE 06: LOAI_TRU_SAC (Charger Type)
-- =============================================================================
CREATE TABLE LOAI_TRU_SAC (
    MaLoaiTru   VARCHAR(20)     PRIMARY KEY,
    TenLoai     VARCHAR(50)     NOT NULL,
    DongDien    VARCHAR(10)     NOT NULL
        CHECK (DongDien IN ('AC', 'DC')),
    CongSuat_kW NUMERIC(5, 2)  NOT NULL
        CHECK (CongSuat_kW > 0),
    ChuanKetNoi VARCHAR(30)     NOT NULL
);


-- =============================================================================
-- TABLE 07: TRU_SAC (Charging Pillar)
-- =============================================================================
CREATE TABLE TRU_SAC (
    MaTru           VARCHAR(20)     PRIMARY KEY,
    MaCho           VARCHAR(20)     NOT NULL UNIQUE
        REFERENCES CHO_DO_XE(MaCho),
    MaLoaiTru       VARCHAR(20)     NOT NULL
        REFERENCES LOAI_TRU_SAC(MaLoaiTru),
    TrangThaiTru    VARCHAR(20)     NOT NULL DEFAULT 'Available'
        CHECK (TrangThaiTru IN ('Available', 'Charging', 'Faulted', 'Maintenance')),
    NgayLapDat      DATE            NOT NULL DEFAULT CURRENT_DATE
);


-- =============================================================================
-- TABLE 08: BANG_GIA (Pricing Tariff)
-- =============================================================================
CREATE TABLE BANG_GIA (
    MaBangGia       VARCHAR(20)     PRIMARY KEY,
    LoaiGia         VARCHAR(20)     NOT NULL
        CHECK (LoaiGia IN ('Parking', 'Charging', 'PostCharging')),
    MaLoaiTru       VARCHAR(20)     REFERENCES LOAI_TRU_SAC(MaLoaiTru),
    LoaiCho         VARCHAR(20)
        CHECK (LoaiCho IN ('CarSlot', 'MotorbikeSlot')),
    GioBatDau       TIME            NOT NULL,
    GioKetThuc      TIME            NOT NULL,
    LaCaoDiem       BOOLEAN         NOT NULL DEFAULT FALSE,
    DonGiaTheoPhut  NUMERIC(10, 2)  NOT NULL
        CHECK (DonGiaTheoPhut >= 0),
    HieuLucTu       DATE            NOT NULL,
    HieuLucDen      DATE,
    MaQTV           VARCHAR(20)     REFERENCES QUAN_TRI_VIEN(MaQTV),

    CONSTRAINT CHK_LoaiGia_LoaiTru CHECK (
        (LoaiGia = 'Charging'
            AND MaLoaiTru IS NOT NULL
            AND LoaiCho IS NULL)
        OR (LoaiGia IN ('Parking', 'PostCharging')
            AND MaLoaiTru IS NULL
            AND LoaiCho IS NOT NULL)
    ),

    CONSTRAINT CHK_KhungGio CHECK (GioKetThuc > GioBatDau),
    CONSTRAINT CHK_HieuLuc CHECK (HieuLucDen IS NULL OR HieuLucDen >= HieuLucTu)
);

CREATE INDEX IDX_BangGia_TraCuu ON BANG_GIA (LoaiGia, HieuLucTu, HieuLucDen);


-- =============================================================================
-- TABLE 09: DAT_CHO (Reservation)
-- =============================================================================
CREATE TABLE DAT_CHO (
    MaDatCho        VARCHAR(20)     PRIMARY KEY,
    MaXe            VARCHAR(20)     NOT NULL
        REFERENCES PHUONG_TIEN(MaXe),
    MaCho           VARCHAR(20)     NOT NULL
        REFERENCES CHO_DO_XE(MaCho),
    ThoiGianDat     TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ThoiGianHetHan  TIMESTAMP       NOT NULL,
    TienCoc         NUMERIC(12, 2)  NOT NULL DEFAULT 0.00
        CHECK (TienCoc >= 0),
    TrangThaiDatCho VARCHAR(20)     NOT NULL DEFAULT 'Active'
        CHECK (TrangThaiDatCho IN ('Active', 'Completed', 'Cancelled', 'Expired')),

    CONSTRAINT CHK_ThoiGianDat CHECK (ThoiGianHetHan > ThoiGianDat)
);

CREATE UNIQUE INDEX UQ_DatCho_Active_Xe ON DAT_CHO (MaXe)
    WHERE TrangThaiDatCho = 'Active';

CREATE UNIQUE INDEX UQ_DatCho_Active_Cho ON DAT_CHO (MaCho)
    WHERE TrangThaiDatCho = 'Active';

CREATE INDEX IDX_DatCho_ThoiGianHetHan ON DAT_CHO (ThoiGianHetHan);


-- =============================================================================
-- TABLE 10: PHIEN (Service Session)
-- =============================================================================
CREATE TABLE PHIEN (
    MaPhien         VARCHAR(20)     PRIMARY KEY,
    MaXe            VARCHAR(20)     NOT NULL
        REFERENCES PHUONG_TIEN(MaXe),
    MaCho           VARCHAR(20)     NOT NULL
        REFERENCES CHO_DO_XE(MaCho),
    MaDatCho        VARCHAR(20)     UNIQUE
        REFERENCES DAT_CHO(MaDatCho),
    LoaiPhien       VARCHAR(20)     NOT NULL
        CHECK (LoaiPhien IN ('ParkingOnly', 'ParkingAndCharging')),
    TrangThaiPhien  VARCHAR(20)     NOT NULL DEFAULT 'Active'
        CHECK (TrangThaiPhien IN ('Active', 'Completed', 'Cancelled', 'Interrupted')),
    ThoiGianVao     TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ThoiGianRa      TIMESTAMP,
    GhiChu          TEXT,

    CONSTRAINT CHK_ThoiGianPhien CHECK (
        ThoiGianRa IS NULL OR ThoiGianRa >= ThoiGianVao
    )
);

CREATE UNIQUE INDEX UQ_Phien_Active_Xe ON PHIEN (MaXe)
    WHERE TrangThaiPhien = 'Active';

CREATE UNIQUE INDEX UQ_Phien_Active_Cho ON PHIEN (MaCho)
    WHERE TrangThaiPhien = 'Active';

CREATE INDEX IDX_Phien_MaXe ON PHIEN (MaXe);
CREATE INDEX IDX_Phien_MaCho ON PHIEN (MaCho);
CREATE INDEX IDX_Phien_ThoiGianVao ON PHIEN (ThoiGianVao);


-- =============================================================================
-- TABLE 11: CHI_TIET_PHIEN_SAC (Charging Session Detail — Subclass of PHIEN)
-- =============================================================================
CREATE TABLE CHI_TIET_PHIEN_SAC (
    MaPhien             VARCHAR(20)     PRIMARY KEY
        REFERENCES PHIEN(MaPhien),
    MaTru               VARCHAR(20)     NOT NULL
        REFERENCES TRU_SAC(MaTru),
    ThoiGianBatDauSac   TIMESTAMP       NOT NULL,
    ThoiGianKetThucSac  TIMESTAMP,
    ThoiGianHetAnHan    TIMESTAMP,
    ThoiGianRutSungSac  TIMESTAMP,
    ChiSoCongToDau      NUMERIC(10, 2)  NOT NULL
        CHECK (ChiSoCongToDau >= 0),
    ChiSoCongToCuoi     NUMERIC(10, 2)
        CHECK (ChiSoCongToCuoi >= ChiSoCongToDau),
    SoKWh               NUMERIC(10, 2)  GENERATED ALWAYS AS
        (ChiSoCongToCuoi - ChiSoCongToDau) STORED,

    HanMucSac_VND       NUMERIC(12, 2)
        CHECK (HanMucSac_VND IS NULL OR HanMucSac_VND > 0),
    HanMucSac_kWh       NUMERIC(6, 2)
        CHECK (HanMucSac_kWh IS NULL OR HanMucSac_kWh > 0),

    TrangThaiSac        VARCHAR(20)     NOT NULL DEFAULT 'Charging'
        CHECK (TrangThaiSac IN ('Charging', 'Completed', 'Interrupted', 'Suspended')),
    LyDoKetThuc         VARCHAR(50)
        CHECK (LyDoKetThuc IN (
            'Normal_FullBattery', 
            'UserStopped', 
            'AutoCutoff_LimitReached', 
            'AutoCutoff_LowBalance', 
            'PowerLoss', 
            'EmergencyStop', 
            'Other'
        )),

    CONSTRAINT CHK_ThoiGianSac CHECK (
        ThoiGianKetThucSac IS NULL
        OR ThoiGianKetThucSac >= ThoiGianBatDauSac
    ),
    CONSTRAINT CHK_ThoiGianRutSung CHECK (
        ThoiGianRutSungSac IS NULL
        OR (ThoiGianKetThucSac IS NOT NULL AND ThoiGianRutSungSac >= ThoiGianKetThucSac)
    )
);

CREATE INDEX IDX_ChiTietPhienSac_MaTru ON CHI_TIET_PHIEN_SAC (MaTru);


-- =============================================================================
-- TABLE 12: CHI_TIET_PHI (Fee Detail — Weak Entity)
-- =============================================================================
CREATE TABLE CHI_TIET_PHI (
    MaPhien         VARCHAR(20)
        REFERENCES PHIEN(MaPhien),
    SoDong          INT             NOT NULL
        CHECK (SoDong > 0),
    MaBangGia       VARCHAR(20)     NOT NULL
        REFERENCES BANG_GIA(MaBangGia),
    KhoanMuc        VARCHAR(30)     NOT NULL
        CHECK (KhoanMuc IN ('Parking', 'Charging', 'PostCharging')),
    ThoiGianBatDau  TIMESTAMP       NOT NULL,
    ThoiGianKetThuc TIMESTAMP       NOT NULL,
    SoPhut          INT             NOT NULL
        CHECK (SoPhut >= 0),
    SoTien          NUMERIC(12, 2)  NOT NULL
        CHECK (SoTien >= 0),

    PRIMARY KEY (MaPhien, SoDong),
    CONSTRAINT CHK_ThoiGianPhi CHECK (ThoiGianKetThuc >= ThoiGianBatDau)
);


-- =============================================================================
-- TABLE 13: HOA_DON (Invoice)
-- =============================================================================
CREATE TABLE HOA_DON (
    MaHD                    VARCHAR(20)     PRIMARY KEY,
    MaPhien                 VARCHAR(20)     NOT NULL UNIQUE
        REFERENCES PHIEN(MaPhien),
    PhiDoXe                 NUMERIC(12, 2)  NOT NULL DEFAULT 0.00
        CHECK (PhiDoXe >= 0),
    PhiSacDien              NUMERIC(12, 2)  NOT NULL DEFAULT 0.00
        CHECK (PhiSacDien >= 0),
    PhiDoSauSac             NUMERIC(12, 2)  NOT NULL DEFAULT 0.00
        CHECK (PhiDoSauSac >= 0),
    TienKhauTru             NUMERIC(12, 2)  NOT NULL DEFAULT 0.00
        CHECK (TienKhauTru >= 0),

    TongTien                NUMERIC(12, 2)  GENERATED ALWAYS AS
        (PhiDoXe + PhiSacDien + PhiDoSauSac - TienKhauTru) STORED,

    PhuongThucThanhToan     VARCHAR(30)     NOT NULL DEFAULT 'Wallet'
        CHECK (PhuongThucThanhToan IN ('Wallet', 'POS_Card', 'Dynamic_QR', 'Cash')),
    TrangThaiThanhToan      VARCHAR(20)     NOT NULL DEFAULT 'Unpaid'
        CHECK (TrangThaiThanhToan IN ('Unpaid', 'Paid', 'Refunded')),
    MaGiaoDichNgoai         VARCHAR(100),
    NgayLapHoaDon           TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    NgayThanhToan           TIMESTAMP,

    CONSTRAINT CHK_KhauTru CHECK (
        TienKhauTru <= (PhiDoXe + PhiSacDien + PhiDoSauSac)
    ),

    CONSTRAINT CHK_NgayThanhToan CHECK (
        NgayThanhToan IS NULL OR NgayThanhToan >= NgayLapHoaDon
    )
);

CREATE INDEX IDX_HoaDon_TrangThai ON HOA_DON (TrangThaiThanhToan);
CREATE INDEX IDX_HoaDon_NgayLap ON HOA_DON (NgayLapHoaDon);


-- =============================================================================
-- TABLE 14: GIAO_DICH_VI (Wallet Ledger)
-- =============================================================================
CREATE TABLE GIAO_DICH_VI (
    MaGD                VARCHAR(20)     PRIMARY KEY,
    MaKH                VARCHAR(20)     NOT NULL
        REFERENCES KHACH_HANG(MaKH),
    LoaiGD              VARCHAR(20)     NOT NULL
        CHECK (LoaiGD IN ('Deposit', 'Payment', 'Refund', 'DirectPayment')),
    SoTien              NUMERIC(12, 2)  NOT NULL
        CHECK (SoTien > 0),
    SoDuTruoc           NUMERIC(12, 2)  NOT NULL
        CHECK (SoDuTruoc >= 0),
    SoDuSau             NUMERIC(12, 2)  NOT NULL
        CHECK (SoDuSau >= 0),
    MaHD                VARCHAR(20)     REFERENCES HOA_DON(MaHD),
    MaGiaoDichDoiTac    VARCHAR(100)    UNIQUE,
    ThoiGianGD          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    GhiChu              TEXT,

    CONSTRAINT CHK_GiaoDich_SoDu CHECK (
        (LoaiGD = 'Deposit'         AND SoDuSau = SoDuTruoc + SoTien)
        OR (LoaiGD = 'Payment'      AND SoDuSau = SoDuTruoc - SoTien)
        OR (LoaiGD = 'Refund'       AND SoDuSau = SoDuTruoc + SoTien)
        OR (LoaiGD = 'DirectPayment' AND SoDuTruoc = SoDuSau)
    )
);

CREATE INDEX IDX_GiaoDichVi_MaKH ON GIAO_DICH_VI (MaKH);
CREATE INDEX IDX_GiaoDichVi_ThoiGian ON GIAO_DICH_VI (ThoiGianGD);


-- =============================================================================
-- TRIGGERS & FUNCTIONS
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
        RAISE EXCEPTION 'TRẢI NGHIỆM KHÁCH HÀNG: Xe máy không được đỗ tại ô đỗ ô tô (CarSlot)';
    END IF;
    IF v_loaixe = 'Car_4W' AND v_loaicho = 'MotorbikeSlot' THEN
        RAISE EXCEPTION 'TRẢI NGHIỆM KHÁCH HÀNG: Ô tô không được đỗ tại ô đỗ xe máy (MotorbikeSlot)';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Phien_CheckLoaiXe
    BEFORE INSERT ON PHIEN
    FOR EACH ROW
    EXECUTE FUNCTION fn_check_loaixe_loaicho();


CREATE OR REPLACE FUNCTION fn_check_cho_bao_tri()
RETURNS TRIGGER AS $$
DECLARE
    v_trangthai VARCHAR(20);
BEGIN
    SELECT TrangThaiCho INTO v_trangthai
    FROM CHO_DO_XE WHERE MaCho = NEW.MaCho;

    IF v_trangthai = 'Maintenance' THEN
        RAISE EXCEPTION 'Ô đỗ % đang bảo trì kỹ thuật, vui lòng chọn ô khác!', NEW.MaCho;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_DatCho_KiemTraBaoTri
    BEFORE INSERT ON DAT_CHO
    FOR EACH ROW EXECUTE FUNCTION fn_check_cho_bao_tri();

CREATE TRIGGER TRG_Phien_KiemTraBaoTri
    BEFORE INSERT ON PHIEN
    FOR EACH ROW EXECUTE FUNCTION fn_check_cho_bao_tri();


CREATE OR REPLACE FUNCTION fn_check_dieu_kien_mo_phien()
RETURNS TRIGGER AS $$
DECLARE
    v_trangthaitk   VARCHAR(20);
    v_loaikhach     VARCHAR(20);
    v_soduthucte    NUMERIC(12, 2);
    v_sodutoithieu  NUMERIC(12, 2);
BEGIN
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
        RAISE EXCEPTION 'Tài khoản khách hàng đang bị khóa';
    END IF;

    IF v_loaikhach = 'Registered' THEN
        IF v_soduthucte < v_sodutoithieu THEN
            RAISE EXCEPTION 'Số dư ví (%.2f) chưa đạt mức tối thiểu mở phiên của trạm (%.2f)',
                v_soduthucte, v_sodutoithieu;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Phien_KiemTraDieuKienMo
    BEFORE INSERT ON PHIEN
    FOR EACH ROW EXECUTE FUNCTION fn_check_dieu_kien_mo_phien();


CREATE OR REPLACE FUNCTION fn_check_tru_sac_truoc_khi_sac()
RETURNS TRIGGER AS $$
DECLARE
    v_trangthaitru VARCHAR(20);
    v_chuanketnoi  VARCHAR(30);
    v_chuansac_xe  VARCHAR(20);
BEGIN
    SELECT ts.TrangThaiTru, lts.ChuanKetNoi
    INTO   v_trangthaitru, v_chuanketnoi
    FROM   TRU_SAC ts
    JOIN   LOAI_TRU_SAC lts ON ts.MaLoaiTru = lts.MaLoaiTru
    WHERE  ts.MaTru = NEW.MaTru;

    IF v_trangthaitru IN ('Faulted', 'Maintenance') THEN
        RAISE EXCEPTION 'Trụ sạc % đang bảo trì hoặc báo lỗi', NEW.MaTru;
    END IF;

    SELECT pt.ChuanSac INTO v_chuansac_xe
    FROM   PHIEN p
    JOIN   PHUONG_TIEN pt ON p.MaXe = pt.MaXe
    WHERE  p.MaPhien = NEW.MaPhien;

    IF v_chuanketnoi <> 'Other' AND v_chuansac_xe <> 'Other' AND v_chuanketnoi <> v_chuansac_xe THEN
        RAISE EXCEPTION 'Chuẩn sạc của xe (%) không khớp với súng sạc (%) của trụ %',
            v_chuansac_xe, v_chuanketnoi, NEW.MaTru;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_PhienSac_KiemTraTru
    BEFORE INSERT ON CHI_TIET_PHIEN_SAC
    FOR EACH ROW EXECUTE FUNCTION fn_check_tru_sac_truoc_khi_sac();


CREATE OR REPLACE FUNCTION fn_check_xe_bi_khoa()
RETURNS TRIGGER AS $$
DECLARE
    v_bidenkhoa BOOLEAN;
BEGIN
    SELECT BiDenKhoa INTO v_bidenkhoa
    FROM PHUONG_TIEN WHERE MaXe = NEW.MaXe;

    IF v_bidenkhoa = TRUE THEN
        RAISE EXCEPTION 'Phương tiện % đang có khoản nợ chưa thanh toán', NEW.MaXe;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_DatCho_KiemTraKhoaDen
    BEFORE INSERT ON DAT_CHO
    FOR EACH ROW EXECUTE FUNCTION fn_check_xe_bi_khoa();

CREATE TRIGGER TRG_Phien_KiemTraKhoaDen
    BEFORE INSERT ON PHIEN
    FOR EACH ROW EXECUTE FUNCTION fn_check_xe_bi_khoa();


CREATE OR REPLACE FUNCTION fn_check_phien_datcho_khop()
RETURNS TRIGGER AS $$
DECLARE
    v_maxe_datcho  VARCHAR(20);
    v_macho_datcho VARCHAR(20);
BEGIN
    IF NEW.MaDatCho IS NOT NULL THEN
        SELECT MaXe, MaCho INTO v_maxe_datcho, v_macho_datcho
        FROM DAT_CHO WHERE MaDatCho = NEW.MaDatCho;

        IF v_maxe_datcho <> NEW.MaXe THEN
            RAISE EXCEPTION 'Xe trong phiên (%) không khớp xe đặt chỗ (%)', NEW.MaXe, v_maxe_datcho;
        END IF;
        IF v_macho_datcho <> NEW.MaCho THEN
            RAISE EXCEPTION 'Chỗ đỗ trong phiên (%) không khớp chỗ đặt (%)', NEW.MaCho, v_macho_datcho;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Phien_KiemTraDatChoKhop
    BEFORE INSERT ON PHIEN
    FOR EACH ROW EXECUTE FUNCTION fn_check_phien_datcho_khop();


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
    BEFORE INSERT ON DAT_CHO
    FOR EACH ROW EXECUTE FUNCTION fn_check_loaixe_loaicho_datcho();


CREATE OR REPLACE FUNCTION fn_sync_trangthai_phien()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.TrangThaiPhien = 'Active' THEN
        UPDATE CHO_DO_XE SET TrangThaiCho = 'Occupied' WHERE MaCho = NEW.MaCho;
        IF NEW.LoaiPhien = 'ParkingAndCharging' THEN
            UPDATE TRU_SAC SET TrangThaiTru = 'Charging' WHERE MaCho = NEW.MaCho;
        END IF;
    ELSIF NEW.TrangThaiPhien IN ('Completed', 'Cancelled', 'Interrupted') THEN
        UPDATE CHO_DO_XE SET TrangThaiCho = 'Available' WHERE MaCho = NEW.MaCho;
        UPDATE TRU_SAC SET TrangThaiTru = 'Available' WHERE MaCho = NEW.MaCho;

        IF NEW.MaDatCho IS NOT NULL THEN
            UPDATE DAT_CHO SET TrangThaiDatCho = 'Completed' WHERE MaDatCho = NEW.MaDatCho;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Phien_SyncTrangThai
    AFTER INSERT OR UPDATE OF TrangThaiPhien ON PHIEN
    FOR EACH ROW EXECUTE FUNCTION fn_sync_trangthai_phien();


CREATE OR REPLACE FUNCTION fn_auto_calc_an_han()
RETURNS TRIGGER AS $$
DECLARE
    v_phutanhan INT;
BEGIN
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
    FOR EACH ROW EXECUTE FUNCTION fn_auto_calc_an_han();


CREATE OR REPLACE FUNCTION fn_protect_wallet_ledger()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'AN TOÀN TÀI CHÍNH: Bảng GIAO_DICH_VI là sổ cái bất biến (Append-Only), nghiêm cấm sửa hoặc xóa dữ liệu!';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_GiaoDichVi_Protect
    BEFORE UPDATE OR DELETE ON GIAO_DICH_VI
    FOR EACH ROW EXECUTE FUNCTION fn_protect_wallet_ledger();


-- =============================================================================
-- STORED PROCEDURES (VẬN HÀNH & THANH TOÁN AN TOÀN)
-- =============================================================================

-- PROCEDURE 1: Kiểm tra công tơ & Tự động ngắt sạc khi chạm hạn mức hoặc ví
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
    SELECT ct.ChiSoCongToDau, ct.HanMucSac_VND, ct.HanMucSac_kWh, p.MaXe
    INTO   v_chi_so_dau, v_hanmuc_vnd, v_hanmuc_kwh, v_ma_xe
    FROM   CHI_TIET_PHIEN_SAC ct
    JOIN   PHIEN p ON ct.MaPhien = p.MaPhien
    WHERE  ct.MaPhien = p_ma_phien;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Phiên sạc % không tồn tại', p_ma_phien;
    END IF;

    v_sokwh_dadung   := GREATEST(0, p_chi_so_cong_to - v_chi_so_dau);
    v_chiphi_hientai := v_sokwh_dadung * COALESCE(p_don_gia_kwh, 3858.00);

    SELECT kh.SoDuViDienTu, kh.LoaiKhach, kh.MaKH
    INTO   v_sodu_vi, v_loaikhach, v_ma_kh
    FROM   PHUONG_TIEN pt
    JOIN   KHACH_HANG kh ON pt.MaKH = kh.MaKH
    WHERE  pt.MaXe = v_ma_xe;

    -- A: Chạm hạn mức tiền khách cài đặt
    IF v_hanmuc_vnd IS NOT NULL AND v_chiphi_hientai >= v_hanmuc_vnd THEN
        UPDATE CHI_TIET_PHIEN_SAC
        SET ChiSoCongToCuoi    = p_chi_so_cong_to,
            ThoiGianKetThucSac = CURRENT_TIMESTAMP,
            TrangThaiSac       = 'Completed',
            LyDoKetThuc        = 'AutoCutoff_LimitReached'
        WHERE MaPhien = p_ma_phien;
        RETURN;
    END IF;

    -- B: Chạm hạn mức kWh khách cài đặt
    IF v_hanmuc_kwh IS NOT NULL AND v_sokwh_dadung >= v_hanmuc_kwh THEN
        UPDATE CHI_TIET_PHIEN_SAC
        SET ChiSoCongToCuoi    = p_chi_so_cong_to,
            ThoiGianKetThucSac = CURRENT_TIMESTAMP,
            TrangThaiSac       = 'Completed',
            LyDoKetThuc        = 'AutoCutoff_LimitReached'
        WHERE MaPhien = p_ma_phien;
        RETURN;
    END IF;

    -- C: Khách sạc theo số dư ví -> Tự ngắt an toàn trước khi âm tiền
    IF v_loaikhach = 'Registered' AND (v_sodu_vi - v_chiphi_hientai) <= 5000.00 THEN
        UPDATE CHI_TIET_PHIEN_SAC
        SET ChiSoCongToCuoi    = p_chi_so_cong_to,
            ThoiGianKetThucSac = CURRENT_TIMESTAMP,
            TrangThaiSac       = 'Completed',
            LyDoKetThuc        = 'AutoCutoff_LowBalance'
        WHERE MaPhien = p_ma_phien;
        RETURN;
    END IF;
END;
$$;


-- PROCEDURE 2: Thanh toán Hóa đơn qua Ví (B2C)
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
    SELECT SoDuViDienTu
    INTO   v_soduthucte
    FROM   KHACH_HANG
    WHERE  MaKH = p_ma_kh
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Khách hàng % không tồn tại', p_ma_kh;
    END IF;

    SELECT TongTien, TrangThaiThanhToan, MaPhien
    INTO   v_tongtien_hd, v_trangthai_hd, v_ma_phien
    FROM   HOA_DON
    WHERE  MaHD = p_ma_hd;

    IF v_trangthai_hd = 'Paid' THEN
        RAISE EXCEPTION 'Hóa đơn % đã thanh toán!', p_ma_hd;
    END IF;

    IF v_soduthucte < v_tongtien_hd THEN
        RAISE EXCEPTION 'Số dư ví (%.2f) không đủ thanh toán (%.2f)', v_soduthucte, v_tongtien_hd;
    END IF;

    v_sodu_sau := v_soduthucte - v_tongtien_hd;

    UPDATE KHACH_HANG
    SET SoDuViDienTu = v_sodu_sau
    WHERE MaKH = p_ma_kh;

    v_ma_gd := 'GD_PAY_' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8);

    INSERT INTO GIAO_DICH_VI (
        MaGD, MaKH, LoaiGD, SoTien, SoDuTruoc, SoDuSau,
        MaHD, MaGiaoDichDoiTac, GhiChu
    ) VALUES (
        v_ma_gd, p_ma_kh, 'Payment', v_tongtien_hd, v_soduthucte, v_sodu_sau,
        p_ma_hd, p_idempotency_key, 'Thanh toán hóa đơn ' || p_ma_hd
    );

    UPDATE HOA_DON
    SET TrangThaiThanhToan  = 'Paid',
        PhuongThucThanhToan = 'Wallet',
        NgayThanhToan       = CURRENT_TIMESTAMP
    WHERE MaHD = p_ma_hd;

    UPDATE PHIEN
    SET TrangThaiPhien = 'Completed',
        ThoiGianRa     = CURRENT_TIMESTAMP
    WHERE MaPhien = v_ma_phien;
END;
$$;


-- PROCEDURE 3: Thanh toán trực tiếp ngoài ví tại Barrier (Walk-in)
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

    IF v_trang_thai = 'Paid' THEN
        RAISE EXCEPTION 'Hóa đơn % đã thanh toán!', p_ma_hd;
    END IF;

    SELECT SoDuViDienTu INTO v_sodu_hientai FROM KHACH_HANG WHERE MaKH = v_ma_kh;

    UPDATE HOA_DON
    SET TrangThaiThanhToan  = 'Paid',
        PhuongThucThanhToan = p_phuong_thuc,
        MaGiaoDichNgoai     = p_ma_gd_ngoai,
        NgayThanhToan       = CURRENT_TIMESTAMP
    WHERE MaHD = p_ma_hd;

    v_ma_gd := 'GD_WALK_' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8);

    INSERT INTO GIAO_DICH_VI (
        MaGD, MaKH, LoaiGD, SoTien, SoDuTruoc, SoDuSau,
        MaHD, MaGiaoDichDoiTac, GhiChu
    ) VALUES (
        v_ma_gd, v_ma_kh, 'DirectPayment', v_tong_tien, v_sodu_hientai, v_sodu_hientai,
        p_ma_hd, p_ma_gd_ngoai, 'Thanh toán trực tiếp (' || p_phuong_thuc || ') cho ' || p_ma_hd
    );

    UPDATE PHIEN
    SET TrangThaiPhien = 'Completed',
        ThoiGianRa     = CURRENT_TIMESTAMP
    WHERE MaPhien = v_ma_phien;
END;
$$;


-- PROCEDURE 4: Xử lý Đặt chỗ quá hạn (No-Show Reaper)
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
        UPDATE DAT_CHO SET TrangThaiDatCho = 'Expired' WHERE MaDatCho = r.MaDatCho;
        UPDATE CHO_DO_XE SET TrangThaiCho = 'Available' WHERE MaCho = r.MaCho AND TrangThaiCho = 'Reserved';
    END LOOP;
END;
$$;


-- =============================================================================
-- RBAC: PHÂN QUYỀN TRUY CẬP
-- =============================================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'app_user_role') THEN
        CREATE ROLE app_user_role;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'station_operator_role') THEN
        CREATE ROLE station_operator_role;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'sys_admin_role') THEN
        CREATE ROLE sys_admin_role;
    END IF;
END
$$;

GRANT SELECT ON TRAM, CHO_DO_XE, LOAI_TRU_SAC, TRU_SAC, BANG_GIA TO app_user_role;
GRANT SELECT, INSERT ON DAT_CHO, PHIEN, CHI_TIET_PHIEN_SAC TO app_user_role;
GRANT SELECT ON KHACH_HANG, PHUONG_TIEN, HOA_DON, GIAO_DICH_VI TO app_user_role;
GRANT EXECUTE ON PROCEDURE sp_thanh_toan_hoa_don_vi(VARCHAR, VARCHAR, VARCHAR) TO app_user_role;
GRANT EXECUTE ON PROCEDURE sp_kiem_tra_va_ngat_sac_tu_dong(VARCHAR, NUMERIC, NUMERIC) TO app_user_role;

GRANT SELECT, UPDATE ON CHO_DO_XE, TRU_SAC, PHUONG_TIEN TO station_operator_role;
GRANT SELECT, INSERT, UPDATE ON BANG_GIA TO station_operator_role;
GRANT SELECT, UPDATE ON HOA_DON, PHIEN TO station_operator_role;
GRANT SELECT ON KHACH_HANG, GIAO_DICH_VI TO station_operator_role;
GRANT EXECUTE ON PROCEDURE sp_thanh_toan_walkin_ngoai(VARCHAR, VARCHAR, VARCHAR) TO station_operator_role;
GRANT EXECUTE ON PROCEDURE sp_xu_ly_dat_cho_qua_han() TO station_operator_role;
GRANT EXECUTE ON PROCEDURE sp_kiem_tra_va_ngat_sac_tu_dong(VARCHAR, NUMERIC, NUMERIC) TO station_operator_role;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO sys_admin_role;
GRANT ALL PRIVILEGES ON ALL ROUTINES IN SCHEMA public TO sys_admin_role;
