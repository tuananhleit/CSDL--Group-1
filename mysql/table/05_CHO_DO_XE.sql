SET NAMES utf8mb4;
USE smart_ev_parking;

CREATE TABLE CHO_DO_XE (
    MaCho           VARCHAR(20)     NOT NULL,
    MaTram          VARCHAR(20)     NOT NULL,
    MaViTri         VARCHAR(20)     NOT NULL,
    LoaiCho         VARCHAR(20)     NOT NULL DEFAULT 'CarSlot',
    MoTaViTri       VARCHAR(100)    NULL,
    TrangThaiCho    VARCHAR(20)     NOT NULL DEFAULT 'Available',

    PRIMARY KEY (MaCho),

    CONSTRAINT UQ_Tram_ViTri UNIQUE (MaTram, MaViTri),
    CONSTRAINT FK_ChoDoXe_Tram FOREIGN KEY (MaTram) REFERENCES TRAM (MaTram),
    CONSTRAINT CHK_ChoDoXe_LoaiCho   CHECK (LoaiCho IN ('CarSlot', 'MotorbikeSlot')),
    CONSTRAINT CHK_ChoDoXe_TrangThai CHECK (TrangThaiCho IN ('Available', 'Occupied', 'Reserved', 'Maintenance'))
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE INDEX IDX_ChoDoXe_Tram_TrangThai ON CHO_DO_XE (MaTram, TrangThaiCho);

INSERT INTO CHO_DO_XE (MaCho, MaTram, MaViTri, LoaiCho, MoTaViTri) VALUES
('CHO01', 'T01', 'A-01', 'CarSlot', 'Tang ham B1, gan thang may'),
('CHO02', 'T01', 'A-02', 'CarSlot', 'Tang ham B1, khu sac nhanh'),
('CHO03', 'T01', 'A-03', 'CarSlot', 'Tang ham B1, khu sac sieu nhanh'),
('CHO04', 'T01', 'A-04', 'CarSlot', 'Tang ham B1, khong co tru'),
('CHO05', 'T01', 'A-05', 'CarSlot', 'Tang ham B1, khong co tru'),
('CHO13', 'T01', 'M-01', 'MotorbikeSlot', 'Khu xe may, co o cam sac'),
('CHO06', 'T02', 'B-01', 'CarSlot', 'Tang ham B2'),
('CHO07', 'T02', 'B-02', 'CarSlot', 'Tang ham B2'),
('CHO08', 'T02', 'B-03', 'CarSlot', 'Tang ham B2, khu sac nhanh'),
('CHO09', 'T02', 'B-04', 'CarSlot', 'Tang ham B2, khong co tru'),
('CHO14', 'T02', 'M-01', 'MotorbikeSlot', 'Khu xe may, khong co tru'),
('CHO10', 'T03', 'C-01', 'CarSlot', 'Bai ngoai troi, khu sac nhanh'),
('CHO11', 'T03', 'C-02', 'CarSlot', 'Bai ngoai troi, khu sac sieu nhanh'),
('CHO12', 'T03', 'C-03', 'CarSlot', 'Bai ngoai troi, khong co tru');

INSERT INTO CHO_DO_XE (MaCho, MaTram, MaViTri, LoaiCho, MoTaViTri) VALUES
('CHO101', 'T04', 'A-01', 'CarSlot', 'Tang ham B1, khu sac AC 22 kW'),
('CHO102', 'T04', 'A-02', 'CarSlot', 'Tang ham B1, khu sac AC 22 kW'),
('CHO103', 'T04', 'A-03', 'CarSlot', 'Tang ham B1, khu sac AC 11 kW'),
('CHO104', 'T04', 'A-04', 'CarSlot', 'Tang ham B1, khu sac nhanh DC 50 kW'),
('CHO105', 'T04', 'A-05', 'CarSlot', 'Tang ham B1, khu sac nhanh DC 50 kW'),
('CHO106', 'T04', 'A-06', 'CarSlot', 'Tang ham B1, khu sac sieu nhanh DC 150 kW'),
('CHO107', 'T04', 'A-07', 'CarSlot', 'Tang ham B1, khong co tru'),
('CHO108', 'T04', 'A-08', 'CarSlot', 'Tang ham B1, khong co tru'),
('CHO109', 'T04', 'M-01', 'MotorbikeSlot', 'Khu xe may, co o cam sac'),
('CHO110', 'T04', 'M-02', 'MotorbikeSlot', 'Khu xe may, khong co tru'),
('CHO111', 'T05', 'A-01', 'CarSlot', 'Tang ham B1, khu sac AC 22 kW'),
('CHO112', 'T05', 'A-02', 'CarSlot', 'Tang ham B1, khu sac AC 22 kW'),
('CHO113', 'T05', 'A-03', 'CarSlot', 'Tang ham B1, khu sac AC 11 kW'),
('CHO114', 'T05', 'A-04', 'CarSlot', 'Tang ham B1, khu sac nhanh DC 50 kW'),
('CHO115', 'T05', 'A-05', 'CarSlot', 'Tang ham B1, khu sac nhanh DC 50 kW'),
('CHO116', 'T05', 'A-06', 'CarSlot', 'Tang ham B1, khu sac sieu nhanh DC 150 kW'),
('CHO117', 'T05', 'A-07', 'CarSlot', 'Tang ham B1, khong co tru'),
('CHO118', 'T05', 'A-08', 'CarSlot', 'Tang ham B1, khong co tru'),
('CHO119', 'T05', 'M-01', 'MotorbikeSlot', 'Khu xe may, co o cam sac'),
('CHO120', 'T05', 'M-02', 'MotorbikeSlot', 'Khu xe may, khong co tru'),
('CHO121', 'T06', 'A-01', 'CarSlot', 'Tang ham B1, khu sac AC 22 kW'),
('CHO122', 'T06', 'A-02', 'CarSlot', 'Tang ham B1, khu sac AC 22 kW'),
('CHO123', 'T06', 'A-03', 'CarSlot', 'Tang ham B1, khu sac AC 11 kW'),
('CHO124', 'T06', 'A-04', 'CarSlot', 'Tang ham B1, khu sac nhanh DC 50 kW'),
('CHO125', 'T06', 'A-05', 'CarSlot', 'Tang ham B1, khu sac nhanh DC 50 kW'),
('CHO126', 'T06', 'A-06', 'CarSlot', 'Tang ham B1, khu sac sieu nhanh DC 150 kW'),
('CHO127', 'T06', 'A-07', 'CarSlot', 'Tang ham B1, khong co tru'),
('CHO128', 'T06', 'A-08', 'CarSlot', 'Tang ham B1, khong co tru'),
('CHO129', 'T06', 'M-01', 'MotorbikeSlot', 'Khu xe may, co o cam sac'),
('CHO130', 'T06', 'M-02', 'MotorbikeSlot', 'Khu xe may, khong co tru'),
('CHO131', 'T07', 'A-01', 'CarSlot', 'Tang ham B1, khu sac AC 22 kW'),
('CHO132', 'T07', 'A-02', 'CarSlot', 'Tang ham B1, khu sac AC 22 kW'),
('CHO133', 'T07', 'A-03', 'CarSlot', 'Tang ham B1, khu sac AC 11 kW'),
('CHO134', 'T07', 'A-04', 'CarSlot', 'Tang ham B1, khu sac nhanh DC 50 kW'),
('CHO135', 'T07', 'A-05', 'CarSlot', 'Tang ham B1, khu sac nhanh DC 50 kW'),
('CHO136', 'T07', 'A-06', 'CarSlot', 'Tang ham B1, khu sac sieu nhanh DC 150 kW'),
('CHO137', 'T07', 'A-07', 'CarSlot', 'Tang ham B1, khong co tru'),
('CHO138', 'T07', 'A-08', 'CarSlot', 'Tang ham B1, khong co tru'),
('CHO139', 'T07', 'M-01', 'MotorbikeSlot', 'Khu xe may, co o cam sac'),
('CHO140', 'T07', 'M-02', 'MotorbikeSlot', 'Khu xe may, khong co tru'),
('CHO141', 'T08', 'A-01', 'CarSlot', 'Tang ham B1, khu sac AC 22 kW'),
('CHO142', 'T08', 'A-02', 'CarSlot', 'Tang ham B1, khu sac AC 22 kW'),
('CHO143', 'T08', 'A-03', 'CarSlot', 'Tang ham B1, khu sac AC 11 kW'),
('CHO144', 'T08', 'A-04', 'CarSlot', 'Tang ham B1, khu sac nhanh DC 50 kW'),
('CHO145', 'T08', 'A-05', 'CarSlot', 'Tang ham B1, khu sac nhanh DC 50 kW'),
('CHO146', 'T08', 'A-06', 'CarSlot', 'Tang ham B1, khu sac sieu nhanh DC 150 kW'),
('CHO147', 'T08', 'A-07', 'CarSlot', 'Tang ham B1, khong co tru'),
('CHO148', 'T08', 'A-08', 'CarSlot', 'Tang ham B1, khong co tru'),
('CHO149', 'T08', 'M-01', 'MotorbikeSlot', 'Khu xe may, co o cam sac'),
('CHO150', 'T08', 'M-02', 'MotorbikeSlot', 'Khu xe may, khong co tru'),
('CHO151', 'T09', 'A-01', 'CarSlot', 'Tang ham B1, khu sac AC 22 kW'),
('CHO152', 'T09', 'A-02', 'CarSlot', 'Tang ham B1, khu sac AC 22 kW'),
('CHO153', 'T09', 'A-03', 'CarSlot', 'Tang ham B1, khu sac AC 11 kW'),
('CHO154', 'T09', 'A-04', 'CarSlot', 'Tang ham B1, khu sac nhanh DC 50 kW'),
('CHO155', 'T09', 'A-05', 'CarSlot', 'Tang ham B1, khu sac nhanh DC 50 kW'),
('CHO156', 'T09', 'A-06', 'CarSlot', 'Tang ham B1, khu sac sieu nhanh DC 150 kW'),
('CHO157', 'T09', 'A-07', 'CarSlot', 'Tang ham B1, khong co tru'),
('CHO158', 'T09', 'A-08', 'CarSlot', 'Tang ham B1, khong co tru'),
('CHO159', 'T09', 'M-01', 'MotorbikeSlot', 'Khu xe may, co o cam sac'),
('CHO160', 'T09', 'M-02', 'MotorbikeSlot', 'Khu xe may, khong co tru');

UPDATE CHO_DO_XE SET TrangThaiCho = 'Occupied'    WHERE MaCho IN ('CHO01', 'CHO02', 'CHO03', 'CHO04');
UPDATE CHO_DO_XE SET TrangThaiCho = 'Reserved'    WHERE MaCho = 'CHO08';
UPDATE CHO_DO_XE SET TrangThaiCho = 'Maintenance' WHERE MaCho = 'CHO12';
