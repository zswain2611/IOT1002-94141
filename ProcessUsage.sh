#!/bin/bash

# ProcessUsage.sh
# IOT1025 – Semester Long Assignment - Part #2
# Finds top 5 CPU processes, kills non-root, logs details
# Run with: sudo ./ProcessUsage.sh
# Created: October 28, 2025

# Log goes into the home directory of the user who runs sudo
LOG_DIR="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
# Get current date for log file name
CURRENT_DATE=$(date '+%Y-%m-%d')
# Set log file name
LOG_FILE="${LOG_DIR}/ProcessUsageReport-${CURRENT_DATE}"
# Counter for killed processes
killed_count=0

# Temporary file (subshell-safe)
TMP_FILE="/tmp/top5_$$.txt"
trap 'rm -f "$TMP_FILE"' EXIT   # always clean up

# Find the top 5 processes by CPU% (skip headers, take top 5)
top_processes=$(top -b -n 1 -o %CPU | tail -n +8 | head -n 5)

# If top returns nothing exit cleanly
[[ -z "$top_processes" ]] && {
    echo "No processes found – nothing to kill."
    exit 0
}

# Show the top 5 processes to the user
echo "Top 5 processes by CPU%:"
echo "$top_processes"
echo
read -p "Kill these processes? (yes/no): " confirm
confirm="${confirm,,}"          # force lower-case
if [[ "$confirm" != "yes" && "$confirm" != "y" ]]; then
    echo "Exiting without killing any processes."
    exit 0
fi

# Save top 5 to temp file
echo "$top_processes" > "$TMP_FILE"

# Loop through each process
while IFS= read -r line; do
    # Extract PID and USER from columns
    pid=$(awk '{print $1}' <<< "$line")
    user=$(awk '{print $2}' <<< "$line")

    # Skip root processes
    [[ "$user" == "root" ]] && continue

    # Get process start time
    start_time=$(ps -p "$pid" -o lstart= 2>/dev/null || echo "Unknown")

    # Get current time when killed
    kill_time=$(date '+%Y-%m-%d %H:%M:%S')

    # Get department
    dept=$(id -gn "$user" 2>/dev/null || echo "Unknown")

    # kill with SIGKILL (signal 9)
    if kill -9 "$pid" 2>/dev/null; then
        ((killed_count++))
    else
        # If the process vanished between top and kill, just note it
        echo "Warning: PID $pid disappeared before kill."
        continue
    fi

    # Log details
    {
        echo "Username: $user"
        echo "Started:  $start_time"
        echo "Killed:   $kill_time"
        echo "Department: $dept"
        echo "---"
    } >> "$LOG_FILE"

done < "$TMP_FILE"

# Final message
echo "Killed $killed_count processes."
echo "Log saved to: $LOG_FILE"
