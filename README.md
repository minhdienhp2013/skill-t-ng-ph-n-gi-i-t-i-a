# Upscale ảnh

Codex skill để phóng lớn ảnh, giảm răng cưa, tăng độ nét và xuất PNG theo kích thước in.

## Dùng trong Codex

Cài thư mục skill này vào `~/.codex/skills/upscale-anh`, rồi gọi `$upscale-anh` và đính kèm ảnh cùng yêu cầu kích thước hoặc khổ in.

## Chạy công cụ độc lập

Trên macOS, script `scripts/enhance.sh` dùng Real-ESRGAN đóng gói sẵn để nâng ảnh 4×:

```bash
scripts/enhance.sh input.jpg output.png photo
scripts/enhance.sh logo.png logo-upscaled.png artwork
```

- `photo`: ảnh chụp và nội dung tự nhiên.
- `artwork`: chữ, logo, biểu tượng và minh họa.
- `scripts/export-png.sh --help`: xem cách xuất PNG theo kích thước và thông số in.

Skill đi kèm runtime macOS universal (Apple silicon và Intel) cùng model. Các giấy phép và thông báo của thành phần bên thứ ba nằm trong `assets/realesrgan/`.

Xem [SKILL.md](SKILL.md) để biết quy trình đầy đủ và [hướng dẫn xuất in](references/xuat-in.md) để chuẩn bị file theo khổ in.
