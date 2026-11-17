from flask import Blueprint, render_template, request, redirect, url_for, flash
from db import test_connection, query_all, execute_statement
import datetime

bookings_bp = Blueprint("bookings", __name__)

@bookings_bp.route("/bookings")
def list_bookings():
    db_ok, db_msg = test_connection()
    bookings = []
    available_slots = []
    vehicles = []
    
    if db_ok:
        try:
            bookings = query_all("""
                SELECT d.MaDatCho, d.MaXe, pt.BienSo, pt.LoaiXe, kh.HoTen AS TenKhach,
                       d.MaCho, t.TenTram, c.MaViTri, d.ThoiGianDat, d.ThoiGianHetHan,
                       d.TienCoc, d.TrangThaiDatCho
                FROM DAT_CHO d
                JOIN PHUONG_TIEN pt ON d.MaXe = pt.MaXe
                JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                JOIN CHO_DO_XE c ON d.MaCho = c.MaCho
                JOIN TRAM t ON c.MaTram = t.MaTram
                ORDER BY d.ThoiGianDat DESC
                LIMIT 50
            """)
            available_slots = query_all("""
                SELECT c.MaCho, c.MaViTri, c.LoaiCho, t.TenTram
                FROM CHO_DO_XE c
                JOIN TRAM t ON c.MaTram = t.MaTram
                WHERE c.TrangThaiCho = 'Available'
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
            
    return render_template("bookings.html", db_ok=db_ok, db_msg=db_msg,
                           bookings=bookings, available_slots=available_slots,
                           vehicles=vehicles)

@bookings_bp.route("/bookings/create", methods=["POST"])
def create_booking():
    ma_xe = request.form.get("ma_xe")
    ma_cho = request.form.get("ma_cho")
    tien_coc = float(request.form.get("tien_coc", 20000))
    minutes = int(request.form.get("minutes", 30))
    
    now = datetime.datetime.now()
    het_han = now + datetime.timedelta(minutes=minutes)
    ma_dat_cho = f"DC{int(now.timestamp())}"
    
    try:
        execute_statement("""
            INSERT INTO DAT_CHO (MaDatCho, MaXe, MaCho, ThoiGianDat, ThoiGianHetHan, TienCoc, TrangThaiDatCho)
            VALUES (%s, %s, %s, %s, %s, %s, 'Active')
        """, (ma_dat_cho, ma_xe, ma_cho, now, het_han, tien_coc))
        flash(f"Đặt chỗ thành công! Mã: {ma_dat_cho} (Ô đỗ đã chuyển sang Reserved)", "success")
    except Exception as e:
        flash(f"Không thể đặt chỗ: {str(e)}", "danger")
        
    return redirect(url_for("bookings.list_bookings"))

@bookings_bp.route("/bookings/<id>/cancel", methods=["POST"])
def cancel_booking(id):
    try:
        execute_statement("""
            UPDATE DAT_CHO SET TrangThaiDatCho = 'Cancelled' WHERE MaDatCho = %s
        """, (id,))
        flash(f"Đã hủy đặt chỗ {id}! (Ô đỗ tự động trả về Available)", "info")
    except Exception as e:
        flash(f"Lỗi khi hủy đặt chỗ: {str(e)}", "danger")
        
    return redirect(url_for("bookings.list_bookings"))
