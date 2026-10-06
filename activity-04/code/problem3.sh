#!/usr/bin/env bash
# Problem 3 (Mode in Block Cipher): encrypt a 1-bit PBM image with AES-256 in ECB and in
# modes with an IV / chaining / feedback, then look at how much of the picture survives.
#
# Usage: bash problem3.sh   (needs ImageMagick 6 `convert`, OpenSSL and python3)
set -euo pipefail

cd "$(dirname "$0")"
OUT="problem3"   # working files: PBM images, raw pixel data (.x) and cipher texts
FIG="../images"  # PNGs used in the report
mkdir -p "$OUT" "$FIG"

KEY="4d79af6618ab04423bd8e0e06f95f0c7156256d02e50380b1ed098d6adef1115"  # AES-256 key (256 bits, hex)
IV="ecd0a4e1eb4570bbd396dbcccc1a0825"                                  # 128-bit IV / initial counter
SIZE=2048  # > 2000 pixels; 2048 bits per row = 256 bytes = exactly 16 AES blocks

section() { printf '\n===== %s =====\n' "$1"; }

# "<distinct blocks> <occurrences of the most common block>" of a file cut into 16-byte blocks
block_stats() {
    xxd -p -c 16 "$1" | sort | uniq -c | sort -rn | awk 'NR == 1 { top = $1 } END { print NR, top }'
}

# --------------------------------------------------------------------------------------------
section "(a) Source image -> 1-bit PBM"
# A 2048x2048 picture: large flat areas (title, padlock) plus a photo-like dithered texture.
convert -size 420x760 -seed 2110413 plasma:fractal -colorspace Gray \
    -dither FloydSteinberg -monochrome "$OUT/texture.png"
convert -size ${SIZE}x${SIZE} xc:white \
    -font DejaVu-Sans-Bold -pointsize 250 -fill black -gravity north -annotate +0+110 "CEDT 2110413" \
    -gravity northwest \
    -fill none -stroke black -strokewidth 120 -draw "arc 700,560 1348,1200 180,360" \
    -draw "line 700,880 700,1060" -draw "line 1348,880 1348,1060" \
    -stroke none -fill black -draw "roundrectangle 560,1000 1488,1800 70,70" \
    -fill white -draw "circle 1024,1280 1024,1370" -draw "polygon 980,1320 1068,1320 1110,1620 938,1620" \
    "$OUT/texture.png" -geometry +70+1020 -composite \
    -fill black -pointsize 150 -annotate +1560+1200 "AES" \
    "$OUT/image.png"

# Handout step (ImageMagick 7 spells it `magick convert`); -threshold keeps pixels pure black/white
convert "$OUT/image.png" -resize ${SIZE}x${SIZE} -threshold 50% "$OUT/org.pbm"
identify "$OUT/org.pbm"

# Second, different image with the same size (only used for the IV-reuse experiment)
convert -size ${SIZE}x${SIZE} xc:white -font DejaVu-Sans-Bold -fill black -gravity center \
    -pointsize 330 -annotate +0-250 "TOP" -annotate +0+150 "SECRET" \
    -fill none -stroke black -strokewidth 60 -draw "circle 1024,1024 1024,120" \
    -threshold 50% "$OUT/org2.pbm"

# --------------------------------------------------------------------------------------------
section "(b) Take out the header"
# `head`/`tail` instead of vi: an editor may add a trailing newline or mangle the binary data.
head -n 2 "$OUT/org.pbm" > "$OUT/header.txt"
HEADER_BYTES=$(wc -c < "$OUT/header.txt")
tail -c +$((HEADER_BYTES + 1)) "$OUT/org.pbm" > "$OUT/org.x"
tail -c +$((HEADER_BYTES + 1)) "$OUT/org2.pbm" > "$OUT/org2.x"
echo "header ($HEADER_BYTES bytes):"
xxd "$OUT/header.txt"
echo "org.pbm = $(wc -c < "$OUT/org.pbm") bytes, org.x (pixels only) = $(wc -c < "$OUT/org.x") bytes"
echo "first 3 blocks of org.x:"
xxd -c 16 -l 48 "$OUT/org.x"

# --------------------------------------------------------------------------------------------
section "(c) Encrypt with AES-256-ECB (no padding, no salt)"
openssl enc -aes-256-ecb -e -in "$OUT/org.x" -out "$OUT/enc-ecb.x" -K "$KEY" -nopad -nosalt
echo "enc-ecb.x = $(wc -c < "$OUT/enc-ecb.x") bytes"
echo "first 3 blocks of enc-ecb.x:"
xxd -c 16 -l 48 "$OUT/enc-ecb.x"

# --------------------------------------------------------------------------------------------
section "(d) Pad the header back"
cat "$OUT/header.txt" "$OUT/enc-ecb.x" > "$OUT/ecb.pbm"
identify "$OUT/ecb.pbm"

# --------------------------------------------------------------------------------------------
section "(e) Modes with IV, chaining or feedback"
for mode in cbc cfb ofb ctr; do
    openssl enc -aes-256-$mode -e -in "$OUT/org.x" -out "$OUT/enc-$mode.x" -K "$KEY" -iv "$IV" -nopad -nosalt
    cat "$OUT/header.txt" "$OUT/enc-$mode.x" > "$OUT/$mode.pbm"
    # Round trip: decrypting must give back the original pixels
    openssl enc -aes-256-$mode -d -in "$OUT/enc-$mode.x" -K "$KEY" -iv "$IV" -nopad -nosalt | cmp -s - "$OUT/org.x"
    echo "aes-256-$mode: encrypted $(wc -c < "$OUT/enc-$mode.x") bytes, decrypts back to org.x: OK"
done
openssl enc -aes-256-ecb -d -in "$OUT/enc-ecb.x" -K "$KEY" -nopad -nosalt | cmp -s - "$OUT/org.x"
echo "aes-256-ecb: decrypts back to org.x: OK"
echo "first 3 blocks of enc-cbc.x:"
xxd -c 16 -l 48 "$OUT/enc-cbc.x"

# --------------------------------------------------------------------------------------------
section "Block statistics (16-byte blocks)"
printf '%-12s %8s %10s %14s\n' "file" "blocks" "distinct" "most common"
for f in org ecb cbc cfb ofb ctr; do
    [[ $f == org ]] && file="$OUT/org.x" || file="$OUT/enc-$f.x"
    read -r distinct top < <(block_stats "$file")
    printf '%-12s %8d %10d %14d\n' "$f" $(( $(wc -c < "$file") / 16 )) "$distinct" "$top"
done

# --------------------------------------------------------------------------------------------
section "Extra: reusing the same key and IV"
# CBC is deterministic for a fixed key and IV: the same image gives the same cipher text again.
openssl enc -aes-256-cbc -e -in "$OUT/org.x" -out "$OUT/enc-cbc-again.x" -K "$KEY" -iv "$IV" -nopad -nosalt
cmp -s "$OUT/enc-cbc.x" "$OUT/enc-cbc-again.x" && echo "CBC, same key + IV, same image twice: identical cipher texts"

# CTR with a reused key and IV: C1 xor C2 = P1 xor P2, so both pictures leak without the key.
openssl enc -aes-256-ctr -e -in "$OUT/org2.x" -out "$OUT/enc2-ctr.x" -K "$KEY" -iv "$IV" -nopad -nosalt
python3 - "$OUT/enc-ctr.x" "$OUT/enc2-ctr.x" "$OUT/ctr-xor.x" <<'PY'
import sys
a, b = (open(path, "rb").read() for path in sys.argv[1:3])
x = (int.from_bytes(a, "big") ^ int.from_bytes(b, "big")).to_bytes(len(a), "big")
open(sys.argv[3], "wb").write(x)
PY
cat "$OUT/header.txt" "$OUT/enc2-ctr.x" > "$OUT/ctr2.pbm"
cat "$OUT/header.txt" "$OUT/ctr-xor.x" > "$OUT/ctr-xor.pbm"
python3 - "$OUT/org.x" "$OUT/org2.x" "$OUT/ctr-xor.x" <<'PY'
import sys
p1, p2, x = (open(path, "rb").read() for path in sys.argv[1:4])
same = (int.from_bytes(p1, "big") ^ int.from_bytes(p2, "big")).to_bytes(len(p1), "big") == x
print("CTR, same key + IV, two images: C1 xor C2 == P1 xor P2 ->", same)
PY

# --------------------------------------------------------------------------------------------
section "Figures"
# Box-filter downscaling averages 4x4 pixels, so the eye sees the structure, not single bits.
for f in org ecb cbc cfb ofb ctr org2 ctr2 ctr-xor; do
    convert "$OUT/$f.pbm" -filter Box -resize 512x512 "$FIG/p3-$f.png"
done
# Native-resolution zoom (256x256 pixels around the padlock's top-left corner, shown 2x)
for f in org ecb cbc; do
    convert "$OUT/$f.pbm" -crop 256x256+432+872 +repage -filter point -resize 200% "$FIG/p3-$f-zoom.png"
done
ls -l "$FIG"/p3-*.png | awk '{ print $5, $9 }'
