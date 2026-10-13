-- =============================================================================
-- TABLE 02: PHUONG_TIEN (Vehicle)
-- =============================================================================
-- Mô tả: Quản lý phương tiện cá nhân & xe vãng lai, chuẩn kết nối sạc,
--        cờ khóa nợ xấu bảo vệ doanh nghiệp.
-- Dependencies: KHACH_HANG
-- =============================================================================

CREATE TABLE PHUONG_TIEN (
    MaXe                VARCHAR(20)     PRIMARY KEY,
    BienSo              VARCHAR(20)     NOT NULL UNIQUE,
    MaKH                VARCHAR(20)     NOT NULL
        REFERENCES KHACH_HANG(MaKH),
    LoaiXe              VARCHAR(20)     NOT NULL DEFAULT 'Car_4W'
        CHECK (LoaiXe IN ('Car_4W', 'Motorbike_2W')),
    ChuanSac            VARCHAR(20)     NOT NULL DEFAULT 'CCS2'
        CHECK (ChuanSac IN ('CCS2', 'Type2', 'GB_T', 'CHAdeMO', 'AC_Plug', 'Other')),
    HangXe              VARCHAR(50),
    CongSuatSacToiDa_kW NUMERIC(5, 2)  CHECK (CongSuatSacToiDa_kW > 0),
    BiDenKhoa           BOOLEAN         NOT NULL DEFAULT FALSE
);

CREATE INDEX IDX_PhuongTien_BienSo ON PHUONG_TIEN (BienSo);
CREATE INDEX IDX_PhuongTien_MaKH ON PHUONG_TIEN (MaKH);
