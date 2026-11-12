import Quickshell
import Quickshell.Wayland
import qs.services

// Uses the Wayland session-lock protocol: if the shell ever crashes while locked,
// the compositor keeps the screen locked.
Scope {
    WlSessionLock {
        locked: Lock.locked
        LockSurface {}
    }
}
