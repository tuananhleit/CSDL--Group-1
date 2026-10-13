-- =============================================================================
-- TABLE 12: CHI_TIET_PHI (Fee Detail — Weak Entity)
-- =============================================================================
-- Mô tả: Thực thể yếu, lưu chi tiết từng khoản phí của phiên
-- Dependencies: PHIEN, BANG_GIA
-- =============================================================================

CREATE TABLE CHI_TIET_PHI (
    MaPhien         VARCHAR(20)
        REFERENCES PHIEN(MaPhien),                  -- [FIX] Bỏ ON DELETE CASCADE
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
