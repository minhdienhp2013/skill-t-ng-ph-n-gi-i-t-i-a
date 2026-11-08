---
name: upscale-anh
description: Nâng độ phân giải và chất lượng ảnh bằng AI, giảm răng cưa, làm nét và xuất ảnh cho in ấn hoặc sử dụng kỹ thuật số. Dùng khi người dùng yêu cầu upscale, phóng lớn, phục hồi độ nét, ảnh 4K/8K/16K hoặc file ảnh đúng kích thước in; không dùng cho yêu cầu chỉ tạo ảnh mới.
---

# Upscale ảnh

Biến ảnh người dùng cung cấp thành file có kích thước mong muốn, nét tự nhiên và giữ đúng nội dung gốc. Làm việc trực tiếp với file có độ phân giải gốc, không lấy ảnh xem trước hoặc ảnh thu nhỏ làm nguồn khi có bản tốt hơn.

## Quy trình

1. Kiểm tra kích thước pixel, tỷ lệ, hướng ảnh, chữ/logo, khuôn mặt, nền, vùng trong suốt và định dạng nguồn. Xác nhận đơn vị hoặc kích thước khi thiếu thông tin thực sự cần thiết; không tự mặc định toàn bộ ảnh phải là 16K hay để in.
2. Giữ nguyên nhận diện, nội dung, chính tả, bố cục, màu và ánh sáng. Chỉ xóa vật thể, thay nền, tăng sáng hay thay thiết kế khi người dùng yêu cầu. Thực hiện yêu cầu chỉnh sửa bằng công cụ tạo/chỉnh ảnh tích hợp theo chỉ dẫn của công cụ đó; kiểm tra đầu ra vì ảnh sinh lại có thể làm sai logo hoặc chữ. Nếu kết quả làm sai chi tiết, giữ phần đó từ ảnh gốc và chỉ sử dụng phần chỉnh phù hợp.
3. Chọn công cụ nâng ảnh phù hợp. Trên macOS có sẵn bộ [Real-ESRGAN](assets/realesrgan/NOTICE.md) trong skill: `scripts/enhance.sh INPUT OUTPUT.png artwork` cho chữ, biểu tượng và minh họa; dùng `photo` cho ảnh tự nhiên. Đây là mô hình 4×, hãy thử vùng nhỏ khi chữ hoặc nhận diện quan trọng và so sánh với ảnh gốc. Tránh làm nét quá mức gây viền sáng, méo chữ hoặc thêm chi tiết giả. Nếu hình đã đủ lớn, không bắt buộc chạy 4× rồi tạo file trung gian quá lớn.
4. Với ảnh cần in, đọc [hướng dẫn xuất in](references/xuat-in.md). Xử lý tỷ lệ và kích thước chính xác, tôn trọng yêu cầu về nền trong suốt; không tự kéo méo hay cắt mất nội dung. Nếu không có yêu cầu khổ in, giữ tỷ lệ gốc và không gán kích thước vật lý tùy ý.
5. Kiểm tra ảnh hoàn chỉnh và các vùng chi tiết ở tỷ lệ lớn: chữ, logo/khuôn mặt, rìa ảnh, màu, vùng trong suốt và lỗi ghép. Kiểm tra file thật sau khi xuất: kích thước pixel, DPI khi có khổ in, hệ màu và khả năng mở. Xuất PNG hoặc định dạng khác theo yêu cầu; lưu bản mới, không ghi đè ảnh nguồn.

Khi bàn giao, liên kết file thành phẩm, nêu pixel và kích thước in khi có, cùng các chỉnh sửa đã làm. Nói rõ ảnh được nâng bằng AI khi phù hợp: tăng số pixel và làm mịn không khôi phục chắc chắn mọi chi tiết gốc, không bảo đảm hết răng cưa ở mọi mức zoom. Với ảnh nguồn nhỏ và bản in lớn, khuyến nghị in thử một đoạn đúng tỷ lệ.
