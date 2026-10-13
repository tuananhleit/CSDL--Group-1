-- =============================================================================
-- TABLE 06: LOAI_TRU_SAC (Charger Type)
-- =============================================================================
-- Mô tả: Bảng phân loại cấp công suất trụ sạc (AC/DC, kW, chuẩn kết nối)
-- Dependencies: Không phụ thuộc bảng nào
-- =============================================================================

CREATE TABLE LOAI_TRU_SAC (
    MaLoaiTru   VARCHAR(20)     PRIMARY KEY,
    TenLoai     VARCHAR(50)     NOT NULL,
    DongDien    VARCHAR(10)     NOT NULL
        CHECK (DongDien IN ('AC', 'DC')),
    CongSuat_kW NUMERIC(5, 2)  NOT NULL
        CHECK (CongSuat_kW > 0),
    ChuanKetNoi VARCHAR(30)     NOT NULL
);
