#include <stdio.h>
#include <stdlib.h>
#include <string.h>


int check_auth(char* passwd)
{
	char password_buffer[64] = {0};

	printf("password_buffer is at address: %p\n", password_buffer);
	strcpy(password_buffer, passwd);

	if (strcmp(password_buffer, "fqwe3452fwertg") == 0)
		return 1;
	else if (strcmp(password_buffer, "@$ew4rtg3#$5sdf25") == 0)
		return 1;
	else
		return 0;
}


int main(int argc, char* argv[])
{
	if (argc < 2)
	{
		printf("Usage: %s <password>\n", argv[0]);
		return 0;
	}

	if (check_auth(argv[1]))
		printf("Access granted!\n");
	else
		printf("Access denied!\n");

	return 0;
}
