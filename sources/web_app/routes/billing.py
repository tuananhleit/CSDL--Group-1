from flask import Blueprint, render_template, request, redirect, url_for, flash
from db import test_connection, query_all, query_one, call_procedure
import uuid

billing_bp = Blueprint("billing", __name__)

@billing_bp.route("/billing")
def list_billing():
    db_ok, db_msg = test_connection()
    invoices = []
    transactions = []
    
    if db_ok:
        try:
            invoices = query_all("""
                SELECT hd.MaHD, hd.MaPhien, pt.BienSo, kh.MaKH, kh.HoTen AS TenKhach,
                       hd.PhiDoXe, hd.PhiSacDien, hd.PhiDoSauSac, hd.TienKhauTru,
                       hd.TongTien, hd.PhuongThucThanhToan, hd.TrangThaiThanhToan,
                       hd.NgayLapHoaDon, hd.NgayThanhToan
                FROM HOA_DON hd
                JOIN PHIEN p ON hd.MaPhien = p.MaPhien
                JOIN PHUONG_TIEN pt ON p.MaXe = pt.MaXe
                JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                ORDER BY hd.NgayLapHoaDon DESC
                LIMIT 50
            """)
            transactions = query_all("""
                SELECT g.MaGD, g.MaKH, kh.HoTen, g.LoaiGD, g.SoTien,
                       g.SoDuTruoc, g.SoDuSau, g.MaHD, g.ThoiGianGD, g.GhiChu
                FROM GIAO_DICH_VI g
                JOIN KHACH_HANG kh ON g.MaKH = kh.MaKH
                ORDER BY g.ThoiGianGD DESC
                LIMIT 30
            """)
        except Exception as e:
            db_msg = str(e)
            
    return render_template("billing.html", db_ok=db_ok, db_msg=db_msg,
                           invoices=invoices, transactions=transactions)

@billing_bp.route("/billing/<id>/pay_wallet", methods=["POST"])
def pay_by_wallet(id):
    ma_kh = request.form.get("ma_kh")
    idempotency_key = f"IDEM-{uuid.uuid4().hex[:8].upper()}"
    try:
        call_procedure("sp_thanh_toan_hoa_don_vi", (ma_kh, id, idempotency_key))
        flash(f"Thanh toán hóa đơn {id} qua Ví điện tử thành công! (Khóa đối tác: {idempotency_key})", "success")
    except Exception as e:
        flash(f"Lỗi thanh toán qua ví: {str(e)}", "danger")
        
    return redirect(url_for("billing.list_billing"))

@billing_bp.route("/billing/<id>/pay_walkin", methods=["POST"])
def pay_walkin(id):
    phuong_thuc = request.form.get("phuong_thuc", "Dynamic_QR")
    ma_gd_ngoai = f"EXT-{uuid.uuid4().hex[:8].upper()}"
    try:
        call_procedure("sp_thanh_toan_walkin_ngoai", (id, phuong_thuc, ma_gd_ngoai))
        flash(f"Thanh toán trực tiếp hóa đơn {id} ({phuong_thuc}) thành công! (Mã đối tác: {ma_gd_ngoai})", "success")
    except Exception as e:
        flash(f"Lỗi thanh toán trực tiếp: {str(e)}", "danger")
        
    return redirect(url_for("billing.list_billing"))
