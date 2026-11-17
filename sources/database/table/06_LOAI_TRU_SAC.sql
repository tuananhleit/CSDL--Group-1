SET NAMES utf8mb4;
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

INSERT INTO LOAI_TRU_SAC (MaLoaiTru, TenLoai, DongDien, CongSuat_kW, ChuanKetNoi) VALUES
('LT01', 'AC 11 kW', 'AC', 11, 'Type2'),
('LT02', 'AC 22 kW', 'AC', 22, 'Type2'),
('LT03', 'DC 50 kW', 'DC', 50, 'CCS2'),
('LT04', 'DC 150 kW', 'DC', 150, 'CCS2'),
('LT05', 'AC 3 kW (xe may)', 'AC', 3, 'AC_Plug');
