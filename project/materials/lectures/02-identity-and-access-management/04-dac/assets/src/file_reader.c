#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    int fd;
    char buf[4096];
    ssize_t n;

    if (argc != 2) {
        fprintf(stderr, "Usage: %s <file>\n", argv[0]);
        return 1;
    }

    /* Открываем файл на чтение и запись */
    fd = open(argv[1], O_RDWR);
    if (fd == -1) {
        fprintf(stderr, "Error opening file '%s': %s\n", argv[1], strerror(errno));
        return 1;
    }

    printf("File '%s' opened successfully. Contents:\n\n", argv[1]);
    while ((n = read(fd, buf, sizeof(buf))) > 0)
        fwrite(buf, 1, (size_t)n, stdout);

    printf("\nFile reading completed.\n");
    close(fd);
    return 0;
}
