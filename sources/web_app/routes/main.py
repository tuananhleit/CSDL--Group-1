from flask import Blueprint, render_template, current_app, session, redirect, request, url_for, flash
from db import test_connection, query_one, query_all

main_bp = Blueprint("main", __name__)

@main_bp.route("/switch-role/<role>")
def switch_role(role):
    """
    Chuyển đổi vai trò an toàn:
    - Chuyển sang Admin: BẮT BUỘC phải đăng nhập mật khẩu qua cổng bảo mật /login (Chống Leo Thang Đặc Quyền - Privilege Escalation).
    - Chuyển sang Khách Hàng: Cho phép Quản trị viên chuyển về giao diện trải nghiệm người dùng.
    """
    if role == "admin":
        if session.get("role") != "admin":
            flash("Khu vực bảo vệ: Vui lòng nhập tài khoản Quản trị viên (Admin) để kích hoạt quyền quản trị!", "warning")
            return redirect(url_for("auth.login_page", role="admin", next=request.referrer or url_for("main.dashboard")))
    elif role == "customer":
        session["role"] = "customer"
        flash("Đã chuyển sang chế độ Khách Hàng (Tài xế EV).", "info")

    referrer = request.referrer
    return redirect(referrer if referrer else url_for("main.dashboard"))

@main_bp.route("/")
def dashboard():
    db_ok, db_msg = test_connection()
    current_role = session.get("role", "customer")
    is_logged_in = session.get("logged_in", False)
    current_user_id = session.get("user_id")
    stats = {
        "total_customers": 0,
        "total_stations": 0,
        "available_slots": 0,
        "active_sessions": 0,
        "available_chargers": 0,
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

            # So luong tru sac san sang sac cho khach hang
            tru = query_one("SELECT COUNT(*) AS total FROM TRU_SAC WHERE TrangThaiTru = 'Available'")
            stats["available_chargers"] = tru["total"] if tru else 0

            # Doanh thu chi duoc truy van cho Admin (Bao mat thong tin noi bo)
            if current_role == "admin":
                dt = query_one("SELECT COALESCE(SUM(TongTien), 0) AS total FROM HOA_DON WHERE TrangThaiThanhToan = 'Paid'")
                stats["paid_revenue"] = dt["total"] if dt else 0
            else:
                stats["paid_revenue"] = 0

            if current_role == "customer" and is_logged_in and current_user_id:
                stats["recent_sessions"] = query_all("""
                    SELECT p.MaPhien, pt.BienSo, t.TenTram, c.MaViTri, p.LoaiPhien, p.TrangThaiPhien, p.ThoiGianVao,
                           (pt.MaKH = %s) AS IsMySession
                    FROM PHIEN p
                    JOIN PHUONG_TIEN pt ON p.MaXe = pt.MaXe
                    JOIN CHO_DO_XE c ON p.MaCho = c.MaCho
                    JOIN TRAM t ON c.MaTram = t.MaTram
                    ORDER BY (pt.MaKH = %s) DESC, p.ThoiGianVao DESC
                    LIMIT 6
                """, (current_user_id, current_user_id))
            else:
                stats["recent_sessions"] = query_all("""
                    SELECT p.MaPhien, pt.BienSo, t.TenTram, c.MaViTri, p.LoaiPhien, p.TrangThaiPhien, p.ThoiGianVao,
                           0 AS IsMySession
                    FROM PHIEN p
                    JOIN PHUONG_TIEN pt ON p.MaXe = pt.MaXe
                    JOIN CHO_DO_XE c ON p.MaCho = c.MaCho
                    JOIN TRAM t ON c.MaTram = t.MaTram
                    ORDER BY p.ThoiGianVao DESC
                    LIMIT 6
                """)
        except Exception as e:
            db_msg = f"Lỗi truy vấn: {str(e)}"
            
    return render_template("dashboard.html", db_ok=db_ok, db_msg=db_msg, stats=stats,
                           current_role=current_role, is_logged_in=is_logged_in)
