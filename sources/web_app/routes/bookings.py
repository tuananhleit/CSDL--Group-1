from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from db import test_connection, query_all, query_one, execute_statement, format_db_error
import datetime

bookings_bp = Blueprint("bookings", __name__)

@bookings_bp.route("/bookings")
def list_bookings():
    db_ok, db_msg = test_connection()
    bookings = []
    available_slots = []
    vehicles = []
    current_role = session.get("role", "customer")
    is_logged_in = session.get("logged_in", False)
    current_user_id = session.get("user_id")
    
    if db_ok:
        try:
            if current_role == "customer" and is_logged_in and current_user_id:
                bookings = query_all("""
                    SELECT d.MaDatCho, d.MaXe, pt.BienSo, pt.LoaiXe, kh.HoTen AS TenKhach,
                           d.MaCho, t.TenTram, c.MaViTri, d.ThoiGianDat, d.ThoiGianHetHan,
                           d.TienCoc, d.TrangThaiDatCho,
                           (pt.MaKH = %s) AS IsMyBooking
                    FROM DAT_CHO d
                    JOIN PHUONG_TIEN pt ON d.MaXe = pt.MaXe
                    JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                    JOIN CHO_DO_XE c ON d.MaCho = c.MaCho
                    JOIN TRAM t ON c.MaTram = t.MaTram
                    ORDER BY (pt.MaKH = %s) DESC, (d.TrangThaiDatCho = 'Active') DESC, d.ThoiGianDat DESC
                    LIMIT 50
                """, (current_user_id, current_user_id))

                vehicles = query_all("""
                    SELECT pt.MaXe, pt.BienSo, pt.LoaiXe, pt.ChuanSac, kh.HoTen, 1 AS IsMyVehicle
                    FROM PHUONG_TIEN pt
                    JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                    WHERE pt.MaKH = %s AND pt.BiDenKhoa = FALSE AND kh.TrangThaiTK = 'Active'
                    ORDER BY pt.BienSo
                """, (current_user_id,))
            elif current_role == "admin":
                bookings = query_all("""
                    SELECT d.MaDatCho, d.MaXe, pt.BienSo, pt.LoaiXe, kh.HoTen AS TenKhach,
                           d.MaCho, t.TenTram, c.MaViTri, d.ThoiGianDat, d.ThoiGianHetHan,
                           d.TienCoc, d.TrangThaiDatCho,
                           1 AS IsMyBooking
                    FROM DAT_CHO d
                    JOIN PHUONG_TIEN pt ON d.MaXe = pt.MaXe
                    JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                    JOIN CHO_DO_XE c ON d.MaCho = c.MaCho
                    JOIN TRAM t ON c.MaTram = t.MaTram
                    ORDER BY (d.TrangThaiDatCho = 'Active') DESC, d.ThoiGianDat DESC
                    LIMIT 50
                """)

                vehicles = query_all("""
                    SELECT pt.MaXe, pt.BienSo, pt.LoaiXe, pt.ChuanSac, kh.HoTen, 0 AS IsMyVehicle
                    FROM PHUONG_TIEN pt
                    JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                    WHERE pt.BiDenKhoa = FALSE AND kh.TrangThaiTK = 'Active'
                    ORDER BY pt.BienSo
                    LIMIT 100
                """)
            else:
                # Khách hàng chưa đăng nhập: Không lộ xe cá nhân của người khác
                bookings = query_all("""
                    SELECT d.MaDatCho, d.MaXe, pt.BienSo, pt.LoaiXe, kh.HoTen AS TenKhach,
                           d.MaCho, t.TenTram, c.MaViTri, d.ThoiGianDat, d.ThoiGianHetHan,
                           d.TienCoc, d.TrangThaiDatCho,
                           0 AS IsMyBooking
                    FROM DAT_CHO d
                    JOIN PHUONG_TIEN pt ON d.MaXe = pt.MaXe
                    JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                    JOIN CHO_DO_XE c ON d.MaCho = c.MaCho
                    JOIN TRAM t ON c.MaTram = t.MaTram
                    ORDER BY (d.TrangThaiDatCho = 'Active') DESC, d.ThoiGianDat DESC
                    LIMIT 30
                """)
                vehicles = []

            available_slots = query_all("""
                SELECT c.MaCho, c.MaViTri, c.LoaiCho, t.TenTram,
                       ts.MaTru, ts.TrangThaiTru, lt.ChuanKetNoi, lt.CongSuat_kW
                FROM CHO_DO_XE c
                JOIN TRAM t ON c.MaTram = t.MaTram
                LEFT JOIN TRU_SAC ts ON c.MaCho = ts.MaCho
                LEFT JOIN LOAI_TRU_SAC lt ON ts.MaLoaiTru = lt.MaLoaiTru
                WHERE c.TrangThaiCho = 'Available'
                ORDER BY t.TenTram, c.MaViTri
            """)
        except Exception as e:
            db_msg = str(e)
            
    return render_template("bookings.html", db_ok=db_ok, db_msg=db_msg,
                           bookings=bookings, available_slots=available_slots,
                           vehicles=vehicles, current_role=current_role, is_logged_in=is_logged_in)

@bookings_bp.route("/bookings/create", methods=["POST"])
def create_booking():
    current_role = session.get("role", "customer")
    is_logged_in = session.get("logged_in", False)
    current_user_id = session.get("user_id")

    if current_role == "customer" and not is_logged_in:
        flash("Vui lòng đăng nhập hoặc tạo tài khoản để thực hiện đặt chỗ xe!", "warning")
        return redirect(url_for("auth.login_page", next=url_for("bookings.list_bookings")))

    ma_xe = request.form.get("ma_xe")
    ma_cho = request.form.get("ma_cho")
    tien_coc = float(request.form.get("tien_coc", 20000))
    minutes = int(request.form.get("minutes", 30))

    if not ma_xe or not ma_cho:
        flash("Vui lòng chọn phương tiện và vị trí ô đỗ!", "warning")
        return redirect(url_for("bookings.list_bookings"))

    # Kiểm tra quyền sở hữu xe đối với khách hàng (Chống IDOR)
    if current_role == "customer":
        owner = query_one("SELECT MaKH FROM PHUONG_TIEN WHERE MaXe = %s", (ma_xe,))
        if not owner or owner["MaKH"] != current_user_id:
            flash("Lỗi bảo mật: Bạn chỉ có thể đặt chỗ cho phương tiện thuộc sở hữu của bạn!", "danger")
            return redirect(url_for("bookings.list_bookings"))
    
    now = datetime.datetime.now()
    het_han = now + datetime.timedelta(minutes=minutes)
    ma_dat_cho = f"DC{int(now.timestamp())}"
    
    try:
        execute_statement("""
            INSERT INTO DAT_CHO (MaDatCho, MaXe, MaCho, ThoiGianDat, ThoiGianHetHan, TienCoc, TrangThaiDatCho)
            VALUES (%s, %s, %s, %s, %s, %s, 'Active')
        """, (ma_dat_cho, ma_xe, ma_cho, now, het_han, tien_coc))
        flash(f"Đặt chỗ thành công! Mã: {ma_dat_cho} (Ô đỗ đã chuyển sang Reserved trong {minutes} phút)", "success")
    except Exception as e:
        flash(f"Không thể đặt chỗ: {format_db_error(e)}", "danger")
        
    return redirect(url_for("bookings.list_bookings"))

@bookings_bp.route("/bookings/<id>/cancel", methods=["POST"])
def cancel_booking(id):
    current_role = session.get("role", "customer")
    is_logged_in = session.get("logged_in", False)
    current_user_id = session.get("user_id")

    if current_role == "customer" and not is_logged_in:
        flash("Vui lòng đăng nhập để thực hiện thao tác!", "warning")
        return redirect(url_for("auth.login_page", next=url_for("bookings.list_bookings")))

    if current_role == "customer":
        booking = query_one("""
            SELECT d.MaDatCho, pt.MaKH 
            FROM DAT_CHO d
            JOIN PHUONG_TIEN pt ON d.MaXe = pt.MaXe
            WHERE d.MaDatCho = %s
        """, (id,))
        if not booking or booking["MaKH"] != current_user_id:
            flash("Lỗi bảo mật: Bạn chỉ có quyền hủy đặt chỗ của chính phương tiện bạn!", "danger")
            return redirect(url_for("bookings.list_bookings"))

    try:
        execute_statement("""
            UPDATE DAT_CHO SET TrangThaiDatCho = 'Cancelled' WHERE MaDatCho = %s
        """, (id,))
        flash(f"Đã hủy đặt chỗ {id}! (Ô đỗ tự động trả về Available)", "info")
    except Exception as e:
        flash(f"Lỗi khi hủy đặt chỗ: {format_db_error(e)}", "danger")
        
    return redirect(url_for("bookings.list_bookings"))
