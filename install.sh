#!/usr/bin/env bash
#=============================================================================
# 🐧 FlyTux v26.2 - Sistema Cognitivo Cooperativo (Safe Edition)
# Correcciones vs v26.1:
#  • Ya NO desactiva el servicio Bluetooth (bluetooth)
#  • Ya NO desactiva el servicio de Impresoras (cups)
#  • Mantiene todo el hardening, detección y optimización de CPU/GPU/RAM
#=============================================================================

set -Eeuo pipefail

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN GLOBAL
# ═══════════════════════════════════════════════════════════════════════════

FX="/etc/flytux"
FV="/var/lib/flytux"
LOG="/var/log/flytux-$(date +%F-%H%M).log"
BKP="/var/backups/flytux-$(date +%F).tar.gz"
ERRORS=()
WARNINGS=()

# ═══════════════════════════════════════════════════════════════════════════
# HELPERS DE LOGGING
# ═══════════════════════════════════════════════════════════════════════════

log()   { echo "✅ $*"; logger -t flytux "$*"; }
info()  { echo "ℹ️  $*"; }
warn()  { echo "⚠️  $*" >&2; WARNINGS+=("$*"); logger -t flytux "WARN: $*"; }
error() { echo "❌ $*" >&2; ERRORS+=("$*"); logger -t flytux "ERROR: $*"; }
fatal() { echo "💀 $*" >&2; logger -t flytux "FATAL: $*"; exit 1; }

# ═══════════════════════════════════════════════════════════════════════════
# GESTIÓN DE ERRORES
# ═══════════════════════════════════════════════════════════════════════════

run() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    return 0
  else
    local rc=$?
    error "[$desc] falló (rc=$rc): $*"
    return $rc
  fi
}

run_visible() {
  local desc="$1"; shift
  if "$@"; then
    return 0
  else
    local rc=$?
    error "[$desc] falló (rc=$rc): $*"
    return $rc
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# HELPERS DE PAQUETES Y SERVICIOS
# ═══════════════════════════════════════════════════════════════════════════

pkg_exists() { apt-cache madison "$1" 2>/dev/null | grep -q '|' || false; }

inst() {
  local desc="$1"; shift
  info "📦 $desc: $*"
  if run "inst:$desc" apt install -y "$@"; then
    log "$desc instalado"
  else
    warn "$desc: algunos paquetes fallaron"
  fi
}

svc_on() {
  systemctl list-unit-files "$1.service" &>/dev/null | grep -q "$1" || return 0
  run "svc_on:$1" systemctl enable --now "$1"
}

svc_off() {
  systemctl list-unit-files "$1.service" &>/dev/null | grep -q "$1" || return 0
  run "svc_off:$1" systemctl disable --now "$1"
}

# ═══════════════════════════════════════════════════════════════════════════
# JSON SEGURO
# ═══════════════════════════════════════════════════════════════════════════

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  echo "$s"
}

json_write() {
  local file="$1"; shift
  local json="{"
  local first=true
  while [ $# -ge 2 ]; do
    local key="$1" val="$2"; shift 2
    $first || json+=","
    first=false
    if [[ "$val" == "true" || "$val" == "false" || "$val" =~ ^[0-9]+$ ]]; then
      json+="\"$key\":$val"
    else
      json+="\"$key\":\"$(json_escape "$val")\""
    fi
  done
  json+="}"
  echo "$json" > "$file"
}

# ═══════════════════════════════════════════════════════════════════════════
# DETECCIÓN DE CPU (perfil completo + CPUID real)
# ═══════════════════════════════════════════════════════════════════════════

read_cpuinfo() {
  CV=""; CF=""; CM=""; CS=""; CN=""; FLG=""
  CPU_CUR_MHZ=0; CPU_PHYS_CORES=""; CPU_SIBLINGS=""; CPU_CACHE=""; CPU_SOCKETS=1

  eval "$(awk -F: '
    /^vendor_id/ && !v {gsub(/^[ \t]+|[ \t]+$/, "", $2); print "CV=" tolower($2); v=1}
    /^cpu family/ && !f {gsub(/^[ \t]+|[ \t]+$/, "", $2); print "CF=" $2; f=1}
    /^model[ \t]*:/ && !m {gsub(/^[ \t]+|[ \t]+$/, "", $2); print "CM=" $2; m=1}
    /^stepping/ && !s {gsub(/^[ \t]+|[ \t]+$/, "", $2); print "CS=" $2; s=1}
    /^model name/ && !n {gsub(/^[ \t]+|[ \t]+$/, "", $2); print "CN=\"" $2 "\""; n=1}
    /^flags/ && !fl {gsub(/^[ \t]+|[ \t]+$/, "", $2); print "FLG=\"" $2 "\""; fl=1}
    /^cpu MHz/ && !mhz {gsub(/^[ \t]+|[ \t]+$/, "", $2); print "CPU_CUR_MHZ=" int($2); mhz=1}
    /^cpu cores/ && !cores {gsub(/^[ \t]+|[ \t]+$/, "", $2); print "CPU_PHYS_CORES=" $2; cores=1}
    /^siblings/ && !sib {gsub(/^[ \t]+|[ \t]+$/, "", $2); print "CPU_SIBLINGS=" $2; sib=1}
    /^physical id/ && !pid {gsub(/^[ \t]+|[ \t]+$/, "", $2); SOCKETS[$2]=1}
    /^cache size/ && !cache {gsub(/^[ \t]+|[ \t]+$/, "", $2); print "CPU_CACHE=\"" $2 "\""; cache=1}
    END {
      print "CPU_SOCKETS=" length(SOCKETS)
    }
  ' /proc/cpuinfo)"
  
  CC=$(nproc)
  AVX2=$(echo "$FLG" | grep -qw avx2 && echo true || echo false)
  AVX512=$(echo "$FLG" | grep -qw avx512f && echo true || echo false)
  
  SMT=false
  [ -n "$CPU_PHYS_CORES" ] && [ -n "$CPU_SIBLINGS" ] && [ "$CPU_SIBLINGS" -gt "$CPU_PHYS_CORES" ] && SMT=true
  
  CPU_MAX_MHZ=0
  CPU_MIN_MHZ=0
  if [ -f /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq ]; then
    CPU_MAX_MHZ=$(( $(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq) / 1000 ))
    [ -f /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq ] && \
      CPU_MIN_MHZ=$(( $(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq) / 1000 ))
  elif command -v lscpu &>/dev/null; then
    if lscpu -J &>/dev/null; then
      CPU_MAX_MHZ=$(lscpu -J 2>/dev/null | awk -F'"' '/CPU max MHz/{for(i=1;i<=NF;i++) if($i=="CPU max MHz") print $(i+4)}' | tr -d ' ,')
      CPU_MIN_MHZ=$(lscpu -J 2>/dev/null | awk -F'"' '/CPU min MHz/{for(i=1;i<=NF;i++) if($i=="CPU min MHz") print $(i+4)}' | tr -d ' ,')
    fi
    [ -z "$CPU_MAX_MHZ" ] || [ "$CPU_MAX_MHZ" -eq 0 ] && \
      CPU_MAX_MHZ=$(lscpu 2>/dev/null | awk '/CPU max MHz/{printf "%d",$4}')
    [ -z "$CPU_MIN_MHZ" ] || [ "$CPU_MIN_MHZ" -eq 0 ] && \
      CPU_MIN_MHZ=$(lscpu 2>/dev/null | awk '/CPU min MHz/{printf "%d",$4}')
  fi
  [ -z "$CPU_MAX_MHZ" ] || [ "$CPU_MAX_MHZ" -eq 0 ] && CPU_MAX_MHZ=2000
  [ -z "$CPU_MIN_MHZ" ] || [ "$CPU_MIN_MHZ" -eq 0 ] && CPU_MIN_MHZ=800
  
  HYB=false
  CAPS=$(cat /sys/devices/system/cpu/cpu*/cpu_capacity 2>/dev/null | sort -u | wc -l)
  [ "$CAPS" -gt 1 ] && HYB=true
  
  VIRT="none"
  echo "$FLG" | grep -qw vmx && VIRT="vmx"
  echo "$FLG" | grep -qw svm && VIRT="svm"
  command -v systemd-detect-virt &>/dev/null && {
    VIRT_TYPE=$(systemd-detect-virt 2>/dev/null)
    [ "$VIRT_TYPE" != "none" ] && VIRT="$VIRT_TYPE"
  }
  
  NUMA_NODES=1
  [ -d /sys/devices/system/node ] && NUMA_NODES=$(ls -d /sys/devices/system/node/node* 2>/dev/null | wc -l)
}

# ═══════════════════════════════════════════════════════════════════════════
# BASE CPUID
# ═══════════════════════════════════════════════════════════════════════════

detect_cpu_generation() {
  CG="unknown"; TLE=100
  
  if [[ "$CV" == *"intel"* && "$CF" == "6" ]]; then
    case "$CM" in
      198) CG="ArrowLake-S"; TLE=105;; 185) CG="LunarLake"; TLE=105;; 183) CG="ArrowLake-H"; TLE=105;;
      173) CG="MeteorLake"; TLE=105;; 170|171) CG="RaptorLake-R"; TLE=100;; 167) CG="RocketLake"; TLE=100;;
      158|165) CG="RaptorLake"; TLE=100;; 151|154|155) CG="AlderLake"; TLE=100;; 140|141) CG="TigerLake"; TLE=100;;
      142) CG="KabyLake-R"; TLE=100;; 126) CG="CometLake-U"; TLE=100;; 125) CG="IceLake-Y"; TLE=100;;
      102) CG="CannonLake"; TLE=100;; 150) CG="AlderLake-N"; TLE=105;; 166) CG="CometLake-H"; TLE=100;;
      162) CG="CoffeeLake-R"; TLE=100;; 152) CG="CoffeeLake"; TLE=100;; 122) CG="GeminiLake"; TLE=105;;
      92) CG="ApolloLake"; TLE=105;; 78|94) CG="Skylake"; TLE=100;; 61|71) CG="Broadwell"; TLE=100;;
      60|69|70) CG="Haswell"; TLE=100;; 58) CG="IvyBridge"; TLE=105;; 42) CG="SandyBridge"; TLE=100;;
      37|44|53) CG="Westmere"; TLE=105;; 26|30|31|46) CG="Nehalem"; TLE=100;; 23|29) CG="Penryn"; TLE=105;;
      15) CG="Merom"; TLE=100;; *) CG="Intel-F6-M$CM";;
    esac
  elif [[ "$CV" == *"amd"* ]]; then
    case "$CF" in
      26) CG="Zen5"; TLE=95;;
      25)
        if [ "$CM" -ge 112 ] 2>/dev/null; then CG="Zen4-Dragon"; TLE=95
        elif [ "$CM" -ge 96 ] 2>/dev/null; then CG="Zen4-Phoenix"; TLE=95
        elif [ "$CM" -ge 80 ] 2>/dev/null; then CG="Zen4-Raphael"; TLE=95
        elif [ "$CM" -ge 64 ] 2>/dev/null; then CG="Zen3+-Rembrandt"; TLE=95
        elif [ "$CM" -ge 32 ] 2>/dev/null; then CG="Zen3-Vermeer"; TLE=90
        elif [ "$CM" -ge 16 ] 2>/dev/null; then CG="Zen3-Cezanne"; TLE=90
        else CG="Zen3"; TLE=90; fi;;
      23)
        if [ "$CM" -ge 112 ] 2>/dev/null; then CG="Zen2-Vermeer"; TLE=95
        elif [ "$CM" -ge 96 ] 2>/dev/null; then CG="Zen2-Matisse"; TLE=95
        elif [ "$CM" -ge 48 ] 2>/dev/null; then CG="Zen2-Renoir"; TLE=95
        elif [ "$CM" -ge 16 ] 2>/dev/null; then CG="Zen+-Picasso"; TLE=95
        else CG="Zen-Summit"; TLE=95; fi;;
      21) CG="Bulldozer/Piledriver"; TLE=90;; *) CG="AMD-F$CF";;
    esac
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# GPU
# ═══════════════════════════════════════════════════════════════════════════

cache_lspci() {
  LSPCI_NN=$(lspci -nn 2>/dev/null || echo "")
  LSPCI_NNK=$(lspci -nnk 2>/dev/null || echo "")
}

detect_gpu() {
  GV=""; HI=false; HA=false; HN=false; GC=0; PD="unknown"; HYB_GPU=false
  
  if [ -n "$LSPCI_NN" ]; then
    echo "$LSPCI_NN" | grep -iE "vga|3d|display" | grep -q "\[8086:" && { GV+="intel,"; HI=true; GC=$((GC+1)); }
    echo "$LSPCI_NN" | grep -iE "vga|3d|display" | grep -q "\[1002:" && { GV+="amd,"; HA=true; GC=$((GC+1)); }
    echo "$LSPCI_NN" | grep -iE "vga|3d|display" | grep -q "\[10de:" && { GV+="nvidia,"; HN=true; GC=$((GC+1)); }
    [ "$GC" -gt 1 ] && HYB_GPU=true || HYB_GPU=false
    PD=$(echo "$LSPCI_NNK" | grep -i "vga compatible controller" -A2 | grep "Kernel driver in use:" | awk '{print $4}' | tr A-Z a-z | head -1)
    [ -z "$PD" ] && PD=$(echo "$LSPCI_NNK" | grep -i "3d controller" -A2 | grep "Kernel driver in use:" | awk '{print $4}' | tr A-Z a-z | head -1)
    [ -z "$PD" ] && PD="unknown"
  fi
  GV="${GV%,}"; [ -z "$GV" ] && GV="unknown"
}

get_gpu_score() {
  local GPU_ID=$(echo "$LSPCI_NN" | grep -iE "vga|3d" | head -1 | grep -oE '\[[0-9a-f]{4}:[0-9a-f]{4}\]' | tr -d '[]')
  case "$GPU_ID" in
    10de:2f00|10de:2f01|10de:2f02|10de:2f03|10de:2f04|10de:2f05|10de:2f06|10de:2f07) echo 20;;
    10de:2684|10de:2685|10de:2686|10de:2687|10de:2700|10de:2701|10de:2702|10de:2703|10de:2704|10de:2705|10de:2706|10de:2707|10de:2708|10de:2709) echo 18;;
    10de:2204|10de:2206|10de:2207|10de:2208|10de:2216|10de:2484|10de:2486|10de:2487|10de:2489|10de:24b0|10de:24b4|10de:24b6|10de:24b8|10de:24b9|10de:24ba|10de:24bb|10de:24bc|10de:24bd|10de:24be|10de:24bf) echo 16;;
    10de:1e04|10de:1e07|10de:1e30|10de:1e37|10de:1e84|10de:1e87|10de:1e89|10de:1ec2|10de:1ec7|10de:1f07|10de:1f08|10de:1f10|10de:1f11|10de:1f14|10de:1f15|10de:1f42|10de:1f50|10de:1f51|10de:1f54|10de:1f55|10de:1fb0|10de:1fb1|10de:1fb2|10de:1fb9|10de:1fba|10de:1fbb|10de:1ffc|10de:1ffd|10de:1ff6) echo 14;;
    10de:1b00|10de:1b06|10de:1b80|10de:1b81|10de:1b82|10de:1b84|10de:1ba1|10de:1be0|10de:1be1|10de:1c02|10de:1c03|10de:1c20|10de:1c30|10de:1c31|10de:1c81|10de:1c82|10de:1c8d|10de:1d01|10de:1d02|10de:1d10|10de:1d12|10de:1d33|10de:1d35) echo 10;;
    1002:744c|1002:744d|1002:747c|1002:747e|1002:743f|1002:7440|1002:7441|1002:7445|1002:7447|1002:7448|1002:744a|1002:744b|1002:744e|1002:744f|1002:745a|1002:745c|1002:745e|1002:7460|1002:7461|1002:747d|1002:747f) echo 18;;
    1002:73a1|1002:73a2|1002:73a3|1002:73a5|1002:73ab|1002:73ae|1002:73b5|1002:73bf|1002:73c1|1002:73c3|1002:73d1|1002:73d3|1002:73d5|1002:73db|1002:73dd|1002:73df|1002:73e0|1002:73e1|1002:73e2|1002:73e3|1002:73e5|1002:73eb|1002:73ed|1002:73ef|1002:73ff) echo 15;;
    1002:7310|1002:7312|1002:731a|1002:731b|1002:731f|1002:7340|1002:7341|1002:7360|1002:7362) echo 12;;
    8086:4c8a|8086:4c8b|8086:4c8c|8086:4c90|8086:5690|8086:5691|8086:5692|8086:56a0|8086:56a1|8086:56a5|8086:56a6|8086:56b0|8086:56b1|8086:56c0|8086:7d55|8086:7d60|8086:7dd5) echo 14;;
    8086:9a40|8086:9a49|8086:9a60|8086:9a68|8086:9a78|8086:9ac0|8086:9ac9|8086:9ad9|8086:9af8) echo 6;;
    *) echo 6;;
  esac
}

# ═══════════════════════════════════════════════════════════════════════════
# DETECCIÓN RESTANTE
# ═══════════════════════════════════════════════════════════════════════════

detect_storage() {
  DN=""; DT="hdd"; TRIM="false"
  eval "$(lsblk -ndo NAME,TYPE,SIZE,MODEL,ROTA,DISC-GRAN,DISC-MAX 2>/dev/null | awk '
    NR==1 {next}
    $2=="disk" && !found {
      print "DN=" $1
      print "DT=" ($7 ~ /^[0-9]/ && $7 > 0 ? "ssd" : "hdd")
      if ($1 ~ /nvme/) print "DT=nvme"
      print "TRIM=" ($8 ~ /^[0-9]/ && $8 > 0 ? "true" : "false")
      found=1
    }
  ')"
  [ -z "$DT" ] && DT="hdd"
  [ -z "$TRIM" ] && TRIM="false"
}

detect_peripherals() {
  BT=false
  lsusb 2>/dev/null | grep -qi bluetooth && BT=true
  [ "$BT" = "false" ] && [ -n "$LSPCI_NN" ] && echo "$LSPCI_NN" | grep -qi bluetooth && BT=true
  [ "$BT" = "false" ] && command -v hciconfig &>/dev/null && hciconfig 2>/dev/null | grep -q hci && BT=true
  MD=$(lsusb 2>/dev/null | grep -qiE "modem|lte|4g|5g" && echo true || echo false)
  PR=$(lpstat -p 2>/dev/null | grep -q printer && echo true || echo false)
  SN=false; command -v sensors &>/dev/null && sensors 2>/dev/null | grep -qE "Core|Tctl|Package" && SN=true
}

detect_system() {
  RAM=0; SWAP=0
  eval "$(awk '
    /^MemTotal:/ {print "RAM=" int($2/1024)}
    /^SwapTotal:/ {print "SWAP=" $2}
  ' /proc/meminfo)"
  
  LAPTOP=$(ls /sys/class/power_supply/BAT* &>/dev/null && echo true || echo false)
  BOOT=$([ -d /sys/firmware/efi ] && echo uefi || echo bios)
  SB="unknown"; command -v mokutil &>/dev/null && { mokutil --sb-state 2>/dev/null | grep -q "enabled" && SB="on"; mokutil --sb-state 2>/dev/null | grep -q "disabled" && SB="off"; }
  AU=$(logname 2>/dev/null || who | awk '{print $1;exit}')
  DE="${XDG_CURRENT_DESKTOP:-unknown}"; DE=$(echo "$DE" | tr A-Z a-z)
  
  AM=""
  systemctl is-active -q power-profiles-daemon 2>/dev/null && AM+="ppd,"
  systemctl is-active -q tlp 2>/dev/null && AM+="tlp,"
  systemctl is-active -q thermald 2>/dev/null && AM+="thermald,"
  AM="${AM%,}"; [ -z "$AM" ] && AM="none"
  FM=$([ "$AM" = "none" ] && echo "exclusive" || echo "cooperative")
}

# ═══════════════════════════════════════════════════════════════════════════
# HAL FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

thermal_get_temp() {
  local T=0
  for H in /sys/class/hwmon/hwmon*/temp1_input; do
    [ -f "$H" ] || continue
    LABEL=$(cat "${H%temp1_input}/name" 2>/dev/null)
    case "$LABEL" in coretemp*|k10temp*|cpu*|zen*|acpitz*) ;; *) continue;; esac
    V=$(cat "$H" 2>/dev/null); V=$((V/1000))
    [ "$V" -gt "$T" ] && T=$V
  done
  if [ "$T" -eq 0 ]; then
    for Z in /sys/class/thermal/thermal_zone*; do
      [ -d "$Z" ] || continue
      TYPE=$(cat "$Z/type" 2>/dev/null)
      case "$TYPE" in x86_pkg_temp*|k10temp*|coretemp*|cpu_thermal*) ;; *) continue;; esac
      V=$(cat "$Z/temp" 2>/dev/null); V=$((V/1000))
      [ "$V" -gt "$T" ] && T=$V
    done
  fi
  echo "$T"
}

thermal_get_limit() {
  local L=0
  for H in /sys/class/hwmon/hwmon*/temp1_crit; do
    [ -f "$H" ] || continue
    V=$(cat "$H" 2>/dev/null); V=$((V/1000))
    [ "$V" -ge 70 ] && [ "$V" -le 115 ] && [ "$V" -gt "$L" ] && L=$V
  done
  [ "$L" -eq 0 ] && L=${TLE:-100}
  [ -z "$L" ] || [ "$L" -eq 0 ] && L=100
  echo "$L"
}

thermal_profile() {
  local T=$(thermal_get_temp) L=$(thermal_get_limit) P=$((T*100/L))
  if [ "$P" -lt 75 ]; then echo performance
  elif [ "$P" -lt 88 ]; then echo balanced
  else echo powersave; fi
}

cpu_set_governor() {
  local REQ="$1" NOW=$(date +%s)
  local SF="/var/lib/flytux/history/cpu-state"
  [ -f "$SF" ] && { LAST=$(cut -d'|' -f1 "$SF"); LC=$(cut -d'|' -f2 "$SF"); }
  [ "$LAST" = "$REQ" ] && return
  [ $((NOW - ${LC:-0})) -lt 120 ] && return
  
  local DRV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null)
  local GOV="schedutil"
  case "$DRV" in
    intel_pstate|amd_pstate*)
      case "$REQ" in performance) GOV="performance";; *) GOV="powersave";; esac;;
    *)
      case "$REQ" in performance) GOV="performance";; balanced) GOV="schedutil";; powersave|silent) GOV="powersave";; esac;;
  esac
  grep -q "$GOV" /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || return
  echo "$GOV" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor &>/dev/null || true
  echo "${REQ}|${NOW}" > "$SF"
  logger -t flytux "gov=$GOV ($REQ) drv=$DRV"
}

gpu_set_mode() {
  local MODE="$1"
  if command -v prime-select &>/dev/null; then
    case "$MODE" in
      integrated) prime-select intel 2>/dev/null || prime-select amd 2>/dev/null;;
      nvidia)     prime-select nvidia 2>/dev/null;;
      on-demand)  prime-select on-demand 2>/dev/null;;
    esac
  elif command -v envycontrol &>/dev/null; then
    case "$MODE" in
      integrated) envycontrol -s integrated 2>/dev/null;;
      nvidia)     envycontrol -s nvidia 2>/dev/null;;
      hybrid)     envycontrol -s hybrid 2>/dev/null;;
    esac
  fi
}

battery_get_source() {
  for P in /sys/class/power_supply/*/type; do
    [ -f "$P" ] && grep -q Mains "$P" 2>/dev/null && [ "$(cat "${P%type}online" 2>/dev/null)" = "1" ] && { echo ac; return; }
  done
  echo battery
}

battery_get_percent() {
  for C in /sys/class/power_supply/BAT*/capacity; do
    [ -f "$C" ] && { cat "$C"; return; }
  done
  echo 100
}

battery_apply_profile() {
  local S=$(battery_get_source) B=$(battery_get_percent) G="balanced" GM="on-demand"
  [ "$S" = "battery" ] && { G="powersave"; GM="integrated"; }
  cpu_set_governor "$G"
  gpu_set_mode "$GM"
  logger -t flytux "power=$S batt=$B gov=$G gpu=$GM"
}

# ═══════════════════════════════════════════════════════════════════════════
# SCORE PONDERADO
# ═══════════════════════════════════════════════════════════════════════════

score_calculate() {
  local S_CPU=0 S_RAM=0 S_GPU=0 S_DISK=0 S_INST=0 S_GEN=0 S_TEMP=0
  local cpu_pts=0
  cpu_pts=$((CC > 24 ? 20 : CC > 16 ? 17 : CC > 12 ? 14 : CC > 8 ? 11 : CC > 4 ? 7 : 3))
  cpu_pts=$((cpu_pts + (CPU_MAX_MHZ > 5000 ? 10 : CPU_MAX_MHZ > 4000 ? 8 : CPU_MAX_MHZ > 3000 ? 5 : 2)))
  $HYB && cpu_pts=$((cpu_pts + 5))
  [ "$cpu_pts" -gt 35 ] && cpu_pts=35
  S_CPU=$cpu_pts
  
  S_RAM=$((RAM > 32768 ? 20 : RAM > 16384 ? 17 : RAM > 8192 ? 13 : RAM > 4096 ? 8 : 4))
  S_GPU=$(get_gpu_score)
  [ "$S_GPU" -gt 20 ] && S_GPU=20
  
  if echo "$DN" | grep -qi nvme; then S_DISK=10
  elif [ -n "$DN" ] && [ "$(cat /sys/block/$DN/queue/rotational 2>/dev/null)" = "0" ]; then S_DISK=6; fi
  
  if echo "$FLG" | grep -qw avx512f; then S_INST=5
  elif echo "$FLG" | grep -qw avx2; then S_INST=3
  else S_INST=1; fi
  
  case "$CG" in
    *Zen5*|*Lunar*|*Arrow*|*Meteor*) S_GEN=5;; *Zen4*|*Raptor*|*Alder*) S_GEN=4;;
    *Zen3*|*Tiger*|*Rocket*) S_GEN=3;; *Zen2*|*Ice*|*Comet*) S_GEN=2;; *) S_GEN=1;;
  esac
  
  local TEMP=$(thermal_get_temp 2>/dev/null)
  [ -n "$TEMP" ] && [ "$TEMP" -gt 0 ] && {
    [ "$TEMP" -lt 50 ] && S_TEMP=5 || [ "$TEMP" -lt 65 ] && S_TEMP=4 || [ "$TEMP" -lt 80 ] && S_TEMP=2 || S_TEMP=1
  } || S_TEMP=3
  
  local TOTAL=$((S_CPU + S_RAM + S_GPU + S_DISK + S_INST + S_GEN + S_TEMP))
  [ "$TOTAL" -gt 100 ] && TOTAL=100
  echo "$TOTAL|$S_CPU|$S_RAM|$S_GPU|$S_DISK|$S_INST|$S_GEN|$S_TEMP"
}

# ═══════════════════════════════════════════════════════════════════════════
# DAEMON
# ═══════════════════════════════════════════════════════════════════════════

daemon_main() {
  local PF="/run/flytuxd.pid" HD="/var/lib/flytux/history" LOCK="/run/lock/flytuxd.lock"
  mkdir -p "$HD" /run/lock
  exec 9>"$LOCK"
  if ! flock -n 9; then logger -t flytuxd "Otra instancia ya está corriendo"; exit 1; fi
  trap 'logger -t flytuxd "Daemon detenido (SIGTERM)"; rm -f "$PF"; exit 0' SIGTERM SIGINT
  trap 'logger -t flytuxd "Daemon recargado (SIGHUP)"' SIGHUP
  echo $$ > "$PF"
  [ -n "${NOTIFY_SOCKET:-}" ] && systemd-notify --ready 2>/dev/null || true
  FM=$(grep -o '"mode":"[^"]*"' /etc/flytux/hw.json 2>/dev/null | cut -d'"' -f4)
  [ -z "$FM" ] && FM="cooperative"
  logger -t flytuxd "Daemon iniciado (PID $$, modo: $FM)"
  LP=""; LT=""; CY=0
  while true; do
    PPD=$(systemctl is-active -q power-profiles-daemon 2>/dev/null && echo y || echo n)
    TLD=$(systemctl is-active -q thermald 2>/dev/null && echo y || echo n)
    ACT=true; [ "$FM" = "cooperative" ] && [ "$PPD" = "y" ] && ACT=false
    PS=$(battery_get_source)
    [ "$PS" != "$LP" ] && { $ACT && battery_apply_profile; LP="$PS"; }
    if [ "$TLD" = "n" ] || [ "$FM" = "exclusive" ]; then
      TP=$(thermal_profile)
      [ "$TP" != "$LT" ] && { cpu_set_governor "$TP"; LT="$TP"; }
    fi
    CY=$((CY+1))
    if [ "$CY" -ge 10 ]; then
      CY=0
      T=$(thermal_get_temp); B=$(battery_get_percent)
      RA=$(awk '/MemAvailable/{printf "%d",$2/1024}' /proc/meminfo)
      LD=$(cut -d' ' -f1 /proc/loadavg)
      echo "$(date -Iseconds)|t=${T:-0}|p=$PS|b=$B|r=$RA|l=$LD|g=${LT:-?}" >> "$HD/sys.log"
      [ -f "$HD/sys.log" ] && [ "$(stat -c%s "$HD/sys.log" 2>/dev/null)" -gt 1048576 ] && tail -1000 "$HD/sys.log" > "$HD/sys.log.tmp" && mv "$HD/sys.log.tmp" "$HD/sys.log"
      [ -n "${NOTIFY_SOCKET:-}" ] && systemd-notify WATCHDOG=1 2>/dev/null || true
    fi
    sleep 30
  done
}

# ═══════════════════════════════════════════════════════════════════════════
# INSTALADOR
# ═══════════════════════════════════════════════════════════════════════════

install_backup() {
  info "🔐 [1/12] Backup..."
  run "backup" tar czf "$BKP" /etc/sysctl.d /etc/default /etc/systemd/system /etc/udev/rules.d \
    /etc/modprobe.d /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null || true
}

install_repos() {
  info "🔓 [2/12] Repositorios..."
  for F in /etc/apt/sources.list.d/*.sources /etc/apt/sources.sources; do
    [ -f "$F" ] && grep -q "^Components:" "$F" && ! grep -q "non-free" "$F" && \
      sed -i '/^Components:/ s/$/ non-free non-free-firmware/' "$F" 2>/dev/null || true
  done
  if [[ "$ID" == "ubuntu" || "$ID_LIKE" == *"ubuntu"* || "$ID" == "linuxmint" || "$ID" == "pop" || "$ID" == "zorin" ]]; then
    if command -v add-apt-repository &>/dev/null; then
      run_visible "add-repo-multiverse" add-apt-repository multiverse -y
      run_visible "add-repo-restricted" add-apt-repository restricted -y
    fi
  fi
  run_visible "apt update" apt update -o Acquire::Retries=3 --allow-releaseinfo-change || warn "apt update con errores"
}

install_detect() {
  info "🔍 [3/12] Detectando hardware..."
  read_cpuinfo; cache_lspci; detect_cpu_generation; detect_gpu
  detect_storage; detect_peripherals; detect_system
  info "💾 ${RAM}MB | 💻 $LAPTOP | 🖥️ $CV $CG (F$CF/M$CM/S$CS) TLe≈${TLE}°C"
  info "💿 $DT | 🎮 $GV ($PD) | 🤝 $AM → $FM"
  info "🔧 SMT: $SMT | NUMA: $NUMA_NODES | Virtualización: $VIRT | Caché: $CPU_CACHE"
}

install_profile() {
  info "💾 [4/12] Guardando perfil..."
  DU=$(cat /sys/class/dmi/id/product_uuid 2>/dev/null || echo "none")
  MI=$(cat /etc/machine-id 2>/dev/null || echo "none")
  UUID=$(echo -n "$DU-$MI" | sha256sum | cut -c1-32 | sed 's/\(........\)\(....\)\(....\)\(....\)\(.*\)/\1-\2-4\3-8\4-\5/')
  [ -f "$FX/hw.json" ] && OLD_UUID=$(grep -o '"uuid":"[^"]*"' "$FX/hw.json" | cut -d'"' -f4) && [ -n "$OLD_UUID" ] && UUID="$OLD_UUID"
  json_write "$FX/hw.json" \
    v "26.2" uuid "$UUID" ts "$(date -Iseconds)" \
    cpu_vendor "$CV" cpu_gen "$CG" cpu_family "$CF" cpu_model "$CM" cpu_stepping "$CS" \
    cpu_cores "$CC" cpu_phys_cores "${CPU_PHYS_CORES:-$CC}" cpu_siblings "${CPU_SIBLINGS:-$CC}" \
    cpu_sockets "${CPU_SOCKETS:-1}" cpu_cache "${CPU_CACHE:-unknown}" \
    cpu_hybrid "$HYB" cpu_tle "$TLE" cpu_max_mhz "$CPU_MAX_MHZ" cpu_min_mhz "$CPU_MIN_MHZ" cpu_cur_mhz "${CPU_CUR_MHZ:-0}" \
    cpu_smt "$SMT" cpu_virt "$VIRT" numa_nodes "$NUMA_NODES" \
    ram "$RAM" disk "$DT" trim "$TRIM" gpu "$GV" hyb_gpu "$HYB_GPU" \
    laptop "$LAPTOP" bt "$BT" modem "$MD" sb "$SB" de "$DE" managers "$AM" mode "$FM"
}

install_daemon() {
  info "🤖 [5/12] Instalando daemon..."
  run "install-binary" cp "$0" /usr/local/bin/flytux
  run "chmod-binary" chmod +x /usr/local/bin/flytux
  cat > /etc/systemd/system/flytuxd.service <<EOF
[Unit]
Description=FlyTux Cooperative Daemon
After=systemd-modules-load.service
Wants=systemd-modules-load.service

[Service]
Type=notify
WatchdogSec=120
ExecStart=/usr/local/bin/flytux --daemon
Restart=on-failure
RestartSec=10

ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
NoNewPrivileges=yes
MemoryDenyWriteExecute=yes
ProtectKernelTunables=no
ProtectKernelModules=yes
ProtectKernelLogs=yes
ProtectControlGroups=yes
RestrictSUIDSGID=yes
RestrictRealtime=yes
LockPersonality=yes
SystemCallFilter=@system-service

ReadWritePaths=/var/lib/flytux /etc/flytux /run /run/lock /sys/devices/system/cpu

[Install]
WantedBy=multi-user.target
EOF
  cat > /etc/systemd/system/flytux-battery.service <<EOF
[Unit]
Description=Apply FlyTux battery profile
[Service]
Type=oneshot
ExecStart=/usr/local/bin/flytux --battery-apply
EOF
  cat > /etc/udev/rules.d/99-flytux-power.rules <<EOF
ACTION=="change", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_TYPE}=="Mains", SYSTEMD_WANTS="flytux-battery.service"
EOF
  run "daemon-reload" systemctl daemon-reload
  svc_on flytuxd
  run "udev-reload" udevadm control --reload-rules
}

install_kernel() {
  info "⚙️  [6/12] Configurando kernel..."
  cat > /etc/sysctl.d/99-flytux.conf <<EOF
net.core.somaxconn=4096
net.ipv4.tcp_fastopen=3
net.core.netdev_max_backlog=4096
net.core.rmem_max=16777216
net.core.wmem_max=16777216
EOF
  sysctl net.ipv4.tcp_available_congestion_control 2>/dev/null | grep -q bbr && \
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.d/99-flytux.conf
  run "sysctl" sysctl -p /etc/sysctl.d/99-flytux.conf
}

install_memory() {
  info "⚡ [7/12] Configurando memoria..."
  ZS=$((RAM*50/100)); [ "$ZS" -gt 4096 ] && ZS=4096
  if [ "$RAM" -le 8192 ] && [ ! -b /dev/zram0 ]; then
    if pkg_exists systemd-zram-generator; then
      inst "ZRAM" systemd-zram-generator
      mkdir -p /etc/systemd/zram-generator.conf.d
      echo -e "[zram0]\nzram-size=ram/2\ncompression-algorithm=zstd" > /etc/systemd/zram-generator.conf.d/fx.conf
      run "daemon-reload" systemctl daemon-reload
      svc_on systemd-zram-setup@zram0
    elif pkg_exists zram-tools; then
      inst "ZRAM" zram-tools
      echo -e "ENABLE=yes\nSIZE=$ZS\nALGO=zstd\nPRIORITY=100" > /etc/default/zramswap
      svc_on zramswap
    fi
  fi
  [ "$RAM" -le 8192 ] && { inst "EarlyOOM" earlyoom; svc_on earlyoom; }
  [ "$RAM" -le 4096 ] && [ "$DT" = "hdd" ] && { inst "Preload" preload; svc_on preload; }
}

install_power() {
  info "🌡️  [8/12] Configurando energía..."
  if [ "$LAPTOP" = "true" ]; then
    [[ "$CV" == *"intel"* ]] && { inst "Thermald" thermald; svc_on thermald; }
    if [[ "$ID" != "debian" && "$ID_LIKE" != *"debian"* ]]; then
      inst "PPD" power-profiles-daemon; svc_on power-profiles-daemon
    else
      systemctl is-active -q power-profiles-daemon 2>/dev/null || { inst "TLP" tlp tlp-rdw; svc_on tlp; }
    fi
  fi
  inst "Sensors" lm-sensors
}

install_gpu() {
  info "🏭 [9/12] Drivers..."
  [[ "$CV" == *"intel"* ]] && ! dpkg -l intel-microcode 2>/dev/null | grep -q "^ii" && inst "µcode" intel-microcode
  [[ "$CV" == *"amd"* ]] && ! dpkg -l amd64-microcode 2>/dev/null | grep -q "^ii" && inst "µcode" amd64-microcode
  $HI && { PK=(); pkg_exists intel-media-driver && PK+=(intel-media-driver); pkg_exists mesa-va-drivers && PK+=(mesa-va-drivers); pkg_exists mesa-vulkan-drivers && PK+=(mesa-vulkan-drivers); [ ${#PK[@]} -gt 0 ] && inst "Intel GPU" "${PK[@]}"; }
  $HA && { PK=(); pkg_exists firmware-amd-graphics && PK+=(firmware-amd-graphics); pkg_exists mesa-vulkan-drivers && PK+=(mesa-vulkan-drivers); pkg_exists mesa-va-drivers && PK+=(mesa-va-drivers); [ ${#PK[@]} -gt 0 ] && inst "AMD GPU" "${PK[@]}"; }
  if $HN; then
    NP="nvidia-driver"
    command -v ubuntu-drivers &>/dev/null && { R=$(ubuntu-drivers devices 2>/dev/null | awk '/recommended/{print $3}'); [ -n "$R" ] && NP="$R"; }
    if [ "$SB" = "on" ]; then
      warn "Secure Boot ON → NVIDIA omitido (requiere MOK enrollment)"
    else
      inst "NVIDIA" "$NP" nvidia-settings nvidia-prime
      $HYB_GPU && command -v prime-select &>/dev/null && run "prime-select" prime-select on-demand || true
    fi
  fi
  inst "Firmware" linux-firmware fwupd; svc_on fwupd
  $TRIM && svc_on fstrim.timer
  [ "$DT" = "nvme" ] && inst "NVMe" nvme-cli
  pkg_exists envycontrol && inst "EnvyControl" envycontrol
}

install_services() {
  info "🔕 [10/12] Optimizando servicios..."
  # MANTENEMOS ACTIVOS: Bluetooth e Impresoras (CUPS)
  # para que funcionen si los conectas/encendes después de instalar.
  
  # Solo desactivamos ModemManager si no hay módem celular
  $MD || svc_off ModemManager
}

install_security() {
  info "🛡️ [11/12] Seguridad..."
  if command -v ufw &>/dev/null; then
    run "ufw-reset" ufw --force reset
    run "ufw-default-in" ufw default deny incoming
    run "ufw-default-out" ufw default allow outgoing
    for P in 21 23 135 137 139 445 3389 5900; do run "ufw-deny-$P" ufw deny $P/tcp 2>/dev/null || true; done
    run "ufw-enable" ufw --force enable
    svc_on ufw
  else
    warn "UFW no detectado. Se omite la configuración del firewall."
  fi
  for p in popularity-contest whoopsie apport ubuntu-report; do
    dpkg -l "$p" &>/dev/null && run "purge:$p" apt purge -y "$p" || true
  done
  command -v aa-enforce &>/dev/null && {
    for f in /etc/apparmor.d/*flatpak* /etc/apparmor.d/*bwrap*; do
      [ -f "$f" ] && run "apparmor:$f" aa-enforce "$f" || true
    done
    svc_on apparmor
  }
  if [ -n "$AU" ] && [ "$AU" != "root" ]; then
    DB="unix:path=/run/user/$(id -u "$AU")/bus"
    case "$DE" in
      *gnome*|*zorin*) runuser -u "$AU" -- env DBUS_SESSION_BUS_ADDRESS="$DB" gsettings set org.gnome.desktop.interface enable-animations true 2>/dev/null || true;;
      *cinnamon*) runuser -u "$AU" -- env DBUS_SESSION_BUS_ADDRESS="$DB" gsettings set org.cinnamon.desktop.interface enable-animations true 2>/dev/null || true;;
      *kde*|*plasma*) runuser -u "$AU" -- kwriteconfig5 --file kwinrc --group Compositing --key Enabled true 2>/dev/null || true;;
    esac
  fi
}

install_cleanup() {
  info "🧹 [12/12] Limpieza..."
  run "full-upgrade" apt full-upgrade -y
  run "autoremove" apt autoremove -y --purge
  run "clean" apt clean
  run "journal-vacuum" journalctl --vacuum-size=200M --vacuum-time=14d
  run "tmpfiles" systemd-tmpfiles --clean
  cat > "$FV/PRIVACY.txt" <<EOF
🔒 FlyTux: 100% local. Sin red. Sin telemetría externa.
Datos en $FV/history/ son SOLO tuyos.
EOF
}

install_flytux() {
  echo "🐧 FlyTux v26.2 - Instalando..."
  [ "$(id -u)" -ne 0 ] && fatal "Ejecutar con: sudo bash $0"
  . /etc/os-release
  [[ "$ID_LIKE" =~ debian|ubuntu || "$ID" =~ debian|ubuntu|linuxmint|pop|zorin ]] || fatal "Distro incompatible"
  export DEBIAN_FRONTEND=noninteractive
  mkdir -p /var/backups "$FX" "$FV/history"
  exec > >(tee -a "$LOG") 2>&1
  install_backup; install_repos; install_detect; install_profile; install_daemon
  install_kernel; install_memory; install_power; install_gpu; install_services
  install_security; install_cleanup
  SCORE_DATA=$(score_calculate)
  IFS='|' read -r TOTAL S_CPU S_RAM S_GPU S_DISK S_INST S_GEN S_TEMP <<< "$SCORE_DATA"
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo "🐧 FlyTux v26.2 INSTALADO"
  echo "════════════════════════════════════════════════════════"
  echo ""
  echo "🆔 UUID: $UUID"
  echo "🖥️  CPU: $CV $CG (F$CF/M$CM) TLe≈${TLE}°C"
  echo "   Cores: $CC (físicos: ${CPU_PHYS_CORES:-?}, logical: ${CPU_SIBLINGS:-?})"
  echo "   SMT: $SMT | NUMA: $NUMA_NODES | Virtualización: $VIRT"
  echo "   Frecuencia: ${CPU_MIN_MHZ}-${CPU_MAX_MHZ} MHz (actual: ${CPU_CUR_MHZ:-?})"
  echo "   Caché: $CPU_CACHE"
  echo "💾 RAM: ${RAM}MB | 💿 Disco: $DT | 🎮 GPU: $GV"
  echo "🤝 Modo: $FM | 🔐 Secure Boot: $SB"
  echo ""
  echo "📊 SCORE: $TOTAL/100"
  echo "   CPU: $S_CPU/35 | RAM: $S_RAM/20 | GPU: $S_GPU/20"
  echo "   Disco: $S_DISK/10 | Instr: $S_INST/5 | Gen: $S_GEN/5 | Temp: $S_TEMP/5"
  echo ""
  if [ ${#ERRORS[@]} -gt 0 ]; then
    echo "⚠️  ERRORES DURANTE LA INSTALACIÓN (${#ERRORS[@]}):"
    for e in "${ERRORS[@]}"; do echo "   • $e"; done; echo ""
  fi
  if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo "ℹ️  ADVERTENCIAS (${#WARNINGS[@]}):"
    for w in "${WARNINGS[@]}"; do echo "   • $w"; done; echo ""
  fi
  echo "📁 Archivos:"
  echo "   • Perfil: $FX/hw.json"
  echo "   • Historial: $FV/history/"
  echo "   • Daemon: /usr/local/bin/flytux --daemon"
  echo ""
  echo "💡 Reinicia para activar el daemon."
  echo "🔙 Revertir: sudo tar xzf $BKP -C /"
  echo "════════════════════════════════════════════════════════"
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

case "$1" in
  --daemon)
    read_cpuinfo; cache_lspci; detect_cpu_generation; detect_storage; daemon_main;;
  --battery-apply)
    battery_apply_profile;;
  --score)
    read_cpuinfo; cache_lspci; detect_cpu_generation; detect_gpu; detect_storage
    SCORE_DATA=$(score_calculate)
    IFS='|' read -r TOTAL S_CPU S_RAM S_GPU S_DISK S_INST S_GEN S_TEMP <<< "$SCORE_DATA"
    echo "📊 FlyTux Score: $TOTAL/100"
    echo "   CPU: $S_CPU/35 | RAM: $S_RAM/20 | GPU: $S_GPU/20"
    echo "   Disco: $S_DISK/10 | Instr: $S_INST/5 | Gen: $S_GEN/5 | Temp: $S_TEMP/5";;
  --install|"")
    install_flytux;;
  *)
    echo "Uso: $0 [--daemon|--install|--score|--battery-apply]"; exit 1;;
esac
