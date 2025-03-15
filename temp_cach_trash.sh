#!/bin/bash
#=====================================================================
# System Cleanup Utility
# Description: A cross-platform utility to clean temporary files
# =====================================================================
# **Color Codes for Terminal Output**
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
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
    log_operation "Gathering system information..."
    echo -e "${GREEN}${BOLD}====== System Information ======${NC}"
    echo -e "OS: $(uname -s) $(uname -r)"
    echo -e "Hostname: $(hostname)"
    echo -e "User: $(whoami)"
    echo -e "Date/Time: $(date)"
    echo -e "Uptime: $(uptime)"
    echo -e "IP Address: $(if [ "$(uname)" = "Darwin" ]; then ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1; else ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1" | head -n 1; fi)"
    echo -e "Disk Space: $(df -h / | awk 'NR==2 {print "Total: " $2 ", Used: " $3 ", Free: " $4}')"
}

# **Safely Delete Files**
safe_delete() {
    local dir="$1"
    local description="$2"
    shift 2
    
    if [[ "$dir" == "/" || "$dir" == "$HOME" || "$dir" == "/home" ]]; then
        log_error "Refusing to delete critical directory: $dir"
        return 1
    fi
    
    if [ ! -d "$dir" ]; then
        log_error "Directory does not exist: $dir"
        return 1
    fi
    
    local file_count=$(find "$dir" -type f 2>/dev/null | wc -l)
    if [ "$file_count" -eq 0 ]; then
        echo -e "${YELLOW}${BOLD}Notice:${NC} No files found in $dir"
        return 0
    fi
    
    local total_size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
    
    if [ "$AUTO_CONFIRM" -eq 1 ]; then
        confirm="y"
    else
        echo -e "${YELLOW}${BOLD}Warning:${NC} About to delete $file_count files in $dir ($total_size)"
        read -p "Are you sure you want to proceed? (y/n): " confirm
    fi
    
    if [[ "$confirm" != [yY] ]]; then
        echo -e "${BLUE}${BOLD}Info:${NC} Deletion cancelled for $dir"
        log_operation "Deletion cancelled for $dir by user"
        return 0
    fi
    
    log_operation "Starting deletion of $description in $dir"
    local deleted_count=0
    
    find "$dir" -type f | while read file; do
        if [ "$DRY_RUN" -eq 1 ]; then
            echo "[DRY RUN] Would delete: $file"
            log_deletion "[DRY RUN] $file"
        else
            if rm -f "$file" 2>/dev/null; then
                echo -e "${GREEN}${BOLD}Deleted:${NC} $file"
                log_deletion "$file"
                ((deleted_count++))
            else
                log_error "Failed to delete: $file"
            fi
        fi
    done
    
    if [ "$DRY_RUN" -eq 0 ]; then
        find "$dir" -type d -empty -delete 2>/dev/null
    fi
    
    local new_size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
    echo -e "${GREEN}${BOLD}Completed cleaning $description.${NC}"
    echo -e "Directory size: Before=$total_size, After=$new_size"
    log_operation "Completed deletion in $dir. Files deleted: $deleted_count"
}

# **Analyze Disk Usage**
analyze_disk_usage() {
    log_operation "Analyzing disk usage"
    echo -e "${GREEN}${BOLD}====== Disk Usage Analysis ======${NC}"
    if [ "$(uname)" = "Darwin" ]; then
        du -sh /private/var/tmp /tmp ~/Library/Caches 2>/dev/null
    else
        du -sh /var/tmp /tmp ~/.cache 2>/dev/null
    fi
    log_operation "Disk usage analysis completed"
}

# **Clean User Cache**
clean_user_cache() {
    local cache_dir
    [ "$(uname)" = "Darwin" ] && cache_dir="$HOME/Library/Caches" || cache_dir="$HOME/.cache"
    safe_delete "$cache_dir" "user cache"
}

# **Clean Temporary Files**
clean_temp_files() {
    if [ "$(uname)" = "Darwin" ]; then
        safe_delete "/tmp" "temporary files"
        safe_delete "/private/var/tmp" "system temporary files"
    else
        safe_delete "/tmp" "temporary files"
        safe_delete "/var/tmp" "system temporary files"
    fi
}

# **Clean Trash**
clean_trash() {
    [ "$(uname)" = "Darwin" ] && safe_delete "$HOME/.Trash" "trash" || safe_delete "$HOME/.local/share/Trash/files" "trash"
}

# **Help Menu**
show_help() {
    echo -e "${GREEN}${BOLD}=================================${NC}"
    echo -e "${GREEN}${BOLD}    SYSTEM CLEANUP UTILITY      ${NC}"
    echo -e "${GREEN}${BOLD}=================================${NC}"
    echo -e "Usage: $0 [OPTIONS]"
    echo -e "Options:"
    echo -e "  --system-info       Display system information"
    echo -e "  --analyze-disk      Analyze disk usage"
    echo -e "  --clean-cache       Clean user cache"
    echo -e "  --clean-temp        Clean temporary files"
    echo -e "  --clean-trash       Clean trash/recycle bin"
    echo -e "  --dry-run           Simulate cleanup without deleting"
    echo -e "  --yes               Auto-confirm all prompts"
    echo -e "  --help              Show this help message"
    echo -e "${GREEN}${BOLD}=================================${NC}"
}

# **Main Function**
main() {
    clear
    echo -e "${GREEN}${BOLD}=================================================${NC}"
    echo -e "${GREEN}${BOLD}        WELCOME TO SYSTEM CLEANUP UTILITY        ${NC}"
    echo -e "${GREEN}${BOLD}=================================================${NC}"
    echo
    
    log_operation "Script started by user $(whoami)"
    check_sudo
    
    echo -e "${YELLOW}${BOLD}WARNING:${NC} Ensure important data is backed up before proceeding."
    read -p "Press Enter to continue or Ctrl+C to exit..."
    
    # Parse command-line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --system-info) get_system_info ;;
            --analyze-disk) analyze_disk_usage ;;
            --clean-cache) clean_user_cache ;;
            --clean-temp) clean_temp_files ;;
            --clean-trash) clean_trash ;;
            --dry-run) DRY_RUN=1 ;;
            --yes) AUTO_CONFIRM=1 ;;
            --help) show_help; exit 0 ;;
            *) echo "Error: Invalid option '$1'"; show_help; exit 1 ;;
        esac
        shift
    done
    
    # If no arguments, show help
    if [ "$#" -eq 0 ]; then
        show_help
    fi
    
    echo -e "${GREEN}${BOLD}Cleanup completed!${NC}"
    echo -e "Log saved to: ${CYAN}$CWD_LOG${NC}"
    log_operation "Script terminated normally"
}

# Start the script
main "$@"
