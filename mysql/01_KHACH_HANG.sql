-- =============================================================================
-- TABLE 01: KHACH_HANG (Customer)
-- =============================================================================
-- Mô tả: Quản lý khách hàng cá nhân (B2C) và khách vãng lai (Walk-in).
--        Thân thiện với người dùng: KHÔNG giam cọc lớn, hỗ trợ sạc theo số dư
--        hoặc thanh toán linh hoạt qua ví / ngân hàng.
-- Dependencies: Không phụ thuộc bảng nào
-- =============================================================================

CREATE TABLE KHACH_HANG (
    MaKH            VARCHAR(20)     PRIMARY KEY,
    HoTen           VARCHAR(100)    NOT NULL DEFAULT 'Khách Vãng Lai',
    SDT             VARCHAR(15)     UNIQUE,
    Email           VARCHAR(100)    UNIQUE,
    LoaiKhach       VARCHAR(20)     NOT NULL DEFAULT 'Registered'
        CHECK (LoaiKhach IN ('Registered', 'WalkIn')),
    SoDuViDienTu    NUMERIC(12, 2)  NOT NULL DEFAULT 0.00
        CHECK (SoDuViDienTu >= 0),
    TrangThaiTK     VARCHAR(20)     NOT NULL DEFAULT 'Active'
        CHECK (TrangThaiTK IN ('Active', 'Locked')),
    NgayDangKy      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Khách Registered bắt buộc có SDT hoặc Email để nhận hóa đơn và thông báo
    CONSTRAINT CHK_KhachHang_Reg CHECK (
        (LoaiKhach = 'Registered' AND (SDT IS NOT NULL OR Email IS NOT NULL))
        OR (LoaiKhach = 'WalkIn')
    )
);

CREATE INDEX IDX_KhachHang_SDT ON KHACH_HANG (SDT);
CREATE INDEX IDX_KhachHang_LoaiKhach ON KHACH_HANG (LoaiKhach);
