# BÁO CÁO NHÓM 01 - BẢN 1410
## Smart City EV Charging & Parking Management System

---

## 1. Thông tin đề tài

- **Tên đề tài:** Smart City EV Charging & Parking Management System
- **Mã đề tài:** 01
- **Nhóm:** Group 01
- **Nguồn hợp nhất:** `Report_Group1_1310.docx`, `Report_Group1_2209.docx`, `Report_Group1_Refined.md`

> **Ghi chú trích xuất DOCX:** Nội dung DOCX được đọc lại từ dữ liệu văn bản trong repository. Một số đoạn định dạng Word (hình, bố cục trang, caption) có thể không giữ nguyên 100%; báo cáo 1410 ưu tiên đồng bộ với schema SQL chuẩn trong `mysql/1410/`.

---

## 2. Giới thiệu đề tài dưới góc độ khách hàng/người dùng dịch vụ

Từ góc nhìn khách hàng, hệ thống này giải quyết một bài toán rất thực tế: **đến trạm nhanh, tìm đúng chỗ, sạc đúng trụ, trả tiền minh bạch, rời trạm thuận tiện**.

Nhu cầu chính của người dùng:

1. Biết còn chỗ trống hay không và loại chỗ phù hợp xe của mình.
2. Có thể **đặt chỗ trước** để giảm rủi ro hết chỗ.
3. Dùng được cả hai nhu cầu:
   - **Chỉ đỗ xe** (`ParkingOnly`)
   - **Đỗ + sạc** (`ParkingAndCharging`)
4. Thanh toán linh hoạt:
   - Thành viên: ví điện tử (`Wallet`)
   - Vãng lai: `POS_Card`, `Dynamic_QR`, `Cash`
5. Hệ thống công bằng khi có đông người dùng đồng thời, không để xảy ra trùng chỗ/trùng trụ.
6. Có cơ chế xử lý sau sạc (ân hạn, phí quá hạn) để tránh chiếm dụng trụ.

Bản 1410 hướng đến trải nghiệm “dùng được ngoài thực tế”, không chỉ đúng mô hình dữ liệu.

---

## 3. Hợp nhất điểm mạnh của 1310 và 2209 trong bản 1410

Bản 1410 giữ và chuẩn hóa các điểm tốt của hai bản trước:

- Quản lý khách hàng `Registered` và `WalkIn`.
- Một khách có thể quản lý nhiều phương tiện.
- Hỗ trợ phân luồng chỗ đỗ ô tô (`CarSlot`) và xe máy điện (`MotorbikeSlot`).
- Có đặt chỗ (`DAT_CHO`) và phiên dịch vụ (`PHIEN`).
- Tách rõ phiên đỗ/sạc qua `LoaiPhien` và `CHI_TIET_PHIEN_SAC`.
- Tính phí nhiều khoản mục (`CHI_TIET_PHI`, `BANG_GIA`).
- Hóa đơn (`HOA_DON`) và sổ cái ví (`GIAO_DICH_VI`) nhất quán hơn.
- Thanh toán đa phương thức: `Wallet`, `POS_Card`, `Dynamic_QR`, `Cash`.
- Cơ chế blacklist phương tiện (`PHUONG_TIEN.BiDenKhoa`).
- Quản lý trạng thái trụ sạc và bảo trì.
- Kiểm tra tương thích chuẩn sạc (`ChuanSac` vs `ChuanKetNoi`).
- Hỗ trợ ân hạn sau sạc (`ThoiGianHetAnHan`).
- RBAC theo vai trò vận hành.

---

## 4. Các lỗi/thiếu sót của 1310 và 2209 đã được khắc phục ở 1410

### 4.1 Xác minh chủ sở hữu hóa đơn trước khi thanh toán ví

- Đã xử lý trong procedure: `sp_thanh_toan_hoa_don_vi`.
- Kiểm tra chủ sở hữu hóa đơn theo chuỗi:
  `HOA_DON -> PHIEN -> PHUONG_TIEN -> KHACH_HANG`.
- Chặn trường hợp khách A trả nhầm/chi trả hóa đơn của khách B.

### 4.2 Idempotency cho thanh toán (retry không trừ tiền hai lần)

- Vẫn dùng khóa đối tác `MaGiaoDichDoiTac`.
- Trong `sp_thanh_toan_hoa_don_vi` đã thêm logic:
  - Cùng key + cùng `MaHD` => retry thành công, **không trừ ví lần 2**.
  - Cùng key + khác `MaHD` => báo lỗi nghiệp vụ.

### 4.3 Chống dùng trùng trụ sạc/chỗ đỗ trong cạnh tranh

- Chỗ đỗ/xe: unique partial index trên phiên active và đặt chỗ active.
- Trụ sạc: unique partial index `UQ_ChiTietPhienSac_Tru_Charging`.
- Trigger kiểm tra trụ chỉ cho phép bắt đầu khi `TRU_SAC.TrangThaiTru = 'Available'`.
- Có `FOR UPDATE` để giảm race condition.

### 4.4 Không cho `ParkingOnly` tạo chi tiết sạc

- Trigger `fn_check_tru_sac_truoc_khi_sac` chặn `CHI_TIET_PHIEN_SAC` nếu phiên không phải `ParkingAndCharging`.

### 4.5 Giải phóng tài nguyên chỉ khi không còn phiên active khác

- Trigger đồng bộ trạng thái (`fn_sync_trangthai_phien`, `fn_sync_trangthai_tru_sac`) chỉ trả `CHO_DO_XE/TRU_SAC` về `Available` khi không còn phiên/chi tiết sạc active liên quan.

### 4.6 Kiểm tra phương thức và loại khách trong thanh toán walk-in

- Procedure `sp_thanh_toan_walkin_ngoai` chỉ nhận `POS_Card`, `Dynamic_QR`, `Cash`.
- Với `POS_Card`/`Dynamic_QR` bắt buộc có `MaGiaoDichNgoai`.
- Chỉ cho hóa đơn thuộc khách `WalkIn` đi theo luồng này.

### 4.7 Kiểm tra nhất quán hóa đơn, ledger, khấu trừ, tổng tiền, thời gian thanh toán

- `HOA_DON`: ràng buộc tổng tiền không âm, `TienKhauTru` không vượt tổng phí, trạng thái thanh toán khớp `NgayThanhToan`.
- `GIAO_DICH_VI`: kiểm tra `SoDuTruoc/SoDuSau` theo từng loại giao dịch (`Deposit/Payment/Refund/DirectPayment`).
- Trigger bảo vệ sổ cái ví theo hướng append-only (cấm update/delete).

### 4.8 Trigger bao phủ các đường INSERT/UPDATE quan trọng

- Nhiều trigger đã áp cho cả `INSERT` và `UPDATE OF ...` ở các điểm nhạy cảm:
  - kiểm tra loại xe-loại chỗ,
  - bảo trì,
  - khóa đen,
  - đồng bộ trạng thái,
  - kiểm tra phiên/đặt chỗ,
  - kiểm tra trụ & trạng thái sạc.

---

## 5. Kiến trúc dữ liệu bản 1410 (đồng bộ theo `mysql/1410/`)

## 5.1 Bộ SQL chuẩn sử dụng

- Nguồn triển khai chuẩn: `mysql/1410/00_FULL_DDL.sql`
- Thành phần chính:
  - `01..14`: bảng dữ liệu
  - `15_TRIGGERS.sql`: trigger/function cưỡng chế nghiệp vụ
  - `16_RBAC.sql`: phân quyền
  - `17_PROCEDURES.sql`: thủ tục vận hành/thanh toán

## 5.2 Danh sách bảng lõi

| Nhóm | Bảng |
|---|---|
| Khách hàng & xe | `KHACH_HANG`, `PHUONG_TIEN` |
| Quản trị trạm | `QUAN_TRI_VIEN`, `TRAM` |
| Hạ tầng đỗ/sạc | `CHO_DO_XE`, `LOAI_TRU_SAC`, `TRU_SAC` |
| Giá & đặt chỗ | `BANG_GIA`, `DAT_CHO` |
| Phiên & phí | `PHIEN`, `CHI_TIET_PHIEN_SAC`, `CHI_TIET_PHI` |
| Hóa đơn & ví | `HOA_DON`, `GIAO_DICH_VI` |

## 5.3 Quan hệ chính

- `KHACH_HANG (1) - (N) PHUONG_TIEN`
- `TRAM (1) - (N) CHO_DO_XE`
- `CHO_DO_XE (1) - (0..1) TRU_SAC`
- `PHUONG_TIEN (1) - (N) DAT_CHO`, `PHUONG_TIEN (1) - (N) PHIEN`
- `PHIEN (1) - (0..1) CHI_TIET_PHIEN_SAC`
- `PHIEN (1) - (N) CHI_TIET_PHI`
- `PHIEN (1) - (1) HOA_DON`
- `KHACH_HANG (1) - (N) GIAO_DICH_VI`
- `HOA_DON (1) - (N) GIAO_DICH_VI` (đối soát)

## 5.4 Ràng buộc quan trọng

- PK/FK đầy đủ ở toàn bộ 14 bảng.
- Unique index chống trùng phiên/đặt chỗ active.
- Unique cho giao dịch ngoài và key đối tác.
- CHECK cho trạng thái, thời gian, số dư, tổng tiền, khấu trừ, loại phí.

## 5.5 Trigger, procedure, RBAC

- **Trigger/function:** tập trung trong `15_TRIGGERS.sql`.
- **Procedure:**
  - `sp_kiem_tra_va_ngat_sac_tu_dong`
  - `sp_thanh_toan_hoa_don_vi`
  - `sp_thanh_toan_walkin_ngoai`
  - `sp_xu_ly_dat_cho_qua_han`
- **RBAC (`16_RBAC.sql`):**
  - `app_user_role`
  - `station_operator_role`
  - `sys_admin_role`

---

## 6. Luồng nghiệp vụ khách hàng (end-to-end)

## 6.1 Tìm chỗ

1. Khách xem trạm/chỗ trống theo `TRAM`, `CHO_DO_XE`, `TRU_SAC`.
2. Hệ thống lọc theo loại xe và loại chỗ phù hợp.

## 6.2 Đặt chỗ

1. Tạo `DAT_CHO` trạng thái `Active`.
2. Trigger kiểm tra bảo trì, khóa đen, loại xe-loại chỗ.
3. Unique index chặn trùng chỗ/trùng xe ở trạng thái active.

## 6.3 Vào trạm

1. Mở `PHIEN` trạng thái `Active`.
2. Trigger kiểm tra điều kiện tài khoản/số dư tối thiểu (đặc biệt cho `Registered`).

## 6.4 Bắt đầu sạc

1. Tạo `CHI_TIET_PHIEN_SAC` với `TrangThaiSac='Charging'`.
2. Trigger kiểm tra:
   - phiên phải là `ParkingAndCharging`,
   - trụ `Available`,
   - tương thích chuẩn sạc.

## 6.5 Sạc hoàn tất

1. Cập nhật `ThoiGianKetThucSac`, `TrangThaiSac='Completed'`.
2. Trigger tự tính `ThoiGianHetAnHan` theo `TRAM.PhutAnHanSauSac`.

## 6.6 Quá hạn ân hạn

- Nếu xe còn chiếm chỗ có trụ sau thời điểm ân hạn, tính phí `PostCharging` trong `CHI_TIET_PHI` theo quy tắc ứng dụng.

## 6.7 Thanh toán

- **Thành viên (`Wallet`):** `sp_thanh_toan_hoa_don_vi`.
- **Vãng lai (`WalkIn`):** `sp_thanh_toan_walkin_ngoai` với `POS_Card`/`Dynamic_QR`/`Cash`.

## 6.8 Rời trạm

1. Phiên được đóng (`Completed`).
2. Trigger đồng bộ trả tài nguyên nếu không còn phiên active khác.

## 6.9 No-show

- `sp_xu_ly_dat_cho_qua_han` chuyển đặt chỗ quá hạn sang `Expired`, giải phóng chỗ nếu hợp lệ.

## 6.10 Trụ lỗi

- Trạng thái trụ `Faulted`/`Maintenance` sẽ bị chặn mở sạc mới bởi trigger.

## 6.11 Ví không đủ tiền

- Trong thanh toán ví, procedure chặn nếu số dư không đủ.
- Trong quá trình sạc, `sp_kiem_tra_va_ngat_sac_tu_dong` có thể ngắt theo ngưỡng an toàn.

---

## 7. Business rules, edge cases, security, data integrity, test scenarios

## 7.1 Business rules chính

1. Mỗi xe tối đa một phiên `Active` tại một thời điểm.
2. Mỗi chỗ tối đa một phiên `Active` tại một thời điểm.
3. `WalkIn` không đi qua thanh toán ví.
4. Phiên `ParkingOnly` không được có chi tiết sạc.
5. Trụ không ở trạng thái `Available` thì không mở sạc mới.

## 7.2 Edge cases tiêu biểu

- Hai người tranh chấp cùng một chỗ/trụ cùng lúc.
- Retry thanh toán do timeout mạng.
- Người dùng gửi sai phương thức thanh toán cho walk-in.
- Phiên kết thúc nhưng còn phiên active khác cùng tài nguyên.
- Trụ bảo trì hoặc lỗi giữa vòng đời phiên.

## 7.3 Security & kiểm soát truy cập

- RBAC tách vai trò app user, vận hành trạm, quản trị hệ thống.
- Tránh ghi đè lịch sử tài chính bằng trigger bảo vệ `GIAO_DICH_VI`.
- Ràng buộc dữ liệu tài chính để giảm gian lận và sai lệch.

## 7.4 Data integrity

- CHECK trạng thái và mốc thời gian toàn vẹn.
- FK đảm bảo quan hệ tham chiếu.
- Unique index bảo vệ tính duy nhất nghiệp vụ.
- Procedure dùng khóa hàng (`FOR UPDATE`) ở các luồng thanh toán quan trọng.

## 7.5 Test scenarios khuyến nghị

Bộ test tham khảo đã được mô tả trong `mysql/1410/17_PROCEDURES.sql` (khối comment cuối file), gồm:

1. Sai chủ hóa đơn khi thanh toán ví.
2. Retry idempotency cùng key/cùng hóa đơn.
3. Cùng key cho hóa đơn khác.
4. Mở sạc trên trụ bận/lỗi/bảo trì.
5. `ParkingOnly` tạo chi tiết sạc.
6. Walk-in dùng sai phương thức.
7. Trùng `MaGiaoDichNgoai`.
8. Kết thúc một phiên nhưng còn phiên active khác cùng tài nguyên.

---

## 8. So sánh 1310 vs 2209 vs 1410

| Tiêu chí | 1310 | 2209 | 1410 |
|---|---|---|---|
| Trải nghiệm khách hàng | Cơ bản | Tốt hơn rõ rệt | Đầy đủ và chặt chẽ nhất hiện tại |
| Hỗ trợ WalkIn | Hạn chế | Có | Có + kiểm tra phương thức/loại khách rõ hơn |
| Chống trừ tiền sai | Chưa tốt | Có nhưng hở logic | Sửa chủ hóa đơn + idempotency đầy đủ hơn |
| Chống tranh chấp tài nguyên | Chưa đầy đủ | Có nền tảng | Tăng khóa/ràng buộc/điều kiện giải phóng |
| ParkingOnly vs Charging | Chưa chặt | Còn lỗ hổng | Đã chặn rõ ở trigger |
| Tính nhất quán hóa đơn/ledger | Trung bình | Tốt hơn | Chặt hơn với CHECK + trigger + procedure |
| Mức sẵn sàng vận hành | Demo | Gần thực tế | Tốt nhất trong 3 bản, phù hợp khách hàng nhất |

**Kết luận:** Bản **1410** là bản đầy đủ nhất và phù hợp nhất dưới góc nhìn khách hàng sử dụng dịch vụ.

**Giới hạn còn lại (nêu rõ):**

- Chưa tự điều khiển phần cứng barrier/trụ sạc chỉ bằng SQL.
- Chưa tự gửi notification thực sự chỉ từ DB.
- Chưa thay thế hoàn toàn tầng ứng dụng cho điều phối thời gian thực.
- Chưa bao gồm toàn bộ kiểm thử tích hợp IoT/payment gateway ở mức hệ thống.

---

## 9. Phạm vi xử lý bằng database vs phần ngoài database

## 9.1 Phạm vi xử lý bằng database

Database 1410 chịu trách nhiệm chính cho:

- Mô hình dữ liệu lõi, PK/FK/CHECK/UNIQUE.
- Trigger cưỡng chế nghiệp vụ liên bảng và đồng bộ trạng thái dữ liệu.
- Procedure thanh toán, no-show, auto-cutoff logic ở mức dữ liệu.
- RBAC và bảo vệ ledger khỏi chỉnh sửa trái phép.

## 9.2 Phần cần application/scheduler/IoT bên ngoài database

Cần hệ thống ngoài DB để hoàn thiện vận hành thực tế:

- Điều khiển phần cứng trụ sạc, relay, barrier, camera ANPR.
- Gửi push notification/SMS/email.
- Chạy scheduler/job định kỳ tin cậy (ví dụ quét quá hạn theo lịch vận hành).
- Tích hợp cổng thanh toán thực (POS/QR/bank gateway) và đối soát realtime.
- API/UI cho người dùng và vận hành.

> Vì vậy, báo cáo 1410 **không tuyên bố quá mức** rằng SQL tự động làm toàn bộ nghiệp vụ vật lý ngoài đời thực.

---

## 10. Hướng dẫn triển khai ngắn gọn

1. Vào thư mục SQL chuẩn:

```bash
cd mysql/1410
```

2. Chạy orchestrator:

```bash
psql -v ON_ERROR_STOP=1 -f 00_FULL_DDL.sql <ten_database>
```

3. Phân quyền role theo `16_RBAC.sql` và cấp user thực tế theo môi trường triển khai.

4. Kiểm thử các kịch bản chính ở phần comment cuối `17_PROCEDURES.sql`.

---

## 11. Tổng kết

Bản báo cáo 1410 đã hợp nhất phần mạnh của 1310 và 2209, đồng thời mô tả rõ các lỗi logic đã khắc phục trong bộ SQL chuẩn `mysql/1410/`. Ở góc nhìn khách hàng, 1410 là phiên bản cân bằng tốt nhất giữa đầy đủ nghiệp vụ, an toàn tài chính và nhất quán dữ liệu, nhưng vẫn cần tầng application/scheduler/IoT để đạt mức vận hành thương mại hoàn chỉnh.
