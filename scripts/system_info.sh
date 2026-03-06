#!/usr/bin/env bash

echo "=============================="
echo "       SYSTEM INFORMATION     "
echo "=============================="

echo ""
echo "--- OS & Kernel ---"
uname -a
if [ -f /etc/os-release ]; then
  . /etc/os-release
  echo "Distro: $PRETTY_NAME"
fi

echo ""
echo "--- Hostname & Uptime ---"
echo "Hostname: $(hostname)"
uptime

echo ""
echo "--- CPU ---"
if command -v lscpu &>/dev/null; then
  lscpu | grep -E "Model name|Architecture|CPU\(s\)|Thread|Core|Socket"
else
  sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "CPU info unavailable"
fi

echo ""
echo "--- Memory ---"
if command -v free &>/dev/null; then
  free -h
else
  vm_stat 2>/dev/null || echo "Memory info unavailable"
fi

echo ""
echo "--- Disk Usage ---"
df -h --total 2>/dev/null || df -h

echo ""
echo "--- Network Interfaces ---"
if command -v ip &>/dev/null; then
  ip -brief addr
else
  ifconfig 2>/dev/null | grep -E "^[a-z]|inet " || echo "Network info unavailable"
fi

echo ""
echo "--- Logged-in Users ---"
who

echo ""
echo "--- Shell & Environment ---"
echo "Shell:   $SHELL"
echo "User:    $(whoami)"
echo "Home:    $HOME"
echo "PATH:    $PATH"

echo ""
echo "=============================="