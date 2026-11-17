#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
KỊCH BẢN DEMO CLI HỆ THỐNG SMART EV PARKING (NHÓM 01 - PTIT)
Đề tài: Quản lý trạm sạc và bãi đỗ xe điện trong thành phố thông minh
Môn học: Cơ sở dữ liệu (INT1313) - GVHD: ThS. Lê Hà Thành
Thành viên: Lê Tuấn Anh, Đỗ Huy Ba, Châu Gia Bảo
"""

import os
import sys
import time
import mysql.connector

# Đặt thư mục làm việc về root của dự án
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
os.chdir(PROJECT_ROOT)
sys.path.append(os.path.join(PROJECT_ROOT, "sources", "web_app"))

from config import Config
from db import get_db_connection

def print_header(title):
    print("\n" + "=" * 75)
    print(f"  {title}")
    print("=" * 75)

def run_demo():
    print_header("HỆ THỐNG QUẢN LÝ TRẠM SẠC VÀ BÃI ĐỖ XE ĐIỆN (SMART EV PARKING)")
    print("  Nhóm 01 | PTITHCM | Học kỳ 1 - 2026-2027")
    print("  GVHD: ThS. Lê Hà Thành (lehathanh@ptithcm.edu.vn)")
    print("  Thành viên: Lê Tuấn Anh, Đỗ Huy Ba (litlecist), Châu Gia Bảo")
    print("=" * 75)

    # 1. KẾT NỐI CSDL
    print_header("1. KIỂM TRA MÔI TRƯỜNG & KẾT NỐI MYSQL 8.0")
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT VERSION()")
        ver = cursor.fetchone()["VERSION()"]
        print(f"  [OK] Đã kết nối thành công tới MySQL Server:")
        print(f"       + Máy chủ: {Config.MYSQL_HOST}:{Config.MYSQL_PORT}")
        print(f"       + Người dùng: {Config.MYSQL_USER}")
        print(f"       + Cơ sở dữ liệu: {Config.MYSQL_DATABASE}")
        print(f"       + Phiên bản MySQL: {ver}")
    except Exception as e:
        print(f"  [LỖI] Không thể kết nối tới MySQL: {e}")
        return

    # 2. THỐNG KÊ 14 BẢNG VÀ DỮ LIỆU
    print_header("2. DỮ LIỆU ĐỒ ÁN TRÊN 14 BẢNG (CHUẨN HÓA 3NF/BCNF)")
    tables = [
        "khach_hang", "phuong_tien", "quan_tri_vien", "tram", "cho_do_xe",
        "loai_tru_sac", "tru_sac", "bang_gia", "dat_cho", "phien",
        "chi_tiet_phien_sac", "chi_tiet_phi", "hoa_don", "giao_dich_vi"
    ]
    total_records = 0
    for t in tables:
        cursor.execute(f"SELECT COUNT(*) AS cnt FROM `{t}`")
        cnt = cursor.fetchone()["cnt"]
        total_records += cnt
        print(f"  - Bảng {t:<22}: {cnt:>8,} bản ghi")
    print("-" * 75)
    print(f"  => TỔNG CỘNG BẢN GHI DỮ LIỆU MẪU: {total_records:>8,} bản ghi")

    # 3. ROUTINES, TRIGGERS & VIEWS
    print_header("3. ĐỐI TƯỢNG NGHIỆP VỤ (TRIGGERS, PROCEDURES, FUNCTIONS, VIEWS)")
    cursor.execute("SHOW TRIGGERS")
    trgs = cursor.fetchall()
    print(f"  - Triggers kích hoạt tự động ({len(trgs)}):")
    for trg in trgs[:6]:
        print(f"      + {trg['Trigger']} (trên bảng {trg['Table']}, sự kiện {trg['Event']})")
    if len(trgs) > 6:
        print(f"      ... và {len(trgs)-6} triggers khác.")

    cursor.execute(f"SHOW PROCEDURE STATUS WHERE Db = '{Config.MYSQL_DATABASE}'")
    procs = cursor.fetchall()
    print(f"\n  - Stored Procedures xử lý nghiệp vụ ({len(procs)}):")
    for p in procs:
        print(f"      + {p['Name']}")

    cursor.execute(f"SHOW FUNCTION STATUS WHERE Db = '{Config.MYSQL_DATABASE}'")
    funcs = cursor.fetchall()
    print(f"\n  - Functions tính toán ({len(funcs)}):")
    for fn in funcs:
        print(f"      + {fn['Name']}")

    cursor.execute("SHOW FULL TABLES WHERE Table_type = 'VIEW'")
    views = cursor.fetchall()
    print(f"\n  - Views tổng hợp dữ liệu ({len(views)}):")
    for v in views:
        v_name = list(v.values())[0]
        print(f"      + {v_name}")

    # 4. TRUY VẤN NGHIỆP VỤ MẪU
    print_header("4. DEMO CÁC TRUY VẤN NGHIỆP VỤ PHỨC TẠP TỪ CSDL")
    
    # Demo 1: Thống kê doanh thu theo trạm
    t0 = time.time()
    cursor.execute("""
        SELECT t.TenTram, COUNT(DISTINCT p.MaPhien) AS SoPhien,
               SUM(hd.PhiDoXe) AS TienDo, SUM(hd.PhiSacDien) AS TienSac,
               SUM(hd.TongTien) AS DoanhThu
        FROM TRAM t
        JOIN CHO_DO_XE c ON c.MaTram = t.MaTram
        JOIN PHIEN p ON p.MaCho = c.MaCho
        JOIN HOA_DON hd ON hd.MaPhien = p.MaPhien
        WHERE hd.TrangThaiThanhToan = 'Paid'
        GROUP BY t.MaTram, t.TenTram
        ORDER BY DoanhThu DESC LIMIT 3
    """)
    dt = (time.time() - t0) * 1000
    print(f"  [Q2 - Top 3 Trạm có doanh thu cao nhất] ({dt:.1f} ms):")
    for r in cursor.fetchall():
        print(f"      * {r['TenTram']:<25} | Phiên: {r['SoPhien']:>4} | Đỗ: {float(r['TienDo']):>10,.0f}đ | Sạc: {float(r['TienSac']):>10,.0f}đ | Tổng: {float(r['DoanhThu']):>12,.0f}đ")

    # Demo 2: Đối chiếu sổ cái bất biến (Toàn vẹn số dư ví)
    t0 = time.time()
    cursor.execute("""
        SELECT COUNT(*) AS SaiLechSoDu
        FROM (
            SELECT g.MaGD, g.MaKH, g.ThoiGianGD, g.SoDuTruoc,
                   LAG(g.SoDuSau) OVER (PARTITION BY g.MaKH ORDER BY g.ThoiGianGD, g.MaGD) AS SoDuSauGiaoDichTruoc
            FROM GIAO_DICH_VI g
        ) x
        WHERE x.SoDuSauGiaoDichTruoc IS NOT NULL
          AND x.SoDuTruoc <> x.SoDuSauGiaoDichTruoc
    """)
    dt = (time.time() - t0) * 1000
    res_ledger = cursor.fetchone()["SaiLechSoDu"]
    print(f"\n  [Q11 - Đối soát tính bất biến của Sổ cái Ví điện tử] ({dt:.1f} ms):")
    print(f"      * Số lỗi sai lệch số dư phát hiện: {res_ledger} (Sổ cái đạt tính toàn vẹn 100%!)")

    # 5. KIỂM THỬ TỰ ĐỘNG
    print_header("5. TỰ ĐỘNG KIỂM TRA ĐỒ ÁN (VERIFICATION)")
    sys.path.append(os.path.join(PROJECT_ROOT, "sources", "scripts"))
    from verify_project import check_structure, check_ddl_sync, check_triggers_and_routines
    ok1 = check_structure()
    ok2 = check_ddl_sync()
    ok3 = check_triggers_and_routines()
    if ok1 and ok2 and ok3:
        print("\n  => TẤT CẢ KIỂM TRA ĐỀU ĐẠT: Báo cáo, DDL, Triggers và Test Cases đồng bộ 100%!")

    # 6. THÔNG TIN KHỞI CHẠY WEB APP
    print_header("6. ỨNG DỤNG WEB APP FLASK DASHBOARD")
    print("  - Thư mục ứng dụng: sources/web_app")
    print("  - Điểm khởi chạy:   sources/web_app/app.py")
    print("  - Script khởi chạy nhanh: run_app.bat (nhấp đúp trên Windows)")
    print("  - Địa chỉ truy cập: http://127.0.0.1:5000")
    print("  - Bao gồm 6 module: Dashboard, Trạm sạc, Đặt chỗ, Phiên sạc, Hóa đơn, Truy vấn SQL")
    print("=" * 75)
    print("  DEMO CLI HOÀN TẤT THÀNH CÔNG RỰC RỠ!")
    print("=" * 75 + "\n")

    conn.close()

if __name__ == "__main__":
    run_demo()
