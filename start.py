#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HỆ THỐNG SMART EV PARKING - KHỞI ĐỘNG NHANH 1 LỆNH (NHÓM 01 - PTIT)
Đề tài: Quản lý trạm sạc và bãi đỗ xe điện trong thành phố thông minh
Môn học: Cơ sở dữ liệu (INT1313) - GVHD: ThS. Lê Hà Thành
Thành viên: Lê Tuấn Anh, Đỗ Huy Ba, Châu Gia Bảo

Cách dùng:
  Chỉ cần chạy lệnh: python start.py
  (Hoặc nhấp đúp file run_app.bat trên Windows)
  Hệ thống sẽ tự nạp cấu hình, kết nối CSDL và tự động mở trình duyệt web lên để sử dụng.
"""

import os
import sys
import time
import threading
import webbrowser
import shutil

# Định vị thư mục gốc và thư mục web_app
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
WEB_APP_DIR = os.path.join(PROJECT_ROOT, "sources", "web_app")
sys.path.insert(0, WEB_APP_DIR)

# Khởi tạo file .env từ .env.example nếu chưa có
env_path = os.path.join(WEB_APP_DIR, ".env")
if not os.path.exists(env_path):
    example_path = os.path.join(WEB_APP_DIR, ".env.example")
    if os.path.exists(example_path):
        shutil.copyfile(example_path, env_path)

from config import Config
import mysql.connector

def print_banner():
    print("=" * 70)
    print("   HỆ THỐNG QUẢN LÝ TRẠM SẠC & BÃI ĐỖ XE ĐIỆN (SMART EV PARKING)")
    print("   Nhóm 01 | PTITHCM | GVHD: ThS. Lê Hà Thành")
    print("   Thành viên: Lê Tuấn Anh - Đỗ Huy Ba - Châu Gia Bảo")
    print("=" * 70)

def check_and_init_database():
    print("\n[*] [1/3] Kiểm tra kết nối Cơ sở dữ liệu MySQL...")
    try:
        conn = mysql.connector.connect(
            host=Config.MYSQL_HOST,
            port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER,
            password=Config.MYSQL_PASSWORD
        )
        cursor = conn.cursor()
        cursor.execute(f"SHOW DATABASES LIKE '{Config.MYSQL_DATABASE}'")
        db_exists = cursor.fetchone()
        
        if not db_exists:
            print(f"[*] Chưa tìm thấy CSDL '{Config.MYSQL_DATABASE}', đang tự động tạo...")
            cursor.execute(f"CREATE DATABASE `{Config.MYSQL_DATABASE}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
            print(f"[OK] Đã tạo CSDL '{Config.MYSQL_DATABASE}'.")
            
        conn.database = Config.MYSQL_DATABASE
        cursor.execute("SHOW TABLES")
        tables = cursor.fetchall()
        print(f"[OK] Cơ sở dữ liệu '{Config.MYSQL_DATABASE}' sẵn sàng ({len(tables)} bảng thực thể)!")
        conn.close()
    except Exception as e:
        print(f"[CẢNH BÁO] Không kết nối được MySQL ({e}).")
        print("  -> Bạn có thể mở file sources/web_app/.env để chỉnh lại mật khẩu MySQL.")

def auto_open_browser(url):
    time.sleep(1.2)
    print(f"[*] [3/3] Đang tự động mở trình duyệt web...")
    try:
        webbrowser.open(url)
    except Exception:
        pass

def main():
    print_banner()
    check_and_init_database()
    
    port = int(os.environ.get("PORT", 5000))
    url = f"http://127.0.0.1:{port}"
    
    print(f"\n[*] [2/3] Đang khởi chạy Flask Web Application Server...")
    print("=" * 70)
    print(f"   Ứng dụng đang hoạt động tại địa chỉ: {url}")
    print("   Trình duyệt web sẽ tự động mở lên trong giây lát...")
    print("   Nhấn Ctrl+C trong cửa sổ này khi muốn dừng máy chủ.")
    print("=" * 70 + "\n")
    
    # Kích hoạt mở trình duyệt tự động
    threading.Thread(target=auto_open_browser, args=(url,), daemon=True).start()
    
    from app import create_app
    app = create_app()
    app.run(host="0.0.0.0", port=port, debug=False)

if __name__ == "__main__":
    main()
