# Bộ SQL 1410 (PostgreSQL)

## 1) Phạm vi
- Bộ script chuẩn mới nằm tại: `mysql/1410/`.
- Không sửa/xóa các file SQL cũ `mysql/00...17`.
- **Nguồn chuẩn để triển khai 1410**: `mysql/1410/00_FULL_DDL.sql` (orchestrator) + các file `01..17` cùng thư mục.

## 2) Thứ tự chạy
Khuyến nghị dùng psql:

```bash
cd mysql/1410
psql -v ON_ERROR_STOP=1 -f 00_FULL_DDL.sql <ten_database>
```

Nếu chạy thủ công, theo đúng thứ tự:
1. `01_KHACH_HANG.sql`
2. `02_PHUONG_TIEN.sql`
3. `03_QUAN_TRI_VIEN.sql`
4. `04_TRAM.sql`
5. `05_CHO_DO_XE.sql`
6. `06_LOAI_TRU_SAC.sql`
7. `07_TRU_SAC.sql`
8. `08_BANG_GIA.sql`
9. `09_DAT_CHO.sql`
10. `10_PHIEN.sql`
11. `11_CHI_TIET_PHIEN_SAC.sql`
12. `12_CHI_TIET_PHI.sql`
13. `13_HOA_DON.sql`
14. `14_GIAO_DICH_VI.sql`
15. `15_TRIGGERS.sql`
16. `16_RBAC.sql`
17. `17_PROCEDURES.sql`

## 3) Điểm đồng bộ/khác biệt chính so với 1310/2209
Bản 1410 giữ các điểm tốt (Registered/WalkIn, nhiều xe, CarSlot/MotorbikeSlot, đặt chỗ, phiên đỗ/sạc, pricing, invoice, wallet ledger, RBAC, hạn mức sạc, ân hạn, blacklist, bảo trì, tương thích chuẩn sạc) và sửa các lỗi logic trọng yếu:

1. **Thanh toán ví đúng chủ hóa đơn**
   - `sp_thanh_toan_hoa_don_vi` xác thực `p_ma_kh` là chủ hóa đơn qua chuỗi `HOA_DON -> PHIEN -> PHUONG_TIEN`.

2. **Idempotency thật sự cho thanh toán ví**
   - Cùng `idempotency_key` + cùng `MaHD` => retry thành công, **không trừ ví lần 2**.
   - Cùng `idempotency_key` nhưng khác `MaHD` => báo lỗi nghiệp vụ.

3. **Chặn trụ không sẵn sàng**
   - Chỉ cho phép mở sạc mới khi `TRU_SAC.TrangThaiTru = 'Available'`.
   - Có `FOR UPDATE` để giảm race condition khi tranh chấp cùng trụ.
   - Bổ sung unique partial index tránh nhiều phiên cùng `Charging` trên một trụ.

4. **Cấm ParkingOnly tạo chi tiết sạc**
   - Trigger kiểm tra `PHIEN.LoaiPhien` trước khi cho insert/update `CHI_TIET_PHIEN_SAC`.

5. **Giải phóng tài nguyên an toàn**
   - Chỉ trả `CHO_DO_XE/TRU_SAC` về `Available` khi không còn phiên `Active/Charging` khác trên cùng tài nguyên.

6. **Walk-in đúng phương thức và chống trùng external reference**
   - Walk-in chỉ cho `POS_Card`, `Dynamic_QR`, `Cash`.
   - `POS_Card/Dynamic_QR` bắt buộc có `MaGiaoDichNgoai`.
   - Chống tái sử dụng `MaGiaoDichNgoai` qua unique index + kiểm tra thủ tục.

7. **Invoice/Ledger nhất quán hơn**
   - Ràng buộc tổng tiền không âm, trạng thái thanh toán khớp thời gian thanh toán.
   - Ledger vẫn append-only và kiểm tra số dư theo loại giao dịch.

8. **Mở rộng coverage trigger cho INSERT + UPDATE quan trọng**
   - Các trigger check nghiệp vụ đã mở rộng cho các cột trọng yếu để giảm bypass khi UPDATE.

## 4) Cột đã đồng bộ xuyên file
Đã thống nhất dùng các cột:
- `ChuanSac`
- `HanMucSac_VND`
- `HanMucSac_kWh`
- `TrangThaiSac`
- `LyDoKetThuc`
- `MaGiaoDichDoiTac`
- `MaGiaoDichNgoai`
- `TienCoc`
- `TienKhauTru`

## 5) Test tình huống lỗi
Các kịch bản test SQL/comment nằm cuối `17_PROCEDURES.sql` gồm:
- sai chủ hóa đơn,
- retry idempotency,
- cùng key cho hóa đơn khác,
- trụ bận,
- ParkingOnly sạc,
- walk-in sai phương thức,
- duplicate external reference,
- giải phóng tài nguyên khi còn phiên active khác.

## 6) Lưu ý PostgreSQL role/transaction
- Nên chạy bằng tài khoản có quyền tạo bảng/function/trigger/procedure/index/role grant.
- Dùng `-v ON_ERROR_STOP=1` để fail-fast.
- Khi tích hợp ứng dụng thật, các lệnh `CALL` thanh toán nên đặt trong transaction rõ ràng ở tầng ứng dụng để kiểm soát retry/log.
