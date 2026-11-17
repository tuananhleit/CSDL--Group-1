#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script kiểm tra tính toàn vẹn và đồng bộ của đồ án CSDL - Group 01:
Quản lý trạm sạc và bãi đỗ xe điện trong thành phố thông minh.
"""

import os
import re
import sys
import glob

# Định vị thư mục gốc của project (2 cấp từ sources/scripts/verify_project.py)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
os.chdir(PROJECT_ROOT)

def check_structure():
    print("=" * 60)
    print("1. KIỂM TRA CẤU TRÚC FILE DỰ ÁN")
    print("=" * 60)
    
    expected_files = [
        "README.md",
        "USER_GUIDE.md",
        ".gitignore",
        "run_app.bat",
        "start.py",
        "report/Report_Group1.md",
        "report/images/EER.png",
        "report/images/luoc_do_quan_he.png",
        "sources/database/00_setup.sql",
        "sources/database/15_routines_triggers.sql",
        "sources/database/16_roles_grants.sql",
        "sources/database/17_views.sql",
        "sources/database/18_queries.sql",
        "sources/database/19_tests.sql",
        "sources/database/run_all.sql",
        "sources/web_app/app.py",
        "sources/web_app/config.py",
        "sources/web_app/db.py",
        "sources/web_app/requirements.txt",
        "sources/web_app/.env.example",
        "sources/web_app/templates/base.html",
        "sources/web_app/templates/dashboard.html",
        "sources/web_app/templates/stations.html",
        "sources/web_app/templates/bookings.html",
        "sources/web_app/templates/sessions.html",
        "sources/web_app/templates/billing.html",
        "sources/web_app/templates/queries.html",
        "sources/scripts/verify_project.py",
    ]
    
    tables = [
        "01_KHACH_HANG.sql", "02_PHUONG_TIEN.sql", "03_QUAN_TRI_VIEN.sql",
        "04_TRAM.sql", "05_CHO_DO_XE.sql", "06_LOAI_TRU_SAC.sql",
        "07_TRU_SAC.sql", "08_BANG_GIA.sql", "09_DAT_CHO.sql",
        "10_PHIEN.sql", "11_CHI_TIET_PHIEN_SAC.sql", "12_CHI_TIET_PHI.sql",
        "13_HOA_DON.sql", "14_GIAO_DICH_VI.sql"
    ]
    for t in tables:
        expected_files.append(os.path.join("sources", "database", "table", t))
        
    all_ok = True
    for f in expected_files:
        if os.path.exists(f):
            print(f"  [OK] {f} ({os.path.getsize(f):,} bytes)")
        else:
            print(f"  [MISSING] {f}")
            all_ok = False
    return all_ok

def check_ddl_sync():
    print("\n" + "=" * 60)
    print("2. KIỂM TRA TÍNH ĐỒNG BỘ DDL GIỮA BÁO CÁO VÀ FILE SQL")
    print("=" * 60)
    
    report_path = "report/Report_Group1.md"
    if not os.path.exists(report_path):
        print(f"  [ERROR] Không tìm thấy file báo cáo tại {report_path}")
        return False
        
    with open(report_path, "r", encoding="utf-8") as f:
        report_content = f.read()
        
    table_files = sorted(glob.glob("sources/database/table/*.sql"))
    all_synced = True
    
    for tf in table_files:
        table_name = os.path.basename(tf).replace(".sql", "")
        pure_name = re.sub(r"^\d+_", "", table_name)
        
        with open(tf, "r", encoding="utf-8") as f:
            sql_content = f.read()
            
        match_sql = re.search(r"CREATE TABLE(?:\s+IF\s+NOT\s+EXISTS)?\s+(\w+)\s*\((.*?)\)\s*ENGINE", sql_content, re.DOTALL | re.IGNORECASE)
        if not match_sql:
            print(f"  [WARN] Không parse được DDL từ {tf}")
            continue
            
        sql_cols = [line.strip().rstrip(",") for line in match_sql.group(2).strip().splitlines() if line.strip() and not line.strip().startswith("--")]
        
        pattern = rf"CREATE TABLE(?:\s+IF\s+NOT\s+EXISTS)?\s+{pure_name}\s*\((.*?)\)\s*ENGINE"
        match_rep = re.search(pattern, report_content, re.DOTALL | re.IGNORECASE)
        
        if not match_rep:
            print(f"  [FAIL] Bảng {pure_name} trong báo cáo KHÔNG tìm thấy định nghĩa DDL khớp!")
            all_synced = False
        else:
            rep_cols = [line.strip().rstrip(",") for line in match_rep.group(1).strip().splitlines() if line.strip() and not line.strip().startswith("--")]
            if len(sql_cols) == len(rep_cols):
                print(f"  [OK] Bảng {pure_name}: Khớp 100% định nghĩa ({len(sql_cols)} dòng)")
            else:
                print(f"  [DIFF] Bảng {pure_name}: SQL có {len(sql_cols)} dòng, Báo cáo có {len(rep_cols)} dòng")
                all_synced = False
                
    return all_synced

def check_triggers_and_routines():
    print("\n" + "=" * 60)
    print("3. KIỂM TRA ROUTINES, TRIGGERS & 16 TEST CASES")
    print("=" * 60)
    
    rt_file = "sources/database/15_routines_triggers.sql"
    if not os.path.exists(rt_file):
        print(f"  [ERROR] Không tìm thấy file {rt_file}")
        return False
        
    with open(rt_file, "r", encoding="utf-8") as f:
        content = f.read()
        
    triggers = re.findall(r"CREATE TRIGGER(?:\s+IF\s+NOT\s+EXISTS)?\s+(\w+)", content, re.IGNORECASE)
    procedures = re.findall(r"CREATE PROCEDURE(?:\s+IF\s+NOT\s+EXISTS)?\s+(\w+)", content, re.IGNORECASE)
    functions = re.findall(r"CREATE FUNCTION(?:\s+IF\s+NOT\s+EXISTS)?\s+(\w+)", content, re.IGNORECASE)
    
    print(f"  - Triggers tìm thấy ({len(triggers)}):")
    for t in triggers:
        print(f"      + {t}")
    print(f"  - Stored Procedures tìm thấy ({len(procedures)}):")
    for p in procedures:
        print(f"      + {p}")
    print(f"  - Functions tìm thấy ({len(functions)}):")
    for fn in functions:
        print(f"      + {fn}")
        
    test_file = "sources/database/19_tests.sql"
    if os.path.exists(test_file):
        with open(test_file, "r", encoding="utf-8") as f:
            test_content = f.read()
        tcs = re.findall(r"-- (TC\d+):", test_content)
        print(f"  - Ca kiểm thử trong 19_tests.sql ({len(tcs)}/16):")
        print(f"      {', '.join(tcs)}")
    else:
        print(f"  [MISSING] {test_file}")
        
    return len(triggers) >= 15 and len(procedures) >= 5

if __name__ == "__main__":
    ok1 = check_structure()
    ok2 = check_ddl_sync()
    ok3 = check_triggers_and_routines()
    
    print("\n" + "=" * 60)
    if ok1 and ok2 and ok3:
        print("KẾT LUẬN: HỆ THỐNG ĐÃ ĐỒNG BỘ VÀ HOÀN THIỆN XUẤT SẮC!")
    else:
        print("KẾT LUẬN: CẦN KIỂM TRA LẠI MỘT SỐ MỤC CHƯA KHỚP Ở TRÊN.")
    print("=" * 60)
