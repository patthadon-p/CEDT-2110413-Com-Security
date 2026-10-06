#!/bin/bash
# Usage: ./get_chain.sh <host>
# Saves the server certificate as <host>.cert and the intermediate(s) it sends as <host>_intermediate.cert
host=$1
openssl s_client -connect "$host:443" -servername "$host" -showcerts </dev/null 2>/dev/null \
  | awk '/BEGIN CERT/{n++} n{print > "cert" n ".tmp"} /END CERT/{n+=0}' 
mv cert1.tmp "$host.cert"
cat cert[2-9].tmp > "${host}_intermediate.cert" 2>/dev/null; rm -f cert*.tmp
