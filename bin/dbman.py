#!/usr/bin/env python3

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

CONFIG_DIR = Path.home() / ".dbman"
CONFIG_FILE = CONFIG_DIR / "containers.json"

PG_DEFAULT_PORT = 5432
PG_DEFAULT_USER = "postgres"
PG_DEFAULT_PASSWORD = "postgres"
PG_DEFAULT_DB = "postgres"
PG_DEFAULT_IMAGE = "postgres:16-alpine"

REDIS_DEFAULT_PORT = 6379


class C:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    RED = "\033[91m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    CYAN = "\033[96m"
    GRAY = "\033[90m"
    WHITE = "\033[97m"


def c(color, text):
    return f"{color}{text}{C.RESET}"


def ok(msg):
    print(f"  {c(C.GREEN, '✔')}  {msg}")


def err(msg):
    print(f"  {c(C.RED, '✖')}  {msg}")


def info(msg):
    print(f"  {c(C.BLUE, '●')}  {msg}")


def warn(msg):
    print(f"  {c(C.YELLOW, '!')}  {msg}")


def header(title):
    print(f"\n{c(C.BOLD + C.WHITE, title)}")
    print(c(C.GRAY, "─" * 50))


def load_config() -> dict:
    CONFIG_DIR.mkdir(exist_ok=True)
    if CONFIG_FILE.exists():
        content = CONFIG_FILE.read_text().strip()
        if content:
            return json.loads(content)
    return {}


def save_config(data: dict):
    CONFIG_DIR.mkdir(exist_ok=True)
    CONFIG_FILE.write_text(json.dumps(data, indent=2))


def get_entry(name: str) -> dict | None:
    return load_config().get(name)


def set_entry(name: str, entry: dict):
    data = load_config()
    data[name] = entry
    save_config(data)


def del_entry(name: str):
    data = load_config()
    data.pop(name, None)
    save_config(data)


def run(cmd: list[str], capture=True, check=False) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=capture, text=True, check=check)


def docker_container_exists(name: str) -> bool:
    r = run(["docker", "ps", "-a", "--format", "{{.Names}}"])
    return name in r.stdout.split()


def docker_container_running(name: str) -> bool:
    r = run(["docker", "ps", "--format", "{{.Names}}"])
    return name in r.stdout.split()


def docker_start(name: str) -> bool:
    r = run(["docker", "start", name])
    return r.returncode == 0


def docker_stop(name: str) -> bool:
    r = run(["docker", "stop", name])
    return r.returncode == 0


def docker_rm(name: str) -> bool:
    run(["docker", "stop", name])
    r = run(["docker", "rm", name])
    return r.returncode == 0


def port_in_use(port: int) -> str | None:
    """Returns the container name using the port, or None."""
    r = run(["docker", "ps", "--format", "{{.Names}} {{.Ports}}"])
    for line in r.stdout.strip().splitlines():
        if f":{port}->" in line or f"0.0.0.0:{port}" in line:
            return line.split()[0]
    return None


def free_port(port: int, force: bool) -> bool:
    """Stop whatever container is using the port if -f is passed."""
    blocker = port_in_use(port)
    if not blocker:
        return True
    if not force:
        err(f"Port {port} is already used by container '{blocker}'.")
        info("Use -f to force-stop it and claim the port.")
        return False
    warn(f"Force-stopping '{blocker}' to free port {port}...")
    docker_stop(blocker)
    ok(f"Stopped '{blocker}'.")
    return True


def wait_healthy(container: str, timeout: int = 15) -> bool:
    for _ in range(timeout):
        r = run(["docker", "inspect", "--format", "{{.State.Status}}", container])
        if r.stdout.strip() == "running":
            return True
        time.sleep(1)
    return False


# Postgres
def pg_create(name: str, port: int, force: bool, image: str = PG_DEFAULT_IMAGE):
    container = f"dbman-pg-{name}"
    header(f"Postgres  ›  {name}")

    # Already tracked — just start it
    entry = get_entry(name)
    if entry and entry["type"] == "postgres":
        if docker_container_running(container):
            ok(f"Container '{container}' is already running.")
            pg_info(name)
            return
        if docker_container_exists(container):
            info(f"Starting existing container '{container}'...")
            docker_start(container)
            ok("Container started.")
            pg_info(name)
            return

    # Container exists in Docker but not tracked
    if docker_container_exists(container):
        info(f"Container '{container}' exists (untracked). Starting it...")
        docker_start(container)
        # Re-detect port
        r = run(
            [
                "docker",
                "inspect",
                "--format",
                '{{(index (index .NetworkSettings.Ports "5432/tcp") 0).HostPort}}',
                container,
            ]
        )
        actual_port = int(r.stdout.strip()) if r.stdout.strip().isdigit() else port
        entry = {
            "type": "postgres",
            "container": container,
            "port": actual_port,
            "user": name,
            "password": PG_DEFAULT_PASSWORD,
            "db": name,
            "image": image,
        }
        set_entry(name, entry)
        ok("Container started and tracked.")
        pg_info(name)
        return

    # Fresh create
    if not free_port(port, force):
        return

    info(f"Pulling & starting postgres container '{container}' on port {port}...")
    info(f"Using image: {c(C.CYAN, image)}")
    r = run(
        [
            "docker",
            "run",
            "-d",
            "--name",
            container,
            "-e",
            f"POSTGRES_USER={name}",
            "-e",
            f"POSTGRES_PASSWORD={PG_DEFAULT_PASSWORD}",
            "-e",
            f"POSTGRES_DB={name}",
            "-p",
            f"{port}:5432",
            image,
        ]
    )
    if r.returncode != 0:
        err("Failed to start container.")
        print(r.stderr)
        return

    wait_healthy(container)
    entry = {
        "type": "postgres",
        "container": container,
        "port": port,
        "user": name,
        "password": PG_DEFAULT_PASSWORD,
        "db": name,
        "image": image,
    }
    set_entry(name, entry)
    ok(f"Container '{container}' is running.")
    pg_info(name)


def pg_info(name: str):
    entry = get_entry(name)
    if not entry or entry["type"] != "postgres":
        err(f"No postgres container tracked under '{name}'.")
        return

    port = entry["port"]
    user = entry["user"]
    password = entry["password"]
    db = entry["db"]
    host = "localhost"
    container = entry["container"]
    image = entry.get("image", PG_DEFAULT_IMAGE)
    running = docker_container_running(container)
    status = c(C.GREEN, "running") if running else c(C.YELLOW, "stopped")

    header(f"Postgres  ›  {name}  [{status}{C.BOLD}]")
    print(f"  {'Container':<18} {c(C.CYAN, container)}")
    print(f"  {'Image':<18} {c(C.CYAN, image)}")
    print(f"  {'Host':<18} {c(C.WHITE, host)}")
    print(f"  {'Port':<18} {c(C.WHITE, str(port))}")
    print(f"  {'User':<18} {c(C.WHITE, user)}")
    print(f"  {'Password':<18} {c(C.WHITE, password)}")
    print(f"  {'Database':<18} {c(C.WHITE, db)}")
    print()

    pg_url = f"postgresql://{user}:{password}@{host}:{port}/{db}"
    sqlalc = f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{db}"
    asyncpg = f"postgresql+asyncpg://{user}:{password}@{host}:{port}/{db}"
    env_block = (
        f"POSTGRES_HOST={host}\n"
        f"POSTGRES_PORT={port}\n"
        f"POSTGRES_USER={user}\n"
        f"POSTGRES_PASSWORD={password}\n"
        f"POSTGRES_DB={db}\n"
        f"DATABASE_URL={pg_url}"
    )

    print(c(C.BOLD, "  Connection URLs"))
    print(c(C.GRAY, "  " + "─" * 46))
    print(f"  {c(C.GRAY, 'psql')}        {c(C.YELLOW, pg_url)}")
    print(f"  {c(C.GRAY, 'SQLAlchemy')}  {c(C.YELLOW, sqlalc)}")
    print(f"  {c(C.GRAY, 'asyncpg')}     {c(C.YELLOW, asyncpg)}")
    print()
    print(c(C.BOLD, "  .env block"))
    print(c(C.GRAY, "  " + "─" * 46))
    for line in env_block.splitlines():
        key, _, val = line.partition("=")
        print(f"  {c(C.GRAY, key + '=')}{c(C.GREEN, val)}")
    print()
    if running:
        print(c(C.GRAY, f"  Shell: dbman pg connect {name}"))
    else:
        print(c(C.YELLOW, f"  Tip: dbman pg start {name}   (container is stopped)"))
    print()


def pg_connect(name: str, replace: bool = True):
    entry = get_entry(name)
    if not entry or entry["type"] != "postgres":
        err(f"No postgres container tracked under '{name}'.")
        sys.exit(1)
    container = entry["container"]
    if not docker_container_running(container):
        warn("Container is stopped. Starting it...")
        docker_start(container)
        time.sleep(2)
    print(c(C.CYAN, f"\n  Connecting to {container}  (type \\q to quit)\n"))
    cmd = [
        "docker",
        "exec",
        "-it",
        container,
        "psql",
        "-U",
        entry["user"],
        "-d",
        entry["db"],
    ]
    if replace:
        os.execvp("docker", cmd)
    subprocess.run(cmd)


def pg_stop(name: str):
    entry = get_entry(name)
    if not entry:
        err(f"No container tracked under '{name}'.")
        return
    docker_stop(entry["container"])
    ok(f"Stopped '{entry['container']}'.")


def pg_remove(name: str):
    entry = get_entry(name)
    if not entry:
        err(f"No container tracked under '{name}'.")
        return
    header(f"Remove  ›  {name}")
    ans = input(
        f"  {c(C.YELLOW, '⚠')}  This will DELETE the container and all its data. Continue? [y/N] "
    )
    if ans.strip().lower() != "y":
        info("Aborted.")
        return
    docker_rm(entry["container"])
    del_entry(name)
    ok(f"Container '{entry['container']}' removed.")


# Redis
def redis_create(name: str, port: int, force: bool):
    container = f"dbman-redis-{name}"
    header(f"Redis  ›  {name}")

    entry = get_entry(name)
    if entry and entry["type"] == "redis":
        if docker_container_running(container):
            ok(f"Container '{container}' is already running.")
            redis_info(name)
            return
        if docker_container_exists(container):
            info(f"Starting existing container '{container}'...")
            docker_start(container)
            ok("Container started.")
            redis_info(name)
            return

    if docker_container_exists(container):
        info(f"Container '{container}' exists (untracked). Starting it...")
        docker_start(container)
        entry = {"type": "redis", "container": container, "port": port}
        set_entry(name, entry)
        ok("Container started and tracked.")
        redis_info(name)
        return

    if not free_port(port, force):
        return

    info(f"Pulling & starting redis container '{container}' on port {port}...")
    r = run(
        [
            "docker",
            "run",
            "-d",
            "--name",
            container,
            "-p",
            f"{port}:6379",
            "redis:7-alpine",
        ]
    )
    if r.returncode != 0:
        err("Failed to start container.")
        print(r.stderr)
        return

    wait_healthy(container)
    entry = {"type": "redis", "container": container, "port": port}
    set_entry(name, entry)
    ok(f"Container '{container}' is running.")
    redis_info(name)


def redis_info(name: str):
    entry = get_entry(name)
    if not entry or entry["type"] != "redis":
        err(f"No redis container tracked under '{name}'.")
        return

    port = entry["port"]
    host = "localhost"
    container = entry["container"]
    running = docker_container_running(container)
    status = c(C.GREEN, "running") if running else c(C.YELLOW, "stopped")

    header(f"Redis  ›  {name}  [{status}{C.BOLD}]")
    print(f"  {'Container':<18} {c(C.CYAN, container)}")
    print(f"  {'Host':<18} {c(C.WHITE, host)}")
    print(f"  {'Port':<18} {c(C.WHITE, str(port))}")
    print()

    redis_url = f"redis://{host}:{port}/0"
    env_block = f"REDIS_HOST={host}\nREDIS_PORT={port}\nREDIS_URL={redis_url}"

    print(c(C.BOLD, "  Connection URLs"))
    print(c(C.GRAY, "  " + "─" * 46))
    print(
        f"  {c(C.GRAY, 'redis-cli')}   {c(C.YELLOW, f'redis-cli -h {host} -p {port}')}"
    )
    print(f"  {c(C.GRAY, 'URL')}         {c(C.YELLOW, redis_url)}")
    print()
    print(c(C.BOLD, "  .env block"))
    print(c(C.GRAY, "  " + "─" * 46))
    for line in env_block.splitlines():
        key, _, val = line.partition("=")
        print(f"  {c(C.GRAY, key + '=')}{c(C.GREEN, val)}")
    print()
    if running:
        print(c(C.GRAY, f"  Shell: dbman redis connect {name}"))
    else:
        print(c(C.YELLOW, f"  Tip: dbman redis start {name}   (container is stopped)"))
    print()


def redis_connect(name: str, replace: bool = True):
    entry = get_entry(name)
    if not entry or entry["type"] != "redis":
        err(f"No redis container tracked under '{name}'.")
        sys.exit(1)
    container = entry["container"]
    if not docker_container_running(container):
        warn("Container is stopped. Starting it...")
        docker_start(container)
        time.sleep(1)
    print(c(C.CYAN, f"\n  Connecting to {container}  (type quit to exit)\n"))
    cmd = ["docker", "exec", "-it", container, "redis-cli"]
    if replace:
        os.execvp("docker", cmd)
    subprocess.run(cmd)


def redis_stop(name: str):
    entry = get_entry(name)
    if not entry:
        err(f"No container tracked under '{name}'.")
        return
    docker_stop(entry["container"])
    ok(f"Stopped '{entry['container']}'.")


def redis_remove(name: str):
    entry = get_entry(name)
    if not entry:
        err(f"No container tracked under '{name}'.")
        return
    header(f"Remove  ›  {name}")
    ans = input(
        f"  {c(C.YELLOW, '⚠')}  This will DELETE the container and all its data. Continue? [y/N] "
    )
    if ans.strip().lower() != "y":
        info("Aborted.")
        return
    docker_rm(entry["container"])
    del_entry(name)
    ok(f"Container '{entry['container']}' removed.")


# ── List ──────────────────────────────────────────────────────────────────────
def list_all():
    data = load_config()
    if not data:
        info("No containers tracked yet. Try: dbman pg create myproject")
        return

    header("Managed Containers")
    for name, entry in data.items():
        container = entry["container"]
        running = docker_container_running(container)
        status = c(C.GREEN, "● running") if running else c(C.GRAY, "○ stopped")
        kind = (
            c(C.CYAN, "postgres")
            if entry["type"] == "postgres"
            else c(C.RED, "redis   ")
        )
        port = entry["port"]
        image_info = ""
        if entry["type"] == "postgres":
            image_info = f"  {c(C.GRAY, entry.get('image', PG_DEFAULT_IMAGE))}"
        print(
            f"  {kind}  {c(C.WHITE, name):<22} {status:<24}  port {c(C.YELLOW, str(port))}{image_info}"
        )
    print()


# Interactive UI
def require_fzf() -> bool:
    if shutil.which("fzf"):
        return True
    err("fzf is not installed or not available in PATH.")
    info("Install fzf, then run: dbman ui")
    return False


def fzf_select(
    options: list[tuple[str, str]], prompt: str, header_text: str = ""
) -> str | None:
    if not options:
        return None

    rows = "\n".join(f"{key}\t{label}" for key, label in options)
    cmd = [
        "fzf",
        "--ansi",
        "--layout=reverse",
        "--height=90%",
        "--border",
        "--cycle",
        "--no-sort",
        "--delimiter",
        "\t",
        "--with-nth",
        "2..",
        "--prompt",
        prompt,
    ]
    if header_text:
        cmd.extend(["--header", header_text])

    r = subprocess.run(cmd, input=rows, stdout=subprocess.PIPE, text=True)
    if r.returncode != 0:
        return None
    selected = r.stdout.rstrip("\n")
    if not selected:
        return None
    return selected.split("\t", 1)[0]


def ui_pause():
    try:
        input(c(C.GRAY, "\nPress Enter to continue..."))
    except (EOFError, KeyboardInterrupt):
        print()


def ui_prompt_text(label: str, default: str | None = None) -> str | None:
    while True:
        suffix = f" [{default}]" if default is not None else ""
        try:
            value = input(f"{label}{suffix}: ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            return None
        if value:
            return value
        if default is not None:
            return default
        warn("Value cannot be empty.")


def ui_prompt_port(default: int) -> int | None:
    while True:
        value = ui_prompt_text("Port", str(default))
        if value is None:
            return None
        try:
            port = int(value)
        except ValueError:
            warn("Port must be a number.")
            continue
        if 1 <= port <= 65535:
            return port
        warn("Port must be between 1 and 65535.")


def ui_prompt_confirm(label: str, default: bool = False) -> bool | None:
    suffix = "Y/n" if default else "y/N"
    while True:
        try:
            answer = input(f"{label} [{suffix}]: ").strip().lower()
        except (EOFError, KeyboardInterrupt):
            print()
            return None
        if not answer:
            return default
        if answer in ("y", "yes"):
            return True
        if answer in ("n", "no"):
            return False
        warn("Answer yes or no.")


def ui_create(kind: str):
    header(f"Create {kind.title()}")
    name = ui_prompt_text("Name")
    if not name:
        return
    default_port = PG_DEFAULT_PORT if kind == "postgres" else REDIS_DEFAULT_PORT
    port = ui_prompt_port(default_port)
    if port is None:
        return

    image = None
    if kind == "postgres":
        image = ui_prompt_text("Image", PG_DEFAULT_IMAGE)
        if image is None:
            return

    force = ui_prompt_confirm("Force-stop a container already using this port?", False)
    if force is None:
        return

    if kind == "postgres":
        if not image:
            image = PG_DEFAULT_IMAGE
        pg_create(name, port, force, image)
    else:
        redis_create(name, port, force)
    ui_pause()


def ui_entry_label(name: str, entry: dict) -> str:
    kind = entry["type"]
    container = entry["container"]
    running = docker_container_running(container)
    status = c(C.GREEN, "running") if running else c(C.GRAY, "stopped")
    kind_label = c(C.CYAN, "postgres") if kind == "postgres" else c(C.RED, "redis")
    image_info = ""
    if kind == "postgres":
        img = entry.get("image", PG_DEFAULT_IMAGE)
        image_info = f"  {c(C.GRAY, img)}"
    return (
        f"{kind_label:<18} "
        f"{c(C.WHITE, name):<28} "
        f"{status:<18} "
        f"port {c(C.YELLOW, str(entry['port'])):<10} "
        f"{c(C.GRAY, container)}{image_info}"
    )


def ui_start(name: str) -> bool:
    entry = get_entry(name)
    if not entry:
        err(f"No container tracked under '{name}'.")
        return False
    if docker_start(entry["container"]):
        ok(f"Started '{entry['container']}'.")
        return True
    err(f"Failed to start '{entry['container']}'.")
    return False


def ui_manage(name: str):
    while True:
        entry = get_entry(name)
        if not entry:
            warn(f"'{name}' is no longer tracked.")
            ui_pause()
            return

        container = entry["container"]
        running = docker_container_running(container)
        status = "running" if running else "stopped"
        title = f"{entry['type']} / {name} / {status} / port {entry['port']}"
        actions = [
            ("info", "View info / connection strings"),
            ("start", "Start"),
            ("stop", "Stop"),
            ("connect", "Connect shell"),
            ("remove", c(C.RED, "Delete")),
            ("back", "Back"),
        ]
        action = fzf_select(actions, "action> ", title)
        if action in (None, "back"):
            return

        if action == "info":
            if entry["type"] == "postgres":
                pg_info(name)
            else:
                redis_info(name)
            ui_pause()
        elif action == "start":
            ui_start(name)
            ui_pause()
        elif action == "stop":
            if entry["type"] == "postgres":
                pg_stop(name)
            else:
                redis_stop(name)
            ui_pause()
        elif action == "connect":
            if entry["type"] == "postgres":
                pg_connect(name, replace=False)
            else:
                redis_connect(name, replace=False)
            ui_pause()
        elif action == "remove":
            if entry["type"] == "postgres":
                pg_remove(name)
            else:
                redis_remove(name)
            ui_pause()
            if not get_entry(name):
                return


def ui_main():
    if not require_fzf():
        sys.exit(1)

    while True:
        data = load_config()
        options = [
            ("create:postgres", f"{c(C.GREEN, '+')} Create Postgres"),
            ("create:redis", f"{c(C.GREEN, '+')} Create Redis"),
        ]
        for name, entry in sorted(data.items()):
            options.append((f"manage:{name}", ui_entry_label(name, entry)))
        options.append(("quit", "Quit"))

        header_text = "Enter: select | Esc: quit | type: filter"
        choice = fzf_select(options, "dbman> ", header_text)
        if choice in (None, "quit"):
            return
        if choice == "create:postgres":
            ui_create("postgres")
        elif choice == "create:redis":
            ui_create("redis")
        elif choice.startswith("manage:"):
            ui_manage(choice.split(":", 1)[1])


# CLI
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="dbman",
        description="Local Docker Database Manager",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
            Examples:
              dbman pg create myapp              # Postgres on default port 5432
              dbman pg create myapp -p 5433      # Postgres on custom port
              dbman pg create myapp -f           # Force-claim port 5432 if taken
              dbman pg create myapp --image pgvector/pgvector:pg16
              dbman pg info myapp                # Show connection details & URLs
              dbman pg connect myapp             # Open psql shell
              dbman pg stop myapp                # Stop container
              dbman pg remove myapp              # Delete container + data

              dbman redis create myapp           # Redis on default port 6379
              dbman redis connect myapp          # Open redis-cli
              dbman redis info myapp             # Show connection details

              dbman list                         # All managed containers
              dbman ui                           # Interactive fzf UI
        """,
    )
    sub = p.add_subparsers(dest="cmd")

    # pg
    pg = sub.add_parser("pg", help="Manage Postgres containers")
    pg_sub = pg.add_subparsers(dest="pg_cmd")

    for action in ("create", "info", "connect", "stop", "remove", "start"):
        sp = pg_sub.add_parser(action)
        sp.add_argument("name", help="Project name")
        if action == "create":
            sp.add_argument(
                "-p",
                "--port",
                type=int,
                default=PG_DEFAULT_PORT,
                help=f"Host port (default {PG_DEFAULT_PORT})",
            )
            sp.add_argument(
                "-f",
                "--force",
                action="store_true",
                help="Force-stop any container using the port",
            )
            sp.add_argument(
                "--image",
                default=PG_DEFAULT_IMAGE,
                help=f"Postgres Docker image (default: {PG_DEFAULT_IMAGE})",
            )

    # redis
    rd = sub.add_parser("redis", help="Manage Redis containers")
    rd_sub = rd.add_subparsers(dest="redis_cmd")

    for action in ("create", "info", "connect", "stop", "remove", "start"):
        sp = rd_sub.add_parser(action)
        sp.add_argument("name", help="Project name")
        if action == "create":
            sp.add_argument(
                "-p",
                "--port",
                type=int,
                default=REDIS_DEFAULT_PORT,
                help=f"Host port (default {REDIS_DEFAULT_PORT})",
            )
            sp.add_argument(
                "-f",
                "--force",
                action="store_true",
                help="Force-stop any container using the port",
            )

    # list
    sub.add_parser("list", help="List all managed containers")
    sub.add_parser("ui", help="Open the interactive fzf UI")

    return p


def main():
    parser = build_parser()
    args = parser.parse_args()

    if args.cmd == "pg":
        if args.pg_cmd == "create":
            pg_create(args.name, args.port, args.force, args.image)
        elif args.pg_cmd in ("info", None):
            pg_info(args.name)
        elif args.pg_cmd == "connect":
            pg_connect(args.name)
        elif args.pg_cmd in ("stop",):
            pg_stop(args.name)
        elif args.pg_cmd == "start":
            entry = get_entry(args.name)
            if entry:
                docker_start(entry["container"])
                ok(f"Started '{entry['container']}'.")
                if entry["type"] == "postgres":
                    pg_info(args.name)
                else:
                    redis_info(args.name)
            else:
                err(f"No container tracked under '{args.name}'. Use 'create' first.")
        elif args.pg_cmd == "remove":
            pg_remove(args.name)
        else:
            parser.parse_args(["pg", "--help"])

    elif args.cmd == "redis":
        if args.redis_cmd == "create":
            redis_create(args.name, args.port, args.force)
        elif args.redis_cmd in ("info", None):
            redis_info(args.name)
        elif args.redis_cmd == "connect":
            redis_connect(args.name)
        elif args.redis_cmd == "stop":
            redis_stop(args.name)
        elif args.redis_cmd == "start":
            entry = get_entry(args.name)
            if entry:
                docker_start(entry["container"])
                ok(f"Started '{entry['container']}'.")
                redis_info(args.name)
            else:
                err(f"No container tracked under '{args.name}'. Use 'create' first.")
        elif args.redis_cmd == "remove":
            redis_remove(args.name)
        else:
            parser.parse_args(["redis", "--help"])

    elif args.cmd == "list":
        list_all()

    elif args.cmd == "ui":
        ui_main()

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
