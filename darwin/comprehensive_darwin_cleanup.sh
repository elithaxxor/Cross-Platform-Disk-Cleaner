#!/bin/bash
#=====================================================================
# System Cleanup Utility
# Description: A cross-platform utility to clean temporary files
#              and cache directories on Linux and macOS systems.


# **Color Codes for Terminal Output**
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# **Global Variables**
DRY_RUN=0          # Flag for dry run mode
AUTO_CONFIRM=0     # Flag for auto-confirming prompts

# **Setup Logging**
LOGS_DIR="$HOME/cleanup_logs"
mkdir -p "$LOGS_DIR"
DELETION_LOG="$LOGS_DIR/deletions.log"
OPERATIONS_LOG="$LOGS_DIR/operations.log"
ERROR_LOG="$LOGS_DIR/errors.log"

# Create a log file in the current working directory
CWD_LOG="$(pwd)/cleanup_$(date +%Y-%m-%d_%H-%M-%S).log"
touch "$CWD_LOG"
echo "System Cleanup Utility - Deletion Log" > "$CWD_LOG"
echo "Started: $(date)" >> "$CWD_LOG"
echo "User: $(whoami)" >> "$CWD_LOG"
echo "----------------------------------------" >> "$CWD_LOG"

# **Timestamp Function for Logs**
timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

# **Log Functions**
log_operation() {
    echo "$(timestamp) - $1" >> "$OPERATIONS_LOG"
    echo -e "${BLUE}${BOLD}INFO:${NC} $1"
}

log_error() {
    echo "$(timestamp) - ERROR: $1" >> "$ERROR_LOG"
    echo -e "${RED}${BOLD}ERROR:${NC} $1" >&2
}

log_deletion() {
    local item="$1"
    echo "$(timestamp) - DELETED: $item" >> "$DELETION_LOG"
    echo "DELETED: $item" >> "$CWD_LOG"
}

# **Check if Script is Run with Sudo**
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}${BOLD}Notice:${NC} Some operations may require administrative privileges."
        echo -e "You can run again with 'sudo' for full functionality.\n"
    fi
}

# **Get System Information**
get_system_info() {
    echo -e "\n=============== SYSTEM INFORMATION ===============" >> "$OPERATIONS_LOG"
    log_operation "Gathering system information..."
    
    OS_TYPE=$(uname -s)
    OS_VERSION=$(uname -r)
    HOSTNAME=$(hostname)
    CURRENT_USER=$(whoami)
    UPTIME=$(uptime)
    
    if [ "$OS_TYPE" = "Darwin" ]; then
        IP_ADDRESS=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1)
        MAC_ADDRESS=$(ifconfig en0 | awk '/ether/{print $2}')
        WIRELESS_INTERFACE=$(networksetup -listallhardwareports | grep -A 1 "Wi-Fi" | grep "Device" | awk '{print $2}')
    else
        IP_ADDRESS=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1" | head -n 1)
        MAC_ADDRESS=$(ip link show | grep -oP '(?<=link/ether\s)([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -n 1)
        WIRELESS_INTERFACE=$(ip link show | grep -i wireless | cut -d: -f2 | awk '{print $1}' | head -n 1)
    fi
    
    if [ "$OS_TYPE" = "Darwin" ]; then
        DISK_INFO=$(df -h / | tail -n 1)
        DISK_TOTAL=$(echo "$DISK_INFO" | awk '{print $2}')
        DISK_USED=$(echo "$DISK_INFO" | awk '{print $3}')
        DISK_AVAIL=$(echo "$DISK_INFO" | awk '{print $4}')
        DISK_PERCENT=$(echo "$DISK_INFO" | awk '{print $5}')
    else
        DISK_INFO=$(df -h / | tail -n 1)
        DISK_TOTAL=$(echo "$DISK_INFO" | awk '{print $2}')
        DISK_USED=$(echo "$DISK_INFO" | awk '{print $3}')
        DISK_AVAIL=$(echo "$DISK_INFO" | awk '{print $4}')
        DISK_PERCENT=$(echo "$DISK_INFO" | awk '{print $5}')
    fi
    
    echo -e "\n${GREEN}${BOLD}====== System Information ======${NC}"
    echo -e "${CYAN}${BOLD}Operating System:${NC} $OS_TYPE $OS_VERSION"
    echo -e "${CYAN}${BOLD}Hostname:${NC} $HOSTNAME"
    echo -e "${CYAN}${BOLD}User:${NC} $CURRENT_USER"
    echo -e "${CYAN}${BOLD}Date/Time:${NC} $(date)"
    echo -e "${CYAN}${BOLD}Uptime:${NC} $UPTIME"
    echo
    echo -e "${GREEN}${BOLD}====== Network Information ======${NC}"
    echo -e "${CYAN}${BOLD}IP Address:${NC} $IP_ADDRESS"
    echo -e "${CYAN}${BOLD}MAC Address:${NC} $MAC_ADDRESS"
    echo -e "${CYAN}${BOLD}Wireless Interface:${NC} $WIRELESS_INTERFACE"
    echo
    echo -e "${GREEN}${BOLD}====== Disk Information ======${NC}"
    echo -e "${CYAN}${BOLD}Total Disk Space:${NC} $DISK_TOTAL"
    echo -e "${CYAN}${BOLD}Used Disk Space:${NC} $DISK_USED ($DISK_PERCENT)"
    echo -e "${CYAN}${BOLD}Available Disk Space:${NC} $DISK_AVAIL"
    echo
    
    echo "OS Type: $OS_TYPE $OS_VERSION" >> "$OPERATIONS_LOG"
    echo "Hostname: $HOSTNAME" >> "$OPERATIONS_LOG"
    echo "User: $CURRENT_USER" >> "$OPERATIONS_LOG"
    echo "Date/Time: $(date)" >> "$OPERATIONS_LOG"
    echo "IP Address: $IP_ADDRESS" >> "$OPERATIONS_LOG"
    echo "MAC Address: $MAC_ADDRESS" >> "$OPERATIONS_LOG"
    echo "Wireless Interface: $WIRELESS_INTERFACE" >> "$OPERATIONS_LOG"
    echo "Disk Space: Total=$DISK_TOTAL, Used=$DISK_USED ($DISK_PERCENT), Available=$DISK_AVAIL" >> "$OPERATIONS_LOG"
    echo "=========================================" >> "$OPERATIONS_LOG"
    
    read -p "Press Enter to continue..."
}

# **Safely Delete Files with Enhancements**
safe_delete() {
    local dir="$1"
    local description="$2"
    local days=""
    
    # Check if third parameter is a number for time-based deletion
    if [[ "$3" =~ ^[0-9]+$ ]]; then
        days="$3"
        shift 3
    else
        shift 2
    fi
    
    local exclude_patterns=("$@")  # Remaining arguments are exclude patterns
    
    # Safety check for critical directories
    if [[ "$dir" == "/" || "$dir" == "$HOME" || "$dir" == "/home" ]]; then
        log_error "Refusing to delete critical directory: $dir"
        return 1
    fi
    
    if [ ! -d "$dir" ]; then
        log_error "Directory does not exist: $dir"
        return 1
    fi
    
    # Count files based on days
    if [ -n "$days" ]; then
        local file_count=$(find "$dir" -type f -mtime +"$days" 2>/dev/null | wc -l)
    else
        local file_count=$(find "$dir" -type f 2>/dev/null | wc -l)
    fi
    
    if [ "$file_count" -eq 0 ]; then
        echo -e "${YELLOW}${BOLD}Notice:${NC} No files found in $dir"
        return 0
    fi
    
    local total_size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
    
    echo -e "\n--- Cleaning $description ($dir) - $(timestamp) ---" >> "$CWD_LOG"
    
    # Confirmation unless auto-confirmed
    if [ "$AUTO_CONFIRM" -eq 1 ]; then
        confirm="y"
    else
        echo -e "${YELLOW}${BOLD}Warning:${NC} About to delete $file_count files in $dir ($total_size)"
        read -p "Are you sure you want to proceed? (y/n): " confirm
    fi
    
    if [[ "$confirm" != [yY] ]]; then
        echo -e "${BLUE}${BOLD}Info:${NC} Deletion cancelled for $dir"
        log_operation "Deletion cancelled for $dir by user"
        echo "* Deletion cancelled by user" >> "$CWD_LOG"
        return 0
    fi
    
    log_operation "Starting deletion of $description in $dir"
    echo "===== Deleting files from $dir on $(timestamp) =====" >> "$DELETION_LOG"
    
    local deleted_count=0
    local skipped_count=0
    local error_count=0
    
    # Build find command with optional time-based filter
    if [ -n "$days" ]; then
        find_cmd="find \"$dir\" -type f -mtime +$days"
    else
        find_cmd="find \"$dir\" -type f"
    fi
    
    eval $find_cmd | while read file; do
        skip=0
        for pattern in "${exclude_patterns[@]}"; do
            if [[ "$file" =~ $pattern ]]; then
                echo -e "${YELLOW}${BOLD}Skipping:${NC} $file (matches $pattern)"
                ((skipped_count++))
                skip=1
                break
            fi
        done
        
        if [ "$skip" -eq 0 ]; then
            if [ "$DRY_RUN" -eq 1 ]; then
                echo "[DRY RUN] Would delete: $file"
                log_deletion "[DRY RUN] $file"
            else
                if rm -f "$file" 2>/dev/null; then
                    echo -e "${GREEN}${BOLD}Deleted:${NC} $file"
                    log_deletion "$file"
                    ((deleted_count++))
                else
                    if [ ! -w "$file" ]; then
                        log_error "Permission denied: $file (try with sudo)"
                    else
                        log_error "Failed to delete: $file"
                    fi
                    ((error_count++))
                fi
            fi
        fi
    done
    
    # Clean up empty directories if not in dry run
    if [ "$DRY_RUN" -eq 0 ]; then
        find "$dir" -type d -empty -delete 2>/dev/null
    fi
    
    local new_size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
    echo -e "${GREEN}${BOLD}Completed cleaning $description.${NC}"
    echo -e "Directory size: Before=$total_size, After=$new_size"
    log_operation "Completed deletion in $dir. Size before: $total_size, after: $new_size"
    
    echo "* Size before: $total_size, after: $new_size" >> "$CWD_LOG"
    echo "* Files deleted: $deleted_count, skipped: $skipped_count, errors: $error_count" >> "$CWD_LOG"
    
    read -p "Press Enter to continue..."
}

# **Analyze Disk Usage**
analyze_disk_usage() {
    log_operation "Analyzing disk usage"
    
    echo -e "\n${GREEN}${BOLD}====== Disk Usage Analysis ======${NC}"
    
    if [ "$(uname)" = "Darwin" ]; then
        echo -e "${CYAN}${BOLD}System and User Temporary Locations:${NC}"
        echo -e "============================================"
        du -sh /private/var/log/ /private/var/tmp/ /tmp/ ~/Library/Logs/ ~/Library/Caches/ ~/.Trash/ 2>/dev/null
        
        echo -e "\n${CYAN}${BOLD}Top 15 largest directories in ~/Library/Caches/:${NC}"
        du -sh ~/Library/Caches/* 2>/dev/null | sort -rh | head -n 15
        
        echo -e "\n${CYAN}${BOLD}Top 15 largest directories in ~/Library/Logs/:${NC}"
        du -sh ~/Library/Logs/* 2>/dev/null | sort -rh | head -n 15
    else
        echo -e "${CYAN}${BOLD}System and User Temporary Locations:${NC}"
        echo -e "============================================"
        du -sh /var/log/ /tmp/ /var/tmp/ ~/.cache/ ~/.local/share/Trash/files 2>/dev/null
        
        echo -e "\n${CYAN}${BOLD}Top 15 largest directories in ~/.cache/:${NC}"
        du -sh ~/.cache/* 2>/dev/null | sort -rh | head -n 15
        
        echo -e "\n${CYAN}${BOLD}Top 15 largest directories in /var/log/:${NC}"
        du -sh /var/log/* 2>/dev/null | sort -rh | head -n 15
    fi
    
    log_operation "Disk usage analysis completed"
    read -p "Press Enter to continue..."
}

# **Clean User Cache with Interactive Selection**
clean_user_cache() {
    if [ "$(uname)" = "Darwin" ]; then
        cache_dir="$HOME/Library/Caches"
        exclude_patterns=(".*\.plist$" ".*\.app$")
    else
        cache_dir="$HOME/.cache"
        exclude_patterns=(".*\.conf$" ".*\.log$")
    fi
    
    echo "Found caches in $cache_dir:"
    find "$cache_dir" -maxdepth 1 -type d | while read subdir; do
        if [ "$subdir" != "$cache_dir" ]; then
            size=$(du -sh "$subdir" 2>/dev/null | awk '{print $1}' || echo "0B")
            echo "  $(basename "$subdir"): $size"
        fi
    done
    
    read -p "Enter cache name to clean (or 'all', 'skip'): " choice
    if [ "$choice" == "all" ]; then
        safe_delete "$cache_dir" "user cache" "${exclude_patterns[@]}"
    elif [ "$choice" == "skip" ]; then
        echo "Skipping user cache cleanup"
    elif [ -d "$cache_dir/$choice" ]; then
        safe_delete "$cache_dir/$choice" "$choice cache" "${exclude_patterns[@]}"
    else
        echo "Invalid choice"
    fi
}

# **Clean Temporary Files**
clean_temp_files() {
    if [ "$(uname)" = "Darwin" ]; then
        safe_delete "/tmp" "temporary files" ".*\.plist$" ".*\.app$"
        safe_delete "/private/var/tmp" "system temporary files" ".*\.plist$" ".*\.app$"
    else
        safe_delete "/tmp" "temporary files" ".*\.conf$" ".*\.log$"
        safe_delete "/var/tmp" "system temporary files" ".*\.conf$" ".*\.log$"
    fi
}

# **Clean Trash**
clean_trash() {
    if [ "$(uname)" = "Darwin" ]; then
        safe_delete "$HOME/.Trash" "trash"
    else
        safe_delete "$HOME/.local/share/Trash/files" "trash"
    fi
}

# **Clean Logs with Time-Based Deletion**
clean_logs() {
    if [ "$(uname)" = "Darwin" ]; then
        safe_delete "$HOME/Library/Logs" "user logs" 30 ".*System.*"
    else
        if [ -d "$HOME/.local/share/logs" ]; then
            safe_delete "$HOME/.local/share/logs" "user logs" 30
        else
            echo -e "${YELLOW}${BOLD}Notice:${NC} No user logs directory found."
        fi
    fi
}

# **Clean Browser Caches**
clean_browser_caches() {
    if [ "$(uname)" = "Darwin" ]; then
        safe_delete "$HOME/Library/Caches/Google/Chrome" "Chrome cache"
        safe_delete "$HOME/Library/Caches/com.apple.Safari" "Safari cache"
    else
        safe_delete "$HOME/.cache/google-chrome" "Chrome cache"
        safe_delete "$HOME/.cache/mozilla/firefox" "Firefox cache"
    fi
}

# **Clean Package Manager Caches**
clean_package_caches() {
    if [ "$(uname)" = "Darwin" ]; then
        safe_delete "$HOME/Library/Caches/Homebrew" "Homebrew cache"
    else
        if [ -d "/var/cache/apt" ]; then
            echo "Cleaning APT cache requires sudo"
            if [ "$EUID" -eq 0 ]; then
                apt-get clean
                log_operation "Cleaned APT cache"
            else
                echo "Please run with sudo to clean APT cache"
            fi
        fi
        # Add support for other package managers (e.g., yum, pacman) as needed
    fi
}

# **Clean All Users' Caches (Sudo Only)**
clean_all_users() {
    if [ "$EUID" -ne 0 ]; then
        echo "This option requires sudo"
        return
    fi
    echo -e "${YELLOW}${BOLD}WARNING:${NC} This will clean caches for all users."
    read -p "Proceed? (y/n): " confirm
    if [[ "$confirm" != [yY] ]]; then
        return
    fi
    if [ "$(uname)" = "Darwin" ]; then
        for user in $(dscl . list /Users | grep -v '^_'); do
            user_home=$(dscl . read /Users/$user NFSHomeDirectory | cut -d: -f2 | sed 's/^ //')
            if [ -d "$user_home/Library/Caches" ]; then
                safe_delete "$user_home/Library/Caches" "$user user cache" ".*\.plist$" ".*\.app$"
            fi
        done
    else
        for user_home in /home/*; do
            if [ -d "$user_home/.cache" ]; then
                safe_delete "$user_home/.cache" "$(basename $user_home) user cache" ".*\.conf$" ".*\.log$"
            fi
        done
    fi
}

# **Show Disk Usage**
show_disk_usage() {
    df -h / | awk 'NR==2 {print "Used: " $3 " Free: " $4}'
}

# **Main Menu Function**
show_menu() {
    clear
    echo -e "${GREEN}${BOLD}=================================${NC}"
    echo -e "${GREEN}${BOLD}    SYSTEM CLEANUP UTILITY      ${NC}"
    echo -e "${GREEN}${BOLD}=================================${NC}"
    echo -e "${CYAN}${BOLD}Operating System:${NC} $(uname -s) $(uname -r)"
    echo -e "${CYAN}${BOLD}User:${NC} $(whoami)"
    echo -e "${CYAN}${BOLD}Date:${NC} $(date)"
    echo -e "${CYAN}${BOLD}Disk Usage:${NC} $(show_disk_usage)"
    echo -e "${GREEN}${BOLD}=================================${NC}"
    echo -e "1. ${BOLD}System Information${NC}"
    echo -e "2. ${BOLD}Analyze Disk Usage${NC}"
    echo -e "3. ${BOLD}Clean User Cache${NC}"
    echo -e "4. ${BOLD}Clean Temporary Files${NC}"
    echo -e "5. ${BOLD}Clean Trash/Recycle Bin${NC}"
    echo -e "6. ${BOLD}Clean Logs${NC}"
    echo -e "7. ${BOLD}Clean Browser Caches${NC}"
    echo -e "8. ${BOLD}Clean Package Manager Caches${NC}"
    if [ "$EUID" -eq 0 ]; then
        echo -e "9. ${BOLD}Clean All Users' Caches${NC}"
    fi
    echo -e "0. ${BOLD}Exit${NC}"
    echo -e "${GREEN}${BOLD}=================================${NC}"
    echo -e "Enter your choice: "
}

# **Trap for Script Interruption**
trap "echo -e '\n${MAGENTA}${BOLD}🛑 Script interrupted${NC}'; exit 1" SIGINT SIGTERM

# **Main Function**
main() {
    clear
    echo -e "${GREEN}${BOLD}=================================================${NC}"
    echo -e "${GREEN}${BOLD}        WELCOME TO SYSTEM CLEANUP UTILITY        ${NC}"
    echo -e "${GREEN}${BOLD}=================================================${NC}"
    echo -e "${BLUE}${BOLD}This utility helps clean temporary files and cache${NC}"
    echo -e "${BLUE}${BOLD}directories on both Linux and macOS systems.      ${NC}"
    echo -e "${GREEN}${BOLD}=================================================${NC}"
    echo
    
    log_operation "Script started by user $(whoami)"
    check_sudo
    
    # Parse command-line arguments
    while [[ "$1" == --* ]]; do
        case "$1" in
            --dry-run) DRY_RUN=1 ;;
            --yes) AUTO_CONFIRM=1 ;;
            --help)
                echo "Usage: $0 [--dry-run] [--yes] [--help]"
                echo "  --dry-run: Simulate actions without deleting"
                echo "  --yes: Auto-confirm all prompts"
                echo "  --help: Show this message"
                exit 0
                ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done
    
    # Backup reminder
    echo -e "${YELLOW}${BOLD}WARNING:${NC} Ensure important data is backed up before proceeding."
    read -p "Press Enter to continue or Ctrl+C to exit..."
    
    # Main menu loop
    while true; do
        show_menu
        read choice
        echo
        
        case $choice in
            1) get_system_info ;;
            2) analyze_disk_usage ;;
            3) clean_user_cache ;;
            4) clean_temp_files ;;
            5) clean_trash ;;
            6) clean_logs ;;
            7) clean_browser_caches ;;
            8) clean_package_caches ;;
            9)
                if [ "$EUID" -eq 0 ]; then
                    clean_all_users
                else
                    echo -e "${RED}${BOLD}Invalid option${NC}"
                    sleep 1
                fi
                ;;
            0)
                echo -e "${GREEN}${BOLD}Thank you for using System Cleanup Utility!${NC}"
                log_operation "Script terminated normally by user"
                
                echo "----------------------------------------" >> "$CWD_LOG"
                echo "Cleanup completed: $(date)" >> "$CWD_LOG"
                DELETION_COUNT=$(grep -c "DELETED:" "$CWD_LOG")
                echo "Total items deleted: $DELETION_COUNT" >> "$CWD_LOG"
                
                echo -e "${GREEN}${BOLD}A log of all deletions has been saved to:${NC}"
                echo -e "${CYAN}$CWD_LOG${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}${BOLD}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# Start the script
main "$@"
