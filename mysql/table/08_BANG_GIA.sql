SET NAMES utf8mb4;
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
