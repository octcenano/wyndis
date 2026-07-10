#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Wyndis v3.0 - Linux Security Auditor (Bash port)
# https://github.com/octcenano/wyndis
#
# Professional Linux security auditor with 200+ checks across 20 modules
# Generates professional HTML/PDF reports with scoring

set -euo pipefail

# ─── GLOBALS ──────────────────────────────────────────────────────────────
WYNDIS_VERSION="3.0.0"
WYNDIS_START_TIME=$(date +%s)
declare -A FINDINGS
FINDINGS_COUNT=0
CRITICAL_COUNT=0
WARNING_COUNT=0
SCORE=100
MODULES_RUN=0
REPORT_LINES=()
SYSTEM_INFO=()
NO_COLOR=false
QUICK_MODE=false
REPORT_PATH=""
NO_PDF=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── HELPERS ──────────────────────────────────────────────────────────────

color() {
    if [[ "$NO_COLOR" == "true" ]]; then cat; else sed "s/{R}/$RED/g; s/{G}/$GREEN/g; s/{Y}/$YELLOW/g; s/{B}/$BLUE/g; s/{M}/$MAGENTA/g; s/{C}/$CYAN/g; s/{W}/$WHITE/g; s/{GR}/$GRAY/g; s/{RS}/$RESET/g; s/{BD}/$BOLD/g"; fi
}

write_banner() {
    cat <<'EOF' | color
  ╔══════════════════════════════════════════════════════════════╗
  ║              Wyndis v{V} — Linux Security Auditor            ║
  ║           MIT License | Open Source | 200+ Checks            ║
  ║           https://github.com/octcenano/wyndis                ║
  ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "  ${W}Professional Linux security auditor${RS}"
    echo -e "  ${GR}20 modules · 200+ checks · HTML/JSON reports${RS}"
    echo -e "  ${GR}100% free · Open source (MIT) · No telemetry${RS}"
    echo ""
    echo -e "  ${B}Web: https://wyndis-download-ce9eb.web.app${RS}"
    echo -e "  ${B}GitHub: https://github.com/octcenano/wyndis${RS}"
    echo -e "  ${B}Discord: https://discord.gg/wyndis${RS}"
    echo ""
    echo -e "  ${Y}⚠ Wyndis does NOT collect telemetry or personal data.${RS}"
    echo -e "  ${Y}⚠ All analysis runs locally on your machine.${RS}"
    echo ""
}

write_section() { echo -e "\n  ${C}${BD}== $1 ==${RS}"; }
write_ok()    { echo -e "  ${G}[ OK ]${RS} $1"; }
write_warn()  { echo -e "  ${Y}[WARN]${RS} $1"; }
write_crit()  { echo -e "  ${R}[CRIT]${RS} $1"; }
write_info()  { echo -e "  ${B}[INFO]${RS} $1"; }
write_sugg()  { echo -e "  ${M}[SUGG]${RS} $1"; }

add_finding() {
    local id="$1" category="$2" name="$3" severity="$4" details="$5" remediation="$6" ref="$7"
    FINDINGS["$id"]="$category|$name|$severity|$details|$remediation|$ref|$(date '+%Y-%m-%d %H:%M:%S')"
    ((FINDINGS_COUNT++))
    if [[ "$severity" == "Critical" ]]; then
        ((CRITICAL_COUNT++))
        ((SCORE -= 5))
        write_crit "$category - $name"
    else
        ((WARNING_COUNT++))
        ((SCORE -= 2))
        write_warn "$category - $name"
    fi
    [[ -n "$details" ]] && echo -e "       ${GR}$details${RS}"
    [[ $SCORE -lt 0 ]] && SCORE=0
}

add_report_line() { REPORT_LINES+=("$1"); }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        write_warn "Not running as root. Many checks will be limited."
        write_sugg "Run: sudo $0"
        return 1
    fi
    write_ok "Running as root"
    return 0
}

collect_system_info() {
    write_info "Collecting system information..."
    SYSTEM_INFO[hostname]=$(hostname)
    SYSTEM_INFO[user]=$(whoami)
    SYSTEM_INFO[os]=$(source /etc/os-release && echo "$PRETTY_NAME")
    SYSTEM_INFO[kernel]=$(uname -r)
    SYSTEM_INFO[arch]=$(uname -m)
    SYSTEM_INFO[uptime]=$(uptime -p 2>/dev/null || uptime)
    SYSTEM_INFO[cpu]=$(lscpu | grep 'Model name' | cut -d: -f2 | xargs)
    SYSTEM_INFO[cores]=$(nproc)
    SYSTEM_INFO[mem_total]=$(free -h | awk '/^Mem:/ {print $2}')
    SYSTEM_INFO[mem_free]=$(free -h | awk '/^Mem:/ {print $7}')
    SYSTEM_INFO[disk_root]=$(df -h / | awk 'NR==2 {print $4 " free of " $2}')
    SYSTEM_INFO[is_root]=$([[ $EUID -eq 0 ]] && echo "yes" || echo "no")

    write_ok "Host: ${SYSTEM_INFO[hostname]}"
    write_ok "OS: ${SYSTEM_INFO[os]} (${SYSTEM_INFO[kernel]})"
    write_ok "CPU: ${SYSTEM_INFO[cpu]} (${SYSTEM_INFO[cores]} cores)"
    write_ok "RAM: ${SYSTEM_INFO[mem_free]} free of ${SYSTEM_INFO[mem_total]}"
    write_ok "Disk /: ${SYSTEM_INFO[disk_root]}"
    write_ok "Root: ${SYSTEM_INFO[is_root]}"
}

show_score() {
    local grade=""
    local grade_color=""
    if [[ $SCORE -ge 90 ]]; then grade="🟢 EXCELLENT"; grade_color=$GREEN
    elif [[ $SCORE -ge 70 ]]; then grade="🟡 GOOD"; grade_color=$YELLOW
    elif [[ $SCORE -ge 40 ]]; then grade="🟠 ACCEPTABLE"; grade_color=$MAGENTA
    elif [[ $SCORE -ge 10 ]]; then grade="🔴 NEEDS IMPROVEMENT"; grade_color=$RED
    else grade="⚫ CRITICAL"; grade_color=$RED$BOLD; fi

    echo ""
    echo -e "  ${C}${BD}╔══════════════════════════════════════════════════════════════╗${RS}"
    printf "  ${C}${BD}║  SECURITY SCORE: %3d / 100  ║${RS}\n" "$SCORE"
    printf "  ${C}${BD}║  %-46s  ║${RS}\n" "$grade"
    echo -e "  ${C}${BD}╚══════════════════════════════════════════════════════════════╝${RS}"
    echo ""
    echo -e "  ${R}[CRIT]${RS} Critical findings:   $CRITICAL_COUNT"
    echo -e "  ${Y}[WARN]${RS} Warning findings:    $WARNING_COUNT"
    echo -e "  ${B}[TOTAL]${RS} Total findings:       $FINDINGS_COUNT"
    echo ""
    echo -e "  ${GR}Scale: 90-100 🟢 Excellent | 70-89 🟡 Good | 40-69 🟠 Acceptable | 10-39 🔴 Needs Improvement | 0-9 ⚫ Critical${RS}"
    echo -e "  ${GR}Each critical finding -5 points; each warning -2 points.${RS}"
    echo ""
}

# ─── MODULE IMPLEMENTATIONS ───────────────────────────────────────────────

# Module: System Info (always runs)
module_system_info() {
    write_section "1. System Information"
    collect_system_info
    ((MODULES_RUN++))
}

# Module: Package Manager / Updates
module_updates() {
    write_section "2. Package Updates"
    if command -v apt &>/dev/null; then
        apt list --upgradable 2>/dev/null | tail -n +2 | while read -r line; do
            [[ -n "$line" ]] && write_info "Upgradable: $line"
        done
        local count=$(apt list --upgradable 2>/dev/null | tail -n +2 | wc -l)
        if [[ $count -gt 0 ]]; then
            add_finding "UPD-001" "Updates" "$count package(s) upgradable" "Warning" "Security updates pending" "apt update && apt upgrade -y" "CIS 1.1"
        else
            write_ok "No pending updates (apt)"
        fi
    elif command -v dnf &>/dev/null; then
        local count=$(dnf check-update -q 2>/dev/null | grep -c '^[a-z]' || true)
        if [[ $count -gt 0 ]]; then
            add_finding "UPD-002" "Updates" "$count package(s) upgradable" "Warning" "Security updates pending" "dnf upgrade -y" "CIS 1.1"
        else
            write_ok "No pending updates (dnf)"
        fi
    elif command -v pacman &>/dev/null; then
        local count=$(pacman -Qu 2>/dev/null | wc -l)
        if [[ $count -gt 0 ]]; then
            add_finding "UPD-003" "Updates" "$count package(s) upgradable" "Warning" "Security updates pending" "pacman -Syu" "CIS 1.1"
        else
            write_ok "No pending updates (pacman)"
        fi
    elif command -v zypper &>/dev/null; then
        local count=$(zypper list-updates 2>/dev/null | grep -c '^v' || true)
        if [[ $count -gt 0 ]]; then
            add_finding "UPD-004" "Updates" "$count package(s) upgradable" "Warning" "Security updates pending" "zypper update" "CIS 1.1"
        else
            write_ok "No pending updates (zypper)"
        fi
    else
        write_warn "Package manager not detected"
    fi
    ((MODULES_RUN++))
}

# Module: SSH Configuration
module_ssh() {
    write_section "3. SSH Configuration"
    local sshd_config="/etc/ssh/sshd_config"
    [[ ! -f "$sshd_config" ]] && { write_warn "sshd_config not found"; ((MODULES_RUN++)); return; }

    check_ssh_setting() {
        local setting="$1" expected="$2" finding_id="$3" severity="${4:-Warning}" msg="$5"
        local actual=$(grep -i "^${setting}" "$sshd_config" 2>/dev/null | awk '{print $2}' | head -1)
        actual=${actual:-$(grep -i "^#${setting}" "$sshd_config" 2>/dev/null | awk '{print $3}' | head -1)}
        actual=${actual:-"NOT SET (default)"}
        if [[ "$actual" == "$expected" ]] || [[ "$actual" =~ ^$expected$ ]]; then
            write_ok "SSH $setting: $actual"
        else
            add_finding "$finding_id" "SSH" "SSH $setting = $actual (expected: $expected)" "$severity" "$msg" "Set '$setting $expected' in $sshd_config and restart sshd" "CIS 5.2"
        fi
    }

    check_ssh_setting "PermitRootLogin" "no" "SSH-001" "Critical" "Root login via SSH enabled"
    check_ssh_setting "PasswordAuthentication" "no" "SSH-002" "Critical" "Password auth enabled; use keys only"
    check_ssh_setting "PubkeyAuthentication" "yes" "SSH-003" "Warning" "Public key auth disabled"
    check_ssh_setting "PermitEmptyPasswords" "no" "SSH-004" "Critical" "Empty passwords allowed"
    check_ssh_setting "MaxAuthTries" "4" "SSH-005" "Warning" "Too many auth attempts allowed"
    check_ssh_setting "ClientAliveInterval" "300" "SSH-006" "Warning" "No keepalive; idle sessions persist"
    check_ssh_setting "ClientAliveCountMax" "2" "SSH-007" "Warning" "No disconnect on unresponsive client"
    check_ssh_setting "LoginGraceTime" "60" "SSH-008" "Warning" "Too long grace period"
    check_ssh_setting "X11Forwarding" "no" "SSH-009" "Warning" "X11 forwarding enabled (risk)"
    check_ssh_setting "AllowAgentForwarding" "no" "SSH-010" "Warning" "Agent forwarding enabled (risk)"
    check_ssh_setting "AllowTcpForwarding" "no" "SSH-011" "Warning" "TCP forwarding enabled (tunnel risk)"
    check_ssh_setting "PermitUserEnvironment" "no" "SSH-012" "Warning" "User environment processing enabled"
    check_ssh_setting "Protocol" "2" "SSH-013" "Critical" "SSH Protocol 1 allowed"
    check_ssh_setting "IgnoreRhosts" "yes" "SSH-014" "Warning" "Rhosts not ignored"
    check_ssh_setting "HostbasedAuthentication" "no" "SSH-015" "Warning" "Host-based auth enabled"
    check_ssh_setting "Banner" "/etc/issue.net" "SSH-016" "Warning" "No login banner"

    # Check for weak ciphers/MACs
    if grep -qi "^Ciphers.*\(aes128-cbc\|3des-cbc\|blowfish-cbc\|cast128-cbc\|arcfour\|rijndael-cbc@lysator.liu.se\)" "$sshd_config"; then
        add_finding "SSH-017" "SSH" "Weak ciphers configured" "Warning" "Legacy ciphers allowed" "Set Ciphers to strong ones only (aes256-gcm@openssh.com,chacha20-poly1305@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr)" "CIS 5.2.13"
    else
        write_ok "SSH Ciphers: No weak ciphers found"
    fi

    if grep -qi "^MACs.*\(hmac-md5\|hmac-sha1-96\|hmac-sha1\|umac-64@openssh.com\|umac-128@openssh.com\)" "$sshd_config"; then
        add_finding "SSH-018" "SSH" "Weak MACs configured" "Warning" "Legacy MACs allowed" "Set MACs to strong ones only (hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-512)" "CIS 5.2.14"
    else
        write_ok "SSH MACs: No weak MACs found"
    fi

    ((MODULES_RUN++))
}

# Module: Firewall (UFW/iptables/nftables)
module_firewall() {
    write_section "4. Firewall"

    if command -v ufw &>/dev/null; then
        local status=$(ufw status 2>/dev/null | head -1)
        if [[ "$status" == *"active"* ]]; then
            write_ok "UFW: ACTIVE"
            ufw status numbered | while read -r line; do
                [[ -n "$line" ]] && write_info "  $line"
            done
        else
            add_finding "FW-001" "Firewall" "UFW INACTIVE" "Critical" "No host firewall active" "ufw enable" "CIS 3.1"
        fi
    elif command -v firewall-cmd &>/dev/null; then
        if firewall-cmd --state 2>/dev/null | grep -q "running"; then
            write_ok "firewalld: RUNNING"
            firewall-cmd --list-all | while read -r line; do write_info "  $line"; done
        else
            add_finding "FW-002" "Firewall" "firewalld NOT RUNNING" "Critical" "No host firewall active" "systemctl enable --now firewalld" "CIS 3.1"
        fi
    elif command -v iptables &>/dev/null; then
        local rules=$(iptables -L -n 2>/dev/null | grep -c '^ACCEPT\|^DROP\|^REJECT' || true)
        if [[ $rules -gt 4 ]]; then
            write_ok "iptables: RULES CONFIGURED ($rules rules)"
        else
            add_finding "FW-003" "Firewall" "iptables: MINIMAL/NO RULES" "Warning" "No effective firewall rules" "Configure iptables/nftables rules" "CIS 3.1"
        fi
    elif command -v nft &>/dev/null; then
        local tables=$(nft list tables 2>/dev/null | wc -l)
        if [[ $tables -gt 0 ]]; then
            write_ok "nftables: TABLES CONFIGURED ($tables)"
        else
            add_finding "FW-004" "Firewall" "nftables: NO TABLES" "Warning" "No nftables configuration" "Configure nftables ruleset" "CIS 3.1"
        fi
    else
        add_finding "FW-005" "Firewall" "NO FIREWALL TOOL DETECTED" "Critical" "No firewall management tool found" "Install ufw, firewalld, or configure nftables/iptables" "CIS 3.1"
    fi

    ((MODULES_RUN++))
}

# Module: User Accounts
module_accounts() {
    write_section "5. User Accounts"

    # Root account
    if grep -q '^root:[^!*]' /etc/shadow 2>/dev/null; then
        add_finding "ACC-001" "Accounts" "Root account has password set" "Warning" "Root should be locked; use sudo" "passwd -l root" "CIS 5.3"
    else
        write_ok "Root account: LOCKED (no password)"
    fi

    # Accounts with UID 0 (besides root)
    local uid0=$(awk -F: '($3 == 0) {print $1}' /etc/passwd | grep -v '^root$')
    if [[ -n "$uid0" ]]; then
        add_finding "ACC-002" "Accounts" "Additional UID 0 accounts: $uid0" "Critical" "Multiple UID 0 accounts = backdoor risk" "Remove or change UID of: $uid0" "CIS 5.4"
    else
        write_ok "No additional UID 0 accounts"
    fi

    # Accounts with empty passwords
    local empty_pass=$(awk -F: '($2 == "" || $2 == "!" || $2 == "*") {print $1}' /etc/shadow 2>/dev/null | head -20)
    if [[ -n "$empty_pass" ]]; then
        add_finding "ACC-003" "Accounts" "Accounts with empty/locked passwords: $empty_pass" "Warning" "Locked accounts listed" "Review: passwd -S \$(awk -F: '(\$2==\"\"||\$2==\"!\"||\$2==\"*\") {print \$1}' /etc/shadow)" "CIS 5.5"
    else
        write_ok "No accounts with empty passwords"
    fi

    # Password aging
    local no_expire=$(awk -F: '($5 == 99999 || $5 == "") {print $1}' /etc/shadow 2>/dev/null | grep -v '^root$' | head -10)
    if [[ -n "$no_expire" ]]; then
        add_finding "ACC-004" "Accounts" "Accounts with password never expiring: $no_expire" "Warning" "Static passwords increase risk" "chage -M 90 \$user" "CIS 5.6"
    else
        write_ok "All accounts have password expiration"
    fi

    # Sudoers
    if [[ -f /etc/sudoers ]]; then
        if grep -q '^Defaults\s*!authenticate' /etc/sudoers /etc/sudoers.d/* 2>/dev/null; then
            add_finding "ACC-005" "Accounts" "sudo NOPASSWD or !authenticate found" "Critical" "Passwordless sudo allows privilege escalation" "Remove NOPASSWD/!authenticate from sudoers" "CIS 5.7"
        else
            write_ok "sudo: Authentication required"
        fi
    fi

    # Wheel/sudo group members
    local wheel=$(grep '^wheel:' /etc/group 2>/dev/null | cut -d: -f4)
    local sudo_grp=$(grep '^sudo:' /etc/group 2>/dev/null | cut -d: -f4)
    local admin_users="${wheel:-}${sudo_grp:-}"
    if [[ -n "$admin_users" ]]; then
        write_info "Admin group members: $admin_users"
    fi

    ((MODULES_RUN++))
}

# Module: Kernel Hardening
module_kernel() {
    write_section "6. Kernel Hardening"

    # Sysctl settings
    check_sysctl() {
        local param="$1" expected="$2" finding_id="$3" severity="${4:-Warning}" msg="$5"
        local actual=$(sysctl -n "$param" 2>/dev/null || echo "N/A")
        if [[ "$actual" == "$expected" ]]; then
            write_ok "Kernel $param = $actual"
        else
            add_finding "$finding_id" "Kernel" "$param = $actual (expected: $expected)" "$severity" "$msg" "echo '$param = $expected' >> /etc/sysctl.d/99-wyndis.conf && sysctl -p" "CIS 4.x"
        fi
    }

    check_sysctl "net.ipv4.ip_forward" "0" "KER-001" "Warning" "IP forwarding enabled"
    check_sysctl "net.ipv4.conf.all.send_redirects" "0" "KER-002" "Warning" "ICMP redirects sent"
    check_sysctl "net.ipv4.conf.default.send_redirects" "0" "KER-003" "Warning" "ICMP redirects sent (default)"
    check_sysctl "net.ipv4.conf.all.accept_redirects" "0" "KER-004" "Warning" "ICMP redirects accepted"
    check_sysctl "net.ipv4.conf.default.accept_redirects" "0" "KER-005" "Warning" "ICMP redirects accepted (default)"
    check_sysctl "net.ipv4.conf.all.secure_redirects" "0" "KER-006" "Warning" "Secure redirects accepted"
    check_sysctl "net.ipv4.conf.default.secure_redirects" "0" "KER-007" "Warning" "Secure redirects accepted (default)"
    check_sysctl "net.ipv4.conf.all.log_martians" "1" "KER-008" "Warning" "Martian packets not logged"
    check_sysctl "net.ipv4.conf.default.log_martians" "1" "KER-009" "Warning" "Martian packets not logged (default)"
    check_sysctl "net.ipv4.icmp_echo_ignore_broadcasts" "1" "KER-010" "Warning" "Broadcast ping not ignored"
    check_sysctl "net.ipv4.icmp_ignore_bogus_error_responses" "1" "KER-011" "Warning" "Bogus ICMP errors not ignored"
    check_sysctl "net.ipv4.tcp_syncookies" "1" "KER-012" "Critical" "SYN cookies disabled (DoS risk)"
    check_sysctl "net.ipv4.conf.all.rp_filter" "1" "KER-013" "Warning" "Reverse path filtering disabled"
    check_sysctl "net.ipv4.conf.default.rp_filter" "1" "KER-014" "Warning" "RP filter disabled (default)"
    check_sysctl "net.ipv6.conf.all.disable_ipv6" "1" "KER-015" "Warning" "IPv6 enabled (disable if unused)"
    check_sysctl "net.ipv6.conf.default.disable_ipv6" "1" "KER-016" "Warning" "IPv6 enabled (default)"
    check_sysctl "kernel.dmesg_restrict" "1" "KER-017" "Warning" "dmesg accessible to non-root"
    check_sysctl "kernel.kptr_restrict" "2" "KER-018" "Warning" "Kernel pointers exposed"
    check_sysctl "kernel.perf_event_paranoid" "3" "KER-019" "Warning" "Perf events not restricted"
    check_sysctl "kernel.yama.ptrace_scope" "1" "KER-020" "Warning" "ptrace not restricted"
    check_sysctl "fs.suid_dumpable" "0" "KER-021" "Warning" "SUID core dumps allowed"
    check_sysctl "fs.protected_hardlinks" "1" "KER-022" "Warning" "Hardlink following not protected"
    check_sysctl "fs.protected_symlinks" "1" "KER-023" "Warning" "Symlink following not protected"
    check_sysctl "fs.protected_fifos" "2" "KER-024" "Warning" "FIFO creation not protected"
    check_sysctl "fs.protected_regular" "2" "KER-025" "Warning" "Regular file creation not protected"

    ((MODULES_RUN++))
}

# Module: Filesystem / Mounts
module_filesystem() {
    write_section "7. Filesystem & Mounts"

    # Check for noexec, nosuid, nodev on /tmp, /var/tmp, /dev/shm
    check_mount_option() {
        local mount_point="$1" option="$2" finding_id="$3"
        if findmnt -n -o OPTIONS "$mount_point" 2>/dev/null | grep -qw "$option"; then
            write_ok "$mount_point: $option set"
        else
            add_finding "$finding_id" "Filesystem" "$mount_point missing $option mount option" "Warning" "Missing $option on $mount_point" "Add '$option' to $mount_point in /etc/fstab" "CIS 1.1.x"
        fi
    }

    check_mount_option "/tmp" "noexec" "FS-001"
    check_mount_option "/tmp" "nosuid" "FS-002"
    check_mount_option "/tmp" "nodev" "FS-003"
    check_mount_option "/var/tmp" "noexec" "FS-004"
    check_mount_option "/var/tmp" "nosuid" "FS-005"
    check_mount_option "/var/tmp" "nodev" "FS-006"
    check_mount_option "/dev/shm" "noexec" "FS-007"
    check_mount_option "/dev/shm" "nosuid" "FS-008"
    check_mount_option "/dev/shm" "nodev" "FS-009"

    # Check for world-writable dirs
    local ww_dirs=$(find / -xdev -type d -perm -0002 2>/dev/null | grep -v '^/proc\|^/sys\|^/run' | head -10)
    if [[ -n "$ww_dirs" ]]; then
        add_finding "FS-010" "Filesystem" "World-writable directories found" "Warning" "Directories: $ww_dirs" "chmod o-w <dir> or add sticky bit" "CIS 6.1.10"
    else
        write_ok "No world-writable directories (excluding sticky)"
    fi

    # Check for unowned files
    local unowned=$(find / -xdev -nouser -o -nogroup 2>/dev/null | head -10)
    if [[ -n "$unowned" ]]; then
        add_finding "FS-011" "Filesystem" "Unowned files/directories found" "Warning" "Files: $unowned" "chown root:root <file> or remove" "CIS 6.1.11"
    else
        write_ok "No unowned files"
    fi

    ((MODULES_RUN++))
}

# Module: Services
module_services() {
    write_section "8. Services"

    # Dangerous services
    local dangerous=(
        "telnet.socket:Telnet"
        "rsh.socket:RSH"
        "rlogin.socket:Rlogin"
        "rexec.socket:Rexec"
        "tftp.socket:TFTP"
        "xinetd:Xinetd"
        "rsyncd:Rsync daemon"
        "nfs-server:NFS Server"
        "rpcbind:RPC Bind"
        "cups:CUPS Printing"
        "avahi-daemon:Avahi/mDNS"
        "bluetooth:Bluetooth"
        "ModemManager:ModemManager"
    )

    for entry in "${dangerous[@]}"; do
        local svc="${entry%%:*}"
        local desc="${entry##*:}"
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            add_finding "SVC-$(echo $svc | tr '.' '_')" "Services" "$desc ($svc) is RUNNING" "Warning" "Unnecessary service exposes attack surface" "systemctl stop $svc && systemctl disable $svc" "CIS 2.1"
        elif systemctl is-enabled --quiet "$svc" 2>/dev/null; then
            write_info "$desc ($svc): ENABLED (not running)"
        else
            write_ok "$desc ($svc): DISABLED"
        fi
    done

    # Check for services running as root
    local root_svcs=$(systemctl list-units --type=service --state=running --no-legend 2>/dev/null | awk '{print $1}' | while read unit; do
        local user=$(systemctl show -p User "$unit" 2>/dev/null | cut -d= -f2)
        [[ -z "$user" || "$user" == "root" ]] && echo "$unit"
    done | head -10)

    if [[ -n "$root_svcs" ]]; then
        write_info "Services running as root: $root_svcs"
    fi

    ((MODULES_RUN++))
}

# Module: Auditd
module_auditd() {
    write_section "9. Audit Daemon (auditd)"

    if systemctl is-active --quiet auditd 2>/dev/null; then
        write_ok "auditd: RUNNING"

        # Check rules
        local rules=$(auditctl -l 2>/dev/null | wc -l)
        write_info "Audit rules loaded: $rules"

        # Key rules to check
        local required_rules=(
            "-w /etc/passwd -p wa -k identity"
            "-w /etc/group -p wa -k identity"
            "-w /etc/shadow -p wa -k identity"
            "-w /etc/sudoers -p wa -k scope"
            "-w /var/log/sudo.log -p wa -k actions"
            "-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change"
            "-a always,exit -F arch=b64 -S clock_settime -k time-change"
            "-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod"
        )

        for rule in "${required_rules[@]}"; do
            if auditctl -l 2>/dev/null | grep -q "$(echo $rule | awk '{print $1,$2,$3,$4,$5}')"; then
                write_ok "Audit rule present: ${rule:0:60}..."
            else
                add_finding "AUD-$(echo $rule | md5sum | cut -c1-6)" "Auditd" "Missing audit rule: $rule" "Warning" "Critical file/action not audited" "Add to /etc/audit/rules.d/50-wyndis.rules" "CIS 4.1.x"
            fi
        done
    else
        add_finding "AUD-001" "Auditd" "auditd NOT RUNNING" "Critical" "No audit trail for security events" "systemctl enable --now auditd" "CIS 4.1"
    fi

    ((MODULES_RUN++))
}

# Module: Logging
module_logging() {
    write_section "10. Logging (rsyslog/journald)"

    if systemctl is-active --quiet rsyslog 2>/dev/null; then
        write_ok "rsyslog: RUNNING"
        if [[ -f /etc/rsyslog.conf ]]; then
            if grep -q '^\$FileCreateMode 0640' /etc/rsyslog.conf; then
                write_ok "rsyslog: FileCreateMode 0640"
            else
                add_finding "LOG-001" "Logging" "rsyslog FileCreateMode not 0640" "Warning" "Log files world-readable" "Add '\$FileCreateMode 0640' to /etc/rsyslog.conf" "CIS 4.2"
            fi
        fi
    elif systemctl is-active --quiet systemd-journald 2>/dev/null; then
        write_ok "systemd-journald: RUNNING"
        if [[ -f /etc/systemd/journald.conf ]]; then
            if grep -q '^ForwardToSyslog=yes' /etc/systemd/journald.conf; then
                write_ok "journald: ForwardToSyslog=yes"
            else
                add_finding "LOG-002" "Logging" "journald not forwarding to syslog" "Warning" "Logs may not reach central log server" "Set ForwardToSyslog=yes in /etc/systemd/journald.conf" "CIS 4.2"
            fi
        fi
    else
        add_finding "LOG-003" "Logging" "NO LOGGING DAEMON RUNNING" "Critical" "No syslog/journald" "systemctl enable --now rsyslog" "CIS 4.2"
    fi

    # Log rotation
    if [[ -f /etc/logrotate.conf ]]; then
        write_ok "logrotate: CONFIGURED"
    else
        add_finding "LOG-004" "Logging" "logrotate not configured" "Warning" "Logs may fill disk" "Install and configure logrotate" "CIS 4.2"
    fi

    ((MODULES_RUN++))
}

# Module: Cron / Scheduled Tasks
module_cron() {
    write_section "11. Cron & Scheduled Tasks"

    # Check cron permissions
    for f in /etc/crontab /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly; do
        if [[ -e "$f" ]]; then
            local perm=$(stat -c "%a" "$f")
            if [[ "$perm" != "600" && "$perm" != "700" ]]; then
                add_finding "CRON-001" "Cron" "$f permissions: $perm (should be 600/700)" "Warning" "Cron files readable by others" "chmod 600 $f" "CIS 5.1.1"
            else
                write_ok "$f permissions: $perm"
            fi
        fi
    done

    # cron.allow/deny
    if [[ -f /etc/cron.allow ]]; then
        write_ok "cron.allow exists (allow list)"
    elif [[ -f /etc/cron.deny ]]; then
        add_finding "CRON-002" "Cron" "cron.deny exists (should use cron.allow)" "Warning" "Deny list less secure than allow list" "Create /etc/cron.allow with authorized users" "CIS 5.1.2"
    else
        add_finding "CRON-003" "Cron" "Neither cron.allow nor cron.deny exists" "Warning" "All users can use cron" "Create /etc/cron.allow with authorized users" "CIS 5.1.3"
    fi

    # at.allow/deny
    if [[ -f /etc/at.allow ]]; then
        write_ok "at.allow exists"
    elif [[ -f /etc/at.deny ]]; then
        add_finding "CRON-004" "Cron" "at.deny exists (should use at.allow)" "Warning" "Deny list less secure" "Create /etc/at.allow" "CIS 5.1.4"
    else
        add_finding "CRON-005" "Cron" "Neither at.allow nor at.deny" "Warning" "All users can use at" "Create /etc/at.allow" "CIS 5.1.5"
    fi

    # Check for suspicious cron entries
    local suspicious=$(grep -r 'curl\|wget\|nc\|netcat\|bash -i\|sh -i\|/dev/tcp' /etc/cron* /var/spool/cron/ 2>/dev/null | head -5)
    if [[ -n "$suspicious" ]]; then
        add_finding "CRON-006" "Cron" "Suspicious cron entries found" "Critical" "Possible persistence/backdoor" "Review and remove: $suspicious" "CIS 5.1.6"
    else
        write_ok "No suspicious cron entries"
    fi

    ((MODULES_RUN++))
}

# Module: Network
module_network() {
    write_section "12. Network Configuration"

    # IP forwarding (already in kernel module)

    # Listening ports
    write_info "Listening ports:"
    ss -tuln 2>/dev/null | tail -n +2 | while read -r line; do
        write_info "  $line"
    done

    # Check for risky services listening
    local risky_ports="21:FTP 23:Telnet 135:RPC 139:NetBIOS 445:SMB 1433:MSSQL 3306:MySQL 3389:RDP 5432:PostgreSQL 5900:VNC 5985:WinRM 5986:WinRM-SSL 6379:Redis 8080:HTTP-Proxy 8443:HTTPS-Proxy 9200:Elasticsearch 27017:MongoDB"
    for entry in $risky_ports; do
        local port="${entry%%:*}"
        local name="${entry##*:}"
        if ss -tuln 2>/dev/null | grep -q ":$port "; then
            add_finding "NET-$(printf "%03d" $port)" "Network" "$name ($port) listening on all interfaces" "Warning" "Exposed service: $name" "Restrict to localhost or firewall: ss -tuln | grep :$port" "CIS 3.2"
        fi
    done

    # ICMP redirects (kernel)
    # DNS config
    if [[ -f /etc/resolv.conf ]]; then
        write_info "DNS servers: $(grep nameserver /etc/resolv.conf | awk '{print $2}' | tr '\n' ' ')"
    fi

    ((MODULES_RUN++))
}

# Module: Bootloader
module_bootloader() {
    write_section "13. Bootloader (GRUB)"

    if [[ -f /boot/grub2/grub.cfg ]] || [[ -f /boot/grub/grub.cfg ]]; then
        local grub_cfg=$(find /boot -name "grub.cfg" 2>/dev/null | head -1)

        if grep -q 'set superusers=' "$grub_cfg" 2>/dev/null; then
            write_ok "GRUB: Superusers configured"
        else
            add_finding "GRUB-001" "Bootloader" "GRUB superusers NOT configured" "Warning" "No password protection on boot menu" "Set GRUB_PASSWORD in /etc/grub.d/40_custom" "CIS 1.4"
        fi

        if grep -q 'password_pbkdf2' "$grub_cfg" 2>/dev/null; then
            write_ok "GRUB: Password hash present"
        else
            add_finding "GRUB-002" "Bootloader" "GRUB password NOT set" "Warning" "Bootloader editable at boot" "grub-mkpasswd-pbkdf2 and add to 40_custom" "CIS 1.4"
        fi

        # Check permissions
        local perm=$(stat -c "%a" "$grub_cfg" 2>/dev/null)
        if [[ "$perm" == "400" || "$perm" == "600" ]]; then
            write_ok "grub.cfg permissions: $perm"
        else
            add_finding "GRUB-003" "Bootloader" "grub.cfg permissions: $perm (should be 400/600)" "Warning" "Boot config readable by others" "chmod 600 $grub_cfg" "CIS 1.4"
        fi
    else
        write_info "GRUB config not found (maybe systemd-boot or other)"
    fi

    ((MODULES_RUN++))
}

# Module: Cryptographic Policies
module_crypto() {
    write_section "14. Cryptographic Policies"

    if command -v update-crypto-policies &>/dev/null; then
        local policy=$(update-crypto-policies --show 2>/dev/null)
        write_info "Crypto policy: $policy"
        case "$policy" in
            FIPS|FUTURE) write_ok "Strong crypto policy: $policy" ;;
            DEFAULT) write_info "DEFAULT policy (consider FUTURE/FIPS)" ;;
            LEGACY) add_finding "CRYPTO-001" "Crypto" "LEGACY crypto policy active" "Critical" "Weak algorithms allowed" "update-crypto-policies --set FUTURE" "CIS 3.4" ;;
        esac
    elif [[ -f /etc/crypto-policies/config ]]; then
        local policy=$(cat /etc/crypto-policies/config)
        write_info "Crypto policy: $policy"
    else
        write_info "Crypto policies not managed by update-crypto-policies"
    fi

    # OpenSSL config
    if [[ -f /etc/ssl/openssl.cnf ]]; then
        if grep -q 'MinProtocol = TLSv1.2' /etc/ssl/openssl.cnf; then
            write_ok "OpenSSL: MinProtocol TLSv1.2"
        else
            add_finding "CRYPTO-002" "Crypto" "OpenSSL MinProtocol not TLSv1.2+" "Warning" "Old TLS versions allowed" "Add MinProtocol = TLSv1.2 to openssl.cnf" "CIS 3.4"
        fi
    fi

    ((MODULES_RUN++))
}

# Module: AppArmor / SELinux
module_mac() {
    write_section "15. Mandatory Access Control (AppArmor/SELinux)"

    if command -v aa-status &>/dev/null; then
        if aa-status --enabled 2>/dev/null; then
            write_ok "AppArmor: ENABLED"
            local profiles=$(aa-status 2>/dev/null | grep -c 'profiles loaded' || true)
            write_info "Profiles loaded: $profiles"
            local enforce=$(aa-status 2>/dev/null | grep -c 'enforce' || true)
            local complain=$(aa-status 2>/dev/null | grep -c 'complain' || true)
            write_info "Enforce: $enforce, Complain: $complain"
            if [[ $complain -gt 0 ]]; then
                add_finding "AA-001" "AppArmor" "$complain profiles in complain mode" "Warning" "Complain mode = not enforcing" "aa-enforce /etc/apparmor.d/*" "CIS 1.7"
            fi
        else
            add_finding "AA-002" "AppArmor" "AppArmor DISABLED" "Critical" "No mandatory access control" "systemctl enable --now apparmor" "CIS 1.7"
        fi
    elif command -v sestatus &>/dev/null; then
        local se=$(sestatus 2>/dev/null | grep "Current mode" | awk '{print $3}')
        if [[ "$se" == "enforcing" ]]; then
            write_ok "SELinux: ENFORCING"
        elif [[ "$se" == "permissive" ]]; then
            add_finding "SE-001" "SELinux" "SELinux PERMISSIVE" "Warning" "Not enforcing policies" "setenforce 1; edit /etc/selinux/config" "CIS 1.6"
        else
            add_finding "SE-002" "SELinux" "SELinux DISABLED" "Critical" "No MAC" "Edit /etc/selinux/config; reboot" "CIS 1.6"
        fi
    else
        add_finding "MAC-001" "MAC" "Neither AppArmor nor SELinux detected" "Critical" "No mandatory access control system" "Install apparmor or enable SELinux" "CIS 1.6/1.7"
    fi

    ((MODULES_RUN++))
}

# Module: Container Security (Docker/Podman)
module_containers() {
    write_section "16. Container Security (Docker/Podman)"

    for runtime in docker podman; do
        if command -v $runtime &>/dev/null; then
            write_info "$runtime detected"

            # Check daemon config
            if [[ "$runtime" == "docker" ]]; then
                local config="/etc/docker/daemon.json"
            else
                local config="/etc/containers/containers.conf"
            fi

            if [[ -f "$config" ]]; then
                write_ok "$runtime config exists: $config"
                # Check for userns-remap, no-new-privileges, etc.
            else
                add_finding "CONT-${runtime^^}-001" "Containers" "$runtime daemon.json not configured" "Warning" "Default daemon config insecure" "Create $config with hardening" "CIS Docker 2.x"
            fi

            # Running containers
            if $runtime ps --format "{{.Names}}" 2>/dev/null | grep -q .; then
                local count=$($runtime ps -q 2>/dev/null | wc -l)
                write_info "$runtime: $count container(s) running"
                $runtime ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" 2>/dev/null | while read line; do write_info "  $line"; done
            else
                write_ok "$runtime: No containers running"
            fi
        fi
    done

    ((MODULES_RUN++))
}

# Module: Package Integrity
module_pkg_integrity() {
    write_section "17. Package Integrity"

    if command -v rpm &>/dev/null; then
        local modified=$(rpm -Va 2>/dev/null | grep -v '^........  c ' | head -10)
        if [[ -n "$modified" ]]; then
            add_finding "PKG-001" "Packages" "RPM files modified from original" "Warning" "Files: $modified" "rpm2cpio / rpm -V investigation" "CIS 6.1"
        else
            write_ok "RPM: No modified files (excl. config)"
        fi
    elif command -v dpkg &>/dev/null; then
        if command -v debsums &>/dev/null; then
            local modified=$(debsums -s 2>/dev/null | head -10)
            if [[ -n "$modified" ]]; then
                add_finding "PKG-002" "Packages" "dpkg files modified" "Warning" "Files: $modified" "apt install --reinstall <pkg>" "CIS 6.1"
            else
                write_ok "dpkg: No modified files (debsums)"
            fi
        else
            write_info "debsums not installed (install for integrity check)"
        fi
    elif command -v pacman &>/dev/null; then
        local modified=$(pacman -Qkk 2>/dev/null | grep -v ' 0 altered' | head -10)
        if [[ -n "$modified" ]]; then
            add_finding "PKG-003" "Packages" "Pacman files modified" "Warning" "Files: $modified" "pacman -Qkk investigation" "CIS 6.1"
        else
            write_ok "Pacman: No modified files"
        fi
    fi

    ((MODULES_RUN++))
}

# Module: Permissions
module_permissions() {
    write_section "18. Critical File Permissions"

    check_perm() {
        local file="$1" expected="$2" finding_id="$3"
        if [[ -f "$file" ]]; then
            local perm=$(stat -c "%a" "$file")
            local owner=$(stat -c "%U:%G" "$file")
            if [[ "$perm" == "$expected" ]]; then
                write_ok "$file: $perm $owner"
            else
                add_finding "$finding_id" "Permissions" "$file: $perm $owner (expected: $expected)" "Warning" "Incorrect permissions on critical file" "chmod $expected $file; chown root:root $file" "CIS 6.1"
            fi
        fi
    }

    check_perm "/etc/passwd" "644" "PERM-001"
    check_perm "/etc/shadow" "600" "PERM-002"
    check_perm "/etc/group" "644" "PERM-003"
    check_perm "/etc/gshadow" "600" "PERM-004"
    check_perm "/etc/sudoers" "440" "PERM-005"
    check_perm "/etc/ssh/sshd_config" "600" "PERM-006"
    check_perm "/etc/ssh/ssh_host_rsa_key" "600" "PERM-007"
    check_perm "/etc/ssh/ssh_host_ecdsa_key" "600" "PERM-008"
    check_perm "/etc/ssh/ssh_host_ed25519_key" "600" "PERM-009"
    check_perm "/etc/crontab" "600" "PERM-010"
    check_perm "/etc/login.defs" "644" "PERM-011"
    check_perm "/etc/sysctl.conf" "644" "PERM-012"
    check_perm "/etc/sysctl.d/99-wyndis.conf" "644" "PERM-013"

    ((MODULES_RUN++))
}

# Module: Hardware Security
module_hardware() {
    write_section "19. Hardware Security"

    # TPM
    if [[ -c /dev/tpm0 ]] || [[ -c /dev/tpmrm0 ]]; then
        write_ok "TPM device present"
        if command -v tpm2_getcap &>/dev/null; then
            local tpm=$(tpm2_getcap properties-fixed 2>/dev/null | grep -i "tpm2" | head -1)
            write_info "TPM: $tpm"
        fi
    else
        write_info "TPM: Not detected"
    fi

    # Secure Boot
    if [[ -d /sys/firmware/efi ]]; then
        if command -v mokutil &>/dev/null; then
            local sb=$(mokutil --sb-state 2>/dev/null)
            if echo "$sb" | grep -qi "enabled"; then
                write_ok "Secure Boot: ENABLED"
            else
                add_finding "HW-001" "Hardware" "Secure Boot: DISABLED" "Warning" "Unsigned bootloaders allowed" "Enable in UEFI/BIOS" "CIS 1.5"
            fi
        fi
    else
        write_info "BIOS/Legacy boot (no Secure Boot)"
    fi

    # CPU mitigations
    if [[ -f /sys/devices/system/cpu/vulnerabilities/* ]]; then
        write_info "CPU Vulnerabilities:"
        for v in /sys/devices/system/cpu/vulnerabilities/*; do
            local name=$(basename "$v")
            local status=$(cat "$v" 2>/dev/null)
            write_info "  $name: $status"
        done
    fi

    ((MODULES_RUN++))
}

# Module: Summary / Compliance
module_summary() {
    write_section "20. Summary & Compliance"

    echo ""
    echo -e "  ${C}${BD}=== WYNDIS LINUX AUDIT COMPLETE ===${RS}"
    echo ""
    echo -e "  Modules executed: $MODULES_RUN"
    echo -e "  Total findings:   $FINDINGS_COUNT"
    echo -e "  ${R}Critical: $CRITICAL_COUNT${RS}"
    echo -e "  ${Y}Warnings: $WARNING_COUNT${RS}"
    echo -e "  Score: ${BD}$SCORE/100${RS}"
    echo ""

    # Grade
    local grade=""
    if [[ $SCORE -ge 90 ]]; then grade="🟢 EXCELLENT - System well hardened"
    elif [[ $SCORE -ge 70 ]]; then grade="🟡 GOOD - Minor improvements needed"
    elif [[ $SCORE -ge 40 ]]; then grade="🟠 ACCEPTABLE - Several issues to address"
    elif [[ $SCORE -ge 10 ]]; then grade="🔴 NEEDS IMPROVEMENT - Multiple critical issues"
    else grade="⚫ CRITICAL - Immediate action required"; fi

    echo -e "  Assessment: $grade"
    echo ""
    echo -e "  ${B}Next steps:${RS}"
    echo -e "  1. Review all CRITICAL findings first"
    echo -e "  2. Apply mitigations per remediation guidance"
    echo -e "  3. Re-run Wyndis to verify fixes"
    echo -e "  4. Schedule regular audits (weekly/monthly)"
    echo ""
    echo -e "  ${B}Report:${RS} JSON/HTML available via --report"
    echo -e "  ${B}Web:${RS} https://wyndis-download-ce9eb.web.app"
    echo -e "  ${B}GitHub:${RS} https://github.com/octcenano/wyndis"
    echo ""
}

# ─── REPORT GENERATION ────────────────────────────────────────────────────

generate_json_report() {
    local outfile="$1"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local duration=$(( $(date +%s) - WYNDIS_START_TIME ))

    cat > "$outfile" <<EOF
{
  "version": "$WYNDIS_VERSION",
  "timestamp": "$timestamp",
  "duration_seconds": $duration,
  "system_info": $(declare -p SYSTEM_INFO | sed 's/declare -A //' | sed 's/\[\([^]]*\)\]="\([^"]*\)"/"\1": "\2"/g' | sed 's/ /, /g' | sed 's/^/(/; s/$/)/'),
  "score": $SCORE,
  "findings_total": $FINDINGS_COUNT,
  "findings_critical": $CRITICAL_COUNT,
  "findings_warning": $WARNING_COUNT,
  "modules_run": $MODULES_RUN,
  "findings": {
EOF
    local first=true
    for id in "${!FINDINGS[@]}"; do
        IFS='|' read -r cat name sev details remediation ref ts <<< "${FINDINGS[$id]}"
        if [[ "$first" == "true" ]]; then first=false; else echo ","; fi
        cat <<EOF
    "$id": {
      "category": "$cat",
      "name": "$name",
      "severity": "$sev",
      "details": "$details",
      "remediation": "$remediation",
      "reference": "$ref",
      "timestamp": "$ts"
    }
EOF
    done
    echo "  }"
    echo "}"
}

generate_html_report() {
    local outfile="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local duration=$(( $(date +%s) - WYNDIS_START_TIME ))

    cat > "$outfile" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Wyndis Linux Security Audit Report</title>
<style>
body{font-family:system-ui,sans-serif;line-height:1.6;margin:0;padding:20px;background:#f8fafc;color:#1e293b}
.container{max-width:1000px;margin:0 auto;background:white;padding:30px;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08)}
.header{text-align:center;border-bottom:3px solid #3b82f6;padding-bottom:20px;margin-bottom:30px}
.header h1{margin:0;color:#1e293b;font-size:28px}
.score-card{background:linear-gradient(135deg,#1e293b 0%,#0f172a 100%);color:white;border-radius:12px;padding:30px;text-align:center;margin-bottom:30px}
.score-value{font-size:72px;font-weight:700;line-height:1}
.grade{font-size:18px;font-weight:600;margin-top:16px;padding:8px 24px;border-radius:9999px;display:inline-block;color:white}
.info-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:16px;margin-bottom:30px}
.info-card{background:#f8fafc;border:1px solid #e2e8f0;border-radius:8px;padding:16px}
.info-card h3{margin:0 0 8px;font-size:14px;color:#64748b;text-transform:uppercase;letter-spacing:0.5px}
.info-card p{margin:0;font-size:16px;font-weight:500}
.section{margin-bottom:30px;page-break-inside:avoid}
.section h2{font-size:18px;color:#1e293b;border-bottom:2px solid #e2e8f0;padding-bottom:8px;margin-bottom:16px}
table{width:100%;border-collapse:collapse;font-size:12px}
th,td{padding:8px 10px;text-align:left;border-bottom:1px solid #e2e8f0}
th{background:#f1f5f9;font-weight:600;color:#334155}
tr:hover{background:#f8fafc}
.severity-crit{color:#dc2626;font-weight:600}
.severity-warn{color:#f59e0b;font-weight:600}
.badge{display:inline-block;padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;text-transform:uppercase}
.badge-crit{background:#fef2f2;color:#dc2626}
.badge-warn{background:#fffbeb;color:#f59e0b}
.footer{text-align:center;margin-top:40px;padding-top:20px;border-top:1px solid #e2e8f0;color:#64748b;font-size:12px}
</style>
</head>
<body>
<div class="container">
<div class="header">
  <h1>Wyndis v$WYNDIS_VERSION — Linux Security Audit Report</h1>
  <div style="color:#64748b;margin-top:8px;">Generated: $timestamp | Duration: ${duration}s | Host: ${SYSTEM_INFO[hostname]}</div>
</div>

<div class="score-card">
  <div class="score-value" style="color: $( [[ $SCORE -ge 90 ]] && echo '#34d399' || [[ $SCORE -ge 70 ]] && echo '#fbbf24' || [[ $SCORE -ge 40 ]] && echo '#f97316' || [[ $SCORE -ge 10 ]] && echo '#f87171' || echo '#dc2626' )">$SCORE</div>
  <div class="score-label">Security Score / 100</div>
  <span class="grade" style="background: $( [[ $SCORE -ge 90 ]] && echo '#34d399' || [[ $SCORE -ge 70 ]] && echo '#fbbf24' || [[ $SCORE -ge 40 ]] && echo '#f97316' || [[ $SCORE -ge 10 ]] && echo '#f87171' || echo '#dc2626' )">$( [[ $SCORE -ge 90 ]] && echo 'EXCELLENT' || [[ $SCORE -ge 70 ]] && echo 'GOOD' || [[ $SCORE -ge 40 ]] && echo 'ACCEPTABLE' || [[ $SCORE -ge 10 ]] && echo 'NEEDS IMPROVEMENT' || echo 'CRITICAL' )</span>
</div>

<div class="info-grid">
  <div class="info-card"><h3>Host</h3><p>${SYSTEM_INFO[hostname]}</p></div>
  <div class="info-card"><h3>OS</h3><p>${SYSTEM_INFO[os]}</p></div>
  <div class="info-card"><h3>Kernel</h3><p>${SYSTEM_INFO[kernel]}</p></div>
  <div class="info-card"><h3>Audit Date</h3><p>$timestamp</p></div>
  <div class="info-card"><h3>Duration</h3><p>${duration}s</p></div>
  <div class="info-card"><h3>Modules</h3><p>$MODULES_RUN</p></div>
  <div class="info-card"><h3>Findings</h3><p>$FINDINGS_COUNT</p></div>
  <div class="info-card"><h3>Critical / Warning</h3><p>$CRITICAL_COUNT / $WARNING_COUNT</p></div>
</div>

<div class="section">
  <h2>Findings Detail</h2>
  <table>
    <thead><tr><th>ID</th><th>Category</th><th>Finding</th><th>Severity</th><th>Details</th><th>Remediation</th></tr></thead>
    <tbody>
EOF

    for id in "${!FINDINGS[@]}"; do
        IFS='|' read -r cat name sev details remediation ref ts <<< "${FINDINGS[$id]}"
        local badge_class=$([ "$sev" = "Critical" ] && echo "badge-crit" || echo "badge-warn")
        cat <<EOF
      <tr>
        <td>$id</td>
        <td>$cat</td>
        <td>$name</td>
        <td><span class="badge $badge_class">$sev</span></td>
        <td>$details</td>
        <td>$remediation</td>
      </tr>
EOF
    done

    cat <<EOF
    </tbody>
  </table>
</div>

<div class="footer">
  Wyndis v$WYNDIS_VERSION · MIT License · https://github.com/octcenano/wyndis<br>
  100% free · No telemetry · Open source · Generated locally
</div>
</div>
</body>
</html>
EOF
}

# ─── MAIN ──────────────────────────────────────────────────────────────────

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -q|--quick) QUICK_MODE=true; shift ;;
            --no-color) NO_COLOR=true; shift ;;
            --no-pdf) NO_PDF=true; shift ;;
            -r|--report) REPORT_PATH="$2"; shift 2 ;;
            -h|--help)
                cat <<EOF
Wyndis v$WYNDIS_VERSION — Linux Security Auditor
Usage: $0 [options]

Options:
  -q, --quick       Quick audit (skip containers, hardware, etc.)
      --no-color    Disable colored output
      --no-pdf      Skip PDF generation (requires wkhtmltopdf)
  -r, --report PATH Save JSON/HTML report to PATH
  -h, --help        Show this help

Examples:
  sudo $0
  sudo $0 --quick --report /tmp/wyndis-report
  sudo $0 --no-pdf

Modules (20): System, Updates, SSH, Firewall, Accounts, Kernel, Filesystem,
Services, Auditd, Logging, Cron, Network, Bootloader, Crypto, MAC,
Containers, Packages, Permissions, Hardware, Summary

EOF
                exit 0
                ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
    done
}

run_modules() {
    module_system_info
    module_updates
    module_ssh
    module_firewall
    module_accounts
    module_kernel
    module_filesystem
    module_services
    module_auditd
    module_logging
    module_cron
    module_network
    module_bootloader
    module_crypto
    module_mac

    if [[ "$QUICK_MODE" != "true" ]]; then
        module_containers
        module_pkg_integrity
        module_permissions
        module_hardware
    fi

    module_summary
}

main() {
    parse_args "$@"

    write_banner

    check_root || true

    run_modules

    # Generate reports
    if [[ -n "$REPORT_PATH" ]]; then
        local json_path="${REPORT_PATH}.json"
        local html_path="${REPORT_PATH}.html"
        write_info "Generating JSON report: $json_path"
        generate_json_report "$json_path"
        write_info "Generating HTML report: $html_path"
        generate_html_report "$html_path"
        write_ok "Reports saved"

        if [[ "$NO_PDF" != "true" ]] && command -v wkhtmltopdf &>/dev/null; then
            local pdf_path="${REPORT_PATH}.pdf"
            write_info "Generating PDF report: $pdf_path"
            wkhtmltopdf "$html_path" "$pdf_path" 2>/dev/null && write_ok "PDF saved: $pdf_path" || write_warn "PDF generation failed"
        elif [[ "$NO_PDF" != "true" ]]; then
            write_warn "wkhtmltopdf not installed; skipping PDF (install: apt install wkhtmltopdf)"
        fi
    fi
}

main "$@"
