#!/bin/bash
# Health monitoring script. This script will triger the warning alert once the threshold is above 80%.
#Later, Scheduled in cron to keep on monitoring.

CPU_USAGE=$(vmstat 1 2 | tail -1 | awk '{ print 100-$15}')
MEM_USAGE=$(free -m | awk ' NR==2 {print $3} ')
DISK_USAGE=$(df -h / | awk 'NR==2 { print $5 }' | sed 's/%//g')

echo "CPU Usage: $CPU_USAGE%"
echo "Memory Usage: $MEM_USAGE MB"
echo "Disk Usage: $DISK_USAGE%"


if [ $CPU_USAGE -gt 80 ]; then
    echo -e "Subject: CPU Alert\n\nWarning: CPU usage is above 80%." | msmtp ajayraina473@gmail.com
fi

if [ $MEM_USAGE -gt 1024 ]; then
    echo -e "Subject: Memory usage is above\n\nWarning: Memory usage is above 1024 MB." | msmtp ajayraina473@gmail.com
fi

if [ $DISK_USAGE -gt 80 ]; then
    echo -e "Subject: Disk usage is above\n\nWarning: Disk usage is above 80%." | msmtp ajayraina473@gmail.com
fi
