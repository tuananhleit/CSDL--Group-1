**THÔNG TIN ĐỀ TÀI**

| Trường | Nội dung |
| --- | --- |
| Tên đề tài | Quản lý trạm sạc và bãi đỗ xe điện trong thành phố thông minh |
| Mã đề tài | 01 |
| Tên nhóm | Group 01 |
| Thành viên | 1. Lê Tuấn Anh — N25DCAT064 (n25dcat064@student.ptithcm.edu.vn)<br>2. Đỗ Huy Ba — N25DCAT068 (n25dcat068@student.ptithcm.edu.vn)<br>3. Châu Gia Bảo — N22DCAT005 (n22dcat005@student.ptithcm.edu.vn) |

# 1. Giới thiệu và phạm vi dự án (phỏng theo chuẩn ISO/IEC/IEEE 29148)

Tài liệu này trình bày các yêu cầu nền tảng và phạm vi cho hệ thống Quản lý bãi đỗ xe và sạc xe điện của thành phố thông minh. Hệ thống tập trung đáp ứng nhu cầu ngày càng tăng của người dùng xe điện ở đô thị: tìm được chỗ đỗ, giữ được chỗ, sạc đúng loại súng và thanh toán minh bạch theo thời gian thực.

Tài liệu gồm toàn bộ quá trình từ phân tích yêu cầu, thiết kế cơ sở dữ liệu (sơ đồ EER, lược đồ quan hệ, chuẩn hóa) đến cài đặt trên MySQL 8.0: DDL, trigger, stored procedure, phân quyền, dữ liệu mẫu, truy vấn và kiểm thử. Mô hình dữ liệu bao gồm **xe máy điện**, **khách vãng lai**, **tiền cọc đặt chỗ**, **hạn mức sạc tự ngắt** và **sổ cái ví bất biến**.

## 1.1 Mục tiêu hệ thống

Hệ thống hướng tới năm mục tiêu chính:

- Giúp người lái xe tìm và giữ trước chỗ đỗ còn trống, thay vì phải chạy vòng quanh bãi để tìm.
- Theo dõi trạng thái chỗ đỗ và trụ sạc theo thời gian thực để khai thác hết công suất của bãi.
- Cho phép đặt giá khác nhau theo khung giờ cao điểm hoặc thấp điểm và theo công suất của từng loại trụ sạc.
- Tính tiền và lập hóa đơn rõ ràng cho từng phiên; mọi biến động số dư ví đều ghi lại để đối chiếu.
- Bảo vệ khách hàng và doanh nghiệp: tự ngắt sạc khi chạm hạn mức hoặc sát số dư ví, hoàn tiền khi sự cố, thu cọc chống bỏ chỗ (no-show), khóa xe nợ xấu.

## 1.2 Phạm vi

**Trong phạm vi:** quản lý trạm, chỗ đỗ, trụ sạc và cấp công suất; hồ sơ khách hàng (thành viên và khách vãng lai) và phương tiện (ô tô 4 bánh, xe máy 2 bánh); đặt chỗ trước có tiền cọc; phiên sử dụng (chỉ đỗ xe hoặc đỗ và sạc); bảng giá theo khung giờ cao điểm hoặc thấp điểm, theo loại trụ và loại chỗ; tính phí, lập hóa đơn, khấu trừ tiền cọc; ví điện tử với sổ cái bất biến; thanh toán bằng ví, QR động, thẻ POS hoặc tiền mặt; phân quyền theo vai trò.

**Ngoài phạm vi:** việc kết nối trực tiếp với phần cứng trụ sạc (nhóm chỉ lưu trạng thái và chỉ số công tơ do thiết bị gửi về), cổng thanh toán và ngân hàng của bên thứ ba (nhóm chỉ lưu mã giao dịch đối tác để chống trùng), điều tiết lưới điện, dẫn đường, chương trình khách hàng thân thiết và nhận diện biển số tự động.

## 1.3 Quy tắc nghiệp vụ và các ràng buộc

### A. Khách hàng và phương tiện

- Mỗi khách hàng có mã riêng (MaKH). Khách thuộc một trong hai loại: **Registered** (thành viên, bắt buộc có số điện thoại hoặc email để nhận hóa đơn) và **WalkIn** (khách vãng lai, không cần thông tin liên hệ). Số điện thoại và email không trùng giữa các khách.
- Mỗi phương tiện có biển số duy nhất, thuộc đúng một khách hàng, có loại xe (**Car_4W** hoặc **Motorbike_2W**) và chuẩn cổng sạc (CCS2, Type2, GB_T, CHAdeMO, AC_Plug, Other). Xe có nợ chưa thanh toán bị gắn cờ **BiDenKhoa** và không được đặt chỗ hay mở phiên.
- Muốn mở phiên, tài khoản phải ở trạng thái Active; với khách Registered, số dư ví phải đạt mức tối thiểu của trạm (mặc định 20.000đ).
- Mọi thay đổi số dư ví đều ghi vào sổ cái GIAO_DICH_VI (nạp tiền, thanh toán, hoàn tiền, thanh toán trực tiếp). Sổ cái là bảng chỉ thêm (append-only): cấm sửa hoặc xóa.

### B. Trạm, chỗ đỗ và trụ sạc

- Mỗi chỗ đỗ thuộc một trạm. Mã vị trí (A-01, B-02...) chỉ cần không trùng trong cùng một trạm. Chỗ đỗ có loại **CarSlot** hoặc **MotorbikeSlot**: ô tô chỉ đỗ ở CarSlot, xe máy chỉ đỗ ở MotorbikeSlot.
- Nhóm tách riêng chỗ đỗ (CHO_DO_XE) và trụ sạc (TRU_SAC): có chỗ đỗ không gắn trụ, và khi trụ hỏng thì chỗ đó vẫn dùng được để đỗ. Mỗi chỗ có tối đa một trụ; một trụ gắn đúng một chỗ.
- Trụ sạc không lưu thẳng số kW mà tham chiếu sang LOAI_TRU_SAC (dòng điện AC/DC, công suất kW, chuẩn kết nối). Giá sạc gắn với loại trụ, không gắn với từng trụ riêng lẻ.
- Chuẩn súng sạc của trụ phải tương thích cổng sạc của xe (trừ khi một bên là Other). Trụ ở trạng thái Faulted hoặc Maintenance thì không được mở phiên sạc; chỗ đỗ ở trạng thái Maintenance thì không nhận đặt chỗ và phiên mới.

### C. Đặt chỗ và kiểm tra chỗ trống

- Khi cần, khách chọn một chỗ còn trống và đặt trước; đặt chỗ có thể kèm **tiền cọc** (TienCoc) chống bỏ chỗ. Mỗi đặt chỗ có thời hạn giữ chỗ; quá hạn thì chuyển sang Expired.
- Mỗi xe chỉ có tối đa một đặt chỗ đang hiệu lực, và mỗi chỗ đỗ chỉ có tối đa một đặt chỗ đang hiệu lực.
- Phiên mở từ một đặt chỗ phải đúng xe và đúng chỗ đã đặt. Tại một thời điểm, mỗi xe và mỗi chỗ chỉ có một phiên đang chạy.

### D. Cách tính tiền

- Chỉ đỗ xe: tính theo phút từ lúc xe vào đến lúc xe ra, theo bảng giá của loại chỗ (CarSlot hoặc MotorbikeSlot) và khung giờ.
- Đỗ và sạc: trong lúc đang sạc chỉ tính tiền sạc theo loại trụ (đơn giá theo phút gắn với công suất trụ); khoảng đỗ trước khi cắm sạc tính như đỗ xe.
- Sau khi sạc xong khách được **ân hạn miễn phí** (cấu hình theo trạm, mặc định 15 phút). Hết ân hạn mà xe chưa rời chỗ thì tính **phí đỗ sau sạc** để tránh chiếm trụ.
- Khách có thể đặt hạn mức sạc (theo tiền hoặc theo kWh); hệ thống tự ngắt khi đạt hạn mức hoặc khi tiền điện tiến sát số dư ví. Phiên bị sự cố (mất điện, dừng khẩn cấp) có trạng thái Interrupted và có thể hoàn tiền.
- Hóa đơn: Tổng tiền = phí đỗ xe + phí sạc + phí đỗ sau sạc − tiền khấu trừ (cọc, ưu đãi). Phương thức thanh toán: ví, thẻ POS, QR động hoặc tiền mặt.

### E. Quản trị viên và phân quyền

- Quản trị viên có mã riêng (MaQTV) và phụ trách trạm. Quản trị viên thiết lập bảng giá; mỗi dòng giá ghi nhận người đặt và khoảng thời gian hiệu lực, nên khi đổi giá thì giá cũ vẫn được giữ để tra cứu hóa đơn trước đó.
- Hệ thống có ba vai trò cơ sở dữ liệu: **app_user_role** (ứng dụng của tài xế), **station_operator_role** (vận hành trạm, thu ngân khách vãng lai) và **sys_admin_role** (quản trị toàn quyền).

# 2. Thiết kế cơ sở dữ liệu

## 2.1 Mô hình khái niệm (sơ đồ EER)

Mô hình EER dùng ký hiệu Chen: hình chữ nhật là thực thể (viền đơn là thực thể mạnh, viền kép là thực thể yếu), hình thoi là mối quan hệ (viền kép là quan hệ định danh), hình elip là thuộc tính. Thuộc tính gạch dưới là khóa, gạch đứt là khóa bộ phận, elip nét đứt là thuộc tính dẫn xuất. Sơ đồ đầy đủ ở trang sau.

Mô hình gồm 13 thực thể (12 thực thể mạnh: KHACH_HANG, PHUONG_TIEN, GIAO_DICH_VI, QUAN_TRI_VIEN, TRAM, CHO_DO_XE, LOAI_TRU_SAC, TRU_SAC, BANG_GIA, DAT_CHO, PHIEN, HOA_DON và 1 thực thể yếu: CHI_TIET_PHI), 2 lớp con (PHIEN_SAC, PHIEN_DO_XE) và 18 mối quan hệ.

![Hình 1](images/figure1.png)

*Hình 1. Sơ đồ EER (ký hiệu Chen) của hệ thống*

Giải thích các thành phần chính của mô hình:

- Thực thể mạnh: KHACH_HANG, PHUONG_TIEN, GIAO_DICH_VI, QUAN_TRI_VIEN, TRAM, CHO_DO_XE, LOAI_TRU_SAC, TRU_SAC, BANG_GIA, DAT_CHO, PHIEN và HOA_DON — mỗi thực thể có khóa chính riêng.
- Thực thể yếu CHI_TIET_PHI phụ thuộc vào PHIEN, khóa chính là cặp (MaPhien, SoDong). Thuộc tính khóa bộ phận là SoDong, mối quan hệ GOM là quan hệ định danh.
- PHIEN được chuyên biệt hóa thành hai lớp con là PHIEN_DO_XE và PHIEN_SAC, phân biệt bằng thuộc tính LoaiPhien (ParkingOnly hoặc ParkingAndCharging). Chuyên biệt hóa này toàn phần (phiên nào cũng thuộc một trong hai loại) và tách rời (không thuộc cả hai).
- PHIEN_DO_XE không có thuộc tính riêng nên khi ánh xạ sẽ không sinh bảng. PHIEN_SAC có các mốc thời gian sạc, chỉ số công tơ, hạn mức sạc, trạng thái và lý do kết thúc sạc; khi ánh xạ thành bảng CHI_TIET_PHIEN_SAC dùng chung khóa với PHIEN.
- Thuộc tính dẫn xuất: TongTien của HOA_DON (phí đỗ + phí sạc + phí đỗ sau sạc − khấu trừ) và SoKWh của PHIEN_SAC (chỉ số cuối − chỉ số đầu); cả hai được cài đặt bằng cột sinh tự động (GENERATED ... STORED).
- Quan hệ giữa CHO_DO_XE và TRU_SAC là 1:0..1 — một chỗ có thể không có trụ, còn mỗi trụ gắn đúng một chỗ. Quan hệ KICH_HOAT giữa DAT_CHO và PHIEN là 0..1 – 0..1: một đặt chỗ có thể chuyển thành một phiên, và một phiên có thể mở mà không cần đặt trước.
- Quan hệ THANH_TOAN giữa GIAO_DICH_VI và HOA_DON là 0..1 – 0..1: giao dịch nạp tiền không gắn hóa đơn, còn hóa đơn chưa thanh toán thì chưa có giao dịch.

## 2.2 Ánh xạ sang lược đồ quan hệ

Từ mô hình EER, nhóm ánh xạ sang 14 bảng theo các quy tắc: thực thể mạnh thành bảng; thực thể yếu thành bảng có khóa chính gồm khóa của thực thể chủ và khóa bộ phận; quan hệ 1:N thêm khóa ngoại về phía N; quan hệ 1:1 thêm khóa ngoại kèm ràng buộc UNIQUE; chuyên biệt hóa toàn phần tách rời được ánh xạ theo cách một bảng cha PHIEN cùng một bảng con CHI_TIET_PHIEN_SAC cho lớp con có thuộc tính riêng.

Bảng 1 liệt kê các bảng, thuộc tính và ràng buộc chính; PK là khóa chính, FK là khóa ngoại, U là ràng buộc UNIQUE.

| Bảng | Thuộc tính | Ràng buộc chính |
| --- | --- | --- |
| KHACH_HANG | MaKH (PK), HoTen, SDT (U), Email (U), LoaiKhach, SoDuViDienTu, TrangThaiTK, NgayDangKy | SoDuViDienTu ≥ 0; LoaiKhach ∈ {Registered, WalkIn}; TrangThaiTK ∈ {Active, Locked}; khách Registered phải có SDT hoặc Email |
| PHUONG_TIEN | MaXe (PK), BienSo (U), MaKH (FK), LoaiXe, ChuanSac, HangXe, CongSuatSacToiDa_kW, BiDenKhoa | LoaiXe ∈ {Car_4W, Motorbike_2W}; ChuanSac ∈ {CCS2, Type2, GB_T, CHAdeMO, AC_Plug, Other}; công suất > 0 |
| QUAN_TRI_VIEN | MaQTV (PK), HoTen, Email (U), VaiTro | — |
| TRAM | MaTram (PK), TenTram, DiaChi, ViDo, KinhDo, PhutAnHanSauSac, SoDuToiThieu, MaQTV (FK) | PhutAnHanSauSac ≥ 0 (mặc định 15); SoDuToiThieu ≥ 0 (mặc định 20.000) |
| CHO_DO_XE | MaCho (PK), MaTram (FK), MaViTri, LoaiCho, MoTaViTri, TrangThaiCho | UNIQUE (MaTram, MaViTri); LoaiCho ∈ {CarSlot, MotorbikeSlot}; TrangThaiCho ∈ {Available, Occupied, Reserved, Maintenance} |
| LOAI_TRU_SAC | MaLoaiTru (PK), TenLoai, DongDien, CongSuat_kW, ChuanKetNoi | DongDien ∈ {AC, DC}; CongSuat_kW > 0 |
| TRU_SAC | MaTru (PK), MaCho (FK, U), MaLoaiTru (FK), TrangThaiTru, NgayLapDat | TrangThaiTru ∈ {Available, Charging, Faulted, Maintenance}; MaCho UNIQUE (quan hệ 1:0..1) |
| BANG_GIA | MaBangGia (PK), LoaiGia, MaLoaiTru (FK), LoaiCho, GioBatDau, GioKetThuc, LaCaoDiem, DonGiaTheoPhut, HieuLucTu, HieuLucDen, MaQTV (FK) | LoaiGia ∈ {Parking, Charging, PostCharging}; Charging bắt buộc có MaLoaiTru và không có LoaiCho; Parking/PostCharging bắt buộc có LoaiCho và không có MaLoaiTru; GioKetThuc > GioBatDau; HieuLucDen ≥ HieuLucTu |
| DAT_CHO | MaDatCho (PK), MaXe (FK), MaCho (FK), ThoiGianDat, ThoiGianHetHan, TienCoc, TrangThaiDatCho | ThoiGianHetHan > ThoiGianDat; TienCoc ≥ 0; mỗi xe và mỗi chỗ có tối đa một đặt chỗ Active (ràng buộc UNIQUE một phần; MySQL cài bằng cột sinh XeDangGiu, ChoDangGiu kèm UNIQUE) |
| PHIEN | MaPhien (PK), MaXe (FK), MaCho (FK), MaDatCho (FK, U), LoaiPhien, TrangThaiPhien, ThoiGianVao, ThoiGianRa, GhiChu | LoaiPhien ∈ {ParkingOnly, ParkingAndCharging}; TrangThaiPhien ∈ {Active, Completed, Cancelled, Interrupted}; ThoiGianRa ≥ ThoiGianVao; mỗi xe và mỗi chỗ có tối đa một phiên Active (ràng buộc UNIQUE một phần; MySQL cài bằng cột sinh XeDangHoatDong, ChoDangHoatDong kèm UNIQUE) |
| CHI_TIET_PHIEN_SAC | MaPhien (PK, FK), MaTru (FK), ThoiGianBatDauSac, ThoiGianKetThucSac, ThoiGianHetAnHan, ThoiGianRutSungSac, ChiSoCongToDau, ChiSoCongToCuoi, SoKWh (sinh), HanMucSac_VND, HanMucSac_kWh, TrangThaiSac, LyDoKetThuc | ChiSoCongToCuoi ≥ ChiSoCongToDau; SoKWh = cuối − đầu; hạn mức > 0 nếu có; TrangThaiSac ∈ {Charging, Completed, Interrupted, Suspended}; LyDoKetThuc thuộc danh sách 7 lý do |
| CHI_TIET_PHI | MaPhien (PK, FK), SoDong (PK), MaBangGia (FK), KhoanMuc, ThoiGianBatDau, ThoiGianKetThuc, SoPhut, SoTien | KhoanMuc ∈ {Parking, Charging, PostCharging}; SoPhut ≥ 0; SoTien ≥ 0; ThoiGianKetThuc ≥ ThoiGianBatDau |
| HOA_DON | MaHD (PK), MaPhien (FK, U), PhiDoXe, PhiSacDien, PhiDoSauSac, TienKhauTru, TongTien (sinh), PhuongThucThanhToan, TrangThaiThanhToan, MaGiaoDichNgoai, NgayLapHoaDon, NgayThanhToan | TienKhauTru ≤ tổng các khoản phí; TongTien = phí đỗ + phí sạc + phí đỗ sau sạc − khấu trừ; PhuongThuc ∈ {Wallet, POS_Card, Dynamic_QR, Cash}; TrangThai ∈ {Unpaid, Paid, Refunded}; NgayThanhToan ≥ NgayLapHoaDon |
| GIAO_DICH_VI | MaGD (PK), MaKH (FK), LoaiGD, SoTien, SoDuTruoc, SoDuSau, MaHD (FK), MaGiaoDichDoiTac (U), ThoiGianGD, GhiChu | LoaiGD ∈ {Deposit, Payment, Refund, DirectPayment}; SoTien > 0; SoDuSau khớp từng loại giao dịch (Deposit/Refund: cộng, Payment: trừ, DirectPayment: không đổi); MaGiaoDichDoiTac là khóa chống trùng webhook |

*Bảng 1. Các bảng của lược đồ quan hệ*

![Hình 2](images/figure2.png)

*Hình 2. Lược đồ quan hệ (ánh xạ từ sơ đồ EER) — 14 bảng*

Các khóa ngoại của lược đồ (19 khóa ngoại): PHUONG_TIEN.MaKH → KHACH_HANG; GIAO_DICH_VI.MaKH → KHACH_HANG; GIAO_DICH_VI.MaHD → HOA_DON; HOA_DON.MaPhien → PHIEN; DAT_CHO.MaXe → PHUONG_TIEN; DAT_CHO.MaCho → CHO_DO_XE; PHIEN.MaXe → PHUONG_TIEN; PHIEN.MaCho → CHO_DO_XE; PHIEN.MaDatCho → DAT_CHO; CHI_TIET_PHIEN_SAC.MaPhien → PHIEN; CHI_TIET_PHIEN_SAC.MaTru → TRU_SAC; CHI_TIET_PHI.MaPhien → PHIEN; CHI_TIET_PHI.MaBangGia → BANG_GIA; CHO_DO_XE.MaTram → TRAM; TRU_SAC.MaCho → CHO_DO_XE; TRU_SAC.MaLoaiTru → LOAI_TRU_SAC; BANG_GIA.MaLoaiTru → LOAI_TRU_SAC; BANG_GIA.MaQTV → QUAN_TRI_VIEN; TRAM.MaQTV → QUAN_TRI_VIEN.

Ngoài các ràng buộc khai báo trong bảng, một số quy tắc liên bảng không thể biểu diễn bằng CHECK nên được cưỡng chế bằng trigger (mục 3.3): khớp loại xe và loại chỗ, chỗ bảo trì không nhận phiên, số dư tối thiểu, chuẩn súng sạc, xe bị khóa, đặt chỗ khớp phiên, đồng bộ trạng thái chỗ và trụ, tự tính ân hạn, bảo vệ sổ cái.

## 2.3 Chuẩn hóa

Nhóm kiểm tra từng bảng theo phụ thuộc hàm xác định bởi các khóa. Bảng 2 liệt kê các khóa ứng viên và kết luận về dạng chuẩn. Tất cả các bảng đều đạt BCNF: mọi phụ thuộc hàm không tầm thường đều có vế trái là siêu khóa.

| Bảng | Khóa ứng viên | Dạng chuẩn cao nhất |
| --- | --- | --- |
| KHACH_HANG | MaKH; SDT; Email | BCNF |
| PHUONG_TIEN | MaXe; BienSo | BCNF |
| QUAN_TRI_VIEN | MaQTV; Email | BCNF |
| TRAM | MaTram | BCNF |
| CHO_DO_XE | MaCho; (MaTram, MaViTri) | BCNF |
| LOAI_TRU_SAC | MaLoaiTru | BCNF |
| TRU_SAC | MaTru; MaCho | BCNF |
| BANG_GIA | MaBangGia | BCNF |
| DAT_CHO | MaDatCho | BCNF |
| PHIEN | MaPhien; MaDatCho | BCNF |
| CHI_TIET_PHIEN_SAC | MaPhien | BCNF (SoKWh là cột sinh, không lưu độc lập) |
| CHI_TIET_PHI | (MaPhien, SoDong) | BCNF |
| HOA_DON | MaHD; MaPhien | BCNF (TongTien là cột sinh) |
| GIAO_DICH_VI | MaGD; MaGiaoDichDoiTac | BCNF |

*Bảng 2. Khóa ứng viên và dạng chuẩn của các bảng*

Hai cột sinh (SoKWh, TongTien) là giá trị dẫn xuất nhưng được khai báo GENERATED ALWAYS AS ... STORED, nên cơ sở dữ liệu tự tính và không thể bị nhập lệch; vì vậy không phá vỡ chuẩn hóa. Các cột tổng hợp theo phí (PhiDoXe, PhiSacDien, PhiDoSauSac) trong HOA_DON được giữ lại có chủ đích để chốt giá trị tại thời điểm lập hóa đơn; tính đúng đắn của chúng được đối chiếu với CHI_TIET_PHI bằng truy vấn Q10 (mục 3.7). Tương tự, số dư SoDuViDienTu là số dư hiện hành, còn lịch sử nằm ở sổ cái; truy vấn Q11 đối chiếu hai nguồn này.

# 3. Cài đặt cơ sở dữ liệu

## 3.1 Cấu trúc script và thứ tự chạy

Phần cài đặt viết cho **MySQL 8.0.16 trở lên** (từ phiên bản này MySQL mới thực thi ràng buộc CHECK) và được tách thành từng tệp, **mỗi bảng một tệp** DDL và một tệp dữ liệu, trong thư mục **phase3_mysql**: thư mục ddl/ gồm 01_KHACH_HANG.sql đến 14_GIAO_DICH_VI.sql cùng 15_TRIGGERS.sql, 16_RBAC.sql, 17_PROCEDURES.sql; thư mục data/ có tệp dữ liệu mẫu cùng tên cho từng bảng và 99_TRANG_THAI_HIEN_TAI.sql; thư mục queries/ có 20_QUERIES.sql và 21_VIEWS.sql. Tệp run_all.sql chạy toàn bộ theo đúng thứ tự (trigger, thủ tục rồi mới đến phân quyền; dữ liệu nạp trong một giao dịch): đứng trong thư mục phase3_mysql và chạy mysql -u root -p --default-character-set=utf8mb4 < run_all.sql. Để chạy trong MySQL Workbench dùng tệp gộp **Phase3_Group01_MySQL.sql** (File > Run SQL Script). Tệp 00_DROP_ALL.sql xóa và tạo lại database smart_ev_parking, nên chỉ chạy trên database dành cho đồ án. Phần cài đặt chuyển từ script DDL chung của nhóm viết cho PostgreSQL (00_FULL_DDL.sql, gồm các tệp 01–17), bổ sung dữ liệu mẫu, truy vấn và view.

| Phần | Nội dung | Ghi chú |
| --- | --- | --- |
| A | DROP/CREATE DATABASE (chạy lại được) và 14 lệnh CREATE TABLE, chỉ mục | Tệp 00 và 01–14; InnoDB, utf8mb4 |
| B | 11 quy tắc nghiệp vụ = 17 trigger và 1 thủ tục, 1 hàm dùng chung | Tệp 15 (trigger 1–11) |
| C | 4 stored procedure | Tệp 17; phải chạy trước phần phân quyền |
| D | Phân quyền RBAC (3 vai trò) | Tệp 16 |
| E | Dữ liệu mẫu (DML) | Bật trigger khi nạp |
| F | 13 truy vấn phức tạp | Phần 3.7 |
| G | 2 view | Phần 3.8 |

## 3.2 Định nghĩa bảng (DDL)

Mã dưới đây là phần DDL của 14 bảng đúng như trong script MySQL (đã lược bỏ các dòng kẻ banner). So với bản PostgreSQL, DDL có các điểm khác sau:

- Khóa ngoại khai báo bằng mệnh đề FOREIGN KEY riêng, vì MySQL bỏ qua REFERENCES viết ngay sau tên cột.
- Kiểu dữ liệu: TIMESTAMP chuyển thành DATETIME, NUMERIC thành DECIMAL, BOOLEAN là TINYINT(1); ngày mặc định dùng DEFAULT (CURRENT_DATE).
- MySQL không có chỉ mục UNIQUE một phần (WHERE ...). Quy tắc 'mỗi xe, mỗi chỗ chỉ một phiên Active' và 'mỗi xe, mỗi chỗ chỉ một đặt chỗ Active' được cài bằng cột sinh (chỉ có giá trị khi trạng thái là Active, ngược lại NULL) kèm ràng buộc UNIQUE; UNIQUE bỏ qua NULL nên các phiên đã kết thúc không bị chặn.
- Mọi ràng buộc CHECK được đặt tên (CHK_...), nên thông báo lỗi của MySQL nêu rõ ràng buộc nào bị vi phạm. Collation utf8mb4_unicode_ci nên so sánh chuỗi không phân biệt hoa thường.

```sql
CREATE TABLE KHACH_HANG (
    MaKH            VARCHAR(20)     NOT NULL,
    HoTen           VARCHAR(100)    NOT NULL DEFAULT 'Khách Vãng Lai',
    SDT             VARCHAR(15)     NULL,
    Email           VARCHAR(100)    NULL,
    LoaiKhach       VARCHAR(20)     NOT NULL DEFAULT 'Registered',
    SoDuViDienTu    DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,
    TrangThaiTK     VARCHAR(20)     NOT NULL DEFAULT 'Active',
    NgayDangKy      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (MaKH),
    UNIQUE KEY UQ_KhachHang_SDT (SDT),
    UNIQUE KEY UQ_KhachHang_Email (Email),
    CONSTRAINT CHK_KhachHang_LoaiKhach CHECK (LoaiKhach IN ('Registered', 'WalkIn')),
    CONSTRAINT CHK_KhachHang_SoDu      CHECK (SoDuViDienTu >= 0),
    CONSTRAINT CHK_KhachHang_TrangThai CHECK (TrangThaiTK IN ('Active', 'Locked')),

    CONSTRAINT CHK_KhachHang_Reg CHECK (
        (LoaiKhach = 'Registered' AND (SDT IS NOT NULL OR Email IS NOT NULL))
        OR (LoaiKhach = 'WalkIn')
    )
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE INDEX IDX_KhachHang_LoaiKhach ON KHACH_HANG (LoaiKhach);

CREATE TABLE PHUONG_TIEN (
    MaXe                VARCHAR(20)     NOT NULL,
    BienSo              VARCHAR(20)     NOT NULL,
    MaKH                VARCHAR(20)     NOT NULL,
    LoaiXe              VARCHAR(20)     NOT NULL DEFAULT 'Car_4W',
    ChuanSac            VARCHAR(20)     NOT NULL DEFAULT 'CCS2',
    HangXe              VARCHAR(50)     NULL,
    CongSuatSacToiDa_kW DECIMAL(5, 2)   NULL,
    BiDenKhoa           BOOLEAN         NOT NULL DEFAULT FALSE,

    PRIMARY KEY (MaXe),
    UNIQUE KEY UQ_PhuongTien_BienSo (BienSo),
    CONSTRAINT FK_PhuongTien_KhachHang FOREIGN KEY (MaKH) REFERENCES KHACH_HANG (MaKH),
    CONSTRAINT CHK_PhuongTien_LoaiXe   CHECK (LoaiXe IN ('Car_4W', 'Motorbike_2W')),
    CONSTRAINT CHK_PhuongTien_ChuanSac CHECK (ChuanSac IN ('CCS2', 'Type2', 'GB_T', 'CHAdeMO', 'AC_Plug', 'Other')),
    CONSTRAINT CHK_PhuongTien_CongSuat CHECK (CongSuatSacToiDa_kW IS NULL OR CongSuatSacToiDa_kW > 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE INDEX IDX_PhuongTien_MaKH ON PHUONG_TIEN (MaKH);

CREATE TABLE QUAN_TRI_VIEN (
    MaQTV   VARCHAR(20)     NOT NULL,
    HoTen   VARCHAR(100)    NOT NULL,
    Email   VARCHAR(100)    NOT NULL,
    VaiTro  VARCHAR(50)     NOT NULL DEFAULT 'Operator',

    PRIMARY KEY (MaQTV),
    UNIQUE KEY UQ_QuanTriVien_Email (Email)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE TRAM (
    MaTram          VARCHAR(20)     NOT NULL,
    TenTram         VARCHAR(100)    NOT NULL,
    DiaChi          TEXT            NOT NULL,
    ViDo            DECIMAL(9, 6)   NULL,
    KinhDo          DECIMAL(9, 6)   NULL,
    PhutAnHanSauSac INT             NOT NULL DEFAULT 15,
    SoDuToiThieu    DECIMAL(12, 2)  NOT NULL DEFAULT 20000.00,
    MaQTV           VARCHAR(20)     NULL,

    PRIMARY KEY (MaTram),
    CONSTRAINT FK_Tram_QuanTriVien FOREIGN KEY (MaQTV) REFERENCES QUAN_TRI_VIEN (MaQTV),
    CONSTRAINT CHK_Tram_AnHan      CHECK (PhutAnHanSauSac >= 0),
    CONSTRAINT CHK_Tram_SoDuToiThieu CHECK (SoDuToiThieu >= 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE CHO_DO_XE (
    MaCho           VARCHAR(20)     NOT NULL,
    MaTram          VARCHAR(20)     NOT NULL,
    MaViTri         VARCHAR(20)     NOT NULL,
    LoaiCho         VARCHAR(20)     NOT NULL DEFAULT 'CarSlot',
    MoTaViTri       VARCHAR(100)    NULL,
    TrangThaiCho    VARCHAR(20)     NOT NULL DEFAULT 'Available',

    PRIMARY KEY (MaCho),

    CONSTRAINT UQ_Tram_ViTri UNIQUE (MaTram, MaViTri),
    CONSTRAINT FK_ChoDoXe_Tram FOREIGN KEY (MaTram) REFERENCES TRAM (MaTram),
    CONSTRAINT CHK_ChoDoXe_LoaiCho   CHECK (LoaiCho IN ('CarSlot', 'MotorbikeSlot')),
    CONSTRAINT CHK_ChoDoXe_TrangThai CHECK (TrangThaiCho IN ('Available', 'Occupied', 'Reserved', 'Maintenance'))
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE INDEX IDX_ChoDoXe_Tram_TrangThai ON CHO_DO_XE (MaTram, TrangThaiCho);

CREATE TABLE LOAI_TRU_SAC (
    MaLoaiTru   VARCHAR(20)     NOT NULL,
    TenLoai     VARCHAR(50)     NOT NULL,
    DongDien    VARCHAR(10)     NOT NULL,
    CongSuat_kW DECIMAL(5, 2)   NOT NULL,
    ChuanKetNoi VARCHAR(30)     NOT NULL,

    PRIMARY KEY (MaLoaiTru),
    CONSTRAINT CHK_LoaiTruSac_DongDien CHECK (DongDien IN ('AC', 'DC')),
    CONSTRAINT CHK_LoaiTruSac_CongSuat CHECK (CongSuat_kW > 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE TRU_SAC (
    MaTru           VARCHAR(20)     NOT NULL,
    MaCho           VARCHAR(20)     NOT NULL,
    MaLoaiTru       VARCHAR(20)     NOT NULL,
    TrangThaiTru    VARCHAR(20)     NOT NULL DEFAULT 'Available',
    NgayLapDat      DATE            NOT NULL DEFAULT (CURRENT_DATE),

    PRIMARY KEY (MaTru),
    UNIQUE KEY UQ_TruSac_MaCho (MaCho),
    CONSTRAINT FK_TruSac_ChoDoXe  FOREIGN KEY (MaCho)     REFERENCES CHO_DO_XE (MaCho),
    CONSTRAINT FK_TruSac_LoaiTru  FOREIGN KEY (MaLoaiTru) REFERENCES LOAI_TRU_SAC (MaLoaiTru),
    CONSTRAINT CHK_TruSac_TrangThai CHECK (TrangThaiTru IN ('Available', 'Charging', 'Faulted', 'Maintenance'))
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE BANG_GIA (
    MaBangGia       VARCHAR(20)     NOT NULL,
    LoaiGia         VARCHAR(20)     NOT NULL,
    MaLoaiTru       VARCHAR(20)     NULL,
    LoaiCho         VARCHAR(20)     NULL,
    GioBatDau       TIME            NOT NULL,
    GioKetThuc      TIME            NOT NULL,
    LaCaoDiem       BOOLEAN         NOT NULL DEFAULT FALSE,
    DonGiaTheoPhut  DECIMAL(10, 2)  NOT NULL,
    HieuLucTu       DATE            NOT NULL,
    HieuLucDen      DATE            NULL,
    MaQTV           VARCHAR(20)     NULL,

    PRIMARY KEY (MaBangGia),
    CONSTRAINT FK_BangGia_LoaiTru FOREIGN KEY (MaLoaiTru) REFERENCES LOAI_TRU_SAC (MaLoaiTru),
    CONSTRAINT FK_BangGia_QTV     FOREIGN KEY (MaQTV)     REFERENCES QUAN_TRI_VIEN (MaQTV),
    CONSTRAINT CHK_BangGia_LoaiGia CHECK (LoaiGia IN ('Parking', 'Charging', 'PostCharging')),
    CONSTRAINT CHK_BangGia_LoaiCho CHECK (LoaiCho IS NULL OR LoaiCho IN ('CarSlot', 'MotorbikeSlot')),
    CONSTRAINT CHK_BangGia_DonGia  CHECK (DonGiaTheoPhut >= 0),

    CONSTRAINT CHK_LoaiGia_LoaiTru CHECK (
        (LoaiGia = 'Charging' AND MaLoaiTru IS NOT NULL AND LoaiCho IS NULL)
        OR (LoaiGia IN ('Parking', 'PostCharging') AND MaLoaiTru IS NULL AND LoaiCho IS NOT NULL)
    ),

    CONSTRAINT CHK_KhungGio CHECK (GioKetThuc > GioBatDau),
    CONSTRAINT CHK_HieuLuc  CHECK (HieuLucDen IS NULL OR HieuLucDen >= HieuLucTu)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE DAT_CHO (
    MaDatCho        VARCHAR(20)     NOT NULL,
    MaXe            VARCHAR(20)     NOT NULL,
    MaCho           VARCHAR(20)     NOT NULL,
    ThoiGianDat     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ThoiGianHetHan  DATETIME        NOT NULL,
    TienCoc         DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,
    TrangThaiDatCho VARCHAR(20)     NOT NULL DEFAULT 'Active',
    XeDangGiu       VARCHAR(20)     GENERATED ALWAYS AS (IF(TrangThaiDatCho = 'Active', MaXe,  NULL)) VIRTUAL,
    ChoDangGiu      VARCHAR(20)     GENERATED ALWAYS AS (IF(TrangThaiDatCho = 'Active', MaCho, NULL)) VIRTUAL,

    PRIMARY KEY (MaDatCho),
    UNIQUE KEY UQ_DatCho_Active_Xe  (XeDangGiu),
    UNIQUE KEY UQ_DatCho_Active_Cho (ChoDangGiu),
    CONSTRAINT FK_DatCho_PhuongTien FOREIGN KEY (MaXe)  REFERENCES PHUONG_TIEN (MaXe),
    CONSTRAINT FK_DatCho_ChoDoXe    FOREIGN KEY (MaCho) REFERENCES CHO_DO_XE (MaCho),
    CONSTRAINT CHK_DatCho_TienCoc   CHECK (TienCoc >= 0),
    CONSTRAINT CHK_DatCho_TrangThai CHECK (TrangThaiDatCho IN ('Active', 'Completed', 'Cancelled', 'Expired')),
    CONSTRAINT CHK_ThoiGianDat      CHECK (ThoiGianHetHan > ThoiGianDat)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE INDEX IDX_DatCho_ThoiGianHetHan ON DAT_CHO (ThoiGianHetHan);
CREATE INDEX IDX_DatCho_TrangThai ON DAT_CHO (TrangThaiDatCho);

CREATE TABLE PHIEN (
    MaPhien         VARCHAR(20)     NOT NULL,
    MaXe            VARCHAR(20)     NOT NULL,
    MaCho           VARCHAR(20)     NOT NULL,
    MaDatCho        VARCHAR(20)     NULL,
    LoaiPhien       VARCHAR(20)     NOT NULL,
    TrangThaiPhien  VARCHAR(20)     NOT NULL DEFAULT 'Active',
    ThoiGianVao     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ThoiGianRa      DATETIME        NULL,
    GhiChu          TEXT            NULL,
    XeDangHoatDong  VARCHAR(20)     GENERATED ALWAYS AS (IF(TrangThaiPhien = 'Active', MaXe,  NULL)) VIRTUAL,
    ChoDangHoatDong VARCHAR(20)     GENERATED ALWAYS AS (IF(TrangThaiPhien = 'Active', MaCho, NULL)) VIRTUAL,

    PRIMARY KEY (MaPhien),
    UNIQUE KEY UQ_Phien_MaDatCho (MaDatCho),
    UNIQUE KEY UQ_Phien_Active_Xe  (XeDangHoatDong),
    UNIQUE KEY UQ_Phien_Active_Cho (ChoDangHoatDong),
    CONSTRAINT FK_Phien_PhuongTien FOREIGN KEY (MaXe)      REFERENCES PHUONG_TIEN (MaXe),
    CONSTRAINT FK_Phien_ChoDoXe    FOREIGN KEY (MaCho)     REFERENCES CHO_DO_XE (MaCho),
    CONSTRAINT FK_Phien_DatCho     FOREIGN KEY (MaDatCho)  REFERENCES DAT_CHO (MaDatCho),
    CONSTRAINT CHK_Phien_LoaiPhien CHECK (LoaiPhien IN ('ParkingOnly', 'ParkingAndCharging')),
    CONSTRAINT CHK_Phien_TrangThai CHECK (TrangThaiPhien IN ('Active', 'Completed', 'Cancelled', 'Interrupted')),
    CONSTRAINT CHK_ThoiGianPhien   CHECK (ThoiGianRa IS NULL OR ThoiGianRa >= ThoiGianVao)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE INDEX IDX_Phien_MaXe ON PHIEN (MaXe);
CREATE INDEX IDX_Phien_MaCho ON PHIEN (MaCho);
CREATE INDEX IDX_Phien_ThoiGianVao ON PHIEN (ThoiGianVao);
CREATE INDEX IDX_Phien_TrangThai ON PHIEN (TrangThaiPhien);

CREATE TABLE CHI_TIET_PHIEN_SAC (
    MaPhien             VARCHAR(20)     NOT NULL,
    MaTru               VARCHAR(20)     NOT NULL,
    ThoiGianBatDauSac   DATETIME        NOT NULL,
    ThoiGianKetThucSac  DATETIME        NULL,
    ThoiGianHetAnHan    DATETIME        NULL,
    ThoiGianRutSungSac  DATETIME        NULL,
    ChiSoCongToDau      DECIMAL(10, 2)  NOT NULL,
    ChiSoCongToCuoi     DECIMAL(10, 2)  NULL,
    SoKWh               DECIMAL(10, 2)  GENERATED ALWAYS AS (ChiSoCongToCuoi - ChiSoCongToDau) STORED,
    HanMucSac_VND       DECIMAL(12, 2)  NULL,
    HanMucSac_kWh       DECIMAL(6, 2)   NULL,
    TrangThaiSac        VARCHAR(20)     NOT NULL DEFAULT 'Charging',
    LyDoKetThuc         VARCHAR(50)     NULL,

    PRIMARY KEY (MaPhien),
    CONSTRAINT FK_ChiTietPhienSac_Phien FOREIGN KEY (MaPhien) REFERENCES PHIEN (MaPhien),
    CONSTRAINT FK_ChiTietPhienSac_Tru   FOREIGN KEY (MaTru)   REFERENCES TRU_SAC (MaTru),
    CONSTRAINT CHK_PhienSac_CongToDau  CHECK (ChiSoCongToDau >= 0),
    CONSTRAINT CHK_PhienSac_CongToCuoi CHECK (ChiSoCongToCuoi IS NULL OR ChiSoCongToCuoi >= ChiSoCongToDau),
    CONSTRAINT CHK_PhienSac_HanMucVND  CHECK (HanMucSac_VND IS NULL OR HanMucSac_VND > 0),
    CONSTRAINT CHK_PhienSac_HanMuckWh  CHECK (HanMucSac_kWh IS NULL OR HanMucSac_kWh > 0),
    CONSTRAINT CHK_PhienSac_TrangThai  CHECK (TrangThaiSac IN ('Charging', 'Completed', 'Interrupted', 'Suspended')),
    CONSTRAINT CHK_PhienSac_LyDo CHECK (LyDoKetThuc IS NULL OR LyDoKetThuc IN (
        'Normal_FullBattery', 'UserStopped', 'AutoCutoff_LimitReached', 'AutoCutoff_LowBalance',
        'PowerLoss', 'EmergencyStop', 'Other')),

    CONSTRAINT CHK_ThoiGianSac CHECK (ThoiGianKetThucSac IS NULL OR ThoiGianKetThucSac >= ThoiGianBatDauSac),
    CONSTRAINT CHK_ThoiGianRutSung CHECK (
        ThoiGianRutSungSac IS NULL
        OR (ThoiGianKetThucSac IS NOT NULL AND ThoiGianRutSungSac >= ThoiGianKetThucSac)
    )
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE INDEX IDX_ChiTietPhienSac_MaTru ON CHI_TIET_PHIEN_SAC (MaTru);
CREATE INDEX IDX_ChiTietPhienSac_TrangThai ON CHI_TIET_PHIEN_SAC (TrangThaiSac);

CREATE TABLE CHI_TIET_PHI (
    MaPhien         VARCHAR(20)     NOT NULL,
    SoDong          INT             NOT NULL,
    MaBangGia       VARCHAR(20)     NOT NULL,
    KhoanMuc        VARCHAR(30)     NOT NULL,
    ThoiGianBatDau  DATETIME        NOT NULL,
    ThoiGianKetThuc DATETIME        NOT NULL,
    SoPhut          INT             NOT NULL,
    SoTien          DECIMAL(12, 2)  NOT NULL,

    PRIMARY KEY (MaPhien, SoDong),
    CONSTRAINT FK_ChiTietPhi_Phien   FOREIGN KEY (MaPhien)   REFERENCES PHIEN (MaPhien),
    CONSTRAINT FK_ChiTietPhi_BangGia FOREIGN KEY (MaBangGia) REFERENCES BANG_GIA (MaBangGia),
    CONSTRAINT CHK_ChiTietPhi_SoDong   CHECK (SoDong > 0),
    CONSTRAINT CHK_ChiTietPhi_KhoanMuc CHECK (KhoanMuc IN ('Parking', 'Charging', 'PostCharging')),
    CONSTRAINT CHK_ChiTietPhi_SoPhut   CHECK (SoPhut >= 0),
    CONSTRAINT CHK_ChiTietPhi_SoTien   CHECK (SoTien >= 0),
    CONSTRAINT CHK_ThoiGianPhi CHECK (ThoiGianKetThuc >= ThoiGianBatDau)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE HOA_DON (
    MaHD                    VARCHAR(20)     NOT NULL,
    MaPhien                 VARCHAR(20)     NOT NULL,
    PhiDoXe                 DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,
    PhiSacDien              DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,
    PhiDoSauSac             DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,
    TienKhauTru             DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,

    TongTien                DECIMAL(12, 2)  GENERATED ALWAYS AS
        (PhiDoXe + PhiSacDien + PhiDoSauSac - TienKhauTru) STORED,
    PhuongThucThanhToan     VARCHAR(30)     NOT NULL DEFAULT 'Wallet',
    TrangThaiThanhToan      VARCHAR(20)     NOT NULL DEFAULT 'Unpaid',
    MaGiaoDichNgoai         VARCHAR(100)    NULL,
    NgayLapHoaDon           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    NgayThanhToan           DATETIME        NULL,

    PRIMARY KEY (MaHD),
    UNIQUE KEY UQ_HoaDon_MaPhien (MaPhien),
    CONSTRAINT FK_HoaDon_Phien FOREIGN KEY (MaPhien) REFERENCES PHIEN (MaPhien),
    CONSTRAINT CHK_HoaDon_PhiDoXe     CHECK (PhiDoXe >= 0),
    CONSTRAINT CHK_HoaDon_PhiSacDien  CHECK (PhiSacDien >= 0),
    CONSTRAINT CHK_HoaDon_PhiDoSauSac CHECK (PhiDoSauSac >= 0),
    CONSTRAINT CHK_HoaDon_KhauTruAm   CHECK (TienKhauTru >= 0),
    CONSTRAINT CHK_HoaDon_PhuongThuc  CHECK (PhuongThucThanhToan IN ('Wallet', 'POS_Card', 'Dynamic_QR', 'Cash')),
    CONSTRAINT CHK_HoaDon_TrangThai   CHECK (TrangThaiThanhToan IN ('Unpaid', 'Paid', 'Refunded')),

    CONSTRAINT CHK_KhauTru CHECK (TienKhauTru <= (PhiDoXe + PhiSacDien + PhiDoSauSac)),

    CONSTRAINT CHK_NgayThanhToan CHECK (NgayThanhToan IS NULL OR NgayThanhToan >= NgayLapHoaDon)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE INDEX IDX_HoaDon_TrangThai ON HOA_DON (TrangThaiThanhToan);
CREATE INDEX IDX_HoaDon_NgayLap ON HOA_DON (NgayLapHoaDon);

CREATE TABLE GIAO_DICH_VI (
    MaGD                VARCHAR(20)     NOT NULL,
    MaKH                VARCHAR(20)     NOT NULL,
    LoaiGD              VARCHAR(20)     NOT NULL,
    SoTien              DECIMAL(12, 2)  NOT NULL,
    SoDuTruoc           DECIMAL(12, 2)  NOT NULL,
    SoDuSau             DECIMAL(12, 2)  NOT NULL,
    MaHD                VARCHAR(20)     NULL,
    MaGiaoDichDoiTac    VARCHAR(100)    NULL,
    ThoiGianGD          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    GhiChu              TEXT            NULL,

    PRIMARY KEY (MaGD),
    UNIQUE KEY UQ_GiaoDichVi_DoiTac (MaGiaoDichDoiTac),
    CONSTRAINT FK_GiaoDichVi_KhachHang FOREIGN KEY (MaKH) REFERENCES KHACH_HANG (MaKH),
    CONSTRAINT FK_GiaoDichVi_HoaDon    FOREIGN KEY (MaHD) REFERENCES HOA_DON (MaHD),
    CONSTRAINT CHK_GiaoDich_LoaiGD CHECK (LoaiGD IN ('Deposit', 'Payment', 'Refund', 'DirectPayment')),
    CONSTRAINT CHK_GiaoDich_SoTien CHECK (SoTien > 0),
    CONSTRAINT CHK_GiaoDich_SoDuTruoc CHECK (SoDuTruoc >= 0),
    CONSTRAINT CHK_GiaoDich_SoDuSau   CHECK (SoDuSau >= 0),

    CONSTRAINT CHK_GiaoDich_SoDu CHECK (
        (LoaiGD = 'Deposit'          AND SoDuSau = SoDuTruoc + SoTien)
        OR (LoaiGD = 'Payment'       AND SoDuSau = SoDuTruoc - SoTien)
        OR (LoaiGD = 'Refund'        AND SoDuSau = SoDuTruoc + SoTien)
        OR (LoaiGD = 'DirectPayment' AND SoDuTruoc = SoDuSau)
    )
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE INDEX IDX_GiaoDichVi_MaKH ON GIAO_DICH_VI (MaKH);
CREATE INDEX IDX_GiaoDichVi_ThoiGian ON GIAO_DICH_VI (ThoiGianGD);
CREATE INDEX IDX_GiaoDichVi_MaHD ON GIAO_DICH_VI (MaHD);
```

## 3.3 Trigger

Mười một quy tắc nghiệp vụ được cưỡng chế bằng trigger. MySQL chỉ cho mỗi trigger gắn với một sự kiện nên trigger 8, 9, 10 và 11 mỗi cái tách thành hai, tổng cộng có 17 trigger; phần xử lý dùng chung của trigger 8 và 9 đặt trong một thủ tục và một hàm. Các trigger cùng bảng và cùng sự kiện chạy theo thứ tự tạo; script tạo theo thứ tự bảng chữ cái của tên (như bản gốc), nên khi nhiều điều kiện cùng vi phạm thì lỗi trả về là lỗi của trigger đứng trước. Lỗi nghiệp vụ được báo bằng SIGNAL SQLSTATE '45000' (thông báo tối đa 128 ký tự).

| # | Trigger | Sự kiện | Quy tắc |
| --- | --- | --- | --- |
| 1 | TRG_Phien_CheckLoaiXe | BEFORE INSERT PHIEN | Xe máy chỉ vào MotorbikeSlot, ô tô chỉ vào CarSlot |
| 2 | TRG_DatCho_KiemTraBaoTri / TRG_Phien_KiemTraBaoTri | BEFORE INSERT DAT_CHO, PHIEN | Chỗ đỗ đang Maintenance thì không nhận đặt chỗ hoặc phiên mới |
| 3 | TRG_Phien_KiemTraDieuKienMo | BEFORE INSERT PHIEN | Tài khoản phải Active; khách Registered phải có số dư ≥ SoDuToiThieu của trạm |
| 4 | TRG_PhienSac_KiemTraTru | BEFORE INSERT CHI_TIET_PHIEN_SAC | Trụ không ở Faulted/Maintenance; trụ thuộc đúng chỗ đỗ của phiên; chuẩn súng sạc của trụ khớp cổng xe |
| 5 | TRG_DatCho_KiemTraKhoaDen / TRG_Phien_KiemTraKhoaDen | BEFORE INSERT DAT_CHO, PHIEN | Xe bị khóa nợ xấu (BiDenKhoa) không được đặt chỗ hoặc mở phiên |
| 6 | TRG_Phien_KiemTraDatChoKhop | BEFORE INSERT PHIEN | Phiên mở từ đặt chỗ phải đúng xe, đúng chỗ đã đặt và đặt chỗ chưa bị hủy hoặc hết hạn |
| 7 | TRG_DatCho_CheckLoaiXe | BEFORE INSERT DAT_CHO | Khớp loại xe và loại chỗ khi đặt chỗ |
| 8 | TRG_Phien_SyncTrangThai_Ins / _Upd | AFTER INSERT, AFTER UPDATE PHIEN | Đồng bộ trạng thái chỗ đỗ, trụ sạc và đặt chỗ theo trạng thái phiên (gọi sp_dong_bo_trang_thai_phien); khi phiên kết thúc mà chỗ đỗ còn đặt chỗ Active khác thì chuyển sang Reserved thay vì Available |
| 9 | TRG_PhienSac_AutoAnHan_Ins / _Upd | BEFORE INSERT, BEFORE UPDATE CHI_TIET_PHIEN_SAC | Khi kết thúc sạc mà chưa có hạn ân hạn thì tự tính theo PhutAnHanSauSac của trạm (hàm fn_tinh_an_han) |
| 10 | TRG_GiaoDichVi_Protect_Upd / _Del | BEFORE UPDATE, BEFORE DELETE GIAO_DICH_VI | Sổ cái bất biến: cấm sửa hoặc xóa |
| 11 | TRG_DatCho_Reserve_Ins / TRG_DatCho_Release_Upd | AFTER INSERT, AFTER UPDATE DAT_CHO | Đặt chỗ Active mới đưa chỗ đỗ từ Available sang Reserved; đặt chỗ bị hủy hoặc hết hạn trả chỗ đỗ về Available |

Hai nhóm đối tượng dưới đây nêu mã đầy đủ: trigger 3 (mẫu dùng SIGNAL và CONCAT) và trigger 8, gồm thủ tục dùng chung cùng hai trigger. Trigger 8 chỉ đổi trạng thái khi chỗ và trụ đang ở trạng thái bình thường. Trigger 3:

```sql
DELIMITER $$

CREATE TRIGGER TRG_Phien_KiemTraDieuKienMo
BEFORE INSERT ON PHIEN
FOR EACH ROW
BEGIN
    DECLARE v_trangthaitk   VARCHAR(20);
    DECLARE v_loaikhach     VARCHAR(20);
    DECLARE v_soduthucte    DECIMAL(12, 2);
    DECLARE v_sodutoithieu  DECIMAL(12, 2);

    SELECT kh.TrangThaiTK, kh.SoDuViDienTu, kh.LoaiKhach
    INTO   v_trangthaitk, v_soduthucte, v_loaikhach
    FROM   PHUONG_TIEN pt
    JOIN   KHACH_HANG kh ON pt.MaKH = kh.MaKH
    WHERE  pt.MaXe = NEW.MaXe;

    SELECT t.SoDuToiThieu INTO v_sodutoithieu
    FROM   CHO_DO_XE c
    JOIN   TRAM t ON c.MaTram = t.MaTram
    WHERE  c.MaCho = NEW.MaCho;

    IF v_trangthaitk <> 'Active' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tài khoản khách hàng đang bị khóa';
    END IF;

    IF v_loaikhach = 'Registered' AND v_soduthucte < v_sodutoithieu THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = CONCAT('Số dư ví (', v_soduthucte, ') chưa đạt mức tối thiểu mở phiên của trạm (', v_sodutoithieu, ')');
    END IF;
END$$

DELIMITER ;
```

Trigger 8 (thủ tục dùng chung và hai trigger):

```sql
DELIMITER $$

CREATE PROCEDURE sp_dong_bo_trang_thai_phien(
    IN p_ma_cho      VARCHAR(20),
    IN p_loai_phien  VARCHAR(20),
    IN p_trang_thai  VARCHAR(20),
    IN p_ma_dat_cho  VARCHAR(20)
)
BEGIN
    IF p_trang_thai = 'Active' THEN
        UPDATE CHO_DO_XE SET TrangThaiCho = 'Occupied'
        WHERE MaCho = p_ma_cho AND TrangThaiCho IN ('Available', 'Reserved');

        IF p_loai_phien = 'ParkingAndCharging' THEN
            UPDATE TRU_SAC SET TrangThaiTru = 'Charging'
            WHERE MaCho = p_ma_cho AND TrangThaiTru = 'Available';
        END IF;

    ELSEIF p_trang_thai IN ('Completed', 'Cancelled', 'Interrupted') THEN
        UPDATE CHO_DO_XE
        SET TrangThaiCho = CASE
            WHEN EXISTS (SELECT 1 FROM DAT_CHO d
                         WHERE d.MaCho = p_ma_cho
                           AND d.TrangThaiDatCho = 'Active'
                           AND d.MaDatCho <> COALESCE(p_ma_dat_cho, ''))
            THEN 'Reserved' ELSE 'Available' END
        WHERE MaCho = p_ma_cho AND TrangThaiCho = 'Occupied';

        UPDATE TRU_SAC SET TrangThaiTru = 'Available'
        WHERE MaCho = p_ma_cho AND TrangThaiTru = 'Charging';

        IF p_ma_dat_cho IS NOT NULL THEN
            UPDATE DAT_CHO SET TrangThaiDatCho = 'Completed' WHERE MaDatCho = p_ma_dat_cho;
        END IF;
    END IF;
END$$

CREATE TRIGGER TRG_Phien_SyncTrangThai_Ins
AFTER INSERT ON PHIEN
FOR EACH ROW
BEGIN
    CALL sp_dong_bo_trang_thai_phien(NEW.MaCho, NEW.LoaiPhien, NEW.TrangThaiPhien, NEW.MaDatCho);
END$$

CREATE TRIGGER TRG_Phien_SyncTrangThai_Upd
AFTER UPDATE ON PHIEN
FOR EACH ROW
BEGIN
    IF NOT (OLD.TrangThaiPhien <=> NEW.TrangThaiPhien) THEN
        CALL sp_dong_bo_trang_thai_phien(NEW.MaCho, NEW.LoaiPhien, NEW.TrangThaiPhien, NEW.MaDatCho);
    END IF;
END$$

DELIMITER ;
```

## 3.4 Stored procedure

Các thủ tục thanh toán chạy trong một giao dịch (START TRANSACTION, có bộ xử lý lỗi ROLLBACK rồi ném lại lỗi), vì khóa dòng bằng FOR UPDATE trong MySQL chỉ có tác dụng trong giao dịch.

| Thủ tục | Chức năng |
| --- | --- |
| sp_kiem_tra_va_ngat_sac_tu_dong (mã phiên, chỉ số công tơ, thời điểm kiểm tra) | Tính điện năng (kWh) và chi phí sạc đến thời điểm kiểm tra, trong đó chi phí = số phút sạc × đơn giá theo phút của BANG_GIA (LoaiGia = Charging) ứng với loại trụ, khung giờ và ngày hiệu lực, cùng đơn vị với hóa đơn; tự ngắt sạc (ghi Completed, lý do AutoCutoff_LimitReached hoặc AutoCutoff_LowBalance) khi đạt hạn mức VND, hạn mức kWh hoặc khi số dư ví chỉ còn dưới 5.000đ. Tham số thời điểm để NULL thì lấy giờ hiện tại. |
| sp_thanh_toan_hoa_don_vi (mã khách, mã hóa đơn, khóa idempotency) | Thanh toán hóa đơn bằng ví: khóa dòng khách và dòng hóa đơn bằng FOR UPDATE chống đua, kiểm tra hóa đơn thuộc đúng khách đang thanh toán, kiểm tra số dư, trừ ví, ghi sổ cái Payment, cập nhật hóa đơn Paid và đóng phiên (trigger 8 giải phóng chỗ và trụ). Hóa đơn 0đ chỉ được đánh dấu Paid, không trừ ví và không ghi sổ cái vì ràng buộc SoTien > 0. |
| sp_thanh_toan_walkin_ngoai (mã hóa đơn, phương thức, mã giao dịch ngoài) | Thanh toán trực tiếp bằng QR/POS/tiền mặt cho khách vãng lai: chỉ nhận phương thức POS_Card, Dynamic_QR hoặc Cash, khóa dòng hóa đơn, từ chối hóa đơn đã thanh toán hoặc đã hoàn tiền; ghi sổ cái DirectPayment (số dư không đổi, bỏ qua hóa đơn 0đ), cập nhật hóa đơn và đóng phiên. |
| sp_xu_ly_dat_cho_qua_han () | Quét các đặt chỗ Active đã quá hạn và chưa chuyển thành phiên (NOT EXISTS trên PHIEN), chuyển sang Expired; trigger TRG_DatCho_Release_Upd trả chỗ đỗ về Available nếu đang Reserved (một câu UPDATE thay cho vòng lặp). |

## 3.5 Phân quyền (RBAC)

Ba vai trò là ROLE của MySQL 8 (CREATE ROLE), cấp cho tài khoản thật bằng GRANT vai_trò TO tài_khoản. MySQL không cho liệt kê nhiều bảng trong một lệnh GRANT nên script cấp quyền từng bảng.

| Vai trò | Quyền |
| --- | --- |
| app_user_role (ứng dụng tài xế) | SELECT trên TRAM, CHO_DO_XE, LOAI_TRU_SAC, TRU_SAC, BANG_GIA, KHACH_HANG, PHUONG_TIEN, HOA_DON, GIAO_DICH_VI; SELECT, INSERT trên DAT_CHO, PHIEN, CHI_TIET_PHIEN_SAC; EXECUTE sp_thanh_toan_hoa_don_vi và sp_kiem_tra_va_ngat_sac_tu_dong |
| station_operator_role (vận hành, thu ngân) | SELECT, UPDATE trên CHO_DO_XE, TRU_SAC, PHUONG_TIEN, HOA_DON, PHIEN; SELECT, INSERT, UPDATE trên BANG_GIA; SELECT trên KHACH_HANG, GIAO_DICH_VI; EXECUTE sp_thanh_toan_walkin_ngoai, sp_xu_ly_dat_cho_qua_han, sp_kiem_tra_va_ngat_sac_tu_dong |
| sys_admin_role (quản trị hệ thống) | Toàn quyền trên mọi bảng và thủ tục của database smart_ev_parking |

## 3.6 Dữ liệu mẫu

Dữ liệu mẫu mô phỏng ba trạm hoạt động từ tháng 9 đến giữa tháng 10/2026. Số dòng của từng bảng:

| Bảng | Số dòng | Bảng | Số dòng |
| --- | --- | --- | --- |
| QUAN_TRI_VIEN | 3 | BANG_GIA | 15 |
| KHACH_HANG | 8 | DAT_CHO | 7 |
| PHUONG_TIEN | 10 | PHIEN | 19 |
| TRAM | 3 | CHI_TIET_PHIEN_SAC | 12 |
| CHO_DO_XE | 14 | CHI_TIET_PHI | 24 |
| LOAI_TRU_SAC | 5 | HOA_DON | 15 |
| TRU_SAC | 9 | GIAO_DICH_VI | 25 |

Dữ liệu được thiết kế để mỗi truy vấn đều có kết quả và để phủ hầu hết tình huống nghiệp vụ:

- **Đổi giá:** giá đỗ xe ô tô cao điểm đổi từ 400 lên 500 đ/phút từ 01/10/2026 (BG12 → BG02); phiên tháng 9 tính giá cũ, tháng 10 tính giá mới.
- **Khách vãng lai và xe máy:** KH08 (WalkIn) sạc xe máy tại ổ cắm AC_Plug và thanh toán QR tại barrier (hóa đơn HD13, giao dịch DirectPayment); KH04 có thêm một xe máy gửi tại chỗ MotorbikeSlot.
- **Tiền cọc:** DC01 và DC03 có cọc 20.000đ, được khấu trừ vào hóa đơn HD02 và HD06 (TienKhauTru); DC05 là đặt chỗ bỏ (Expired), DC06 bị hủy, DC07 đang giữ chỗ.
- **Tự ngắt sạc:** phiên P04 dừng ở hạn mức 22 kWh, phiên P08 dừng ở hạn mức 225.000đ (LyDoKetThuc = AutoCutoff_LimitReached).
- **Sự cố và hoàn tiền:** phiên P18 bị mất điện giữa chừng (Interrupted, PowerLoss); hóa đơn HD15 được thanh toán rồi hoàn tiền (giao dịch Payment và Refund, trạng thái Refunded); trụ TS08 chuyển Faulted.
- **Phí đỗ sau sạc:** các phiên P03, P06, P07, P10, P12 có xe ở lại quá ân hạn nên phát sinh phí PostCharging.
- **Tài khoản khóa:** KH07 (Locked) và xe XE08 bị gắn BiDenKhoa; không có phiên nào của khách này.
- **Phiên đang chạy (Active):** P12 sạc xong và có hóa đơn chưa thanh toán (HD12), P13 đang sạc, P14 chỉ đỗ xe, P15 sạc xong nhưng xe chưa rời chỗ.
- **Trạng thái hạ tầng:** TS05 bảo trì (chưa từng được dùng), CHO12 bảo trì, CHO08 đang giữ chỗ (Reserved).

Một số lưu ý khi nạp dữ liệu (có ghi chú ngay trong script): các phiên đã kết thúc được nạp trước và phiên Active nạp sau cùng, vì trigger 8 trả chỗ đỗ về Available khi gặp phiên đã kết thúc; số dư ví của khách là số dư cuối sau mọi giao dịch, nên trigger 3 (đọc số dư hiện tại) cho phép mở các phiên lịch sử; xe CCS2 chỉ sạc ở trụ DC, xe Type2 chỉ sạc ở trụ AC, xe máy chỉ sạc ở trụ AC_Plug để thỏa trigger 4; thời hạn ân hạn do trigger 9 tự tính; trạng thái Maintenance, Faulted và Reserved cập nhật ở cuối sau khi nạp xong lịch sử.

## 3.7 Mười ba truy vấn

Các truy vấn dưới đây dùng đa dạng kỹ thuật: kết nối nhiều bảng, LEFT JOIN, tổng hợp với GROUP BY/HAVING, truy vấn con (vô hướng, NOT EXISTS, NOT IN, tương quan, bảng dẫn xuất), CTE, hàm cửa sổ (RANK, LAG) và tổng hợp có điều kiện (CASE WHEN). Kết quả mong đợi tính trên bộ dữ liệu mẫu ở mục 3.6; riêng Q10, Q11 và Q13 là các truy vấn đối chiếu nên kết quả mong đợi là 0 dòng.

### Truy vấn 1 — [JOIN 6 bảng] Các phiên đã hoàn tất kèm khách, xe, trạm, hóa đơn

Kỹ thuật: Kết nối 6 bảng.

```sql
SELECT  p.MaPhien, kh.HoTen, kh.LoaiKhach, pt.BienSo, t.TenTram, c.MaViTri,
        p.LoaiPhien, p.ThoiGianVao, p.ThoiGianRa,
        hd.TongTien, hd.PhuongThucThanhToan, hd.TrangThaiThanhToan
FROM PHIEN p
JOIN PHUONG_TIEN pt ON pt.MaXe    = p.MaXe
JOIN KHACH_HANG  kh ON kh.MaKH    = pt.MaKH
JOIN CHO_DO_XE   c  ON c.MaCho    = p.MaCho
JOIN TRAM        t  ON t.MaTram   = c.MaTram
JOIN HOA_DON     hd ON hd.MaPhien = p.MaPhien
WHERE p.TrangThaiPhien = 'Completed'
ORDER BY p.ThoiGianVao DESC;
```

Kết quả mong đợi:

| MaPhien | HoTen | BienSo | TenTram | MaViTri | TongTien | PhuongThucThanhToan |
| --- | --- | --- | --- | --- | --- | --- |
| P11 | Nguyen Minh Khoa | 51K-678.90 | Tram Vincom Thu Duc | A-05 | 45.000 | Wallet |
| P10 | Le Quoc Bao | 51H-333.44 | Tram Landmark 81 | B-03 | 302.500 | Wallet |
| P17 | Pham Ngoc Lan | 59Z1-555.66 | Tram Landmark 81 | M-01 | 18.000 | Wallet |
| P09 | Nguyen Minh Khoa | 51A-123.45 | Tram San bay Tan Son Nhat | C-03 | 75.000 | Wallet |
| P16 | Khach Vang Lai 01 | 59X1-123.45 | Tram Vincom Thu Duc | M-01 | 76.500 | Dynamic_QR |
| P08 | Vo Thanh Dat | 60A-999.00 | Tram San bay Tan Son Nhat | C-01 | 225.000 | Wallet |
| P07 | Tran Thu Ha | 59A-111.22 | Tram Vincom Thu Duc | A-03 | 365.000 | Wallet |
| P06 | Hoang Gia Huy | 51F-777.88 | Tram Landmark 81 | B-03 | 250.000 | Wallet |
| P05 | Nguyen Minh Khoa | 51K-678.90 | Tram Landmark 81 | B-04 | 90.000 | Wallet |
| P04 | Pham Ngoc Lan | 50E-555.66 | Tram Landmark 81 | B-01 | 221.000 | Wallet |
| P03 | Le Quoc Bao | 51H-333.44 | Tram Vincom Thu Duc | A-03 | 320.000 | Wallet |
| P02 | Tran Thu Ha | 59A-111.22 | Tram Vincom Thu Duc | A-02 | 222.000 | Wallet |
| P01 | Nguyen Minh Khoa | 51A-123.45 | Tram Vincom Thu Duc | A-04 | 48.000 | Wallet |

### Truy vấn 2 — [LEFT JOIN + GROUP BY] Doanh thu thực thu theo trạm, tháng 10/2026

Kỹ thuật: LEFT JOIN + GROUP BY, điều kiện lọc đặt trong ON. Loc dat trong ON de tram khong co phien van hien dong gia tri 0.

```sql
SELECT  t.MaTram, t.TenTram,
        COUNT(DISTINCT p.MaPhien)           AS SoPhienHoanTat,
        COALESCE(SUM(hd.PhiDoXe), 0)        AS PhiDoXe,
        COALESCE(SUM(hd.PhiSacDien), 0)     AS PhiSacDien,
        COALESCE(SUM(hd.PhiDoSauSac), 0)    AS PhiDoSauSac,
        COALESCE(SUM(hd.TienKhauTru), 0)    AS TienKhauTru,
        COALESCE(SUM(hd.TongTien), 0)       AS DoanhThuThucThu
FROM TRAM t
LEFT JOIN CHO_DO_XE c ON c.MaTram = t.MaTram
LEFT JOIN PHIEN p     ON p.MaCho = c.MaCho
                     AND p.TrangThaiPhien = 'Completed'
                     AND p.ThoiGianVao >= DATE '2026-10-01'
                     AND p.ThoiGianVao <  DATE '2026-11-01'
LEFT JOIN HOA_DON hd  ON hd.MaPhien = p.MaPhien
                     AND hd.TrangThaiThanhToan = 'Paid'
GROUP BY t.MaTram, t.TenTram
ORDER BY DoanhThuThucThu DESC;
```

Kết quả mong đợi:

| MaTram | TenTram | SoPhienHoanTat | PhiDoXe | PhiSacDien | PhiDoSauSac | TienKhauTru | DoanhThuThucThu |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T02 | Tram Landmark 81 | 5 | 115.500 | 726.000 | 60.000 | 20.000 | 881.500 |
| T01 | Tram Vincom Thu Duc | 3 | 45.000 | 432.000 | 9.500 | 0 | 486.500 |
| T03 | Tram San bay Tan Son Nhat | 2 | 75.000 | 225.000 | 0 | 0 | 300.000 |

### Truy vấn 3 — [GROUP BY + HAVING] Khách hàng đã trả từ 250.000đ trở lên (hóa đơn Paid)

Kỹ thuật: GROUP BY + HAVING.

```sql
SELECT  kh.MaKH, kh.HoTen,
        COUNT(hd.MaHD)      AS SoHoaDonDaTra,
        SUM(hd.TongTien)    AS TongChiTieu,
        MAX(hd.TongTien)    AS HoaDonLonNhat
FROM KHACH_HANG kh
JOIN PHUONG_TIEN pt ON pt.MaKH    = kh.MaKH
JOIN PHIEN p        ON p.MaXe     = pt.MaXe
JOIN HOA_DON hd     ON hd.MaPhien = p.MaPhien
WHERE hd.TrangThaiThanhToan = 'Paid'
GROUP BY kh.MaKH, kh.HoTen
HAVING SUM(hd.TongTien) >= 250000
ORDER BY TongChiTieu DESC;
```

Kết quả mong đợi:

| MaKH | HoTen | SoHoaDonDaTra | TongChiTieu | HoaDonLonNhat |
| --- | --- | --- | --- | --- |
| KH03 | Le Quoc Bao | 2 | 622.500 | 320.000 |
| KH02 | Tran Thu Ha | 2 | 587.000 | 365.000 |
| KH01 | Nguyen Minh Khoa | 4 | 258.000 | 90.000 |
| KH05 | Hoang Gia Huy | 1 | 250.000 | 250.000 |

### Truy vấn 4 — [SUBQUERY vô hướng] Hóa đơn có tổng tiền cao hơn mức trung bình hệ thống

Kỹ thuật: Truy vấn con vô hướng.

```sql
SELECT  hd.MaHD, hd.MaPhien, pt.BienSo, hd.TongTien,
        (SELECT ROUND(AVG(TongTien), 0) FROM HOA_DON) AS TrungBinhHeThong
FROM HOA_DON hd
JOIN PHIEN p        ON p.MaPhien = hd.MaPhien
JOIN PHUONG_TIEN pt ON pt.MaXe   = p.MaXe
WHERE hd.TongTien > (SELECT AVG(TongTien) FROM HOA_DON)
ORDER BY hd.TongTien DESC;
```

Kết quả mong đợi:

| MaHD | MaPhien | BienSo | TongTien | TrungBinhHeThong |
| --- | --- | --- | --- | --- |
| HD07 | P07 | 59A-111.22 | 365.000 | 173.800 |
| HD03 | P03 | 51H-333.44 | 320.000 | 173.800 |
| HD10 | P10 | 51H-333.44 | 302.500 | 173.800 |
| HD06 | P06 | 51F-777.88 | 250.000 | 173.800 |
| HD08 | P08 | 60A-999.00 | 225.000 | 173.800 |
| HD02 | P02 | 59A-111.22 | 222.000 | 173.800 |
| HD04 | P04 | 50E-555.66 | 221.000 | 173.800 |
| HD12 | P12 | 50E-555.66 | 205.000 | 173.800 |

### Truy vấn 5 — [NOT EXISTS - subquery tương quan] Xe đã đăng ký nhưng chưa từng gửi

Kỹ thuật: NOT EXISTS (truy vấn con tương quan).

```sql
SELECT  pt.MaXe, pt.BienSo, pt.LoaiXe, pt.ChuanSac, pt.BiDenKhoa, kh.HoTen, kh.TrangThaiTK
FROM PHUONG_TIEN pt
JOIN KHACH_HANG kh ON kh.MaKH = pt.MaKH
WHERE NOT EXISTS (SELECT 1 FROM PHIEN p WHERE p.MaXe = pt.MaXe);
```

Kết quả mong đợi:

| MaXe | BienSo | LoaiXe | ChuanSac | BiDenKhoa | HoTen | TrangThaiTK |
| --- | --- | --- | --- | --- | --- | --- |
| XE08 | 52B-246.80 | Car_4W | Type2 | TRUE | Dang Bao Tram | Locked |

### Truy vấn 6 — [NOT IN] Trụ sạc chưa từng được dùng để sạc

Kỹ thuật: NOT IN.

```sql
SELECT  ts.MaTru, t.TenTram, c.MaViTri, lt.TenLoai, lt.ChuanKetNoi, ts.TrangThaiTru
FROM TRU_SAC ts
JOIN CHO_DO_XE c     ON c.MaCho = ts.MaCho
JOIN TRAM t          ON t.MaTram = c.MaTram
JOIN LOAI_TRU_SAC lt ON lt.MaLoaiTru = ts.MaLoaiTru
WHERE ts.MaTru NOT IN (SELECT cts.MaTru FROM CHI_TIET_PHIEN_SAC cts);
```

Kết quả mong đợi:

| MaTru | TenTram | MaViTri | TenLoai | ChuanKetNoi | TrangThaiTru |
| --- | --- | --- | --- | --- | --- |
| TS05 | Tram Landmark 81 | B-02 | AC 22 kW | Type2 | Maintenance |

### Truy vấn 7 — [JOIN + AGGREGATION] Sản lượng điện và thời gian sạc trung bình theo loại trụ

Kỹ thuật: Kết nối + hàm tổng hợp + CASE WHEN. Chi tinh phien sac da ket thuc (co ThoiGianKetThucSac).

```sql
SELECT  lt.MaLoaiTru, lt.TenLoai, lt.DongDien,
        COUNT(*)                      AS SoPhienSac,
        SUM(cts.SoKWh)                AS TongKWh,
        ROUND(AVG(cts.SoKWh), 2)      AS KWhTrungBinh,
        ROUND(AVG(TIMESTAMPDIFF(SECOND, cts.ThoiGianBatDauSac, cts.ThoiGianKetThucSac) / 60), 1)
                                      AS PhutSacTrungBinh,
        SUM(CASE WHEN cts.LyDoKetThuc LIKE 'AutoCutoff%' THEN 1 ELSE 0 END) AS SoLanTuNgat
FROM CHI_TIET_PHIEN_SAC cts
JOIN TRU_SAC ts      ON ts.MaTru     = cts.MaTru
JOIN LOAI_TRU_SAC lt ON lt.MaLoaiTru = ts.MaLoaiTru
WHERE cts.ThoiGianKetThucSac IS NOT NULL
GROUP BY lt.MaLoaiTru, lt.TenLoai, lt.DongDien
ORDER BY TongKWh DESC;
```

Kết quả mong đợi:

| MaLoaiTru | TenLoai | DongDien | SoPhienSac | TongKWh | KWhTrungBinh | PhutSacTrungBinh | SoLanTuNgat |
| --- | --- | --- | --- | --- | --- | --- | --- |
| LT03 | DC 50 kW | DC | 5 | 143 | 28.6 | 44 | 1 |
| LT04 | DC 150 kW | DC | 3 | 128 | 42.67 | 22.3 | 0 |
| LT01 | AC 11 kW | AC | 1 | 22 | 22 | 120 | 1 |
| LT02 | AC 22 kW | AC | 1 | 22 | 22 | 60 | 0 |
| LT05 | AC 3 kW (xe may) | AC | 1 | 4.5 | 4.5 | 90 | 0 |

### Truy vấn 8 — [CTE + WINDOW FUNCTION RANK] Khách chi tiêu nhiều nhất tại mỗi trạm

Kỹ thuật: CTE + hàm cửa sổ RANK.

```sql
WITH chi_tieu AS (
    SELECT  t.MaTram, t.TenTram, kh.MaKH, kh.HoTen,
            SUM(hd.TongTien) AS TongChiTieu
    FROM HOA_DON hd
    JOIN PHIEN p        ON p.MaPhien = hd.MaPhien
    JOIN CHO_DO_XE c    ON c.MaCho   = p.MaCho
    JOIN TRAM t         ON t.MaTram  = c.MaTram
    JOIN PHUONG_TIEN pt ON pt.MaXe   = p.MaXe
    JOIN KHACH_HANG kh  ON kh.MaKH   = pt.MaKH
    WHERE hd.TrangThaiThanhToan = 'Paid'
    GROUP BY t.MaTram, t.TenTram, kh.MaKH, kh.HoTen
),
xep_hang AS (
    SELECT  chi_tieu.*,
            RANK() OVER (PARTITION BY MaTram ORDER BY TongChiTieu DESC) AS Hang
    FROM chi_tieu
)
SELECT MaTram, TenTram, MaKH, HoTen, TongChiTieu
FROM xep_hang
WHERE Hang = 1
ORDER BY MaTram;
```

Kết quả mong đợi:

| MaTram | TenTram | MaKH | HoTen | TongChiTieu |
| --- | --- | --- | --- | --- |
| T01 | Tram Vincom Thu Duc | KH02 | Tran Thu Ha | 587.000 |
| T02 | Tram Landmark 81 | KH03 | Le Quoc Bao | 302.500 |
| T03 | Tram San bay Tan Son Nhat | KH06 | Vo Thanh Dat | 225.000 |

### Truy vấn 9 — [JOIN BANG_GIA + GROUP BY] Doanh thu theo khoản mục, loại chỗ và khung giờ

Kỹ thuật: Kết nối BANG_GIA + GROUP BY.

```sql
SELECT  ctp.KhoanMuc,
        COALESCE(bg.LoaiCho, 'Tru sac')                                 AS LoaiCho,
        CASE WHEN bg.LaCaoDiem THEN 'Cao diem' ELSE 'Thap diem' END     AS KhungGio,
        bg.DonGiaTheoPhut   AS DonGiaTheoPhut,
        COUNT(*)            AS SoDongPhi,
        SUM(ctp.SoPhut)     AS TongPhut,
        SUM(ctp.SoTien)     AS TongTien
FROM CHI_TIET_PHI ctp
JOIN BANG_GIA bg ON bg.MaBangGia = ctp.MaBangGia
GROUP BY ctp.KhoanMuc, bg.LoaiCho, bg.LaCaoDiem, bg.DonGiaTheoPhut
ORDER BY ctp.KhoanMuc, LoaiCho, bg.LaCaoDiem DESC, bg.DonGiaTheoPhut;
```

Kết quả mong đợi:

| KhoanMuc | LoaiCho | KhungGio | DonGiaTheoPhut | SoDongPhi | TongPhut | TongTien |
| --- | --- | --- | --- | --- | --- | --- |
| Charging | Tru sac | Cao diem | 800 | 1 | 90 | 72.000 |
| Charging | Tru sac | Cao diem | 1.800 | 1 | 120 | 216.000 |
| Charging | Tru sac | Cao diem | 3.000 | 1 | 60 | 180.000 |
| Charging | Tru sac | Cao diem | 6.000 | 3 | 125 | 750.000 |
| Charging | Tru sac | Cao diem | 12.000 | 3 | 67 | 804.000 |
| Charging | Tru sac | Thap diem | 4.500 | 1 | 50 | 225.000 |
| Parking | CarSlot | Cao diem | 400 | 2 | 125 | 50.000 |
| Parking | CarSlot | Cao diem | 500 | 5 | 435 | 217.500 |
| Parking | MotorbikeSlot | Cao diem | 150 | 1 | 120 | 18.000 |
| PostCharging | CarSlot | Cao diem | 1.000 | 5 | 110 | 110.000 |
| PostCharging | MotorbikeSlot | Cao diem | 300 | 1 | 15 | 4.500 |

### Truy vấn 10 — [DERIVED TABLE + CASE WHEN] Đối chiếu hóa đơn với chi tiết phí

Kỹ thuật: Bảng dẫn xuất + CASE WHEN. Ket qua mong doi: 0 dong. Co dong tra ve = hoa don lech voi chi tiet phi.

```sql
SELECT  hd.MaHD, hd.MaPhien,
        hd.PhiDoXe,     ct.TongDoXe,
        hd.PhiSacDien,  ct.TongSac,
        hd.PhiDoSauSac, ct.TongDoSauSac
FROM HOA_DON hd
LEFT JOIN (
    SELECT  MaPhien,
            COALESCE(SUM(CASE WHEN KhoanMuc = 'Parking' THEN SoTien END), 0) AS TongDoXe,
            COALESCE(SUM(CASE WHEN KhoanMuc = 'Charging' THEN SoTien END), 0) AS TongSac,
            COALESCE(SUM(CASE WHEN KhoanMuc = 'PostCharging' THEN SoTien END), 0) AS TongDoSauSac
    FROM CHI_TIET_PHI
    GROUP BY MaPhien
) ct ON ct.MaPhien = hd.MaPhien
WHERE hd.PhiDoXe     <> COALESCE(ct.TongDoXe, 0)
   OR hd.PhiSacDien  <> COALESCE(ct.TongSac, 0)
   OR hd.PhiDoSauSac <> COALESCE(ct.TongDoSauSac, 0);
```

Kết quả mong đợi: 0 dòng (dữ liệu nhất quán).

### Truy vấn 11 — [WINDOW FUNCTION LAG + SUBQUERY tương quan] Đối chiếu sổ cái ví

Kỹ thuật: Hàm cửa sổ LAG + truy vấn con tương quan. (a) SoDuTruoc cua giao dich phai bang SoDuSau cua giao dich ngay truoc do. (b) SoDuViDienTu hien tai phai bang SoDuSau cua giao dich cuoi cung. Ca hai ket qua mong doi: 0 dong. (a)

```sql
SELECT *
FROM (
    SELECT  g.MaGD, g.MaKH, g.ThoiGianGD, g.SoDuTruoc,
            LAG(g.SoDuSau) OVER (PARTITION BY g.MaKH ORDER BY g.ThoiGianGD, g.MaGD) AS SoDuSauGiaoDichTruoc
    FROM GIAO_DICH_VI g
) x
WHERE x.SoDuSauGiaoDichTruoc IS NOT NULL
  AND x.SoDuTruoc <> x.SoDuSauGiaoDichTruoc;

SELECT  kh.MaKH, kh.HoTen, kh.SoDuViDienTu, g.SoDuSau AS SoDuSauGiaoDichCuoi
FROM KHACH_HANG kh
JOIN GIAO_DICH_VI g ON g.MaKH = kh.MaKH
WHERE g.ThoiGianGD = (SELECT MAX(g2.ThoiGianGD) FROM GIAO_DICH_VI g2 WHERE g2.MaKH = kh.MaKH)
  AND kh.SoDuViDienTu <> g.SoDuSau;
```

Kết quả mong đợi: 0 dòng (dữ liệu nhất quán).

### Truy vấn 12 — [MULTI-JOIN + GREATEST] Xe đã sạc xong nhưng vẫn chiếm chỗ

Kỹ thuật: Kết nối nhiều bảng + GREATEST. Gom ca xe con trong an han va xe da qua an han (se bi tinh phi do sau sac).

```sql
SELECT  p.MaPhien, pt.BienSo, kh.HoTen, kh.SDT,
        t.TenTram, c.MaViTri,
        cts.ThoiGianKetThucSac, cts.ThoiGianHetAnHan,
        CASE WHEN CURRENT_TIMESTAMP >= cts.ThoiGianHetAnHan
             THEN 'DA QUA AN HAN' ELSE 'Dang trong an han' END AS TinhTrang,
        ROUND(GREATEST(TIMESTAMPDIFF(SECOND, cts.ThoiGianHetAnHan, CURRENT_TIMESTAMP) / 60, 0), 0) AS SoPhutQuaAnHan
FROM PHIEN p
JOIN CHI_TIET_PHIEN_SAC cts ON cts.MaPhien = p.MaPhien
JOIN PHUONG_TIEN pt         ON pt.MaXe     = p.MaXe
JOIN KHACH_HANG kh          ON kh.MaKH     = pt.MaKH
JOIN CHO_DO_XE c            ON c.MaCho     = p.MaCho
JOIN TRAM t                 ON t.MaTram    = c.MaTram
WHERE p.TrangThaiPhien = 'Active'
  AND cts.ThoiGianKetThucSac IS NOT NULL
ORDER BY SoPhutQuaAnHan DESC;
```

Kết quả mong đợi (mẫu): thời điểm chạy khác nhau cho cột SoPhutQuaAnHan khác nhau; phiên P12 và P15 luôn xuất hiện vì xe đã sạc xong và hết ân hạn.

| MaPhien | BienSo | HoTen | TenTram | MaViTri | ThoiGianHetAnHan | TinhTrang |
| --- | --- | --- | --- | --- | --- | --- |
| P12 | 50E-555.66 | Pham Ngoc Lan | Tram Vincom Thu Duc | A-01 | 2026-10-12 17:15 | DA QUA AN HAN |
| P15 | 59A-111.22 | Tran Thu Ha | Tram Vincom Thu Duc | A-02 | 2026-10-13 10:05 | DA QUA AN HAN |

### Truy vấn 13 — [LEFT JOIN] Đối chiếu hóa đơn đã thu tiền với sổ cái ví

Kỹ thuật: LEFT JOIN đối chiếu. Hoa don Paid/Refunded phai co dung 1 dong Payment/DirectPayment bang TongTien. Ket qua mong doi: 0 dong.

```sql
SELECT  hd.MaHD, hd.TrangThaiThanhToan, hd.TongTien, g.MaGD, g.LoaiGD, g.SoTien
FROM HOA_DON hd
LEFT JOIN GIAO_DICH_VI g ON g.MaHD = hd.MaHD
                        AND g.LoaiGD IN ('Payment', 'DirectPayment')
WHERE hd.TrangThaiThanhToan IN ('Paid', 'Refunded')
  AND (g.MaGD IS NULL OR g.SoTien <> hd.TongTien);
```

Kết quả mong đợi: 0 dòng (dữ liệu nhất quán).

## 3.8 Hai view

View VW_CHO_DO_TRONG phục vụ màn hình tìm chỗ của ứng dụng, view VW_DOANH_THU_TRAM_THANG phục vụ báo cáo của quản trị viên.

```sql
CREATE OR REPLACE VIEW VW_CHO_DO_TRONG AS
SELECT  t.MaTram, t.TenTram, c.MaCho, c.MaViTri, c.LoaiCho, c.MoTaViTri,
        ts.MaTru, lt.TenLoai AS LoaiTru, lt.ChuanKetNoi, lt.CongSuat_kW,
        CASE
            WHEN ts.MaTru IS NULL                              THEN 'Khong co tru sac'
            WHEN ts.TrangThaiTru IN ('Faulted', 'Maintenance') THEN 'Tru khong kha dung'
            ELSE 'San sang sac'
        END AS TinhTrangSac
FROM CHO_DO_XE c
JOIN TRAM t               ON t.MaTram = c.MaTram
LEFT JOIN TRU_SAC ts      ON ts.MaCho = c.MaCho
LEFT JOIN LOAI_TRU_SAC lt ON lt.MaLoaiTru = ts.MaLoaiTru
WHERE c.TrangThaiCho = 'Available';

CREATE OR REPLACE VIEW VW_DOANH_THU_TRAM_THANG AS
SELECT  t.MaTram, t.TenTram,
        CAST(DATE_FORMAT(hd.NgayThanhToan, '%Y-%m-01') AS DATE) AS Thang,
        COUNT(*)                AS SoHoaDon,
        SUM(hd.PhiDoXe)         AS PhiDoXe,
        SUM(hd.PhiSacDien)      AS PhiSacDien,
        SUM(hd.PhiDoSauSac)     AS PhiDoSauSac,
        SUM(hd.TienKhauTru)     AS TienKhauTru,
        SUM(hd.TongTien)        AS DoanhThuThucThu
FROM HOA_DON hd
JOIN PHIEN p     ON p.MaPhien = hd.MaPhien
JOIN CHO_DO_XE c ON c.MaCho   = p.MaCho
JOIN TRAM t      ON t.MaTram  = c.MaTram
WHERE hd.TrangThaiThanhToan = 'Paid'
GROUP BY t.MaTram, t.TenTram, CAST(DATE_FORMAT(hd.NgayThanhToan, '%Y-%m-01') AS DATE);
```

Kết quả mong đợi của VW_CHO_DO_TRONG (các chỗ đang Available):

| MaTram | MaViTri | LoaiCho | MaTru | LoaiTru | TinhTrangSac |
| --- | --- | --- | --- | --- | --- |
| T01 | A-05 | CarSlot | NULL | NULL | Khong co tru sac |
| T01 | M-01 | MotorbikeSlot | TS09 | AC 3 kW (xe may) | San sang sac |
| T02 | B-01 | CarSlot | TS04 | AC 11 kW | San sang sac |
| T02 | B-02 | CarSlot | TS05 | AC 22 kW | Tru khong kha dung |
| T02 | B-04 | CarSlot | NULL | NULL | Khong co tru sac |
| T02 | M-01 | MotorbikeSlot | NULL | NULL | Khong co tru sac |
| T03 | C-01 | CarSlot | TS07 | DC 50 kW | San sang sac |
| T03 | C-02 | CarSlot | TS08 | DC 150 kW | Tru khong kha dung |

Kết quả mong đợi của VW_DOANH_THU_TRAM_THANG (hóa đơn Paid, theo tháng thanh toán):

| MaTram | Thang | SoHoaDon | DoanhThu |
| --- | --- | --- | --- |
| T01 | 2026-09 | 3 | 590.000 |
| T01 | 2026-10 | 3 | 486.500 |
| T02 | 2026-10 | 5 | 881.500 |
| T03 | 2026-10 | 2 | 300.000 |

# 4. Kiểm thử

Các ca kiểm thử dưới đây chạy trên bộ dữ liệu mẫu ở mục 3.6, mỗi ca đặt trong giao dịch (START TRANSACTION ... ROLLBACK) để không làm thay đổi dữ liệu. Mỗi ca nêu lệnh và lỗi mong đợi theo định dạng của MySQL: lỗi do trigger hoặc thủ tục có mã 1644 (SQLSTATE 45000) kèm thông báo tiếng Việt; lỗi ràng buộc CHECK có mã 3819 nêu tên ràng buộc; lỗi UNIQUE có mã 1062.

### TC1 — Một xe không thể có hai phiên đang chạy

```sql
START TRANSACTION;
INSERT INTO PHIEN (MaPhien, MaXe, MaCho, LoaiPhien)
VALUES ('P90', 'XE04', 'CHO05', 'ParkingOnly');
ROLLBACK;
```

Lỗi mong đợi: ERROR 1062 (23000): Duplicate entry 'XE04' for key 'PHIEN.UQ_Phien_Active_Xe' (XE04 đang có phiên P13 Active)

### TC2 — Số dư ví không được âm

```sql
UPDATE KHACH_HANG SET SoDuViDienTu = -1 WHERE MaKH = 'KH01';
```

Lỗi mong đợi: ERROR 3819 (HY000): Check constraint 'CHK_KhachHang_SoDu' is violated.

### TC3 — Giá sạc bắt buộc có loại trụ

```sql
INSERT INTO BANG_GIA (MaBangGia, LoaiGia, MaLoaiTru, LoaiCho, GioBatDau, GioKetThuc,
                      LaCaoDiem, DonGiaTheoPhut, HieuLucTu, MaQTV)
VALUES ('BG99', 'Charging', NULL, NULL, '06:00', '22:00', TRUE, 1000, '2026-11-01', 'QTV01');
```

Lỗi mong đợi: ERROR 3819 (HY000): Check constraint 'CHK_LoaiGia_LoaiTru' is violated.

### TC4 — Không mở phiên sạc trên trụ hỏng

```sql
START TRANSACTION;
INSERT INTO PHIEN (MaPhien, MaXe, MaCho, LoaiPhien)
VALUES ('P91', 'XE01', 'CHO11', 'ParkingAndCharging');
INSERT INTO CHI_TIET_PHIEN_SAC (MaPhien, MaTru, ThoiGianBatDauSac, ChiSoCongToDau)
VALUES ('P91', 'TS08', CURRENT_TIMESTAMP, 718);
ROLLBACK;
```

Lỗi mong đợi: ERROR 1644 (45000): Trụ sạc TS08 đang bảo trì hoặc báo lỗi

### TC5 — Không đặt chỗ ở chỗ đang bảo trì

```sql
INSERT INTO DAT_CHO (MaDatCho, MaXe, MaCho, ThoiGianDat, ThoiGianHetHan)
VALUES ('DC90', 'XE01', 'CHO12', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL 30 MINUTE);
```

Lỗi mong đợi: ERROR 1644 (45000): Ô đỗ CHO12 đang bảo trì kỹ thuật, vui lòng chọn ô khác!

### TC6 — Xe máy không đỗ ở ô đỗ ô tô

```sql
INSERT INTO PHIEN (MaPhien, MaXe, MaCho, LoaiPhien)
VALUES ('P92', 'XE10', 'CHO05', 'ParkingOnly');
```

Lỗi mong đợi: ERROR 1644 (45000): TRẢI NGHIỆM KHÁCH HÀNG: Xe máy không được đỗ tại ô đỗ ô tô (CarSlot)

### TC7 — Tài khoản bị khóa không mở được phiên

```sql
INSERT INTO PHIEN (MaPhien, MaXe, MaCho, LoaiPhien)
VALUES ('P93', 'XE08', 'CHO06', 'ParkingOnly');
```

Lỗi mong đợi: ERROR 1644 (45000): Tài khoản khách hàng đang bị khóa (xe XE08 cũng bị BiDenKhoa, nhưng trigger 3 được tạo trước trigger 5 nên lỗi tài khoản khóa được báo trước)

### TC8 — Chuẩn súng sạc không khớp cổng xe

```sql
START TRANSACTION;
INSERT INTO PHIEN (MaPhien, MaXe, MaCho, LoaiPhien)
VALUES ('P94', 'XE01', 'CHO06', 'ParkingAndCharging');
INSERT INTO CHI_TIET_PHIEN_SAC (MaPhien, MaTru, ThoiGianBatDauSac, ChiSoCongToDau)
VALUES ('P94', 'TS04', CURRENT_TIMESTAMP, 322);
ROLLBACK;
```

Lỗi mong đợi: ERROR 1644 (45000): Chuẩn sạc của xe (CCS2) không khớp với súng sạc (Type2) của trụ TS04

### TC9 — Sổ cái ví bất biến

```sql
UPDATE GIAO_DICH_VI SET SoTien = 1 WHERE MaGD = 'GD01';
```

Lỗi mong đợi: ERROR 1644 (45000): AN TOÀN TÀI CHÍNH: Bảng GIAO_DICH_VI là sổ cái bất biến (Append-Only), nghiêm cấm sửa hoặc xóa dữ liệu!

### TC10 — Số dư trước/sau của giao dịch phải khớp loại giao dịch

```sql
INSERT INTO GIAO_DICH_VI (MaGD, MaKH, LoaiGD, SoTien, SoDuTruoc, SoDuSau)
VALUES ('GD90', 'KH01', 'Deposit', 100000, 542000, 600000);
```

Lỗi mong đợi: ERROR 3819 (HY000): Check constraint 'CHK_GiaoDich_SoDu' is violated.

### TC11 — Phiên mở từ đặt chỗ phải đúng xe

```sql
INSERT INTO PHIEN (MaPhien, MaXe, MaCho, MaDatCho, LoaiPhien)
VALUES ('P95', 'XE01', 'CHO05', 'DC01', 'ParkingOnly');
```

Lỗi mong đợi: ERROR 1644 (45000): Xe trong phiên (XE01) không khớp xe đặt chỗ (XE03)

### TC12 — Thanh toán ví khi không đủ số dư

```sql
CALL sp_thanh_toan_hoa_don_vi('KH04', 'HD12', 'IDEM-DEMO-01');
```

Lỗi mong đợi: ERROR 1644 (45000): Số dư ví (161000.00) không đủ thanh toán (205000.00)

### TC13 — Không thanh toán hóa đơn của khách khác

```sql
CALL sp_thanh_toan_hoa_don_vi('KH01', 'HD12', 'IDEM-DEMO-02');
```

Lỗi mong đợi: ERROR 1644 (45000): Hóa đơn HD12 không thuộc khách hàng KH01 (HD12 là hóa đơn của KH04, dù KH01 đủ số dư)

### TC14 — Đặt chỗ mới đưa chỗ đỗ sang Reserved

```sql
START TRANSACTION; INSERT INTO DAT_CHO (MaDatCho, MaXe, MaCho, ThoiGianDat, ThoiGianHetHan) VALUES ('DC91', 'XE01', 'CHO05', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL 30 MINUTE); SELECT TrangThaiCho FROM CHO_DO_XE WHERE MaCho = 'CHO05'; ROLLBACK;
```

Kết quả mong đợi: TrangThaiCho = Reserved (trước khi đặt, CHO05 ở trạng thái Available)

### TC15 — Không mở phiên từ đặt chỗ đã hết hạn

```sql
INSERT INTO PHIEN (MaPhien, MaXe, MaCho, MaDatCho, LoaiPhien) VALUES ('P96', 'XE01', 'CHO05', 'DC05', 'ParkingOnly');
```

Lỗi mong đợi: ERROR 1644 (45000): Đặt chỗ DC05 đã bị hủy hoặc hết hạn

### TC16 — Trụ sạc phải thuộc đúng chỗ đỗ của phiên

```sql
START TRANSACTION; INSERT INTO PHIEN (MaPhien, MaXe, MaCho, LoaiPhien) VALUES ('P97', 'XE01', 'CHO06', 'ParkingAndCharging'); INSERT INTO CHI_TIET_PHIEN_SAC (MaPhien, MaTru, ChiSoCongToDau, ThoiGianBatDauSac) VALUES ('P97', 'TS02', 5060.00, CURRENT_TIMESTAMP); ROLLBACK;
```

Lỗi mong đợi: ERROR 1644 (45000): Trụ sạc TS02 không thuộc chỗ đỗ CHO06 của phiên

## 4.1 Tổng kết

Mười sáu ca kiểm thử bao phủ các ràng buộc khai báo (CHECK, UNIQUE trên cột sinh), các trigger 1, 2, 3, 4, 6, 10, 11 và thủ tục thanh toán. Trigger 5 và 7 có cấu trúc tương tự trigger 1 và 2 (cùng một mẫu kiểm tra trước khi INSERT); trigger 8 và 9 được kiểm chứng gián tiếp qua trạng thái cuối của dữ liệu mẫu, thời hạn ân hạn tự tính và các truy vấn Q6, Q12. Ba truy vấn đối chiếu Q10, Q11, Q13 cho kết quả 0 dòng, xác nhận hóa đơn, chi tiết phí, sổ cái và số dư ví khớp nhau.

# 5. Kết luận

Nhóm đã hoàn thành chuỗi công việc từ phân tích yêu cầu, thiết kế mô hình dữ liệu 14 bảng đã chuẩn hóa đến cài đặt đầy đủ trên MySQL 8.0 gồm 14 bảng, 11 quy tắc trigger (17 trigger vật lý), 4 stored procedure, phân quyền theo 3 vai trò, bộ dữ liệu mẫu 19 phiên, 13 truy vấn và 2 view. Dữ liệu mẫu được nạp khi các trigger đang bật nên đồng thời đóng vai trò kiểm thử các quy tắc nghiệp vụ.

Các khác biệt khi chuyển hệ thống từ PostgreSQL sang MySQL được ghi lại ở mục 3.9. Hướng phát triển tiếp theo là cho phép tương thích một chiều giữa chuẩn sạc của xe và súng sạc (trigger 4), và tính chi phí sạc theo từng khung giờ khi phiên kéo dài qua nhiều khung giá.

## 5.1 Đối chiếu với yêu cầu đồ án

| Giai đoạn | Yêu cầu | Nội dung trong báo cáo |
| --- | --- | --- |
| Phase 1: Thiết kế khái niệm | Problem statement, Business Rules, sơ đồ ER/EER đầy đủ | Mục 1 (giới thiệu, phạm vi, quy tắc nghiệp vụ 1.3); sơ đồ EER mục 2.1 |
| Phase 2: Thiết kế logic và chuẩn hóa | Ánh xạ lược đồ quan hệ, khóa ngoại, chứng minh chuẩn hóa 3NF/BCNF | Mục 2.2 (ánh xạ, 19 khóa ngoại); mục 2.3 (chuẩn hóa đến BCNF) |
| Phase 3: Cài đặt và truy vấn | Script DDL, dữ liệu mẫu (DML), từ 10 truy vấn phức tạp, 2 Trigger/View | Mục 3.2 (DDL 14 bảng); 3.6 (dữ liệu mẫu); 3.7 (13 truy vấn JOIN, truy vấn con, tổng hợp, CTE, hàm cửa sổ); 3.3 (17 trigger); 3.4 (4 stored procedure); 3.8 (2 view); mục 4 (kiểm thử) |
