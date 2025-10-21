# Generic Python Binary Builder

A tool to automatically analyze Python scripts, discover dependencies, and build standalone executables using PyInstaller.

## Features

- **Automatic Import Discovery**: Analyzes Python files using AST to find all imports
- **Smart Dependency Detection**: Filters out standard library modules, keeps only third-party packages
- **Requirements Generation**: Auto-generates `requirements.txt` with discovered dependencies
- **One-Command Building**: Handles dependency installation and binary compilation
- **Isolated Environment**: Designed to work in virtual environments to avoid conflicts
- **Cross-Platform**: Works on Linux, macOS, and Windows

## Files

- **`build_binary.py`** - Main Python script with import parsing and dependency discovery
- **`build_binary.sh`** - Bash wrapper for easier usage (Linux/Mac only)

## Prerequisites (Manual Setup)

Before using the builder, you need to set up an isolated environment:

### 1. Create Virtual Environment

```bash
# On your EC2 instance or local machine
cd /path/to/your/project
python3 -m venv build-env
```

### 2. Activate Virtual Environment

```bash
# Linux/Mac
source build-env/bin/activate

# Windows
build-env\Scripts\activate
```

### 3. Install PyInstaller

```bash
pip install pyinstaller
```

### 4. Place Your Python Script

Make sure your Python script is accessible in the current directory or provide the full path.

## Usage

### Option 1: Python Script (Recommended for cross-platform)

```bash
# Basic usage - analyzes, installs deps, and builds
python3 build_binary.py my_script.py

# Specify output name
python3 build_binary.py my_script.py --output-name my_app

# Skip install if dependencies already installed
python3 build_binary.py my_script.py --skip-install

# Add extra hidden imports for packages PyInstaller might miss
python3 build_binary.py my_script.py --extra-imports sklearn,tensorflow

# Keep the .spec file for future customization
python3 build_binary.py my_script.py --keep-spec

# Custom requirements filename
python3 build_binary.py my_script.py --requirements-file deps.txt
```

### Option 2: Bash Wrapper (Linux/Mac only)

```bash
# Make executable (first time only)
chmod +x build_binary.sh

# Basic usage
./build_binary.sh my_script.py

# With custom output name
./build_binary.sh my_script.py my_app

# Using environment variables
SKIP_INSTALL=1 ./build_binary.sh my_script.py
KEEP_SPEC=1 ./build_binary.sh my_script.py
EXTRA_IMPORTS="sklearn,torch" ./build_binary.sh ml_script.py
```

## How It Works

The builder follows these steps:

1. **Analyze Python File** - Parses the script using Python's AST to extract all imports
2. **Create Requirements** - Generates `requirements.txt` with third-party packages only
3. **Install Dependencies** - Runs `pip install -r requirements.txt` in the active venv
4. **Build Binary** - Executes PyInstaller with appropriate flags and hidden imports
5. **Cleanup** - Removes build artifacts, keeping only the final binary in `dist/`

## Example: Building excel_converter.py

```bash
# Setup (one-time)
python3 -m venv build-env
source build-env/bin/activate
pip install pyinstaller

# Build the binary
python3 build_binary.py excel_converter.py

# Result
# ✓ Binary created at: dist/excel_converter
# ✓ Requirements saved: requirements.txt
# ✓ Ready to distribute!

# Test it
./dist/excel_converter --help

# Package for distribution
tar -czf excel_converter.tar.gz -C dist excel_converter
```

## Output

After successful build, you'll find:

- **`dist/excel_converter`** - Your standalone binary (50-100MB typical)
- **`requirements.txt`** - List of dependencies used
- **Build artifacts cleaned** - `build/` and `.spec` removed (unless `--keep-spec`)

## Common Use Cases

### On AWS EC2

```bash
# SSH into EC2
ssh -i key.pem ec2-user@instance-ip

# Setup build environment
python3 -m venv build-env
source build-env/bin/activate
pip install pyinstaller

# Copy your script
# (use scp, git clone, or aws s3 cp)

# Build
python3 build_binary.py your_script.py

# Upload binary to S3 for distribution
aws s3 cp dist/your_script s3://your-bucket/binaries/
```

### For Multiple Scripts

```bash
# Build multiple binaries in one session
source build-env/bin/activate

python3 build_binary.py script1.py --skip-install  # First one installs
python3 build_binary.py script2.py --skip-install  # Reuse deps
python3 build_binary.py script3.py --skip-install  # Reuse deps
```

### With Extra Hidden Imports

Some packages need explicit declaration for PyInstaller:

```bash
# Machine learning scripts
python3 build_binary.py ml_script.py --extra-imports sklearn,torch,tensorflow

# Data processing with custom modules
python3 build_binary.py processor.py --extra-imports custom_module,helper_lib
```

## Troubleshooting

### Import Not Found at Runtime

If the binary fails with "ModuleNotFoundError":

```bash
# Rebuild with the missing module as hidden import
python3 build_binary.py script.py --extra-imports missing_module
```

### Binary Too Large

The binary includes all dependencies. To reduce size:

- Use `--exclude-module` in a custom .spec file
- Consider containerization instead (Docker)

### Build Fails

Check that:
1. You're in an activated virtual environment
2. PyInstaller is installed: `pip list | grep -i pyinstaller`
3. The Python script has no syntax errors
4. All imports are available: `python3 your_script.py --help`

## Advanced: Custom .spec Files

For complex projects, keep and modify the .spec file:

```bash
# Build with --keep-spec
python3 build_binary.py script.py --keep-spec

# Edit script.spec to customize
# Then rebuild directly
pyinstaller script.spec
```

## Distribution

After building, distribute the binary:

```bash
# Create tarball
tar -czf my_app.tar.gz -C dist my_app

# Upload to S3
aws s3 cp my_app.tar.gz s3://bucket/path/

# On target machines (no Python needed!)
wget https://bucket.s3.amazonaws.com/path/my_app.tar.gz
tar -xzf my_app.tar.gz
chmod +x my_app
./my_app --help
```

## Package Support

The builder is **completely package-agnostic** and works with any Python package by:

1. **AST-based discovery** - Analyzes your Python file to find all explicit imports
2. **Standard library filtering** - Automatically excludes built-in modules (no installation needed)
3. **PyInstaller compatibility** - Any package that works with PyInstaller will work

**Common packages that work well:**
- AWS: boto3, botocore, s3transfer
- Data: pandas, numpy, openpyxl, xlrd
- Web: requests, urllib3, flask, fastapi
- Database: psycopg2, pymongo, sqlalchemy

**For dynamic imports:** If a package uses `importlib` or plugin systems, use `--extra-imports` for modules that can't be discovered via AST parsing.

## Notes

- Binary is **platform-specific** (build on same OS as deployment)
- Virtual environment **prevents conflicts** with system packages
- Generated `requirements.txt` uses **exact versions** from your environment
- Build time depends on package size (1-5 minutes typical)
- Binary size is typically **50-100MB** depending on dependencies

## Support

For issues with:
- **This builder**: Check file paths, venv activation, and PyInstaller installation
- **PyInstaller**: See https://pyinstaller.org/en/stable/
- **Specific packages**: Consult package-specific PyInstaller guides
