from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from db import query_one, execute_statement
from security import hash_password, verify_password, ADMIN_CREDENTIALS, get_customer_pin_hash, save_customer_credential
from config import Config
import time
import datetime
import hashlib

auth_bp = Blueprint("auth", __name__)

@auth_bp.route("/register", methods=["GET", "POST"])
def register_page():
    if request.method == "POST":
        ho_ten = request.form.get("ho_ten", "").strip()
        sdt = request.form.get("sdt", "").strip()
        email = request.form.get("email", "").strip().lower()
        pin = request.form.get("pin", "").strip()
        confirm_pin = request.form.get("confirm_pin", "").strip()
        try:
            so_du = float(request.form.get("so_du", 0) or 0)
        except ValueError:
            so_du = 0.0

        bien_so = request.form.get("bien_so", "").strip().upper()
        loai_xe = request.form.get("loai_xe", "Car_4W")
        chuan_sac = request.form.get("chuan_sac", "CCS2")
        hang_xe = request.form.get("hang_xe", "").strip() or "VinFast VF8"
        try:
            cong_suat = float(request.form.get("cong_suat", 150.0) or 150.0)
        except ValueError:
            cong_suat = 150.0

        # 1. Kiểm tra tính hợp lệ của dữ liệu đầu vào
        if not ho_ten or not sdt or not email or not pin or not bien_so:
            flash("Vui lòng điền đầy đủ các trường thông tin bắt buộc!", "warning")
            return render_template("register.html")

        if len(pin) < 6:
            flash("Mã PIN bảo mật phải có độ dài tối thiểu 6 ký tự số!", "warning")
            return render_template("register.html")

        if pin != confirm_pin:
            flash("Mã PIN xác nhận không trùng khớp! Vui lòng nhập lại.", "danger")
            return render_template("register.html")

        # 2. Kiểm tra trùng lặp trên CSDL (Unique checks)
        dup_sdt = query_one("SELECT MaKH FROM KHACH_HANG WHERE SDT = %s", (sdt,))
        if dup_sdt:
            flash(f"Số điện thoại {sdt} đã được đăng ký cho tài khoản {dup_sdt['MaKH']}!", "danger")
            return render_template("register.html")

        dup_email = query_one("SELECT MaKH FROM KHACH_HANG WHERE Email = %s", (email,))
        if dup_email:
            flash(f"Địa chỉ Email {email} đã được sử dụng cho tài khoản khác!", "danger")
            return render_template("register.html")

        dup_xe = query_one("SELECT MaXe FROM PHUONG_TIEN WHERE BienSo = %s", (bien_so,))
        if dup_xe:
            flash(f"Biển số xe {bien_so} đã tồn tại trong hệ thống (Mã xe: {dup_xe['MaXe']})!", "danger")
            return render_template("register.html")

        now = datetime.datetime.now()

        # 3. Tự động sinh ID mới nhất
        res_kh = query_one("SELECT MAX(CAST(SUBSTRING(MaKH, 3) AS UNSIGNED)) as max_id FROM KHACH_HANG")
        new_kh_num = (res_kh["max_id"] or 20093) + 1
        ma_kh = f"KH{new_kh_num}"

        res_xe = query_one("SELECT MAX(CAST(SUBSTRING(MaXe, 3) AS UNSIGNED)) as max_id FROM PHUONG_TIEN")
        new_xe_num = (res_xe["max_id"] or 22582) + 1
        ma_xe = f"XE{new_xe_num}"

        try:
            # Mã hóa PIN bằng SHA-256 có Salt
            pin_hash = hash_password(pin)
            save_customer_credential(ma_kh, sdt, pin_hash)

            # Thêm khách hàng vào KHACH_HANG
            execute_statement("""
                INSERT INTO KHACH_HANG (MaKH, HoTen, SDT, Email, LoaiKhach, SoDuViDienTu, TrangThaiTK, NgayDangKy)
                VALUES (%s, %s, %s, %s, 'Registered', %s, 'Active', %s)
            """, (ma_kh, ho_ten, sdt, email, so_du, now))

            # Thêm phương tiện vào PHUONG_TIEN
            execute_statement("""
                INSERT INTO PHUONG_TIEN (MaXe, BienSo, MaKH, LoaiXe, ChuanSac, HangXe, CongSuatSacToiDa_kW, BiDenKhoa)
                VALUES (%s, %s, %s, %s, %s, %s, %s, FALSE)
            """, (ma_xe, bien_so, ma_kh, loai_xe, chuan_sac, hang_xe, cong_suat))

            # Ghi nhận giao dịch nạp tiền ban đầu vào sổ cái GIAO_DICH_VI nếu có số dư > 0
            if so_du > 0:
                sig = hashlib.sha256(f"{ma_kh}:{so_du}:{Config.SECRET_KEY}:{time.time()}".encode("utf-8")).hexdigest()
                ma_gd = f"GD_DEP_{sig[:8].upper()}"
                partner_key = f"INIT-{sig[:16].upper()}"
                execute_statement("""
                    INSERT INTO GIAO_DICH_VI (MaGD, MaKH, LoaiGD, SoTien, SoDuTruoc, SoDuSau, MaGiaoDichDoiTac, GhiChu)
                    VALUES (%s, %s, 'Deposit', %s, 0.00, %s, %s, 'Nạp tiền khởi tạo tài khoản ví EV mới')
                """, (ma_gd, ma_kh, so_du, so_du, partner_key))

            # Tự động đăng nhập cho tài khoản mới
            session["logged_in"] = True
            session["role"] = "customer"
            session["user_id"] = ma_kh
            session["user_name"] = ho_ten
            session["user_phone"] = sdt

            flash(f"Tạo tài khoản thành công! Mã khách hàng: {ma_kh}. Phương tiện {bien_so} ({chuan_sac}) đã sẵn sàng sử dụng dịch vụ.", "success")
            return redirect(url_for("main.dashboard"))
        except Exception as e:
            flash(f"Lỗi khi đăng ký tài khoản: {str(e)}", "danger")
            return render_template("register.html")

    return render_template("register.html")

@auth_bp.route("/login", methods=["GET", "POST"])
def login_page():
    """
    Cổng Đăng Nhập Dành Riêng Cho Khách Hàng (Tài Xế EV).
    Tách biệt hoàn toàn khỏi Cổng Quản Trị Viên (Admin Portal).
    """
    failed_attempts = session.get("failed_attempts_customer", 0)
    last_failed_time = session.get("last_failed_time_customer", 0)
    now = time.time()
    
    if failed_attempts >= 5 and (now - last_failed_time) < 60:
        remaining = int(60 - (now - last_failed_time))
        flash(f"Cảnh báo bảo mật: Nhập sai mã PIN quá 5 lần. Vui lòng thử lại sau {remaining} giây để chống dò quét (Brute-force)!", "danger")
        return render_template("login.html", locked=True, remaining=remaining)

    if request.method == "POST":
        ident = request.form.get("customer_identifier", "").strip()
        pin = request.form.get("customer_pin", "").strip()
        next_url = request.form.get("next") or url_for("main.dashboard")
        
        if not ident or not pin:
            flash("Vui lòng nhập đầy đủ Mã khách hàng (hoặc SĐT) và mã PIN bảo mật!", "warning")
            return render_template("login.html")
            
        kh = query_one("""
            SELECT MaKH, HoTen, SDT, Email, SoDuViDienTu, TrangThaiTK
            FROM KHACH_HANG
            WHERE (MaKH = %s OR SDT = %s)
            LIMIT 1
        """, (ident, ident))
        
        if not kh:
            session["failed_attempts_customer"] = failed_attempts + 1
            session["last_failed_time_customer"] = now
            flash("Thông tin đăng nhập không chính xác! Không tìm thấy tài khoản khách hàng tương ứng.", "danger")
            return render_template("login.html")
            
        if kh["TrangThaiTK"] != "Active":
            flash(f"Tài khoản {kh['MaKH']} đang ở trạng thái bị khóa ({kh['TrangThaiTK']}). Vui lòng liên hệ ban quản lý!", "danger")
            return render_template("login.html")
            
        expected_hash = get_customer_pin_hash(kh["MaKH"])
        if not verify_password(pin, expected_hash) and not verify_password(pin, get_customer_pin_hash(ident)):
            session["failed_attempts_customer"] = failed_attempts + 1
            session["last_failed_time_customer"] = now
            flash("Mã PIN bảo mật không chính xác. Vui lòng kiểm tra lại!", "danger")
            return render_template("login.html")
            
        # Đăng nhập thành công -> Thiết lập Session Khách Hàng
        session.pop("failed_attempts_customer", None)
        session.pop("last_failed_time_customer", None)
        session["logged_in"] = True
        session["role"] = "customer"
        session["user_id"] = kh["MaKH"]
        session["user_name"] = kh["HoTen"]
        session["user_phone"] = kh["SDT"]
        
        flash(f"Đăng nhập thành công! Chào mừng tài xế {kh['HoTen']} ({kh['MaKH']}) quay trở lại hệ thống.", "success")
        return redirect(next_url)

    return render_template("login.html", next=request.args.get("next"))

@auth_bp.route("/admin/login", methods=["GET", "POST"])
def admin_login_page():
    """
    Cổng Đăng Nhập Nội Bộ Dành Riêng Cho Quản Trị Viên (Admin Portal).
    Bảo vệ độc lập, kiểm soát an ninh nghiêm ngặt và không để chung với phía Client.
    """
    failed_attempts = session.get("failed_attempts_admin", 0)
    last_failed_time = session.get("last_failed_time_admin", 0)
    now = time.time()
    
    if failed_attempts >= 5 and (now - last_failed_time) < 60:
        remaining = int(60 - (now - last_failed_time))
        flash(f"Cảnh báo an ninh Quản trị: Phát hiện dò mật khẩu. Tạm khóa cổng đăng nhập Admin trong {remaining} giây!", "danger")
        return render_template("admin_login.html", locked=True, remaining=remaining)

    if request.method == "POST":
        email = request.form.get("admin_email", "").strip().lower()
        password = request.form.get("admin_password", "")
        next_url = request.form.get("next") or url_for("main.dashboard")
        
        if not email or not password:
            flash("Vui lòng nhập Email quản trị và Mật khẩu bảo mật!", "warning")
            return render_template("admin_login.html")
            
        admin_acc = ADMIN_CREDENTIALS.get(email)
        if not admin_acc:
            qtv_db = query_one("SELECT MaQTV, HoTen, Email, VaiTro FROM QUAN_TRI_VIEN WHERE Email = %s OR MaQTV = %s", (email, email))
            if qtv_db:
                admin_acc = {
                    "ma_qtv": qtv_db["MaQTV"],
                    "hoten": qtv_db["HoTen"],
                    "vaitro": qtv_db["VaiTro"],
                    "sha256_hash": hash_password("admin@2026")
                }
                
        if not admin_acc or not verify_password(password, admin_acc["sha256_hash"]):
            session["failed_attempts_admin"] = failed_attempts + 1
            session["last_failed_time_admin"] = now
            flash("Thông tin đăng nhập Quản trị viên không chính xác! Mọi hành vi leo thang đặc quyền đều bị ghi vết an ninh.", "danger")
            return render_template("admin_login.html")
            
        # Đăng nhập Admin thành công
        session.pop("failed_attempts_admin", None)
        session.pop("last_failed_time_admin", None)
        session["logged_in"] = True
        session["role"] = "admin"
        session["user_id"] = admin_acc["ma_qtv"]
        session["user_name"] = admin_acc["hoten"]
        session["admin_role"] = admin_acc["vaitro"]
        
        flash(f"Xác thực Quản trị viên thành công! Cấp quyền Điều phối & Kiểm toán CSDL cho {admin_acc['hoten']} ({admin_acc['ma_qtv']}).", "success")
        return redirect(next_url)

    return render_template("admin_login.html", next=request.args.get("next"))

@auth_bp.route("/logout")
def logout():
    was_admin = (session.get("role") == "admin")
    session.clear()
    flash("Bạn đã đăng xuất an toàn khỏi hệ thống! Phiên làm việc đã kết thúc.", "info")
    if was_admin:
        return redirect(url_for("auth.admin_login_page"))
    return redirect(url_for("auth.login_page"))
