#!/bin/bash
#=====================================================================
# System Cleanup Utility
# Description: A cross-platform utility to clean temporary files
#              and cache directories on Linux and macOS systems.
# Author: Your Name
# Version: 1.0
# License: MIT
#=====================================================================

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Setup logging
LOGS_DIR="$HOME/cleanup_logs"
mkdir -p "$LOGS_DIR"
DELETION_LOG="$LOGS_DIR/deletions.log"
OPERATIONS_LOG="$LOGS_DIR/operations.log"
ERROR_LOG="$LOGS_DIR/errors.log"

# Timestamp function for logs
timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

# Log functions
log_operation() {
    echo "$(timestamp) - $1" >> "$OPERATIONS_LOG"
    echo -e "${BLUE}${BOLD}INFO:${NC} $1"
}

log_error() {
    echo "$(timestamp) - ERROR: $1" >> "$ERROR_LOG"
    echo -e "${RED}${BOLD}ERROR:${NC} $1" >&2
}

log_deletion() {
    echo "$(timestamp) - DELETED: $1" >> "$DELETION_LOG"
}

# Function to check if the script is run with sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}${BOLD}Notice:${NC} Some operations may require administrative privileges."
        echo -e "You can run again with 'sudo' for full functionality.\n"
    fi
}

# Function to get system information
get_system_info() {
    # Create a header in the logs
    echo -e "\n=============== SYSTEM INFORMATION ===============" >> "$OPERATIONS_LOG"
    log_operation "Gathering system information..."
    
    # Get OS information
    OS_TYPE=$(uname -s)
    OS_VERSION=$(uname -r)
    HOSTNAME=$(hostname)
    CURRENT_USER=$(whoami)
    UPTIME=$(uptime)
    
    # Get network information
    if [ "$OS_TYPE" = "Darwin" ]; then
        # macOS
        IP_ADDRESS=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1)
        MAC_ADDRESS=$(ifconfig en0 | awk '/ether/{print $2}')
        WIRELESS_INTERFACE=$(networksetup -listallhardwareports | grep -A 1 "Wi-Fi" | grep "Device" | awk '{print $2}')
    else
        # Linux
        IP_ADDRESS=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1" | head -n 1)
        MAC_ADDRESS=$(ip link show | grep -oP '(?<=link/ether\s)([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -n 1)
        WIRELESS_INTERFACE=$(ip link show | grep -i wireless | cut -d: -f2 | awk '{print $1}' | head -n 1)
    fi
    
    # Get disk information
    if [ "$OS_TYPE" = "Darwin" ]; then
        # macOS
        DISK_INFO=$(df -h / | tail -n 1)
        DISK_TOTAL=$(echo "$DISK_INFO" | awk '{print $2}')
        DISK_USED=$(echo "$DISK_INFO" | awk '{print $3}')
        DISK_AVAIL=$(echo "$DISK_INFO" | awk '{print $4}')
        DISK_PERCENT=$(echo "$DISK_INFO" | awk '{print $5}')
    else
        # Linux
        DISK_INFO=$(df -h / | tail -n 1)
        DISK_TOTAL=$(echo "$DISK_INFO" | awk '{print $2}')
        DISK_USED=$(echo "$DISK_INFO" | awk '{print $3}')
        DISK_AVAIL=$(echo "$DISK_INFO" | awk '{print $4}')
        DISK_PERCENT=$(echo "$DISK_INFO" | awk '{print $5}')
    fi
    
    # Output the information
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
    
    # Add information to the log file
    echo "OS Type: $OS_TYPE $OS_VERSION" >> "$OPERATIONS_LOG"
    echo "Hostname: $HOSTNAME" >> "$OPERATIONS_LOG"
    echo "User: $CURRENT_USER" >> "$OPERATIONS_LOG"
    echo "Date/Time: $(date)" >> "$OPERATIONS_LOG"
    echo "IP Address: $IP_ADDRESS" >> "$OPERATIONS_LOG"
    echo "MAC Address: $MAC_ADDRESS" >> "$OPERATIONS_LOG"
    echo "Wireless Interface: $WIRELESS_INTERFACE" >> "$OPERATIONS_LOG"
    echo "Disk Space: Total=$DISK_TOTAL, Used=$DISK_USED ($DISK_PERCENT), Available=$DISK_AVAIL" >> "$OPERATIONS_LOG"
    echo "=========================================" >> "$OPERATIONS_LOG"
    
    # Press enter to continue
    read -p "Press Enter to continue..."
}

# Function to safely delete files with user confirmation
safe_delete() {
    local dir="$1"
    local description="$2"
    local skip_pattern="$3"
    
    if [ ! -d "$dir" ]; then
        log_error "Directory does not exist: $dir"
        return 1
    fi
    
    # Count files before asking for confirmation
    local file_count=$(find "$dir" -type f | wc -l)
    if [ "$file_count" -eq 0 ]; then
        echo -e "${YELLOW}${BOLD}Notice:${NC} No files found in $dir"
        return 0
    fi
    
    # Calculate total size
    local total_size=$(du -sh "$dir" | awk '{print $1}')
    
    # Confirm deletion
    echo -e "${YELLOW}${BOLD}Warning:${NC} About to delete $file_count files in $dir ($total_size)"
    read -p "Are you sure you want to proceed? (y/n): " confirm
    if [[ "$confirm" != [yY] ]]; then
        echo -e "${BLUE}${BOLD}Info:${NC} Deletion cancelled for $dir"
        log_operation "Deletion cancelled for $dir by user"
        return 0
    fi
    
    log_operation "Starting deletion of $description in $dir"
    
    # Create header in deletion log
    echo "===== Deleting files from $dir on $(timestamp) =====" >> "$DELETION_LOG"
    
    # Loop through files instead of using rm -rf for more control
    find "$dir" -type f | while read file; do
        # Skip files matching the skip pattern
        if [[ -n "$skip_pattern" && "$file" =~ $skip_pattern ]]; then
            echo -e "${YELLOW}${BOLD}Skipping protected file:${NC} $file"
        else
            # Delete the file and log it
            rm -f "$file" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}${BOLD}Deleted:${NC} $file"
                log_deletion "$file"
            else
                echo -e "${RED}${BOLD}Failed to delete:${NC} $file"
                log_error "Failed to delete: $file"
            fi
        fi
    done
    
    # Also clean empty directories
    find "$dir" -type d -empty -delete 2>/dev/null
    
    # Summarize
    local new_size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
    echo -e "${GREEN}${BOLD}Completed cleaning $description.${NC}"
    echo -e "Directory size: Before=$total_size, After=$new_size"
    log_operation "Completed deletion in $dir. Size before: $total_size, after: $new_size"
    
    # Press enter to continue
    read -p "Press Enter to continue..."
}

# Function to analyze disk usage
analyze_disk_usage() {
    log_operation "Analyzing disk usage"
    
    echo -e "\n${GREEN}${BOLD}====== Disk Usage Analysis ======${NC}"
    
    if [ "$(uname)" = "Darwin" ]; then
        # macOS
        echo -e "${CYAN}${BOLD}System and User Temporary Locations:${NC}"
        echo -e "============================================"
        du -sh /private/var/log/ /private/var/tmp/ /tmp/ ~/Library/Logs/ ~/Library/Caches/ ~/.Trash/ 2>/dev/null
        
        echo -e "\n${CYAN}${BOLD}Top 15 largest directories in ~/Library/Caches/:${NC}"
        du -sh ~/Library/Caches/* 2>/dev/null | sort -rh | head -n 15
        
        echo -e "\n${CYAN}${BOLD}Top 15 largest directories in ~/Library/Logs/:${NC}"
        du -sh ~/Library/Logs/* 2>/dev/null | sort -rh | head -n 15
    else
        # Linux
        echo -e "${CYAN}${BOLD}System and User Temporary Locations:${NC}"
        echo -e "============================================"
        du -sh /var/log/ /tmp/ /var/tmp/ ~/.cache/ ~/.local/share/Trash/files 2>/dev/null
        
        echo -e "\n${CYAN}${BOLD}Top 15 largest directories in ~/.cache/:${NC}"
        du -sh ~/.cache/* 2>/dev/null | sort -rh | head -n 15
        
        echo -e "\n${CYAN}${BOLD}Top 15 largest directories in /var/log/:${NC}"
        du -sh /var/log/* 2>/dev/null | sort -rh | head -n 15
    fi
    
    log_operation "Disk usage analysis completed"
    
    # Press enter to continue
    read -p "Press Enter to continue..."
}

# Function to clean user cache
clean_user_cache() {
    if [ "$(uname)" = "Darwin" ]; then
        # macOS
        safe_delete "$HOME/Library/Caches" "user cache" ".*\.(plist|app)$"
    else
        # Linux
        safe_delete "$HOME/.cache" "user cache" ".*\.(conf|log)$"
    fi
}

# Function to clean temporary files
clean_temp_files() {
    if [ "$(uname)" = "Darwin" ]; then
        # macOS
        safe_delete "/tmp" "temporary files" ".*\.(plist|app)$"
        safe_delete "/private/var/tmp" "system temporary files" ".*\.(plist|app)$"
    else
        # Linux
        safe_delete "/tmp" "temporary files" ".*\.(conf|log)$"
        safe_delete "/var/tmp" "system temporary files" ".*\.(conf|log)$"
    fi
}

# Function to clean trash
clean_trash() {
    if [ "$(uname)" = "Darwin" ]; then
        # macOS
        safe_delete "$HOME/.Trash" "trash" ""
    else
        # Linux
        safe_delete "$HOME/.local/share/Trash/files" "trash" ""
    fi
}

# Function to clean logs
clean_logs() {
    if [ "$(uname)" = "Darwin" ]; then
        # macOS
        safe_delete "$HOME/Library/Logs" "user logs" ".*System.*"
    else
        # Linux
        # Most Linux logs need sudo access
        echo -e "${YELLOW}${BOLD}Note:${NC} Cleaning system logs typically requires sudo privileges."
        echo -e "This option will only clean logs the current user has permission to modify."
        
        if [ -d "$HOME/.local/share/logs" ]; then
            safe_delete "$HOME/.local/share/logs" "user logs" ""
        else
            echo -e "${YELLOW}${BOLD}Notice:${NC} No user logs directory found."
        fi
    fi
}

# Function to clean Time Machine snapshots (macOS only)
clean_time_machine_snapshots() {
    if [ "$(uname)" != "Darwin" ]; then
        echo -e "${YELLOW}${BOLD}Notice:${NC} Time Machine is only available on macOS."
        read -p "Press Enter to continue..."
        return
    fi
    
    log_operation "Listing Time Machine snapshots"
    
    # List snapshots
    echo -e "${CYAN}${BOLD}Current Time Machine Snapshots:${NC}"
    tmutil listlocalsnapshots / 2>/dev/null
    
    # Ask for confirmation
    echo
    read -p "Do you want to delete all local Time Machine snapshots? (y/n): " confirm
    if [[ "$confirm" != [yY] ]]; then
        echo -e "${BLUE}${BOLD}Info:${NC} Snapshot deletion cancelled."
        log_operation "Time Machine snapshot deletion cancelled by user"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Run with sudo if available
    if [ "$EUID" -eq 0 ]; then
        log_operation "Deleting all Time Machine snapshots"
        echo -e "${GREEN}${BOLD}Deleting all Time Machine snapshots...${NC}"
        tmutil deletelocalsnapshots / &>/dev/null
        echo -e "${GREEN}${BOLD}Done!${NC}"
    else
        echo -e "${YELLOW}${BOLD}Notice:${NC} Administrative privileges required for this operation."
        echo -e "Please run this script with sudo to delete Time Machine snapshots."
    fi
    
    log_operation "Time Machine snapshot cleanup completed"
    read -p "Press Enter to continue..."
}

# Function to scan Wi-Fi networks
scan_wifi() {
    log_operation "Scanning Wi-Fi networks"
    
    # Detect OS
    if [ "$(uname)" = "Darwin" ]; then
        # macOS Wi-Fi scanning
        echo -e "${CYAN}${BOLD}Scanning for nearby Wi-Fi networks...${NC}"
        echo -e "This may take a few seconds...\n"
        
        # Use airport command
        AIRPORT="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
        
        if [ -x "$AIRPORT" ]; then
            "$AIRPORT" -s
        else
            echo -e "${RED}${BOLD}Error:${NC} Airport utility not found."
            log_error "Airport utility not found at $AIRPORT"
        fi
    else
        # Linux Wi-Fi scanning
        echo -e "${CYAN}${BOLD}Scanning for nearby Wi-Fi networks...${NC}"
        echo -e "This may take a few seconds...\n"
        
        # Try to determine wireless interface
        WIRELESS_INTERFACE=$(ip link show | grep -i wireless | cut -d: -f2 | awk '{print $1}' | head -n 1)
        
        if [ -z "$WIRELESS_INTERFACE" ]; then
            # Ask user to specify
            echo -e "${YELLOW}${BOLD}Could not detect wireless interface automatically.${NC}"
            read -p "Please enter your wireless interface name (e.g., wlan0): " WIRELESS_INTERFACE
        fi
        
        # Check if iwlist is available
        if command -v iwlist &>/dev/null; then
            echo -e "${CYAN}${BOLD}Using interface:${NC} $WIRELESS_INTERFACE"
            
            if [ "$EUID" -eq 0 ]; then
                iwlist "$WIRELESS_INTERFACE" scan | grep -E "ESSID|Quality|Channel"
            else
                echo -e "${YELLOW}${BOLD}Note:${NC} For better results, run with sudo."
                sudo iwlist "$WIRELESS_INTERFACE" scan | grep -E "ESSID|Quality|Channel" || iwlist "$WIRELESS_INTERFACE" scan | grep -E "ESSID|Quality|Channel"
            fi
        else
            echo -e "${RED}${BOLD}Error:${NC} iwlist command not found."
            log_error "iwlist command not found"
        fi
    fi
    
    log_operation "Wi-Fi scan completed"
    read -p "Press Enter to continue..."
}

# Main menu function
show_menu() {
    clear
    echo -e "${GREEN}${BOLD}=================================${NC}"
    echo -e "${GREEN}${BOLD}    SYSTEM CLEANUP UTILITY      ${NC}"
    echo -e "${GREEN}${BOLD}=================================${NC}"
    echo -e "${CYAN}${BOLD}Operating System:${NC} $(uname -s) $(uname -r)"
    echo -e "${CYAN}${BOLD}User:${NC} $(whoami)"
    echo -e "${CYAN}${BOLD}Date:${NC} $(date)"
    echo -e "${GREEN}${BOLD}=================================${NC}"
    echo -e "1. ${BOLD}System Information${NC}"
    echo -e "2. ${BOLD}Analyze Disk Usage${NC}"
    echo -e "3. ${BOLD}Clean User Cache${NC}"
    echo -e "4. ${BOLD}Clean Temporary Files${NC}"
    echo -e "5. ${BOLD}Clean Trash/Recycle Bin${NC}"
    echo -e "6. ${BOLD}Clean Logs${NC}"
    echo -e "7. ${BOLD}Wi-Fi Diagnostics${NC}"
    
    # Show macOS-specific options
    if [ "$(uname)" = "Darwin" ]; then
        echo -e "8. ${BOLD}Clean Time Machine Snapshots${NC}"
    fi
    
    echo -e "0. ${BOLD}Exit${NC}"
    echo -e "${GREEN}${BOLD}=================================${NC}"
    echo -e "Enter your choice: "
}

# Set up trap to handle script interruption
trap "echo -e '\n${MAGENTA}${BOLD}🛑 Script interrupted${NC}'; exit 1" SIGINT SIGTERM

# Welcome message and main function
main() {
    clear
    echo -e "${GREEN}${BOLD}=================================================${NC}"
    echo -e "${GREEN}${BOLD}        WELCOME TO SYSTEM CLEANUP UTILITY        ${NC}"
    echo -e "${GREEN}${BOLD}=================================================${NC}"
    echo -e "${BLUE}${BOLD}This utility helps clean temporary files and cache${NC}"
    echo -e "${BLUE}${BOLD}directories on both Linux and macOS systems.      ${NC}"
    echo -e "${GREEN}${BOLD}=================================================${NC}"
    echo
    
    # Record script start
    log_operation "Script started by user $(whoami)"
    
    # Check for sudo
    check_sudo
    
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
            7) scan_wifi ;;
            8) 
                if [ "$(uname)" = "Darwin" ]; then
                    clean_time_machine_snapshots
                else
                    echo -e "${RED}${BOLD}Invalid option${NC}"
                    sleep 1
                fi
                ;;
            0) 
                echo -e "${GREEN}${BOLD}Thank you for using System Cleanup Utility!${NC}"
                log_operation "Script terminated normally by user"
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
main
