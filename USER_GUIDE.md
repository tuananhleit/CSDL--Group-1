# HƯỚNG DẪN SỬ DỤNG DỊCH VỤ SMART EV PARKING
## HỆ THỐNG QUẢN LÝ TRẠM SẠC VÀ BÃI ĐỖ XE ĐIỆN THÀNH PHỐ THÔNG MINH
**Đề tài môn học:** Cơ sở dữ liệu (INT1313) — Nhóm 01 (PTITHCM)  
**Tác giả:** Lê Tuấn Anh — Đỗ Huy Ba — Châu Gia Bảo  

---

## 📌 MỤC LỤC
1. [Giới thiệu tổng quan dịch vụ](#1-giới-thiệu-tổng-quan-dịch-vụ)
2. [Hướng dẫn dành cho Khách hàng lái xe điện](#2-hướng-dẫn-dành-cho-khách-hàng-lái-xe-điện)
   - [2.1. Đăng ký & Nạp tiền vào Ví điện tử](#21-đăng-ký--nạp-tiền-vào-ví-điện-tử)
   - [2.2. Tìm trạm & Đặt chỗ đỗ trước (Booking)](#22-tìm-trạm--đặt-chỗ-đỗ-trước-booking)
   - [2.3. Check-in & Mở phiên sạc xe điện](#23-check-in--mở-phiên-sạc-xe-điện)
   - [2.4. Ngắt sạc tự động & Thời gian ân hạn di dời xe](#24-ngắt-sạc-tự-động--thời-gian-ân-hạn-di-dời-xe)
   - [2.5. Thanh toán hóa đơn](#25-thanh-toán-hóa-đơn)
3. [Hướng dẫn dành cho Khách vãng lai (Walk-in)](#3-hướng-dẫn-dành-cho-khách-vãng-lai-walk-in)
4. [Hướng dẫn dành cho Quản trị viên & Vận hành trạm](#4-hướng-dẫn-dành-cho-quản-trị-viên--vận-hành-trạm)
5. [Hướng dẫn trải nghiệm các tính năng trên Giao diện Web App](#5-hướng-dẫn-trải-nghiệm-các-tính-năng-trên-giao-diện-web-app)
6. [Các câu hỏi thường gặp (FAQ)](#6-các-câu-hỏi-thường-gặp-faq)

---

## 1. GIỚI THIỆU TỔNG QUAN DỊCH VỤ

Hệ thống **Smart EV Parking** cung cấp dịch vụ tích hợp 2 trong 1: **Đỗ xe thông minh** và **Sạc pin xe điện** tại các bãi đỗ xe thuộc khu đô thị, trung tâm thương mại và sân bay.

Hệ thống hỗ trợ 2 nhóm phương tiện:
- **Ô tô điện (Car_4W):** Hỗ trợ sạc chậm AC (Type 2 - 11 kW, 22 kW) và sạc nhanh DC (CCS2 - 50 kW, 150 kW).
- **Xe máy điện (Motorbike_2W):** Hỗ trợ các ổ cắm chuyên dụng AC 3 kW (AC_Plug) tại khu vực riêng.

---

## 2. HƯỚNG DẪN DÀNH CHO KHÁCH HÀNG LÁI XE ĐIỆN

### 2.1. Đăng ký & Nạp tiền vào Ví điện tử
- **Tài khoản Thành viên (Registered):** Bắt buộc cung cấp Họ tên, Số điện thoại hoặc Email để nhận hóa đơn điện tử và sử dụng tính năng đặt chỗ trước.
- **Quy tắc số dư tối thiểu:** Tài khoản phải có số dư tối thiểu **20.000 VNĐ** để có thể đặt chỗ hoặc mở phiên sạc.
- **Nạp tiền vào ví:** Khách hàng có thể nạp tiền thông qua chuyển khoản ngân hàng hoặc cổng thanh toán đối tác. Mọi giao dịch nạp tiền đều được lưu vào **Sổ cái ví bất biến (Append-Only)**, số dư được cập nhật tức thì.

### 2.2. Tìm trạm & Đặt chỗ đỗ trước (Booking)
1. **Tra cứu trạm:** Mở ứng dụng để xem 9 trạm trong thành phố, theo dõi số lượng chỗ đỗ còn trống (**Available**), vị trí ô và loại trụ sạc tương thích.
2. **Chọn ô đỗ & khung giờ:** Chọn ô đỗ phù hợp với loại xe (ô tô hoặc xe máy) và chọn chuẩn cổng sạc tương thích với xe của bạn.
3. **Thanh toán tiền cọc:** Hệ thống sẽ tạm giữ một khoản tiền cọc (mặc định 20.000 VNĐ) từ ví để giữ chỗ.
4. **Quy định thời gian giữ chỗ:**
   - Hệ thống giữ chỗ tối đa **30 phút** kể từ thời điểm đặt.
   - Khi bạn đến trạm đúng giờ, toàn bộ tiền cọc sẽ được **khấu trừ 100% vào hóa đơn** cuối cùng.
   - Nếu quá thời hạn mà bạn không đến (No-Show), lịch đặt sẽ bị hủy và tiền cọc không được hoàn lại.

### 2.3. Check-in & Mở phiên sạc xe điện
1. **Đến vị trí đỗ:** Đưa xe vào đúng vị trí ô đỗ đã đặt (hoặc chọn ô trống có đèn báo xanh).
2. **Cắm súng sạc:** Cắm đầu súng sạc vào cổng sạc trên xe:
   - Hệ thống kiểm tra chuẩn kết nối (Ví dụ: xe CCS2 chỉ cắm được trụ sạc CCS2).
   - Nếu súng sạc bị lỗi hoặc trụ đang bảo trì, hệ thống sẽ từ chối mở phiên để đảm bảo an toàn điện.
3. **Chọn loại phiên sử dụng:**
   - **Chỉ đỗ xe (ParkingOnly):** Dành cho xe chỉ có nhu cầu gửi xe, không cắm sạc.
   - **Đỗ xe và Sạc điện (ParkingAndCharging):** Vừa tính tiền đỗ xe theo giờ, vừa tính tiền điện nạp theo kWh.
4. **Thiết lập hạn mức tự ngắt:** Khách hàng có thể cài đặt mức sạc mong muốn (ví dụ: sạc đến 80% pin hoặc tối đa 40 kWh).

### 2.4. Ngắt sạc tự động & Thời gian ân hạn di dời xe
- **Cơ chế tự ngắt bảo vệ pin và tài chính:**
  - Phiên sạc sẽ **tự động ngắt** khi pin xe đầy, khi chạm hạn mức kWh đã đăng ký, hoặc khi số dư ví gần chạm ngưỡng thanh toán.
- **Thời gian ân hạn (Grace Period):**
  - Sau khi sạc xong, khách hàng có **15 phút ân hạn miễn phí** để rút súng sạc và di dời xe ra ô đỗ thường hoặc rời bãi.
  - Sau 15 phút ân hạn, nếu xe vẫn tiếp tục chiếm dụng trụ sạc, hệ thống sẽ tự động tính **Phí đỗ chiếm dụng sau sạc (Overstay Fee)** theo từng block 15 phút nhằm đảm bảo công bằng cho người đến sau.

### 2.5. Thanh toán hóa đơn
Khi xe rời bãi, hệ thống tự động chốt phiên và lập hóa đơn chi tiết:
$$\text{Tổng tiền} = \text{Tiền đỗ xe} + \text{Tiền sạc điện} + \text{Phí quá hạn (nếu có)} - \text{Tiền cọc đã trả}$$

- **Thanh toán qua Ví điện tử:** Hệ thống tự động khấu trừ vào số dư ví của thành viên. Giao dịch được xác thực an toàn tuyệt đối qua mã giao dịch sổ cái.
- **Khóa xe nợ cước (BiDenKhoa):** Nếu số dư ví không đủ thanh toán và khách hàng chưa thanh toán trong hạn, phương tiện sẽ bị gắn cờ tạm khóa và không thể đặt chỗ cho đến khi thanh toán xong.

---

## 3. HƯỚNG DẪN DÀNH CHO KHÁCH VÃNG LAI (WALK-IN)

Dành cho khách hàng chưa đăng ký tài khoản thành viên:
1. **Vào bãi:** Lấy thẻ từ hoặc quét mã vào bãi tại cổng kiểm soát.
2. **Sử dụng trụ sạc:** Cắm súng sạc và yêu cầu mở phiên tại cây sạc bằng hình thức Walk-in.
3. **Thanh toán khi ra về:**
   - Khách vãng lai thanh toán trực tiếp tại quầy thanh toán hoặc máy POS tự động bằng: **Thẻ ngân hàng (POS), Mã QR động (VietQR/MoMo) hoặc Tiền mặt**.
   - Hóa đơn được in phiếu thanh toán hoặc xuất mã tra cứu điện tử.

---

## 4. HƯỚNG DẪN DÀNH CHO QUẢN TRỊ VIÊN & VẬN HÀNH TRẠM

Dành cho nhân viên quản lý kỹ thuật và ban điều hành:
1. **Giám sát thời gian thực:**
   - Theo dõi trạng thái từng vị trí đỗ: `Available` (Trống), `Occupied` (Có xe), `Reserved` (Đã đặt trước), `Maintenance` (Bảo trì).
   - Theo dõi trạng thái trụ sạc: `Available`, `Charging` (Đang sạc), `Maintenance`, `Faulted`.
2. **Bảo trì kỹ thuật:**
   - Khi phát hiện trụ sạc hỏng hoặc ô đỗ cần bảo trì, đổi trạng thái sang `Maintenance`.
   - Hệ thống trigger tự động bảo vệ: **Chặn toàn bộ yêu cầu đặt chỗ và mở phiên** tại vị trí đang bảo trì.
3. **Đối soát tài chính & Doanh thu:**
   - Xem báo cáo doanh thu tổng hợp theo từng trạm, theo tháng, theo khung giờ cao điểm/thấp điểm.
   - Kiểm tra tính bất biến của sổ cái ví điện tử (bảo đảm $100\%$ không bị sửa đổi thủ công).

---

## 5. HƯỚNG DẪN TRẢI NGHIỆM CÁC TÍNH NĂNG TRÊN GIAO DIỆN WEB APP

Khi khởi động ứng dụng bằng lệnh `python start.py` (hoặc nhấp đúp `run_app.bat`), trình duyệt sẽ mở giao diện điều khiển với 6 module:

```
[Dashboard] ── [Trạm sạc] ── [Đặt chỗ] ── [Phiên sạc] ── [Hóa đơn] ── [Truy vấn SQL]
```

1. **Trang chủ (Dashboard):**
   - Xem nhanh 4 thẻ thống kê: Tổng số trạm (9), Chỗ đỗ khả dụng, Số trụ đang sạc, Doanh thu tổng.
   - Biểu đồ phân bổ loại phiên (Chỉ đỗ xe vs Đỗ và sạc).
2. **Trang Trạm sạc (Stations):**
   - Xem lưới danh sách ô đỗ của từng trạm với nhãn màu trực quan:
     - 🟢 **Xanh lá (Available):** Ô trống sẵn sàng tiếp nhận xe.
     - 🔴 **Đỏ (Occupied):** Ô đang có xe đỗ/sạc.
     - 🟡 **Vàng (Reserved):** Ô đang được giữ chỗ trước.
     - ⚪ **Xám (Maintenance):** Đang bảo trì kỹ thuật.
3. **Trang Đặt chỗ (Bookings):**
   - Danh sách các lịch đặt chỗ mới nhất, thời gian giữ chỗ, xe đặt và tiền cọc.
4. **Trang Phiên sạc (Sessions):**
   - Danh sách các phiên sạc đang hoạt động và lịch sử phiên hoàn tất kèm chỉ số kWh tiêu thụ.
5. **Trang Hóa đơn & Ví (Billing):**
   - Xem chi tiết từng hóa đơn, bóc tách tiền đỗ, tiền điện sạc và lịch sử biến động số dư ví.
6. **Trang Khám phá Truy vấn (Queries & Tests):**
   - Bấm vào từng câu truy vấn từ **Q1 đến Q10** để chạy trực tiếp trên cơ sở dữ liệu thật và xem kết quả bảng dữ liệu phản hồi ngay lập tức.
   - Xem kết quả đối soát của **16 ca kiểm thử nghiệp vụ**.

---

## 6. CÁC CÂU HỎI THƯỜNG GẶP (FAQ)

**Q1: Xe máy điện có thể đỗ vào ô của ô tô không?**  
*Trả lời:* Không. Ràng buộc toàn vẹn trigger `TRG_DatCho_CheckLoaiXe` và `TRG_Phien_CheckLoaiXe` sẽ tự động từ chối và báo lỗi để bảo vệ không gian bãi đỗ cho ô tô.

**Q2: Nếu cắm nhầm súng sạc không tương thích thì sao?**  
*Trả lời:* Trigger `TRG_PhienSac_KiemTraTru` sẽ so khớp chuẩn sạc của xe và súng sạc. Nếu không khớp (ví dụ xe CCS2 cắm súng Type2), hệ thống sẽ từ chối mở phiên sạc.

**Q3: Tôi có thể sửa hoặc xóa lịch sử giao dịch ví không?**  
*Trả lời:* Hoàn toàn không. Trigger `TRG_GiaoDichVi_Protect_Upd` và `TRG_GiaoDichVi_Protect_Del` sẽ ngăn chặn mọi hành vi UPDATE hoặc DELETE trên bảng `GIAO_DICH_VI` để bảo đảm tính bất biến của sổ cái tài chính.

**Q4: Dữ liệu của tôi có bị mất khi chạy thử các ca kiểm thử không?**  
*Trả lời:* Không. Toàn bộ 16 ca kiểm thử trong `19_tests.sql` đều được bảo vệ trong khối giao dịch `START TRANSACTION ... ROLLBACK`, trạng thái cơ sở dữ liệu mẫu ban đầu luôn được bảo toàn nguyên vẹn.
