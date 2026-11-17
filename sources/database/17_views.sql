SET NAMES utf8mb4;
USE smart_ev_parking;

CREATE OR REPLACE VIEW VW_CHO_DO_TRONG AS
SELECT  t.MaTram, t.TenTram, c.MaCho, c.MaViTri, c.LoaiCho, c.MoTaViTri,
        ts.MaTru, lt.TenLoai AS LoaiTru, lt.ChuanKetNoi, lt.CongSuat_kW,
        CASE
            WHEN ts.MaTru IS NULL                              THEN 'Khong co tru sac'
            WHEN ts.TrangThaiTru IN ('Faulted', 'Maintenance') THEN 'Tru khong kha dung'
            ELSE 'San sang sac'
        END AS TinhTrangSac
FROM CHO_DO_XE c
JOIN TRAM t               ON t.MaTram = c.MaTram
LEFT JOIN TRU_SAC ts      ON ts.MaCho = c.MaCho
LEFT JOIN LOAI_TRU_SAC lt ON lt.MaLoaiTru = ts.MaLoaiTru
WHERE c.TrangThaiCho = 'Available';

CREATE OR REPLACE VIEW VW_DOANH_THU_TRAM_THANG AS
SELECT  t.MaTram, t.TenTram,
        CAST(DATE_FORMAT(hd.NgayThanhToan, '%Y-%m-01') AS DATE) AS Thang,
        COUNT(*)                AS SoHoaDon,
        SUM(hd.PhiDoXe)         AS PhiDoXe,
        SUM(hd.PhiSacDien)      AS PhiSacDien,
        SUM(hd.PhiDoSauSac)     AS PhiDoSauSac,
        SUM(hd.TienKhauTru)     AS TienKhauTru,
        SUM(hd.TongTien)        AS DoanhThuThucThu
FROM HOA_DON hd
JOIN PHIEN p     ON p.MaPhien = hd.MaPhien
JOIN CHO_DO_XE c ON c.MaCho   = p.MaCho
JOIN TRAM t      ON t.MaTram  = c.MaTram
WHERE hd.TrangThaiThanhToan = 'Paid'
GROUP BY t.MaTram, t.TenTram, CAST(DATE_FORMAT(hd.NgayThanhToan, '%Y-%m-01') AS DATE);

SELECT * FROM VW_CHO_DO_TRONG ORDER BY MaTram, MaViTri;
SELECT * FROM VW_DOANH_THU_TRAM_THANG ORDER BY Thang, MaTram;
