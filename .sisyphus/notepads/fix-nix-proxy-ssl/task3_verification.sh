#!/bin/bash
# Task 3 Verification Script
# Run this AFTER executing /tmp/fix-nix-daemon-proxy.sh

LAN_IP=$(cat .sisyphus/notepads/fix-nix-proxy-ssl/lan_ip.txt)

echo "=== Task 3 Verification ==="
echo ""

# Check 1: Backup exists
if [ -f /etc/systemd/system/nix-daemon.service.d/override.conf.backup ]; then
    echo "✓ Backup exists"
else
    echo "✗ Backup NOT found"
    exit 1
fi

# Check 2: Configuration updated
if systemctl show nix-daemon -p Environment 2>/dev/null | grep -q "HTTP_PROXY.*$LAN_IP"; then
    echo "✓ Proxy configuration uses LAN IP ($LAN_IP)"
else
    echo "✗ Proxy still uses old configuration"
    systemctl show nix-daemon -p Environment 2>/dev/null | grep -i proxy
    exit 1
fi

# Check 3: nix-daemon is active
if systemctl is-active nix-daemon &>/dev/null; then
    echo "✓ nix-daemon is active"
else
    echo "✗ nix-daemon is NOT active"
    systemctl status nix-daemon
    exit 1
fi

# Check 4: File contents verification
if grep -q "HTTP_PROXY=http://$LAN_IP:7890" /etc/systemd/system/nix-daemon.service.d/override.conf; then
    echo "✓ override.conf contains correct LAN IP"
else
    echo "✗ override.conf does NOT contain LAN IP"
    cat /etc/systemd/system/nix-daemon.service.d/override.conf
    exit 1
fi

echo ""
echo "=== All Task 3 checks PASSED ==="
exit 0
