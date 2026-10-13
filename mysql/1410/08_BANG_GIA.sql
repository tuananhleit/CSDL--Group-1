-- =============================================================================
-- TABLE 08: BANG_GIA (Pricing Tariff)
-- =============================================================================
-- Mô tả: Bảng giá theo khung giờ, loại phí, loại trụ/chỗ đỗ
-- Dependencies: LOAI_TRU_SAC, QUAN_TRI_VIEN
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

    -- [FIX #4] Charging bắt buộc có MaLoaiTru, không có LoaiCho
    --          Parking/PostCharging bắt buộc có LoaiCho, không có MaLoaiTru
    CONSTRAINT CHK_LoaiGia_LoaiTru CHECK (
        (LoaiGia = 'Charging'
            AND MaLoaiTru IS NOT NULL
            AND LoaiCho IS NULL)
        OR (LoaiGia IN ('Parking', 'PostCharging')
            AND MaLoaiTru IS NULL
            AND LoaiCho IS NOT NULL)
    ),

    -- Khung giờ không được vượt qua mốc nửa đêm
    CONSTRAINT CHK_KhungGio CHECK (GioKetThuc > GioBatDau),

    -- [FIX #5] Ngày kết thúc hiệu lực không trước ngày bắt đầu
    CONSTRAINT CHK_HieuLuc CHECK (
        HieuLucDen IS NULL OR HieuLucDen >= HieuLucTu
    )
);
