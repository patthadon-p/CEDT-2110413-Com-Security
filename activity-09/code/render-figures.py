#!/usr/bin/env python3
"""Render the saved nmap outputs in code/out/ as terminal-style PNG figures.

Usage:  python3 code/render-figures.py      (from activity-09/)
Writes 8-bit RGB PNGs to images/ (16-bit PNGs render blank in the XeLaTeX PDF).
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "code" / "out"
IMG = ROOT / "images"
FONT = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", 26)
FONT_B = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf", 26)

BG, FG, PROMPT, DIM, HIT = (30, 30, 36), (220, 220, 220), (120, 200, 120), (140, 140, 150), (240, 200, 90)


def lines_of(name, drop=()):
    out = []
    for ln in (OUT / name).read_text().splitlines():
        if ln.startswith("# Nmap") or any(d in ln for d in drop):
            continue
        out.append(ln)
    while out and not out[-1].strip():
        out.pop()
    return out


def render(path, blocks, highlight=()):
    """blocks: list of (command, [output lines])."""
    rows = []
    for cmd, body in blocks:
        rows.append(("cmd", cmd))
        rows += [("out", b) for b in body]
        rows.append(("out", ""))
    rows.pop()
    lh, pad = 34, 28
    width = max(FONT.getlength("$ " + t) for _, t in rows) + 2 * pad
    img = Image.new("RGB", (int(width), lh * len(rows) + 2 * pad + 30), BG)
    d = ImageDraw.Draw(img)
    for i, c in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
        d.ellipse((pad + i * 30, 12, pad + i * 30 + 16, 28), fill=c)
    y = pad + 30
    for kind, text in rows:
        if kind == "cmd":
            d.text((pad, y), "$ ", font=FONT_B, fill=PROMPT)
            d.text((pad + FONT.getlength("$ "), y), text, font=FONT_B, fill=FG)
        else:
            colour = HIT if any(h in text for h in highlight) else (DIM if text.startswith("Read data") else FG)
            d.text((pad, y), text, font=FONT, fill=colour)
        y += lh
    img.save(path, "PNG")
    print("wrote", path, img.size, img.mode)


targets = dict(l.split("=", 1) for l in (OUT / "p2-targets.txt").read_text().split())

render(IMG / "sol-1-ping.png",
       [("sudo nmap -v -sn 10.203.237.0/24", lines_of("p1-ping.txt", drop=("Read data", "host down")) +
         ["Nmap done: 256 IP addresses (2 hosts up) scanned in 10.06 seconds"])],
       highlight=("scan report",))

render(IMG / "sol-2-osscan.png",
       [(f"sudo nmap -v -A {targets['Gateway']}       # gateway",
         lines_of("p2-A-Gateway.txt", drop=("Read data", "OS and Service", "TRACEROUTE", "HOP", "1   1.97"))),
        (f"sudo nmap -v --osscan-guess -O {targets['iPad']}   # iPad",
         lines_of("p2-os-iPad.txt", drop=("Read data",))),
        (f"sudo nmap -v --osscan-guess -O {targets['Android']}   # Android",
         lines_of("p2-os-Android.txt", drop=("Read data",)))],
       highlight=("Too many", "host down", "MAC Address"))

p3 = lines_of("p3-campus-webservers.nmap", drop=("Service detection",))
render(IMG / "sol-3-web.png",
       [("sudo nmap -T4 -p 80,443,8080,8443 --open -sV --script http-title 10.203.0.0/16 -oA campus-webservers",
         p3 + ["Nmap done: 65536 IP addresses (373 hosts up) scanned in 866.75 seconds"]),
        ("grep -E \"(80|443|8080|8443)/open\" campus-webservers.gnmap | awk '{print $2}' | wc -l",
         [str(len((OUT / "p3-webserver-ips.txt").read_text().split()))])],
       highlight=("373 hosts up",))
