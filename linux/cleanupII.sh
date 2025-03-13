#!/bin/bash

# Function to safely delete files and log the actions
delete_files() {
    local dir="$1"
    if [ -d "$dir" ]; then
        for file in "$dir"/*; do
            # Check if the file exists (in case the directory is empty)
            if [ -e "$file" ]; then
                # Check if the file is sensitive (you can add more sensitive files as needed)
                if [[ "$file" == *".conf" || "$file" == *".log" || "$file" == *"System" || "$file" == *"root" ]]; then
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

echo "System and User Temporary Locations on Linux:"
echo "==========================================="
du -sh /var/log/ /tmp/ /var/tmp/ ~/.cache/ ~/.local/share/Trash/files 2>/dev/null
echo "\nTop 15 largest directories in ~/.cache/:"
du -sh ~/.cache/* 2>/dev/null | sort -rh | head -n 15
echo "\nTop 15 largest directories in /var/log/:"
du -sh /var/log/* 2>/dev/null | sort -rh | head -n 15

# Delete files in specified directories
delete_files /tmp
delete_files /var/tmp
delete_files ~/.cache
delete_files ~/.local/share/Trash/files

# Optionally, you can add more directories to clean up
# delete_files /var/log

echo "Cleanup complete. Deleted files logged in deleted_files.log."
```

### Explanation of the Script:

1. **Function Definition**:
   - The `delete_files` function takes a directory as an argument and checks if it exists. If it does, it iterates over all files in that directory.

2. **Sensitive File Check**:
   - The script checks if the file is sensitive and should not be deleted. In this example, it avoids deleting files with `.conf` and `.log` extensions, as well as files containing "System" or "root" in their names. You can modify this list based on your requirements.

3. **Logging Deleted Files**:
   - If a file is deleted, its path is logged to a file named `deleted_files.log`.

4. **Output Indication**:
   - The script echoes `[+]` for deleted files and `[-]` for files that are not deleted (either because they are sensitive or the directory does not exist).

5. **Cleanup Calls**:
   - The script calls the `delete_files` function for the specified directories (`/tmp`, `/var/tmp`, `~/.cache`, and `~/.local/share/Trash/files`). You can add more directories as needed.

### Usage Instructions:

1. **Save the Script**:
   - Save the script to a file, for example, `cleanup.sh`.

2. **Make it Executable**:
   - Run the command: 
     ```bash
     chmod +x cleanup.sh
     ```

3. **Run the Script**:
   - Execute the script with:
     ```bash
     ./cleanup.sh
     ```

### Important Notes:
- **Backup Important Data**: Always ensure that you have backups of important data before running cleanup scripts, especially those that delete files.
- **Modify Sensitive File Checks**: Adjust the sensitive file checks in the script according to your specific needs and the files you want to protect from deletion.
- **Run with Caution**: Be cautious when running scripts that delete files, especially with `rm -rf`, as it can lead to data loss if misconfigured.