int main(int argc, char* argv[])
{
	char bin_sh[] = "/bin/sh";
	char* args[2] = {bin_sh, 0};
	asm(
	"movq %0, %%rdi    \n\t"
	"movq %1, %%rsi    \n\t"
	"xorq %%rdx, %%rdx \n\t"
	"movl $0x3b, %%eax \n\t"
	"syscall"
	: /* no output */
	: "b" (bin_sh), "a" (args)
	: 
	);
	return 0;
}

