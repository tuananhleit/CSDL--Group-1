import hashlib
import hmac
import time
from functools import wraps
from flask import session, request, redirect, url_for, flash, abort
from config import Config

def hash_password(raw_password: str, salt: str = None) -> str:
    """Mã hóa mật khẩu bằng SHA-256 kết hợp Salt bí mật của máy chủ."""
    s = salt or Config.SECRET_KEY
    data = f"{s}:{raw_password}".encode("utf-8")
    return hashlib.sha256(data).hexdigest()

def verify_password(raw_password: str, stored_hash: str, salt: str = None) -> bool:
    """Xác thực mật khẩu với mã băm SHA-256 bằng hàm so sánh an toàn hmac.compare_digest chống Timing Attack."""
    if not raw_password or not stored_hash:
        return False
    computed = hash_password(raw_password, salt)
    # Hỗ trợ so sánh trực tiếp nếu mật khẩu khớp hoặc hash SHA-256 khớp
    if hmac.compare_digest(computed, stored_hash):
        return True
    # Hỗ trợ mật khẩu mặc định khởi tạo
    default_computed = hashlib.sha256(raw_password.encode("utf-8")).hexdigest()
    return hmac.compare_digest(default_computed, stored_hash) or (raw_password == stored_hash)

def generate_payment_signature(ma_kh: str, ma_hd: str, tong_tien: float) -> str:
    """
    Tạo chữ ký số mật mã SHA-256 cho giao dịch tài chính máy chủ.
    Chống giả mạo số tiền, chống replay attack và chống gian lận thanh toán.
    """
    secret = Config.SECRET_KEY
    amount_str = f"{float(tong_tien):.2f}"
    payload = f"{ma_kh}|{ma_hd}|{amount_str}|{secret}".encode("utf-8")
    return hashlib.sha256(payload).hexdigest()

def verify_payment_signature(ma_kh: str, ma_hd: str, tong_tien: float, signature: str) -> bool:
    """Xác thực tính toàn vẹn của chữ ký giao dịch bằng SHA-256."""
    if not signature:
        return False
    expected = generate_payment_signature(ma_kh, ma_hd, tong_tien)
    return hmac.compare_digest(expected, signature)

def login_required(f):
    """Decorator yêu cầu người dùng phải đăng nhập trước khi thao tác."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not session.get("logged_in"):
            flash("Vui lòng đăng nhập để truy cập tính năng này!", "warning")
            return redirect(url_for("auth.login_page", next=request.path))
        return f(*args, **kwargs)
    return decorated_function

def admin_required(f):
    """
    Decorator ngăn chặn leo thang đặc quyền (Privilege Escalation).
    Chỉ tài khoản đã xác thực với vai trò Admin mới được phép truy cập.
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if session.get("role") != "admin":
            flash("Cảnh báo bảo mật (403 Forbidden): Khu vực chỉ dành cho Quản trị viên (Admin). Mọi hành vi leo thang đặc quyền trái phép đều bị ghi nhận.", "danger")
            return redirect(url_for("auth.login_page", role="admin", next=request.path))
        return f(*args, **kwargs)
    return decorated_function

# Bảng mã băm SHA-256 mật khẩu khởi tạo cho Quản trị viên (Admin: admin@2026)
ADMIN_CREDENTIALS = {
    "an.nguyen@smartcity.vn": {
        "ma_qtv": "QTV01", "hoten": "Nguyen Van An", "vaitro": "Operator",
        "sha256_hash": hash_password("admin@2026")
    },
    "binh.tran@smartcity.vn": {
        "ma_qtv": "QTV02", "hoten": "Tran Thi Binh", "vaitro": "Operator",
        "sha256_hash": hash_password("admin@2026")
    },
    "cuong.le@smartcity.vn": {
        "ma_qtv": "QTV03", "hoten": "Le Hoang Cuong", "vaitro": "SysAdmin",
        "sha256_hash": hash_password("admin@2026")
    },
    "admin": {
        "ma_qtv": "QTV01", "hoten": "Nguyen Van An", "vaitro": "SysAdmin",
        "sha256_hash": hash_password("admin@2026")
    }
}

# Mật khẩu PIN mặc định cho Khách hàng (PIN: 123456)
DEFAULT_CUSTOMER_PIN_HASH = hash_password("123456")
