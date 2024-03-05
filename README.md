# RsyncfileSSH-Multi-Server
 Tools đồng bộ dữ liệu Rsync-SSH nhiều máy chủ

# Giới Thiệu Dự Án Đồng Bộ Hóa File

Dự án này bao gồm một script bash (`syncfile.sh`), một file cấu hình (`syncfile.conf`), và một thư mục (`count`) để lưu trữ các thống kê.

## Mục Đích

Script `syncfile.sh` được thiết kế để đồng bộ hóa dữ liệu giữa nhiều máy chủ dựa vào cấu hình được định nghĩa trong `syncfile.conf`. Nó sử dụng `rsync` để đồng bộ dữ liệu và `inotifywait` để theo dõi các thay đổi trong thư mục đồng bộ hóa.

## Cấu Trúc Dự Án

- `syncfile.sh`: Script chính để thực hiện đồng bộ hóa.
- `syncfile.conf`: File cấu hình chứa thông tin như danh sách các máy chủ, đường dẫn thư mục đồng bộ, và thông tin cần thiết cho việc gửi thông báo qua Telegram.
- `count`: Thư mục này chứa các file để lưu trữ số lượng các sự kiện như tạo mới, chỉnh sửa, và xóa file, cũng như số lượng lần đồng bộ hóa thành công và thất bại.

## Chức Năng Chính

### Đọc Cấu Hình

Script đầu tiên đọc cấu hình từ `syncfile.conf` để lấy thông tin cần thiết như danh sách máy chủ và cấu hình Telegram.

### Kiểm Tra và Tạo Thư Mục `count`

Nếu thư mục `count` không tồn tại, script sẽ tạo thư mục này để lưu trữ các số liệu thống kê.

### Theo Dõi Thay Đổi và Đồng Bộ Hóa

Script sử dụng `inotifywait` để theo dõi các thay đổi trong thư mục đồng bộ hóa và thực hiện đồng bộ hóa dữ liệu sử dụng `rsync` mỗi khi có sự kiện tạo mới, chỉnh sửa hoặc xóa file.

### Gửi Thông Báo qua Telegram

Mỗi khi có sự kiện đáng chú ý, script có thể gửi thông báo qua Telegram sử dụng API của Telegram.

### Ghi Log và Báo Cáo

Tất cả các sự kiện quan trọng đều được ghi lại trong file log (`logsync.log`) và có thể gửi báo cáo hàng ngày qua Telegram về tình trạng đồng bộ hóa.

## Kết Luận

Dự án này cung cấp một giải pháp tự động cho việc đồng bộ hóa dữ liệu giữa các máy chủ, với khả năng theo dõi thay đổi thời gian thực và thông báo tức thì qua Telegram, giúp quản trị hệ thống dễ dàng theo dõi và quản lý tình trạng đồng bộ hóa.
