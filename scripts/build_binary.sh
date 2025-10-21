#!/bin/bash
#
# Generic Binary Builder - Bash Wrapper
#
# This script provides a simple interface to build standalone binaries from Python scripts.
#
# PREREQUISITES (you must do these manually first):
#   1. Create virtual environment:
#      python3 -m venv build-env
#
#   2. Activate the virtual environment:
#      source build-env/bin/activate
#
#   3. Install PyInstaller:
#      pip install pyinstaller
#
# USAGE:
#   ./build_binary.sh <python_file> [output_name]
#
# EXAMPLES:
#   ./build_binary.sh excel_converter.py
#   ./build_binary.sh ../scripts/data_profiler.py data_profiler_binary
#
# OPTIONS:
#   Set environment variables to customize behavior:
#     SKIP_INSTALL=1         Skip pip install step
#     KEEP_SPEC=1            Keep .spec file after build
#     EXTRA_IMPORTS="mod1,mod2"  Add extra hidden imports
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILDER_SCRIPT="${SCRIPT_DIR}/build_binary.py"

# Check if builder script exists
if [ ! -f "$BUILDER_SCRIPT" ]; then
    echo -e "${RED}ERROR: build_binary.py not found at: ${BUILDER_SCRIPT}${NC}" >&2
    exit 1
fi

# Check if we're in a virtual environment
check_venv() {
    if [ -z "$VIRTUAL_ENV" ]; then
        echo -e "${YELLOW}WARNING: Not in a virtual environment!${NC}" >&2
        echo -e "${YELLOW}It's recommended to use a virtual environment.${NC}" >&2
        echo ""
        echo "To create and activate a virtual environment:"
        echo "  python3 -m venv build-env"
        echo "  source build-env/bin/activate"
        echo ""
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo -e "${GREEN}✓ Virtual environment active: ${VIRTUAL_ENV}${NC}"
    fi
}

# Check if PyInstaller is installed
check_pyinstaller() {
    if ! python -c "import PyInstaller" 2>/dev/null; then
        echo -e "${RED}ERROR: PyInstaller not installed${NC}" >&2
        echo "Install it with: pip install pyinstaller"
        exit 1
    fi
    echo -e "${GREEN}✓ PyInstaller is installed${NC}"
}

# Show usage
show_usage() {
    echo "Usage: $0 <python_file> [output_name]"
    echo ""
    echo "Arguments:"
    echo "  python_file    Path to Python script to build"
    echo "  output_name    Optional: Name for output binary (default: script name)"
    echo ""
    echo "Environment Variables:"
    echo "  SKIP_INSTALL=1              Skip pip install step"
    echo "  KEEP_SPEC=1                 Keep .spec file after build"
    echo "  EXTRA_IMPORTS=\"mod1,mod2\"   Add extra hidden imports"
    echo ""
    echo "Examples:"
    echo "  $0 excel_converter.py"
    echo "  $0 script.py my_binary"
    echo "  SKIP_INSTALL=1 $0 script.py"
    echo "  EXTRA_IMPORTS=\"sklearn,torch\" $0 ml_script.py"
    exit 1
}

# Main script
main() {
    # Check arguments
    if [ $# -lt 1 ]; then
        echo -e "${RED}ERROR: Python file argument required${NC}" >&2
        echo ""
        show_usage
    fi

    PYTHON_FILE="$1"
    OUTPUT_NAME="${2:-}"

    # Validate Python file
    if [ ! -f "$PYTHON_FILE" ]; then
        echo -e "${RED}ERROR: Python file not found: ${PYTHON_FILE}${NC}" >&2
        exit 1
    fi

    # Check prerequisites
    echo -e "${BLUE}Checking prerequisites...${NC}"
    check_venv
    check_pyinstaller
    echo ""

    # Build command
    CMD=(python "$BUILDER_SCRIPT" "$PYTHON_FILE")

    # Add optional arguments
    if [ -n "$OUTPUT_NAME" ]; then
        CMD+=(--output-name "$OUTPUT_NAME")
    fi

    if [ "${SKIP_INSTALL:-0}" = "1" ]; then
        CMD+=(--skip-install)
    fi

    if [ "${KEEP_SPEC:-0}" = "1" ]; then
        CMD+=(--keep-spec)
    fi

    if [ -n "${EXTRA_IMPORTS:-}" ]; then
        CMD+=(--extra-imports "$EXTRA_IMPORTS")
    fi

    # Show command
    echo -e "${BLUE}Running builder...${NC}"
    echo "Command: ${CMD[*]}"
    echo ""

    # Execute
    "${CMD[@]}"
}

# Run main function
main "$@"
