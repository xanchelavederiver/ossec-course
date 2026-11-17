make all: auth overflow format

auth: auth.c
	gcc -g -m32 -z execstack -fno-PIC -fno-stack-protector auth.c -o auth -no-pie

overflow: overflow.c
	gcc -g -m32 -z execstack -fno-PIC -fno-stack-protector overflow.c -o overflow -no-pie

format: format.c
	gcc -g -m32 -z execstack -fno-PIC -fno-stack-protector -Wno-format-security format.c -o format -no-pie


# exercises: auth2.c overflow2.c format2.c
#	gcc -g -m32 -z execstack -fno-PIC -fno-stack-protector auth2.c -o auth2 -no-pie
#	gcc -g -m32 -z execstack -fno-PIC -fno-stack-protector overflow2.c -o overflow2 -no-pie
#	gcc -g -m32 -z execstack -fno-PIC -fno-stack-protector -Wno-format-security format2.c -o format2 -no-pie
