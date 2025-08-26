#!/bin/sh

# macOS Artifact Cleanup Script for /mnt/SDCARD/
# Device-specific version with live counter and logging

# Target directory and log file
TARGET_DIR="/mnt/SDCARD"
LOG_DIR="/mnt/SDCARD/App/DotCleanPlus"
LOG_FILE="$LOG_DIR/removed_log.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Global counter for deleted items
DELETED_COUNT=0

# Function to print colored output
print_status() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

print_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

print_warning() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

# Function to update live counter
update_counter() {
    DELETED_COUNT=$(expr $DELETED_COUNT + 1)
    printf "\r${GREEN}Files deleted: %d${NC}" "$DELETED_COUNT"
}

# Function to log removed file
log_removal() {
    filepath="$1"
    printf "%s\n" "$filepath" >> "$LOG_FILE"
}

# Function to create log directory if it doesn't exist
setup_logging() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR" 2>/dev/null
        if [ $? -ne 0 ]; then
            print_error "Failed to create log directory: $LOG_DIR"
            exit 1
        fi
    fi
    
    # Add session header to log
    printf "\n" >> "$LOG_FILE"
    printf "=== Cleanup Session: %s ===\n" "$(date)" >> "$LOG_FILE"
}

# Function to finalize log
finalize_log() {
    printf "Total files removed: %d\n" "$DELETED_COUNT" >> "$LOG_FILE"
    printf "=== End Session ===\n" >> "$LOG_FILE"
}

# Function to safely remove files/directories with logging
safe_remove_with_log() {
    target="$1"
    type="$2"
    
    if [ "$type" = "file" ] && [ -f "$target" ]; then
        if rm -f "$target" 2>/dev/null; then
            log_removal "$target"
            update_counter
        fi
    elif [ "$type" = "dir" ] && [ -d "$target" ]; then
        if rm -rf "$target" 2>/dev/null; then
            log_removal "$target"
            update_counter
        fi
    fi
}

# Function to clean specific pattern
clean_pattern() {
    pattern="$1"
    type="$2"
    description="$3"
    
    print_status "Cleaning $description..."
    
    find "$TARGET_DIR" -name "$pattern" -type "$type" 2>/dev/null | while read -r item; do
        safe_remove_with_log "$item" "$type"
    done
}

# Main cleanup function
cleanup_macos_artifacts() {
    print_status "Starting macOS artifact cleanup in: $TARGET_DIR"
    print_status "Log file: $LOG_FILE"
    
    # Setup logging
    setup_logging
    
    # Initialize counter display
    printf "${GREEN}Files deleted: 0${NC}"
    
    # Clean .DS_Store files
    clean_pattern ".DS_Store" "f" ".DS_Store files"
    
    # Clean ._* files (AppleDouble files)
    clean_pattern "._*" "f" "._* files (AppleDouble)"
    
    # Clean .Trashes directories
    clean_pattern ".Trashes" "d" ".Trashes directories"
    
    # Clean .Spotlight-V100 directories
    clean_pattern ".Spotlight-V100" "d" ".Spotlight-V100 directories"
    
    # Clean .fseventsd directories
    clean_pattern ".fseventsd" "d" ".fseventsd directories"
    
    # Final newline after counter
    printf "\n"
    
    # Finalize log
    finalize_log
    
    # Summary
    if [ $DELETED_COUNT -eq 0 ]; then
        print_success "Cleanup complete! No macOS artifacts found."
    else
        print_success "Cleanup complete! Removed $DELETED_COUNT macOS artifacts."
        print_status "Detailed log saved to: $LOG_FILE"
    fi
}

# Help function
show_help() {
    cat << EOF
macOS Artifact Cleanup Script for /mnt/SDCARD/

This script removes macOS artifacts from /mnt/SDCARD/ including all subdirectories.

USAGE:
    $(basename "$0") [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Show verbose output (default behavior)
    
FEATURES:
    - Cleans /mnt/SDCARD/ and all subdirectories (including hidden)
    - Live counter of deleted files
    - Detailed logging to $LOG_FILE
    - Each run appends to log with timestamp

CLEANED ARTIFACTS:
    - .DS_Store files
    - ._* files (AppleDouble/resource forks)
    - .Trashes directories
    - .Spotlight-V100 directories  
    - .fseventsd directories

LOG FORMAT:
    Each session creates a timestamped entry with:
    - Session start time
    - Full path of each removed file/directory
    - Total count of removed items
    - Session end marker

EOF
}

# Parse command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            # Verbose is default behavior
            shift
            ;;
        -*)
            print_error "Unknown option: $1"
            printf "Use --help for usage information\n"
            exit 1
            ;;
        *)
            print_warning "This script only cleans /mnt/SDCARD/. Ignoring argument: $1"
            shift
            ;;
    esac
done

# Check if target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    print_error "Target directory does not exist: $TARGET_DIR"
    print_error "Please ensure your SD card is mounted at /mnt/SDCARD/"
    exit 1
fi

# Check if target directory is writable
if [ ! -w "$TARGET_DIR" ]; then
    print_error "No write permission for: $TARGET_DIR"
    print_error "You may need to run this script with appropriate privileges"
    exit 1
fi

print_status "Device-specific macOS cleanup starting..."
print_status "Target: $TARGET_DIR (including all subdirectories and hidden folders)"

# Run the cleanup
cleanup_macos_artifacts

print_success "Script execution completed!"

# Wait for user input before exiting
printf "\nPress any key to exit..."
read -r dummy