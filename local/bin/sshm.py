#!/usr/bin/env python3


import os
import sys
import json
import shutil
import subprocess
import argparse
from pathlib import Path
from datetime import datetime

# Paths
CACHE_DIR = Path.home() / ".cache" / "sshm"
KEYS_DIR = CACHE_DIR / "keys"
CONFIG_FILE = CACHE_DIR / "servers.json"

CACHE_DIR.mkdir(parents=True, exist_ok=True)
KEYS_DIR.mkdir(parents=True, exist_ok=True)


# Config helpers
def load_servers() -> dict:
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE) as f:
            return json.load(f)
    return {}


def save_servers(servers: dict):
    with open(CONFIG_FILE, "w") as f:
        json.dump(servers, f, indent=2)
    CONFIG_FILE.chmod(0o600)


def server_label(name: str, info: dict) -> str:
    """Format a single fzf line for a server entry."""
    auth = f"key:{Path(info['key']).name}" if info.get("key") else "password"
    port = f":{info['port']}" if info.get("port", 22) != 22 else ""
    last = info.get("last_connected", "never")
    return (
        f"{name:<20}  {info['user']}@{info['host']}{port:<22}  "
        f"[{auth:<25}]  last: {last}"
    )


# Key management
def import_key(src: str) -> Path:
    """Copy a key file into the cache and return its new path."""
    src_path = Path(src).expanduser().resolve()
    if not src_path.exists():
        die(f"Key file not found: {src}")
    dest = KEYS_DIR / src_path.name
    if dest.exists() and dest.read_bytes() == src_path.read_bytes():
        return dest
    shutil.copy2(src_path, dest)
    dest.chmod(0o600)
    print(f"  ✓ Key imported → {dest}")
    return dest


# Add / edit
def cmd_add(args):
    """Add a server interactively or via flags."""
    servers = load_servers()

    host = args.host or prompt("Host / IP")
    user = args.user or prompt("Username", default="ubuntu")
    port = args.port or prompt_int("Port", default=22)

    # Auth
    if args.key:
        key_path = str(import_key(args.key))
        auth_type = "key"
    elif args.password_auth:
        key_path = None
        auth_type = "password"
    else:
        choice = prompt(
            "Auth type  [k]ey / [p]assword",
            default="k",
            choices=["k", "p", "key", "password"],
        ).lower()
        if choice in ("k", "key"):
            raw = prompt("Path to private key")
            key_path = str(import_key(raw))
            auth_type = "key"
        else:
            key_path = None
            auth_type = "password"

    # Derive a default name
    default_name = args.name or f"{user}@{host}"
    name = prompt("Nickname", default=default_name)

    if name in servers:
        overwrite = prompt(
            f"  '{name}' already exists — overwrite?",
            default="n",
            choices=["y", "n"],
        )
        if overwrite.lower() != "y":
            print("Aborted.")
            return

    servers[name] = {
        "host": host,
        "user": user,
        "port": port,
        "key": key_path,
        "auth_type": auth_type,
        "added": datetime.now().isoformat(timespec="seconds"),
        "last_connected": None,
    }
    save_servers(servers)
    print(f"\n  ✓ Server '{name}' saved.")


# Quick-import from a raw ssh command
def cmd_import(args):
    """
    Parse a raw ssh command and store it.
    e.g.  sshm import 'ssh -i Flintkey.pem flint@3.226.153.116'
          sshm import -- ssh -i Flintkey.pem flint@3.226.153.116
    """
    raw_parts = args.command
    if not raw_parts:
        die("Provide the ssh command, e.g.: sshm import ssh -i key.pem user@host")

    if raw_parts[0] == "ssh":
        raw_parts = raw_parts[1:]

    key_file = None
    port = 22
    positional = []
    i = 0
    while i < len(raw_parts):
        t = raw_parts[i]
        if t == "-i" and i + 1 < len(raw_parts):
            key_file = raw_parts[i + 1]
            i += 2
        elif t == "-p" and i + 1 < len(raw_parts):
            port = int(raw_parts[i + 1])
            i += 2
        elif t.startswith("-"):
            i += 1
        else:
            positional.append(t)
            i += 1

    if not positional:
        die("Could not find user@host in the command.")

    user_host = positional[0]
    if "@" in user_host:
        user, host = user_host.split("@", 1)
    else:
        user = "ubuntu"
        host = user_host

    servers = load_servers()

    # key
    if key_file:
        key_path = str(import_key(key_file))
        auth_type = "key"
    else:
        key_path = None
        auth_type = "password"

    default_name = args.name or f"{user}@{host}"
    name = prompt("Nickname", default=default_name)

    servers[name] = {
        "host": host,
        "user": user,
        "port": port,
        "key": key_path,
        "auth_type": auth_type,
        "added": datetime.now().isoformat(timespec="seconds"),
        "last_connected": None,
    }
    save_servers(servers)
    print(f"\n  ✓ Imported as '{name}'.")


# List
def cmd_list(args):
    servers = load_servers()
    if not servers:
        print(
            "No servers saved yet.  Use: sshm add  or  sshm import ssh -i key.pem user@host"
        )
        return
    print(f"\n{'NAME':<20}  {'DESTINATION':<32}  {'AUTH':<27}  LAST CONNECTED")
    print("─" * 100)
    for name, info in sorted(servers.items()):
        print(server_label(name, info))
    print()


# Remove
def cmd_remove(args):
    servers = load_servers()
    name = args.name or pick_server(servers, "Remove server")
    if not name:
        return
    if name not in servers:
        die(f"Unknown server: {name}")
    del servers[name]
    save_servers(servers)
    print(f"  ✓ Removed '{name}'.")


# Connect
def cmd_connect(args):
    servers = load_servers()
    if not servers:
        die("No servers saved. Add one with: sshm add")

    name = args.name or pick_server(servers, "Connect")
    if not name:
        return

    info = servers.get(name)
    if not info:
        die(f"Unknown server: {name}")

    assert info, f"Server info not found for {name}"
    _update_last(servers, name)

    ssh_cmd = build_ssh_cmd(info)
    print(f"\n  ⇒  {' '.join(ssh_cmd)}\n")
    os.execvp("ssh", ssh_cmd)


# Copy (scp)
def cmd_copy(args):
    """
    sshm copy <src> <dst>
    Use ':' prefix to denote remote path, e.g.
        sshm copy ./local.txt :~/remote.txt
        sshm copy :~/remote.txt ./local/
    """
    servers = load_servers()
    name = args.name or pick_server(servers, "Copy via")
    if not name:
        return

    info = servers.get(name)
    if not info:
        die(f"Unknown server: {name}")

    assert info, f"Server info not found for {name}"
    _update_last(servers, name)

    dest_str = f"{info['user']}@{info['host']}"
    scp_args = []

    if info.get("key"):
        scp_args += ["-i", info["key"]]
    if info.get("port", 22) != 22:
        scp_args += ["-P", str(info["port"])]

    def resolve(path):
        if path.startswith(":"):
            return f"{dest_str}:{path[1:]}"
        return path

    src = resolve(args.src)
    dst = resolve(args.dst)

    scp_cmd = ["scp"] + scp_args + [src, dst]
    print(f"\n  ⇒  {' '.join(scp_cmd)}\n")
    os.execvp("scp", scp_cmd)


# Port forward
def cmd_forward(args):
    """
    sshm forward [--name prod] <remote_port> [local_port]
    Forwards remote_port → localhost:local_port (defaults to same port).
    """
    servers = load_servers()
    name = args.name or pick_server(servers, "Port-forward from")
    if not name:
        return

    info = servers.get(name)
    if not info:
        die(f"Unknown server: {name}")

    assert info, f"Server info not found for {name}"
    _update_last(servers, name)

    remote_port = args.remote_port
    local_port = args.local_port or remote_port

    ssh_cmd = build_ssh_cmd(
        info,
        extra=[
            "-N",
            "-L",
            f"{local_port}:localhost:{remote_port}",
        ],
    )
    print(f"\n  ⇒  {' '.join(ssh_cmd)}")
    print(f"  ✓  Forwarding  localhost:{local_port}  →  {info['host']}:{remote_port}")
    print("     Press Ctrl-C to stop.\n")
    os.execvp("ssh", ssh_cmd)


# Run a remote command
def cmd_run(args):
    """sshm run [--name prod] -- <remote command>"""
    servers = load_servers()
    name = args.name or pick_server(servers, "Run command on")
    if not name:
        return

    info = servers.get(name)
    if not info:
        die(f"Unknown server: {name}")

    assert info, f"Server info not found for {name}"
    _update_last(servers, name)

    ssh_cmd = build_ssh_cmd(info, extra=args.command)
    print(f"\n  ⇒  {' '.join(ssh_cmd)}\n")
    os.execvp("ssh", ssh_cmd)


# Helpers
def build_ssh_cmd(info: dict, extra: list | None = None) -> list:
    cmd = ["ssh"]
    if info.get("key"):
        cmd += ["-i", info["key"]]
    if info.get("port", 22) != 22:
        cmd += ["-p", str(info["port"])]
    if extra:
        cmd += extra
    cmd.append(f"{info['user']}@{info['host']}")
    return cmd


def pick_server(servers: dict, action: str = "Select") -> str | None:
    """Launch fzf and return the chosen server name."""
    if not shutil.which("fzf"):
        die("fzf is not installed. Install it: sudo apt install fzf")

    lines = [server_label(n, i) for n, i in sorted(servers.items())]
    fzf_input = "\n".join(lines)

    result = subprocess.run(
        [
            "fzf",
            "--ansi",
            "--prompt",
            f"  {action} › ",
            "--height",
            "40%",
            "--border",
            "rounded",
            "--info",
            "inline",
            "--header",
            f"{'NAME':<20}  {'DESTINATION':<32}  {'AUTH':<27}  LAST CONNECTED",
        ],
        input=fzf_input,
        text=True,
        capture_output=True,
    )

    if result.returncode != 0 or not result.stdout.strip():
        return None

    chosen_line = result.stdout.strip()
    name = chosen_line.split()[0]  # first token is always the name
    return name


def _update_last(servers, name):
    servers[name]["last_connected"] = datetime.now().isoformat(timespec="seconds")
    save_servers(servers)


def prompt(label: str, default: str | None = None, choices: list | None = None) -> str:
    hint = ""
    if default:
        hint += f" [{default}]"
    if choices:
        hint += f" ({'/'.join(choices)})"
    line = input(f"  {label}{hint}: ").strip()
    if not line and default is not None:
        return default
    return line


def prompt_int(label: str, default: int | None = None) -> int:
    while True:
        raw = prompt(label, default=str(default) if default is not None else None)
        try:
            return int(raw)
        except ValueError:
            print("  Please enter a number.")


def die(msg: str):
    print(f"\n  ✗  {msg}\n", file=sys.stderr)
    sys.exit(1)


# CLI
def main():
    p = argparse.ArgumentParser(
        prog="sshm",
        description="SSH Manager — store, pick and connect to servers with fzf.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  sshm import ssh -i Flintkey.pem flint@3.226.153.116
  sshm add
  sshm add --name prod --host 3.226.153.116 --user flint --key ./Flintkey.pem
  sshm                               # fzf picker → connect
  sshm connect
  sshm connect --name prod
  sshm forward 8080                  # forward remote:8080 → local:8080
  sshm forward 8080 9090             # forward remote:8080 → local:9090
  sshm copy ./file.txt :~/file.txt   # upload
  sshm copy :~/logs/app.log ./       # download
  sshm run -- df -h
  sshm list
  sshm remove
        """,
    )
    sub = p.add_subparsers(dest="cmd")

    # add
    pa = sub.add_parser("add", help="Add a server (interactive or via flags)")
    pa.add_argument("--name", help="Nickname")
    pa.add_argument("--host", help="Host / IP")
    pa.add_argument("--user", "-u", help="SSH username")
    pa.add_argument("--port", "-p", type=int, default=22)
    pa.add_argument("--key", "-i", help="Path to private key")
    pa.add_argument("--password-auth", action="store_true")

    # import
    pi = sub.add_parser("import", help="Import from a raw ssh command")
    pi.add_argument("--name", help="Override nickname")
    pi.add_argument("command", nargs=argparse.REMAINDER)

    # list
    sub.add_parser("list", aliases=["ls"], help="List saved servers")

    # remove
    pr = sub.add_parser("remove", aliases=["rm", "delete"], help="Remove a server")
    pr.add_argument("name", nargs="?", help="Nickname (fzf if omitted)")

    # connect
    pc = sub.add_parser("connect", aliases=["ssh"], help="Connect to a server")
    pc.add_argument("name", nargs="?", help="Nickname (fzf if omitted)")

    # forward
    pf = sub.add_parser("forward", aliases=["fwd", "tunnel"], help="Port-forward")
    pf.add_argument("--name", "-n", help="Server nickname (fzf if omitted)")
    pf.add_argument("remote_port", type=int)
    pf.add_argument("local_port", type=int, nargs="?")

    # copy
    pcp = sub.add_parser("copy", aliases=["cp", "scp"], help="Copy files via scp")
    pcp.add_argument("--name", "-n", help="Server nickname (fzf if omitted)")
    pcp.add_argument("src")
    pcp.add_argument("dst")

    # run
    prun = sub.add_parser("run", aliases=["exec"], help="Run a remote command")
    prun.add_argument("--name", "-n", help="Server nickname (fzf if omitted)")
    prun.add_argument("command", nargs=argparse.REMAINDER)

    args = p.parse_args()

    dispatch = {
        "add": cmd_add,
        "import": cmd_import,
        "list": cmd_list,
        "ls": cmd_list,
        "remove": cmd_remove,
        "rm": cmd_remove,
        "delete": cmd_remove,
        "connect": cmd_connect,
        "ssh": cmd_connect,
        "forward": cmd_forward,
        "fwd": cmd_forward,
        "tunnel": cmd_forward,
        "copy": cmd_copy,
        "cp": cmd_copy,
        "scp": cmd_copy,
        "run": cmd_run,
        "exec": cmd_run,
    }

    if args.cmd is None:
        cmd_connect(argparse.Namespace(name=None))
    elif args.cmd in dispatch:
        dispatch[args.cmd](args)
    else:
        p.print_help()


if __name__ == "__main__":
    main()
