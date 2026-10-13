-- =============================================================================
-- TABLE 13: HOA_DON (Invoice)
-- =============================================================================
-- Mô tả: Hóa đơn thanh toán dịch vụ, hỗ trợ khấu trừ tiền cọc đặt chỗ/ưu đãi,
--        đa dạng phương thức thanh toán cho khách B2C (Ví) và Walk-in (QR/POS/Tiền mặt).
-- Dependencies: PHIEN
-- =============================================================================

CREATE TABLE HOA_DON (
    MaHD                    VARCHAR(20)     PRIMARY KEY,
    MaPhien                 VARCHAR(20)     NOT NULL UNIQUE
        REFERENCES PHIEN(MaPhien),
    PhiDoXe                 NUMERIC(12, 2)  NOT NULL DEFAULT 0.00
        CHECK (PhiDoXe >= 0),
    PhiSacDien              NUMERIC(12, 2)  NOT NULL DEFAULT 0.00
        CHECK (PhiSacDien >= 0),
    PhiDoSauSac             NUMERIC(12, 2)  NOT NULL DEFAULT 0.00
        CHECK (PhiDoSauSac >= 0),
    TienKhauTru             NUMERIC(12, 2)  NOT NULL DEFAULT 0.00
        CHECK (TienKhauTru >= 0),

    -- Tổng tiền thực thu sau khi trừ cọc/ưu đãi
    TongTien                NUMERIC(12, 2)  GENERATED ALWAYS AS
        (PhiDoXe + PhiSacDien + PhiDoSauSac - TienKhauTru) STORED,

    PhuongThucThanhToan     VARCHAR(30)     NOT NULL DEFAULT 'Wallet'
        CHECK (PhuongThucThanhToan IN ('Wallet', 'POS_Card', 'Dynamic_QR', 'Cash')),
    TrangThaiThanhToan      VARCHAR(20)     NOT NULL DEFAULT 'Unpaid'
        CHECK (TrangThaiThanhToan IN ('Unpaid', 'Paid', 'Refunded')),
    MaGiaoDichNgoai         VARCHAR(100),
    NgayLapHoaDon           TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    NgayThanhToan           TIMESTAMP,

    -- Khấu trừ không được vượt quá tổng các khoản phí phát sinh
    CONSTRAINT CHK_KhauTru CHECK (
        TienKhauTru <= (PhiDoXe + PhiSacDien + PhiDoSauSac)
    ),

    -- Ngày thanh toán không được trước ngày lập hóa đơn
    CONSTRAINT CHK_NgayThanhToan CHECK (
        NgayThanhToan IS NULL OR NgayThanhToan >= NgayLapHoaDon
    ),

    -- Tổng tiền thực thu không âm
    CONSTRAINT CHK_TongTienKhongAm CHECK (TongTien >= 0),

    -- Trạng thái và thời gian thanh toán phải nhất quán
    CONSTRAINT CHK_TrangThai_NgayThanhToan CHECK (
        (TrangThaiThanhToan = 'Unpaid' AND NgayThanhToan IS NULL)
        OR (TrangThaiThanhToan IN ('Paid', 'Refunded') AND NgayThanhToan IS NOT NULL)
    )
);

CREATE INDEX IDX_HoaDon_TrangThai ON HOA_DON (TrangThaiThanhToan);
CREATE INDEX IDX_HoaDon_NgayLap ON HOA_DON (NgayLapHoaDon);
CREATE UNIQUE INDEX UQ_HoaDon_MaGiaoDichNgoai
    ON HOA_DON (MaGiaoDichNgoai)
    WHERE MaGiaoDichNgoai IS NOT NULL;
