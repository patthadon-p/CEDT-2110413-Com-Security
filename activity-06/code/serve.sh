#!/bin/bash
# Emulate the victim as an internet service on tcp/60000.
# OpenBSD netcat has no -e, so we wire stdin/stdout with a FIFO.
# stderr is redirected onto the connection so the client can read the
# leaked &shell (the program prints the addresses on stderr).
FIFO=$(mktemp -u); mkfifo "$FIFO"
trap 'rm -f "$FIFO"' EXIT
nc -l 60000 < "$FIFO" | ./victim-2020 > "$FIFO" 2>&1
