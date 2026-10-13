# Báo cáo hệ thống 1410
## Hệ thống quản lý bãi đỗ xe và sạc xe điện trong đô thị

## 1. Giới thiệu hệ thống
Hệ thống hỗ trợ vận hành bãi đỗ xe tích hợp trụ sạc xe điện theo hướng tập trung, giúp khách hàng dễ tìm chỗ, đặt chỗ, đỗ xe, sạc xe và thanh toán minh bạch trong cùng một hành trình dịch vụ.

Hệ thống phục vụ cả khách thành viên và khách vãng lai, đồng thời hỗ trợ nhiều loại phương tiện, nhiều phiên sử dụng dịch vụ và theo dõi trạng thái theo thời gian thực.

## 2. Mục tiêu và lợi ích dành cho khách hàng
- **Thuận tiện khi sử dụng:** tìm nhanh trạm phù hợp, kiểm tra chỗ trống và thực hiện dịch vụ trên một luồng thống nhất.
- **Minh bạch chi phí:** phí đỗ xe, phí sạc, phụ phí phát sinh (nếu có) và thanh toán được thể hiện rõ ràng theo từng phiên.
- **Linh hoạt theo nhu cầu thực tế:** đáp ứng cả nhu cầu chỉ đỗ xe hoặc đỗ kết hợp sạc.
- **Hỗ trợ đa đối tượng khách:** khách thành viên có trải nghiệm đầy đủ; khách vãng lai vẫn có thể sử dụng dịch vụ và thanh toán theo quy trình tại chỗ.

## 3. Hành trình sử dụng dịch vụ điển hình
1. Khách hàng tìm trạm gần nhất và kiểm tra chỗ đỗ/trụ sạc phù hợp với phương tiện.
2. Khách thành viên có thể đặt chỗ trước; khách vãng lai có thể vào sử dụng trực tiếp theo khả dụng thực tế.
3. Bắt đầu phiên đỗ xe hoặc phiên đỗ kết hợp sạc.
4. Theo dõi trạng thái trong quá trình sử dụng: trạng thái chỗ đỗ, trạng thái sạc, thời gian sử dụng và hạn mức sạc.
5. Kết thúc phiên, hệ thống tính phí theo quy định và hỗ trợ thanh toán.
6. Khách nhận hóa đơn và xem lại lịch sử giao dịch.

## 4. Các tính năng chính dành cho khách hàng
- **Tìm kiếm và chọn dịch vụ:**
  - Tìm trạm, chỗ đỗ và trụ sạc theo nhu cầu.
  - Xác định loại dịch vụ: chỉ đỗ xe hoặc đỗ kết hợp sạc.

- **Hỗ trợ khách thành viên và khách vãng lai:**
  - Khách thành viên: hỗ trợ đặt chỗ trước, quản lý phương tiện và lịch sử sử dụng.
  - Khách vãng lai: hỗ trợ quy trình vào bãi, sử dụng dịch vụ và thanh toán tại chỗ.

- **Quản lý nhiều phương tiện:**
  - Một khách hàng có thể quản lý nhiều phương tiện trong cùng tài khoản.

- **Đặt chỗ và quản lý chỗ đỗ:**
  - Tạo đặt chỗ, theo dõi trạng thái đặt chỗ và thời hạn hiệu lực.

- **Đỗ xe và sạc xe:**
  - Mở phiên dịch vụ, ghi nhận thời gian vào/ra.
  - Ghi nhận quá trình sạc, trạng thái đang sạc/đã hoàn tất.

- **Theo dõi trạng thái và hạn mức sạc:**
  - Theo dõi tiến trình sử dụng theo thời gian thực.
  - Thiết lập hoặc áp dụng hạn mức sạc theo cấu hình dịch vụ.

- **Thời gian ân hạn và tính phí:**
  - Hỗ trợ thời gian ân hạn sau khi sạc hoàn tất.
  - Tính phí theo từng khoản mục: đỗ xe, sạc xe và các khoản phát sinh theo chính sách.

- **Thanh toán, hóa đơn và lịch sử giao dịch:**
  - Hỗ trợ thanh toán theo phương thức được triển khai tại hệ thống.
  - Xuất hóa đơn theo từng phiên.
  - Tra cứu lịch sử giao dịch để đối soát.

## 5. Các tình huống sử dụng và vận hành thực tế
1. **Đặt chỗ đồng thời:** nhiều khách thao tác cùng lúc cho một chỗ đỗ.
2. **Khách không đến (no-show):** đặt chỗ hết hạn nhưng khách không xuất hiện.
3. **Sạc xong nhưng chưa rời chỗ:** cần áp dụng thời gian ân hạn và quy tắc chuyển tiếp tính phí.
4. **Hết tiền khi sạc:** phiên sạc cần được xử lý theo quy tắc an toàn giao dịch.
5. **Trụ lỗi hoặc mất điện:** phiên đang chạy cần được ghi nhận trạng thái phù hợp.
6. **Không tương thích chuẩn sạc:** phương tiện và trụ không tương thích, cần chuyển phương án sử dụng.
7. **Thanh toán thất bại:** cần cơ chế ghi nhận và xử lý trạng thái thanh toán chưa hoàn tất.
8. **Khách vãng lai:** cần quy trình sử dụng dịch vụ không phụ thuộc tài khoản thành viên.
9. **Mất kết nối:** gián đoạn kết nối trong lúc sử dụng dịch vụ cần có cơ chế đồng bộ lại trạng thái.
10. **Tranh chấp hóa đơn:** cần đối soát lịch sử phiên và giao dịch để xử lý minh bạch.

## 6. Cam kết về tính thuận tiện, minh bạch và an toàn
- **Thuận tiện:** hành trình sử dụng rõ ràng từ tìm chỗ đến thanh toán.
- **Minh bạch:** mọi phiên dịch vụ đều có thông tin trạng thái, chi phí và hóa đơn tương ứng.
- **An toàn:** trạng thái vận hành và giao dịch được quản lý có kiểm soát, hỗ trợ truy vết khi phát sinh sự cố hoặc tranh chấp.

## 7. Phạm vi hệ thống và lưu ý triển khai
- Báo cáo này tập trung vào phạm vi dữ liệu và quy trình nghiệp vụ cốt lõi của hệ thống đỗ xe/sạc xe.
- Một số chức năng trong thực tế cần phối hợp thêm ứng dụng khách hàng, bộ lập lịch tác vụ và thiết bị hiện trường (ví dụ trụ sạc, cổng vào/ra, cảm biến kết nối).
- Việc triển khai thực tế cần cấu hình chi tiết theo từng trạm, chính sách vận hành và phương thức thanh toán áp dụng.
