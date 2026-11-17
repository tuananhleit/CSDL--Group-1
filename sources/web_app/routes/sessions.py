from flask import Blueprint, render_template, request, redirect, url_for, flash
from db import test_connection, query_all, query_one, execute_statement, call_procedure
import datetime

sessions_bp = Blueprint("sessions", __name__)

@sessions_bp.route("/sessions")
def list_sessions():
    db_ok, db_msg = test_connection()
    sessions = []
    available_slots = []
    vehicles = []
    
    if db_ok:
        try:
            sessions = query_all("""
                SELECT p.MaPhien, p.MaXe, pt.BienSo, pt.LoaiXe, kh.HoTen AS TenKhach,
                       p.MaCho, t.TenTram, c.MaViTri, p.LoaiPhien, p.TrangThaiPhien,
                       p.ThoiGianVao, p.ThoiGianRa,
                       cts.MaTru, cts.TrangThaiSac, cts.ChiSoCongToDau, cts.ChiSoCongToCuoi,
                       cts.SoKWh, cts.LyDoKetThuc
                FROM PHIEN p
                JOIN PHUONG_TIEN pt ON p.MaXe = pt.MaXe
                JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                JOIN CHO_DO_XE c ON p.MaCho = c.MaCho
                JOIN TRAM t ON c.MaTram = t.MaTram
                LEFT JOIN CHI_TIET_PHIEN_SAC cts ON p.MaPhien = cts.MaPhien
                ORDER BY (p.TrangThaiPhien = 'Active') DESC, p.ThoiGianVao DESC
                LIMIT 50
            """)
            available_slots = query_all("""
                SELECT c.MaCho, c.MaViTri, c.LoaiCho, t.TenTram, ts.MaTru, ts.TrangThaiTru
                FROM CHO_DO_XE c
                JOIN TRAM t ON c.MaTram = t.MaTram
                LEFT JOIN TRU_SAC ts ON c.MaCho = ts.MaCho
                WHERE c.TrangThaiCho IN ('Available', 'Reserved')
                ORDER BY t.TenTram, c.MaViTri
            """)
            vehicles = query_all("""
                SELECT pt.MaXe, pt.BienSo, pt.LoaiXe, kh.HoTen
                FROM PHUONG_TIEN pt
                JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                WHERE pt.BiDenKhoa = FALSE AND kh.TrangThaiTK = 'Active'
                ORDER BY pt.BienSo
                LIMIT 100
            """)
        except Exception as e:
            db_msg = str(e)
            
    return render_template("sessions.html", db_ok=db_ok, db_msg=db_msg,
                           sessions=sessions, available_slots=available_slots,
                           vehicles=vehicles)

@sessions_bp.route("/sessions/create", methods=["POST"])
def create_session():
    ma_xe = request.form.get("ma_xe")
    ma_cho = request.form.get("ma_cho")
    loai_phien = request.form.get("loai_phien", "ParkingOnly")
    ma_dat_cho = request.form.get("ma_dat_cho") or None
    
    now = datetime.datetime.now()
    ma_phien = f"P{int(now.timestamp())}"
    
    try:
        execute_statement("""
            INSERT INTO PHIEN (MaPhien, MaXe, MaCho, MaDatCho, LoaiPhien, TrangThaiPhien, ThoiGianVao)
            VALUES (%s, %s, %s, %s, %s, 'Active', %s)
        """, (ma_phien, ma_xe, ma_cho, ma_dat_cho, loai_phien, now))
        
        # Nếu là sạc điện, khởi tạo luôn bản ghi CHI_TIET_PHIEN_SAC
        if loai_phien == "ParkingAndCharging":
            tru = query_one("SELECT MaTru FROM TRU_SAC WHERE MaCho = %s", (ma_cho,))
            if tru:
                execute_statement("""
                    INSERT INTO CHI_TIET_PHIEN_SAC (MaPhien, MaTru, ThoiGianBatDauSac, ChiSoCongToDau, TrangThaiSac)
                    VALUES (%s, %s, %s, 1000.00, 'Charging')
                """, (ma_phien, tru["MaTru"], now))
                
        flash(f"Mở phiên thành công! Mã: {ma_phien}", "success")
    except Exception as e:
        flash(f"Không thể mở phiên: {str(e)}", "danger")
        
    return redirect(url_for("sessions.list_sessions"))

@sessions_bp.route("/sessions/<id>/cutoff", methods=["POST"])
def cutoff_session(id):
    chi_so_cuoi = float(request.form.get("chi_so_cuoi", 1025.50))
    now = datetime.datetime.now()
    try:
        call_procedure("sp_kiem_tra_va_ngat_sac_tu_dong", (id, chi_so_cuoi, now))
        flash(f"Đã gọi sp_kiem_tra_va_ngat_sac_tu_dong cho phiên {id}!", "success")
    except Exception as e:
        flash(f"Lỗi khi ngắt sạc: {str(e)}", "danger")
        
    return redirect(url_for("sessions.list_sessions"))

@sessions_bp.route("/sessions/<id>/complete", methods=["POST"])
def complete_session(id):
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
                    LyDoKetThuc = COALESCE(LyDoKetThuc, 'UserStop')
                WHERE MaPhien = %s AND TrangThaiSac = 'Charging'
            """, (now, id))

        # Cap nhat phien thanh Completed (Trigger TRG_Phien_SyncTrangThai_Upd se tu dong tra cho & tru ve Available)
        execute_statement("""
            UPDATE PHIEN
            SET TrangThaiPhien = 'Completed', ThoiGianRa = %s
            WHERE MaPhien = %s
        """, (now, id))

        flash(f"Phiên {id} đã hoàn tất thành công! Xe đã ra bãi, ô đỗ và trụ sạc đã được tự động giải phóng.", "success")
    except Exception as e:
        flash(f"Lỗi khi hoàn tất phiên: {str(e)}", "danger")
        
    return redirect(url_for("sessions.list_sessions"))
