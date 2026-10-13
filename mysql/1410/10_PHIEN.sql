-- =============================================================================
-- TABLE 10: PHIEN (Service Session)
-- =============================================================================
-- Mô tả: Phiên dịch vụ bãi đỗ & trạm sạc cho khách B2C và Walk-in.
--        Hỗ trợ trạng thái sự cố (Interrupted) để đảm bảo trải nghiệm khách hàng
--        khi mất điện hoặc lỗi kỹ thuật.
-- Dependencies: PHUONG_TIEN, CHO_DO_XE, DAT_CHO
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

-- Mỗi xe chỉ có tối đa MỘT phiên đang hoạt động
CREATE UNIQUE INDEX UQ_Phien_Active_Xe ON PHIEN (MaXe)
    WHERE TrangThaiPhien = 'Active';

-- Mỗi chỗ đỗ chỉ có tối đa MỘT phiên đang hoạt động
CREATE UNIQUE INDEX UQ_Phien_Active_Cho ON PHIEN (MaCho)
    WHERE TrangThaiPhien = 'Active';

CREATE INDEX IDX_Phien_MaXe ON PHIEN (MaXe);
CREATE INDEX IDX_Phien_MaCho ON PHIEN (MaCho);
CREATE INDEX IDX_Phien_ThoiGianVao ON PHIEN (ThoiGianVao);
CREATE INDEX IDX_Phien_TrangThai ON PHIEN (TrangThaiPhien);
