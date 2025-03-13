Script Explanation
	1.	Logging Setup:
	•	The script sets a log file ($HOME/deleted_files.log) to record paths of files that will be deleted.
	2.	Disk Usage Display:
	•	It prints the disk usage for a mix of system directories (like /var/log and /tmp) and user directories ($HOME/.cache and $HOME/.local/share/Trash).
	•	It then lists the top 15 largest directories in the user cache and system log directories (the latter for informational purposes only).
	3.	Allowed Directories for Deletion:
	•	The allowed_dirs array is defined to include only directories that are generally safe to clear:
	•	User cache: ~/.cache
	•	User trash: ~/.local/share/Trash
	•	The temporary folder: /tmp
	4.	Deletion Loop:
	•	For each allowed directory, the script checks if the directory exists and is writable.
	•	It logs all file paths within the directory using find before performing deletion.
	•	The contents of the directory are then removed using rm -rf "$dir"/*.
	•	The script prints “[+]” for directories it processes successfully and “[-]” for those it cannot process.

Use this script with caution and make sure to adjust the allowed directories as needed for your specific environment.