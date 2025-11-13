#!/bin/bash

TIMESTAMP=$(date +%F_%T)
LOG_FILE="/var/log/auth.log"
REPORT="/home/admin/ssh_audit_report_$TIMESTAMP.txt"

echo "SSH Audit Report - $TIMESTAMP" > "$REPORT"
echo " ----------------------------" >> "$REPORT"

# Successful logins
echo "Successful Logins:" >> "$REPORT"
grep "Accepted publickey" "$LOG_FILE" >> "$REPORT"

echo " " >> "$REPORT"

# Failed logins
echo "Failed Logins:" >> "$REPORT"
grep "Failed password" "$LOG_FILE" >> "$REPORT"

echo "Report saved to $REPORT"
