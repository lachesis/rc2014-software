#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <termios.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <sys/ioctl.h>
#include <signal.h>

/*
 * ioctl          set or clear the RTS/DTR lines (once per execution)
 *
 * Usage:       ioctl <device> <1 or 0 (RTS)> <1 or 0 (DTR)>
 *              For example, rts /dev/ttyS1 1 1 to set RTS and DTR line on ttyS1
 *
 * Author:      Adrian Pike, but really just a minor modification of:
 *              Ben Dugan, which in turn is a modification of:
 *              Harvey J. Stein <hjstein@math.huji.ac.il>
 *              UPS-Howto, which in turn is:
 *              (but really just a minor modification of Miquel van
 *              Smoorenburg's <miquels@drinkel.nl.mugnet.org> powerd.c
 *
 * Version:     1.0 2009
 *
 */

/* Main program. */
int main(int argc, char **argv)
{
    int fd;

    int rtsEnable;
    int dtrEnable;
    int flags;

    if (argc < 2) {
        fprintf(stderr, "Usage: z80_reset <device>\n");
        exit(1);
    }

    /* Open monitor device. */
    if ((fd = open(argv[1], O_RDWR | O_NDELAY)) < 0) {
        fprintf(stderr, "upscheck: %s: %s\n", argv[1], sys_errlist[errno]);
        exit(1);}

    /* Get the current flags */
    ioctl(fd, TIOCMGET, &flags);

    /* Set DTR to enabled (active LOW, just like our reset) */
    flags |= TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);

    /* Sleep for 500ms */
    nanosleep((const struct timespec[]){{0, 500000000L}}, NULL);

    /* Set DTR to disabled (HIGH) */
    flags &= ~TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);

    /* Close and return */
    close(fd);
    return 0;
}
