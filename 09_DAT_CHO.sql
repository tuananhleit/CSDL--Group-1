-- =============================================================================
-- TABLE 09: DAT_CHO (Reservation)
-- =============================================================================
-- Mô tả: Đặt chỗ trước cho phương tiện, cơ chế tiền cọc chống No-Show phá hoại,
--        bảo vệ doanh thu cho doanh nghiệp SME.
-- Dependencies: PHUONG_TIEN, CHO_DO_XE
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

-- Mỗi xe chỉ có tối đa MỘT đặt chỗ đang hiệu lực
CREATE UNIQUE INDEX UQ_DatCho_Active_Xe ON DAT_CHO (MaXe)
    WHERE TrangThaiDatCho = 'Active';

-- Mỗi chỗ đỗ chỉ có tối đa MỘT đặt chỗ đang hiệu lực
CREATE UNIQUE INDEX UQ_DatCho_Active_Cho ON DAT_CHO (MaCho)
    WHERE TrangThaiDatCho = 'Active';

CREATE INDEX IDX_DatCho_ThoiGianHetHan ON DAT_CHO (ThoiGianHetHan);
CREATE INDEX IDX_DatCho_TrangThai ON DAT_CHO (TrangThaiDatCho);
