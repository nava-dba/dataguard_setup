#!/bin/bash

export ORACLE_SID={{ databases.primary.db_sid }}
export ORACLE_HOME={{ databases.primary.oracle_db_home }}
export PATH={{ databases.primary.oracle_db_home }}/bin:$PATH
grid_asm_flag="{{ grid_asm_flag | lower }}"

MASTER_LOG="{{ done_dir }}/primary_info.log"
FAILURE_LOG="{{ done_dir }}/primary_info_fail.log"

# Ensure log files are empty before running
> "$MASTER_LOG"
> "$FAILURE_LOG"

# Run the query to fetch DBID and control file location
sqlplus -s / as sysdba <<SQL | tee -a "$MASTER_LOG"
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SET LINESIZE 1000
SET TRIMOUT ON
SET TRIMSPOOL ON

-- Fetch DBID
SELECT 'DBID:' || dbid FROM v\$database;

-- Fetch control file location
SELECT 'CONTROLFILE_LOCATION:' || name FROM v\$controlfile WHERE rownum = 1;
EXIT;
SQL

# Capture SQL*Plus exit status
sqlplus_exit_code=$?

# Check if the SQL*Plus command was successful
if [[ $sqlplus_exit_code -ne 0 ]]; then
    echo "ERROR: SQL*Plus command failed with exit status $sqlplus_exit_code. Check logs for details." | tee -a "$FAILURE_LOG"
    exit 1
fi

# Extracting values using grep and awk
DBID=$(grep "DBID:" "$MASTER_LOG" | awk -F ':' '{print $2}')
CONTROLFILE_LOCATION=$(grep "CONTROLFILE_LOCATION:" "$MASTER_LOG" | awk -F ':' '{print $2}')

if [[ -n "$DBID" ]]; then
    echo "DBID: $DBID"
    echo "$DBID" > "{{ scripts_dir }}/dbid.txt"
else 
    echo "ERROR: DBID is empty!" | tee -a "$FAILURE_LOG"
fi

# Handle and save CONTROLFILE_LOCATION based on grid_asm_flag
if [[ -n "$CONTROLFILE_LOCATION" ]]; then
    if [[ "$grid_asm_flag" == "true" ]]; then
        CONTROLFILE_LOCATION=$(echo "$CONTROLFILE_LOCATION"| sed 's:/[^/]*$::' | awk -F'/' '{if (NF > 2) { for(i=3; i<=NF; i++) printf "%s%s", $i, (i==NF ? "\n" : "/") }}')
    elif [[ "$grid_asm_flag" == "false" ]]; then
        CONTROLFILE_LOCATION=$(echo "$CONTROLFILE_LOCATION"| awk -F'/' '{for(i=4; i<NF; i++) printf "%s%s", $i, (i==NF-1 ? "\n" : "/")}')
    else 
        echo "ERROR: Invalid value for 'grid_asm_flag'. Please provide 'true' or 'false." | tee -a "$FAILURE_LOG"
    fi
    echo "CONTROLFILE_LOCATION: $CONTROLFILE_LOCATION"
    echo "$CONTROLFILE_LOCATION" > "{{ scripts_dir }}/controlfile_location.txt"
else
    echo "ERROR: CONTROLFILE_LOCATION is empty!" | tee -a "$FAILURE_LOG"
fi

# Output the values
echo "DBID: $DBID"
echo "CONTROLFILE_LOCATION: $CONTROLFILE_LOCATION"

# Save the values to a file for later use
echo "$DBID" > "{{ scripts_dir }}/dbid.txt"
echo "$CONTROLFILE_LOCATION" > "{{ scripts_dir }}/controlfile_location.txt"

# Check for failures and exit accordingly
if [[ -s "$FAILURE_LOG" ]]; then
    cat "$FAILURE_LOG"
    rm -f "$FAILURE_LOG"
    exit 1
fi

echo "DBID and control file location fetched successfully!" | tee -a "$MASTER_LOG"
rm -f "$FAILURE_LOG"
exit 0