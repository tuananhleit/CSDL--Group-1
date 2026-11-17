# Quản lý Trạm sạc và Bãi đỗ xe điện trong Thành phố thông minh (Smart EV Parking)

Dự án môn học: **Cơ sở dữ liệu (INT1313)** — Học viện Công nghệ Bưu chính Viễn thông (PTITHCM).  
Giảng viên hướng dẫn: **ThS. Lê Hà Thành** (`lehathanh@ptithcm.edu.vn`)

---

## 👥 Danh sách thành viên Nhóm 01

| STT | Họ và tên | Mã sinh viên | Email |
| :---: | :--- | :---: | :--- |
| 1 | **Lê Tuấn Anh** | N25DCAT064 | n25dcat064@student.ptithcm.edu.vn |
| 2 | **Đỗ Huy Ba** | N25DCAT068 | n25dcat068@student.ptithcm.edu.vn |
| 3 | **Châu Gia Bảo** | N22DCAT005 | n22dcat005@student.ptithcm.edu.vn |

---

## 📁 Cấu trúc thư mục dự án

Dự án được phân chia độc lập và khoa học thành 2 phần: **`report/`** (Tài liệu học thuật & Thiết kế) và **`sources/`** (Toàn bộ mã nguồn thực thi):

```text
csdl_gr1/
├── report/                         # Báo cáo học thuật & Sơ đồ thiết kế
│   ├── Report_Group1.md            # Báo cáo toàn văn (chuẩn ISO/IEC/IEEE 29148)
│   └── images/                     # Thư mục hình ảnh thiết kế hệ thống
│       ├── EER.png                 # Sơ đồ thực thể kết hợp mở rộng (Enhanced ER)
│       └── luoc_do_quan_he.png     # Lược đồ cơ sở dữ liệu quan hệ
│
├── sources/                        # Toàn bộ mã nguồn dự án
│   ├── database/                   # Hệ thống Cơ sở dữ liệu MySQL 8.0
│   │   ├── run_all.sql             # Kịch bản 1-click tạo DB, 14 bảng, nạp toàn bộ dữ liệu mẫu & trigger
│   │   ├── 00_setup.sql            # Tạo cơ sở dữ liệu smart_ev_parking
│   │   ├── table/                  # 14 bảng DDL chuẩn hóa 3NF/BCNF kèm dữ liệu mẫu
│   │   │   ├── 01_KHACH_HANG.sql   ... 14_GIAO_DICH_VI.sql
│   │   ├── 15_routines_triggers.sql# 17 Triggers + 5 Stored Procedures + 1 Function
│   │   ├── 16_roles_grants.sql     # Phân quyền 4 nhóm người dùng RBAC
│   │   ├── 17_views.sql            # 3 View nghiệp vụ tổng hợp dữ liệu
│   │   ├── 18_queries.sql          # 10 Truy vấn nghiệp vụ từ cơ bản đến nâng cao
│   │   └── 19_tests.sql            # 16 Ca kiểm thử tự động (Transaction an toàn)
│   │
│   ├── web_app/                    # Ứng dụng điều hành Web App (Python/Flask + TailwindCSS)
│   │   ├── app.py                  # Entry point máy chủ Flask
│   │   ├── config.py               # Quản lý cấu hình & kết nối .env
│   │   ├── db.py                   # Module thao tác CSDL MySQL
│   │   ├── requirements.txt        # Danh sách thư viện Python
│   │   ├── .env.example            # Mẫu cấu hình môi trường an toàn
│   │   ├── routes/                 # 6 Module điều hướng nghiệp vụ
│   │   └── templates/              # Giao diện responsive Dashboard
│   │
│   └── scripts/                    # Kịch bản hỗ trợ & kiểm thử
│       └── verify_project.py       # Script kiểm tra 100% khớp nối giữa báo cáo và SQL
│
├── run_app.bat                     # File 1-click khởi chạy Web App trên Windows
├── start.py                        # Script khởi động nhanh 1 lệnh và tự mở trình duyệt
├── USER_GUIDE.md                   # Hướng dẫn chi tiết sử dụng các dịch vụ hệ thống
├── .gitignore                      # Chặn rò rỉ file môi trường (.env, cache,...)
└── README.md                       # Hướng dẫn chi tiết cài đặt và sử dụng
```

---

## 🛠️ Yêu cầu môi trường (Prerequisites)

- **Cơ sở dữ liệu:** MySQL Server **8.0** trở lên (InnoDB Engine, bộ mã `utf8mb4`).
- **Ứng dụng Web:** Python **3.10** trở lên (kèm `pip`).
- **Hệ điều hành:** Hỗ trợ tốt trên Windows, macOS và Linux.

---

## 🚀 Hướng dẫn cài đặt (Installation Guide)

### Bước 1: Nạp Cơ sở dữ liệu MySQL

1. Khởi động MySQL Server trên máy tính của bạn (cổng mặc định `3306`).
2. Thực thi file tổng hợp **`sources/database/run_all.sql`**:
   - **Cách 1: Sử dụng MySQL Workbench hoặc DBeaver:**  
     Mở file `sources/database/run_all.sql` trong MySQL Workbench và nhấn **Execute (Ctrl + Shift + Enter)**.
   - **Cách 2: Sử dụng Command Prompt / PowerShell:**  
     ```bash
     mysql -u root -p < sources/database/run_all.sql
     ```
3. Sau khi thực thi, CSDL `smart_ev_parking` sẽ được tạo đầy đủ với 14 bảng dữ liệu, 17 triggers và toàn bộ dữ liệu mẫu ban đầu.

---

## 🚀 Hướng dẫn Khởi động nhanh (Quickstart)

Chỉ cần thực hiện **1 trong 2 cách** sau để khởi động toàn bộ hệ thống:

### Cách 1: Khởi động 1-click trên Windows (Khuyên dùng)
- Nhấp đúp trực tiếp vào file **`run_app.bat`** tại thư mục gốc.

### Cách 2: Khởi động bằng 1 dòng lệnh trong Terminal / PowerShell
- Mở cửa sổ Terminal tại thư mục dự án và chạy:
  ```bash
  python start.py
  ```

---

### 🔄 Quá trình tự động diễn ra:
1. **Kiểm tra CSDL:** Hệ thống tự động kết nối MySQL Server và kiểm tra CSDL `smart_ev_parking`.
2. **Khởi chạy Máy chủ Web:** Tự động nạp cấu hình và kích hoạt Flask Web Server tại `http://127.0.0.1:5000`.
3. **Tự động mở Trình duyệt Web:** Trình duyệt mặc định của bạn sẽ tự động bật lên giao diện **Dashboard Quản lý Smart EV Parking**.
4. Bạn có thể sử dụng toàn bộ tính năng (xem trạm sạc, đặt chỗ, mở phiên sạc, thanh toán hóa đơn, khám phá SQL) trực tiếp trên giao diện Web UI mà không cần thao tác thêm bằng dòng lệnh!

---

## 🖥️ Hướng dẫn sử dụng các phân hệ chính trên Web App

Sau khi khởi chạy, giao diện điều khiển cung cấp 6 phân hệ quản lý trực quan:

1. **Bảng điều khiển (Dashboard):**
   - Giám sát tổng quan theo thời gian thực: Tổng số trạm sạc, chỗ đỗ còn trống (Available), chỗ đang có xe (Occupied), số trụ sạc đang hoạt động và tổng doanh thu thu về.
   - Thống kê tỷ lệ lấp đầy bãi đỗ và phân bổ các phiên sạc đang hoạt động.

2. **Quản lý Trạm & Chỗ đỗ (Stations):**
   - Danh sách chi tiết các trạm xe điện trong thành phố.
   - Theo dõi từng vị trí đỗ (Mã chỗ, loại xe hỗ trợ: Ô tô 4 bánh hoặc Xe máy 2 bánh).
   - Bộ lọc trạng thái trực tiếp: *Available, Occupied, Reserved, Maintenance*.

3. **Quản lý Đặt chỗ (Bookings):**
   - Xem danh sách đặt chỗ trước từ khách hàng thành viên.
   - Theo dõi thời gian đặt, khung giờ đến hạn, mức tiền cọc giữ chỗ và trạng thái (Active, Completed, Cancelled, Expired).

4. **Quản lý Phiên sử dụng & Sạc pin (Sessions):**
   - Theo dõi trạng thái từng phiên sạc: Bắt đầu sạc, dung lượng điện tiêu thụ (kWh), trụ sạc kết nối.
   - Hệ thống tự ngắt sạc an toàn khi đạt hạn mức kWh hoặc chạm ngưỡng số dư ví.

5. **Lập hóa đơn & Thanh toán (Billing):**
   - Tổng hợp chi tiết tiền đỗ xe, tiền điện sạc, phí quá hạn và trừ tiền cọc giữ chỗ.
   - Hỗ trợ thanh toán trừ tiền ví điện tử (sổ cái bất biến) hoặc thanh toán khách vãng lai.

6. **Khám phá Truy vấn & Kiểm thử (Queries & Tests):**
   - Xem và thực thi trực tiếp 10 câu truy vấn nghiệp vụ phức tạp (Q1 đến Q10) từ CSDL.
   - Theo dõi kết quả 16 ca kiểm thử toàn vẹn dữ liệu (TC1 đến TC16) đảm bảo các trigger và stored procedure hoạt động chính xác.

---

## 🧪 Kiểm tra tính toàn vẹn của đồ án (Verification Script)

Dự án tích hợp sẵn công cụ tự động đối soát toàn bộ mã nguồn SQL và ứng dụng so với tài liệu báo cáo:

```bash
python sources/scripts/verify_project.py
```
Script sẽ tự động quét và xác thực:
- 100% các file thành phần có mặt đầy đủ.
- 100% cấu trúc 14 bảng DDL trong các file SQL khớp từng dòng với bảng DDL trong `report/Report_Group1.md`.
- Đầy đủ 17 Triggers, 5 Stored Procedures, 1 Hàm tính toán và 16 Ca kiểm thử.
