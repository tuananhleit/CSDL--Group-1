from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from db import test_connection, query_all, query_one, execute_statement, call_procedure, format_db_error
import datetime

sessions_bp = Blueprint("sessions", __name__)

@sessions_bp.route("/sessions")
def list_sessions():
    db_ok, db_msg = test_connection()
    sessions = []
    available_slots = []
    vehicles = []
    current_role = session.get("role", "customer")
    is_logged_in = session.get("logged_in", False)
    current_user_id = session.get("user_id")
    
    if db_ok:
        try:
            if current_role == "customer" and is_logged_in and current_user_id:
                sessions = query_all("""
                    SELECT p.MaPhien, p.MaXe, pt.BienSo, pt.LoaiXe, kh.HoTen AS TenKhach,
                           p.MaCho, t.TenTram, c.MaViTri, p.LoaiPhien, p.TrangThaiPhien,
                           p.ThoiGianVao, p.ThoiGianRa,
                           cts.MaTru, cts.TrangThaiSac, cts.ChiSoCongToDau, cts.ChiSoCongToCuoi,
                           cts.SoKWh, cts.LyDoKetThuc,
                           (pt.MaKH = %s) AS IsMySession
                    FROM PHIEN p
                    JOIN PHUONG_TIEN pt ON p.MaXe = pt.MaXe
                    JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                    JOIN CHO_DO_XE c ON p.MaCho = c.MaCho
                    JOIN TRAM t ON c.MaTram = t.MaTram
                    LEFT JOIN CHI_TIET_PHIEN_SAC cts ON p.MaPhien = cts.MaPhien
                    ORDER BY (pt.MaKH = %s) DESC, (p.TrangThaiPhien = 'Active') DESC, p.ThoiGianVao DESC
                    LIMIT 50
                """, (current_user_id, current_user_id))

                vehicles = query_all("""
                    SELECT pt.MaXe, pt.BienSo, pt.LoaiXe, pt.ChuanSac, kh.HoTen,
                           1 AS IsMyVehicle
                    FROM PHUONG_TIEN pt
                    JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                    WHERE pt.MaKH = %s AND pt.BiDenKhoa = FALSE AND kh.TrangThaiTK = 'Active'
                    ORDER BY pt.BienSo
                """, (current_user_id,))
            elif current_role == "admin":
                sessions = query_all("""
                    SELECT p.MaPhien, p.MaXe, pt.BienSo, pt.LoaiXe, kh.HoTen AS TenKhach,
                           p.MaCho, t.TenTram, c.MaViTri, p.LoaiPhien, p.TrangThaiPhien,
                           p.ThoiGianVao, p.ThoiGianRa,
                           cts.MaTru, cts.TrangThaiSac, cts.ChiSoCongToDau, cts.ChiSoCongToCuoi,
                           cts.SoKWh, cts.LyDoKetThuc,
                           1 AS IsMySession
                    FROM PHIEN p
                    JOIN PHUONG_TIEN pt ON p.MaXe = pt.MaXe
                    JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                    JOIN CHO_DO_XE c ON p.MaCho = c.MaCho
                    JOIN TRAM t ON c.MaTram = t.MaTram
                    LEFT JOIN CHI_TIET_PHIEN_SAC cts ON p.MaPhien = cts.MaPhien
                    ORDER BY (p.TrangThaiPhien = 'Active') DESC, p.ThoiGianVao DESC
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
                # Khách hàng chưa đăng nhập: Không lộ xe cá nhân trong dropdown
                sessions = query_all("""
                    SELECT p.MaPhien, p.MaXe, pt.BienSo, pt.LoaiXe, kh.HoTen AS TenKhach,
                           p.MaCho, t.TenTram, c.MaViTri, p.LoaiPhien, p.TrangThaiPhien,
                           p.ThoiGianVao, p.ThoiGianRa,
                           cts.MaTru, cts.TrangThaiSac, cts.ChiSoCongToDau, cts.ChiSoCongToCuoi,
                           cts.SoKWh, cts.LyDoKetThuc,
                           0 AS IsMySession
                    FROM PHIEN p
                    JOIN PHUONG_TIEN pt ON p.MaXe = pt.MaXe
                    JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                    JOIN CHO_DO_XE c ON p.MaCho = c.MaCho
                    JOIN TRAM t ON c.MaTram = t.MaTram
                    LEFT JOIN CHI_TIET_PHIEN_SAC cts ON p.MaPhien = cts.MaPhien
                    ORDER BY (p.TrangThaiPhien = 'Active') DESC, p.ThoiGianVao DESC
                    LIMIT 30
                """)
                vehicles = []

            available_slots = query_all("""
                SELECT c.MaCho, c.MaViTri, c.LoaiCho, c.TrangThaiCho, t.TenTram,
                       ts.MaTru, ts.TrangThaiTru, lt.ChuanKetNoi, lt.CongSuat_kW
                FROM CHO_DO_XE c
                JOIN TRAM t ON c.MaTram = t.MaTram
                LEFT JOIN TRU_SAC ts ON c.MaCho = ts.MaCho
                LEFT JOIN LOAI_TRU_SAC lt ON ts.MaLoaiTru = lt.MaLoaiTru
                WHERE c.TrangThaiCho IN ('Available', 'Reserved')
                ORDER BY t.TenTram, c.MaViTri
            """)
        except Exception as e:
            db_msg = str(e)
            
    return render_template("sessions.html", db_ok=db_ok, db_msg=db_msg,
                           sessions=sessions, available_slots=available_slots,
                           vehicles=vehicles, current_role=current_role, is_logged_in=is_logged_in)

@sessions_bp.route("/sessions/create", methods=["POST"])
def create_session():
    current_role = session.get("role", "customer")
    is_logged_in = session.get("logged_in", False)
    current_user_id = session.get("user_id")

    if current_role == "customer" and not is_logged_in:
        flash("Vui lòng đăng nhập hoặc tạo tài khoản để mở phiên sạc cho xe của bạn!", "warning")
        return redirect(url_for("auth.login_page", next=url_for("sessions.list_sessions")))

    ma_xe = request.form.get("ma_xe")
    ma_cho = request.form.get("ma_cho")
    loai_phien = request.form.get("loai_phien", "ParkingOnly")
    ma_dat_cho = request.form.get("ma_dat_cho") or None

    if not ma_xe or not ma_cho:
        flash("Vui lòng chọn phương tiện và vị trí ô đỗ!", "warning")
        return redirect(url_for("sessions.list_sessions"))

    # Kiểm tra quyền sở hữu xe (Chống IDOR)
    if current_role == "customer":
        owner = query_one("SELECT MaKH FROM PHUONG_TIEN WHERE MaXe = %s", (ma_xe,))
        if not owner or owner["MaKH"] != current_user_id:
            flash("Lỗi bảo mật: Bạn chỉ có thể mở phiên cho phương tiện thuộc sở hữu của bạn!", "danger")
            return redirect(url_for("sessions.list_sessions"))
    
    now = datetime.datetime.now()
    ma_phien = f"P{int(now.timestamp())}"
    
    try:
        # Tu dong tim dat cho Active cua xe nay neu chua truyen
        if not ma_dat_cho:
            active_dc = query_one("""
                SELECT MaDatCho FROM DAT_CHO 
                WHERE MaXe = %s AND MaCho = %s AND TrangThaiDatCho = 'Active'
                LIMIT 1
            """, (ma_xe, ma_cho))
            if active_dc:
                ma_dat_cho = active_dc["MaDatCho"]

        execute_statement("""
            INSERT INTO PHIEN (MaPhien, MaXe, MaCho, MaDatCho, LoaiPhien, TrangThaiPhien, ThoiGianVao)
            VALUES (%s, %s, %s, %s, %s, 'Active', %s)
        """, (ma_phien, ma_xe, ma_cho, ma_dat_cho, loai_phien, now))
        
        # Neu co dat cho, hoan tat ban ghi dat cho
        if ma_dat_cho:
            execute_statement("""
                UPDATE DAT_CHO SET TrangThaiDatCho = 'Completed' WHERE MaDatCho = %s
            """, (ma_dat_cho,))

        # Nếu là sạc điện, khởi tạo bản ghi CHI_TIET_PHIEN_SAC
        if loai_phien == "ParkingAndCharging":
            tru = query_one("SELECT MaTru FROM TRU_SAC WHERE MaCho = %s", (ma_cho,))
            if tru:
                execute_statement("""
                    INSERT INTO CHI_TIET_PHIEN_SAC (MaPhien, MaTru, ThoiGianBatDauSac, ChiSoCongToDau, HanMucSac_kWh, TrangThaiSac)
                    VALUES (%s, %s, %s, 1000.00, 25.00, 'Charging')
                """, (ma_phien, tru["MaTru"], now))
                
        flash(f"Mở phiên thành công! Mã phiên: {ma_phien}", "success")
    except Exception as e:
        flash(f"Không thể mở phiên: {format_db_error(e)}", "danger")
        
    return redirect(url_for("sessions.list_sessions"))

@sessions_bp.route("/sessions/<id>/cutoff", methods=["POST"])
def cutoff_session(id):
    current_role = session.get("role", "customer")
    is_logged_in = session.get("logged_in", False)
    current_user_id = session.get("user_id")

    if current_role == "customer" and not is_logged_in:
        flash("Vui lòng đăng nhập để thao tác ngắt sạc!", "warning")
        return redirect(url_for("auth.login_page", next=url_for("sessions.list_sessions")))

    if current_role == "customer":
        owner = query_one("SELECT pt.MaKH FROM PHIEN p JOIN PHUONG_TIEN pt ON p.MaXe = pt.MaXe WHERE p.MaPhien = %s", (id,))
        if not owner or owner["MaKH"] != current_user_id:
            flash("Lỗi bảo mật: Bạn không có quyền ngắt sạc phiên của xe khác!", "danger")
            return redirect(url_for("sessions.list_sessions"))

    chi_so_cuoi = float(request.form.get("chi_so_cuoi", 1025.50))
    now = datetime.datetime.now()
    try:
        cts = query_one("SELECT ChiSoCongToDau, HanMucSac_kWh FROM CHI_TIET_PHIEN_SAC WHERE MaPhien = %s", (id,))
        if cts:
            cs_dau = float(cts["ChiSoCongToDau"] or 1000.00)
            kwh = max(1.0, chi_so_cuoi - cs_dau)
            if cts["HanMucSac_kWh"] is None or float(cts["HanMucSac_kWh"]) > kwh:
                execute_statement("UPDATE CHI_TIET_PHIEN_SAC SET HanMucSac_kWh = %s WHERE MaPhien = %s", (kwh, id))

        call_procedure("sp_kiem_tra_va_ngat_sac_tu_dong", (id, chi_so_cuoi, now))
        flash(f"Đã gọi sp_kiem_tra_va_ngat_sac_tu_dong cho phiên {id}! (Trạng thái sạc: Đã ngắt, tính ân hạn 15p)", "success")
    except Exception as e:
        flash(f"Lỗi khi ngắt sạc: {format_db_error(e)}", "danger")
        
    return redirect(url_for("sessions.list_sessions"))

@sessions_bp.route("/sessions/<id>/complete", methods=["POST"])
def complete_session(id):
    current_role = session.get("role", "customer")
    is_logged_in = session.get("logged_in", False)
    current_user_id = session.get("user_id")

    if current_role == "customer" and not is_logged_in:
        flash("Vui lòng đăng nhập để thao tác cho xe ra bãi!", "warning")
        return redirect(url_for("auth.login_page", next=url_for("sessions.list_sessions")))

    if current_role == "customer":
        owner = query_one("SELECT pt.MaKH FROM PHIEN p JOIN PHUONG_TIEN pt ON p.MaXe = pt.MaXe WHERE p.MaPhien = %s", (id,))
        if not owner or owner["MaKH"] != current_user_id:
            flash("Lỗi bảo mật: Bạn không có quyền kết thúc phiên của xe khác!", "danger")
            return redirect(url_for("sessions.list_sessions"))

    now = datetime.datetime.now()
    try:
        p = query_one("SELECT MaCho, LoaiPhien, MaXe FROM PHIEN WHERE MaPhien = %s", (id,))
        if not p:
            flash(f"Không tìm thấy phiên {id}!", "danger")
            return redirect(url_for("sessions.list_sessions"))
            
        # Neu la sac, hoan tat chi tiet phien sac truoc neu con dang sac
        if p["LoaiPhien"] == "ParkingAndCharging":
            execute_statement("""
                UPDATE CHI_TIET_PHIEN_SAC
                SET TrangThaiSac = 'Completed',
                    ThoiGianKetThucSac = COALESCE(ThoiGianKetThucSac, %s),
                    ChiSoCongToCuoi = COALESCE(ChiSoCongToCuoi, 1025.50),
                    LyDoKetThuc = COALESCE(LyDoKetThuc, 'UserStopped')
                WHERE MaPhien = %s AND TrangThaiSac = 'Charging'
            """, (now, id))

        # Cap nhat phien thanh Completed (Trigger TRG_Phien_SyncTrangThai_Upd tu dong tra o & tru ve Available)
        execute_statement("""
            UPDATE PHIEN
            SET TrangThaiPhien = 'Completed', ThoiGianRa = %s
            WHERE MaPhien = %s
        """, (now, id))

        # Tu dong lap HOA_DON cho phien neu chua co
        existing_hd = query_one("SELECT MaHD FROM HOA_DON WHERE MaPhien = %s", (id,))
        if not existing_hd:
            xe = query_one("SELECT pt.LoaiXe FROM PHIEN p JOIN PHUONG_TIEN pt ON p.MaXe = pt.MaXe WHERE p.MaPhien = %s", (id,))
            is_car = (xe["LoaiXe"] == "Car_4W") if xe else True
            phi_do = 20000.0 if is_car else 5000.0

            phi_sac = 0.0
            if p["LoaiPhien"] == "ParkingAndCharging":
                cts = query_one("SELECT SoKWh FROM CHI_TIET_PHIEN_SAC WHERE MaPhien = %s", (id,))
                sokwh = float(cts["SoKWh"]) if (cts and cts["SoKWh"] is not None) else 25.5
                phi_sac = sokwh * 3850.0

            phi_sau_sac = 0.0

            # Khau tru tien coc
            tien_khau_tru = 0.0
            p_full = query_one("SELECT MaDatCho FROM PHIEN WHERE MaPhien = %s", (id,))
            if p_full and p_full["MaDatCho"]:
                dc = query_one("SELECT TienCoc FROM DAT_CHO WHERE MaDatCho = %s", (p_full["MaDatCho"],))
                if dc and dc["TienCoc"]:
                    tien_khau_tru = min(float(dc["TienCoc"]), phi_do + phi_sac + phi_sau_sac)

            ma_hd = f"HD{int(now.timestamp())}"
            ngay_lap = (now - datetime.timedelta(seconds=2)).replace(microsecond=0)
            execute_statement("""
                INSERT INTO HOA_DON (MaHD, MaPhien, PhiDoXe, PhiSacDien, PhiDoSauSac, TienKhauTru, PhuongThucThanhToan, TrangThaiThanhToan, NgayLapHoaDon)
                VALUES (%s, %s, %s, %s, %s, %s, 'Wallet', 'Unpaid', %s)
            """, (ma_hd, id, phi_do, phi_sac, phi_sau_sac, tien_khau_tru, ngay_lap))

            flash(f"Phiên {id} đã hoàn tất! Hóa đơn {ma_hd} đã được lập (Đã khấu trừ cọc {tien_khau_tru:,.0f}đ). Bạn có thể thanh toán tại mục Hóa Đơn & Ví.", "success")
        else:
            flash(f"Phiên {id} đã hoàn tất thành công! Xe đã ra bãi, ô đỗ và trụ sạc đã được tự động giải phóng.", "success")
    except Exception as e:
        flash(f"Lỗi khi hoàn tất phiên: {format_db_error(e)}", "danger")
        
    return redirect(url_for("sessions.list_sessions"))
