#!/bin/bash

# Log file for deleted files
LOGFILE="$HOME/deleted_files.log"
echo "Deleted files will be logged to: $LOGFILE"

# Display disk usage information for selected directories
echo "System and User Temporary Locations on Linux:"
echo "============================================="
du -sh /var/log/ /tmp/ "$HOME/.cache/" "$HOME/.local/share/Trash/" 2>/dev/null

# List top 15 largest directories in $HOME/.cache/ (user cache)
echo -e "\nTop 15 largest directories in $HOME/.cache/:"
du -sh "$HOME/.cache/"* 2>/dev/null | sort -rh | head -n 15

# List top 15 largest directories in /var/log/ (system logs, for info only)
echo -e "\nTop 15 largest directories in /var/log/:"
du -sh /var/log/* 2>/dev/null | sort -rh | head -n 15

echo -e "\nProceeding to delete contents in allowed directories..."

# Define allowed directories for deletion (user safe-to-delete areas)
allowed_dirs=( "$HOME/.cache" "$HOME/.local/share/Trash" "/tmp" )

# Process each allowed directory
for dir in "${allowed_dirs[@]}"; do
  if [ -d "$dir" ]; then
    if [ -w "$dir" ]; then
      echo "[+] Processing deletion for: $dir"
      
      # Log all files (recursively) that are about to be deleted (with a header)
      echo "===== Deleting files from $dir on $(date) =====" >> "$LOGFILE"
      find "$dir" -type f >> "$LOGFILE"
      
      # Delete all contents inside the directory (but not the directory itself)
      rm -rf "$dir"/* 2>/dev/null
      
      # Confirm deletion
      echo "[+] Deleted contents of $dir"
    else
      echo "[-] Cannot delete $dir (permission denied)"
    fi
  else
    echo "[-] Directory $dir does not exist"
  fi
done