from flask import Blueprint, render_template, current_app
from db import test_connection, query_one, query_all

main_bp = Blueprint("main", __name__)

@main_bp.route("/")
def dashboard():
    db_ok, db_msg = test_connection()
    stats = {
        "total_customers": 0,
        "total_stations": 0,
        "available_slots": 0,
        "active_sessions": 0,
        "paid_revenue": 0,
        "recent_sessions": []
    }
    
    if db_ok:
        try:
            kh = query_one("SELECT COUNT(*) AS total FROM KHACH_HANG")
            stats["total_customers"] = kh["total"] if kh else 0

            tram = query_one("SELECT COUNT(*) AS total FROM TRAM")
            stats["total_stations"] = tram["total"] if tram else 0

            cho = query_one("SELECT COUNT(*) AS total FROM CHO_DO_XE WHERE TrangThaiCho = 'Available'")
            stats["available_slots"] = cho["total"] if cho else 0

            phien = query_one("SELECT COUNT(*) AS total FROM PHIEN WHERE TrangThaiPhien = 'Active'")
            stats["active_sessions"] = phien["total"] if phien else 0

            dt = query_one("SELECT COALESCE(SUM(TongTien), 0) AS total FROM HOA_DON WHERE TrangThaiThanhToan = 'Paid'")
            stats["paid_revenue"] = dt["total"] if dt else 0

            stats["recent_sessions"] = query_all("""
                SELECT p.MaPhien, pt.BienSo, t.TenTram, c.MaViTri, p.LoaiPhien, p.TrangThaiPhien, p.ThoiGianVao
                FROM PHIEN p
                JOIN PHUONG_TIEN pt ON p.MaXe = pt.MaXe
                JOIN CHO_DO_XE c ON p.MaCho = c.MaCho
                JOIN TRAM t ON c.MaTram = t.MaTram
                ORDER BY p.ThoiGianVao DESC
                LIMIT 6
            """)
        except Exception as e:
            db_msg = f"Lỗi truy vấn: {str(e)}"
            
    return render_template("dashboard.html", db_ok=db_ok, db_msg=db_msg, stats=stats)
