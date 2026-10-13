-- =============================================================================
-- TABLE 04: TRAM (Station)
-- =============================================================================
-- Mô tả: Cấu hình trạm sạc & bãi đỗ xe:
--        Ngưỡng mở phiên thân thiện (chỉ từ 20.000đ), thời gian ân hạn miễn phí.
-- Dependencies: QUAN_TRI_VIEN
-- =============================================================================

CREATE TABLE TRAM (
    MaTram          VARCHAR(20)     PRIMARY KEY,
    TenTram         VARCHAR(100)    NOT NULL,
    DiaChi          TEXT            NOT NULL,
    ViDo            NUMERIC(9, 6),
    KinhDo          NUMERIC(9, 6),
    PhutAnHanSauSac INT             NOT NULL DEFAULT 15
        CHECK (PhutAnHanSauSac >= 0),
    SoDuToiThieu    NUMERIC(12, 2)  NOT NULL DEFAULT 20000.00
        CHECK (SoDuToiThieu >= 0),
    MaQTV           VARCHAR(20)     REFERENCES QUAN_TRI_VIEN(MaQTV)
);
