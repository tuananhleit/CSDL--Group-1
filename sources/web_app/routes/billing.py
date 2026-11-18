from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from db import test_connection, query_all, query_one, execute_statement, call_procedure, format_db_error
from security import generate_payment_signature, verify_payment_signature, admin_required
from config import Config
import hashlib
import time
import datetime

billing_bp = Blueprint("billing", __name__)

@billing_bp.route("/billing")
def list_billing():
    db_ok, db_msg = test_connection()
    current_role = session.get("role", "customer")
    is_logged_in = session.get("logged_in", False)
    current_user_id = session.get("user_id")
    search = request.args.get("search", "").strip()
    customer_info = None
    invoices = []
    transactions = []
    topup_requests = []
    pending_topups = []
    
    if db_ok:
        try:
            if current_role == "customer":
                # NẾU CHƯA ĐĂNG NHẬP: BẢO VỆ TUYỆT ĐỐI - KHÔNG HIỂN THỊ DỮ LIỆU CÁ NHÂN HOẶC VÍ
                if not is_logged_in or not current_user_id:
                    return render_template("billing.html", db_ok=db_ok, db_msg=db_msg,
                                           invoices=[], transactions=[], topup_requests=[], pending_topups=[],
                                           search="", customer_info=None,
                                           current_role=current_role, is_logged_in=False)

                # Chế độ Khách Hàng: Chỉ xem thông tin của chính mình
                if search and search != current_user_id:
                    flash(f"Bảo mật quyền riêng tư tài chính: Bạn chỉ có thể tra cứu thông tin tài khoản của chính mình ({current_user_id}). Dữ liệu của khách hàng khác được bảo mật tuyệt đối.", "warning")
                target_search = current_user_id
                
                # Tìm thông tin khách hàng
                customer_info = query_one("""
                    SELECT kh.MaKH, kh.HoTen, kh.SDT, kh.Email, kh.SoDuViDienTu, kh.LoaiKhach
                    FROM KHACH_HANG kh
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

                    # Danh sách yêu cầu nạp tiền của khách hàng
                    topup_requests = query_all("""
                        SELECT MaYC, MaKH, SoTien, PhuongThuc, MaThamChieu, ThoiGianYeuCau, TrangThai, NguoiDuyet, ThoiGianDuyet, GhiChu
                        FROM YEU_CAU_NAP_TIEN
                        WHERE MaKH = %s
                        ORDER BY ThoiGianYeuCau DESC
                        LIMIT 10
                    """, (c_id,))
            else:
                # Chế độ Quản Trị Viên: Xem toàn bộ hóa đơn, sổ cái và các yêu cầu nạp tiền chờ duyệt
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

                # Danh sách yêu cầu nạp tiền chờ Admin phê duyệt
                pending_topups = query_all("""
                    SELECT yc.MaYC, yc.MaKH, kh.HoTen, kh.SDT, kh.SoDuViDienTu,
                           yc.SoTien, yc.PhuongThuc, yc.MaThamChieu, yc.ThoiGianYeuCau, yc.TrangThai, yc.NguoiDuyet, yc.ThoiGianDuyet
                    FROM YEU_CAU_NAP_TIEN yc
                    JOIN KHACH_HANG kh ON yc.MaKH = kh.MaKH
                    ORDER BY (yc.TrangThai = 'Pending') DESC, yc.ThoiGianYeuCau DESC
                    LIMIT 30
                """)
        except Exception as e:
            db_msg = str(e)
            
    return render_template("billing.html", db_ok=db_ok, db_msg=db_msg,
                           invoices=invoices, transactions=transactions,
                           topup_requests=topup_requests, pending_topups=pending_topups,
                           search=search, customer_info=customer_info, current_role=current_role, is_logged_in=is_logged_in)

@billing_bp.route("/billing/topup", methods=["POST"])
@billing_bp.route("/billing/topup-request", methods=["POST"])
def request_topup():
    """
    Khách hàng gửi yêu cầu nạp tiền vào ví điện tử.
    Yêu cầu ở trạng thái 'Pending' và bắt buộc phải được Quản trị viên (Admin) đối soát & xác thực duyệt.
    """
    current_role = session.get("role", "customer")
    is_logged_in = session.get("logged_in", False)
    current_user_id = session.get("user_id")

    if current_role == "customer" and (not is_logged_in or not current_user_id):
        flash("Vui lòng đăng nhập để gửi yêu cầu nạp tiền ví!", "warning")
        return redirect(url_for("auth.login_page", next=url_for("billing.list_billing")))

    ma_kh = current_user_id
    try:
        amount = float(request.form.get("amount", 0))
        phuong_thuc = request.form.get("phuong_thuc", "BankTransfer_VietQR")
        ma_tham_chieu = request.form.get("ma_tham_chieu", "").strip()

        if amount <= 0:
            flash("Số tiền nạp phải lớn hơn 0đ!", "danger")
            return redirect(url_for("billing.list_billing"))
        if amount > 20000000:
            flash("Hạn mức nạp tối đa là 20.000.000đ mỗi giao dịch!", "danger")
            return redirect(url_for("billing.list_billing"))

        now = datetime.datetime.now()
        ma_yc = f"YC{int(now.timestamp())}"

        if not ma_tham_chieu:
            ma_tham_chieu = f"NAPVI {ma_kh} {int(amount/1000)}K"

        execute_statement("""
            INSERT INTO YEU_CAU_NAP_TIEN (MaYC, MaKH, SoTien, PhuongThuc, MaThamChieu, ThoiGianYeuCau, TrangThai, GhiChu)
            VALUES (%s, %s, %s, %s, %s, %s, 'Pending', 'Khách hàng gửi yêu cầu nạp ví chờ Admin phê duyệt')
        """, (ma_yc, ma_kh, amount, phuong_thuc, ma_tham_chieu, now))

        flash(f"Yêu cầu nạp tiền {ma_yc} trị giá {amount:,.0f}đ ({phuong_thuc}) đã được gửi thành công! Tiền sẽ được cộng vào ví ngay sau khi Quản trị viên đối soát & duyệt giao dịch.", "success")
    except Exception as e:
        flash(f"Lỗi khi gửi yêu cầu nạp tiền: {format_db_error(e)}", "danger")

    return redirect(url_for("billing.list_billing"))

@billing_bp.route("/billing/topup/<id>/approve", methods=["POST"])
def approve_topup(id):
    """
    Quản trị viên (Admin) đối soát sao kê ngân hàng và phê duyệt yêu cầu nạp ví.
    Cộng tiền vào ví khách hàng và ghi sổ cái bất biến GIAO_DICH_VI có chữ ký số máy chủ.
    """
    if session.get("role") != "admin":
        flash("Quyền truy cập bị từ chối: Thao tác này chỉ dành riêng cho Quản trị viên!", "danger")
        return redirect(url_for("auth.admin_login_page", next=url_for("billing.list_billing")))

    admin_name = session.get("user_name", "Quản trị viên")
    admin_id = session.get("user_id", "QTV")

    try:
        yc = query_one("SELECT MaYC, MaKH, SoTien, TrangThai, MaThamChieu, PhuongThuc FROM YEU_CAU_NAP_TIEN WHERE MaYC = %s", (id,))
        if not yc:
            flash(f"Không tìm thấy yêu cầu nạp tiền {id}!", "danger")
            return redirect(url_for("billing.list_billing"))

        if yc["TrangThai"] != "Pending":
            flash(f"Yêu cầu {id} đã được xử lý trước đó với trạng thái: {yc['TrangThai']}!", "info")
            return redirect(url_for("billing.list_billing"))

        ma_kh = yc["MaKH"]
        amount = float(yc["SoTien"])

        cust = query_one("SELECT MaKH, HoTen, SoDuViDienTu FROM KHACH_HANG WHERE MaKH = %s", (ma_kh,))
        if not cust:
            flash(f"Không tìm thấy thông tin khách hàng {ma_kh}!", "danger")
            return redirect(url_for("billing.list_billing"))

        sodu_truoc = float(cust["SoDuViDienTu"])
        sodu_sau = sodu_truoc + amount
        now = datetime.datetime.now()

        # Tạo chữ ký số và mã giao dịch
        sig = hashlib.sha256(f"{ma_kh}:{amount}:{Config.SECRET_KEY}:{now.timestamp()}".encode("utf-8")).hexdigest()
        ma_gd = f"GD_DEP_{sig[:8].upper()}"
        ref_key = f"ADM-{admin_id}-{sig[:8].upper()}"

        # 1. Cập nhật số dư ví khách hàng
        execute_statement("UPDATE KHACH_HANG SET SoDuViDienTu = %s WHERE MaKH = %s", (sodu_sau, ma_kh))

        # 2. Ghi sổ cái bất biến GIAO_DICH_VI
        note = f"Admin {admin_name} ({admin_id}) duyệt nạp tiền YC {id}. Ref: {yc.get('MaThamChieu')}"
        execute_statement("""
            INSERT INTO GIAO_DICH_VI (MaGD, MaKH, LoaiGD, SoTien, SoDuTruoc, SoDuSau, ThoiGianGD, MaGiaoDichDoiTac, GhiChu)
            VALUES (%s, %s, 'Deposit', %s, %s, %s, %s, %s, %s)
        """, (ma_gd, ma_kh, amount, sodu_truoc, sodu_sau, now, ref_key, note))

        # 3. Cập nhật trạng thái yêu cầu
        execute_statement("""
            UPDATE YEU_CAU_NAP_TIEN
            SET TrangThai = 'Approved', NguoiDuyet = %s, ThoiGianDuyet = %s, GhiChu = %s
            WHERE MaYC = %s
        """, (f"{admin_name} ({admin_id})", now, f"Đã duyệt và cộng {amount:,.0f}đ vào ví (GD: {ma_gd})", id))

        flash(f"Phê duyệt thành công yêu cầu {id}! Đã cộng {amount:,.0f}đ vào ví của khách hàng {cust['HoTen']} ({ma_kh}). Số dư mới: {sodu_sau:,.0f}đ.", "success")
    except Exception as e:
        flash(f"Lỗi khi phê duyệt nạp tiền: {format_db_error(e)}", "danger")

    return redirect(url_for("billing.list_billing"))

@billing_bp.route("/billing/topup/<id>/reject", methods=["POST"])
def reject_topup(id):
    """
    Quản trị viên từ chối yêu cầu nạp tiền (do chưa nhận được tiền hoặc thông tin sai).
    """
    if session.get("role") != "admin":
        flash("Quyền truy cập bị từ chối: Thao tác này chỉ dành riêng cho Quản trị viên!", "danger")
        return redirect(url_for("auth.admin_login_page", next=url_for("billing.list_billing")))

    admin_name = session.get("user_name", "Quản trị viên")
    admin_id = session.get("user_id", "QTV")
    ly_do = request.form.get("ly_do", "Không nhận được tiền chuyển khoản hoặc sai mã tham chiếu")
    now = datetime.datetime.now()

    try:
        execute_statement("""
            UPDATE YEU_CAU_NAP_TIEN
            SET TrangThai = 'Rejected', NguoiDuyet = %s, ThoiGianDuyet = %s, GhiChu = %s
            WHERE MaYC = %s AND TrangThai = 'Pending'
        """, (f"{admin_name} ({admin_id})", now, ly_do, id))

        flash(f"Đã từ chối yêu cầu nạp tiền {id}. Lý do: {ly_do}", "info")
    except Exception as e:
        flash(f"Lỗi khi từ chối yêu cầu: {format_db_error(e)}", "danger")

    return redirect(url_for("billing.list_billing"))

@billing_bp.route("/billing/<id>/pay_wallet", methods=["POST"])
def pay_by_wallet(id):
    current_role = session.get("role", "customer")
    is_logged_in = session.get("logged_in", False)
    current_user_id = session.get("user_id")

    if current_role == "customer" and (not is_logged_in or not current_user_id):
        flash("Vui lòng đăng nhập để thanh toán hóa đơn!", "warning")
        return redirect(url_for("auth.login_page", next=url_for("billing.list_billing")))

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
