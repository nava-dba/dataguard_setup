#!/bin/bash


MASTER_LOG="{{ done_dir }}/dir_check.log"
FAILURE_LOG="{{ done_dir }}/dir_check_fail.log"

# Ensure log files are empty before running
> "$MASTER_LOG"
> "$FAILURE_LOG"

dir_to_check="$1"

# Check if the directory exists
if [ -d "$dir_to_check" ]; then
    echo "Directory exists." | tee -a "$MASTER_LOG"

    # Check if the directory has read and write permissions
    if [ -r "$dir_to_check" ] && [ -w "$dir_to_check" ]; then
        echo "Directory has read and write permissions." | tee -a "$MASTER_LOG"
    else
        echo "Directory does not have read and write permissions." | tee -a "$FAILURE_LOG"
    fi
else
    echo "Directory does not exist." | tee -a "$FAILURE_LOG"
fi

# Check for failures and exit accordingly
if [[ -s "$FAILURE_LOG" ]]; then
    cat "$FAILURE_LOG"
    rm -f "$FAILURE_LOG"
    exit 1
fi

echo "$ORACLE_BASE/admin have read/write permission to oracle user on standby host." | tee -a "$MASTER_LOG"
rm -f "$FAILURE_LOG"
exit 0