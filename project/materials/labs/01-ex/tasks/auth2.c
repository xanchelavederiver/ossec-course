#include <stdio.h>
#include <stdlib.h>
#include <string.h>


int check_auth(char* passwd)
{
	int auth_flag = 0;
	char true_passwords[] = "@$ew4rtg3#$5sdf25";
	char password_buffer[64] = {0};

	strcpy(password_buffer, passwd);

	if (strcmp(password_buffer, true_passwords) == 0)
		auth_flag = 1;

	return auth_flag;
}


int main(int argc, char* argv[])
{
	if (argc < 2)
	{
		printf("Usage: %s <password>\n", argv[0]);
		return 0;
	}

	if (check_auth(argv[1]) == 1)
		printf("Access granted!\n");
	else
		printf("Access denied!\n");

	return 0;
}
