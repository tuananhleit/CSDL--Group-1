SET NAMES utf8mb4;
USE smart_ev_parking;

CREATE TABLE QUAN_TRI_VIEN (
    MaQTV   VARCHAR(20)     NOT NULL,
    HoTen   VARCHAR(100)    NOT NULL,
    Email   VARCHAR(100)    NOT NULL,
    VaiTro  VARCHAR(50)     NOT NULL DEFAULT 'Operator',

    PRIMARY KEY (MaQTV),
    UNIQUE KEY UQ_QuanTriVien_Email (Email)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

INSERT INTO QUAN_TRI_VIEN (MaQTV, HoTen, Email, VaiTro) VALUES
('QTV01', 'Nguyen Van An', 'an.nguyen@smartcity.vn', 'Operator'),
('QTV02', 'Tran Thi Binh', 'binh.tran@smartcity.vn', 'Operator'),
('QTV03', 'Le Hoang Cuong', 'cuong.le@smartcity.vn', 'SysAdmin');
