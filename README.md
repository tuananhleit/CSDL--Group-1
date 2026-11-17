# Quản lý trạm sạc và bãi đỗ xe điện trong thành phố thông minh

Đồ án môn Cơ sở dữ liệu, Học viện Công nghệ Bưu chính Viễn thông cơ sở TP.HCM (PTITHCM).

## 1. Thông tin dự án

| Trường | Nội dung |
| --- | --- |
| Tên đề tài | Quản lý trạm sạc và bãi đỗ xe điện trong thành phố thông minh |
| Mã đề tài | 01 |
| Nhóm | Group 01 |
| Môn học | Cơ sở dữ liệu |
| Lớp / khóa | INT1313 |
| Giảng viên | Lê Hà Thành (lehathanh@ptithcm.edu.vn) |
| Công nghệ | MySQL 8.0 |

## 2. Thành viên nhóm

| STT | Họ tên | MSSV | Email |
| --- | --- | --- | --- |
| 1 | Lê Tuấn Anh | N25DCAT064 | n25dcat064@student.ptithcm.edu.vn |
| 2 | Đỗ Huy Ba | N25DCAT068 | n25dcat068@student.ptithcm.edu.vn |
| 3 | Châu Gia Bảo | N22DCAT005 | n22dcat005@student.ptithcm.edu.vn |

## 3. Nội dung repo

```
mysql/
  00_setup.sql              tạo database smart_ev_parking (utf8mb4)
  table/01..14_*.sql        mỗi file gồm CREATE TABLE và dữ liệu của bảng đó
  15_routines_triggers.sql  trigger và stored procedure
  16_roles_grants.sql       3 vai trò và phân quyền
  17_views.sql              2 view
  18_queries.sql            13 truy vấn
  run_all.sql               (tùy chọn) gộp toàn bộ script để chạy một lần
report/
  Report_group.md           báo cáo chi tiết (yêu cầu, thiết kế, cài đặt, kiểm thử)
  EER.png, luoc_do_quan_he.png   sơ đồ EER và lược đồ quan hệ
```

Dữ liệu mẫu gồm hơn 10.000 khách hàng, 9 trạm, 12.742 phiên và các bảng liên quan, nằm ngay trong từng file bảng.

## 4. Hướng dẫn cài đặt và chạy

Yêu cầu: MySQL Server 8.0 trở lên (cần hỗ trợ CHECK, cột sinh, ROLE), MySQL Workbench hoặc mysql client.

**Cách 1 — MySQL Workbench:** mở lần lượt từng file bằng File > Run SQL Script, theo đúng thứ tự:

1. `mysql/00_setup.sql`
2. `mysql/table/01_KHACH_HANG.sql` đến `14_GIAO_DICH_VI.sql` (theo số thứ tự)
3. `mysql/15_routines_triggers.sql`
4. `mysql/16_roles_grants.sql`
5. `mysql/17_views.sql`
6. `mysql/18_queries.sql` (chạy các truy vấn xem kết quả)

Hoặc chỉ chạy `mysql/run_all.sql` (file lớn, khoảng 11 MB, nạp mất vài phút).

**Cách 2 — dòng lệnh:**

```bash
mysql -u root -p --default-character-set=utf8mb4 < mysql/00_setup.sql
for f in mysql/table/*.sql; do mysql -u root -p --default-character-set=utf8mb4 smart_ev_parking < "$f"; done
mysql -u root -p --default-character-set=utf8mb4 smart_ev_parking < mysql/15_routines_triggers.sql
mysql -u root -p --default-character-set=utf8mb4 smart_ev_parking < mysql/16_roles_grants.sql
mysql -u root -p --default-character-set=utf8mb4 smart_ev_parking < mysql/17_views.sql
mysql -u root -p --default-character-set=utf8mb4 smart_ev_parking < mysql/18_queries.sql
```

Lưu ý: `00_setup.sql` xóa và tạo lại database `smart_ev_parking`. Trigger được tạo sau khi nạp dữ liệu nên dữ liệu mẫu được nạp trực tiếp.

## 5. Kiểm thử và vận hành

Mục 4 của báo cáo có 16 ca kiểm thử (câu lệnh và lỗi mong đợi) cho ràng buộc, trigger và stored procedure. Các truy vấn đối chiếu Q10, Q11, Q13 trong `18_queries.sql` phải trả về 0 dòng. Phân quyền: gán vai trò cho tài khoản bằng `GRANT app_user_role TO 'ten_tai_khoan'@'%';` (tương tự cho `station_operator_role`, `sys_admin_role`).

## 6. Tài liệu

- Báo cáo chi tiết: [report/Report_group.md](report/Report_group.md).
- Tài liệu tham khảo: R. Elmasri, S. B. Navathe, *Fundamentals of Database Systems*, 7th ed., Pearson, 2016; ISO/IEC/IEEE 29148:2018; MySQL 8.0 Reference Manual.
