#!/bin/bash

# Function to safely delete files and log the actions
delete_files() {
    local dir="$1"
    if [ -d "$dir" ]; then
        for file in "$dir"/*; do
            # Check if the file exists (in case the directory is empty)
            if [ -e "$file" ]; then
                # Check if the file is sensitive (you can add more sensitive files as needed)
                if [[ "$file" == *".plist" || "$file" == *".app" || "$file" == *"System" || "$file" == *"Library" ]]; then
                    echo "[-] Not deleting sensitive file: $file"
                else
                    echo "[+] Deleting: $file"
                    rm -rf "$file" && echo "Deleted: $file" >> deleted_files.log
                fi
            fi
        done
    else
        echo "[-] $dir does not exist"
    fi
}

echo "System and User Temporary Locations on macOS:"
echo "==========================================="
du -sh /private/var/log/ /private/var/tmp/ /tmp/ ~/Library/Logs/ ~/Library/Caches/ ~/.Trash/ 2>/dev/null
echo "\nTop 15 largest directories in ~/Library/Caches/:"
du -sh ~/Library/Caches/* 2>/dev/null | sort -rh | head -n 15
echo "\nTop 15 largest directories in ~/Library/Logs/:"
du -sh ~/Library/Logs/* 2>/dev/null | sort -rh | head -n 15

# Delete files in specified directories
delete_files ~/Library/Caches
delete_files ~/Library/Logs
delete_files ~/.Trash
sudo tmutil deletelocalsnapshots YYYY-MM-DD-HHMMSS
# Optionally, you can add more directories to clean up
delete_files /private/var/tmp
delete_files /tmp

echo "Cleanup complete. Deleted files logged in deleted_files.log."
