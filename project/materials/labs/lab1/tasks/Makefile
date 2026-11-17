make all: auth2 overflow2 format2

auth2: auth2.c
	gcc -g -m32 -z execstack -fno-PIC -fno-stack-protector auth2.c -o auth2 -no-pie

overflow2: overflow2.c
	gcc -g -m32 -z execstack -fno-PIC -fno-stack-protector overflow2.c -o overflow2 -no-pie

format2: format2.c
	gcc -g -m32 -z execstack -fno-PIC -fno-stack-protector -Wno-format-security format2.c -o format2 -no-pie
