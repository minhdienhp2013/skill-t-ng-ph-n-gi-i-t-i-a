# Xuất ảnh đúng kích thước in

- Với kích thước cm và DPI/PPI mục tiêu: `pixel = cm / 2.54 × DPI`. Khi chỉ yêu cầu 16K và không đưa số pixel khác, dùng cạnh dài 16.384 px theo quy ước của người dùng; tính cạnh còn lại theo tỷ lệ. Nếu họ chỉ định 16K UHD hoặc pixel cụ thể, dùng đúng số đó. Ví dụ 445 × 61 cm → 16.384 × 2.246 px, khoảng 93,52 ppi; 165,5 × 165,5 cm → 16.384 × 16.384 px, khoảng 251,45 ppi.
- DPI metadata xác định kích thước đặt in, không bổ sung chi tiết thực. PNG khổ 16K vuông RGBA cần khoảng 1 GiB cho một buffer chưa nén; kiểm tra tài nguyên và không âm thầm giảm độ phân giải nếu máy không đủ.
- Trên macOS, `scripts/export-png.sh` dùng Accelerate để nội suy chất lượng cao và ghi PNG sRGB với DPI đúng khi có kích thước cm. Có thể xử lý ảnh đã nâng AI hoặc nguồn gốc. Giữ tỉ lệ bằng `--fit contain`; vùng thừa là trong suốt, do đó vùng có hình có thể nhỏ hơn toàn khổ in. Công cụ sẽ báo kích thước thực của vùng ảnh. Nếu người dùng muốn hình phủ kín, bổ sung nền hợp lý hoặc hỏi lựa chọn khi cần; chỉ dùng `--fit stretch` khi họ đồng ý biến dạng.

Ví dụ chạy các lệnh sau, thay đường dẫn bằng file thực tế:

```bash
upscale_skill_dir="/đường/dẫn/đến/upscale-anh"
"$upscale_skill_dir/scripts/enhance.sh" "/đường dẫn/ảnh gốc.png" "/đường dẫn/ảnh-4x.png" artwork
"$upscale_skill_dir/scripts/export-png.sh" --input "/đường dẫn/ảnh-4x.png" --output "/đường dẫn/ảnh-in.png" --width-cm 445 --height-cm 61 --long-edge 16384 --fit contain
```

Thay `--long-edge 16384` bằng `--dpi 150` nếu người dùng yêu cầu chính xác DPI và kích thước vật lý. Nếu chỉ cần ảnh kỹ thuật số, bỏ cả `--width-cm` và `--height-cm`, dùng `--long-edge`; công cụ giữ tỷ lệ và không tự xác nhận khổ in. Dùng `--native` để chuẩn hóa hướng mà không thay kích thước pixel. Không kết hợp `--dpi`, `--long-edge` và `--native`.

Nguồn ảnh có thể có profile màu hoặc hướng EXIF; công cụ đọc hướng và xuất sRGB. Không tự nhận PNG RGB là CMYK. Nếu nhà in cần profile CMYK, lề xén hoặc định dạng đặc biệt, xác nhận thông số với họ trước khi chuyển đổi.

Đọc `scripts/enhance.sh --help` và `scripts/export-png.sh --help` để biết lựa chọn. Bộ Real-ESRGAN đóng gói dành cho macOS arm64/x86_64 và cần GPU Metal; nếu sandbox chặn GPU, dùng cơ chế cấp quyền sẵn có hoặc phương án phù hợp, không thay đổi Gatekeeper. Nguồn và giấy phép trong `assets/realesrgan/`.
