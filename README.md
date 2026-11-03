# Born2beroot

[![CI](https://github.com/HexCyb/Born2beroot/actions/workflows/ci.yml/badge.svg)](https://github.com/HexCyb/Born2beroot/actions/workflows/ci.yml)

A secure Debian server set up by hand in a virtual machine: encrypted LVM partitions, strict sudo and password rules, a firewall, SSH on a custom port and a monitoring script that cron runs every 10 minutes.

> Originally completed at **42 Türkiye** as part of the common core. This repository is a 2026 rewrite, because the original code was lost.
> 42 Türkiye'de tamamladığım projenin 2026'da yeniden yazılmış hali; orijinal kod kayboldu.

## What is in this repository

| File | Goes to | Purpose |
|---|---|---|
| `monitoring.sh` | `/usr/local/bin/monitoring.sh` | System summary broadcast with `wall` |
| `config/sudo_config` | `/etc/sudoers.d/sudo_config` | sudo rules: 3 tries, custom message, full logging, TTY, safe PATH |
| `config/pwquality.conf` | `/etc/security/pwquality.conf` | Password strength rules |
| `config/login.defs` | `/etc/login.defs` (3 lines) | Password expiry: 30 / 2 / 7 days |
| `config/crontab` | root's crontab | Runs the script every 10 minutes |

`signature.txt` (the SHA-1 of the virtual disk) belongs to one specific VM, so it is not included.

## Setup, step by step

**1. Install.** Install the latest stable Debian (netinst image, no graphical interface) in VirtualBox. Use the hostname `<login>42`. Choose guided partitioning with **encrypted LVM**: `/boot` stays outside, while root, swap and home are logical volumes inside an encrypted partition.

**2. sudo and groups**
```sh
su -
apt install sudo
groupadd user42
usermod -aG sudo,user42 <login>
mkdir -p /var/log/sudo
cp config/sudo_config /etc/sudoers.d/sudo_config && chmod 440 /etc/sudoers.d/sudo_config
```

**3. Password policy**
```sh
apt install libpam-pwquality
cp config/pwquality.conf /etc/security/pwquality.conf
# set PASS_MAX_DAYS 30, PASS_MIN_DAYS 2, PASS_WARN_AGE 7 in /etc/login.defs, then for existing users:
chage -M 30 -m 2 -W 7 <login> && chage -M 30 -m 2 -W 7 root
passwd <login> && passwd root          # new passwords that follow the rules
```

**4. SSH on port 4242, root login off**
```sh
apt install openssh-server
# /etc/ssh/sshd_config:  Port 4242   and   PermitRootLogin no
systemctl restart ssh
```
In VirtualBox, forward a host port to guest port 4242, then connect with `ssh <login>@localhost -p <host port>`.

**5. Firewall: only 4242 open**
```sh
apt install ufw
ufw default deny incoming && ufw allow 4242 && ufw enable
```

**6. Monitoring every 10 minutes**
```sh
apt install net-tools sysstat
cp monitoring.sh /usr/local/bin/ && chmod 755 /usr/local/bin/monitoring.sh
crontab -u root -e        # add: */10 * * * * /usr/local/bin/monitoring.sh
```

AppArmor is active on Debian by default. Check it with `aa-status`.

## Sample output

```
#Architecture: Linux login42 6.1.0-28-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.119-1 x86_64 GNU/Linux
#CPU physical : 1
#vCPU : 1
#Memory Usage: 158/987MB (16.01%)
#Disk Usage: 1009/8Gb (13%)
#CPU load: 0.5%
#Last boot: 2026-11-02 14:21
#LVM use: yes
#Connections TCP : 1 ESTABLISHED
#User log: 1
#Network: IP 10.0.2.15 (08:00:27:51:9b:a5)
#Sudo : 42 cmd
```

## Evaluation cheat sheet

| Check | Command |
|---|---|
| No graphical interface | `ls /usr/bin/*session` (nothing found) |
| Encrypted LVM partitions | `lsblk` |
| Hostname, and how to change it | `hostnamectl`, then `hostnamectl set-hostname new42` |
| User groups / new group | `groups <login>`, `groupadd evaluating`, `usermod -aG evaluating <user>` |
| Password rules | `chage -l <login>`, `cat /etc/security/pwquality.conf` |
| sudo rules and logs | `sudo cat /etc/sudoers.d/sudo_config`, `sudo ls /var/log/sudo` |
| Firewall | `sudo ufw status numbered`, then `sudo ufw allow 8080` / `sudo ufw delete <n>` |
| SSH | `sudo systemctl status ssh`, `grep -E '^(Port\|PermitRootLogin)' /etc/ssh/sshd_config` |
| AppArmor | `sudo aa-status` |
| Stop the script without editing it | `sudo systemctl stop cron` (or remove the crontab line) |

## Continuous integration

Every push runs [GitHub Actions](https://github.com/HexCyb/Born2beroot/actions/workflows/ci.yml) (`.github/workflows/ci.yml`):

- ShellCheck on `monitoring.sh`
- `visudo -c` parses the sudo rules
- the password policy values (30 / 2 / 7 days, `minlen = 10`, `difok = 7`, `enforce_for_root`)
- `monitoring.sh --stdout` runs on a real Linux machine and must print all 12 lines
