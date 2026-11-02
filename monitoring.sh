#!/bin/bash
# Born2beroot: a system summary broadcast to every terminal with wall.
# cron runs it every 10 minutes. `monitoring.sh --stdout` prints it instead.

arch=$(uname -a)
cpu_physical=$(grep "physical id" /proc/cpuinfo | sort -u | wc -l)
[ "$cpu_physical" -eq 0 ] && cpu_physical=1
vcpu=$(grep -c "^processor" /proc/cpuinfo)

ram_used=$(free -m | awk '/^Mem:/ {print $3}')
ram_total=$(free -m | awk '/^Mem:/ {print $2}')
ram_pct=$(free | awk '/^Mem:/ {printf "%.2f", $3 / $2 * 100}')

disk_used=$(df -BM --total -x tmpfs -x devtmpfs 2>/dev/null | awk '/^total/ {print $3 + 0}')
disk_total=$(df -BG --total -x tmpfs -x devtmpfs 2>/dev/null | awk '/^total/ {print $2 + 0}')
disk_pct=$(df --total -x tmpfs -x devtmpfs 2>/dev/null | awk '/^total/ {print $5}')

cpu_load=$(vmstat 1 2 | tail -1 | awk '{printf "%.1f%%", 100 - $15}')
last_boot=$(who -b | awk '{print $3 " " $4}')
if lsblk 2>/dev/null | grep -q "lvm"; then lvm="yes"; else lvm="no"; fi
tcp=$(ss -Ht state established 2>/dev/null | wc -l)
users_logged=$(users | wc -w)
ip_addr=$(hostname -I 2>/dev/null | awk '{print $1}')
mac=$(ip link 2>/dev/null | awk '/link\/ether/ {print $2; exit}')
sudo_cmds=$(journalctl _COMM=sudo -q 2>/dev/null | grep -c COMMAND)

message="	#Architecture: $arch
	#CPU physical : $cpu_physical
	#vCPU : $vcpu
	#Memory Usage: $ram_used/${ram_total}MB ($ram_pct%)
	#Disk Usage: $disk_used/${disk_total}Gb ($disk_pct)
	#CPU load: $cpu_load
	#Last boot: $last_boot
	#LVM use: $lvm
	#Connections TCP : $tcp ESTABLISHED
	#User log: $users_logged
	#Network: IP $ip_addr ($mac)
	#Sudo : $sudo_cmds cmd"

if [ "$1" = "--stdout" ]; then
    printf '%s\n' "$message"
else
    wall "$message"
fi
