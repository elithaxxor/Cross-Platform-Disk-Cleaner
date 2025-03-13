#!/bin/bash

# Log file for deleted files
LOGFILE="$HOME/deleted_files.log"
echo "Deleted files will be logged to: $LOGFILE"
sudo tmutil deletelocalsnapshots YYYY-MM-DD-HHMMSS
# Display disk usage info
echo "System and User Temporary Locations on macOS:"
echo "==========================================="
du -sh /private/var/log/ /private/var/tmp/ /tmp/ ~/Library/Logs/ ~/Library/Caches/ ~/.Trash/ 2>/dev/null

echo -e "\nTop 15 largest directories in ~/Library/Caches/:"
du -sh ~/Library/Caches/* 2>/dev/null | sort -rh | head -n 15

echo -e "\nTop 15 largest directories in ~/Library/Logs/:"
du -sh ~/Library/Logs/* 2>/dev/null | sort -rh | head -n 15

# List of directories allowed for deletion (non-darwin sensitive)
# Only directories within the user's home and /tmp are included.
allowed_dirs=( "$HOME/Library/Logs" "$HOME/Library/Caches" "$HOME/.Trash" "/tmp" )

echo -e "\nDeleting allowed directories' contents..."

# Process each allowed directory
for dir in "${allowed_dirs[@]}"; do
  if [ -d "$dir" ]; then
    if [ -w "$dir" ]; then
      echo "[+] Processing deletion for: $dir"
      
      # Log all files (recursively) that are going to be deleted
      # (Appending a header for clarity.)
      echo "===== Deleting files from $dir on $(date) =====" >> "$LOGFILE"
      find "$dir" -type f >> "$LOGFILE"
      
      # Delete the contents inside the directory (but not the directory itself)
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