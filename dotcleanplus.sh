#!/bin/sh

# Mac OS Artifact Cleaner Script
# Running on Linux device to clean Mac artifacts from SD card

# Configuration
TARGET_DIR="/mnt/SDCARD"
LOG_DIR="/mnt/SDCARD/App/DotCleanPlus"
LOG_FILE="$LOG_DIR/removed_log.txt"
LOCKFILE="$LOG_DIR/cleaner.lock"

# Counter variables
total_deleted=0
total_failed=0
files_deleted=0
dsstore_deleted=0
volumeicon_deleted=0
trashes_deleted=0
spotlight_deleted=0
fseventsd_deleted=0
volumeicon_failed=0
trashes_failed=0
spotlight_failed=0
fseventsd_failed=0

# Function to clean up and exit safely
cleanup_and_exit() {
    echo ""
    echo "Cleaning up..."
    # Kill any background processes
    if [ -n "$find_pid" ]; then
        kill $find_pid 2>/dev/null
        wait $find_pid 2>/dev/null
    fi
    # Remove all temp files
    rm -f "$LOG_DIR"/temp_*.tmp 2>/dev/null
    rm -f "$LOG_DIR"/counter_*.tmp 2>/dev/null
    # Remove lock file
    rm -f "$LOCKFILE" 2>/dev/null
    echo "Cleanup complete."
    exit 0
}

# Trap signals to ensure cleanup
trap cleanup_and_exit INT TERM

# Check if script is already running
if [ -f "$LOCKFILE" ]; then
    echo "ERROR: Script is already running or didn't exit cleanly."
    echo "Lock file exists: $LOCKFILE"
    echo "If you're sure no other instance is running:"
    echo "  rm '$LOCKFILE'"
    echo ""
    read -r -n 1 -s -p "--- Press any key to exit ---"
    echo ""
    exit 1
fi

# Create lock file
echo $$ > "$LOCKFILE"

# Ensure log directory exists
mkdir -p "$LOG_DIR" 2>/dev/null

# Clean up any old temp files first
echo "Cleaning up old temp files..."
rm -f "$LOG_DIR"/temp_*.tmp 2>/dev/null
rm -f "$LOG_DIR"/counter_*.tmp 2>/dev/null

# --- Main program ---
echo "Mac OS Artifact Cleaner"
echo "========================"
echo "Target directory: $TARGET_DIR"
echo "Running on: $(uname -s) $(uname -m)"
echo ""
echo "Scanning and cleaning Mac OS artifacts..."
echo ""

# Clean ._ files with spinner
printf "Cleaning ._ files...\n"
printf "Searching for ._ files... "
spin_chars="/-\\|"
spin_i=0

# Start find in background
find "$TARGET_DIR" -name "._*" -type f -exec rm -f {} \; 2>/dev/null | wc -l > "$LOG_DIR/counter_underscore.tmp" &
find_pid=$!

# Show spinner while find is running
while kill -0 $find_pid 2>/dev/null; do
    spin_char=$(printf "%s" "$spin_chars" | cut -c$((spin_i + 1)))
    printf "\rSearching for ._ files... %s" "$spin_char"
    spin_i=$(((spin_i + 1) % 4))
    sleep 0.3
done

# Wait for completion
wait $find_pid
find_pid=""

# Read final count
if [ -f "$LOG_DIR/counter_underscore.tmp" ]; then
    files_deleted=$(cat "$LOG_DIR/counter_underscore.tmp" 2>/dev/null || echo 0)
    rm -f "$LOG_DIR/counter_underscore.tmp"
else
    files_deleted=0
fi

printf "\r                                    \r"
if [ "$files_deleted" -eq 0 ]; then
    printf "[    0 deleted]  ._ files... [none found]\n"
else
    printf "[%4d deleted]  ._ files complete\n" "$files_deleted"
fi
sleep 1

# Clean .DS_Store files with spinner  
printf "Searching for .DS_Store files... "
spin_chars="/-\\|"
spin_i=0

# Start find in background
find "$TARGET_DIR" -name ".DS_Store" -type f -exec rm -f {} \; 2>/dev/null | wc -l > "$LOG_DIR/counter_dsstore.tmp" &
find_pid=$!

# Show spinner while find is running
while kill -0 $find_pid 2>/dev/null; do
    spin_char=$(printf "%s" "$spin_chars" | cut -c$((spin_i + 1)))
    printf "\rSearching for .DS_Store files... %s" "$spin_char"
    spin_i=$(((spin_i + 1) % 4))
    sleep 0.3
done

# Wait for completion
wait $find_pid
find_pid=""

# Read final count
if [ -f "$LOG_DIR/counter_dsstore.tmp" ]; then
    dsstore_deleted=$(cat "$LOG_DIR/counter_dsstore.tmp" 2>/dev/null || echo 0)
    rm -f "$LOG_DIR/counter_dsstore.tmp"
else
    dsstore_deleted=0
fi

printf "\r                                      \r"
if [ "$dsstore_deleted" -eq 0 ]; then
    printf "[    0 deleted]  .DS_Store files... [none found]\n"
else
    printf "[%4d deleted]  .DS_Store files complete\n" "$dsstore_deleted"
fi
sleep 1

# Clean .VolumeIcon.icns file (only in root)
printf "Cleaning .VolumeIcon.icns file...\n"
volumeicon_deleted=0
volumeicon_failed=0
if [ -f "$TARGET_DIR/.VolumeIcon.icns" ]; then
    printf "  Found: %s\n" "$TARGET_DIR/.VolumeIcon.icns"
    printf "  Changing permissions..."
    chmod 755 "$TARGET_DIR/.VolumeIcon.icns" 2>/dev/null && printf " SUCCESS\n" || printf " FAILED\n"
    printf "  Deleting: %s\n" "$TARGET_DIR/.VolumeIcon.icns"
    if rm -f "$TARGET_DIR/.VolumeIcon.icns" 2>/dev/null; then
        volumeicon_deleted=1
        printf "  DELETION: SUCCESS\n"
    else
        volumeicon_failed=1
        printf "  DELETION: FAILED\n"
    fi
else
    printf "  No .VolumeIcon.icns file found\n"
fi

if [ "$volumeicon_deleted" -eq 0 ] && [ "$volumeicon_failed" -eq 0 ]; then
    printf "[    0 deleted]  .VolumeIcon.icns file... [none found]\n"
elif [ "$volumeicon_deleted" -gt 0 ]; then
    printf "[%4d deleted]  .VolumeIcon.icns file complete\n" "$volumeicon_deleted"
else
    printf "[%4d failed]   .VolumeIcon.icns file deletion failed\n" "$volumeicon_failed"
fi
sleep 1

# Clean .Trashes directories (only in root)
printf "Cleaning .Trashes directories...\n"
trashes_deleted=0
for trash_dir in "$TARGET_DIR"/.Trashes; do
    if [ -d "$trash_dir" ]; then
        printf "  Found: %s\n" "$trash_dir"
        printf "  Changing permissions..."
        chmod -R 755 "$trash_dir" 2>/dev/null
        if [ $? -eq 0 ]; then
            printf " SUCCESS\n"
        else
            printf " FAILED\n"
        fi
        printf "  Deleting: %s\n" "$trash_dir"
        rm -rf "$trash_dir" 2>/dev/null
        if [ $? -eq 0 ]; then
            trashes_deleted=$((trashes_deleted + 1))
            printf "  DELETION: SUCCESS\n"
        else
            printf "  DELETION: FAILED\n"
        fi
    fi
done

if [ "$trashes_deleted" -eq 0 ]; then
    printf "[    0 deleted]  .Trashes directories... [none found]\n"
else
    printf "[%4d deleted]  .Trashes directories complete\n" "$trashes_deleted"
fi
sleep 1

# Clean .Spotlight-V100 directories (only in root) - WITH SUDO
printf "Cleaning .Spotlight-V100 directories...\n"
spotlight_deleted=0
spotlight_failed=0
if [ -d "$TARGET_DIR/.Spotlight-V100" ]; then
    printf "  Found: %s\n" "$TARGET_DIR/.Spotlight-V100"
    
    # Show current permissions
    ls -ld "$TARGET_DIR/.Spotlight-V100" 2>/dev/null || printf "  Cannot stat directory\n"
    
    printf "  Changing permissions..."
    chmod -R 755 "$TARGET_DIR/.Spotlight-V100" 2>/dev/null && printf " SUCCESS\n" || printf " FAILED\n"
    
    printf "  Attempting normal deletion...\n"
    if rm -rf "$TARGET_DIR/.Spotlight-V100" 2>/dev/null; then
        spotlight_deleted=1
        printf "  DELETION: SUCCESS\n"
    else
        printf "  Normal deletion failed, trying with sudo...\n"
        if sudo rm -rf "$TARGET_DIR/.Spotlight-V100" 2>/dev/null; then
            spotlight_deleted=1
            printf "  SUDO DELETION: SUCCESS\n"
        else
            spotlight_failed=1
            printf "  SUDO DELETION: FAILED - directory is protected\n"
        fi
    fi
else
    printf "  No .Spotlight-V100 directory found\n"
fi

if [ "$spotlight_deleted" -eq 0 ]; then
    printf "[    0 deleted]  .Spotlight-V100 directories... [none found]\n"
else
    printf "[%4d deleted]  .Spotlight-V100 directories complete\n" "$spotlight_deleted"
fi
sleep 1

# Clean .fseventsd directories (only in root) - WITH SUDO
printf "Cleaning .fseventsd directories...\n"
fseventsd_deleted=0
fseventsd_failed=0
if [ -d "$TARGET_DIR/.fseventsd" ]; then
    printf "  Found: %s\n" "$TARGET_DIR/.fseventsd"
    
    # Show current permissions
    ls -ld "$TARGET_DIR/.fseventsd" 2>/dev/null || printf "  Cannot stat directory\n"
    
    printf "  Changing permissions..."
    chmod -R 755 "$TARGET_DIR/.fseventsd" 2>/dev/null && printf " SUCCESS\n" || printf " FAILED\n"
    
    printf "  Attempting normal deletion...\n"
    if rm -rf "$TARGET_DIR/.fseventsd" 2>/dev/null; then
        fseventsd_deleted=1
        printf "  DELETION: SUCCESS\n"
    else
        printf "  Normal deletion failed, trying with sudo...\n"
        if sudo rm -rf "$TARGET_DIR/.fseventsd" 2>/dev/null; then
            fseventsd_deleted=1
            printf "  SUDO DELETION: SUCCESS\n"
        else
            fseventsd_failed=1
            printf "  SUDO DELETION: FAILED - directory is protected\n"
        fi
    fi
else
    printf "  No .fseventsd directory found\n"
fi

if [ "$fseventsd_deleted" -eq 0 ]; then
    printf "[    0 deleted]  .fseventsd directories... [none found]\n"
else
    printf "[%4d deleted]  .fseventsd directories complete\n" "$fseventsd_deleted"
fi

# Calculate totals
total_deleted=$((files_deleted + dsstore_deleted + volumeicon_deleted + trashes_deleted + spotlight_deleted + fseventsd_deleted))
total_failed=$((volumeicon_failed + trashes_failed + spotlight_failed + fseventsd_failed))
total_found=$((total_deleted + total_failed))

echo ""
if [ "$total_found" -eq 0 ]; then
    echo "No Mac OS artifacts found."
else
    # Always write session log when items were found
    {
        echo ""
        echo "========================================"
        echo "Cleaning Session: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "========================================"
        echo "Files processed:"
        printf "  [%-4d]  ._ files (deleted)\n"              "$files_deleted"
        printf "  [%-4d]  .DS_Store files (deleted)\n"       "$dsstore_deleted"
        printf "  [%-4d]  .VolumeIcon.icns file (deleted)\n" "$volumeicon_deleted"
        printf "  [%-4d]  .Trashes directories (deleted)\n"  "$trashes_deleted"
        printf "  [%-4d]  .Spotlight-V100 dirs (deleted)\n"  "$spotlight_deleted"
        printf "  [%-4d]  .fseventsd directories (deleted)\n" "$fseventsd_deleted"
        if [ "$total_failed" -gt 0 ]; then
            echo "----------------------------------------"
            echo "Failed deletions:"
            if [ "$volumeicon_failed" -gt 0 ]; then
                printf "  [%-4d]  .VolumeIcon.icns file (failed)\n" "$volumeicon_failed"
            fi
            if [ "$trashes_failed" -gt 0 ]; then
                printf "  [%-4d]  .Trashes directories (failed)\n" "$trashes_failed"
            fi
            if [ "$spotlight_failed" -gt 0 ]; then
                printf "  [%-4d]  .Spotlight-V100 dirs (failed)\n" "$spotlight_failed"
            fi
            if [ "$fseventsd_failed" -gt 0 ]; then
                printf "  [%-4d]  .fseventsd directories (failed)\n" "$fseventsd_failed"
            fi
        fi
        echo "----------------------------------------"
        printf "Total artifacts deleted: %-4d\n" "$total_deleted"
        printf "Total artifacts failed:  %-4d\n" "$total_failed"
        printf "Total artifacts found:   %-4d\n" "$total_found"
    } >> "$LOG_FILE"

    # Show summary
    echo "Cleaning completed!"
    echo "==================="
    echo "Summary:"
    printf "  [%-4d]  ._ files (deleted)\n"              "$files_deleted"
    printf "  [%-4d]  .DS_Store files (deleted)\n"       "$dsstore_deleted"
    printf "  [%-4d]  .VolumeIcon.icns file (deleted)\n" "$volumeicon_deleted"
    printf "  [%-4d]  .Trashes directories (deleted)\n"  "$trashes_deleted"
    printf "  [%-4d]  .Spotlight-V100 dirs (deleted)\n"  "$spotlight_deleted"
    printf "  [%-4d]  .fseventsd directories (deleted)\n" "$fseventsd_deleted"
    if [ "$total_failed" -gt 0 ]; then
        echo ""
        echo "Failed to delete:"
        if [ "$volumeicon_failed" -gt 0 ]; then
            printf "  [%-4d]  .VolumeIcon.icns file\n" "$volumeicon_failed"
        fi
        if [ "$trashes_failed" -gt 0 ]; then
            printf "  [%-4d]  .Trashes directories\n" "$trashes_failed"
        fi
        if [ "$spotlight_failed" -gt 0 ]; then
            printf "  [%-4d]  .Spotlight-V100 directories\n" "$spotlight_failed"
        fi
        if [ "$fseventsd_failed" -gt 0 ]; then
            printf "  [%-4d]  .fseventsd directories\n" "$fseventsd_failed"
        fi
    fi
    echo ""
    printf "Total deleted: %-4d, Failed: %-4d, Found: %-4d\n" "$total_deleted" "$total_failed" "$total_found"
    echo "Log saved to: $LOG_FILE"
fi

echo ""
echo "Script completed normally."

# Manual cleanup instead of relying on trap that might be causing issues
rm -f "$LOG_DIR"/temp_*.tmp 2>/dev/null
rm -f "$LOG_DIR"/counter_*.tmp 2>/dev/null
rm -f "$LOCKFILE" 2>/dev/null

echo "Cleanup completed."

# Pause to let user stop pressing keys and see the completion message
echo "Waiting 5 seconds before exit prompt..."
sleep 5

# Wait for keypress before exit - this is the ONLY exit point
read -r -n 1 -s -p "--- Press any key to exit ---"
echo ""
echo "Exiting..."
exit 0