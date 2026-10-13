-- =============================================================================
-- TABLE 14: GIAO_DICH_VI (Wallet Ledger)
-- =============================================================================
-- Mô tả: Sổ cái giao dịch tài chính nội bộ, bất biến (Append-Only),
--        hỗ trợ Idempotency Key (MaGiaoDichDoiTac) chống trùng lặp Webhook.
-- Dependencies: KHACH_HANG, HOA_DON
-- =============================================================================

CREATE TABLE GIAO_DICH_VI (
    MaGD                VARCHAR(20)     PRIMARY KEY,
    MaKH                VARCHAR(20)     NOT NULL
        REFERENCES KHACH_HANG(MaKH),
    LoaiGD              VARCHAR(20)     NOT NULL
        CHECK (LoaiGD IN ('Deposit', 'Payment', 'Refund', 'DirectPayment')),
    SoTien              NUMERIC(12, 2)  NOT NULL
        CHECK (SoTien > 0),
    SoDuTruoc           NUMERIC(12, 2)  NOT NULL
        CHECK (SoDuTruoc >= 0),
    SoDuSau             NUMERIC(12, 2)  NOT NULL
        CHECK (SoDuSau >= 0),
    MaHD                VARCHAR(20)     REFERENCES HOA_DON(MaHD),
    MaGiaoDichDoiTac    VARCHAR(100)    UNIQUE,     -- Idempotency Key từ Cổng thanh toán
    ThoiGianGD          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    GhiChu              TEXT,

    -- Kiểm tra tính toán số dư trước/sau khớp với từng loại nghiệp vụ
    CONSTRAINT CHK_GiaoDich_SoDu CHECK (
        (LoaiGD = 'Deposit'         AND SoDuSau = SoDuTruoc + SoTien)
        OR (LoaiGD = 'Payment'      AND SoDuSau = SoDuTruoc - SoTien)
        OR (LoaiGD = 'Refund'       AND SoDuSau = SoDuTruoc + SoTien)
        OR (LoaiGD = 'DirectPayment' AND SoDuTruoc = SoDuSau)
    )
);

CREATE INDEX IDX_GiaoDichVi_MaKH ON GIAO_DICH_VI (MaKH);
CREATE INDEX IDX_GiaoDichVi_ThoiGian ON GIAO_DICH_VI (ThoiGianGD);
CREATE INDEX IDX_GiaoDichVi_MaHD ON GIAO_DICH_VI (MaHD);
