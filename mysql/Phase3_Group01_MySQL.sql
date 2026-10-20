SET NAMES utf8mb4;

DROP DATABASE IF EXISTS smart_ev_parking;
CREATE DATABASE smart_ev_parking CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE smart_ev_parking;

USE smart_ev_parking;

CREATE TABLE KHACH_HANG (
    MaKH            VARCHAR(20)     NOT NULL,
    HoTen           VARCHAR(100)    NOT NULL DEFAULT 'Khách Vãng Lai',
    SDT             VARCHAR(15)     NULL,
    Email           VARCHAR(100)    NULL,
    LoaiKhach       VARCHAR(20)     NOT NULL DEFAULT 'Registered',
    SoDuViDienTu    DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,
    TrangThaiTK     VARCHAR(20)     NOT NULL DEFAULT 'Active',
    NgayDangKy      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (MaKH),
    UNIQUE KEY UQ_KhachHang_SDT (SDT),
    UNIQUE KEY UQ_KhachHang_Email (Email),
    CONSTRAINT CHK_KhachHang_LoaiKhach CHECK (LoaiKhach IN ('Registered', 'WalkIn')),
    CONSTRAINT CHK_KhachHang_SoDu      CHECK (SoDuViDienTu >= 0),
    CONSTRAINT CHK_KhachHang_TrangThai CHECK (TrangThaiTK IN ('Active', 'Locked')),

    CONSTRAINT CHK_KhachHang_Reg CHECK (
        (LoaiKhach = 'Registered' AND (SDT IS NOT NULL OR Email IS NOT NULL))
        OR (LoaiKhach = 'WalkIn')
    )
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE INDEX IDX_KhachHang_LoaiKhach ON KHACH_HANG (LoaiKhach);

USE smart_ev_parking;

CREATE TABLE PHUONG_TIEN (
    MaXe                VARCHAR(20)     NOT NULL,
    BienSo              VARCHAR(20)     NOT NULL,
    MaKH                VARCHAR(20)     NOT NULL,
    LoaiXe              VARCHAR(20)     NOT NULL DEFAULT 'Car_4W',
    ChuanSac            VARCHAR(20)     NOT NULL DEFAULT 'CCS2',
    HangXe              VARCHAR(50)     NULL,
    CongSuatSacToiDa_kW DECIMAL(5, 2)   NULL,
    BiDenKhoa           BOOLEAN         NOT NULL DEFAULT FALSE,

    PRIMARY KEY (MaXe),
    UNIQUE KEY UQ_PhuongTien_BienSo (BienSo),
    CONSTRAINT FK_PhuongTien_KhachHang FOREIGN KEY (MaKH) REFERENCES KHACH_HANG (MaKH),
    CONSTRAINT CHK_PhuongTien_LoaiXe   CHECK (LoaiXe IN ('Car_4W', 'Motorbike_2W')),
    CONSTRAINT CHK_PhuongTien_ChuanSac CHECK (ChuanSac IN ('CCS2', 'Type2', 'GB_T', 'CHAdeMO', 'AC_Plug', 'Other')),
    CONSTRAINT CHK_PhuongTien_CongSuat CHECK (CongSuatSacToiDa_kW IS NULL OR CongSuatSacToiDa_kW > 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE INDEX IDX_PhuongTien_MaKH ON PHUONG_TIEN (MaKH);

USE smart_ev_parking;

CREATE TABLE QUAN_TRI_VIEN (
    MaQTV   VARCHAR(20)     NOT NULL,
    HoTen   VARCHAR(100)    NOT NULL,
    Email   VARCHAR(100)    NOT NULL,
    VaiTro  VARCHAR(50)     NOT NULL DEFAULT 'Operator',

    PRIMARY KEY (MaQTV),
    UNIQUE KEY UQ_QuanTriVien_Email (Email)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

USE smart_ev_parking;

CREATE TABLE TRAM (
    MaTram          VARCHAR(20)     NOT NULL,
    TenTram         VARCHAR(100)    NOT NULL,
    DiaChi          TEXT            NOT NULL,
    ViDo            DECIMAL(9, 6)   NULL,
    KinhDo          DECIMAL(9, 6)   NULL,
    PhutAnHanSauSac INT             NOT NULL DEFAULT 15,
    SoDuToiThieu    DECIMAL(12, 2)  NOT NULL DEFAULT 20000.00,
    MaQTV           VARCHAR(20)     NULL,

    PRIMARY KEY (MaTram),
    CONSTRAINT FK_Tram_QuanTriVien FOREIGN KEY (MaQTV) REFERENCES QUAN_TRI_VIEN (MaQTV),
    CONSTRAINT CHK_Tram_AnHan      CHECK (PhutAnHanSauSac >= 0),
    CONSTRAINT CHK_Tram_SoDuToiThieu CHECK (SoDuToiThieu >= 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

USE smart_ev_parking;

CREATE TABLE CHO_DO_XE (
    MaCho           VARCHAR(20)     NOT NULL,
    MaTram          VARCHAR(20)     NOT NULL,
    MaViTri         VARCHAR(20)     NOT NULL,
    LoaiCho         VARCHAR(20)     NOT NULL DEFAULT 'CarSlot',
    MoTaViTri       VARCHAR(100)    NULL,
    TrangThaiCho    VARCHAR(20)     NOT NULL DEFAULT 'Available',

    PRIMARY KEY (MaCho),

    CONSTRAINT UQ_Tram_ViTri UNIQUE (MaTram, MaViTri),
    CONSTRAINT FK_ChoDoXe_Tram FOREIGN KEY (MaTram) REFERENCES TRAM (MaTram),
    CONSTRAINT CHK_ChoDoXe_LoaiCho   CHECK (LoaiCho IN ('CarSlot', 'MotorbikeSlot')),
    CONSTRAINT CHK_ChoDoXe_TrangThai CHECK (TrangThaiCho IN ('Available', 'Occupied', 'Reserved', 'Maintenance'))
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE INDEX IDX_ChoDoXe_Tram_TrangThai ON CHO_DO_XE (MaTram, TrangThaiCho);

USE smart_ev_parking;

CREATE TABLE LOAI_TRU_SAC (
    MaLoaiTru   VARCHAR(20)     NOT NULL,
    TenLoai     VARCHAR(50)     NOT NULL,
    DongDien    VARCHAR(10)     NOT NULL,
    CongSuat_kW DECIMAL(5, 2)   NOT NULL,
    ChuanKetNoi VARCHAR(30)     NOT NULL,

    PRIMARY KEY (MaLoaiTru),
    CONSTRAINT CHK_LoaiTruSac_DongDien CHECK (DongDien IN ('AC', 'DC')),
    CONSTRAINT CHK_LoaiTruSac_CongSuat CHECK (CongSuat_kW > 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

USE smart_ev_parking;

CREATE TABLE TRU_SAC (
    MaTru           VARCHAR(20)     NOT NULL,
    MaCho           VARCHAR(20)     NOT NULL,
    MaLoaiTru       VARCHAR(20)     NOT NULL,
    TrangThaiTru    VARCHAR(20)     NOT NULL DEFAULT 'Available',
    NgayLapDat      DATE            NOT NULL DEFAULT (CURRENT_DATE),

    PRIMARY KEY (MaTru),
    UNIQUE KEY UQ_TruSac_MaCho (MaCho),
    CONSTRAINT FK_TruSac_ChoDoXe  FOREIGN KEY (MaCho)     REFERENCES CHO_DO_XE (MaCho),
    CONSTRAINT FK_TruSac_LoaiTru  FOREIGN KEY (MaLoaiTru) REFERENCES LOAI_TRU_SAC (MaLoaiTru),
    CONSTRAINT CHK_TruSac_TrangThai CHECK (TrangThaiTru IN ('Available', 'Charging', 'Faulted', 'Maintenance'))
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

USE smart_ev_parking;

CREATE TABLE BANG_GIA (
    MaBangGia       VARCHAR(20)     NOT NULL,
    LoaiGia         VARCHAR(20)     NOT NULL,
    MaLoaiTru       VARCHAR(20)     NULL,
    LoaiCho         VARCHAR(20)     NULL,
    GioBatDau       TIME            NOT NULL,
    GioKetThuc      TIME            NOT NULL,
    LaCaoDiem       BOOLEAN         NOT NULL DEFAULT FALSE,
    DonGiaTheoPhut  DECIMAL(10, 2)  NOT NULL,
    HieuLucTu       DATE            NOT NULL,
    HieuLucDen      DATE            NULL,
    MaQTV           VARCHAR(20)     NULL,

    PRIMARY KEY (MaBangGia),
    CONSTRAINT FK_BangGia_LoaiTru FOREIGN KEY (MaLoaiTru) REFERENCES LOAI_TRU_SAC (MaLoaiTru),
    CONSTRAINT FK_BangGia_QTV     FOREIGN KEY (MaQTV)     REFERENCES QUAN_TRI_VIEN (MaQTV),
    CONSTRAINT CHK_BangGia_LoaiGia CHECK (LoaiGia IN ('Parking', 'Charging', 'PostCharging')),
    CONSTRAINT CHK_BangGia_LoaiCho CHECK (LoaiCho IS NULL OR LoaiCho IN ('CarSlot', 'MotorbikeSlot')),
    CONSTRAINT CHK_BangGia_DonGia  CHECK (DonGiaTheoPhut >= 0),

    CONSTRAINT CHK_LoaiGia_LoaiTru CHECK (
        (LoaiGia = 'Charging' AND MaLoaiTru IS NOT NULL AND LoaiCho IS NULL)
        OR (LoaiGia IN ('Parking', 'PostCharging') AND MaLoaiTru IS NULL AND LoaiCho IS NOT NULL)
    ),

    CONSTRAINT CHK_KhungGio CHECK (GioKetThuc > GioBatDau),
    CONSTRAINT CHK_HieuLuc  CHECK (HieuLucDen IS NULL OR HieuLucDen >= HieuLucTu)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

USE smart_ev_parking;

CREATE TABLE DAT_CHO (
    MaDatCho        VARCHAR(20)     NOT NULL,
    MaXe            VARCHAR(20)     NOT NULL,
    MaCho           VARCHAR(20)     NOT NULL,
    ThoiGianDat     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ThoiGianHetHan  DATETIME        NOT NULL,
    TienCoc         DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,
    TrangThaiDatCho VARCHAR(20)     NOT NULL DEFAULT 'Active',
    XeDangGiu       VARCHAR(20)     GENERATED ALWAYS AS (IF(TrangThaiDatCho = 'Active', MaXe,  NULL)) VIRTUAL,
    ChoDangGiu      VARCHAR(20)     GENERATED ALWAYS AS (IF(TrangThaiDatCho = 'Active', MaCho, NULL)) VIRTUAL,

    PRIMARY KEY (MaDatCho),
    UNIQUE KEY UQ_DatCho_Active_Xe  (XeDangGiu),
    UNIQUE KEY UQ_DatCho_Active_Cho (ChoDangGiu),
    CONSTRAINT FK_DatCho_PhuongTien FOREIGN KEY (MaXe)  REFERENCES PHUONG_TIEN (MaXe),
    CONSTRAINT FK_DatCho_ChoDoXe    FOREIGN KEY (MaCho) REFERENCES CHO_DO_XE (MaCho),
    CONSTRAINT CHK_DatCho_TienCoc   CHECK (TienCoc >= 0),
    CONSTRAINT CHK_DatCho_TrangThai CHECK (TrangThaiDatCho IN ('Active', 'Completed', 'Cancelled', 'Expired')),
    CONSTRAINT CHK_ThoiGianDat      CHECK (ThoiGianHetHan > ThoiGianDat)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE INDEX IDX_DatCho_ThoiGianHetHan ON DAT_CHO (ThoiGianHetHan);
CREATE INDEX IDX_DatCho_TrangThai ON DAT_CHO (TrangThaiDatCho);

USE smart_ev_parking;

CREATE TABLE PHIEN (
    MaPhien         VARCHAR(20)     NOT NULL,
    MaXe            VARCHAR(20)     NOT NULL,
    MaCho           VARCHAR(20)     NOT NULL,
    MaDatCho        VARCHAR(20)     NULL,
    LoaiPhien       VARCHAR(20)     NOT NULL,
    TrangThaiPhien  VARCHAR(20)     NOT NULL DEFAULT 'Active',
    ThoiGianVao     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ThoiGianRa      DATETIME        NULL,
    GhiChu          TEXT            NULL,
    XeDangHoatDong  VARCHAR(20)     GENERATED ALWAYS AS (IF(TrangThaiPhien = 'Active', MaXe,  NULL)) VIRTUAL,
    ChoDangHoatDong VARCHAR(20)     GENERATED ALWAYS AS (IF(TrangThaiPhien = 'Active', MaCho, NULL)) VIRTUAL,

    PRIMARY KEY (MaPhien),
    UNIQUE KEY UQ_Phien_MaDatCho (MaDatCho),
    UNIQUE KEY UQ_Phien_Active_Xe  (XeDangHoatDong),
    UNIQUE KEY UQ_Phien_Active_Cho (ChoDangHoatDong),
    CONSTRAINT FK_Phien_PhuongTien FOREIGN KEY (MaXe)      REFERENCES PHUONG_TIEN (MaXe),
    CONSTRAINT FK_Phien_ChoDoXe    FOREIGN KEY (MaCho)     REFERENCES CHO_DO_XE (MaCho),
    CONSTRAINT FK_Phien_DatCho     FOREIGN KEY (MaDatCho)  REFERENCES DAT_CHO (MaDatCho),
    CONSTRAINT CHK_Phien_LoaiPhien CHECK (LoaiPhien IN ('ParkingOnly', 'ParkingAndCharging')),
    CONSTRAINT CHK_Phien_TrangThai CHECK (TrangThaiPhien IN ('Active', 'Completed', 'Cancelled', 'Interrupted')),
    CONSTRAINT CHK_ThoiGianPhien   CHECK (ThoiGianRa IS NULL OR ThoiGianRa >= ThoiGianVao)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE INDEX IDX_Phien_MaXe ON PHIEN (MaXe);
CREATE INDEX IDX_Phien_MaCho ON PHIEN (MaCho);
CREATE INDEX IDX_Phien_ThoiGianVao ON PHIEN (ThoiGianVao);
CREATE INDEX IDX_Phien_TrangThai ON PHIEN (TrangThaiPhien);

USE smart_ev_parking;

CREATE TABLE CHI_TIET_PHIEN_SAC (
    MaPhien             VARCHAR(20)     NOT NULL,
    MaTru               VARCHAR(20)     NOT NULL,
    ThoiGianBatDauSac   DATETIME        NOT NULL,
    ThoiGianKetThucSac  DATETIME        NULL,
    ThoiGianHetAnHan    DATETIME        NULL,
    ThoiGianRutSungSac  DATETIME        NULL,
    ChiSoCongToDau      DECIMAL(10, 2)  NOT NULL,
    ChiSoCongToCuoi     DECIMAL(10, 2)  NULL,
    SoKWh               DECIMAL(10, 2)  GENERATED ALWAYS AS (ChiSoCongToCuoi - ChiSoCongToDau) STORED,
    HanMucSac_VND       DECIMAL(12, 2)  NULL,
    HanMucSac_kWh       DECIMAL(6, 2)   NULL,
    TrangThaiSac        VARCHAR(20)     NOT NULL DEFAULT 'Charging',
    LyDoKetThuc         VARCHAR(50)     NULL,

    PRIMARY KEY (MaPhien),
    CONSTRAINT FK_ChiTietPhienSac_Phien FOREIGN KEY (MaPhien) REFERENCES PHIEN (MaPhien),
    CONSTRAINT FK_ChiTietPhienSac_Tru   FOREIGN KEY (MaTru)   REFERENCES TRU_SAC (MaTru),
    CONSTRAINT CHK_PhienSac_CongToDau  CHECK (ChiSoCongToDau >= 0),
    CONSTRAINT CHK_PhienSac_CongToCuoi CHECK (ChiSoCongToCuoi IS NULL OR ChiSoCongToCuoi >= ChiSoCongToDau),
    CONSTRAINT CHK_PhienSac_HanMucVND  CHECK (HanMucSac_VND IS NULL OR HanMucSac_VND > 0),
    CONSTRAINT CHK_PhienSac_HanMuckWh  CHECK (HanMucSac_kWh IS NULL OR HanMucSac_kWh > 0),
    CONSTRAINT CHK_PhienSac_TrangThai  CHECK (TrangThaiSac IN ('Charging', 'Completed', 'Interrupted', 'Suspended')),
    CONSTRAINT CHK_PhienSac_LyDo CHECK (LyDoKetThuc IS NULL OR LyDoKetThuc IN (
        'Normal_FullBattery', 'UserStopped', 'AutoCutoff_LimitReached', 'AutoCutoff_LowBalance',
        'PowerLoss', 'EmergencyStop', 'Other')),

    CONSTRAINT CHK_ThoiGianSac CHECK (ThoiGianKetThucSac IS NULL OR ThoiGianKetThucSac >= ThoiGianBatDauSac),
    CONSTRAINT CHK_ThoiGianRutSung CHECK (
        ThoiGianRutSungSac IS NULL
        OR (ThoiGianKetThucSac IS NOT NULL AND ThoiGianRutSungSac >= ThoiGianKetThucSac)
    )
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE INDEX IDX_ChiTietPhienSac_MaTru ON CHI_TIET_PHIEN_SAC (MaTru);
CREATE INDEX IDX_ChiTietPhienSac_TrangThai ON CHI_TIET_PHIEN_SAC (TrangThaiSac);

USE smart_ev_parking;

CREATE TABLE CHI_TIET_PHI (
    MaPhien         VARCHAR(20)     NOT NULL,
    SoDong          INT             NOT NULL,
    MaBangGia       VARCHAR(20)     NOT NULL,
    KhoanMuc        VARCHAR(30)     NOT NULL,
    ThoiGianBatDau  DATETIME        NOT NULL,
    ThoiGianKetThuc DATETIME        NOT NULL,
    SoPhut          INT             NOT NULL,
    SoTien          DECIMAL(12, 2)  NOT NULL,

    PRIMARY KEY (MaPhien, SoDong),
    CONSTRAINT FK_ChiTietPhi_Phien   FOREIGN KEY (MaPhien)   REFERENCES PHIEN (MaPhien),
    CONSTRAINT FK_ChiTietPhi_BangGia FOREIGN KEY (MaBangGia) REFERENCES BANG_GIA (MaBangGia),
    CONSTRAINT CHK_ChiTietPhi_SoDong   CHECK (SoDong > 0),
    CONSTRAINT CHK_ChiTietPhi_KhoanMuc CHECK (KhoanMuc IN ('Parking', 'Charging', 'PostCharging')),
    CONSTRAINT CHK_ChiTietPhi_SoPhut   CHECK (SoPhut >= 0),
    CONSTRAINT CHK_ChiTietPhi_SoTien   CHECK (SoTien >= 0),
    CONSTRAINT CHK_ThoiGianPhi CHECK (ThoiGianKetThuc >= ThoiGianBatDau)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

USE smart_ev_parking;

CREATE TABLE HOA_DON (
    MaHD                    VARCHAR(20)     NOT NULL,
    MaPhien                 VARCHAR(20)     NOT NULL,
    PhiDoXe                 DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,
    PhiSacDien              DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,
    PhiDoSauSac             DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,
    TienKhauTru             DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,

    TongTien                DECIMAL(12, 2)  GENERATED ALWAYS AS
        (PhiDoXe + PhiSacDien + PhiDoSauSac - TienKhauTru) STORED,
    PhuongThucThanhToan     VARCHAR(30)     NOT NULL DEFAULT 'Wallet',
    TrangThaiThanhToan      VARCHAR(20)     NOT NULL DEFAULT 'Unpaid',
    MaGiaoDichNgoai         VARCHAR(100)    NULL,
    NgayLapHoaDon           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    NgayThanhToan           DATETIME        NULL,

    PRIMARY KEY (MaHD),
    UNIQUE KEY UQ_HoaDon_MaPhien (MaPhien),
    CONSTRAINT FK_HoaDon_Phien FOREIGN KEY (MaPhien) REFERENCES PHIEN (MaPhien),
    CONSTRAINT CHK_HoaDon_PhiDoXe     CHECK (PhiDoXe >= 0),
    CONSTRAINT CHK_HoaDon_PhiSacDien  CHECK (PhiSacDien >= 0),
    CONSTRAINT CHK_HoaDon_PhiDoSauSac CHECK (PhiDoSauSac >= 0),
    CONSTRAINT CHK_HoaDon_KhauTruAm   CHECK (TienKhauTru >= 0),
    CONSTRAINT CHK_HoaDon_PhuongThuc  CHECK (PhuongThucThanhToan IN ('Wallet', 'POS_Card', 'Dynamic_QR', 'Cash')),
    CONSTRAINT CHK_HoaDon_TrangThai   CHECK (TrangThaiThanhToan IN ('Unpaid', 'Paid', 'Refunded')),

    CONSTRAINT CHK_KhauTru CHECK (TienKhauTru <= (PhiDoXe + PhiSacDien + PhiDoSauSac)),

    CONSTRAINT CHK_NgayThanhToan CHECK (NgayThanhToan IS NULL OR NgayThanhToan >= NgayLapHoaDon)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE INDEX IDX_HoaDon_TrangThai ON HOA_DON (TrangThaiThanhToan);
CREATE INDEX IDX_HoaDon_NgayLap ON HOA_DON (NgayLapHoaDon);

USE smart_ev_parking;

CREATE TABLE GIAO_DICH_VI (
    MaGD                VARCHAR(20)     NOT NULL,
    MaKH                VARCHAR(20)     NOT NULL,
    LoaiGD              VARCHAR(20)     NOT NULL,
    SoTien              DECIMAL(12, 2)  NOT NULL,
    SoDuTruoc           DECIMAL(12, 2)  NOT NULL,
    SoDuSau             DECIMAL(12, 2)  NOT NULL,
    MaHD                VARCHAR(20)     NULL,
    MaGiaoDichDoiTac    VARCHAR(100)    NULL,
    ThoiGianGD          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    GhiChu              TEXT            NULL,

    PRIMARY KEY (MaGD),
    UNIQUE KEY UQ_GiaoDichVi_DoiTac (MaGiaoDichDoiTac),
    CONSTRAINT FK_GiaoDichVi_KhachHang FOREIGN KEY (MaKH) REFERENCES KHACH_HANG (MaKH),
    CONSTRAINT FK_GiaoDichVi_HoaDon    FOREIGN KEY (MaHD) REFERENCES HOA_DON (MaHD),
    CONSTRAINT CHK_GiaoDich_LoaiGD CHECK (LoaiGD IN ('Deposit', 'Payment', 'Refund', 'DirectPayment')),
    CONSTRAINT CHK_GiaoDich_SoTien CHECK (SoTien > 0),
    CONSTRAINT CHK_GiaoDich_SoDuTruoc CHECK (SoDuTruoc >= 0),
    CONSTRAINT CHK_GiaoDich_SoDuSau   CHECK (SoDuSau >= 0),

    CONSTRAINT CHK_GiaoDich_SoDu CHECK (
        (LoaiGD = 'Deposit'          AND SoDuSau = SoDuTruoc + SoTien)
        OR (LoaiGD = 'Payment'       AND SoDuSau = SoDuTruoc - SoTien)
        OR (LoaiGD = 'Refund'        AND SoDuSau = SoDuTruoc + SoTien)
        OR (LoaiGD = 'DirectPayment' AND SoDuTruoc = SoDuSau)
    )
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE INDEX IDX_GiaoDichVi_MaKH ON GIAO_DICH_VI (MaKH);
CREATE INDEX IDX_GiaoDichVi_ThoiGian ON GIAO_DICH_VI (ThoiGianGD);
CREATE INDEX IDX_GiaoDichVi_MaHD ON GIAO_DICH_VI (MaHD);

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
        UPDATE CHO_DO_XE SET TrangThaiCho = 'Available'
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

    IF NEW.MaDatCho IS NOT NULL THEN
        SELECT MaXe, MaCho INTO v_maxe_datcho, v_macho_datcho
        FROM DAT_CHO WHERE MaDatCho = NEW.MaDatCho;

        IF v_maxe_datcho <> NEW.MaXe THEN
            SET v_msg = CONCAT('Xe trong phiên (', NEW.MaXe, ') không khớp xe đặt chỗ (', v_maxe_datcho, ')');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
        END IF;
        IF v_macho_datcho <> NEW.MaCho THEN
            SET v_msg = CONCAT('Chỗ đỗ trong phiên (', NEW.MaCho, ') không khớp chỗ đặt (', v_macho_datcho, ')');
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

    SELECT ts.TrangThaiTru, lts.ChuanKetNoi
    INTO   v_trangthaitru, v_chuanketnoi
    FROM   TRU_SAC ts
    JOIN   LOAI_TRU_SAC lts ON ts.MaLoaiTru = lts.MaLoaiTru
    WHERE  ts.MaTru = NEW.MaTru;

    IF v_trangthaitru IN ('Faulted', 'Maintenance') THEN
        SET v_msg = CONCAT('Trụ sạc ', NEW.MaTru, ' đang bảo trì hoặc báo lỗi');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    SELECT pt.ChuanSac INTO v_chuansac_xe
    FROM   PHIEN p
    JOIN   PHUONG_TIEN pt ON p.MaXe = pt.MaXe
    WHERE  p.MaPhien = NEW.MaPhien;

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

USE smart_ev_parking;

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

    SET v_thoi_diem = COALESCE(p_thoi_diem, CURRENT_TIMESTAMP);

    SELECT COUNT(*) INTO v_so_dong FROM CHI_TIET_PHIEN_SAC WHERE MaPhien = p_ma_phien;
    IF v_so_dong = 0 THEN
        SET v_msg = CONCAT('Phiên sạc ', p_ma_phien, ' không tồn tại');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    SELECT ct.ChiSoCongToDau, ct.HanMucSac_VND, ct.HanMucSac_kWh, ct.ThoiGianBatDauSac,
           ts.MaLoaiTru, p.MaXe
    INTO   v_chi_so_dau, v_hanmuc_vnd, v_hanmuc_kwh, v_bat_dau_sac,
           v_ma_loai_tru, v_ma_xe
    FROM   CHI_TIET_PHIEN_SAC ct
    JOIN   PHIEN    p  ON ct.MaPhien = p.MaPhien
    JOIN   TRU_SAC  ts ON ct.MaTru   = ts.MaTru
    WHERE  ct.MaPhien = p_ma_phien;

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

    SELECT hd.TongTien, hd.TrangThaiThanhToan, hd.MaPhien, pt.MaKH
    INTO   v_tong_tien, v_trang_thai, v_ma_phien, v_ma_kh
    FROM   HOA_DON hd
    JOIN   PHIEN p        ON hd.MaPhien = p.MaPhien
    JOIN   PHUONG_TIEN pt ON p.MaXe = pt.MaXe
    WHERE  hd.MaHD = p_ma_hd;

    IF v_trang_thai IS NULL THEN
        SET v_msg = CONCAT('Hóa đơn ', p_ma_hd, ' không tồn tại');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
    IF v_trang_thai = 'Paid' THEN
        SET v_msg = CONCAT('Hóa đơn ', p_ma_hd, ' đã thanh toán!');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    SELECT SoDuViDienTu INTO v_sodu_hientai FROM KHACH_HANG WHERE MaKH = v_ma_kh;

    UPDATE HOA_DON
    SET TrangThaiThanhToan  = 'Paid',
        PhuongThucThanhToan = p_phuong_thuc,
        MaGiaoDichNgoai     = p_ma_gd_ngoai,
        NgayThanhToan       = CURRENT_TIMESTAMP
    WHERE MaHD = p_ma_hd;

    SET v_ma_gd = CONCAT('GD_WALK_', SUBSTRING(MD5(RAND()), 1, 8));
    INSERT INTO GIAO_DICH_VI (MaGD, MaKH, LoaiGD, SoTien, SoDuTruoc, SoDuSau, MaHD, MaGiaoDichDoiTac, GhiChu)
    VALUES (v_ma_gd, v_ma_kh, 'DirectPayment', v_tong_tien, v_sodu_hientai, v_sodu_hientai,
            p_ma_hd, p_ma_gd_ngoai, CONCAT('Thanh toán trực tiếp (', p_phuong_thuc, ') cho ', p_ma_hd));

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

USE smart_ev_parking;

CREATE ROLE IF NOT EXISTS 'app_user_role', 'station_operator_role', 'sys_admin_role';

GRANT SELECT ON smart_ev_parking.TRAM TO 'app_user_role';
GRANT SELECT ON smart_ev_parking.CHO_DO_XE TO 'app_user_role';
GRANT SELECT ON smart_ev_parking.LOAI_TRU_SAC TO 'app_user_role';
GRANT SELECT ON smart_ev_parking.TRU_SAC TO 'app_user_role';
GRANT SELECT ON smart_ev_parking.BANG_GIA TO 'app_user_role';
GRANT SELECT ON smart_ev_parking.KHACH_HANG TO 'app_user_role';
GRANT SELECT ON smart_ev_parking.PHUONG_TIEN TO 'app_user_role';
GRANT SELECT ON smart_ev_parking.HOA_DON TO 'app_user_role';
GRANT SELECT ON smart_ev_parking.GIAO_DICH_VI TO 'app_user_role';
GRANT SELECT, INSERT ON smart_ev_parking.DAT_CHO TO 'app_user_role';
GRANT SELECT, INSERT ON smart_ev_parking.PHIEN TO 'app_user_role';
GRANT SELECT, INSERT ON smart_ev_parking.CHI_TIET_PHIEN_SAC TO 'app_user_role';
GRANT EXECUTE ON PROCEDURE smart_ev_parking.sp_thanh_toan_hoa_don_vi TO 'app_user_role';
GRANT EXECUTE ON PROCEDURE smart_ev_parking.sp_kiem_tra_va_ngat_sac_tu_dong TO 'app_user_role';

GRANT SELECT, UPDATE ON smart_ev_parking.CHO_DO_XE TO 'station_operator_role';
GRANT SELECT, UPDATE ON smart_ev_parking.TRU_SAC TO 'station_operator_role';
GRANT SELECT, UPDATE ON smart_ev_parking.PHUONG_TIEN TO 'station_operator_role';
GRANT SELECT, UPDATE ON smart_ev_parking.HOA_DON TO 'station_operator_role';
GRANT SELECT, UPDATE ON smart_ev_parking.PHIEN TO 'station_operator_role';
GRANT SELECT, INSERT, UPDATE ON smart_ev_parking.BANG_GIA TO 'station_operator_role';
GRANT SELECT ON smart_ev_parking.KHACH_HANG TO 'station_operator_role';
GRANT SELECT ON smart_ev_parking.GIAO_DICH_VI TO 'station_operator_role';
GRANT EXECUTE ON PROCEDURE smart_ev_parking.sp_thanh_toan_walkin_ngoai TO 'station_operator_role';
GRANT EXECUTE ON PROCEDURE smart_ev_parking.sp_xu_ly_dat_cho_qua_han TO 'station_operator_role';
GRANT EXECUTE ON PROCEDURE smart_ev_parking.sp_kiem_tra_va_ngat_sac_tu_dong TO 'station_operator_role';

GRANT ALL PRIVILEGES ON smart_ev_parking.* TO 'sys_admin_role';

START TRANSACTION;

USE smart_ev_parking;

INSERT INTO KHACH_HANG (MaKH, HoTen, SDT, Email, LoaiKhach, SoDuViDienTu, TrangThaiTK, NgayDangKy) VALUES
('KH01', 'Nguyen Minh Khoa', '0901000001', 'khoa.nguyen@mail.com', 'Registered', 542000, 'Active', '2026-08-20 09:00:00'),
('KH02', 'Tran Thu Ha', '0901000002', 'ha.tran@mail.com', 'Registered', 413000, 'Active', '2026-08-25 10:30:00'),
('KH03', 'Le Quoc Bao', '0901000003', 'bao.le@mail.com', 'Registered', 677500, 'Active', '2026-09-01 14:00:00'),
('KH04', 'Pham Ngoc Lan', '0901000004', 'lan.pham@mail.com', 'Registered', 161000, 'Active', '2026-09-10 08:15:00'),
('KH05', 'Hoang Gia Huy', '0901000005', 'huy.hoang@mail.com', 'Registered', 150000, 'Active', '2026-09-18 16:45:00'),
('KH06', 'Vo Thanh Dat', '0901000006', 'dat.vo@mail.com', 'Registered', 475000, 'Active', '2026-09-25 11:20:00'),
('KH07', 'Dang Bao Tram', '0901000007', 'tram.dang@mail.com', 'Registered', 20000, 'Locked', '2026-09-28 13:00:00'),
('KH08', 'Khach Vang Lai 01', NULL, NULL, 'WalkIn', 0, 'Active', '2026-10-09 09:55:00');

USE smart_ev_parking;

INSERT INTO PHUONG_TIEN (MaXe, BienSo, MaKH, LoaiXe, ChuanSac, HangXe, CongSuatSacToiDa_kW, BiDenKhoa) VALUES
('XE01', '51A-123.45', 'KH01', 'Car_4W', 'CCS2', 'VinFast VF8', 150, FALSE),
('XE02', '51K-678.90', 'KH01', 'Car_4W', 'CCS2', 'VinFast VF9', 150, FALSE),
('XE03', '59A-111.22', 'KH02', 'Car_4W', 'CCS2', 'Hyundai Ioniq 5', 220, FALSE),
('XE04', '51H-333.44', 'KH03', 'Car_4W', 'CCS2', 'Tesla Model 3', 250, FALSE),
('XE05', '50E-555.66', 'KH04', 'Car_4W', 'Type2', 'VinFast VF5', 11, FALSE),
('XE06', '51F-777.88', 'KH05', 'Car_4W', 'CCS2', 'Kia EV6', 230, FALSE),
('XE07', '60A-999.00', 'KH06', 'Car_4W', 'CCS2', 'BYD Seal', 150, FALSE),
('XE08', '52B-246.80', 'KH07', 'Car_4W', 'Type2', 'VinFast VF3', 7, TRUE),
('XE09', '59X1-123.45', 'KH08', 'Motorbike_2W', 'AC_Plug', 'VinFast Feliz', 3, FALSE),
('XE10', '59Z1-555.66', 'KH04', 'Motorbike_2W', 'AC_Plug', 'Yadea Ulike', 3, FALSE);

USE smart_ev_parking;

INSERT INTO QUAN_TRI_VIEN (MaQTV, HoTen, Email, VaiTro) VALUES
('QTV01', 'Nguyen Van An', 'an.nguyen@smartcity.vn', 'Operator'),
('QTV02', 'Tran Thi Binh', 'binh.tran@smartcity.vn', 'Operator'),
('QTV03', 'Le Hoang Cuong', 'cuong.le@smartcity.vn', 'SysAdmin');

USE smart_ev_parking;

INSERT INTO TRAM (MaTram, TenTram, DiaChi, ViDo, KinhDo, PhutAnHanSauSac, SoDuToiThieu, MaQTV) VALUES
('T01', 'Tram Vincom Thu Duc', '216 Vo Van Ngan, TP Thu Duc, TP.HCM', 10.85, 106.765, 15, 20000, 'QTV01'),
('T02', 'Tram Landmark 81', '720A Dien Bien Phu, Binh Thanh, TP.HCM', 10.795, 106.722, 15, 20000, 'QTV01'),
('T03', 'Tram San bay Tan Son Nhat', 'Truong Son, Tan Binh, TP.HCM', 10.818, 106.659, 10, 50000, 'QTV02');

USE smart_ev_parking;

INSERT INTO CHO_DO_XE (MaCho, MaTram, MaViTri, LoaiCho, MoTaViTri) VALUES
('CHO01', 'T01', 'A-01', 'CarSlot', 'Tang ham B1, gan thang may'),
('CHO02', 'T01', 'A-02', 'CarSlot', 'Tang ham B1, khu sac nhanh'),
('CHO03', 'T01', 'A-03', 'CarSlot', 'Tang ham B1, khu sac sieu nhanh'),
('CHO04', 'T01', 'A-04', 'CarSlot', 'Tang ham B1, khong co tru'),
('CHO05', 'T01', 'A-05', 'CarSlot', 'Tang ham B1, khong co tru'),
('CHO13', 'T01', 'M-01', 'MotorbikeSlot', 'Khu xe may, co o cam sac'),
('CHO06', 'T02', 'B-01', 'CarSlot', 'Tang ham B2'),
('CHO07', 'T02', 'B-02', 'CarSlot', 'Tang ham B2'),
('CHO08', 'T02', 'B-03', 'CarSlot', 'Tang ham B2, khu sac nhanh'),
('CHO09', 'T02', 'B-04', 'CarSlot', 'Tang ham B2, khong co tru'),
('CHO14', 'T02', 'M-01', 'MotorbikeSlot', 'Khu xe may, khong co tru'),
('CHO10', 'T03', 'C-01', 'CarSlot', 'Bai ngoai troi, khu sac nhanh'),
('CHO11', 'T03', 'C-02', 'CarSlot', 'Bai ngoai troi, khu sac sieu nhanh'),
('CHO12', 'T03', 'C-03', 'CarSlot', 'Bai ngoai troi, khong co tru');

USE smart_ev_parking;

INSERT INTO LOAI_TRU_SAC (MaLoaiTru, TenLoai, DongDien, CongSuat_kW, ChuanKetNoi) VALUES
('LT01', 'AC 11 kW', 'AC', 11, 'Type2'),
('LT02', 'AC 22 kW', 'AC', 22, 'Type2'),
('LT03', 'DC 50 kW', 'DC', 50, 'CCS2'),
('LT04', 'DC 150 kW', 'DC', 150, 'CCS2'),
('LT05', 'AC 3 kW (xe may)', 'AC', 3, 'AC_Plug');

USE smart_ev_parking;

INSERT INTO TRU_SAC (MaTru, MaCho, MaLoaiTru, NgayLapDat) VALUES
('TS01', 'CHO01', 'LT02', '2026-01-15'),
('TS02', 'CHO02', 'LT03', '2026-01-15'),
('TS03', 'CHO03', 'LT04', '2026-02-01'),
('TS04', 'CHO06', 'LT01', '2026-03-10'),
('TS05', 'CHO07', 'LT02', '2026-03-10'),
('TS06', 'CHO08', 'LT03', '2026-04-05'),
('TS07', 'CHO10', 'LT03', '2026-05-20'),
('TS08', 'CHO11', 'LT04', '2026-05-20'),
('TS09', 'CHO13', 'LT05', '2026-06-01');

USE smart_ev_parking;

INSERT INTO BANG_GIA (MaBangGia, LoaiGia, MaLoaiTru, LoaiCho, GioBatDau, GioKetThuc, LaCaoDiem, DonGiaTheoPhut, HieuLucTu, HieuLucDen, MaQTV) VALUES
('BG01', 'Parking', NULL, 'CarSlot', '00:00:00', '06:00:00', FALSE, 300, '2026-01-01', NULL, 'QTV01'),
('BG02', 'Parking', NULL, 'CarSlot', '06:00:00', '22:00:00', TRUE, 500, '2026-10-01', NULL, 'QTV01'),
('BG03', 'Parking', NULL, 'CarSlot', '22:00:00', '23:59:59', FALSE, 300, '2026-01-01', NULL, 'QTV01'),
('BG04', 'Charging', 'LT01', NULL, '06:00:00', '22:00:00', TRUE, 1800, '2026-01-01', NULL, 'QTV01'),
('BG05', 'Charging', 'LT02', NULL, '06:00:00', '22:00:00', TRUE, 3000, '2026-01-01', NULL, 'QTV01'),
('BG06', 'Charging', 'LT03', NULL, '06:00:00', '22:00:00', TRUE, 6000, '2026-01-01', NULL, 'QTV01'),
('BG07', 'Charging', 'LT04', NULL, '06:00:00', '22:00:00', TRUE, 12000, '2026-01-01', NULL, 'QTV01'),
('BG08', 'Charging', 'LT02', NULL, '22:00:00', '23:59:59', FALSE, 2200, '2026-01-01', NULL, 'QTV01'),
('BG09', 'Charging', 'LT03', NULL, '22:00:00', '23:59:59', FALSE, 4500, '2026-01-01', NULL, 'QTV01'),
('BG10', 'PostCharging', NULL, 'CarSlot', '06:00:00', '22:00:00', TRUE, 1000, '2026-01-01', NULL, 'QTV01'),
('BG11', 'PostCharging', NULL, 'CarSlot', '22:00:00', '23:59:59', FALSE, 600, '2026-01-01', NULL, 'QTV01'),
('BG12', 'Parking', NULL, 'CarSlot', '06:00:00', '22:00:00', TRUE, 400, '2026-01-01', '2026-09-30', 'QTV01'),
('BG13', 'Parking', NULL, 'MotorbikeSlot', '06:00:00', '22:00:00', TRUE, 150, '2026-01-01', NULL, 'QTV01'),
('BG15', 'Charging', 'LT05', NULL, '06:00:00', '22:00:00', TRUE, 800, '2026-01-01', NULL, 'QTV01'),
('BG16', 'PostCharging', NULL, 'MotorbikeSlot', '06:00:00', '22:00:00', TRUE, 300, '2026-01-01', NULL, 'QTV01');

USE smart_ev_parking;

INSERT INTO DAT_CHO (MaDatCho, MaXe, MaCho, ThoiGianDat, ThoiGianHetHan, TienCoc, TrangThaiDatCho) VALUES
('DC01', 'XE03', 'CHO02', '2026-09-12 07:40:00', '2026-09-12 08:10:00', 20000, 'Completed'),
('DC02', 'XE04', 'CHO03', '2026-09-20 13:40:00', '2026-09-20 14:10:00', 0, 'Completed'),
('DC03', 'XE06', 'CHO08', '2026-10-05 17:40:00', '2026-10-05 18:10:00', 20000, 'Completed'),
('DC04', 'XE07', 'CHO10', '2026-10-08 22:40:00', '2026-10-08 23:10:00', 0, 'Completed'),
('DC05', 'XE01', 'CHO05', '2026-10-04 15:00:00', '2026-10-04 15:30:00', 20000, 'Expired'),
('DC06', 'XE02', 'CHO09', '2026-10-06 10:30:00', '2026-10-06 11:00:00', 0, 'Cancelled'),
('DC07', 'XE07', 'CHO08', '2026-10-13 14:30:00', '2026-10-13 15:30:00', 20000, 'Active');

USE smart_ev_parking;

INSERT INTO PHIEN (MaPhien, MaXe, MaCho, MaDatCho, LoaiPhien, TrangThaiPhien, ThoiGianVao, ThoiGianRa) VALUES
('P01', 'XE01', 'CHO04', NULL, 'ParkingOnly', 'Completed', '2026-09-10 09:00:00', '2026-09-10 11:00:00'),
('P02', 'XE03', 'CHO02', 'DC01', 'ParkingAndCharging', 'Completed', '2026-09-12 08:00:00', '2026-09-12 09:00:00'),
('P03', 'XE04', 'CHO03', 'DC02', 'ParkingAndCharging', 'Completed', '2026-09-20 14:00:00', '2026-09-20 15:00:00'),
('P04', 'XE05', 'CHO06', NULL, 'ParkingAndCharging', 'Completed', '2026-10-02 10:00:00', '2026-10-02 12:20:00'),
('P05', 'XE02', 'CHO09', NULL, 'ParkingOnly', 'Completed', '2026-10-03 07:30:00', '2026-10-03 10:30:00'),
('P06', 'XE06', 'CHO08', 'DC03', 'ParkingAndCharging', 'Completed', '2026-10-05 18:00:00', '2026-10-05 19:25:00'),
('P07', 'XE03', 'CHO03', NULL, 'ParkingAndCharging', 'Completed', '2026-10-07 12:00:00', '2026-10-07 12:50:00'),
('P08', 'XE07', 'CHO10', 'DC04', 'ParkingAndCharging', 'Completed', '2026-10-08 23:00:00', '2026-10-08 23:55:00'),
('P09', 'XE01', 'CHO12', NULL, 'ParkingOnly', 'Completed', '2026-10-10 13:00:00', '2026-10-10 15:30:00'),
('P10', 'XE04', 'CHO08', NULL, 'ParkingAndCharging', 'Completed', '2026-10-11 09:00:00', '2026-10-11 10:35:00'),
('P11', 'XE02', 'CHO05', NULL, 'ParkingOnly', 'Completed', '2026-10-12 08:00:00', '2026-10-12 09:30:00'),
('P16', 'XE09', 'CHO13', NULL, 'ParkingAndCharging', 'Completed', '2026-10-09 10:00:00', '2026-10-09 12:00:00'),
('P17', 'XE10', 'CHO14', NULL, 'ParkingOnly', 'Completed', '2026-10-11 08:00:00', '2026-10-11 10:00:00'),
('P18', 'XE07', 'CHO11', NULL, 'ParkingAndCharging', 'Interrupted', '2026-10-09 14:00:00', '2026-10-09 14:15:00'),
('P19', 'XE02', 'CHO09', NULL, 'ParkingOnly', 'Cancelled', '2026-10-06 11:00:00', '2026-10-06 11:05:00');

INSERT INTO PHIEN (MaPhien, MaXe, MaCho, MaDatCho, LoaiPhien, TrangThaiPhien, ThoiGianVao, ThoiGianRa) VALUES
('P12', 'XE05', 'CHO01', NULL, 'ParkingAndCharging', 'Active', '2026-10-12 16:00:00', NULL),
('P13', 'XE04', 'CHO03', NULL, 'ParkingAndCharging', 'Active', '2026-10-13 10:00:00', NULL),
('P14', 'XE06', 'CHO04', NULL, 'ParkingOnly', 'Active', '2026-10-13 08:00:00', NULL),
('P15', 'XE03', 'CHO02', NULL, 'ParkingAndCharging', 'Active', '2026-10-13 09:00:00', NULL);

USE smart_ev_parking;

INSERT INTO CHI_TIET_PHIEN_SAC (MaPhien, MaTru, ThoiGianBatDauSac, ThoiGianKetThucSac, ChiSoCongToDau, ChiSoCongToCuoi, HanMucSac_VND, HanMucSac_kWh, TrangThaiSac, LyDoKetThuc) VALUES
('P02', 'TS02', '2026-09-12 08:05:00', '2026-09-12 08:45:00', 5000, 5030, NULL, NULL, 'Completed', 'Normal_FullBattery'),
('P03', 'TS03', '2026-09-20 14:00:00', '2026-09-20 14:25:00', 2000, 2050, NULL, NULL, 'Completed', 'UserStopped'),
('P04', 'TS04', '2026-10-02 10:10:00', '2026-10-02 12:10:00', 300, 322, NULL, 22, 'Completed', 'AutoCutoff_LimitReached'),
('P06', 'TS06', '2026-10-05 18:00:00', '2026-10-05 18:40:00', 3000, 3030, NULL, NULL, 'Completed', 'Normal_FullBattery'),
('P07', 'TS03', '2026-10-07 12:00:00', '2026-10-07 12:30:00', 2050, 2110, NULL, NULL, 'Completed', 'Normal_FullBattery'),
('P08', 'TS07', '2026-10-08 23:00:00', '2026-10-08 23:50:00', 100, 125, 225000, NULL, 'Completed', 'AutoCutoff_LimitReached'),
('P10', 'TS06', '2026-10-11 09:05:00', '2026-10-11 09:50:00', 3030, 3058, NULL, NULL, 'Completed', 'UserStopped'),
('P12', 'TS01', '2026-10-12 16:00:00', '2026-10-12 17:00:00', 1000, 1022, NULL, NULL, 'Completed', 'Normal_FullBattery'),
('P13', 'TS03', '2026-10-13 10:05:00', NULL, 2110, NULL, NULL, NULL, 'Charging', NULL),
('P15', 'TS02', '2026-10-13 09:05:00', '2026-10-13 09:50:00', 5030, 5060, NULL, NULL, 'Completed', 'Normal_FullBattery'),
('P16', 'TS09', '2026-10-09 10:00:00', '2026-10-09 11:30:00', 50, 54.5, NULL, NULL, 'Completed', 'Normal_FullBattery'),
('P18', 'TS08', '2026-10-09 14:00:00', '2026-10-09 14:12:00', 700, 718, NULL, NULL, 'Interrupted', 'PowerLoss');

USE smart_ev_parking;

INSERT INTO CHI_TIET_PHI (MaPhien, SoDong, MaBangGia, KhoanMuc, ThoiGianBatDau, ThoiGianKetThuc, SoPhut, SoTien) VALUES
('P01', 1, 'BG12', 'Parking', '2026-09-10 09:00:00', '2026-09-10 11:00:00', 120, 48000),
('P02', 1, 'BG12', 'Parking', '2026-09-12 08:00:00', '2026-09-12 08:05:00', 5, 2000),
('P02', 2, 'BG06', 'Charging', '2026-09-12 08:05:00', '2026-09-12 08:45:00', 40, 240000),
('P03', 1, 'BG07', 'Charging', '2026-09-20 14:00:00', '2026-09-20 14:25:00', 25, 300000),
('P03', 2, 'BG10', 'PostCharging', '2026-09-20 14:40:00', '2026-09-20 15:00:00', 20, 20000),
('P04', 1, 'BG02', 'Parking', '2026-10-02 10:00:00', '2026-10-02 10:10:00', 10, 5000),
('P04', 2, 'BG04', 'Charging', '2026-10-02 10:10:00', '2026-10-02 12:10:00', 120, 216000),
('P05', 1, 'BG02', 'Parking', '2026-10-03 07:30:00', '2026-10-03 10:30:00', 180, 90000),
('P06', 1, 'BG06', 'Charging', '2026-10-05 18:00:00', '2026-10-05 18:40:00', 40, 240000),
('P06', 2, 'BG10', 'PostCharging', '2026-10-05 18:55:00', '2026-10-05 19:25:00', 30, 30000),
('P07', 1, 'BG07', 'Charging', '2026-10-07 12:00:00', '2026-10-07 12:30:00', 30, 360000),
('P07', 2, 'BG10', 'PostCharging', '2026-10-07 12:45:00', '2026-10-07 12:50:00', 5, 5000),
('P08', 1, 'BG09', 'Charging', '2026-10-08 23:00:00', '2026-10-08 23:50:00', 50, 225000),
('P09', 1, 'BG02', 'Parking', '2026-10-10 13:00:00', '2026-10-10 15:30:00', 150, 75000),
('P10', 1, 'BG02', 'Parking', '2026-10-11 09:00:00', '2026-10-11 09:05:00', 5, 2500),
('P10', 2, 'BG06', 'Charging', '2026-10-11 09:05:00', '2026-10-11 09:50:00', 45, 270000),
('P10', 3, 'BG10', 'PostCharging', '2026-10-11 10:05:00', '2026-10-11 10:35:00', 30, 30000),
('P11', 1, 'BG02', 'Parking', '2026-10-12 08:00:00', '2026-10-12 09:30:00', 90, 45000),
('P12', 1, 'BG05', 'Charging', '2026-10-12 16:00:00', '2026-10-12 17:00:00', 60, 180000),
('P12', 2, 'BG10', 'PostCharging', '2026-10-12 17:15:00', '2026-10-12 17:40:00', 25, 25000),
('P16', 1, 'BG15', 'Charging', '2026-10-09 10:00:00', '2026-10-09 11:30:00', 90, 72000),
('P16', 2, 'BG16', 'PostCharging', '2026-10-09 11:45:00', '2026-10-09 12:00:00', 15, 4500),
('P17', 1, 'BG13', 'Parking', '2026-10-11 08:00:00', '2026-10-11 10:00:00', 120, 18000),
('P18', 1, 'BG07', 'Charging', '2026-10-09 14:00:00', '2026-10-09 14:12:00', 12, 144000);

USE smart_ev_parking;

INSERT INTO HOA_DON (MaHD, MaPhien, PhiDoXe, PhiSacDien, PhiDoSauSac, TienKhauTru, PhuongThucThanhToan, TrangThaiThanhToan, NgayLapHoaDon, NgayThanhToan, MaGiaoDichNgoai) VALUES
('HD01', 'P01', 48000, 0, 0, 0, 'Wallet', 'Paid', '2026-09-10 11:00:00', '2026-09-10 11:01:00', NULL),
('HD02', 'P02', 2000, 240000, 0, 20000, 'Wallet', 'Paid', '2026-09-12 09:00:00', '2026-09-12 09:01:00', NULL),
('HD03', 'P03', 0, 300000, 20000, 0, 'Wallet', 'Paid', '2026-09-20 15:00:00', '2026-09-20 15:01:00', NULL),
('HD04', 'P04', 5000, 216000, 0, 0, 'Wallet', 'Paid', '2026-10-02 12:20:00', '2026-10-02 12:21:00', NULL),
('HD05', 'P05', 90000, 0, 0, 0, 'Wallet', 'Paid', '2026-10-03 10:30:00', '2026-10-03 10:31:00', NULL),
('HD06', 'P06', 0, 240000, 30000, 20000, 'Wallet', 'Paid', '2026-10-05 19:25:00', '2026-10-05 19:26:00', NULL),
('HD07', 'P07', 0, 360000, 5000, 0, 'Wallet', 'Paid', '2026-10-07 12:50:00', '2026-10-07 12:51:00', NULL),
('HD08', 'P08', 0, 225000, 0, 0, 'Wallet', 'Paid', '2026-10-08 23:55:00', '2026-10-08 23:56:00', NULL),
('HD09', 'P09', 75000, 0, 0, 0, 'Wallet', 'Paid', '2026-10-10 15:30:00', '2026-10-10 15:31:00', NULL),
('HD10', 'P10', 2500, 270000, 30000, 0, 'Wallet', 'Paid', '2026-10-11 10:35:00', '2026-10-11 10:36:00', NULL),
('HD11', 'P11', 45000, 0, 0, 0, 'Wallet', 'Paid', '2026-10-12 09:30:00', '2026-10-12 09:31:00', NULL),
('HD12', 'P12', 0, 180000, 25000, 0, 'Wallet', 'Unpaid', '2026-10-12 17:40:00', NULL, NULL),
('HD13', 'P16', 0, 72000, 4500, 0, 'Dynamic_QR', 'Paid', '2026-10-09 12:00:00', '2026-10-09 12:01:00', 'VQR-20261009-0001'),
('HD14', 'P17', 18000, 0, 0, 0, 'Wallet', 'Paid', '2026-10-11 10:00:00', '2026-10-11 10:01:00', NULL),
('HD15', 'P18', 0, 144000, 0, 0, 'Wallet', 'Refunded', '2026-10-09 14:15:00', '2026-10-09 14:16:00', NULL);

USE smart_ev_parking;

INSERT INTO GIAO_DICH_VI (MaGD, MaKH, LoaiGD, SoTien, SoDuTruoc, SoDuSau, MaHD, MaGiaoDichDoiTac, ThoiGianGD, GhiChu) VALUES
('GD01', 'KH01', 'Deposit', 500000, 0, 500000, NULL, 'VNP-0001', '2026-09-01 08:00:00', 'Nap tien qua ngan hang'),
('GD02', 'KH01', 'Payment', 48000, 500000, 452000, 'HD01', 'IDEM-HD01', '2026-09-10 11:01:00', 'Thanh toan HD01'),
('GD03', 'KH01', 'Payment', 90000, 452000, 362000, 'HD05', 'IDEM-HD05', '2026-10-03 10:31:00', 'Thanh toan HD05'),
('GD04', 'KH01', 'Deposit', 300000, 362000, 662000, NULL, 'MOMO-0002', '2026-10-05 09:00:00', 'Nap tien qua vi MoMo'),
('GD05', 'KH01', 'Payment', 75000, 662000, 587000, 'HD09', 'IDEM-HD09', '2026-10-10 15:31:00', 'Thanh toan HD09'),
('GD06', 'KH01', 'Payment', 45000, 587000, 542000, 'HD11', 'IDEM-HD11', '2026-10-12 09:31:00', 'Thanh toan HD11'),
('GD07', 'KH02', 'Deposit', 1000000, 0, 1000000, NULL, 'VNP-0003', '2026-09-05 10:00:00', 'Nap tien qua ngan hang'),
('GD08', 'KH02', 'Payment', 222000, 1000000, 778000, 'HD02', 'IDEM-HD02', '2026-09-12 09:01:00', 'Thanh toan HD02 (da tru coc 20.000)'),
('GD09', 'KH02', 'Payment', 365000, 778000, 413000, 'HD07', 'IDEM-HD07', '2026-10-07 12:51:00', 'Thanh toan HD07'),
('GD10', 'KH03', 'Deposit', 800000, 0, 800000, NULL, 'VNP-0004', '2026-09-15 09:30:00', 'Nap tien qua ngan hang'),
('GD11', 'KH03', 'Payment', 320000, 800000, 480000, 'HD03', 'IDEM-HD03', '2026-09-20 15:01:00', 'Thanh toan HD03'),
('GD12', 'KH03', 'Payment', 302500, 480000, 177500, 'HD10', 'IDEM-HD10', '2026-10-11 10:36:00', 'Thanh toan HD10'),
('GD13', 'KH03', 'Deposit', 500000, 177500, 677500, NULL, 'ZALO-0005', '2026-10-12 18:00:00', 'Nap tien qua vi ZaloPay'),
('GD14', 'KH04', 'Deposit', 300000, 0, 300000, NULL, 'VNP-0006', '2026-10-01 08:00:00', 'Nap tien qua ngan hang'),
('GD15', 'KH04', 'Payment', 221000, 300000, 79000, 'HD04', 'IDEM-HD04', '2026-10-02 12:21:00', 'Thanh toan HD04'),
('GD16', 'KH04', 'Deposit', 100000, 79000, 179000, NULL, 'VNP-0007', '2026-10-10 20:00:00', 'Nap tien qua ngan hang'),
('GD17', 'KH04', 'Payment', 18000, 179000, 161000, 'HD14', 'IDEM-HD14', '2026-10-11 10:01:00', 'Thanh toan HD14'),
('GD18', 'KH05', 'Deposit', 400000, 0, 400000, NULL, 'VNP-0008', '2026-10-04 12:00:00', 'Nap tien qua ngan hang'),
('GD19', 'KH05', 'Payment', 250000, 400000, 150000, 'HD06', 'IDEM-HD06', '2026-10-05 19:26:00', 'Thanh toan HD06 (da tru coc 20.000)'),
('GD20', 'KH06', 'Deposit', 700000, 0, 700000, NULL, 'VNP-0009', '2026-10-08 20:00:00', 'Nap tien qua ngan hang'),
('GD21', 'KH06', 'Payment', 225000, 700000, 475000, 'HD08', 'IDEM-HD08', '2026-10-08 23:56:00', 'Thanh toan HD08'),
('GD22', 'KH06', 'Payment', 144000, 475000, 331000, 'HD15', 'IDEM-HD15', '2026-10-09 14:16:00', 'Thanh toan HD15'),
('GD23', 'KH06', 'Refund', 144000, 331000, 475000, 'HD15', 'REFUND-HD15', '2026-10-09 15:00:00', 'Hoan tien: tru sac mat dien giua phien'),
('GD24', 'KH07', 'Deposit', 20000, 0, 20000, NULL, 'VNP-0010', '2026-09-28 13:30:00', 'Nap tien thu nghiem'),
('GD25', 'KH08', 'DirectPayment', 76500, 0, 0, 'HD13', 'VQR-20261009-0001', '2026-10-09 12:01:00', 'Khach vang lai thanh toan QR tai barrier');

USE smart_ev_parking;

UPDATE CHO_DO_XE SET TrangThaiCho = 'Reserved'    WHERE MaCho = 'CHO08' AND TrangThaiCho = 'Available';
UPDATE CHO_DO_XE SET TrangThaiCho = 'Maintenance' WHERE MaCho = 'CHO12';
UPDATE TRU_SAC   SET TrangThaiTru = 'Available'   WHERE MaTru IN ('TS01', 'TS02');
UPDATE TRU_SAC   SET TrangThaiTru = 'Maintenance' WHERE MaTru = 'TS05';
UPDATE TRU_SAC   SET TrangThaiTru = 'Faulted'     WHERE MaTru = 'TS08';

COMMIT;

USE smart_ev_parking;

SELECT  p.MaPhien, kh.HoTen, kh.LoaiKhach, pt.BienSo, t.TenTram, c.MaViTri,
        p.LoaiPhien, p.ThoiGianVao, p.ThoiGianRa,
        hd.TongTien, hd.PhuongThucThanhToan, hd.TrangThaiThanhToan
FROM PHIEN p
JOIN PHUONG_TIEN pt ON pt.MaXe    = p.MaXe
JOIN KHACH_HANG  kh ON kh.MaKH    = pt.MaKH
JOIN CHO_DO_XE   c  ON c.MaCho    = p.MaCho
JOIN TRAM        t  ON t.MaTram   = c.MaTram
JOIN HOA_DON     hd ON hd.MaPhien = p.MaPhien
WHERE p.TrangThaiPhien = 'Completed'
ORDER BY p.ThoiGianVao DESC;

SELECT  t.MaTram, t.TenTram,
        COUNT(DISTINCT p.MaPhien)           AS SoPhienHoanTat,
        COALESCE(SUM(hd.PhiDoXe), 0)        AS PhiDoXe,
        COALESCE(SUM(hd.PhiSacDien), 0)     AS PhiSacDien,
        COALESCE(SUM(hd.PhiDoSauSac), 0)    AS PhiDoSauSac,
        COALESCE(SUM(hd.TienKhauTru), 0)    AS TienKhauTru,
        COALESCE(SUM(hd.TongTien), 0)       AS DoanhThuThucThu
FROM TRAM t
LEFT JOIN CHO_DO_XE c ON c.MaTram = t.MaTram
LEFT JOIN PHIEN p     ON p.MaCho = c.MaCho
                     AND p.TrangThaiPhien = 'Completed'
                     AND p.ThoiGianVao >= DATE '2026-10-01'
                     AND p.ThoiGianVao <  DATE '2026-11-01'
LEFT JOIN HOA_DON hd  ON hd.MaPhien = p.MaPhien
                     AND hd.TrangThaiThanhToan = 'Paid'
GROUP BY t.MaTram, t.TenTram
ORDER BY DoanhThuThucThu DESC;

SELECT  kh.MaKH, kh.HoTen,
        COUNT(hd.MaHD)      AS SoHoaDonDaTra,
        SUM(hd.TongTien)    AS TongChiTieu,
        MAX(hd.TongTien)    AS HoaDonLonNhat
FROM KHACH_HANG kh
JOIN PHUONG_TIEN pt ON pt.MaKH    = kh.MaKH
JOIN PHIEN p        ON p.MaXe     = pt.MaXe
JOIN HOA_DON hd     ON hd.MaPhien = p.MaPhien
WHERE hd.TrangThaiThanhToan = 'Paid'
GROUP BY kh.MaKH, kh.HoTen
HAVING SUM(hd.TongTien) >= 250000
ORDER BY TongChiTieu DESC;

SELECT  hd.MaHD, hd.MaPhien, pt.BienSo, hd.TongTien,
        (SELECT ROUND(AVG(TongTien), 0) FROM HOA_DON) AS TrungBinhHeThong
FROM HOA_DON hd
JOIN PHIEN p        ON p.MaPhien = hd.MaPhien
JOIN PHUONG_TIEN pt ON pt.MaXe   = p.MaXe
WHERE hd.TongTien > (SELECT AVG(TongTien) FROM HOA_DON)
ORDER BY hd.TongTien DESC;

SELECT  pt.MaXe, pt.BienSo, pt.LoaiXe, pt.ChuanSac, pt.BiDenKhoa, kh.HoTen, kh.TrangThaiTK
FROM PHUONG_TIEN pt
JOIN KHACH_HANG kh ON kh.MaKH = pt.MaKH
WHERE NOT EXISTS (SELECT 1 FROM PHIEN p WHERE p.MaXe = pt.MaXe);

SELECT  ts.MaTru, t.TenTram, c.MaViTri, lt.TenLoai, lt.ChuanKetNoi, ts.TrangThaiTru
FROM TRU_SAC ts
JOIN CHO_DO_XE c     ON c.MaCho = ts.MaCho
JOIN TRAM t          ON t.MaTram = c.MaTram
JOIN LOAI_TRU_SAC lt ON lt.MaLoaiTru = ts.MaLoaiTru
WHERE ts.MaTru NOT IN (SELECT cts.MaTru FROM CHI_TIET_PHIEN_SAC cts);

SELECT  lt.MaLoaiTru, lt.TenLoai, lt.DongDien,
        COUNT(*)                      AS SoPhienSac,
        SUM(cts.SoKWh)                AS TongKWh,
        ROUND(AVG(cts.SoKWh), 2)      AS KWhTrungBinh,
        ROUND(AVG(TIMESTAMPDIFF(SECOND, cts.ThoiGianBatDauSac, cts.ThoiGianKetThucSac) / 60), 1)
                                      AS PhutSacTrungBinh,
        SUM(CASE WHEN cts.LyDoKetThuc LIKE 'AutoCutoff%' THEN 1 ELSE 0 END) AS SoLanTuNgat
FROM CHI_TIET_PHIEN_SAC cts
JOIN TRU_SAC ts      ON ts.MaTru     = cts.MaTru
JOIN LOAI_TRU_SAC lt ON lt.MaLoaiTru = ts.MaLoaiTru
WHERE cts.ThoiGianKetThucSac IS NOT NULL
GROUP BY lt.MaLoaiTru, lt.TenLoai, lt.DongDien
ORDER BY TongKWh DESC;

WITH chi_tieu AS (
    SELECT  t.MaTram, t.TenTram, kh.MaKH, kh.HoTen,
            SUM(hd.TongTien) AS TongChiTieu
    FROM HOA_DON hd
    JOIN PHIEN p        ON p.MaPhien = hd.MaPhien
    JOIN CHO_DO_XE c    ON c.MaCho   = p.MaCho
    JOIN TRAM t         ON t.MaTram  = c.MaTram
    JOIN PHUONG_TIEN pt ON pt.MaXe   = p.MaXe
    JOIN KHACH_HANG kh  ON kh.MaKH   = pt.MaKH
    WHERE hd.TrangThaiThanhToan = 'Paid'
    GROUP BY t.MaTram, t.TenTram, kh.MaKH, kh.HoTen
),
xep_hang AS (
    SELECT  chi_tieu.*,
            RANK() OVER (PARTITION BY MaTram ORDER BY TongChiTieu DESC) AS Hang
    FROM chi_tieu
)
SELECT MaTram, TenTram, MaKH, HoTen, TongChiTieu
FROM xep_hang
WHERE Hang = 1
ORDER BY MaTram;

SELECT  ctp.KhoanMuc,
        COALESCE(bg.LoaiCho, 'Tru sac')                                 AS LoaiCho,
        CASE WHEN bg.LaCaoDiem THEN 'Cao diem' ELSE 'Thap diem' END     AS KhungGio,
        COUNT(*)            AS SoDongPhi,
        SUM(ctp.SoPhut)     AS TongPhut,
        SUM(ctp.SoTien)     AS TongTien,
        ROUND(SUM(ctp.SoTien) / NULLIF(SUM(ctp.SoPhut), 0), 0) AS DonGiaBinhQuan
FROM CHI_TIET_PHI ctp
JOIN BANG_GIA bg ON bg.MaBangGia = ctp.MaBangGia
GROUP BY ctp.KhoanMuc, bg.LoaiCho, bg.LaCaoDiem
ORDER BY ctp.KhoanMuc, LoaiCho, bg.LaCaoDiem DESC;

SELECT  hd.MaHD, hd.MaPhien,
        hd.PhiDoXe,     ct.TongDoXe,
        hd.PhiSacDien,  ct.TongSac,
        hd.PhiDoSauSac, ct.TongDoSauSac
FROM HOA_DON hd
LEFT JOIN (
    SELECT  MaPhien,
            COALESCE(SUM(CASE WHEN KhoanMuc = 'Parking' THEN SoTien END), 0) AS TongDoXe,
            COALESCE(SUM(CASE WHEN KhoanMuc = 'Charging' THEN SoTien END), 0) AS TongSac,
            COALESCE(SUM(CASE WHEN KhoanMuc = 'PostCharging' THEN SoTien END), 0) AS TongDoSauSac
    FROM CHI_TIET_PHI
    GROUP BY MaPhien
) ct ON ct.MaPhien = hd.MaPhien
WHERE hd.PhiDoXe     <> COALESCE(ct.TongDoXe, 0)
   OR hd.PhiSacDien  <> COALESCE(ct.TongSac, 0)
   OR hd.PhiDoSauSac <> COALESCE(ct.TongDoSauSac, 0);

SELECT *
FROM (
    SELECT  g.MaGD, g.MaKH, g.ThoiGianGD, g.SoDuTruoc,
            LAG(g.SoDuSau) OVER (PARTITION BY g.MaKH ORDER BY g.ThoiGianGD, g.MaGD) AS SoDuSauGiaoDichTruoc
    FROM GIAO_DICH_VI g
) x
WHERE x.SoDuSauGiaoDichTruoc IS NOT NULL
  AND x.SoDuTruoc <> x.SoDuSauGiaoDichTruoc;

SELECT  kh.MaKH, kh.HoTen, kh.SoDuViDienTu, g.SoDuSau AS SoDuSauGiaoDichCuoi
FROM KHACH_HANG kh
JOIN GIAO_DICH_VI g ON g.MaKH = kh.MaKH
WHERE g.ThoiGianGD = (SELECT MAX(g2.ThoiGianGD) FROM GIAO_DICH_VI g2 WHERE g2.MaKH = kh.MaKH)
  AND kh.SoDuViDienTu <> g.SoDuSau;

SELECT  p.MaPhien, pt.BienSo, kh.HoTen, kh.SDT,
        t.TenTram, c.MaViTri,
        cts.ThoiGianKetThucSac, cts.ThoiGianHetAnHan,
        CASE WHEN CURRENT_TIMESTAMP >= cts.ThoiGianHetAnHan
             THEN 'DA QUA AN HAN' ELSE 'Dang trong an han' END AS TinhTrang,
        ROUND(GREATEST(TIMESTAMPDIFF(SECOND, cts.ThoiGianHetAnHan, CURRENT_TIMESTAMP) / 60, 0), 0) AS SoPhutQuaAnHan
FROM PHIEN p
JOIN CHI_TIET_PHIEN_SAC cts ON cts.MaPhien = p.MaPhien
JOIN PHUONG_TIEN pt         ON pt.MaXe     = p.MaXe
JOIN KHACH_HANG kh          ON kh.MaKH     = pt.MaKH
JOIN CHO_DO_XE c            ON c.MaCho     = p.MaCho
JOIN TRAM t                 ON t.MaTram    = c.MaTram
WHERE p.TrangThaiPhien = 'Active'
  AND cts.ThoiGianKetThucSac IS NOT NULL
ORDER BY SoPhutQuaAnHan DESC;

SELECT  hd.MaHD, hd.TrangThaiThanhToan, hd.TongTien, g.MaGD, g.LoaiGD, g.SoTien
FROM HOA_DON hd
LEFT JOIN GIAO_DICH_VI g ON g.MaHD = hd.MaHD
                        AND g.LoaiGD IN ('Payment', 'DirectPayment')
WHERE hd.TrangThaiThanhToan IN ('Paid', 'Refunded')
  AND (g.MaGD IS NULL OR g.SoTien <> hd.TongTien);

USE smart_ev_parking;

CREATE OR REPLACE VIEW VW_CHO_DO_TRONG AS
SELECT  t.MaTram, t.TenTram, c.MaCho, c.MaViTri, c.LoaiCho, c.MoTaViTri,
        ts.MaTru, lt.TenLoai AS LoaiTru, lt.ChuanKetNoi, lt.CongSuat_kW,
        CASE
            WHEN ts.MaTru IS NULL                              THEN 'Khong co tru sac'
            WHEN ts.TrangThaiTru IN ('Faulted', 'Maintenance') THEN 'Tru khong kha dung'
            ELSE 'San sang sac'
        END AS TinhTrangSac
FROM CHO_DO_XE c
JOIN TRAM t               ON t.MaTram = c.MaTram
LEFT JOIN TRU_SAC ts      ON ts.MaCho = c.MaCho
LEFT JOIN LOAI_TRU_SAC lt ON lt.MaLoaiTru = ts.MaLoaiTru
WHERE c.TrangThaiCho = 'Available';

CREATE OR REPLACE VIEW VW_DOANH_THU_TRAM_THANG AS
SELECT  t.MaTram, t.TenTram,
        CAST(DATE_FORMAT(hd.NgayThanhToan, '%Y-%m-01') AS DATE) AS Thang,
        COUNT(*)                AS SoHoaDon,
        SUM(hd.PhiDoXe)         AS PhiDoXe,
        SUM(hd.PhiSacDien)      AS PhiSacDien,
        SUM(hd.PhiDoSauSac)     AS PhiDoSauSac,
        SUM(hd.TienKhauTru)     AS TienKhauTru,
        SUM(hd.TongTien)        AS DoanhThuThucThu
FROM HOA_DON hd
JOIN PHIEN p     ON p.MaPhien = hd.MaPhien
JOIN CHO_DO_XE c ON c.MaCho   = p.MaCho
JOIN TRAM t      ON t.MaTram  = c.MaTram
WHERE hd.TrangThaiThanhToan = 'Paid'
GROUP BY t.MaTram, t.TenTram, CAST(DATE_FORMAT(hd.NgayThanhToan, '%Y-%m-01') AS DATE);

SELECT * FROM VW_CHO_DO_TRONG ORDER BY MaTram, MaViTri;
SELECT * FROM VW_DOANH_THU_TRAM_THANG ORDER BY Thang, MaTram;

USE smart_ev_parking;
