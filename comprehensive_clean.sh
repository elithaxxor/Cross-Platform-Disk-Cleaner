#!/usr/bin/env bash
#
# comprehensive_cleanup.sh
#
# Displays a warning, shows system info, searches for bug markers,
# offers a menu to delete files, and logs actions.
#

########################################
#            Color Variables           #
########################################
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
WHITE='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m'  # No color / reset

########################################
#       Global Variables & Setup       #
########################################
LOGFILE="$HOME/comprehensive_cleanup_$(date +%Y%m%d_%H%M%S).log"

# Allowed directories to delete
# Customize these as per your environment.
ALLOWED_DIRS=(
  "/tmp"
  "$HOME/.cache"
  "$HOME/.Trash"      # On macOS or Linux if desired
)

########################################
#            Warning Message           #
########################################
function display_warning() {
  echo -e "${RED}${BOLD}WARNING:${NC}"
  echo -e "${RED}This script may delete files irreversibly.${NC}"
  echo -e "${RED}Data loss can occur if used improperly. Proceed at your own risk!${NC}"
  echo -e "${YELLOW}If you do not trust this script or are unsure, please exit now.${NC}"
  echo
  # Log that user saw warning
  echo "=== WARNING displayed on $(date) ===" >> "$LOGFILE"
  echo "Potential data loss if used improperly." >> "$LOGFILE"
}

########################################
#         Collect System Info          #
########################################
function show_system_info() {
  local os_type kernel hostname_str ram total_storage available_storage cpu_info gateway local_ip network_name

  os_type=$(uname -s)              # e.g. Linux or Darwin
  kernel=$(uname -r)               # Kernel release
  hostname_str=$(hostname)         # Hostname
  network_name="$hostname_str"     # Fallback in case a domain or extra detail is unavailable

  # Attempt to get a "Fully Qualified Domain Name" on Linux
  if [ "$os_type" = "Linux" ] && command -v hostname &>/dev/null; then
    fqdn=$(hostname -f 2>/dev/null)
    [ -n "$fqdn" ] && network_name="$fqdn"
  fi

  # RAM
  if [ "$os_type" = "Darwin" ]; then
    # macOS: sysctl hw.memsize reports total bytes
    ram_bytes=$(sysctl -n hw.memsize 2>/dev/null)
    if [ -n "$ram_bytes" ]; then
      ram_gb=$((ram_bytes / 1024 / 1024 / 1024))
      ram="${ram_gb} GB"
    else
      ram="N/A"
    fi
  elif [ "$os_type" = "Linux" ]; then
    # Linux: parse /proc/meminfo
    if [ -r /proc/meminfo ]; then
      ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
      ram_mb=$((ram_kb / 1024))
      ram_gb=$((ram_mb / 1024))
      ram="${ram_gb} GB"
    else
      ram="N/A"
    fi
  else
    ram="N/A"
  fi

  # Storage
  # We just check root partition
  if command -v df &>/dev/null; then
    # Use df -h to get total and available on root "/"
    total_storage=$(df -h / 2>/dev/null | awk 'NR==2 {print $2}')
    available_storage=$(df -h / 2>/dev/null | awk 'NR==2 {print $4}')
  else
    total_storage="N/A"
    available_storage="N/A"
  fi

  # CPU Info
  if [ "$os_type" = "Darwin" ]; then
    cpu_info=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "N/A")
  elif [ "$os_type" = "Linux" ]; then
    if command -v lscpu &>/dev/null; then
      cpu_info=$(lscpu | grep 'Model name' | awk -F: '{print $2}' | sed 's/^ *//')
    else
      cpu_info="N/A"
    fi
  else
    cpu_info="N/A"
  fi

  # Gateway & Local IP
  if [ "$os_type" = "Darwin" ]; then
    # Gateway
    gateway=$(route -n get default 2>/dev/null | awk '/gateway/ {print $2}')
    # Local IP
    local_ip=$(ipconfig getifaddr en0 2>/dev/null || echo "N/A")
  elif [ "$os_type" = "Linux" ]; then
    # Gateway
    gateway=$(ip route 2>/dev/null | awk '/default/ {print $3; exit}')
    # Local IP
    local_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
  else
    gateway="N/A"
    local_ip="N/A"
  fi

  echo -e "${CYAN}${BOLD}System Information:${NC}"
  echo -e "${GREEN}OS Type           :${NC} $os_type"
  echo -e "${GREEN}Kernel            :${NC} $kernel"
  echo -e "${GREEN}Hostname          :${NC} $hostname_str"
  echo -e "${GREEN}Network Name      :${NC} $network_name"
  echo -e "${GREEN}RAM               :${NC} $ram"
  echo -e "${GREEN}Storage (root)    :${NC} $total_storage total, $available_storage free"
  echo -e "${GREEN}Local IP          :${NC} $local_ip"
  echo -e "${GREEN}Gateway IP        :${NC} $gateway"
  echo -e "${GREEN}CPU               :${NC} $cpu_info"
  echo

  # Also log it
  {
    echo "=== System Information on $(date) ==="
    echo "OS            : $os_type"
    echo "Kernel        : $kernel"
    echo "Hostname      : $hostname_str"
    echo "Network Name  : $network_name"
    echo "RAM           : $ram"
    echo "Storage       : $total_storage total, $available_storage free"
    echo "Local IP      : $local_ip"
    echo "Gateway IP    : $gateway"
    echo "CPU           : $cpu_info"
    echo "======================================"
    echo
  } >> "$LOGFILE"

  # Pause 2 seconds for user to read
  sleep 2
}

########################################
#          Find "Bugs" Function        #
########################################
# Searches current directory for lines containing BUG, FIXME, or TODO
function find_bugs() {
  echo -e "${YELLOW}${BOLD}Searching for bug markers (BUG, FIXME, TODO) in current directory...${NC}"
  echo "=== Searching for bug markers on $(date) ===" >> "$LOGFILE"

  # We'll grep for these markers in all files, ignoring permission errors
  results=$(grep -rnw . -e "BUG\|FIXME\|TODO" 2>/dev/null)
  if [ -n "$results" ]; then
    echo -e "${WHITE}$results${NC}"
    echo "$results" >> "$LOGFILE"
  else
    echo -e "${GREEN}No bug markers found.${NC}"
    echo "No bug markers found." >> "$LOGFILE"
  fi
  echo
}

########################################
#         Deletion (Destructive)       #
########################################
function delete_files() {
  echo -e "${RED}${BOLD}You have chosen to delete files from certain allowed directories.${NC}"
  echo -e "These directories are: ${ALLOWED_DIRS[*]}"
  
  # Log user’s choice
  echo "=== Deletion initiated on $(date) ===" >> "$LOGFILE"

  for dir in "${ALLOWED_DIRS[@]}"; do
    # Sanity checks
    if [ -z "$dir" ] || [ "$dir" = "/" ]; then
      echo -e "${RED}[!] Skipping unsafe directory: $dir${NC}"
      continue
    fi

    if [ -d "$dir" ]; then
      if [ -w "$dir" ]; then
        echo -e "${CYAN}Deleting contents of: $dir${NC}"
        echo "Deleting contents of $dir..." >> "$LOGFILE"

        # Log all files that will be deleted
        find "$dir" -type f >> "$LOGFILE" 2>/dev/null

        # Perform deletion
        rm -rf "$dir"/* 2>/dev/null
        echo -e "${GREEN}Deleted contents of $dir${NC}"
        echo "Deleted contents of $dir" >> "$LOGFILE"
      else
        echo -e "${RED}[-] Cannot delete $dir (permission denied)${NC}"
        echo "Permission denied for $dir" >> "$LOGFILE"
      fi
    else
      echo -e "${RED}[-] Directory $dir does not exist${NC}"
      echo "Directory $dir does not exist" >> "$LOGFILE"
    fi
  done
  echo
}

########################################
#               Main Menu              #
########################################
function show_menu() {
  echo -e "${YELLOW}${BOLD}"
  echo "==============================="
  echo "         Main Menu            "
  echo "==============================="
  echo -e "${NC}"
  echo "1) Find Bug Markers (BUG, FIXME, TODO)"
  echo "2) Delete Files from Allowed Directories"
  echo "3) Exit"
  echo

  read -rp "Choose an option (1-3): " choice
  case "$choice" in
    1)
      find_bugs
      ;;
    2)
      delete_files
      ;;
    3)
      echo -e "${GREEN}[+] Exiting...${NC}"
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid choice. Exiting.${NC}"
      exit 1
      ;;
  esac
}

########################################
#                 Main                 #
########################################

# 1. Display warning
display_warning

# 2. Show system info
show_system_info

# 3. If no arguments, display menu; otherwise, skip
if [ $# -eq 0 ]; then
  show_menu
else
  echo -e "${CYAN}Arguments detected: $@${NC}"
  echo "Skipping menu because arguments were provided." >> "$LOGFILE"
  echo -e "You may run the script again without arguments to see the menu.\n"
fi

echo -e "${GREEN}[+] Script completed.${NC}"
echo "Script completed on $(date)" >> "$LOGFILE"
