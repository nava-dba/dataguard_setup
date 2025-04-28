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

    # Get the directory's permission in octal format
    dir_perm=$(stat -c "%a" "$dir_to_check")

    # Check if the directory has read and write permissions
    if [ "$dir_perm" -eq 755 ]; then
        echo "Directory has read and write permissions" | tee -a "$MASTER_LOG"
    else
        echo "Directory permissions are not correct . Current permissions: $dir_perm . Please refer readme prerequisites section for more details" | tee -a "$FAILURE_LOG"
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