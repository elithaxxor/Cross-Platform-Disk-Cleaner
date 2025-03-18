cat << 'EOF' > cleanup_extended.sh
#!/bin/bash

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'      # No Color

# Function: Check Disk Usage
function show_disk_usage() {
    # Display available space on /dev/disk1 (adjust as needed)
    local space
    space=$(df -h | grep /dev/disk1 | awk '{print $4}')
    echo -e "${GREEN}[+] Disk available space: ${space}${NC}"
}

# Function: Remove Unused Applications
function cleanup_apps() {
    echo -e "${GREEN}[+] Removing unused applications...${NC}"
    # Replace "UnusedApp" with your actual app name(s) if needed.
    sudo rm -rf /Applications/UnusedApp.app
    echo -e "${YELLOW}[!] Unused applications removed.${NC}"
}

# Function: Delete Old iOS Backups
function cleanup_ios_backups() {
    echo -e "${GREEN}[+] Deleting old iOS backups...${NC}"
    rm -rf ~/Library/Application\ Support/MobileSync/Backup/*
    echo -e "${YELLOW}[!] Old iOS backups deleted.${NC}"
}

# Function: Clean Up Mail Attachments
function cleanup_mail_attachments() {
    echo -e "${GREEN}[+] Cleaning up mail attachments...${NC}"
    rm -rf ~/Library/Mail/
    echo -e "${YELLOW}[!] Mail attachments cleaned up.${NC}"
}

# Function: Clean All (perform every cleanup and show disk usage before and after)
function clean_all() {
    echo -e "${RED}[-] Initiating full cleanup...${NC}"
    local before after
    before=$(df -h | grep /dev/disk1 | awk '{print $4}')

    cleanup_apps
    cleanup_ios_backups
    cleanup_mail_attachments

    after=$(df -h | grep /dev/disk1 | awk '{print $4}')
    echo -e "${YELLOW}[!] Full cleanup complete. Disk usage changed: ${before} -> ${after}${NC}"
}

# Function: Display the Menu
function show_menu() {
    echo -e "${GREEN}[+] Please choose one of the following options:${NC}"
    echo "1) Remove unused applications"
    echo "2) Delete old iOS backups"
    echo "3) Clean up mail attachments"
    echo "4) Clean All"
    echo "5) Check disk usage"
    echo "6) Exit"
}

# Main loop for invitation
while true; do
    echo ""
    show_menu
    read -rp "[+] Enter your choice: " choice
    echo ""
    case $choice in
        1)
            cleanup_apps
            ;;
        2)
            cleanup_ios_backups
            ;;
        3)
            cleanup_mail_attachments
            ;;
        4)
            clean_all
            ;;
        5)
            show_disk_usage
            ;;
        6)
            echo -e "${RED}[-] Exiting... Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Invalid option. Please try again.${NC}"
            ;;
    esac
done
EOF
