#!/bin/bash
# Task 4: Test home-manager build with new proxy config

echo "=== Task 4: Testing home-manager Build ==="
echo ""

# Check prerequisites
if ! systemctl show nix-daemon -p Environment 2>/dev/null | grep -q "HTTP_PROXY.*192.168.3.75"; then
    echo "✗ PREREQUISITE FAILED: Task 3 not complete"
    echo "  Run /tmp/fix-nix-daemon-proxy.sh first!"
    exit 1
fi

echo "✓ Prerequisite: nix-daemon proxy configured"
echo ""

# Attempt build
echo "Starting home-manager build..."
echo "(This may take several minutes)"
echo ""

cd /home/mingshi/.config/home-manager

if home-manager switch 2>&1 | tee /tmp/hms-build.log; then
    echo ""
    echo "✓ home-manager build SUCCESSFUL!"
    echo ""
    echo "=== Task 4 PASSED ==="
    exit 0
else
    echo ""
    echo "✗ home-manager build FAILED"
    echo ""
    echo "Build log saved to: /tmp/hms-build.log"
    echo "Last 20 lines:"
    tail -20 /tmp/hms-build.log
    echo ""
    echo "=== Task 4 FAILED ==="
    exit 1
fi
