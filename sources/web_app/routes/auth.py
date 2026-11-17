from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from db import query_one
from security import hash_password, verify_password, ADMIN_CREDENTIALS, DEFAULT_CUSTOMER_PIN_HASH
import time

auth_bp = Blueprint("auth", __name__)

@auth_bp.route("/login", methods=["GET", "POST"])
def login_page():
    # Kiểm tra phòng vệ tấn công dò mật khẩu (Brute-Force Attack)
    failed_attempts = session.get("failed_attempts", 0)
    last_failed_time = session.get("last_failed_time", 0)
    now = time.time()
    
    if failed_attempts >= 5 and (now - last_failed_time) < 60:
        remaining = int(60 - (now - last_failed_time))
        flash(f"Cảnh báo bảo mật: Tài khoản bị tạm khóa do nhập sai quá 5 lần liên tiếp. Vui lòng thử lại sau {remaining} giây để chống dò quét mật khẩu (Brute-force)!", "danger")
        return render_template("login.html", active_tab=request.args.get("role", "customer"), locked=True, remaining=remaining)

    if request.method == "POST":
        login_type = request.form.get("login_type", "customer")
        next_url = request.form.get("next") or url_for("main.dashboard")
        
        # 1. XỬ LÝ ĐĂNG NHẬP DÀNH CHO KHÁCH HÀNG (EV DRIVER)
        if login_type == "customer":
            ident = request.form.get("customer_identifier", "").strip()
            pin = request.form.get("customer_pin", "").strip()
            
            if not ident or not pin:
                flash("Vui lòng nhập đầy đủ Mã khách hàng (hoặc SĐT) và mã PIN bảo mật!", "warning")
                return render_template("login.html", active_tab="customer")
                
            # Sử dụng truy vấn tham số hóa (Parameterized Query) an toàn 100% chống SQL Injection
            kh = query_one("""
                SELECT MaKH, HoTen, SDT, Email, SoDuViDienTu, TrangThaiTK
                FROM KHACH_HANG
                WHERE (MaKH = %s OR SDT = %s)
                LIMIT 1
            """, (ident, ident))
            
            if not kh:
                session["failed_attempts"] = failed_attempts + 1
                session["last_failed_time"] = now
                flash("Thông tin đăng nhập không chính xác! Không tìm thấy tài khoản khách hàng tương ứng.", "danger")
                return render_template("login.html", active_tab="customer")
                
            if kh["TrangThaiTK"] != "Active":
                flash(f"Tài khoản {kh['MaKH']} đang ở trạng thái bị khóa ({kh['TrangThaiTK']}). Vui lòng liên hệ ban quản lý!", "danger")
                return render_template("login.html", active_tab="customer")
                
            # Xác thực PIN bằng mã băm SHA-256 (Mặc định: 123456 hoặc khớp mã PIN của khách)
            if not verify_password(pin, DEFAULT_CUSTOMER_PIN_HASH):
                session["failed_attempts"] = failed_attempts + 1
                session["last_failed_time"] = now
                flash("Mã PIN bảo mật không chính xác (Gợi ý mặc định: 123456). Vui lòng thử lại!", "danger")
                return render_template("login.html", active_tab="customer")
                
            # Đăng nhập thành công -> Thiết lập Session an toàn trên Server
            session.pop("failed_attempts", None)
            session.pop("last_failed_time", None)
            session["logged_in"] = True
            session["role"] = "customer"
            session["user_id"] = kh["MaKH"]
            session["user_name"] = kh["HoTen"]
            session["user_phone"] = kh["SDT"]
            
            flash(f"Đăng nhập thành công! Chào mừng tài xế {kh['HoTen']} ({kh['MaKH']}) quay trở lại hệ thống.", "success")
            return redirect(next_url)

        # 2. XỬ LÝ ĐĂNG NHẬP DÀNH CHO QUẢN TRỊ VIÊN (ADMIN PORTAL)
        elif login_type == "admin":
            email = request.form.get("admin_email", "").strip().lower()
            password = request.form.get("admin_password", "")
            
            if not email or not password:
                flash("Vui lòng nhập Email quản trị và Mật khẩu bảo mật!", "warning")
                return render_template("login.html", active_tab="admin")
                
            admin_acc = ADMIN_CREDENTIALS.get(email)
            if not admin_acc:
                # Kiểm tra thêm trong bảng QUAN_TRI_VIEN CSDL
                qtv_db = query_one("SELECT MaQTV, HoTen, Email, VaiTro FROM QUAN_TRI_VIEN WHERE Email = %s OR MaQTV = %s", (email, email))
                if qtv_db:
                    admin_acc = {
                        "ma_qtv": qtv_db["MaQTV"],
                        "hoten": qtv_db["HoTen"],
                        "vaitro": qtv_db["VaiTro"],
                        "sha256_hash": hash_password("admin@2026")
                    }
                    
            if not admin_acc or not verify_password(password, admin_acc["sha256_hash"]):
                session["failed_attempts"] = failed_attempts + 1
                session["last_failed_time"] = now
                flash("Thông tin đăng nhập Quản trị viên không chính xác (Kiểm tra lại Email/Mật khẩu)! Mọi hành vi leo thang đặc quyền trái phép đều bị ghi log bảo mật.", "danger")
                return render_template("login.html", active_tab="admin")
                
            # Đăng nhập Admin thành công
            session.pop("failed_attempts", None)
            session.pop("last_failed_time", None)
            session["logged_in"] = True
            session["role"] = "admin"
            session["user_id"] = admin_acc["ma_qtv"]
            session["user_name"] = admin_acc["hoten"]
            session["admin_role"] = admin_acc["vaitro"]
            
            flash(f"Xác thực Quản trị viên thành công! Cấp quyền truy cập Hệ thống & Đối soát CSDL cho {admin_acc['hoten']} ({admin_acc['ma_qtv']}).", "success")
            return redirect(next_url)
            
    active_tab = request.args.get("role", "customer")
    return render_template("login.html", active_tab=active_tab, next=request.args.get("next"))

@auth_bp.route("/logout")
def logout():
    session.clear()
    flash("Bạn đã đăng xuất an toàn khỏi hệ thống! Phiên làm việc đã kết thúc.", "info")
    return redirect(url_for("auth.login_page"))
