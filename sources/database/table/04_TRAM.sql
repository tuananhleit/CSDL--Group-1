SET NAMES utf8mb4;
USE smart_ev_parking;

CREATE TABLE TRAM (
    MaTram          VARCHAR(20)     NOT NULL,
    TenTram         VARCHAR(100)    NOT NULL,
    DiaChi          TEXT            NOT NULL,
    ViDo            DECIMAL(9, 6)   NULL,
    KinhDo          DECIMAL(9, 6)   NULL,
    PhutAnHanSauSac INT             NOT NULL DEFAULT 15,
    SoDuToiThieu    DECIMAL(12, 2)  NOT NULL DEFAULT 20000.00,
    MaQTV           VARCHAR(20)     NULL,

    PRIMARY KEY (MaTram),
    CONSTRAINT FK_Tram_QuanTriVien FOREIGN KEY (MaQTV) REFERENCES QUAN_TRI_VIEN (MaQTV),
    CONSTRAINT CHK_Tram_AnHan      CHECK (PhutAnHanSauSac >= 0),
    CONSTRAINT CHK_Tram_SoDuToiThieu CHECK (SoDuToiThieu >= 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

INSERT INTO TRAM (MaTram, TenTram, DiaChi, ViDo, KinhDo, PhutAnHanSauSac, SoDuToiThieu, MaQTV) VALUES
('T01', 'Tram Vincom Thu Duc', '216 Vo Van Ngan, TP Thu Duc, TP.HCM', 10.85, 106.765, 15, 20000, 'QTV01'),
('T02', 'Tram Landmark 81', '720A Dien Bien Phu, Binh Thanh, TP.HCM', 10.795, 106.722, 15, 20000, 'QTV01'),
('T03', 'Tram San bay Tan Son Nhat', 'Truong Son, Tan Binh, TP.HCM', 10.818, 106.659, 10, 50000, 'QTV02');

INSERT INTO TRAM (MaTram, TenTram, DiaChi, ViDo, KinhDo, PhutAnHanSauSac, SoDuToiThieu, MaQTV) VALUES
('T04', 'Tram Aeon Binh Tan', '1 Duong so 17A, Binh Tan, TP.HCM', 10.7415, 106.6135, 15, 20000, 'QTV01'),
('T05', 'Tram Crescent Mall', '101 Ton Dat Tien, Quan 7, TP.HCM', 10.729, 106.721, 15, 20000, 'QTV02'),
('T06', 'Tram Bitexco', '2 Hai Trieu, Quan 1, TP.HCM', 10.7716, 106.7044, 15, 20000, 'QTV01'),
('T07', 'Tram Sala Thu Thiem', 'Duong Mai Chi Tho, TP Thu Duc, TP.HCM', 10.7712, 106.723, 15, 20000, 'QTV02'),
('T08', 'Tram Dai hoc Bach Khoa', '268 Ly Thuong Kiet, Quan 10, TP.HCM', 10.7721, 106.6602, 15, 20000, 'QTV01'),
('T09', 'Tram Giga Mall Thu Duc', '240 Pham Van Dong, TP Thu Duc, TP.HCM', 10.8271, 106.721, 15, 20000, 'QTV02');
