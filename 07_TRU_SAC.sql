-- =============================================================================
-- TABLE 07: TRU_SAC (Charging Pillar)
-- =============================================================================
-- Mô tả: Lưu thông tin trụ sạc, quan hệ 1:0..1 với CHO_DO_XE
-- Dependencies: CHO_DO_XE, LOAI_TRU_SAC
-- =============================================================================

CREATE TABLE TRU_SAC (
    MaTru           VARCHAR(20)     PRIMARY KEY,
    MaCho           VARCHAR(20)     NOT NULL UNIQUE
        REFERENCES CHO_DO_XE(MaCho),                -- [FIX] Bỏ ON DELETE CASCADE
    MaLoaiTru       VARCHAR(20)     NOT NULL
        REFERENCES LOAI_TRU_SAC(MaLoaiTru),
    TrangThaiTru    VARCHAR(20)     NOT NULL DEFAULT 'Available'
        CHECK (TrangThaiTru IN ('Available', 'Charging', 'Faulted', 'Maintenance')),
    NgayLapDat      DATE            NOT NULL DEFAULT CURRENT_DATE
);
