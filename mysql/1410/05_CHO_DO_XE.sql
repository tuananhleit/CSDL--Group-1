-- =============================================================================
-- TABLE 05: CHO_DO_XE (Parking Slot)
-- =============================================================================
-- Mô tả: Lưu thông tin chỗ đỗ xe, phân biệt CarSlot / MotorbikeSlot
-- Dependencies: TRAM
-- =============================================================================

CREATE TABLE CHO_DO_XE (
    MaCho           VARCHAR(20)     PRIMARY KEY,
    MaTram          VARCHAR(20)     NOT NULL
        REFERENCES TRAM(MaTram),                    -- [FIX] Bỏ ON DELETE CASCADE
    MaViTri         VARCHAR(20)     NOT NULL,
    LoaiCho         VARCHAR(20)     NOT NULL DEFAULT 'CarSlot'
        CHECK (LoaiCho IN ('CarSlot', 'MotorbikeSlot')),
    MoTaViTri       VARCHAR(100),
    TrangThaiCho    VARCHAR(20)     NOT NULL DEFAULT 'Available'
        CHECK (TrangThaiCho IN ('Available', 'Occupied', 'Reserved', 'Maintenance')),

    -- Mã vị trí chỉ cần không trùng trong cùng một trạm
    CONSTRAINT UQ_Tram_ViTri UNIQUE (MaTram, MaViTri)
);

-- [CẢI THIỆN] Index tăng hiệu năng truy vấn tìm chỗ trống theo trạm
CREATE INDEX IDX_ChoDoXe_Tram_TrangThai ON CHO_DO_XE (MaTram, TrangThaiCho);
