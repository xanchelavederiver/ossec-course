#include <stdio.h>
#include <stdlib.h>


int gadgetgarden()
{
	asm(
	"syscall           \n\t"
	"xorq %rax, %rax   \n\t"
	"popq %rdx         \n\t"
	"ret               \n\t"
	"inc %rax          \n\t"
	"ret               \n\t"
	"movq %rsi, (%rdi) \n\t"
	"ret               \n\t"
	"popq %rsi         \n\t"
	"popq %rdi         \n\t"
	"ret");
	return 0;
}


int copy(char* f_name)
{
	char buf[32];
	FILE* fd = fopen(f_name, "rb");
	fread(buf, 1, 800, fd);
	return 0;
}


int main(int argc, char* argv[])
{
	copy(argv[1]);
	return 0;
}
