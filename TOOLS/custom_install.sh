#!/bin/bash

set -e

function pssh() {
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$@"
}
function pscp() {
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$@"
}

configdir="$HOME/.config/kobra2-tools"
mkdir -p "$configdir"
ip='192.168.1.242'
username='root'
port='22'
if [ -f "$configdir/ssh.cfg" ]; then
    ip="$(cat "$configdir/ssh.cfg" | cut -d: -f1)"
    username="$(cat "$configdir/ssh.cfg" | cut -d: -f2)"
    port="$(cat "$configdir/ssh.cfg" | cut -d: -f3)"
fi
ip="$(dialog --keep-tite --stdout --inputbox 'Printer IP' 10 40 "$ip")"
username="$(dialog --keep-tite --stdout --inputbox 'SSH Username' 10 40 "$username")"
port="$(dialog --keep-tite --stdout --inputbox 'SSH Port' 10 40 "$port")"

echo "$ip:$username:$port" > "$configdir/ssh.cfg"

# Check the remote SWUpdate cert
echo "Checking the printer swupdate public key"
md5sum_local=$(md5sum RESOURCES/KEYS/swupdate_public.pem | awk '{ print $1 }')
echo "MD5 Local : $md5sum_local"
md5sum_remote=$(pssh -p $port $username@$ip "md5sum /etc/swupdate_public.pem" | awk '{ print $1 }')
echo "MD5 Remote: $md5sum_remote"

if [[ "$md5sum_remote" != "$md5sum_local" ]]; then
    echo "MD5 checksums differ! Make sure to replace certs. Follow the docs/ROOT.md guide."
    exit 2
fi

# SCP file transfer
echo "Uploading firmware..."
pscp -P $port update/update.swu $username@$ip:/mnt/UDISK/update.swu

# MD5 Calculation
md5sum_local=$(md5sum update/update.swu | awk '{ print $1 }')
echo "MD5 Local : $md5sum_local"
md5sum_remote=$(pssh -p $port $username@$ip "md5sum /mnt/UDISK/update.swu" | awk '{ print $1 }')
echo "MD5 Remote: $md5sum_remote"
if [[ "$md5sum_remote" != "$md5sum_local" ]]; then
    echo "Firmware MD5 checksums differ! Upload must have failed. Retry."
    pssh -p $port $username@$ip 'rm -f /mnt/UDISK/update.swu'
    exit 3
fi

# Getting boot partition and updating firmware
current_boot_partition=$(pssh -p $port $username@$ip "fw_printenv boot_partition" | awk -F= '{ print $2 }' | tr -d '[:space:]')
boot_partition="now_B_next_A"
if [[ "$current_boot_partition" == "bootA" ]]; then
    boot_partition="now_A_next_B"
fi
# Update
echo "Updating..."
echo pssh -p $port $username@$ip "swupdate_cmd.sh -i /mnt/UDISK/update.swu -e "stable,${boot_partition}" -k /etc/swupdate_public.pem"
echo "SUCCESS!"
exit 0
