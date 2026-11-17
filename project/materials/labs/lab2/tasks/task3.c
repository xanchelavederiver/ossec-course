#include <stdio.h>
#include <stdlib.h>


int gadgetgarden()
{
	asm(
	"popq %rdi         \n\t"
	"popq %rsi         \n\t"
	"ret               \n\t"
	"syscall           \n\t"
	"xorq %rax, %rax   \n\t"
	"popq %rdx         \n\t"
	"ret               \n\t"
	"inc %rax          \n\t"
	"ret               \n\t"
	"movq %rsi, (%rdi) \n\t"
	"ret               \n\t");
	return 0;
}


int copy()
{
	char buf[32];
	printf("Tell me your name: \n");
	scanf("%s", (char*)&buf);
	printf(buf);
	printf(", enter a file to read:\n");
	scanf("%s", (char*)&buf);
	printf("Reading %s\n...", buf);
	FILE* fd = fopen(buf, "rb");
	fread(buf, 1, 800, fd);
	return 0;
}


int main(int argc, char* argv[])
{
	copy();
	return 0;
}
