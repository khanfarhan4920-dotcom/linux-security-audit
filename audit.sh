#!/bin/bash

REPORT_DIR="reports"
REPORT_FILE="$REPORT_DIR/audit_report.txt"

mkdir -p "$REPORT_DIR"

exec > >(tee "$REPORT_FILE") 2>&1#!/bin/bash

echo "===================================="
echo "     LINUX SECURITY AUDIT TOOL      "
echo "===================================="


echo
echo "[+] Starting security audit..."

echo
echo "[+] System Information"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Current User: $(whoami)"
echo
echo "[+] User & Account Security"

echo
echo "Logged-in Users:"
who

echo
echo "Total User Accounts:"
awk -F: '{print $1}' /etc/passwd | wc -l

echo
echo "UID 0 Accounts:"
awk -F: '$3 == 0 {print $1}' /etc/passwd

echo
echo "Users With Login Shells:"
awk -F: '$7 ~ /(bash|sh|zsh)$/ {print $1 " -> " $7}' /etc/passwd

echo
echo "Recent Logins:"

if command -v last >/dev/null 2>&1; then
    last -n 5 2>/dev/null || echo "Login history unavailable on this WSL system."
else
    echo "The 'last' command is not available."
fi


echo
echo "[+] File Permission Security"

WORLD_WRITABLE=$(find /tmp -type f -perm -002 -ls 2>/dev/null)

if [ -z "$WORLD_WRITABLE" ]; then
    echo "World-Writable Files: None found"
    echo "Permission Status: OK"
else
    echo "World-Writable Files Detected:"
    echo "$WORLD_WRITABLE"
    echo "Permission Status: REVIEW REQUIRED"
fi

echo
echo "[+] Process Security"

echo
echo "Total Running Processes:"
ps aux --no-heading | wc -l

echo
echo "Top CPU-Using Processes:"
ps aux --sort=-%cpu | head -n 6

echo
echo "Top Memory-Using Processes:"
ps aux --sort=-%mem | head -n 6


echo
echo "[+] Network Security"

echo
echo "Listening TCP/UDP Ports:"
ss -tuln

echo
echo "Active Network Connections:"
ss -tun

echo
echo "Listening Services With Processes:"
ss -tulnp


echo
echo "[+] SSH Security"

echo
echo "SSH Client:"
if command -v ssh >/dev/null 2>&1; then
    echo "SSH client installed: YES"
    ssh -V 2>&1
else
    echo "SSH client installed: NO"
fi

echo
echo "SSH Server:"
if command -v sshd >/dev/null 2>&1; then
    echo "SSH server installed: YES"
else
    echo "SSH server installed: NO"
fi

echo
echo "SSH Port 22:"
if ss -tln | grep -q ':22 '; then
    echo "WARNING: SSH port 22 is listening"
else
    echo "SSH port 22 is not listening"
fi

echo
echo "SSH Configuration:"
if [ -f /etc/ssh/sshd_config ]; then
    echo "sshd_config found"
else
    echo "sshd_config not found"
fi

echo
echo "[+] Firewall Security"

echo
echo "Firewall Status:"

if command -v ufw >/dev/null 2>&1; then
    ufw status 2>/dev/null
else
    echo "UFW is not installed."
fi

echo
echo "Firewall Rules:"
if command -v iptables >/dev/null 2>&1; then
    sudo iptables -L -n 2>/dev/null | head -n 20
else
    echo "iptables is not available."
fi

echo
echo "[+] System Log Security"

echo
echo "System Journal:"
if command -v journalctl >/dev/null 2>&1; then
    echo "journalctl available: YES"

    echo
    echo "Recent System Errors:"
    journalctl -p 3 -n 10 --no-pager 2>/dev/null || \
        echo "Unable to read system journal."

else
    echo "journalctl is not available."
fi

echo
echo "Authentication Log:"
if [ -f /var/log/auth.log ]; then
    echo "auth.log found"
    echo
    echo "Recent Authentication Events:"
    sudo tail -n 10 /var/log/auth.log 2>/dev/null
else
    echo "auth.log not found on this system."
fi

