#include <stdio.h>
#include <stdlib.h>


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

