#!/bin/bash

set -e

tools_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
project_root="$( dirname "$tools_dir" )"

# Source the utils.sh file
source "$project_root/TOOLS/helpers/utils.sh" "$project_root"

configdir="$HOME/.config/kobra2-tools"
mkdir -p "$configdir"

check_tools 'python3 md5sum dialog ssh'

function pssh() {
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile="$configdir/ssh.known_hosts" -i "$project_root/RESOURCES/KEYS/id_rsa" -p $port $username@$ip "$@"
}

export ip='192.168.1.242'
export username='root'
export port='22'
if [ -f "$configdir/ssh.cfg" ]; then
    ip="$(cat "$configdir/ssh.cfg" | cut -d: -f1)"
    username="$(cat "$configdir/ssh.cfg" | cut -d: -f2)"
    port="$(cat "$configdir/ssh.cfg" | cut -d: -f3)"
fi
ip="$(dialog --keep-tite --stdout --inputbox 'Printer IP' 10 40 "$ip")"
username="$(dialog --keep-tite --stdout --inputbox 'SSH Username' 10 40 "$username")"
port="$(dialog --keep-tite --stdout --inputbox 'SSH Port' 10 40 "$port")"

echo "$ip:$username:$port" > "$configdir/ssh.cfg"
ssh-keyscan -t rsa "$ip" > "$configdir/ssh.known_hosts"

# Check the remote SWUpdate cert
echo -e "${PURPLE}Checking the printer swupdate public key${NC}"
var_local=$(md5sum RESOURCES/KEYS/swupdate_public.pem | awk '{ print $1 }')
echo -e "${PURPLE}MD5 Local :${NC} $var_local"
var_remote=$(pssh "md5sum /etc/swupdate_public.pem" | awk '{ print $1 }')
echo -e "${PURPLE}MD5 Remote:${NC} $var_remote"

if [[ "$var_remote" != "$var_local" ]]; then
    echo -e "${RED}MD5 checksums differ! Make sure to replace certs. Follow the docs/ROOT.md guide.${NC}"
    exit 2
fi
echo -e "${GREEN}Printer's swupdate public key is valid, and will accept custom firmware.${NC}"

echo -e "${PURPLE}Uploading firmware...${NC}"
# dropbear ssh server doesn't support SCP file transfer
python3 -m http.server 9000 --bind 0.0.0.0 &
trap 'jobs -p | xargs -r kill' EXIT
myip="$(hostname -I | awk '{ print $1 }')"
pssh "wget -O /mnt/UDISK/update.swu http://$myip:9000/update/update.swu"
jobs -p | xargs -r kill

# MD5 Calculation
var_local=$(md5sum update/update.swu | awk '{ print $1 }')
echo -e "${PURPLE}MD5 Local :${NC} $var_local"
var_remote=$(pssh "md5sum /mnt/UDISK/update.swu" | awk '{ print $1 }')
echo -e "${PURPLE}MD5 Remote:${NC} $var_remote"
if [[ "$var_remote" != "$var_local" ]]; then
    echo -e "${RED}Firmware MD5 checksums differ! Upload must have failed. Retry.${NC}"
    pssh 'rm -f /mnt/UDISK/update.swu'
    exit 3
fi
echo -e "${GREEN}Custom firmware loaded correctly.${NC}"

# Getting boot partition and updating firmware
current_boot_partition=$(pssh "fw_printenv boot_partition" | awk -F= '{ print $2 }' | tr -d '[:space:]')
boot_partition="now_B_next_A"
if [[ "$current_boot_partition" == "bootA" ]]; then
    boot_partition="now_A_next_B"
fi
echo -e "${PURPLE}Boot partition:${NC} $boot_partition"

# Update
echo -e "${RED}Updating...${NC}"
pssh "swupdate_cmd.sh -i /mnt/UDISK/update.swu -e stable,${boot_partition} -k /etc/swupdate_public.pem"
echo -e "${GREEN}SUCCESS! Firmware updated.${NC}"
exit 0
