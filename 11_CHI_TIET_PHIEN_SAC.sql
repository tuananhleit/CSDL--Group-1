-- =============================================================================
-- TABLE 11: CHI_TIET_PHIEN_SAC (Charging Session Detail — Subclass of PHIEN)
-- =============================================================================
-- Mô tả: Chi tiết phiên sạc thân thiện người dùng:
--        Hỗ trợ khách hàng tự đặt Hạn mức sạc mong muốn (HanMucSac_VND / HanMucSac_kWh),
--        hệ thống tự động ngắt điện khi đạt hạn mức hoặc chạm trần số dư ví.
-- Dependencies: PHIEN, TRU_SAC
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

    -- Khách hàng tự chủ động đặt hạn mức sạc theo nhu cầu cá nhân
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

    -- Ràng buộc logic các mốc thời gian
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
CREATE INDEX IDX_ChiTietPhienSac_TrangThai ON CHI_TIET_PHIEN_SAC (TrangThaiSac);
