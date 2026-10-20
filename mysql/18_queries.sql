SET NAMES utf8mb4;
USE smart_ev_parking;

SELECT  p.MaPhien, kh.HoTen, kh.LoaiKhach, pt.BienSo, t.TenTram, c.MaViTri,
        p.LoaiPhien, p.ThoiGianVao, p.ThoiGianRa,
        hd.TongTien, hd.PhuongThucThanhToan, hd.TrangThaiThanhToan
FROM PHIEN p
JOIN PHUONG_TIEN pt ON pt.MaXe    = p.MaXe
JOIN KHACH_HANG  kh ON kh.MaKH    = pt.MaKH
JOIN CHO_DO_XE   c  ON c.MaCho    = p.MaCho
JOIN TRAM        t  ON t.MaTram   = c.MaTram
JOIN HOA_DON     hd ON hd.MaPhien = p.MaPhien
WHERE p.TrangThaiPhien = 'Completed'
ORDER BY p.ThoiGianVao DESC;

SELECT  t.MaTram, t.TenTram,
        COUNT(DISTINCT p.MaPhien)           AS SoPhienHoanTat,
        COALESCE(SUM(hd.PhiDoXe), 0)        AS PhiDoXe,
        COALESCE(SUM(hd.PhiSacDien), 0)     AS PhiSacDien,
        COALESCE(SUM(hd.PhiDoSauSac), 0)    AS PhiDoSauSac,
        COALESCE(SUM(hd.TienKhauTru), 0)    AS TienKhauTru,
        COALESCE(SUM(hd.TongTien), 0)       AS DoanhThuThucThu
FROM TRAM t
LEFT JOIN CHO_DO_XE c ON c.MaTram = t.MaTram
LEFT JOIN PHIEN p     ON p.MaCho = c.MaCho
                     AND p.TrangThaiPhien = 'Completed'
                     AND p.ThoiGianVao >= DATE '2026-10-01'
                     AND p.ThoiGianVao <  DATE '2026-11-01'
LEFT JOIN HOA_DON hd  ON hd.MaPhien = p.MaPhien
                     AND hd.TrangThaiThanhToan = 'Paid'
GROUP BY t.MaTram, t.TenTram
ORDER BY DoanhThuThucThu DESC;

SELECT  kh.MaKH, kh.HoTen,
        COUNT(hd.MaHD)      AS SoHoaDonDaTra,
        SUM(hd.TongTien)    AS TongChiTieu,
        MAX(hd.TongTien)    AS HoaDonLonNhat
FROM KHACH_HANG kh
JOIN PHUONG_TIEN pt ON pt.MaKH    = kh.MaKH
JOIN PHIEN p        ON p.MaXe     = pt.MaXe
JOIN HOA_DON hd     ON hd.MaPhien = p.MaPhien
WHERE hd.TrangThaiThanhToan = 'Paid'
GROUP BY kh.MaKH, kh.HoTen
HAVING SUM(hd.TongTien) >= 250000
ORDER BY TongChiTieu DESC;

SELECT  hd.MaHD, hd.MaPhien, pt.BienSo, hd.TongTien,
        (SELECT ROUND(AVG(TongTien), 0) FROM HOA_DON) AS TrungBinhHeThong
FROM HOA_DON hd
JOIN PHIEN p        ON p.MaPhien = hd.MaPhien
JOIN PHUONG_TIEN pt ON pt.MaXe   = p.MaXe
WHERE hd.TongTien > (SELECT AVG(TongTien) FROM HOA_DON)
ORDER BY hd.TongTien DESC;

SELECT  pt.MaXe, pt.BienSo, pt.LoaiXe, pt.ChuanSac, pt.BiDenKhoa, kh.HoTen, kh.TrangThaiTK
FROM PHUONG_TIEN pt
JOIN KHACH_HANG kh ON kh.MaKH = pt.MaKH
WHERE NOT EXISTS (SELECT 1 FROM PHIEN p WHERE p.MaXe = pt.MaXe);

SELECT  ts.MaTru, t.TenTram, c.MaViTri, lt.TenLoai, lt.ChuanKetNoi, ts.TrangThaiTru
FROM TRU_SAC ts
JOIN CHO_DO_XE c     ON c.MaCho = ts.MaCho
JOIN TRAM t          ON t.MaTram = c.MaTram
JOIN LOAI_TRU_SAC lt ON lt.MaLoaiTru = ts.MaLoaiTru
WHERE ts.MaTru NOT IN (SELECT cts.MaTru FROM CHI_TIET_PHIEN_SAC cts);

SELECT  lt.MaLoaiTru, lt.TenLoai, lt.DongDien,
        COUNT(*)                      AS SoPhienSac,
        SUM(cts.SoKWh)                AS TongKWh,
        ROUND(AVG(cts.SoKWh), 2)      AS KWhTrungBinh,
        ROUND(AVG(TIMESTAMPDIFF(SECOND, cts.ThoiGianBatDauSac, cts.ThoiGianKetThucSac) / 60), 1)
                                      AS PhutSacTrungBinh,
        SUM(CASE WHEN cts.LyDoKetThuc LIKE 'AutoCutoff%' THEN 1 ELSE 0 END) AS SoLanTuNgat
FROM CHI_TIET_PHIEN_SAC cts
JOIN TRU_SAC ts      ON ts.MaTru     = cts.MaTru
JOIN LOAI_TRU_SAC lt ON lt.MaLoaiTru = ts.MaLoaiTru
WHERE cts.ThoiGianKetThucSac IS NOT NULL
GROUP BY lt.MaLoaiTru, lt.TenLoai, lt.DongDien
ORDER BY TongKWh DESC;

WITH chi_tieu AS (
    SELECT  t.MaTram, t.TenTram, kh.MaKH, kh.HoTen,
            SUM(hd.TongTien) AS TongChiTieu
    FROM HOA_DON hd
    JOIN PHIEN p        ON p.MaPhien = hd.MaPhien
    JOIN CHO_DO_XE c    ON c.MaCho   = p.MaCho
    JOIN TRAM t         ON t.MaTram  = c.MaTram
    JOIN PHUONG_TIEN pt ON pt.MaXe   = p.MaXe
    JOIN KHACH_HANG kh  ON kh.MaKH   = pt.MaKH
    WHERE hd.TrangThaiThanhToan = 'Paid'
    GROUP BY t.MaTram, t.TenTram, kh.MaKH, kh.HoTen
),
xep_hang AS (
    SELECT  chi_tieu.*,
            RANK() OVER (PARTITION BY MaTram ORDER BY TongChiTieu DESC) AS Hang
    FROM chi_tieu
)
SELECT MaTram, TenTram, MaKH, HoTen, TongChiTieu
FROM xep_hang
WHERE Hang = 1
ORDER BY MaTram;

SELECT  ctp.KhoanMuc,
        COALESCE(bg.LoaiCho, 'Tru sac')                                 AS LoaiCho,
        CASE WHEN bg.LaCaoDiem THEN 'Cao diem' ELSE 'Thap diem' END     AS KhungGio,
        bg.DonGiaTheoPhut   AS DonGiaTheoPhut,
        COUNT(*)            AS SoDongPhi,
        SUM(ctp.SoPhut)     AS TongPhut,
        SUM(ctp.SoTien)     AS TongTien
FROM CHI_TIET_PHI ctp
JOIN BANG_GIA bg ON bg.MaBangGia = ctp.MaBangGia
GROUP BY ctp.KhoanMuc, bg.LoaiCho, bg.LaCaoDiem, bg.DonGiaTheoPhut
ORDER BY ctp.KhoanMuc, LoaiCho, bg.LaCaoDiem DESC, bg.DonGiaTheoPhut;

SELECT  hd.MaHD, hd.MaPhien,
        hd.PhiDoXe,     ct.TongDoXe,
        hd.PhiSacDien,  ct.TongSac,
        hd.PhiDoSauSac, ct.TongDoSauSac
FROM HOA_DON hd
LEFT JOIN (
    SELECT  MaPhien,
            COALESCE(SUM(CASE WHEN KhoanMuc = 'Parking' THEN SoTien END), 0) AS TongDoXe,
            COALESCE(SUM(CASE WHEN KhoanMuc = 'Charging' THEN SoTien END), 0) AS TongSac,
            COALESCE(SUM(CASE WHEN KhoanMuc = 'PostCharging' THEN SoTien END), 0) AS TongDoSauSac
    FROM CHI_TIET_PHI
    GROUP BY MaPhien
) ct ON ct.MaPhien = hd.MaPhien
WHERE hd.PhiDoXe     <> COALESCE(ct.TongDoXe, 0)
   OR hd.PhiSacDien  <> COALESCE(ct.TongSac, 0)
   OR hd.PhiDoSauSac <> COALESCE(ct.TongDoSauSac, 0);

SELECT *
FROM (
    SELECT  g.MaGD, g.MaKH, g.ThoiGianGD, g.SoDuTruoc,
            LAG(g.SoDuSau) OVER (PARTITION BY g.MaKH ORDER BY g.ThoiGianGD, g.MaGD) AS SoDuSauGiaoDichTruoc
    FROM GIAO_DICH_VI g
) x
WHERE x.SoDuSauGiaoDichTruoc IS NOT NULL
  AND x.SoDuTruoc <> x.SoDuSauGiaoDichTruoc;

SELECT  kh.MaKH, kh.HoTen, kh.SoDuViDienTu, g.SoDuSau AS SoDuSauGiaoDichCuoi
FROM KHACH_HANG kh
JOIN GIAO_DICH_VI g ON g.MaKH = kh.MaKH
WHERE g.ThoiGianGD = (SELECT MAX(g2.ThoiGianGD) FROM GIAO_DICH_VI g2 WHERE g2.MaKH = kh.MaKH)
  AND kh.SoDuViDienTu <> g.SoDuSau;

SELECT  p.MaPhien, pt.BienSo, kh.HoTen, kh.SDT,
        t.TenTram, c.MaViTri,
        cts.ThoiGianKetThucSac, cts.ThoiGianHetAnHan,
        CASE WHEN CURRENT_TIMESTAMP >= cts.ThoiGianHetAnHan
             THEN 'DA QUA AN HAN' ELSE 'Dang trong an han' END AS TinhTrang,
        ROUND(GREATEST(TIMESTAMPDIFF(SECOND, cts.ThoiGianHetAnHan, CURRENT_TIMESTAMP) / 60, 0), 0) AS SoPhutQuaAnHan
FROM PHIEN p
JOIN CHI_TIET_PHIEN_SAC cts ON cts.MaPhien = p.MaPhien
JOIN PHUONG_TIEN pt         ON pt.MaXe     = p.MaXe
JOIN KHACH_HANG kh          ON kh.MaKH     = pt.MaKH
JOIN CHO_DO_XE c            ON c.MaCho     = p.MaCho
JOIN TRAM t                 ON t.MaTram    = c.MaTram
WHERE p.TrangThaiPhien = 'Active'
  AND cts.ThoiGianKetThucSac IS NOT NULL
ORDER BY SoPhutQuaAnHan DESC;

SELECT  hd.MaHD, hd.TrangThaiThanhToan, hd.TongTien, g.MaGD, g.LoaiGD, g.SoTien
FROM HOA_DON hd
LEFT JOIN GIAO_DICH_VI g ON g.MaHD = hd.MaHD
                        AND g.LoaiGD IN ('Payment', 'DirectPayment')
WHERE hd.TrangThaiThanhToan IN ('Paid', 'Refunded')
  AND (g.MaGD IS NULL OR g.SoTien <> hd.TongTien);
