# RsyncfileSSH-Multi-Server
Tools for synchronizing data with Rsync-SSH across multiple servers

# Introduction to the File Synchronization Project

This project includes a bash script (`syncfile.sh`), a configuration file (`syncfile.conf`), and a directory (`count`) for storing statistics.

## Purpose

The `syncfile.sh` script is designed to synchronize data across multiple servers and automatically switch the master server based on IPVIP as defined in the `syncfile.conf`. It uses `rsync` for data synchronization and `inotifywait` to monitor changes in the synchronization directory.

## Project Structure

- `syncfile.sh`: The main script to perform synchronization.
- `syncfile.conf`: A configuration file containing information such as the list of servers, synchronization directory path, and necessary information for sending notifications via Telegram.
- `count`: This directory contains files to store the number of events such as file creation, modification, and deletion, as well as the number of successful and failed synchronizations.

## Main Features

### Reading Configuration

The script first reads the configuration from `syncfile.conf` to obtain necessary information such as the list of servers and Telegram configuration.

### Checking and Creating the `count` Directory

If the `count` directory does not exist, the script will create it to store statistical data.

### Monitoring Changes and Synchronizing

The script uses `inotifywait` to monitor changes in the synchronization directory and performs data synchronization using `rsync` whenever there are events of file creation, modification, or deletion.

### Sending Notifications via Telegram

For each significant event, the script can send notifications via Telegram using Telegram's API.

### Logging and Reporting

All important events are logged in the log file (`logsync.log`) and daily reports on the synchronization status can be sent via Telegram.

## Conclusion

This project provides an automated solution for data synchronization across servers, with real-time change monitoring and instant notifications via Telegram, helping system administrators easily monitor and manage the synchronization status.

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# RsyncfileSSH-Multi-Server
 Tools đồng bộ dữ liệu Rsync-SSH nhiều máy chủ

# Giới Thiệu Dự Án Đồng Bộ Hóa File

Dự án này bao gồm một script bash (`syncfile.sh`), một file cấu hình (`syncfile.conf`), và một thư mục (`count`) để lưu trữ các thống kê.

## Mục Đích

Script `syncfile.sh` được thiết kế để đồng bộ hóa dữ liệu giữa nhiều máy chủ và tự động chuyển đổi máy chủ master giựa theo IPVIP dựa vào cấu hình được định nghĩa trong `syncfile.conf`. Nó sử dụng `rsync` để đồng bộ dữ liệu và `inotifywait` để theo dõi các thay đổi trong thư mục đồng bộ hóa.

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
