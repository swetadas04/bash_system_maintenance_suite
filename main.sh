#!/bin/bash

LOG_PATH="/var/log/system_toolkit.log"

# Functions for logging
write_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_PATH
    echo "[INFO] $1"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> $LOG_PATH
    echo "[ERROR] $1"
}

# Initialize log file
sudo touch $LOG_PATH 2>/dev/null || touch system_toolkit.log

# Display interface
display_interface() {
    clear
    echo "=== System Administration Toolkit ==="
    echo "1. Create Backup"
    echo "2. System Update"
    echo "3. View Logs"
    echo "4. About System"
    echo "5. Disk Space"
    echo "6. Execute All Operations"
    echo "7. Exit"
    echo -n "Select operation: "
}

# Backup functionality
create_backup() {
    write_log "Initiating backup process"
    
    BACKUP_PATH="$HOME/backups"
    mkdir -p $BACKUP_PATH
    BACKUP_NAME="system_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    echo "Backup selection:"
    echo "1. User home folder"
    echo "2. Specific folder"
    echo -n "Select: "
    read backup_choice
    
    if [ "$backup_choice" = "1" ]; then
        SOURCE_PATH="$HOME"
    else
        echo -n "Enter folder path: "
        read SOURCE_PATH
    fi
    
    if tar -czf "$BACKUP_PATH/$BACKUP_NAME" "$SOURCE_PATH" 2>/dev/null; then
        write_log "Backup successful: $BACKUP_NAME"
        echo "Backup completed!"
    else
        log_error "Backup operation failed"
    fi
    
    # Maintain backup rotation (keep 3 latest)
    ls -t $BACKUP_PATH/*.tar.gz 2>/dev/null | tail -n +4 | xargs rm -f
}

# System update procedure
system_update() {
    write_log "Starting system updates"
    
    echo "Updating package information..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt upgrade -y
        sudo apt autoremove -y
        sudo apt clean
    elif command -v dnf &> /dev/null; then
        sudo dnf update -y
        sudo dnf autoremove -y
        sudo dnf clean all
    fi
    
    echo "Removing temporary files..."
    sudo rm -rf /tmp/*
    rm -rf $HOME/.cache/*
    
    write_log "Update process finished"
}

# Log viewing function
view_logs() {
    echo -n "Monitoring duration (seconds): "
    read monitor_time
    
    echo "Reviewing system logs for $monitor_time seconds..."
    timeout $monitor_time tail -f /var/log/syslog | grep -E "error|fail|warning" || echo "No issues detected"
    write_log "Log review completed"
}

# System information function
about_system() {
    echo "=== System Information Report ==="
    echo "Operating System: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '\"')"
    echo "Kernel Version: $(uname -r)"
    echo "Processor: $(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
    echo "Total Memory: $(free -h | grep Mem: | awk '{print $2}')"
    echo "Available Memory: $(free -h | grep Mem: | awk '{print $7}')"
    echo "System Uptime: $(uptime -p)"
    echo "Logged in Users: $(who | wc -l)"
    echo "Current User: $(whoami)"
    echo "Hostname: $(hostname)"
    
    write_log "System information displayed"
}

# Disk space analysis function
disk_space_analysis() {
    echo "=== Storage Utilization Summary ==="
    df -h | grep -v tmpfs
    
    echo ""
    echo "=== Large File Identification (>100MB) ==="
    find /home -type f -size +100M -exec ls -lh {} \; 2>/dev/null | head -10
    
    echo ""
    echo "=== Directory Size Analysis ==="
    du -sh /home/* 2>/dev/null | sort -hr | head -5
    
    write_log "Disk space analysis completed"
}

# Complete maintenance routine
execute_all_operations() {
    write_log "=== Starting comprehensive maintenance ==="
    echo "Executing full maintenance routine..."
    
    echo "1. Checking system information..."
    about_system
    sleep 2
    
    echo ""
    echo "2. Analyzing disk space..."
    disk_space_analysis
    sleep 2
    
    echo ""
    echo "3. Creating system backup..."
    create_backup
    sleep 2
    
    echo ""
    echo "4. Performing system updates..."
    system_update
    sleep 2
    
    echo ""
    echo "5. Scanning system logs..."
    grep -i "error" /var/log/syslog | tail -3 2>/dev/null || echo "No recent system errors"
    
    write_log "All operations completed"
    echo "Maintenance routine finished!"
}

# Primary execution function
main_execution() {
    write_log "Toolkit started by user: $(whoami)"
    
    while true; do
        display_interface
        read user_choice
        
        case $user_choice in
            1) create_backup ;;
            2) system_update ;;
            3) view_logs ;;
            4) about_system ;;
            5) disk_space_analysis ;;
            6) execute_all_operations ;;
            7) 
                write_log "Toolkit session ended"
                echo "Thank you for using the System Toolkit!"
                exit 0 
                ;;
            *) echo "Invalid selection! Please choose 1-7." ;;
        esac
        
        echo ""
        echo -n "Press Enter to continue..."
        read
    done
}

# Launch the toolkit
main_execution
