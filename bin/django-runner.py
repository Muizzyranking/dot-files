#!/usr/bin/env python3

import os
import sys
import subprocess
import argparse
import signal
import platform


# Set up colorful terminal output
class Colors:
    HEADER = "\033[95m"
    INFO = "\033[94m"
    SUCCESS = "\033[92m"
    WARNING = "\033[93m"
    ERROR = "\033[91m"
    END = "\033[0m"
    BOLD = "\033[1m"


def print_info(message):
    print(f"{Colors.INFO}[INFO] {message}{Colors.END}")


def print_success(message):
    print(f"{Colors.SUCCESS}[SUCCESS] {message}{Colors.END}")


def print_warning(message):
    print(f"{Colors.WARNING}[WARNING] {message}{Colors.END}")


def print_error(message):
    print(f"{Colors.ERROR}[ERROR] {message}{Colors.END}")


def print_header(message):
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'=' * 60}{Colors.END}")
    print(f"{Colors.HEADER}{Colors.BOLD}{message.center(60)}{Colors.END}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'=' * 60}{Colors.END}\n")


def signal_handler(sig, frame):
    print_info("\nShutting down Django server...")
    sys.exit(0)


# Register signal handler for clean termination
signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)


def find_git_root():
    """Find the root directory of a git repository"""
    try:
        git_root = subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"],
            stderr=subprocess.DEVNULL,
            universal_newlines=True,
        ).strip()
        return git_root
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def find_manage_py():
    """Find the manage.py file"""
    # Check current directory
    if os.path.isfile("manage.py"):
        print_success("Found manage.py in the current directory")
        return os.path.abspath("manage.py")

    # Try git root
    git_root = find_git_root()
    if git_root:
        manage_path = os.path.join(git_root, "manage.py")
        if os.path.isfile(manage_path):
            print_success(f"Found manage.py in git root: {git_root}")
            return os.path.abspath(manage_path)

    return None


def is_venv_python():
    """Check if current Python interpreter is from a virtual environment"""
    return hasattr(sys, "real_prefix") or (
        hasattr(sys, "base_prefix") and sys.base_prefix != sys.prefix
    )


def get_project_name(manage_py_path):
    """Extract the Django project name from manage.py"""
    dir_path = os.path.dirname(manage_py_path)
    # Look for directories that might contain settings.py
    for item in os.listdir(dir_path):
        if os.path.isdir(os.path.join(dir_path, item)):
            settings_path = os.path.join(dir_path, item, "settings.py")
            if os.path.isfile(settings_path):
                return item

    # Fall back to directory name
    return os.path.basename(dir_path)


def create_venv(project_dir, project_name):
    """Create a virtual environment"""
    venv_path = os.path.join(project_dir, "venv")
    print_info(f"Creating virtual environment '{venv_path}'...")

    try:
        subprocess.run([sys.executable, "-m", "venv", venv_path], check=True)
        print_success(
            f"Virtual environment created for project {project_name}"
        )
        return venv_path
    except subprocess.CalledProcessError as e:
        print_error(f"Failed to create virtual environment: {e}")
        return None


def activate_venv(venv_path):
    """Activate the virtual environment"""
    if platform.system() == "Windows":
        python_path = os.path.join(venv_path, "Scripts", "python.exe")
        pip_path = os.path.join(venv_path, "Scripts", "pip.exe")
    else:
        python_path = os.path.join(venv_path, "bin", "python")
        pip_path = os.path.join(venv_path, "bin", "pip")

    if not os.path.exists(python_path):
        print_error(
            f"Python interpreter not found in virtual env: {python_path}"
        )
        return None, None

    print_success(f"Using Python from: {python_path}")
    return python_path, pip_path


def install_django_if_needed(pip_path, project_dir):
    """Install Django if it's not already installed"""
    try:
        # Check if Django is installed
        result = subprocess.run(
            [pip_path, "freeze"],
            capture_output=True,
            text=True,
            cwd=project_dir,
        )

        if "django==" not in result.stdout.lower():
            print_info(
                "Django not found in virtual environment. Installing Django..."
            )
            subprocess.run(
                [pip_path, "install", "django"], check=True, cwd=project_dir
            )
            print_success("Django installed successfully")
        else:
            print_info("Django is already installed")
    except subprocess.CalledProcessError as e:
        print_error(f"Failed to install Django: {e}")


def run_migrations(python_path, manage_py_path):
    """Run Django migrations"""
    project_dir = os.path.dirname(manage_py_path)

    print_header("Running Django Migrations")

    print_info("Making migrations...")
    try:
        subprocess.run(
            [python_path, manage_py_path, "makemigrations"],
            check=True,
            cwd=project_dir,
        )
        print_success("Migrations created successfully")
    except subprocess.CalledProcessError as e:
        print_error(f"Failed to create migrations: {e}")
        return False

    print_info("Applying migrations...")
    try:
        subprocess.run(
            [python_path, manage_py_path, "migrate"],
            check=True,
            cwd=project_dir,
        )
        print_success("Migrations applied successfully")
        return True
    except subprocess.CalledProcessError as e:
        print_error(f"Failed to apply migrations: {e}")
        return False


def run_django_server(python_path, manage_py_path, extra_args=None):
    """Run the Django development server"""
    project_dir = os.path.dirname(manage_py_path)

    print_header("Starting Django Development Server")

    cmd = [python_path, manage_py_path, "runserver"]
    if extra_args:
        cmd.extend(extra_args)

    print_info(f"Running command: {' '.join(cmd)}")
    try:
        subprocess.run(cmd, cwd=project_dir)
    except subprocess.CalledProcessError as e:
        print_error(f"Server exited with error: {e}")
    except KeyboardInterrupt:
        print_info("Server stopped by user")


def main():
    parser = argparse.ArgumentParser(description="Django Server Runner")
    parser.add_argument(
        "--migrate",
        action="store_true",
        help="Run migrations before starting the server",
    )
    parser.add_argument(
        "extra_args",
        nargs="*",
        help="Extra arguments to pass to Django's runserver command",
    )

    args = parser.parse_args()

    print_header("Django Server Runner")

    # Find manage.py
    manage_py_path = find_manage_py()
    if not manage_py_path:
        print_error(
            """
                Could not find manage.py. Make sure you're in a Django project
                directory or a git repository containing a Django project.
            """
        )
        sys.exit(1)

    project_dir = os.path.dirname(manage_py_path)
    project_name = get_project_name(manage_py_path)
    print_info(f"Project identified as: {project_name}")

    # Check if we're already in a venv
    if is_venv_python():
        print_info("Already running in a virtual environment")
        python_path = sys.executable
        pip_path = os.path.join(os.path.dirname(python_path), "pip")
    else:
        # Look for venv in project directory
        venv_path = os.path.join(project_dir, "venv")
        if not os.path.isdir(venv_path):
            print_warning("Virtual environment not found in project directory")
            response = (
                input(
                    "Would you like to create a virtual environment? (y/n): "
                )
                .strip()
                .lower()
            )
            if response == "y":
                venv_path = create_venv(project_dir, project_name)
                if not venv_path:
                    sys.exit(1)
            else:
                print_error("Cannot continue without a virtual environment")
                sys.exit(1)

        # Activate venv
        python_path, pip_path = activate_venv(venv_path)
        if not python_path:
            sys.exit(1)

    # Make sure Django is installed
    install_django_if_needed(pip_path, project_dir)

    # Run migrations if requested
    if args.migrate:
        success = run_migrations(python_path, manage_py_path)
        if not success:
            print_warning(
                "Migrations failed, but continuing with server startup"
            )

    # Run the Django server
    run_django_server(python_path, manage_py_path, args.extra_args)


if __name__ == "__main__":
    main()
