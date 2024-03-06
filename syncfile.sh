#!/bin/bash

# Đọc cấu hình từ file syncfile.conf
source syncfile.conf

# Định nghĩa đường dẫn của folder chứa file đếm
COUNT_DIR="./count"

# Kiểm tra và tạo folder count nếu chưa tồn tại
if [ ! -d "$COUNT_DIR" ]; then
    mkdir -p "$COUNT_DIR"
fi

# Biến toàn cục lưu trữ PID của inotifywait
INOTIFY_PID=""

# Khởi tạo giá trị biến
MODIFY_COUNT=0
CREATE_COUNT=0
DELETE_COUNT=0
SYNC_SUCCESS_COUNT=0
SYNC_ERROR_COUNT=0

# Hàm gửi tin nhắn Telegram
send_telegram_message() {
    local message=$1
    message=$(echo -e "$message")
    message=$(echo "$message" | sed 's/ /%20/g')
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="$message" &> /dev/null
}

# Hàm ghi log vaf hien thi log ra console
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Hàm kiểm tra và lấy máy chủ master
check_master() {
    for entry in "${SERVERS[@]}"; do
        server_ip=$(echo "$entry" | cut -d':' -f1)
        if ssh "$server_ip" "ip addr show | grep -q '$VIP'" &> /dev/null; then
            echo "$server_ip"
            return
        fi
    done
    log_message "Không tìm thấy máy chủ master với IP VIP: $VIP"
}

# Hàm đồng bộ hóa dữ liệu
sync_data() {
    local master=$1
    for entry in "${SERVERS[@]}"; do
        server_ip=$(echo "$entry" | cut -d':' -f1)
        sync_dir=$(echo "$entry" | cut -d':' -f2)

        if [ "$server_ip" != "$master" ]; then
            log_message "Đồng bộ hóa dữ liệu từ $master tới $server_ip..."
            if [ "$master" = "$HOSTNAME" ]; then
                if rsync -avz "$sync_dir/" "$server_ip:$sync_dir/" --delete 2>&1 | tee -a "$LOG_FILE"; then
                    ((SYNC_SUCCESS_COUNT++))
                    save_count_to_file
                    log_message "Đồng bộ hóa thành công tới $server_ip"
                else
                    ((SYNC_ERROR_COUNT++))
                    save_count_to_file
                    log_message "Lỗi khi đồng bộ hóa tới $server_ip, xem log trên để biết chi tiết"
                fi
            else
                if ssh "$master" "rsync -avz $sync_dir/ $server_ip:$sync_dir/ --delete" 2>&1 | tee -a "$LOG_FILE"; then
                    ((SYNC_SUCCESS_COUNT++))
                    save_count_to_file
                    log_message "Đồng bộ hóa thành công tới $server_ip"
                else
                    ((SYNC_ERROR_COUNT++))
                    save_count_to_file
                    log_message "Lỗi khi đồng bộ hóa tới $server_ip, xem log trên để biết chi tiết"
                fi
            fi
        fi
    done
}

# Hàm để xác định SYNC_DIR cho máy chủ hiện tại
determine_sync_dir() {
    for entry in "${SERVERS[@]}"; do
        server_ip=$(echo "$entry" | cut -d':' -f1)
        if [ "$server_ip" = "$HOSTNAME" ] || [ "$server_ip" = "$(hostname -I | awk '{print $1}')" ]; then
            SYNC_DIR=$(echo "$entry" | cut -d':' -f2)
            return
        fi
    done
}

# Hàm để khởi động inotifywait
start_inotify() {
    log_message "Bắt đầu inotifywait trên $SYNC_DIR"
    determine_sync_dir
    if [ -d "$SYNC_DIR" ] && [ ! -z "$SYNC_DIR" ]; then
        if [ "$current_master" = "$HOSTNAME" ]; then
            inotifywait -m -r -e modify,create,delete --format '%e %w%f' -q "$SYNC_DIR" | while read -r event file; do
                log_message "Phát hiện thay đổi trên $current_master: $file"
                if [[ $event == *"MODIFY"* ]]; then
                    ((MODIFY_COUNT++))
                    log_message "Tăng MODIFY_COUNT, file: $file"
                fi
                if [[ $event == *"CREATE"* ]]; then
                    ((CREATE_COUNT++))
                    log_message "Tăng CREATE_COUNT, file: $file"
                fi
                if [[ $event == *"DELETE"* ]]; then
                    ((DELETE_COUNT++))
                    log_message "Tăng DELETE_COUNT, file: $file"
                fi
                save_count_to_file
                sync_data "$current_master"
            done &
            INOTIFY_PID=$!
        else
            ssh "$current_master" "inotifywait -m -r -e modify,create,delete --format '%e %w%f' -q '$SYNC_DIR'" | while read -r event file; do
                log_message "Phát hiện thay đổi trên $current_master qua SSH: $file"
                if [[ $event == *"MODIFY"* ]]; then
                    ((MODIFY_COUNT++))
                    log_message "Tăng MODIFY_COUNT qua SSH, file: $file"
                fi
                if [[ $event == *"CREATE"* ]]; then
                    ((CREATE_COUNT++))
                    log_message "Tăng CREATE_COUNT qua SSH, file: $file"
                fi
                if [[ $event == *"DELETE"* ]]; then
                    ((DELETE_COUNT++))
                    log_message "Tăng DELETE_COUNT qua SSH, file: $file"
                fi
                save_count_to_file
                sync_data "$current_master"
            done &
            INOTIFY_PID=$!
        fi
    else
        log_message "Thư mục đồng bộ hóa '$SYNC_DIR' không tồn tại hoặc không được chỉ định."
    fi
}

# Hàm lưu giá trị biến vào file
save_count_to_file() {
    echo "$MODIFY_COUNT" > "$COUNT_DIR/modify_count"
    echo "$CREATE_COUNT" > "$COUNT_DIR/create_count"
    echo "$DELETE_COUNT" > "$COUNT_DIR/delete_count"
    echo "$SYNC_SUCCESS_COUNT" > "$COUNT_DIR/sync_success_count"
    echo "$SYNC_ERROR_COUNT" > "$COUNT_DIR/sync_error_count"
    log_message "Lưu trữ giá trị biến vào file."
}

# Hàm đọc giá trị biến từ file
load_count_from_file() {
    if [ -f "$COUNT_DIR/modify_count" ]; then
        MODIFY_COUNT=$(cat "$COUNT_DIR/modify_count")
		log_message MODIFY_COUNT=$MODIFY_COUNT
    fi
    if [ -f "$COUNT_DIR/create_count" ]; then
        CREATE_COUNT=$(cat "$COUNT_DIR/create_count")
		log_message CREATE_COUNT=$CREATE_COUNT
    fi
    if [ -f "$COUNT_DIR/delete_count" ]; then
        DELETE_COUNT=$(cat "$COUNT_DIR/delete_count")
		log_message DELETE_COUNT=$DELETE_COUNT
    fi
    if [ -f "$COUNT_DIR/sync_success_count" ]; then
        SYNC_SUCCESS_COUNT=$(cat "$COUNT_DIR/sync_success_count")
		log_message SYNC_SUCCESS_COUNT=$SYNC_SUCCESS_COUNT
    fi
    if [ -f "$COUNT_DIR/sync_error_count" ]; then
        SYNC_ERROR_COUNT=$(cat "$COUNT_DIR/sync_error_count")
		log_message SYNC_ERROR_COUNT=$SYNC_ERROR_COUNT
    fi
    log_message "Đọc giá trị biến từ file."
}

# Hàm để ngắt inotifywait hiện tại
stop_inotify() {
    if [ ! -z "$INOTIFY_PID" ]; then
        kill $INOTIFY_PID
        INOTIFY_PID=""
    fi

    pkill -f 'inotifywait -m -r -e modify,create,delete'
    local ssh_pids=$(pgrep -f 'ssh .* inotifywait')
    if [ ! -z "$ssh_pids" ]; then
        for pid in $ssh_pids; do
            kill $pid
        done
    fi

    if [ "$current_master" != "$HOSTNAME" ]; then
        ssh "$current_master" "pkill -f 'inotifywait -m -r -e modify,create,delete'"
    fi

    log_message "Đã dừng tất cả các quá trình inotifywait và các kết nối SSH liên quan trên cả máy chủ local và máy chủ nắm giữ IP VIP"
}

# Hàm gửi báo cáo hàng ngày
send_daily_report() {
    load_count_from_file
    local report="👀🤖 KẾT QUẢ THAY ĐỔI DỮ LIỆU 24h 🤖👀"$'\n\n'"🖥 Server: $VIP - $(hostname)"$'\n\n'"⏰ Thời gian: $(date '+%Y-%m-%d %H:%M:%S')"$'\n\n'"✏️ Modify: $MODIFY_COUNT"$'\n\n'"🆕 Create: $CREATE_COUNT"$'\n\n'"🗑 Delete: $DELETE_COUNT"$'\n\n'"🚀 Sync Master-Slave: $SYNC_SUCCESS_COUNT"$'\n\n'"🆘 Sync Master-Slave Err: $SYNC_ERROR_COUNT"
    log_message "report=$report"
	send_telegram_message "$report"
    log_message "Đã gửi báo cáo hàng ngày."
}

# Kiểm tra đối số dòng lệnh
if [[ "$1" == "send_daily_report" ]]; then
    send_daily_report
    exit 0
fi

# Chính
current_master=""
while true; do
    new_master=$(check_master)
    if [ "$new_master" != "$current_master" ]; then
        log_message "Máy chủ master mới: $new_master"
        stop_inotify  # Ngắt inotifywait hiện tại
        current_master="$new_master"
        sync_data "$current_master"
        start_inotify  # Khởi động inotifywait trên máy chủ master mới
        
        # Xác định danh sách các slave
        slaves=()
        for server in "${SERVERS[@]}"; do
            server_ip=$(echo "$server" | cut -d':' -f1)
            if [ "$server_ip" != "$current_master" ]; then
                slaves+=("$server_ip")
            fi
        done

        # Chuyển danh sách IP slaves thành chuỗi để gửi tin nhắn
        slave_ips_str=$(IFS=, ; echo "${slaves[*]}")

        # Gửi tin nhắn Telegram chỉ với IP của các slave
        send_telegram_message "🤖🔔THÔNG BÁO CẬP NHẬT🔔🤖\n\n📌 VIP: $VIP\n\n➡️ Update sang máy chủ Master mới: $current_master\n\n➡️ Sync từ Master $current_master tới slave $slave_ips_str\n\n⏰ Thời gian: $(date '+%Y-%m-%d %H:%M:%S')"
    fi

    sleep 0.005
done
