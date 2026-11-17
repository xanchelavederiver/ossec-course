#include <stdio.h>
#include <stdlib.h>


static char str[32] = "/bin/sh";


int gadgetgarden()
{
	asm(
		"syscall    \n\t"
		"popq %rdx  \n\t"
		"popq %rax  \n\t"
		"ret        \n\t"
		"popq %rdi  \n\t"
		"popq %rsi  \n\t"
		"ret");
	return 0;
}


int copy(char* f_name)
{
	char buf[32];
	FILE* fd = fopen(f_name, "rb");
	fread(buf, 1, 200, fd);
	return 0;
}


int main(int argc, char* argv[])
{
	copy(argv[1]);
	return 0;
}

