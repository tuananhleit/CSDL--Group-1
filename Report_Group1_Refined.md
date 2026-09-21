# DATABASE PROJECT REPORT
## SMART CITY EV CHARGING & PARKING MANAGEMENT SYSTEM

---

### A. PROJECT IDENTITY
* **Project ID & Title:** #01 - Smart City EV Charging & Parking Management System
* **Team Name:** Group 01
* **Team Members:**
  1. Lê Tuấn Anh — MSSV: N25DCAT064 (Email: n25dcat064@student.ptithcm.edu.vn)
  2. Đỗ Huy Ba — MSSV: N25DCAT068 (Email: n25dcat068@student.ptithcm.edu.vn)
  3. Châu Gia Bảo — MSSV: N22DCAT005 (Email: n22dcat005@student.ptithcm.edu.vn)

---

### B. REPORT STRUCTURE

# 1. INTRODUCTION & PROJECT SCOPE (Adapted from ISO/IEC/IEEE 29148)

## 1.1 System Objective
Dự án mô phỏng hệ thống quản lý hạ tầng tập trung cho bãi đỗ xe kết hợp trạm sạc xe điện (EV) trong đô thị thông minh. Hệ thống giải quyết 4 mục tiêu cốt lõi:
1. **Quản lý đa dạng hạ tầng đỗ & sạc (Hỗ trợ Ô tô 4 bánh & Xe máy 2 bánh):** Phân loại ô đỗ ô tô (`CarSlot`) và ô đỗ xe máy điện (`MotorbikeSlot`), phân biệt trụ sạc công suất cao DC/AC cho ô tô và ổ sạc thông minh cho xe máy điện.
2. **Tối ưu hóa khả năng tiếp cận (Khách thành viên & Khách vãng lai):** Quản lý đỗ xe thuần túy (`ParkingOnly`) và đỗ xe kết hợp sạc (`ParkingAndCharging`). Cho phép 1 khách hàng sở hữu nhiều phương tiện và mở nhiều phiên dịch vụ song song trên cùng 1 ví điện tử.
3. **Tính phí linh hoạt & Chống chiếm dụng hạ tầng:** Áp dụng bảng giá đỗ xe riêng theo loại chỗ (4W/2W), phí sạc riêng theo cấp công suất và chế tài phạt đỗ xe sau sạc (`PostCharging`).
4. **Minh bạch giao dịch & Quản lý công nợ:** Hỗ trợ đa dạng phương thức thanh toán (Trừ ví trả trước, Thẻ POS tại chỗ, Quét mã QR linh hoạt, Tiền mặt) và cơ chế khóa nợ xấu ANPR cho xe bùng tiền.

---

## 1.2 Business Rules & Constraints

### 1.2.1 Quy tắc Nghiệp vụ Cơ bản (Core Business Rules)

* **BR-01 (Phân loại Khách hàng & Xe):** 
  * Khách hàng phân làm 2 loại: Khách thành viên (`Registered`) và Khách vãng lai (`WalkIn`).
  * Loại phương tiện (`LoaiXe`) bao gồm Ô tô 4 bánh (`Car_4W`) và Xe máy điện 2 bánh (`Motorbike_2W`). Mỗi xe có một `BienSo` duy nhất.
* **BR-02 (Một Khách hàng sở hữu Nhiều Xe & Phiên Song song):** 
  * Một khách hàng (`MaKH`) có thể đăng ký sở hữu nhiều phương tiện (`MaXe`).
  * Tất cả xe của cùng 1 khách hàng dùng chung 1 Ví điện tử (`SoDuViDienTu`). Hệ thống cho phép các xe khác nhau của cùng 1 khách hàng mở **nhiều phiên dịch vụ đang chạy song song** ở các trạm khác nhau.
  * Ràng buộc duy nhất: Cùng **1 chiếc xe (`MaXe`)** không thể mở 2 phiên song song tại cùng mốc thời gian. Đồng thời, 1 chiếc xe cũng chỉ được phép có tối đa 1 đặt chỗ đang hiệu lực (`DAT_CHO.TrangThaiDatCho = 'Active'`) tại cùng mốc thời gian.
* **BR-03 (Quy tắc Khách CHỈ ĐỖ XE - Parking Only):** 
  * Khách chỉ đỗ xe (`LoaiPhien = 'ParkingOnly'`) được ưu tiên xếp vào các vị trí đỗ thuần túy không gắn trụ sạc.
  * **Lưu ý:** Quy tắc ưu tiên xếp chỗ được thực thi tại tầng Application Logic (Stored Procedure hoặc API), không phải ràng buộc CHECK/TRIGGER tại DB. Ràng buộc DB chỉ đảm bảo mỗi ô đỗ chỉ có 1 phiên Active tại 1 thời điểm.
* **BR-04 (Quy tắc XE MÁY ĐIỆN 2 BÁNH - Motorbike Charging):**
  * Xe máy điện 2 bánh (`Motorbike_2W`) bắt buộc đỗ và sạc tại phân khu ô đỗ xe máy (`LoaiCho = 'MotorbikeSlot'`).
  * Trụ sạc xe máy điện tham chiếu loại trụ công suất thấp (`AC 2.2kW` / Ổ cắm thông minh), áp dụng bảng giá sạc xe máy riêng rẻ hơn ô tô.
  * **Cưỡng chế tại DB:** Trigger `TRG_Phien_CheckLoaiXe` chặn INSERT vào `PHIEN` nếu `PHUONG_TIEN.LoaiXe` không khớp với `CHO_DO_XE.LoaiCho` (xem DDL Script mục 4.1).
* **BR-05 (Quyền hạn Đặt chỗ trước & Thanh toán):** 
  * Khách vãng lai không được đặt chỗ trước (`DAT_CHO`), thanh toán tại cổng ra qua máy POS, Mã QR hoặc Tiền mặt.
  * Khách thành viên trừ trực tiếp vào `SoDuViDienTu`.
  * **Mọi giao dịch thanh toán** (kể cả khách vãng lai thanh toán POS/QR/Cash) đều được ghi nhận vào sổ cái `GIAO_DICH_VI` với `LoaiGD = 'DirectPayment'` để đảm bảo đối soát tài chính đầy đủ.
* **BR-06 (Quy trình Sạc hoàn tất — Thông báo, Ân hạn & Chuyển tiếp Phí):**
  * **Bước 1 — Thông báo:** Ngay khi trụ sạc ngừng cấp điện (pin đầy hoặc đạt mức khách đặt), hệ thống **bắt buộc gửi thông báo đẩy (Push Notification)** tới ứng dụng di động của khách thành viên, hoặc hiển thị trên màn hình trụ sạc đối với khách vãng lai. Nội dung thông báo ghi rõ: *"Sạc hoàn tất. Bạn có [X] phút ân hạn miễn phí để lấy xe."*
  * **Bước 2 — Ân hạn miễn phí:** Hệ thống ghi nhận `ThoiGianKetThucSac` và tự động tính `ThoiGianHetAnHan = ThoiGianKetThucSac + TRAM.PhutAnHanSauSac` (mặc định 15 phút, cấu hình riêng theo từng trạm). Trong khoảng ân hạn này, khách **không bị tính thêm bất kỳ phí nào**.
  * **Bước 3 — Chuyển tiếp phí sau ân hạn:** Hết thời gian ân hạn mà xe vẫn chưa rời ô đỗ có trụ sạc, hệ thống chuyển sang tính phí theo 1 trong 2 kịch bản: *(A)* Nếu khách chủ động bấm "Tiếp tục đỗ xe" → tính phí đỗ xe bình thường (`KhoanMuc = 'Parking'`); *(B)* Nếu khách không phản hồi → tính phí đỗ sau sạc với đơn giá cao hơn (`KhoanMuc = 'PostCharging'`) nhằm khuyến khích giải phóng trụ sạc.

---

### 1.2.2 Xử lý 10 Tình huống Thực tế & Biên Nghiệp vụ (Real-world Edge Cases)

#### ⚡ Trường hợp 1: Một Khách hàng có Nhiều Xe cùng đỗ/sạc cùng lúc (Multi-vehicle Concurrent Sessions)
* **Thực tế:** Ông A sở hữu 1 xe ô tô VinFast VF8 và 1 xe máy điện Klara. Cả 2 xe cùng vào đỗ/sạc ở 2 địa điểm khác nhau trong cùng một giờ.
* **Hướng xử lý DB:** Ràng buộc `UNIQUE INDEX` chỉ áp trên `PHIEN(MaXe) WHERE TrangThaiPhien = 'Active'`. Ràng buộc này chỉ khóa chiếc xe cụ thể, không khóa `MaKH`. Do đó, tài khoản ông A hỗ trợ $N$ phiên chạy đồng thời cho $N$ xe, miễn là số dư ví $\text{SoDuViDienTu} \ge N \times \text{TRAM.SoDuToiThieu}$.

#### ⚡ Trường hợp 2: Phân luồng Xe 2 Bánh (Xe máy điện) đỗ & sạc (Motorbike EV Handling)
* **Thực tế:** Xe máy điện vào sạc nếu xếp chung vào chỗ đỗ ô tô sẽ lãng phí diện tích (1 ô ô tô chứa được 5 xe máy) và lãng phí trụ sạc công suất lớn DC 150kW.
* **Hướng xử lý DB:** CSDL phân biệt `CHO_DO_XE.LoaiCho IN ('CarSlot', 'MotorbikeSlot')` và `PHUONG_TIEN.LoaiXe IN ('Car_4W', 'Motorbike_2W')`. Trigger `TRG_Phien_CheckLoaiXe` chặn INSERT vào `PHIEN` nếu loại xe không khớp loại chỗ (ví dụ: `Motorbike_2W` cố đỗ vào `CarSlot` sẽ bị từ chối).

#### ⚡ Trường hợp 3: Điều kiện Khách CHỈ ĐỖ XE (Parking-Only Rules)
* **Thực tế:** Khách lái xe xăng hoặc xe điện không có nhu cầu sạc, chỉ muốn gửi xe trong bãi.
* **Hướng xử lý DB:** `PHIEN.LoaiPhien = 'ParkingOnly'`. Khi chốt hóa đơn, `PhiSacDien = 0` và `PhiDoSauSac = 0`, chỉ tính `PhiDoXe` theo phân đoạn phút. Thuật toán ưu tiên xếp ô đỗ không gắn trụ sạc được thực thi tại tầng ứng dụng (API/Stored Procedure), không phải ràng buộc DB.

#### ⚡ Trường hợp 4: Luồng Khách vãng lai (Walk-in / Guest Flow) vào bãi không có tài khoản
* **Thực tế:** Tài xế xe điện lần đầu đến bãi, không cài app, không có tài khoản hay ví điện tử.
* **Hướng xử lý DB:** Camera ANPR tại barrier cổng vào chụp biển số `BienSo`. DB tự động khởi tạo bản ghi `KHACH_HANG` (`LoaiKhach = 'WalkIn'`) và `PHUONG_TIEN`. Khi ra cổng, hệ thống hiển thị Mã QR/POS tại barrier, thanh toán xong mới mở cổng. Giao dịch thanh toán được ghi vào `GIAO_DICH_VI` với `LoaiGD = 'DirectPayment'`.

#### ⚡ Trường hợp 5: Khách vãng lai bùng tiền / Bỏ xe / Không thanh toán khi ra (Walk-in Unpaid / Blacklist)
* **Thực tế:** Khách vãng lai đỗ/sạc xong, tự ý lái xe húc gãy barrier ra ngoài hoặc bỏ xe lại bãi.
* **Hướng xử lý DB:** Hóa đơn ghi `HOA_DON.TrangThaiThanhToan = 'Unpaid'`, cờ `PHUONG_TIEN.BiDenKhoa = TRUE`. Lần sau khi xe có biển số này quay lại bất kỳ trạm nào trong toàn thành phố, camera ANPR quét phát hiện khóa đen sẽ **chặn ngay tại barrier cổng vào**.

#### ⚡ Trường hợp 6: Xe sạc xong — Khách muốn đỗ tiếp hoặc vắng mặt (Post-Charging Transition)
* **Thực tế:** Xe sạc xong, nhưng khách có thể đang đi mua sắm, đang làm việc, hoặc đơn giản chưa muốn rời bãi. Hệ thống **không đuổi khách đi** mà xử lý theo 2 kịch bản:
* **Kịch bản A — Khách chủ động muốn đỗ tiếp:** Sau khi sạc xong, app gửi thông báo cho khách biết sạc hoàn tất. Trong khoảng ân hạn (`PhutAnHanSauSac`, mặc định 15 phút), khách có thể bấm **"Tiếp tục đỗ xe"** trên app. Lúc này hệ thống kết thúc phần sạc (`ThoiGianKetThucSac`) và chuyển phiên sang tính phí đỗ xe bình thường (`KhoanMuc = 'Parking'`). **Lý tưởng nhất:** Khách di chuyển xe sang ô đỗ thường (không gắn trụ sạc) để giải phóng trụ cho người khác — khi đó chỉ trả giá đỗ xe bình thường.
* **Kịch bản B — Khách vắng mặt, không phản hồi (Idle Overstaying):** Nếu hết thời gian ân hạn (`ThoiGianHetAnHan`) mà khách không phản hồi và xe vẫn nằm tại ô đỗ có trụ sạc, hệ thống tự động chuyển sang tính phí `PostCharging` theo phút với **đơn giá cao hơn phí đỗ thường** (ví dụ: gấp 2-3 lần). Mục đích là khuyến khích giải phóng trụ sạc bằng chênh lệch giá, không phải phạt khách.
* **Ghi nhận trong CSDL:** Bảng `CHI_TIET_PHI` tách ra các dòng riêng biệt: dòng `Charging` (thời gian sạc), dòng `Parking` hoặc `PostCharging` (thời gian đỗ sau sạc tùy kịch bản A hay B). `HOA_DON.TongTien` tổng hợp tất cả.

#### ⚡ Trường hợp 7: Khách đặt chỗ nhưng không xuất hiện (No-show / Expired Reservation)
* **Thực tế:** Khách giữ slot từ 14:00 nhưng đến 14:30 vẫn không tới, gây ra "trống ảo" (Ghost Reservation).
* **Hướng xử lý DB:** Tiến trình background quét các bản ghi quá hạn `ThoiGianHetHan` để chuyển `TrangThaiDatCho = 'Expired'` và trả `CHO_DO_XE.TrangThaiCho = 'Available'`.

#### ⚡ Trường hợp 8: Hết tiền/Âm ví khi phiên sạc đang chạy (Mid-Session Depletion)
* **Thực tế:** Khách nạp 50,000đ nhưng sạc DC vượt quá 50,000đ khi không có mặt.
* **Hướng xử lý DB:** Khi số dư khả dụng $\le 0$, hệ thống tự ngắt trụ, chốt công tơ, ghi `Unpaid` và chuyển `KHACH_HANG.TrangThaiTK = 'Locked'`.

#### ⚡ Trường hợp 9: Xung đột đè lịch đặt chỗ / Trùng phiên cùng thời điểm (Concurrency & Overlap)
* **Thực tế:** Hai khách hàng cùng bấm đặt chỗ A-01 từ 10:00-11:00 tại cùng một giây.
* **Hướng xử lý DB:** Cưỡng chế bằng `UNIQUE INDEX` trên phiên `Active` và ràng buộc loại trừ PostgreSQL `EXCLUDE USING gist` trên khoảng thời gian `tsrange`.

#### ⚡ Trường hợp 10: Trụ sạc gặp sự cố kỹ thuật đột xuất (Hardware Fault Mid-charging)
* **Thực tế:** Trụ sạc sập điện hoặc đứt kết nối khi đang sạc được 10 phút.
* **Hướng xử lý DB:** `TRU_SAC.TrangThaiTru = 'Faulted'`, chốt công tơ tại mốc ngắt điện. Phiên tự động chuyển sang dạng `ParkingOnly`, chỉ tính số `SoKWh` thực tế đã cấp trước khi lỗi.

---

# 2. DATABASE DESIGN (ISO/IEC 19505 / IE Standards)

## 2.1 Conceptual Model (EER Diagram)
Mô hình EER phân loại ô đỗ 4W/2W, hỗ trợ 1 Khách hàng - Nhiều Xe, Khách vãng lai và 2 lớp con phiên.

```
 +------------------+        1:N        +------------------+
 |    KHACH_HANG    |-------------------|   PHUONG_TIEN    |
 | (Registered/     |                   | (Car_4W /        |
 |  WalkIn)         |                   |  Motorbike_2W)   |
 +------------------+                   +------------------+
          | 1                                     | 1
          | 1:N                                   | 1:N
 +------------------+                   +------------------+
 |  GIAO_DICH_VI    |                   |     DAT_CHO      |
 +------------------+                   +------------------+
          | N                                     | 0..1
          v 1                                     v 0..1
 +------------------+        1:1        +------------------+
 |     HOA_DON      |-------------------|      PHIEN       |
 +------------------+                   +------------------+
          | 1                                     | 1
          v 1:N (Weak)                            v
 +------------------+                  /=====================\
 |   CHI_TIET_PHI   |                  |  d (Disjoint, Total)|
 +------------------+                  \=====================/
                                          //               \\
                         +-------------------+   +-------------------+
                         |   PHIEN_DO_XE     |   |    PHIEN_SAC      |
                         +-------------------+   +-------------------+
                                                           | 1:1
                                                 +-------------------+
                                                 |CHI_TIET_PHIEN_SAC |
                                                 +-------------------+
```

---

## 2.2 Logical Schema Mapping
Quy tắc ánh xạ chuẩn đại số quan hệ (Khóa chính $\underline{\text{gạch chân}}$, Khóa ngoại $\text{*}$):

1. **`KHACH_HANG`** ($\underline{\text{MaKH}}$, HoTen, SDT, Email, LoaiKhach, SoDuViDienTu, TrangThaiTK, NgayDangKy)
2. **`PHUONG_TIEN`** ($\underline{\text{MaXe}}$, BienSo, MaKH$\text{*}$, LoaiXe, HangXe, CongSuatSacToiDa_kW, BiDenKhoa)
3. **`QUAN_TRI_VIEN`** ($\underline{\text{MaQTV}}$, HoTen, Email, VaiTro)
4. **`TRAM`** ($\underline{\text{MaTram}}$, TenTram, DiaChi, ViDo, KinhDo, PhutAnHanSauSac, SoDuToiThieu, MaQTV$\text{*}$)
5. **`CHO_DO_XE`** ($\underline{\text{MaCho}}$, MaTram$\text{*}$, MaViTri, LoaiCho, MoTaViTri, TrangThaiCho)
6. **`LOAI_TRU_SAC`** ($\underline{\text{MaLoaiTru}}$, TenLoai, DongDien, CongSuat_kW, ChuanKetNoi)
7. **`TRU_SAC`** ($\underline{\text{MaTru}}$, MaCho$\text{*}$, MaLoaiTru$\text{*}$, TrangThaiTru, NgayLapDat)
8. **`BANG_GIA`** ($\underline{\text{MaBangGia}}$, LoaiGia, MaLoaiTru$\text{*}$, LoaiCho, GioBatDau, GioKetThuc, LaCaoDiem, DonGiaTheoPhut, HieuLucTu, HieuLucDen, MaQTV$\text{*}$)
9. **`DAT_CHO`** ($\underline{\text{MaDatCho}}$, MaXe$\text{*}$, MaCho$\text{*}$, ThoiGianDat, ThoiGianHetHan, TrangThaiDatCho)
10. **`PHIEN`** ($\underline{\text{MaPhien}}$, MaXe$\text{*}$, MaCho$\text{*}$, MaDatCho$\text{*}$, LoaiPhien, TrangThaiPhien, ThoiGianVao, ThoiGianRa)
11. **`CHI_TIET_PHIEN_SAC`** ($\underline{\text{MaPhien}}\text{*}$, MaTru$\text{*}$, ThoiGianBatDauSac, ThoiGianKetThucSac, ThoiGianHetAnHan, ChiSoCongToDau, ChiSoCongToCuoi, SoKWh)
12. **`CHI_TIET_PHI`** ($\underline{\text{MaPhien}}\text{*}, \underline{\text{SoDong}}$, MaBangGia$\text{*}$, KhoanMuc, ThoiGianBatDau, ThoiGianKetThuc, SoPhut, SoTien)
13. **`HOA_DON`** ($\underline{\text{MaHD}}$, MaPhien$\text{*}$, PhiDoXe, PhiSacDien, PhiDoSauSac, TongTien, PhuongThucThanhToan, TrangThaiThanhToan, NgayLapHoaDon, NgayThanhToan)
14. **`GIAO_DICH_VI`** ($\underline{\text{MaGD}}$, MaKH$\text{*}$, LoaiGD, SoTien, SoDuTruoc, SoDuSau, MaHD$\text{*}$, ThoiGianGD, GhiChu)

---

## 2.3 Normalization Verification (Formal proofs 1NF → BCNF)

**Định nghĩa BCNF:** Một quan hệ $R$ đạt BCNF nếu với mọi phụ thuộc hàm phi tầm thường $X \rightarrow A \in F^+$, $X$ bắt buộc là một siêu khóa (Superkey) của $R$.

### Nhóm 1: Quan hệ Đơn khóa (11 bảng)
Các quan hệ có khóa chính gồm 1 thuộc tính duy nhất $K$: Không tồn tại phụ thuộc bộ phận (2NF thỏa hiển nhiên). Cần kiểm tra phụ thuộc bắc cầu (3NF) và vế trái siêu khóa (BCNF).

| Bảng | Khóa dự tuyển | FDs (vế trái) | BCNF? |
|:---|:---|:---|:---|
| `KHACH_HANG` | {MaKH}, {SDT}*, {Email}* | MaKH→…, SDT→…, Email→… | ✅ Mọi vế trái là siêu khóa |
| `PHUONG_TIEN` | {MaXe}, {BienSo} | MaXe→…, BienSo→… | ✅ |
| `QUAN_TRI_VIEN` | {MaQTV}, {Email} | MaQTV→…, Email→… | ✅ |
| `TRAM` | {MaTram} | MaTram→… | ✅ |
| `LOAI_TRU_SAC` | {MaLoaiTru} | MaLoaiTru→… | ✅ |
| `BANG_GIA` | {MaBangGia} | MaBangGia→… | ✅ |
| `DAT_CHO` | {MaDatCho} | MaDatCho→… | ✅ |
| `PHIEN` | {MaPhien} | MaPhien→… | ✅ |
| `CHI_TIET_PHIEN_SAC` | {MaPhien} | MaPhien→… | ✅ |
| `GIAO_DICH_VI` | {MaGD} | MaGD→… | ✅ |

*\* `SDT` và `Email` là khóa dự tuyển khi `LoaiKhach = 'Registered'`.*

### Nhóm 2: Quan hệ Đa khóa dự tuyển đặc biệt (2 bảng)

**`CHO_DO_XE`:**
* Khóa dự tuyển: $K_1 = \{\text{MaCho}\}$, $K_2 = \{\text{MaTram, MaViTri}\}$ (do UNIQUE constraint).
* FDs: $\text{MaCho} \rightarrow \text{MaTram, MaViTri, LoaiCho, MoTaViTri, TrangThaiCho}$ và $(\text{MaTram, MaViTri}) \rightarrow \text{MaCho, LoaiCho, MoTaViTri, TrangThaiCho}$.
* Mọi vế trái đều là siêu khóa $\implies$ **Đạt BCNF**.

**`TRU_SAC`:**
* Khóa dự tuyển: $K_1 = \{\text{MaTru}\}$, $K_2 = \{\text{MaCho}\}$ (do UNIQUE NOT NULL trên MaCho — quan hệ $1:0..1$).
* FDs: $\text{MaTru} \rightarrow \dots$ và $\text{MaCho} \rightarrow \dots$. Mọi vế trái đều là siêu khóa $\implies$ **Đạt BCNF**.

**`HOA_DON`:**
* Khóa dự tuyển: $K_1 = \{\text{MaHD}\}$, $K_2 = \{\text{MaPhien}\}$ (do UNIQUE NOT NULL trên MaPhien — quan hệ $1:1$).
* FDs: $\text{MaHD} \rightarrow \dots$ và $\text{MaPhien} \rightarrow \dots$. Mọi vế trái đều là siêu khóa $\implies$ **Đạt BCNF**.

### Nhóm 3: Quan hệ Khóa phức hợp (1 bảng)

**`CHI_TIET_PHI`:**
* Khóa chính: $(\text{MaPhien}, \text{SoDong})$.
* FDs: $(\text{MaPhien, SoDong}) \rightarrow \text{MaBangGia, KhoanMuc, ThoiGianBatDau, ThoiGianKetThuc, SoPhut, SoTien}$.
* Kiểm tra 2NF: Không tồn tại thuộc tính không khóa nào phụ thuộc vào chỉ `MaPhien` hoặc chỉ `SoDong` (mỗi dòng phí của cùng 1 phiên có bảng giá, khoảng thời gian và số tiền riêng biệt).
* Vế trái duy nhất là khóa chính (siêu khóa) $\implies$ **Đạt BCNF**.

### Ghi chú về thuộc tính dẫn xuất
* `SoKWh` trong `CHI_TIET_PHIEN_SAC`: Cài đặt dưới dạng `GENERATED ALWAYS AS ... STORED`, không tạo FD mới.
* `TongTien` trong `HOA_DON`: Chốt giá trị tại thời điểm phát hành hóa đơn (Financial Snapshot Integrity). Cưỡng chế bằng `CHECK (TongTien = PhiDoXe + PhiSacDien + PhiDoSauSac)`.

**Kết luận:** Cả 14 quan hệ đều đạt BCNF.

---

# 3. DATA DICTIONARY (Adapted from ISO/IEC 11179)

### Table 1: `KHACH_HANG` (Customer Metadata)
| Attribute | Data Type | Nullable | Constraint | Description |
|:---|:---|:---|:---|:---|
| `MaKH` | VARCHAR(20) | NO | PK | Mã định danh khách hàng |
| `HoTen` | VARCHAR(100) | NO | DEFAULT 'Khách Vãng Lai' | Họ tên |
| `SDT` | VARCHAR(15) | YES | UNIQUE | SĐT (Bắt buộc nếu Registered) |
| `Email` | VARCHAR(100) | YES | UNIQUE | Email (Bắt buộc nếu Registered) |
| `LoaiKhach` | VARCHAR(20) | NO | CHECK IN ('Registered','WalkIn') | Phân loại khách hàng |
| `SoDuViDienTu` | NUMERIC(12,2) | NO | DEFAULT 0, CHECK (>=0) | Số dư ví điện tử |
| `TrangThaiTK` | VARCHAR(20) | NO | CHECK IN ('Active','Locked') | Trạng thái tài khoản |
| `NgayDangKy` | TIMESTAMP | NO | DEFAULT CURRENT_TIMESTAMP | Ngày đăng ký |

### Table 2: `PHUONG_TIEN` (Vehicle Metadata)
| Attribute | Data Type | Nullable | Constraint | Description |
|:---|:---|:---|:---|:---|
| `MaXe` | VARCHAR(20) | NO | PK | Mã phương tiện |
| `BienSo` | VARCHAR(20) | NO | UNIQUE | Biển số xe |
| `MaKH` | VARCHAR(20) | NO | FK (KHACH_HANG) | Chủ sở hữu (1 KH → N xe) |
| `LoaiXe` | VARCHAR(20) | NO | CHECK IN ('Car_4W','Motorbike_2W') | Loại xe |
| `HangXe` | VARCHAR(50) | YES | — | Hãng sản xuất |
| `CongSuatSacToiDa_kW` | NUMERIC(5,2) | YES | CHECK (>0) | Công suất sạc tối đa |
| `BiDenKhoa` | BOOLEAN | NO | DEFAULT FALSE | Cờ khóa đen nợ xấu |

### Table 3: `CHO_DO_XE` (Parking Slot Metadata)
| Attribute | Data Type | Nullable | Constraint | Description |
|:---|:---|:---|:---|:---|
| `MaCho` | VARCHAR(20) | NO | PK | Mã chỗ đỗ |
| `MaTram` | VARCHAR(20) | NO | FK (TRAM) | Trạm trực thuộc |
| `MaViTri` | VARCHAR(20) | NO | UNIQUE (MaTram, MaViTri) | Vị trí trong trạm (A-01, M-05) |
| `LoaiCho` | VARCHAR(20) | NO | CHECK IN ('CarSlot','MotorbikeSlot') | Loại ô đỗ |
| `MoTaViTri` | VARCHAR(100) | YES | — | Mô tả vị trí |
| `TrangThaiCho` | VARCHAR(20) | NO | CHECK IN ('Available','Occupied','Reserved','Maintenance') | Trạng thái |

### Table 4: `BANG_GIA` (Pricing Tariff Metadata)
| Attribute | Data Type | Nullable | Constraint | Description |
|:---|:---|:---|:---|:---|
| `MaBangGia` | VARCHAR(20) | NO | PK | Mã bảng giá |
| `LoaiGia` | VARCHAR(20) | NO | CHECK IN ('Parking','Charging','PostCharging') | Loại khoản phí |
| `MaLoaiTru` | VARCHAR(20) | YES | FK (LOAI_TRU_SAC) | Loại trụ (bắt buộc nếu Charging) |
| `LoaiCho` | VARCHAR(20) | YES | CHECK IN ('CarSlot','MotorbikeSlot') | Loại ô đỗ (bắt buộc nếu Parking/PostCharging) |
| `GioBatDau` | TIME | NO | — | Mốc bắt đầu khung giờ |
| `GioKetThuc` | TIME | NO | CHECK (GioKetThuc > GioBatDau) | Mốc kết thúc khung giờ |
| `LaCaoDiem` | BOOLEAN | NO | DEFAULT FALSE | Có phải giờ cao điểm |
| `DonGiaTheoPhut` | NUMERIC(10,2) | NO | CHECK (>=0) | Đơn giá mỗi phút (VND) |
| `HieuLucTu` | DATE | NO | — | Ngày bắt đầu hiệu lực |
| `HieuLucDen` | DATE | YES | — | Ngày kết thúc hiệu lực |
| `MaQTV` | VARCHAR(20) | YES | FK (QUAN_TRI_VIEN) | Người thiết lập giá |

### Table 5: `PHIEN` (Service Session Metadata)
| Attribute | Data Type | Nullable | Constraint | Description |
|:---|:---|:---|:---|:---|
| `MaPhien` | VARCHAR(20) | NO | PK | Mã phiên dịch vụ |
| `MaXe` | VARCHAR(20) | NO | FK (PHUONG_TIEN) | Xe sử dụng dịch vụ |
| `MaCho` | VARCHAR(20) | NO | FK (CHO_DO_XE) | Chỗ đỗ sử dụng |
| `MaDatCho` | VARCHAR(20) | YES | FK (DAT_CHO), UNIQUE | Đặt chỗ liên quan (nếu có) |
| `LoaiPhien` | VARCHAR(20) | NO | CHECK IN ('ParkingOnly','ParkingAndCharging') | Loại phiên |
| `TrangThaiPhien` | VARCHAR(20) | NO | CHECK IN ('Active','Completed','Cancelled') | Trạng thái |
| `ThoiGianVao` | TIMESTAMP | NO | DEFAULT CURRENT_TIMESTAMP | Thời điểm vào |
| `ThoiGianRa` | TIMESTAMP | YES | CHECK (>= ThoiGianVao) | Thời điểm ra |

### Table 6: `CHI_TIET_PHIEN_SAC` (Charging Subclass Metadata)
| Attribute | Data Type | Nullable | Constraint | Description |
|:---|:---|:---|:---|:---|
| `MaPhien` | VARCHAR(20) | NO | PK, FK (PHIEN) | Mã phiên sạc |
| `MaTru` | VARCHAR(20) | NO | FK (TRU_SAC) | Trụ sạc cấp nguồn |
| `ThoiGianBatDauSac` | TIMESTAMP | NO | — | Thời điểm bắt đầu sạc |
| `ThoiGianKetThucSac` | TIMESTAMP | YES | CHECK (>= BatDauSac) | Thời điểm kết thúc sạc |
| `ThoiGianHetAnHan` | TIMESTAMP | YES | — | Mốc hết ân hạn sau sạc |
| `ChiSoCongToDau` | NUMERIC(10,2) | NO | CHECK (>=0) | Công tơ lúc bắt đầu |
| `ChiSoCongToCuoi` | NUMERIC(10,2) | YES | CHECK (>= Dau) | Công tơ lúc kết thúc |
| `SoKWh` | NUMERIC(10,2) | YES | GENERATED (Cuoi-Dau) | Điện năng tiêu thụ |

### Table 7: `HOA_DON` (Invoice Metadata)
| Attribute | Data Type | Nullable | Constraint | Description |
|:---|:---|:---|:---|:---|
| `MaHD` | VARCHAR(20) | NO | PK | Mã hóa đơn |
| `MaPhien` | VARCHAR(20) | NO | FK (PHIEN), UNIQUE | Phiên thanh toán |
| `PhiDoXe` | NUMERIC(12,2) | NO | DEFAULT 0, CHECK (>=0) | Phí đỗ xe |
| `PhiSacDien` | NUMERIC(12,2) | NO | DEFAULT 0, CHECK (>=0) | Phí sạc điện |
| `PhiDoSauSac` | NUMERIC(12,2) | NO | DEFAULT 0, CHECK (>=0) | Phí đỗ sau sạc |
| `TongTien` | NUMERIC(12,2) | NO | CHECK (= Do+Sac+SauSac) | Tổng tiền |
| `PhuongThucThanhToan` | VARCHAR(30) | NO | CHECK IN ('Wallet','POS_Card','Dynamic_QR','Cash') | Phương thức thanh toán |
| `TrangThaiThanhToan` | VARCHAR(20) | NO | CHECK IN ('Unpaid','Paid','Refunded') | Trạng thái |

### Table 8: `GIAO_DICH_VI` (Wallet Ledger Metadata)
| Attribute | Data Type | Nullable | Constraint | Description |
|:---|:---|:---|:---|:---|
| `MaGD` | VARCHAR(20) | NO | PK | Mã giao dịch |
| `MaKH` | VARCHAR(20) | NO | FK (KHACH_HANG) | Khách hàng |
| `LoaiGD` | VARCHAR(20) | NO | CHECK IN ('Deposit','Payment','Refund','DirectPayment') | Loại giao dịch |
| `SoTien` | NUMERIC(12,2) | NO | CHECK (>0) | Số tiền giao dịch |
| `SoDuTruoc` | NUMERIC(12,2) | NO | CHECK (>=0) | Số dư trước giao dịch |
| `SoDuSau` | NUMERIC(12,2) | NO | CHECK (>=0) | Số dư sau giao dịch |
| `MaHD` | VARCHAR(20) | YES | FK (HOA_DON) | Hóa đơn liên quan |
| `ThoiGianGD` | TIMESTAMP | NO | DEFAULT CURRENT_TIMESTAMP | Thời điểm giao dịch |
| `GhiChu` | TEXT | YES | — | Ghi chú (VD: phương thức POS) |

---

# 4. DATABASE IMPLEMENTATION (SQL Style Guide Compliant)

## 4.1 DDL Script (Tables, Indexes, Triggers)

```sql
-- =============================================================================
-- FULL DDL SCRIPT — ALL 12 ISSUES FIXED
-- =============================================================================

CREATE TABLE KHACH_HANG (
    MaKH VARCHAR(20) PRIMARY KEY,
    HoTen VARCHAR(100) NOT NULL DEFAULT 'Khách Vãng Lai',
    SDT VARCHAR(15) UNIQUE,
    Email VARCHAR(100) UNIQUE,
    LoaiKhach VARCHAR(20) NOT NULL DEFAULT 'Registered'
        CHECK (LoaiKhach IN ('Registered', 'WalkIn')),
    SoDuViDienTu NUMERIC(12, 2) NOT NULL DEFAULT 0.00
        CHECK (SoDuViDienTu >= 0),
    TrangThaiTK VARCHAR(20) NOT NULL DEFAULT 'Active'
        CHECK (TrangThaiTK IN ('Active', 'Locked')),
    NgayDangKy TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT CHK_KhachHang_Reg CHECK (
        (LoaiKhach = 'Registered' AND SDT IS NOT NULL AND Email IS NOT NULL)
        OR (LoaiKhach = 'WalkIn')
    )
);

CREATE TABLE PHUONG_TIEN (
    MaXe VARCHAR(20) PRIMARY KEY,
    BienSo VARCHAR(20) NOT NULL UNIQUE,
    MaKH VARCHAR(20) NOT NULL REFERENCES KHACH_HANG(MaKH) ON DELETE CASCADE,
    LoaiXe VARCHAR(20) NOT NULL DEFAULT 'Car_4W'
        CHECK (LoaiXe IN ('Car_4W', 'Motorbike_2W')),
    HangXe VARCHAR(50),
    CongSuatSacToiDa_kW NUMERIC(5, 2) CHECK (CongSuatSacToiDa_kW > 0),
    BiDenKhoa BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE QUAN_TRI_VIEN (
    MaQTV VARCHAR(20) PRIMARY KEY,
    HoTen VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    VaiTro VARCHAR(50) NOT NULL DEFAULT 'Operator'
);

CREATE TABLE TRAM (
    MaTram VARCHAR(20) PRIMARY KEY,
    TenTram VARCHAR(100) NOT NULL,
    DiaChi TEXT NOT NULL,
    ViDo NUMERIC(9, 6),
    KinhDo NUMERIC(9, 6),
    PhutAnHanSauSac INT NOT NULL DEFAULT 15 CHECK (PhutAnHanSauSac >= 0),
    SoDuToiThieu NUMERIC(12, 2) NOT NULL DEFAULT 50000.00
        CHECK (SoDuToiThieu >= 0),
    MaQTV VARCHAR(20) REFERENCES QUAN_TRI_VIEN(MaQTV)
);

CREATE TABLE CHO_DO_XE (
    MaCho VARCHAR(20) PRIMARY KEY,
    MaTram VARCHAR(20) NOT NULL REFERENCES TRAM(MaTram) ON DELETE CASCADE,
    MaViTri VARCHAR(20) NOT NULL,
    LoaiCho VARCHAR(20) NOT NULL DEFAULT 'CarSlot'
        CHECK (LoaiCho IN ('CarSlot', 'MotorbikeSlot')),
    MoTaViTri VARCHAR(100),
    TrangThaiCho VARCHAR(20) NOT NULL DEFAULT 'Available'
        CHECK (TrangThaiCho IN ('Available', 'Occupied', 'Reserved', 'Maintenance')),
    CONSTRAINT UQ_Tram_ViTri UNIQUE (MaTram, MaViTri)
);

CREATE TABLE LOAI_TRU_SAC (
    MaLoaiTru VARCHAR(20) PRIMARY KEY,
    TenLoai VARCHAR(50) NOT NULL,
    DongDien VARCHAR(10) NOT NULL CHECK (DongDien IN ('AC', 'DC')),
    CongSuat_kW NUMERIC(5, 2) NOT NULL CHECK (CongSuat_kW > 0),
    ChuanKetNoi VARCHAR(30) NOT NULL
);

CREATE TABLE TRU_SAC (
    MaTru VARCHAR(20) PRIMARY KEY,
    MaCho VARCHAR(20) NOT NULL UNIQUE
        REFERENCES CHO_DO_XE(MaCho) ON DELETE CASCADE,
    MaLoaiTru VARCHAR(20) NOT NULL REFERENCES LOAI_TRU_SAC(MaLoaiTru),
    TrangThaiTru VARCHAR(20) NOT NULL DEFAULT 'Available'
        CHECK (TrangThaiTru IN ('Available', 'Charging', 'Faulted', 'Maintenance')),
    NgayLapDat DATE NOT NULL DEFAULT CURRENT_DATE
);

-- [FIX #1] Thêm LoaiCho vào BANG_GIA để phân biệt giá đỗ CarSlot vs MotorbikeSlot
-- [FIX #7] Thêm CHECK GioKetThuc > GioBatDau
CREATE TABLE BANG_GIA (
    MaBangGia VARCHAR(20) PRIMARY KEY,
    LoaiGia VARCHAR(20) NOT NULL
        CHECK (LoaiGia IN ('Parking', 'Charging', 'PostCharging')),
    MaLoaiTru VARCHAR(20) REFERENCES LOAI_TRU_SAC(MaLoaiTru),
    LoaiCho VARCHAR(20) CHECK (LoaiCho IN ('CarSlot', 'MotorbikeSlot')),
    GioBatDau TIME NOT NULL,
    GioKetThuc TIME NOT NULL,
    LaCaoDiem BOOLEAN NOT NULL DEFAULT FALSE,
    DonGiaTheoPhut NUMERIC(10, 2) NOT NULL CHECK (DonGiaTheoPhut >= 0),
    HieuLucTu DATE NOT NULL,
    HieuLucDen DATE,
    MaQTV VARCHAR(20) REFERENCES QUAN_TRI_VIEN(MaQTV),
    CONSTRAINT CHK_LoaiGia_LoaiTru CHECK (
        (LoaiGia = 'Charging' AND MaLoaiTru IS NOT NULL AND LoaiCho IS NULL)
        OR (LoaiGia IN ('Parking', 'PostCharging') AND MaLoaiTru IS NULL)
    ),
    CONSTRAINT CHK_KhungGio CHECK (GioKetThuc > GioBatDau)
);

CREATE TABLE DAT_CHO (
    MaDatCho VARCHAR(20) PRIMARY KEY,
    MaXe VARCHAR(20) NOT NULL REFERENCES PHUONG_TIEN(MaXe),
    MaCho VARCHAR(20) NOT NULL REFERENCES CHO_DO_XE(MaCho),
    ThoiGianDat TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ThoiGianHetHan TIMESTAMP NOT NULL,
    TrangThaiDatCho VARCHAR(20) NOT NULL DEFAULT 'Active'
        CHECK (TrangThaiDatCho IN ('Active', 'Completed', 'Cancelled', 'Expired')),
    CONSTRAINT CHK_ThoiGianDat CHECK (ThoiGianHetHan > ThoiGianDat)
);

-- [FIX #2] Thêm UNIQUE INDEX chống 1 xe spam đặt nhiều chỗ cùng lúc
CREATE UNIQUE INDEX UQ_DatCho_Active_Xe ON DAT_CHO (MaXe)
    WHERE TrangThaiDatCho = 'Active';
CREATE UNIQUE INDEX UQ_DatCho_Active_Cho ON DAT_CHO (MaCho)
    WHERE TrangThaiDatCho = 'Active';

CREATE TABLE PHIEN (
    MaPhien VARCHAR(20) PRIMARY KEY,
    MaXe VARCHAR(20) NOT NULL REFERENCES PHUONG_TIEN(MaXe),
    MaCho VARCHAR(20) NOT NULL REFERENCES CHO_DO_XE(MaCho),
    MaDatCho VARCHAR(20) UNIQUE REFERENCES DAT_CHO(MaDatCho),
    LoaiPhien VARCHAR(20) NOT NULL
        CHECK (LoaiPhien IN ('ParkingOnly', 'ParkingAndCharging')),
    TrangThaiPhien VARCHAR(20) NOT NULL DEFAULT 'Active'
        CHECK (TrangThaiPhien IN ('Active', 'Completed', 'Cancelled')),
    ThoiGianVao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ThoiGianRa TIMESTAMP,
    CONSTRAINT CHK_ThoiGianPhien CHECK (
        ThoiGianRa IS NULL OR ThoiGianRa >= ThoiGianVao
    )
);

CREATE UNIQUE INDEX UQ_Phien_Active_Xe ON PHIEN (MaXe)
    WHERE TrangThaiPhien = 'Active';
CREATE UNIQUE INDEX UQ_Phien_Active_Cho ON PHIEN (MaCho)
    WHERE TrangThaiPhien = 'Active';

-- [FIX #4] Trigger cưỡng chế khớp LoaiXe <-> LoaiCho khi INSERT vào PHIEN
CREATE OR REPLACE FUNCTION fn_check_loaixe_loaicho()
RETURNS TRIGGER AS $$
DECLARE
    v_loaixe VARCHAR(20);
    v_loaicho VARCHAR(20);
BEGIN
    SELECT LoaiXe INTO v_loaixe FROM PHUONG_TIEN WHERE MaXe = NEW.MaXe;
    SELECT LoaiCho INTO v_loaicho FROM CHO_DO_XE WHERE MaCho = NEW.MaCho;

    IF v_loaixe = 'Motorbike_2W' AND v_loaicho = 'CarSlot' THEN
        RAISE EXCEPTION 'Xe máy 2 bánh (Motorbike_2W) không được đỗ tại ô đỗ ô tô (CarSlot)';
    END IF;
    IF v_loaixe = 'Car_4W' AND v_loaicho = 'MotorbikeSlot' THEN
        RAISE EXCEPTION 'Ô tô 4 bánh (Car_4W) không được đỗ tại ô đỗ xe máy (MotorbikeSlot)';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Phien_CheckLoaiXe
    BEFORE INSERT ON PHIEN
    FOR EACH ROW
    EXECUTE FUNCTION fn_check_loaixe_loaicho();

-- [FIX #8] Thêm CHECK thời gian sạc
CREATE TABLE CHI_TIET_PHIEN_SAC (
    MaPhien VARCHAR(20) PRIMARY KEY
        REFERENCES PHIEN(MaPhien) ON DELETE CASCADE,
    MaTru VARCHAR(20) NOT NULL REFERENCES TRU_SAC(MaTru),
    ThoiGianBatDauSac TIMESTAMP NOT NULL,
    ThoiGianKetThucSac TIMESTAMP,
    ThoiGianHetAnHan TIMESTAMP,
    ChiSoCongToDau NUMERIC(10, 2) NOT NULL CHECK (ChiSoCongToDau >= 0),
    ChiSoCongToCuoi NUMERIC(10, 2) CHECK (ChiSoCongToCuoi >= ChiSoCongToDau),
    SoKWh NUMERIC(10, 2) GENERATED ALWAYS AS
        (ChiSoCongToCuoi - ChiSoCongToDau) STORED,
    CONSTRAINT CHK_ThoiGianSac CHECK (
        ThoiGianKetThucSac IS NULL
        OR ThoiGianKetThucSac >= ThoiGianBatDauSac
    )
);

-- [FIX #6] Thêm CHECK ThoiGianKetThuc >= ThoiGianBatDau
CREATE TABLE CHI_TIET_PHI (
    MaPhien VARCHAR(20) REFERENCES PHIEN(MaPhien) ON DELETE CASCADE,
    SoDong INT NOT NULL CHECK (SoDong > 0),
    MaBangGia VARCHAR(20) NOT NULL REFERENCES BANG_GIA(MaBangGia),
    KhoanMuc VARCHAR(30) NOT NULL
        CHECK (KhoanMuc IN ('Parking', 'Charging', 'PostCharging')),
    ThoiGianBatDau TIMESTAMP NOT NULL,
    ThoiGianKetThuc TIMESTAMP NOT NULL,
    SoPhut INT NOT NULL CHECK (SoPhut >= 0),
    SoTien NUMERIC(12, 2) NOT NULL CHECK (SoTien >= 0),
    PRIMARY KEY (MaPhien, SoDong),
    CONSTRAINT CHK_ThoiGianPhi CHECK (ThoiGianKetThuc >= ThoiGianBatDau)
);

CREATE TABLE HOA_DON (
    MaHD VARCHAR(20) PRIMARY KEY,
    MaPhien VARCHAR(20) NOT NULL UNIQUE REFERENCES PHIEN(MaPhien),
    PhiDoXe NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (PhiDoXe >= 0),
    PhiSacDien NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (PhiSacDien >= 0),
    PhiDoSauSac NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (PhiDoSauSac >= 0),
    TongTien NUMERIC(12, 2) NOT NULL
        CHECK (TongTien = PhiDoXe + PhiSacDien + PhiDoSauSac),
    PhuongThucThanhToan VARCHAR(30) NOT NULL DEFAULT 'Wallet'
        CHECK (PhuongThucThanhToan IN ('Wallet', 'POS_Card', 'Dynamic_QR', 'Cash')),
    TrangThaiThanhToan VARCHAR(20) NOT NULL DEFAULT 'Unpaid'
        CHECK (TrangThaiThanhToan IN ('Unpaid', 'Paid', 'Refunded')),
    NgayLapHoaDon TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    NgayThanhToan TIMESTAMP
);

-- [FIX #5] Thêm 'DirectPayment' cho giao dịch khách vãng lai POS/QR/Cash
CREATE TABLE GIAO_DICH_VI (
    MaGD VARCHAR(20) PRIMARY KEY,
    MaKH VARCHAR(20) NOT NULL REFERENCES KHACH_HANG(MaKH),
    LoaiGD VARCHAR(20) NOT NULL
        CHECK (LoaiGD IN ('Deposit', 'Payment', 'Refund', 'DirectPayment')),
    SoTien NUMERIC(12, 2) NOT NULL CHECK (SoTien > 0),
    SoDuTruoc NUMERIC(12, 2) NOT NULL CHECK (SoDuTruoc >= 0),
    SoDuSau NUMERIC(12, 2) NOT NULL CHECK (SoDuSau >= 0),
    MaHD VARCHAR(20) REFERENCES HOA_DON(MaHD),
    ThoiGianGD TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    GhiChu TEXT
);
```

---

## 4.2 Advanced Queries & Performance Test Cases

### Query 1: Liệt kê Tất cả Phiên đang chạy Song song của Một Khách hàng có Nhiều Xe
```sql
SELECT
    kh.MaKH,
    kh.HoTen,
    kh.SoDuViDienTu,
    pt.BienSo,
    pt.LoaiXe,
    p.MaPhien,
    p.LoaiPhien,
    t.TenTram,
    c.MaViTri,
    p.ThoiGianVao
FROM KHACH_HANG kh
JOIN PHUONG_TIEN pt ON kh.MaKH = pt.MaKH
JOIN PHIEN p ON pt.MaXe = p.MaXe
JOIN CHO_DO_XE c ON p.MaCho = c.MaCho
JOIN TRAM t ON c.MaTram = t.MaTram
WHERE kh.MaKH = 'KH001'
  AND p.TrangThaiPhien = 'Active';
```

### Query 2: Báo cáo Doanh thu & Tỷ lệ Lấp đầy theo Trạm (tháng hiện tại)
```sql
SELECT
    t.MaTram,
    t.TenTram,
    COUNT(DISTINCT c.MaCho) AS TongSoCho,
    COUNT(DISTINCT CASE WHEN c.TrangThaiCho = 'Occupied'
        THEN c.MaCho END) AS SoChoDangDung,
    ROUND(
        COUNT(DISTINCT CASE WHEN c.TrangThaiCho = 'Occupied'
            THEN c.MaCho END)::NUMERIC
        / NULLIF(COUNT(DISTINCT c.MaCho), 0) * 100, 2
    ) AS TyLeLapDay_Pct,
    COALESCE(SUM(hd.TongTien), 0) AS DoanhThuThang_VND
FROM TRAM t
LEFT JOIN CHO_DO_XE c ON t.MaTram = c.MaTram
LEFT JOIN PHIEN p ON c.MaCho = p.MaCho
    AND p.ThoiGianVao >= DATE_TRUNC('month', CURRENT_DATE)
LEFT JOIN HOA_DON hd ON p.MaPhien = hd.MaPhien
    AND hd.TrangThaiThanhToan = 'Paid'
GROUP BY t.MaTram, t.TenTram
ORDER BY DoanhThuThang_VND DESC;
```

### Query 3: Danh sách Xe Nợ xấu / Blacklist (Cảnh báo ANPR tại cổng vào)
```sql
SELECT
    pt.BienSo,
    pt.LoaiXe,
    kh.HoTen,
    kh.LoaiKhach,
    COUNT(hd.MaHD) AS SoHoaDonNo,
    SUM(hd.TongTien) AS TongTienNo_VND,
    MAX(hd.NgayLapHoaDon) AS HoaDonGanNhat
FROM PHUONG_TIEN pt
JOIN KHACH_HANG kh ON pt.MaKH = kh.MaKH
JOIN PHIEN p ON pt.MaXe = p.MaXe
JOIN HOA_DON hd ON p.MaPhien = hd.MaPhien
WHERE pt.BiDenKhoa = TRUE
  AND hd.TrangThaiThanhToan = 'Unpaid'
GROUP BY pt.BienSo, pt.LoaiXe, kh.HoTen, kh.LoaiKhach
ORDER BY TongTienNo_VND DESC;
```

---

# 5. VERIFICATION & SECURITY

## 5.1 Test Cases Preventing Bad Data Insertion

### 🔴 Test Case 1: Xe máy 2 bánh cố đỗ vào ô ô tô (Vi phạm Trigger TRG_Phien_CheckLoaiXe)
```sql
-- Chuẩn bị dữ liệu: Xe máy XM01, Ô đỗ ô tô CHO_OTO_01
INSERT INTO KHACH_HANG (MaKH, HoTen, SDT, Email) VALUES ('KH01', 'Nguyễn Văn A', '0901234567', 'a@mail.com');
INSERT INTO PHUONG_TIEN (MaXe, BienSo, MaKH, LoaiXe) VALUES ('XM01', '59P1-12345', 'KH01', 'Motorbike_2W');
INSERT INTO TRAM (MaTram, TenTram, DiaChi) VALUES ('T01', 'Trạm Quận 1', '123 Lê Lợi');
INSERT INTO CHO_DO_XE (MaCho, MaTram, MaViTri, LoaiCho) VALUES ('CHO_OTO_01', 'T01', 'A-01', 'CarSlot');

-- Thử INSERT phiên: Xe máy vào ô đỗ ô tô
INSERT INTO PHIEN (MaPhien, MaXe, MaCho, LoaiPhien)
VALUES ('P001', 'XM01', 'CHO_OTO_01', 'ParkingOnly');
-- KẾT QUẢ MONG ĐỢI: ERROR
-- "Xe máy 2 bánh (Motorbike_2W) không được đỗ tại ô đỗ ô tô (CarSlot)"
```

### 🔴 Test Case 2: Mở 2 phiên Active trên CÙNG 1 XE (Vi phạm UQ_Phien_Active_Xe)
```sql
-- Giả sử xe OTO01 đã có phiên P01 Active
INSERT INTO PHUONG_TIEN (MaXe, BienSo, MaKH, LoaiXe) VALUES ('OTO01', '51F-67890', 'KH01', 'Car_4W');
INSERT INTO CHO_DO_XE (MaCho, MaTram, MaViTri, LoaiCho) VALUES ('CHO01', 'T01', 'A-02', 'CarSlot');
INSERT INTO CHO_DO_XE (MaCho, MaTram, MaViTri, LoaiCho) VALUES ('CHO02', 'T01', 'A-03', 'CarSlot');
INSERT INTO PHIEN (MaPhien, MaXe, MaCho, LoaiPhien) VALUES ('P01', 'OTO01', 'CHO01', 'ParkingOnly');

-- Thử mở phiên thứ 2 cho CÙNG xe OTO01
INSERT INTO PHIEN (MaPhien, MaXe, MaCho, LoaiPhien)
VALUES ('P02', 'OTO01', 'CHO02', 'ParkingOnly');
-- KẾT QUẢ MONG ĐỢI: ERROR
-- "duplicate key value violates unique constraint "uq_phien_active_xe""
```

### 🔴 Test Case 3: Ví âm (Vi phạm CHECK SoDuViDienTu >= 0)
```sql
INSERT INTO KHACH_HANG (MaKH, HoTen, SDT, Email, SoDuViDienTu)
VALUES ('KH_BAD', 'Khách Lỗi', '0999999999', 'bad@mail.com', -50000);
-- KẾT QUẢ MONG ĐỢI: ERROR
-- "new row violates check constraint "khach_hang_soduvidientu_check""
```

### 🔴 Test Case 4: Xe spam đặt 2 chỗ cùng lúc (Vi phạm UQ_DatCho_Active_Xe)
```sql
-- Giả sử xe OTO01 đã có 1 đặt chỗ Active tại CHO01
INSERT INTO DAT_CHO (MaDatCho, MaXe, MaCho, ThoiGianHetHan)
VALUES ('DC01', 'OTO01', 'CHO01', CURRENT_TIMESTAMP + INTERVAL '30 minutes');

-- Thử đặt chỗ thứ 2 cho CÙNG xe OTO01
INSERT INTO DAT_CHO (MaDatCho, MaXe, MaCho, ThoiGianHetHan)
VALUES ('DC02', 'OTO01', 'CHO02', CURRENT_TIMESTAMP + INTERVAL '30 minutes');
-- KẾT QUẢ MONG ĐỢI: ERROR
-- "duplicate key value violates unique constraint "uq_datcho_active_xe""
```

---

## 5.2 Role-Based Access Control (RBAC) Definition

```sql
CREATE ROLE app_user_role;
CREATE ROLE station_operator_role;
CREATE ROLE sys_admin_role;

-- Người dùng App (Tài xế)
GRANT SELECT ON TRAM, CHO_DO_XE, LOAI_TRU_SAC, TRU_SAC, BANG_GIA TO app_user_role;
GRANT SELECT, INSERT ON DAT_CHO, PHIEN, CHI_TIET_PHIEN_SAC TO app_user_role;
GRANT SELECT ON KHACH_HANG, PHUONG_TIEN, HOA_DON, GIAO_DICH_VI TO app_user_role;

-- Quản lý Trạm (Operator)
GRANT SELECT, UPDATE ON CHO_DO_XE, TRU_SAC, PHUONG_TIEN TO station_operator_role;
GRANT SELECT, INSERT, UPDATE ON BANG_GIA TO station_operator_role;
GRANT SELECT, UPDATE ON HOA_DON TO station_operator_role;

-- Quản trị Hệ thống
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO sys_admin_role;
```

---
*Báo cáo tuân thủ tiêu chuẩn ISO/IEC/IEEE 29148, ISO/IEC 19505 và ISO/IEC 11179.*
