#include <stdio.h>
#include <stdlib.h>
#include <string.h>


int check_auth(char* username, char* passwd)
{
	static int auth_flag = 0x0;
	char password_buffer[64] = {0};

	strncpy(password_buffer, passwd, 64);
	printf(username);
	printf(", password_buffer is at address: %p\n", password_buffer);

	if (strcmp(password_buffer, "fqwe3452fwertg") == 0)
		auth_flag = 1;
	else if (strcmp(password_buffer, "@$ew4rtg3#$5sdf25") == 0)
		auth_flag =1;

	printf("DEBUG: auth_flag (%p) = %d\n", &auth_flag, auth_flag);
	return auth_flag;
}


int main(int argc, char* argv[])
{
	if (argc < 3)
	{
		printf("Usage: %s <user> <password>\n", argv[0]);
		return 0;
	}

	if (check_auth(argv[1], argv[2]))
		printf("Access granted!\n");
	else
		printf("Access denied!\n");

	return 0;
}
