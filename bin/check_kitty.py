#!/usr/bin/env python3
import fcntl
import os
import sys
import termios
import time


def set_nonblocking(fd):
    flags = fcntl.fcntl(fd, fcntl.F_GETFL)
    fcntl.fcntl(fd, fcntl.F_SETFL, flags | os.O_NONBLOCK)


def detect_kitty_graphics(timeout=0.5):
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    new = termios.tcgetattr(fd)
    new[3] = new[3] & ~termios.ICANON & ~termios.ECHO & ~termios.ISIG
    new[6][termios.VMIN] = 1
    new[6][termios.VTIME] = 0
    termios.tcsetattr(fd, termios.TCSANOW, new)
    set_nonblocking(fd)
    try:
        try:
            os.read(fd, 1024)
        except OSError:
            pass
        query = "\x1b_Gi=31,s=1,v=1,a=q,t=d,f=24;AAAA\x1b\\\x1b[c"
        sys.stdout.buffer.write(query.encode("ascii"))
        sys.stdout.flush()
        start_time = time.time()
        response = b""
        while time.time() - start_time < timeout:
            try:
                data = os.read(fd, 1024)
                response += data
            except OSError:
                time.sleep(0.01)
        # Check for graphics query response (even if it's an error response)
        if b"\x1b_Gi=31;" in response:
            return True
        return False
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)


if __name__ == "__main__":
    if detect_kitty_graphics():
        sys.exit(0)
    else:
        sys.exit(1)
