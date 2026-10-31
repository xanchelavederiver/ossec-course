@@ 26
#define RPP_ECHO_OFF    0x00		/* Turn off echo (default). */
#define RPP_ECHO_ON     0x01		/* Leave echo on. */
#define RPP_REQUIRE_TTY 0x02		/* Fail if there is no tty. */
@@ 32
#define RPP_STDIN       0x20		/* Read from stdin, not /dev/tty */
@@ 42
char * readpassphrase(const char *, char *, size_t, int);
