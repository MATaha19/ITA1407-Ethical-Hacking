#!/bin/bash
# enum_priority.sh
# Simple wrapper that runs enumeration tools and flags high-priority findings

TARGET=$1

if [ -z "$TARGET" ]; then
    echo "Usage: $0 <target-ip>"
    exit 1
fi

echo "[*] Running enum4linux against $TARGET ..."
enum4linux -a "$TARGET" > enum4linux_output.txt

echo "[*] Running smbclient share listing ..."
smbclient -L "$TARGET" -N > smb_shares.txt

echo ""
echo "===== USERNAMES FOUND ====="
grep -i "user:" enum4linux_output.txt

echo ""
echo "===== SHARES FOUND ====="
grep -i "Disk" smb_shares.txt

echo ""
echo "===== PRIORITY REPORT ====="

# Flag writable shares
if grep -qi "READ.*WRITE" smb_shares.txt; then
    echo "[HIGH] Writable share detected - possible upload/RCE path"
fi

# Flag known vulnerable Samba version
if grep -qi "Samba 3.0.20" enum4linux_output.txt; then
    echo "[CRITICAL] Samba 3.0.20 detected - vulnerable to CVE-2007-2447 (RCE)"
fi

# Flag privileged usernames
if grep -qiE "administrator|admin|backup" enum4linux_output.txt; then
    echo "[MEDIUM] Privileged/service account found - target for credential attack"
fi

echo ""
echo "[*] Full raw output saved in enum4linux_output.txt and smb_shares.txt"
