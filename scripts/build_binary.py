#!/usr/bin/env python3
"""
Generic Binary Builder for Python Scripts

This script analyzes a Python file, discovers its dependencies, and builds a standalone binary.

PREREQUISITES (Manual Setup Required):
1. Create and activate a Python virtual environment:
   python3 -m venv build-env
   source build-env/bin/activate  # Linux/Mac
   # OR
   build-env\Scripts\activate     # Windows

2. Ensure PyInstaller is installed in the venv:
   pip install pyinstaller

3. Place your Python script in an accessible location

USAGE:
   python build_binary.py <python_file> [options]

EXAMPLES:
   python build_binary.py excel_converter.py
   python build_binary.py ../scripts/data_profiler.py --output-name data_profiler_binary
   python build_binary.py script.py --extra-imports sklearn,tensorflow
"""

import argparse
import ast
import sys
import os
import subprocess
from pathlib import Path
from typing import Set, List, Dict


# Standard library modules that don't need pip installation
STDLIB_MODULES = {
    'abc', 'argparse', 'array', 'ast', 'asyncio', 'atexit', 'base64', 'binascii',
    'bisect', 'builtins', 'bz2', 'calendar', 'cmath', 'cmd', 'code', 'codecs',
    'collections', 'colorsys', 'compileall', 'concurrent', 'configparser', 'contextlib',
    'contextvars', 'copy', 'copyreg', 'csv', 'ctypes', 'curses', 'dataclasses',
    'datetime', 'dbm', 'decimal', 'difflib', 'dis', 'distutils', 'doctest', 'email',
    'encodings', 'enum', 'errno', 'faulthandler', 'fcntl', 'filecmp', 'fileinput',
    'fnmatch', 'fractions', 'ftplib', 'functools', 'gc', 'getopt', 'getpass', 'gettext',
    'glob', 'graphlib', 'grp', 'gzip', 'hashlib', 'heapq', 'hmac', 'html', 'http',
    'imaplib', 'imghdr', 'imp', 'importlib', 'inspect', 'io', 'ipaddress', 'itertools',
    'json', 'keyword', 'lib2to3', 'linecache', 'locale', 'logging', 'lzma', 'mailbox',
    'mailcap', 'marshal', 'math', 'mimetypes', 'mmap', 'modulefinder', 'multiprocessing',
    'netrc', 'nis', 'nntplib', 'numbers', 'operator', 'optparse', 'os', 'ossaudiodev',
    'pathlib', 'pdb', 'pickle', 'pickletools', 'pipes', 'pkgutil', 'platform', 'plistlib',
    'poplib', 'posix', 'posixpath', 'pprint', 'profile', 'pstats', 'pty', 'pwd', 'py_compile',
    'pyclbr', 'pydoc', 'queue', 'quopri', 'random', 're', 'readline', 'reprlib', 'resource',
    'rlcompleter', 'runpy', 'sched', 'secrets', 'select', 'selectors', 'shelve', 'shlex',
    'shutil', 'signal', 'site', 'smtpd', 'smtplib', 'sndhdr', 'socket', 'socketserver',
    'spwd', 'sqlite3', 'ssl', 'stat', 'statistics', 'string', 'stringprep', 'struct',
    'subprocess', 'sunau', 'symtable', 'sys', 'sysconfig', 'syslog', 'tabnanny', 'tarfile',
    'telnetlib', 'tempfile', 'termios', 'test', 'textwrap', 'threading', 'time', 'timeit',
    'tkinter', 'token', 'tokenize', 'tomllib', 'trace', 'traceback', 'tracemalloc', 'tty',
    'turtle', 'types', 'typing', 'typing_extensions', 'unicodedata', 'unittest', 'urllib',
    'uu', 'uuid', 'venv', 'warnings', 'wave', 'weakref', 'webbrowser', 'winreg', 'winsound',
    'wsgiref', 'xdrlib', 'xml', 'xmlrpc', 'zipapp', 'zipfile', 'zipimport', 'zlib', '_thread'
}


class ImportAnalyzer(ast.NodeVisitor):
    """AST visitor to extract all imports from Python code"""

    def __init__(self):
        self.imports: Set[str] = set()
        self.from_imports: Set[str] = set()

    def visit_Import(self, node):
        """Handle 'import module' statements"""
        for alias in node.names:
            module_name = alias.name.split('.')[0]
            self.imports.add(module_name)
        self.generic_visit(node)

    def visit_ImportFrom(self, node):
        """Handle 'from module import x' statements"""
        if node.module:
            module_name = node.module.split('.')[0]
            self.from_imports.add(module_name)
        self.generic_visit(node)

    def get_all_imports(self) -> Set[str]:
        """Get all unique top-level module names"""
        return self.imports | self.from_imports


def discover_imports(python_file: str) -> Set[str]:
    """Parse Python file and discover all imports"""
    print(f"[1/5] Analyzing Python file: {python_file}")

    try:
        with open(python_file, 'r', encoding='utf-8') as f:
            tree = ast.parse(f.read(), filename=python_file)

        analyzer = ImportAnalyzer()
        analyzer.visit(tree)
        all_imports = analyzer.get_all_imports()

        # Filter out standard library modules
        third_party = {imp for imp in all_imports if imp not in STDLIB_MODULES}

        print(f"   Found {len(all_imports)} total imports")
        print(f"   Third-party packages: {len(third_party)}")

        if third_party:
            print(f"   Packages: {', '.join(sorted(third_party))}")

        return third_party

    except Exception as e:
        print(f"   ERROR: Failed to parse Python file: {e}", file=sys.stderr)
        sys.exit(1)


def get_installed_version(package: str) -> str:
    """Get the installed version of a package"""
    try:
        result = subprocess.run(
            [sys.executable, '-m', 'pip', 'show', package],
            capture_output=True,
            text=True,
            check=False
        )

        if result.returncode == 0:
            for line in result.stdout.split('\n'):
                if line.startswith('Version:'):
                    return line.split(':', 1)[1].strip()
        return None
    except Exception:
        return None


def create_requirements(packages: Set[str], requirements_file: str) -> List[str]:
    """Create requirements.txt with discovered packages"""
    print(f"\n[2/5] Creating requirements file: {requirements_file}")

    requirements = []
    for package in sorted(packages):
        version = get_installed_version(package)
        if version:
            req = f"{package}=={version}"
            print(f"   ✓ {req}")
        else:
            req = package
            print(f"   ? {req} (version unknown, will use latest)")
        requirements.append(req)

    # Add PyInstaller if not already there
    if 'pyinstaller' not in packages:
        requirements.append('pyinstaller>=6.0.0')
        print(f"   + pyinstaller>=6.0.0 (required for building)")

    try:
        with open(requirements_file, 'w') as f:
            f.write('\n'.join(requirements) + '\n')
        print(f"   Created: {requirements_file}")
        return requirements
    except Exception as e:
        print(f"   ERROR: Failed to create requirements file: {e}", file=sys.stderr)
        sys.exit(1)


def install_dependencies(requirements_file: str, skip_install: bool) -> bool:
    """Install dependencies from requirements file"""
    if skip_install:
        print(f"\n[3/5] Skipping dependency installation (--skip-install)")
        return True

    print(f"\n[3/5] Installing dependencies from {requirements_file}")
    print("   This may take a few minutes...")

    try:
        result = subprocess.run(
            [sys.executable, '-m', 'pip', 'install', '-r', requirements_file],
            capture_output=True,
            text=True
        )

        if result.returncode == 0:
            print("   ✓ All dependencies installed successfully")
            return True
        else:
            print(f"   ERROR: Failed to install dependencies", file=sys.stderr)
            print(result.stderr, file=sys.stderr)
            return False

    except Exception as e:
        print(f"   ERROR: Failed to run pip install: {e}", file=sys.stderr)
        return False


def build_binary(python_file: str, output_name: str, packages: Set[str], extra_imports: List[str]) -> bool:
    """Build standalone binary using PyInstaller"""
    print(f"\n[4/5] Building standalone binary: {output_name}")

    # Combine discovered packages with extra imports
    all_hidden_imports = sorted(packages | set(extra_imports))

    # Build PyInstaller command
    cmd = [
        sys.executable, '-m', 'PyInstaller',
        '--onefile',
        '--name', output_name,
        '--clean'
    ]

    # Add all hidden imports
    for imp in all_hidden_imports:
        cmd.extend(['--hidden-import', imp])

    cmd.append(python_file)

    print(f"   PyInstaller command:")
    print(f"   {' '.join(cmd)}")
    print("   Building... (this may take several minutes)")

    try:
        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode == 0:
            binary_path = Path('dist') / output_name
            if binary_path.exists():
                size_mb = binary_path.stat().st_size / (1024 * 1024)
                print(f"   ✓ Binary built successfully: {binary_path}")
                print(f"   Size: {size_mb:.1f} MB")
                return True
            else:
                print(f"   ERROR: Build completed but binary not found at {binary_path}", file=sys.stderr)
                return False
        else:
            print(f"   ERROR: PyInstaller failed", file=sys.stderr)
            print(result.stderr, file=sys.stderr)
            return False

    except Exception as e:
        print(f"   ERROR: Failed to run PyInstaller: {e}", file=sys.stderr)
        return False


def cleanup_build_artifacts(keep_spec: bool):
    """Clean up PyInstaller build artifacts"""
    print(f"\n[5/5] Cleaning up build artifacts")

    artifacts = ['build', '*.spec']
    if not keep_spec:
        artifacts.append('*.spec')

    for pattern in artifacts:
        if '*' in pattern:
            # Handle wildcards
            for file in Path('.').glob(pattern):
                if file.is_file():
                    try:
                        file.unlink()
                        print(f"   Removed: {file}")
                    except Exception as e:
                        print(f"   Warning: Could not remove {file}: {e}")
        else:
            # Handle directories
            path = Path(pattern)
            if path.exists() and path.is_dir():
                try:
                    import shutil
                    shutil.rmtree(path)
                    print(f"   Removed: {path}/")
                except Exception as e:
                    print(f"   Warning: Could not remove {path}: {e}")


def main():
    parser = argparse.ArgumentParser(
        description='Generic binary builder for Python scripts',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )

    parser.add_argument('python_file', help='Python script to build into binary')
    parser.add_argument('--output-name', help='Name for output binary (default: script name)')
    parser.add_argument('--extra-imports', help='Additional hidden imports (comma-separated)', default='')
    parser.add_argument('--skip-install', action='store_true',
                       help='Skip pip install step (use if dependencies already installed)')
    parser.add_argument('--keep-spec', action='store_true',
                       help='Keep the .spec file after build')
    parser.add_argument('--requirements-file', default='requirements.txt',
                       help='Name for requirements file (default: requirements.txt)')

    args = parser.parse_args()

    # Validate input file
    python_file = Path(args.python_file)
    if not python_file.exists():
        print(f"ERROR: Python file not found: {args.python_file}", file=sys.stderr)
        sys.exit(1)

    if not python_file.suffix == '.py':
        print(f"ERROR: File must be a Python script (.py): {args.python_file}", file=sys.stderr)
        sys.exit(1)

    # Determine output name
    output_name = args.output_name or python_file.stem

    # Parse extra imports
    extra_imports = [imp.strip() for imp in args.extra_imports.split(',') if imp.strip()]

    print("=" * 70)
    print("GENERIC PYTHON BINARY BUILDER")
    print("=" * 70)
    print(f"Input file:  {python_file}")
    print(f"Output name: {output_name}")
    print(f"Python:      {sys.executable}")
    print(f"Virtual env: {sys.prefix}")
    print("=" * 70)

    # Step 1: Discover imports
    packages = discover_imports(str(python_file))

    # Step 2: Create requirements file
    create_requirements(packages, args.requirements_file)

    # Step 3: Install dependencies
    if not install_dependencies(args.requirements_file, args.skip_install):
        print("\nBUILD FAILED: Could not install dependencies", file=sys.stderr)
        sys.exit(1)

    # Step 4: Build binary
    if not build_binary(str(python_file), output_name, packages, extra_imports):
        print("\nBUILD FAILED: Could not create binary", file=sys.stderr)
        sys.exit(1)

    # Step 5: Cleanup
    cleanup_build_artifacts(args.keep_spec)

    print("\n" + "=" * 70)
    print("BUILD SUCCESSFUL!")
    print("=" * 70)
    print(f"Binary location: dist/{output_name}")
    print(f"Requirements:    {args.requirements_file}")
    print("\nTo test your binary:")
    print(f"  ./dist/{output_name} --help")
    print("\nTo distribute:")
    print(f"  tar -czf {output_name}.tar.gz -C dist {output_name}")
    print("=" * 70)


if __name__ == '__main__':
    main()
