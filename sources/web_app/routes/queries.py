from flask import Blueprint, render_template, request
from db import test_connection, query_all
from security import admin_required
import time

queries_bp = Blueprint("queries", __name__)

QUERIES_DICT = {
    "Q1": {
        "title": "Q1 — [JOIN 6 bảng] Các phiên đã hoàn tất kèm thông tin chi tiết",
        "sql": """SELECT p.MaPhien, kh.HoTen, kh.LoaiKhach, pt.BienSo, t.TenTram, c.MaViTri,
       p.LoaiPhien, p.ThoiGianVao, p.ThoiGianRa,
       hd.TongTien, hd.PhuongThucThanhToan, hd.TrangThaiThanhToan
FROM PHIEN p
JOIN PHUONG_TIEN pt ON pt.MaXe = p.MaXe
JOIN KHACH_HANG kh ON kh.MaKH = pt.MaKH
JOIN CHO_DO_XE c ON c.MaCho = p.MaCho
JOIN TRAM t ON t.MaTram = c.MaTram
JOIN HOA_DON hd ON hd.MaPhien = p.MaPhien
WHERE p.TrangThaiPhien = 'Completed'
ORDER BY p.ThoiGianVao DESC
LIMIT 50;"""
    },
    "Q2": {
        "title": "Q2 — [LEFT JOIN + GROUP BY] Doanh thu thực thu theo trạm, tháng 10/2026",
        "sql": """SELECT t.MaTram, t.TenTram,
       COUNT(DISTINCT p.MaPhien) AS SoPhienHoanTat,
       COALESCE(SUM(hd.PhiDoXe), 0) AS PhiDoXe,
       COALESCE(SUM(hd.PhiSacDien), 0) AS PhiSacDien,
       COALESCE(SUM(hd.PhiDoSauSac), 0) AS PhiDoSauSac,
       COALESCE(SUM(hd.TienKhauTru), 0) AS TienKhauTru,
       COALESCE(SUM(hd.TongTien), 0) AS DoanhThuThucThu
FROM TRAM t
LEFT JOIN CHO_DO_XE c ON c.MaTram = t.MaTram
LEFT JOIN PHIEN p ON p.MaCho = c.MaCho
                 AND p.TrangThaiPhien = 'Completed'
                 AND p.ThoiGianVao >= DATE '2026-10-01'
                 AND p.ThoiGianVao < DATE '2026-11-01'
LEFT JOIN HOA_DON hd ON hd.MaPhien = p.MaPhien AND hd.TrangThaiThanhToan = 'Paid'
GROUP BY t.MaTram, t.TenTram
ORDER BY DoanhThuThucThu DESC;"""
    },
    "Q3": {
        "title": "Q3 — [GROUP BY + HAVING] Khách hàng đã chi tiêu từ 250.000đ trở lên",
        "sql": """SELECT kh.MaKH, kh.HoTen,
       COUNT(hd.MaHD) AS SoHoaDonDaTra,
       SUM(hd.TongTien) AS TongChiTieu,
       MAX(hd.TongTien) AS HoaDonLonNhat
FROM KHACH_HANG kh
JOIN PHUONG_TIEN pt ON pt.MaKH = kh.MaKH
JOIN PHIEN p ON p.MaXe = pt.MaXe
JOIN HOA_DON hd ON hd.MaPhien = p.MaPhien
WHERE hd.TrangThaiThanhToan = 'Paid'
GROUP BY kh.MaKH, kh.HoTen
HAVING SUM(hd.TongTien) >= 250000
ORDER BY TongChiTieu DESC
LIMIT 50;"""
    },
    "Q4": {
        "title": "Q4 — [SUBQUERY vô hướng] Hóa đơn có tổng tiền cao hơn mức trung bình hệ thống",
        "sql": """SELECT hd.MaHD, hd.MaPhien, pt.BienSo, hd.TongTien,
       (SELECT ROUND(AVG(TongTien), 0) FROM HOA_DON) AS TrungBinhHeThong
FROM HOA_DON hd
JOIN PHIEN p ON p.MaPhien = hd.MaPhien
JOIN PHUONG_TIEN pt ON pt.MaXe = p.MaXe
WHERE hd.TongTien > (SELECT AVG(TongTien) FROM HOA_DON)
ORDER BY hd.TongTien DESC
LIMIT 50;"""
    },
    "Q5": {
        "title": "Q5 — [NOT EXISTS] Phương tiện đã đăng ký nhưng chưa từng mở phiên",
        "sql": """SELECT pt.MaXe, pt.BienSo, pt.LoaiXe, pt.ChuanSac, pt.BiDenKhoa, kh.HoTen, kh.TrangThaiTK
FROM PHUONG_TIEN pt
JOIN KHACH_HANG kh ON kh.MaKH = pt.MaKH
WHERE NOT EXISTS (SELECT 1 FROM PHIEN p WHERE p.MaXe = pt.MaXe)
LIMIT 50;"""
    },
    "Q6": {
        "title": "Q6 — [NOT IN] Trụ sạc chưa từng được sử dụng để sạc điện",
        "sql": """SELECT ts.MaTru, t.TenTram, c.MaViTri, lt.TenLoai, lt.ChuanKetNoi, ts.TrangThaiTru
FROM TRU_SAC ts
JOIN CHO_DO_XE c ON c.MaCho = ts.MaCho
JOIN TRAM t ON t.MaTram = c.MaTram
JOIN LOAI_TRU_SAC lt ON lt.MaLoaiTru = ts.MaLoaiTru
WHERE ts.MaTru NOT IN (SELECT cts.MaTru FROM CHI_TIET_PHIEN_SAC cts);"""
    },
    "Q7": {
        "title": "Q7 — [JOIN + AGGREGATION] Sản lượng điện và thời gian sạc trung bình theo loại trụ",
        "sql": """SELECT lt.MaLoaiTru, lt.TenLoai, lt.DongDien,
       COUNT(*) AS SoPhienSac,
       SUM(cts.SoKWh) AS TongKWh,
       ROUND(AVG(cts.SoKWh), 2) AS KWhTrungBinh,
       ROUND(AVG(TIMESTAMPDIFF(SECOND, cts.ThoiGianBatDauSac, cts.ThoiGianKetThucSac) / 60), 1) AS PhutSacTrungBinh,
       SUM(CASE WHEN cts.LyDoKetThuc LIKE 'AutoCutoff%' THEN 1 ELSE 0 END) AS SoLanTuNgat
FROM CHI_TIET_PHIEN_SAC cts
JOIN TRU_SAC ts ON ts.MaTru = cts.MaTru
JOIN LOAI_TRU_SAC lt ON lt.MaLoaiTru = ts.MaLoaiTru
WHERE cts.ThoiGianKetThucSac IS NOT NULL
GROUP BY lt.MaLoaiTru, lt.TenLoai, lt.DongDien
ORDER BY TongKWh DESC;"""
    },
    "Q8": {
        "title": "Q8 — [CTE + WINDOW FUNCTION RANK] Khách hàng chi tiêu nhiều nhất tại mỗi trạm",
        "sql": """WITH chi_tieu AS (
    SELECT t.MaTram, t.TenTram, kh.MaKH, kh.HoTen,
           SUM(hd.TongTien) AS TongChiTieu
    FROM HOA_DON hd
    JOIN PHIEN p ON p.MaPhien = hd.MaPhien
    JOIN CHO_DO_XE c ON c.MaCho = p.MaCho
    JOIN TRAM t ON t.MaTram = c.MaTram
    JOIN PHUONG_TIEN pt ON pt.MaXe = p.MaXe
    JOIN KHACH_HANG kh ON kh.MaKH = pt.MaKH
    WHERE hd.TrangThaiThanhToan = 'Paid'
    GROUP BY t.MaTram, t.TenTram, kh.MaKH, kh.HoTen
),
xep_hang AS (
    SELECT chi_tieu.*,
           RANK() OVER (PARTITION BY MaTram ORDER BY TongChiTieu DESC) AS Hang
    FROM chi_tieu
)
SELECT MaTram, TenTram, MaKH, HoTen, TongChiTieu
FROM xep_hang
WHERE Hang = 1
ORDER BY MaTram;"""
    },
    "Q9": {
        "title": "Q9 — [JOIN + GROUP BY] Doanh thu theo khoản mục, loại chỗ và khung giờ",
        "sql": """SELECT ctp.KhoanMuc,
       COALESCE(bg.LoaiCho, 'Tru sac') AS LoaiCho,
       CASE WHEN bg.LaCaoDiem THEN 'Cao diem' ELSE 'Thap diem' END AS KhungGio,
       bg.DonGiaTheoPhut AS DonGiaTheoPhut,
       COUNT(*) AS SoDongPhi,
       SUM(ctp.SoPhut) AS TongPhut,
       SUM(ctp.SoTien) AS TongTien
FROM CHI_TIET_PHI ctp
JOIN BANG_GIA bg ON bg.MaBangGia = ctp.MaBangGia
GROUP BY ctp.KhoanMuc, bg.LoaiCho, bg.LaCaoDiem, bg.DonGiaTheoPhut
ORDER BY ctp.KhoanMuc, LoaiCho, bg.LaCaoDiem DESC, bg.DonGiaTheoPhut;"""
    },
    "Q10": {
        "title": "Q10 — [DERIVED TABLE] Đối chiếu hóa đơn với chi tiết phí (Kỳ vọng: 0 dòng)",
        "sql": """SELECT hd.MaHD, hd.MaPhien,
       hd.PhiDoXe, ct.TongDoXe,
       hd.PhiSacDien, ct.TongSac,
       hd.PhiDoSauSac, ct.TongDoSauSac
FROM HOA_DON hd
LEFT JOIN (
    SELECT MaPhien,
           COALESCE(SUM(CASE WHEN KhoanMuc = 'Parking' THEN SoTien END), 0) AS TongDoXe,
           COALESCE(SUM(CASE WHEN KhoanMuc = 'Charging' THEN SoTien END), 0) AS TongSac,
           COALESCE(SUM(CASE WHEN KhoanMuc = 'PostCharging' THEN SoTien END), 0) AS TongDoSauSac
    FROM CHI_TIET_PHI
    GROUP BY MaPhien
) ct ON ct.MaPhien = hd.MaPhien
WHERE hd.PhiDoXe <> COALESCE(ct.TongDoXe, 0)
   OR hd.PhiSacDien <> COALESCE(ct.TongSac, 0)
   OR hd.PhiDoSauSac <> COALESCE(ct.TongDoSauSac, 0);"""
    },
    "Q11": {
        "title": "Q11 — [WINDOW FUNCTION LAG] Đối chiếu sổ cái ví điện tử (Kỳ vọng: 0 dòng)",
        "sql": """SELECT *
FROM (
    SELECT g.MaGD, g.MaKH, g.ThoiGianGD, g.SoDuTruoc,
           LAG(g.SoDuSau) OVER (PARTITION BY g.MaKH ORDER BY g.ThoiGianGD, g.MaGD) AS SoDuSauGiaoDichTruoc
    FROM GIAO_DICH_VI g
) x
WHERE x.SoDuSauGiaoDichTruoc IS NOT NULL
  AND x.SoDuTruoc <> x.SoDuSauGiaoDichTruoc;"""
    },
    "Q12": {
        "title": "Q12 — [MULTI-JOIN + GREATEST] Xe đã sạc xong nhưng vẫn chiếm chỗ",
        "sql": """SELECT p.MaPhien, pt.BienSo, kh.HoTen, kh.SDT,
       t.TenTram, c.MaViTri,
       cts.ThoiGianKetThucSac, cts.ThoiGianHetAnHan,
       CASE WHEN CURRENT_TIMESTAMP >= cts.ThoiGianHetAnHan THEN 'DA QUA AN HAN' ELSE 'Dang trong an han' END AS TinhTrang,
       ROUND(GREATEST(TIMESTAMPDIFF(SECOND, cts.ThoiGianHetAnHan, CURRENT_TIMESTAMP) / 60, 0), 0) AS SoPhutQuaAnHan
FROM PHIEN p
JOIN CHI_TIET_PHIEN_SAC cts ON cts.MaPhien = p.MaPhien
JOIN PHUONG_TIEN pt ON pt.MaXe = p.MaXe
JOIN KHACH_HANG kh ON kh.MaKH = pt.MaKH
JOIN CHO_DO_XE c ON c.MaCho = p.MaCho
JOIN TRAM t ON t.MaTram = c.MaTram
WHERE p.TrangThaiPhien = 'Active' AND cts.ThoiGianKetThucSac IS NOT NULL
ORDER BY SoPhutQuaAnHan DESC;"""
    },
    "Q13": {
        "title": "Q13 — [LEFT JOIN] Đối chiếu hóa đơn đã thu tiền với sổ cái ví (Kỳ vọng: 0 dòng)",
        "sql": """SELECT hd.MaHD, hd.TrangThaiThanhToan, hd.TongTien, g.MaGD, g.LoaiGD, g.SoTien
FROM HOA_DON hd
LEFT JOIN GIAO_DICH_VI g ON g.MaHD = hd.MaHD
                        AND g.LoaiGD IN ('Payment', 'DirectPayment')
WHERE hd.TrangThaiThanhToan IN ('Paid', 'Refunded')
  AND (g.MaGD IS NULL OR g.SoTien <> hd.TongTien);"""
    },
    "V1": {
        "title": "View 1: VW_CHO_DO_TRONG — Chỗ đỗ còn trống & Tình trạng trụ sạc",
        "sql": """SELECT * FROM VW_CHO_DO_TRONG ORDER BY MaTram, MaViTri LIMIT 50;"""
    },
    "V2": {
        "title": "View 2: VW_DOANH_THU_TRAM_THANG — Doanh thu thực thu theo trạm hàng tháng",
        "sql": """SELECT * FROM VW_DOANH_THU_TRAM_THANG ORDER BY Thang DESC, MaTram LIMIT 50;"""
    }
}

@queries_bp.route("/queries")
@admin_required
def queries_page():
    db_ok, db_msg = test_connection()
    selected_key = request.args.get("q", "Q1")
    query_info = QUERIES_DICT.get(selected_key, QUERIES_DICT["Q1"])
    
    results = []
    columns = []
    exec_time_ms = 0
    error_msg = None
    
    if db_ok:
        try:
            start_time = time.time()
            clean_sql = query_info["sql"].strip().rstrip(";")
            results = query_all(clean_sql)
            exec_time_ms = round((time.time() - start_time) * 1000, 2)
            if results:
                columns = list(results[0].keys())
        except Exception as e:
            error_msg = str(e)
            
    return render_template("queries.html", db_ok=db_ok, db_msg=db_msg,
                           queries_dict=QUERIES_DICT, selected_key=selected_key,
                           query_info=query_info, results=results, columns=columns,
                           exec_time_ms=exec_time_ms, error_msg=error_msg)
