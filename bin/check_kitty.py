#!/usr/bin/env python3
"""
Description: Checks if the current terminal emulator supports the Kitty graphics protocol.
Usage: check_kitty.py [timeout_seconds]
Exit Code: 0 if supported, 1 otherwise.
"""

import fcntl
import os
import sys
import termios
import time


def set_nonblocking(fd: int) -> None:
    flags = fcntl.fcntl(fd, fcntl.F_GETFL)
    fcntl.fcntl(fd, fcntl.F_SETFL, flags | os.O_NONBLOCK)


def detect_kitty_graphics(timeout: float = 0.5) -> bool:
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    new_settings = termios.tcgetattr(fd)

    # Configure terminal for raw input
    new_settings[3] = new_settings[3] & ~termios.ICANON & ~termios.ECHO & ~termios.ISIG
    new_settings[6][termios.VMIN] = 1
    new_settings[6][termios.VTIME] = 0

    try:
        termios.tcsetattr(fd, termios.TCSANOW, new_settings)
        set_nonblocking(fd)

        # Flush existing input
        try:
            while os.read(fd, 1024):
                pass
        except OSError:
            pass

        # Send Kitty graphics query
        # 'a=q,t=d,f=24' queries for graphics transmission support
        query = b"\x1b_Gi=31,s=1,v=1,a=q,t=d,f=24;AAAA\x1b\\\x1b[c"
        sys.stdout.buffer.write(query)
        sys.stdout.flush()

        start_time = time.time()
        response = b""

        while time.time() - start_time < timeout:
            try:
                data = os.read(fd, 1024)
                if not data:
                    time.sleep(0.01)
                    continue
                response += data
                # Check for Kitty graphics response prefix
                if b"\x1b_Gi=31;" in response:
                    return True
            except OSError:
                time.sleep(0.01)

        return False

    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)


if __name__ == "__main__":
    timeout_val = 0.5
    if len(sys.argv) > 1:
        try:
            timeout_val = float(sys.argv[1])
        except ValueError:
            pass

    if detect_kitty_graphics(timeout=timeout_val):
        sys.exit(0)
    else:
        sys.exit(1)

