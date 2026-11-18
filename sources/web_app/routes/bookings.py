from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from db import test_connection, query_all, query_one, execute_statement, format_db_error
import datetime

bookings_bp = Blueprint("bookings", __name__)

@bookings_bp.route("/bookings")
def list_bookings():
    db_ok, db_msg = test_connection()
    bookings = []
    available_slots = []
    my_vehicles = []
    other_vehicles = []
    current_role = session.get("role", "customer")
    is_logged_in = session.get("logged_in", False)
    current_user_id = session.get("user_id")
    my_guest_bookings = session.get("my_guest_bookings", [])
    
    if db_ok:
        try:
            if current_role == "customer" and is_logged_in and current_user_id:
                # Lấy danh sách đặt chỗ, ưu tiên xe của chính mình và xe mình đặt chỗ giùm
                raw_bookings = query_all("""
                    SELECT d.MaDatCho, d.MaXe, pt.BienSo, pt.LoaiXe, kh.HoTen AS TenKhach,
                           d.MaCho, t.TenTram, c.MaViTri, d.ThoiGianDat, d.ThoiGianHetHan,
                           d.TienCoc, d.TrangThaiDatCho,
                           (pt.MaKH = %s) AS IsMyVehicleBooking
                    FROM DAT_CHO d
                    JOIN PHUONG_TIEN pt ON d.MaXe = pt.MaXe
                    JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                    JOIN CHO_DO_XE c ON d.MaCho = c.MaCho
                    JOIN TRAM t ON c.MaTram = t.MaTram
                    ORDER BY (pt.MaKH = %s) DESC, (d.TrangThaiDatCho = 'Active') DESC, d.ThoiGianDat DESC
                    LIMIT 60
                """, (current_user_id, current_user_id))

                bookings = []
                for b in raw_bookings:
                    is_my_veh = bool(b["IsMyVehicleBooking"])
                    is_guest = b["MaDatCho"] in my_guest_bookings
                    b["IsMyBooking"] = is_my_veh or is_guest
                    b["IsBookedForOther"] = (not is_my_veh) and is_guest
                    bookings.append(b)

                # Xe của chính mình
                my_vehicles = query_all("""
                    SELECT pt.MaXe, pt.BienSo, pt.LoaiXe, pt.ChuanSac, kh.HoTen, 1 AS IsMyVehicle
                    FROM PHUONG_TIEN pt
                    JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                    WHERE pt.MaKH = %s AND pt.BiDenKhoa = FALSE AND kh.TrangThaiTK = 'Active'
                    ORDER BY pt.BienSo
                """, (current_user_id,))

                # Danh sách xe khác trong hệ thống để hỗ trợ tính năng Đặt chỗ giùm
                other_vehicles = query_all("""
                    SELECT pt.MaXe, pt.BienSo, pt.LoaiXe, pt.ChuanSac, kh.HoTen, 0 AS IsMyVehicle
                    FROM PHUONG_TIEN pt
                    JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                    WHERE pt.MaKH != %s AND pt.BiDenKhoa = FALSE AND kh.TrangThaiTK = 'Active'
                    ORDER BY pt.BienSo
                    LIMIT 50
                """, (current_user_id,))

            elif current_role == "admin":
                raw_bookings = query_all("""
                    SELECT d.MaDatCho, d.MaXe, pt.BienSo, pt.LoaiXe, kh.HoTen AS TenKhach,
                           d.MaCho, t.TenTram, c.MaViTri, d.ThoiGianDat, d.ThoiGianHetHan,
                           d.TienCoc, d.TrangThaiDatCho,
                           1 AS IsMyBooking, 0 AS IsBookedForOther
                    FROM DAT_CHO d
                    JOIN PHUONG_TIEN pt ON d.MaXe = pt.MaXe
                    JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                    JOIN CHO_DO_XE c ON d.MaCho = c.MaCho
                    JOIN TRAM t ON c.MaTram = t.MaTram
                    ORDER BY (d.TrangThaiDatCho = 'Active') DESC, d.ThoiGianDat DESC
                    LIMIT 60
                """)
                bookings = raw_bookings

                my_vehicles = query_all("""
                    SELECT pt.MaXe, pt.BienSo, pt.LoaiXe, pt.ChuanSac, kh.HoTen, 0 AS IsMyVehicle
                    FROM PHUONG_TIEN pt
                    JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                    WHERE pt.BiDenKhoa = FALSE AND kh.TrangThaiTK = 'Active'
                    ORDER BY pt.BienSo
                    LIMIT 100
                """)
                other_vehicles = []
            else:
                # Khách hàng chưa đăng nhập: Xem trạng thái chung, không lộ xe cá nhân
                bookings = query_all("""
                    SELECT d.MaDatCho, d.MaXe, pt.BienSo, pt.LoaiXe, kh.HoTen AS TenKhach,
                           d.MaCho, t.TenTram, c.MaViTri, d.ThoiGianDat, d.ThoiGianHetHan,
                           d.TienCoc, d.TrangThaiDatCho,
                           0 AS IsMyBooking, 0 AS IsBookedForOther
                    FROM DAT_CHO d
                    JOIN PHUONG_TIEN pt ON d.MaXe = pt.MaXe
                    JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                    JOIN CHO_DO_XE c ON d.MaCho = c.MaCho
                    JOIN TRAM t ON c.MaTram = t.MaTram
                    ORDER BY (d.TrangThaiDatCho = 'Active') DESC, d.ThoiGianDat DESC
                    LIMIT 30
                """)
                my_vehicles = []
                other_vehicles = []

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
                           my_vehicles=my_vehicles, other_vehicles=other_vehicles,
                           current_role=current_role, is_logged_in=is_logged_in)

@bookings_bp.route("/bookings/create", methods=["POST"])
def create_booking():
    current_role = session.get("role", "customer")
    is_logged_in = session.get("logged_in", False)
    current_user_id = session.get("user_id")

    if current_role == "customer" and not is_logged_in:
        flash("Vui lòng đăng nhập hoặc tạo tài khoản để thực hiện đặt chỗ xe!", "warning")
        return redirect(url_for("auth.login_page", next=url_for("bookings.list_bookings")))

    booking_mode = request.form.get("booking_mode", "my_vehicle") # 'my_vehicle' hoặc 'other_vehicle'
    ma_cho = request.form.get("ma_cho")
    tien_coc = float(request.form.get("tien_coc", 20000))
    minutes = int(request.form.get("minutes", 30))

    if not ma_cho:
        flash("Vui lòng chọn vị trí ô đỗ khả dụng!", "warning")
        return redirect(url_for("bookings.list_bookings"))

    # Xác định phương tiện được đặt chỗ
    is_booking_for_others = False
    if booking_mode == "other_vehicle":
        # ĐẶT CHỖ GIÙM: Khách hàng nhập biển số hoặc chọn xe của người thân/bạn bè
        target_plate = request.form.get("bien_so_other", "").strip().upper()
        target_maxe = request.form.get("ma_xe_other", "").strip()

        target_veh = None
        if target_plate:
            target_veh = query_one("""
                SELECT pt.MaXe, pt.BienSo, pt.LoaiXe, kh.HoTen, kh.MaKH
                FROM PHUONG_TIEN pt
                JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                WHERE pt.BienSo = %s AND pt.BiDenKhoa = FALSE AND kh.TrangThaiTK = 'Active'
            """, (target_plate,))
        elif target_maxe:
            target_veh = query_one("""
                SELECT pt.MaXe, pt.BienSo, pt.LoaiXe, kh.HoTen, kh.MaKH
                FROM PHUONG_TIEN pt
                JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                WHERE pt.MaXe = %s AND pt.BiDenKhoa = FALSE AND kh.TrangThaiTK = 'Active'
            """, (target_maxe,))

        if not target_veh:
            flash("Không tìm thấy phương tiện cần đặt giùm (hoặc xe đang bị tạm khóa)! Vui lòng kiểm tra lại biển số.", "danger")
            return redirect(url_for("bookings.list_bookings"))

        ma_xe = target_veh["MaXe"]
        ten_chu_xe = target_veh["HoTen"]
        bien_so_xe = target_veh["BienSo"]
        is_booking_for_others = True
    else:
        # ĐẶT CHỖ CHO XE CỦA MÌNH
        ma_xe = request.form.get("ma_xe")
        if not ma_xe:
            flash("Vui lòng chọn phương tiện của bạn!", "warning")
            return redirect(url_for("bookings.list_bookings"))

        if current_role == "customer":
            owner = query_one("SELECT MaKH, BienSo FROM PHUONG_TIEN WHERE MaXe = %s", (ma_xe,))
            if not owner or owner["MaKH"] != current_user_id:
                flash("Lỗi bảo mật: Bạn chỉ có thể đặt trực tiếp cho xe thuộc sở hữu của bạn! Hãy chọn tính năng 'Đặt chỗ giùm' nếu muốn đặt hộ xe khác.", "danger")
                return redirect(url_for("bookings.list_bookings"))
            bien_so_xe = owner["BienSo"]
            ten_chu_xe = session.get("user_name", "")
        else:
            veh = query_one("SELECT BienSo FROM PHUONG_TIEN WHERE MaXe = %s", (ma_xe,))
            bien_so_xe = veh["BienSo"] if veh else ma_xe
            ten_chu_xe = "Khách Hàng"

    now = datetime.datetime.now()
    het_han = now + datetime.timedelta(minutes=minutes)
    ma_dat_cho = f"DC{int(now.timestamp())}"
    
    try:
        execute_statement("""
            INSERT INTO DAT_CHO (MaDatCho, MaXe, MaCho, ThoiGianDat, ThoiGianHetHan, TienCoc, TrangThaiDatCho)
            VALUES (%s, %s, %s, %s, %s, %s, 'Active')
        """, (ma_dat_cho, ma_xe, ma_cho, now, het_han, tien_coc))

        # Lưu vết nếu là đặt chỗ giùm để người đặt có quyền quản lý/hủy chỗ
        if is_booking_for_others:
            my_guest = session.get("my_guest_bookings", [])
            my_guest.append(ma_dat_cho)
            session["my_guest_bookings"] = my_guest
            flash(f"Đặt chỗ giùm thành công cho xe {bien_so_xe} (Chủ xe: {ten_chu_xe})! Mã: {ma_dat_cho} (Đã bảo lưu ô đỗ trong {minutes} phút, tiền cọc 20.000đ).", "success")
        else:
            flash(f"Đặt chỗ thành công cho xe {bien_so_xe}! Mã đặt chỗ: {ma_dat_cho} (Ô đỗ đã chuyển sang Reserved trong {minutes} phút)", "success")
    except Exception as e:
        flash(f"Không thể đặt chỗ: {format_db_error(e)}", "danger")
        
    return redirect(url_for("bookings.list_bookings"))

@bookings_bp.route("/bookings/<id>/cancel", methods=["POST"])
def cancel_booking(id):
    current_role = session.get("role", "customer")
    is_logged_in = session.get("logged_in", False)
    current_user_id = session.get("user_id")
    my_guest_bookings = session.get("my_guest_bookings", [])

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

        is_owner = (booking and booking["MaKH"] == current_user_id)
        is_booker = (id in my_guest_bookings)

        if not is_owner and not is_booker:
            flash("Lỗi bảo mật: Bạn chỉ có quyền hủy đặt chỗ của xe bạn hoặc do chính bạn đặt chỗ giùm!", "danger")
            return redirect(url_for("bookings.list_bookings"))

    try:
        execute_statement("""
            UPDATE DAT_CHO SET TrangThaiDatCho = 'Cancelled' WHERE MaDatCho = %s
        """, (id,))
        flash(f"Đã hủy đặt chỗ {id}! (Ô đỗ tự động trả về Available)", "info")
    except Exception as e:
        flash(f"Lỗi khi hủy đặt chỗ: {format_db_error(e)}", "danger")
        
    return redirect(url_for("bookings.list_bookings"))
