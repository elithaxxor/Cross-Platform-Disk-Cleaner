# System Cleanup Utility

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey.svg)

A comprehensive utility for safely cleaning temporary files and caches on both Linux and macOS systems. This tool helps reclaim disk space by removing unnecessary files while preserving system integrity.

## 🌟 Features

* **Cross-Platform Support**: Works on both Linux and macOS
* **Interactive Menu**: User-friendly interface with multiple cleaning options
* **System Information**: Displays detailed system information
* **Safety Measures**: Confirmation prompts and sensitive file protection
* **Detailed Logging**: Comprehensive logs of all actions
* **Disk Space Analysis**: Before and after cleanup reports
* **Time Machine Management**: Optional Time Machine snapshot cleanup for macOS
* **Wi-Fi Diagnostics**: View nearby Wi-Fi networks and signal strength

A comprehensive utility for safely cleaning temporary files and caches on both Linux and macOS systems. This tool helps reclaim disk space by removing unnecessary files while preserving system integrity.

## 🌟 Features

- **Cross-Platform Support**: Works on both Linux and macOS
- **Interactive Menu**: User-friendly interface with multiple cleaning options
- **System Information**: Displays detailed system information
- **Safety Measures**: Confirmation prompts and sensitive file protection
- **Detailed Logging**: Comprehensive logs of all actions
- **Disk Space Analysis**: Before and after cleanup reports
- **Time Machine Management**: Optional Time Machine snapshot cleanup for macOS
- **Wi-Fi Diagnostics**: View nearby Wi-Fi networks and signal strength
- **macOS System Data Cleanup**: Advanced tools to reclaim space from system data storage

## 📋 Requirements

- Bash shell (version 4.0+)
- Administrative privileges for some operations
- Linux or macOS operating system

## 🚀 Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/system-cleanup-utility.git

# Navigate to the directory
cd system-cleanup-utility

# Make the script executable
chmod +x cleanup.sh
```

## 💻 Usage

Simply run the script and follow the interactive menu:

```bash
./cleanup.sh
```

### Available Options

1. **System Information**: Display detailed system information
2. **Analyze Disk Usage**: Show disk usage of temporary directories
3. **Clean User Cache**: Remove user cache files
4. **Clean Temporary Files**: Remove temporary system files
5. **Clean Trash/Recycle Bin**: Empty trash/recycle bin
6. **Clean Logs**: Remove log files to free up space
7. **Wi-Fi Diagnostics**: Scan and display nearby Wi-Fi networks (requires wireless interface)
8. **Clean Time Machine Snapshots**: Remove local Time Machine snapshots (macOS only)
9. **Clean macOS System Data**: Clean up system data storage including iOS backups, XCode caches, and more (macOS only)
10. **Exit**: Exit the program

## ⚠️ Warning

This tool deletes files from your system. While it has been designed with safety in mind:

- **Always backup important data before running cleanup operations**
- Review the logs after each operation
- Use caution when cleaning system directories

## 📊 Logs

All operations are logged to:
- `~/cleanup_logs/deletions.log`: Record of deleted files
- `~/cleanup_logs/operations.log`: Record of all operations performed
- `~/cleanup_logs/errors.log`: Record of any errors encountered
- `./cleanup_[timestamp].log`: A summary log in the current working directory for easy reference

## 🔍 How It Works

The System Cleanup Utility works by:

1. Detecting your operating system (Linux or macOS)
2. Identifying safe-to-clean directories specific to your OS
3. Analyzing disk usage before cleanup
4. Safely removing unnecessary files with appropriate permissions
5. Protecting sensitive system files from deletion
6. Providing detailed logs of all actions

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgements

- Inspired by various system maintenance scripts
- Thanks to all contributors and testers
