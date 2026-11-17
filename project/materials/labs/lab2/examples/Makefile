all: 1.c 2.c 3.c 4.c 5.c 6.c
	gcc -zexecstack -o 1_execstack 1.c
	gcc -o 1_nonexecstack 1.c
	gcc -o 2 2.c
	gcc -o 3 3.c
	gcc -o 4 4.c
	gcc -fno-stack-protector -fno-PIC 5.c -o 5 -no-pie
	gcc -fno-stack-protector 6.c -o 6 -no-pie
