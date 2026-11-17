from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from db import test_connection, query_all, query_one, call_procedure, format_db_error
from security import generate_payment_signature, verify_payment_signature
from config import Config
import hashlib
import time

billing_bp = Blueprint("billing", __name__)

@billing_bp.route("/billing")
def list_billing():
    db_ok, db_msg = test_connection()
    current_role = session.get("role", "customer")
    current_user_id = session.get("user_id", "KH01")
    search = request.args.get("search", "").strip()
    customer_info = None
    invoices = []
    transactions = []
    
    if db_ok:
        try:
            if current_role == "customer":
                # Chế độ Khách Hàng: BẢO MẬT DỮ LIỆU - Khách chỉ được xem tài khoản của chính mình
                if search and search != current_user_id:
                    flash(f"Bảo mật quyền riêng tư tài chính: Bạn chỉ có thể tra cứu thông tin tài khoản của chính mình ({current_user_id}). Dữ liệu của khách hàng khác được bảo mật tuyệt đối.", "warning")
                target_search = current_user_id
                
                # Tim thong tin khach hang
                customer_info = query_one("""
                    SELECT kh.MaKH, kh.HoTen, kh.SDT, kh.Email, kh.SoDuViDienTu, kh.LoaiKhach
                    FROM KHACH_HANG kh
                    LEFT JOIN PHUONG_TIEN pt ON kh.MaKH = pt.MaKH
                    WHERE kh.MaKH = %s OR kh.SDT = %s
                    LIMIT 1
                """, (target_search, target_search))

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
    current_role = session.get("role", "customer")
    current_user_id = session.get("user_id", "KH01")

    # 1. Xác thực hóa đơn tồn tại trên máy chủ
    hd = query_one("""
        SELECT hd.MaHD, hd.TongTien, hd.TrangThaiThanhToan, pt.MaKH
        FROM HOA_DON hd
        JOIN PHIEN p ON hd.MaPhien = p.MaPhien
        JOIN PHUONG_TIEN pt ON p.MaXe = pt.MaXe
        WHERE hd.MaHD = %s
    """, (id,))

    if not hd:
        flash(f"Lỗi bảo mật: Hóa đơn {id} không tồn tại trên hệ thống!", "danger")
        return redirect(url_for("billing.list_billing"))

    # 2. Chống IDOR: Khách hàng chỉ có thể thanh toán hóa đơn của chính mình
    ma_kh = hd["MaKH"]
    if current_role == "customer" and ma_kh != current_user_id:
        flash(f"Cảnh báo gian lận tài chính: Bạn không có quyền thanh toán hóa đơn của tài khoản khác ({ma_kh})!", "danger")
        return redirect(url_for("billing.list_billing"))

    if hd["TrangThaiThanhToan"] == "Paid":
        flash(f"Hóa đơn {id} đã được thanh toán hoàn tất trước đó!", "info")
        return redirect(url_for("billing.list_billing"))

    # 3. Tạo chữ ký số SHA-256 trên Server để chống giả mạo số tiền và replay attack
    tong_tien = float(hd["TongTien"])
    sig_hash = generate_payment_signature(ma_kh, id, tong_tien)
    idempotency_key = f"SEC-{sig_hash[:16].upper()}"

    try:
        call_procedure("sp_thanh_toan_hoa_don_vi", (ma_kh, id, idempotency_key))
        flash(f"Thanh toán hóa đơn {id} qua Ví thành công! (Mã xác thực SHA-256 máy chủ: {idempotency_key})", "success")
    except Exception as e:
        flash(f"Lỗi thanh toán qua ví: {format_db_error(e)}", "danger")
        
    return redirect(url_for("billing.list_billing"))

@billing_bp.route("/billing/<id>/pay_walkin", methods=["POST"])
def pay_walkin(id):
    phuong_thuc = request.form.get("phuong_thuc", "Dynamic_QR")
    
    # 1. Xác thực hóa đơn trên máy chủ
    hd = query_one("SELECT MaHD, TongTien, TrangThaiThanhToan FROM HOA_DON WHERE MaHD = %s", (id,))
    if not hd:
        flash(f"Lỗi bảo mật: Hóa đơn {id} không tồn tại!", "danger")
        return redirect(url_for("billing.list_billing"))
        
    if hd["TrangThaiThanhToan"] == "Paid":
        flash(f"Hóa đơn {id} đã được thanh toán trước đó!", "info")
        return redirect(url_for("billing.list_billing"))

    # 2. Sinh mã giao dịch đối tác ngoài bảo vệ bằng SHA-256
    sig = hashlib.sha256(f"{id}:{phuong_thuc}:{time.time()}:{Config.SECRET_KEY}".encode("utf-8")).hexdigest()
    ma_gd_ngoai = f"EXT-{sig[:16].upper()}"
    try:
        call_procedure("sp_thanh_toan_walkin_ngoai", (id, phuong_thuc, ma_gd_ngoai))
        flash(f"Thanh toán trực tiếp hóa đơn {id} ({phuong_thuc}) thành công! (Mã xác thực SHA-256: {ma_gd_ngoai})", "success")
    except Exception as e:
        flash(f"Lỗi thanh toán trực tiếp: {format_db_error(e)}", "danger")
        
    return redirect(url_for("billing.list_billing"))
