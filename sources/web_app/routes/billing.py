from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from db import test_connection, query_all, query_one, call_procedure
import uuid

billing_bp = Blueprint("billing", __name__)

@billing_bp.route("/billing")
def list_billing():
    db_ok, db_msg = test_connection()
    current_role = session.get("role", "customer")
    search = request.args.get("search", "").strip()
    customer_info = None
    invoices = []
    transactions = []
    
    if db_ok:
        try:
            if current_role == "customer":
                # Che do Khach Hang: Mac dinh tra cuu cho KH01 hoac theo tu khoa tim kiem
                target_search = search if search else "KH01"
                
                # Tim thong tin khach hang
                customer_info = query_one("""
                    SELECT kh.MaKH, kh.HoTen, kh.SDT, kh.Email, kh.SoDuViDienTu, kh.LoaiKhach
                    FROM KHACH_HANG kh
                    LEFT JOIN PHUONG_TIEN pt ON kh.MaKH = pt.MaKH
                    WHERE kh.MaKH = %s OR kh.SDT = %s OR pt.BienSo LIKE %s OR kh.HoTen LIKE %s
                    LIMIT 1
                """, (target_search, target_search, f"%{target_search}%", f"%{target_search}%"))

                if customer_info:
                    c_id = customer_info["MaKH"]
                    invoices = query_all("""
                        SELECT hd.MaHD, hd.MaPhien, pt.BienSo, kh.MaKH, kh.HoTen AS TenKhach,
                               hd.PhiDoXe, hd.PhiSacDien, hd.PhiDoSauSac, hd.TienKhauTru,
                               hd.TongTien, hd.PhuongThucThanhToan, hd.TrangThaiThanhToan,
                               hd.NgayLapHoaDon, hd.NgayThanhToan
                        FROM HOA_DON hd
                        JOIN PHIEN p ON hd.MaPhien = p.MaPhien
                        JOIN PHUONG_TIEN pt ON p.MaXe = pt.MaXe
                        JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                        WHERE kh.MaKH = %s
                        ORDER BY (hd.TrangThaiThanhToan = 'Unpaid') DESC, hd.NgayLapHoaDon DESC
                        LIMIT 30
                    """, (c_id,))

                    transactions = query_all("""
                        SELECT g.MaGD, g.MaKH, kh.HoTen, g.LoaiGD, g.SoTien,
                               g.SoDuTruoc, g.SoDuSau, g.MaHD, g.ThoiGianGD, g.GhiChu
                        FROM GIAO_DICH_VI g
                        JOIN KHACH_HANG kh ON g.MaKH = kh.MaKH
                        WHERE g.MaKH = %s
                        ORDER BY g.ThoiGianGD DESC
                        LIMIT 20
                    """, (c_id,))
            else:
                # Che do Quan Tri Vien: Xem toan bo hoa don va so cai doi soat he thong
                if search:
                    invoices = query_all("""
                        SELECT hd.MaHD, hd.MaPhien, pt.BienSo, kh.MaKH, kh.HoTen AS TenKhach,
                               hd.PhiDoXe, hd.PhiSacDien, hd.PhiDoSauSac, hd.TienKhauTru,
                               hd.TongTien, hd.PhuongThucThanhToan, hd.TrangThaiThanhToan,
                               hd.NgayLapHoaDon, hd.NgayThanhToan
                        FROM HOA_DON hd
                        JOIN PHIEN p ON hd.MaPhien = p.MaPhien
                        JOIN PHUONG_TIEN pt ON p.MaXe = pt.MaXe
                        JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                        WHERE hd.MaHD LIKE %s OR pt.BienSo LIKE %s OR kh.MaKH LIKE %s OR kh.HoTen LIKE %s
                        ORDER BY (hd.TrangThaiThanhToan = 'Unpaid') DESC, hd.NgayLapHoaDon DESC
                        LIMIT 50
                    """, (f"%{search}%", f"%{search}%", f"%{search}%", f"%{search}%"))
                else:
                    invoices = query_all("""
                        SELECT hd.MaHD, hd.MaPhien, pt.BienSo, kh.MaKH, kh.HoTen AS TenKhach,
                               hd.PhiDoXe, hd.PhiSacDien, hd.PhiDoSauSac, hd.TienKhauTru,
                               hd.TongTien, hd.PhuongThucThanhToan, hd.TrangThaiThanhToan,
                               hd.NgayLapHoaDon, hd.NgayThanhToan
                        FROM HOA_DON hd
                        JOIN PHIEN p ON hd.MaPhien = p.MaPhien
                        JOIN PHUONG_TIEN pt ON p.MaXe = pt.MaXe
                        JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
                        ORDER BY (hd.TrangThaiThanhToan = 'Unpaid') DESC, hd.NgayLapHoaDon DESC
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
                           invoices=invoices, transactions=transactions,
                           search=search, customer_info=customer_info, current_role=current_role)

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
