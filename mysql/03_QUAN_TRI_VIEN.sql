-- =============================================================================
-- TABLE 03: QUAN_TRI_VIEN (Admin)
-- =============================================================================
-- Mô tả: Lưu thông tin quản trị viên phụ trách trạm
-- Dependencies: Không phụ thuộc bảng nào
-- =============================================================================

CREATE TABLE QUAN_TRI_VIEN (
    MaQTV   VARCHAR(20)     PRIMARY KEY,
    HoTen   VARCHAR(100)    NOT NULL,
    Email   VARCHAR(100)    NOT NULL UNIQUE,
    VaiTro  VARCHAR(50)     NOT NULL DEFAULT 'Operator'
);
