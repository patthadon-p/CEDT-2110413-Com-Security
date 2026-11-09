#!/usr/bin/env bash
# Activity 09 - run all nmap scans on ChulaWiFi and save the output.
# Usage (as root, WSL in mirrored networking mode):
#   sudo bash code/run-scans.sh "<label>=<ip>" ["<label>=<ip>" ...]
# e.g.
#   sudo bash code/run-scans.sh "iPhone=10.203.240.12" "Android (friend)=10.203.231.7"
# Env overrides: SUBNET (Problem 1), CAMPUS (Problem 3).
set -u
cd "$(dirname "$0")"
OUT=out
mkdir -p "$OUT"

IFACE_IP=$(ip -4 route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')
SUBNET=${SUBNET:-$(echo "$IFACE_IP" | cut -d. -f1-3).0/24}
CAMPUS=${CAMPUS:-$(echo "$IFACE_IP" | cut -d. -f1-2).0.0/16}
GATEWAY=$(ip -4 route | awk '/^default/ {print $3; exit}')

echo "[*] my IP=$IFACE_IP  subnet=$SUBNET  campus=$CAMPUS  gateway=$GATEWAY"
{ echo "ip=$IFACE_IP"; echo "subnet=$SUBNET"; echo "campus=$CAMPUS"; echo "gateway=$GATEWAY"; } > "$OUT/env.txt"
ip -4 addr > "$OUT/ip-addr.txt"

echo "[*] Problem 1: ping scan of $SUBNET"
nmap -v -sn "$SUBNET" -oN "$OUT/p1-ping.txt" > /dev/null

echo "[*] Problem 2: OS detection"
: > "$OUT/p2-targets.txt"
for spec in "Gateway=$GATEWAY" "$@"; do
  label=${spec%%=*}; ip=${spec#*=}
  echo "$label=$ip" >> "$OUT/p2-targets.txt"
  safe=$(echo "$label" | tr -c 'A-Za-z0-9\n' '_')
  echo "    - $label ($ip)"
  nmap -v --osscan-guess -O "$ip" -oN "$OUT/p2-os-$safe.txt" > /dev/null
  nmap -v -A "$ip" -oN "$OUT/p2-A-$safe.txt" > /dev/null
done

echo "[*] Problem 3: web servers in $CAMPUS (this one takes a while)"
nmap -T4 -p 80,443,8080,8443 --open -sV --script http-title "$CAMPUS" \
     -oA "$OUT/p3-campus-webservers" > /dev/null
grep -E "(80|443|8080|8443)/open" "$OUT/p3-campus-webservers.gnmap" | awk '{print $2}' \
     > "$OUT/p3-webserver-ips.txt"

chown -R "${SUDO_UID:-0}:${SUDO_GID:-0}" "$OUT"
echo "[+] done - results in code/$OUT/"
