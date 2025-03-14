# space_cleaner.py
# Note: This script may require admin privileges for some cleanup tasks (e.g., /tmp, Time Machine snapshots).
import subprocess
import os
import shutil
from concurrent.futures import ThreadPoolExecutor

def clear_directory(directory, description):
    """Delete contents of a directory."""
    try:
        for item in os.listdir(directory):
            item_path = os.path.join(directory, item)
            if os.path.isfile(item_path):
                os.remove(item_path)
            elif os.path.isdir(item_path):
                shutil.rmtree(item_path, ignore_errors=True)  # Ignore permission errors
        print(f"Cleared {description}.")
    except PermissionError:
        print(f"Permission denied for some files in {description}. Run with sudo if needed.")
    except Exception as e:
        print(f"Error clearing {description}: {e}")

def get_directory_size(directory):
    """Calculate total size of a directory in MB."""
    if not os.path.exists(directory):
        return 0
    try:
        return sum(os.path.getsize(os.path.join(dirpath, filename)) for dirpath, _, filenames in os.walk(directory) for filename in filenames) / (1024 * 1024)
    except PermissionError:
        return 0  # Skip if no access

def clear_time_machine_snapshots():
    """List and delete Time Machine local snapshots if user agrees."""
    try:
        result = subprocess.run(['tmutil', 'listlocalsnapshots', '/'], capture_output=True, text=True, check=True)
        snapshots = [line for line in result.stdout.splitlines() if line.startswith('com.apple.TimeMachine')]
        if not snapshots:
            print("No Time Machine snapshots found.")
            return
        print(f"Found {len(snapshots)} Time Machine snapshots.")
        choice = input("Delete all local Time Machine snapshots? (yes/no): ").strip().lower()
        if choice == 'yes':
            for snapshot in snapshots:
                snapshot_name = snapshot.split('.')[-1]
                subprocess.run(['sudo', 'tmutil', 'deletelocalsnapshots', snapshot_name], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                print(f"Deleted snapshot: {snapshot_name}")
            print("All snapshots cleared.")
    except subprocess.CalledProcessError as e:
        print(f"Error managing snapshots: {e}. May need sudo privileges.")
    except FileNotFoundError:
        print("Error: 'tmutil' not found. Time Machine tools missing.")

def main():
    cleanup_choice = input("Would you like to clear System Data to free up space? (yes/no): ").strip().lower()
    if cleanup_choice == 'yes':
        print("Scanning System Data for cleanup options...")
        # Define directories to clear
        cleanup_dirs = [
            (os.path.expanduser('~/Library/Caches'), "user cache"),
            (os.path.expanduser('~/Library/Logs'), "user logs"),
            ('/tmp', "temporary files")
        ]

        # Show sizes and get approval
        dirs_to_clear = []
        total_size = 0
        for dir_path, desc in cleanup_dirs:
            size = get_directory_size(dir_path)
            if size > 0:
                print(f"Found {size:.2f} MB in {desc} ({dir_path})")
                total_size += size
            else:
                print(f"No accessible data in {desc} ({dir_path})")

        if total_size > 0:
            choice = input(f"Total {total_size:.2f} MB found. Clear all? (yes/no): ").strip().lower()
            if choice == 'yes':
                with ThreadPoolExecutor(max_workers=6) as executor:
                    executor.map(lambda x: clear_directory(x[0], x[1]), cleanup_dirs)
                print("Directory cleanup completed.")
            else:
                print("Directory cleanup skipped.")
        else:
            print("No cleanup needed.")

        # Clear Time Machine snapshots (sequential)
        clear_time_machine_snapshots()
    else:
        print("Cleanup skipped.")

if __name__ == "__main__":
    main()
