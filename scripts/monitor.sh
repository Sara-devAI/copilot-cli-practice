#!/usr/bin/env bash

# Usage: ./monitor.sh [interval_seconds] [duration_seconds]
INTERVAL=${1:-2}
DURATION=${2:-0}  # 0 = run indefinitely

LOG_FILE="monitor_$(date +%Y%m%d_%H%M%S).log"
START=$(date +%s)

print_header() {
  printf "%-20s %-10s %-10s %-15s %-15s\n" "TIMESTAMP" "CPU%" "MEM%" "MEM_USED" "MEM_TOTAL"
  printf '%s\n' "----------------------------------------------------------------------"
}

get_cpu_usage() {
  # Read two samples of /proc/stat to compute CPU delta
  local cpu1 cpu2 idle1 idle2 total1 total2
  read -r _ user1 nice1 sys1 idle1 iowait1 _ _ _ _ < /proc/stat
  sleep 0.2
  read -r _ user2 nice2 sys2 idle2 iowait2 _ _ _ _ < /proc/stat
  local delta_idle=$(( (idle2 + iowait2) - (idle1 + iowait1) ))
  local delta_total=$(( (user2 + nice2 + sys2 + idle2 + iowait2) - (user1 + nice1 + sys1 + idle1 + iowait1) ))
  echo $(( 100 * (delta_total - delta_idle) / delta_total ))
}

get_mem_info() {
  if command -v free &>/dev/null; then
    read -r _ total used _ < <(free -m | awk 'NR==2')
    local pct=$(( 100 * used / total ))
    echo "$pct $used $total"
  else
    # macOS fallback via vm_stat
    local page_size total_pages free_pages
    page_size=$(pagesize)
    total_pages=$(sysctl -n hw.memsize | awk "{print \$1 / $page_size}")
    free_pages=$(vm_stat | awk '/Pages free/ {gsub(/\./,"",$3); print $3}')
    local used_pages=$(( total_pages - free_pages ))
    local used_mb=$(( used_pages * page_size / 1024 / 1024 ))
    local total_mb=$(( total_pages * page_size / 1024 / 1024 ))
    local pct=$(( 100 * used_mb / total_mb ))
    echo "$pct $used_mb $total_mb"
  fi
}

echo "Monitoring CPU & Memory | Interval: ${INTERVAL}s | Log: $LOG_FILE"
echo "Press Ctrl+C to stop."
echo ""

print_header | tee "$LOG_FILE"

while true; do
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

  CPU=$(get_cpu_usage)
  read -r MEM_PCT MEM_USED MEM_TOTAL < <(get_mem_info)

  LINE=$(printf "%-20s %-10s %-10s %-15s %-15s" \
    "$TIMESTAMP" "${CPU}%" "${MEM_PCT}%" "${MEM_USED}MB" "${MEM_TOTAL}MB")

  echo "$LINE" | tee -a "$LOG_FILE"

  # Warn if CPU or memory is high
  if (( CPU > 85 )); then
    echo "  ⚠️  HIGH CPU: ${CPU}%" | tee -a "$LOG_FILE"
  fi
  if (( MEM_PCT > 85 )); then
    echo "  ⚠️  HIGH MEMORY: ${MEM_PCT}%" | tee -a "$LOG_FILE"
  fi

  # Check duration limit
  if (( DURATION > 0 )); then
    ELAPSED=$(( $(date +%s) - START ))
    if (( ELAPSED >= DURATION )); then
      echo ""
      echo "Duration of ${DURATION}s reached. Exiting."
      break
    fi
  fi

  sleep "$INTERVAL"
done
