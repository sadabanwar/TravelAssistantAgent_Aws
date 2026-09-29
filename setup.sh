#!/usr/bin/env bash
# Setup — Future with Shadab AI Agents masterclass (macOS/Linux).  Run from this folder:   ./setup.sh
set -e

PYTHON=${PYTHON:-python3}
HOMEBREW_EXPAT_LIB="/opt/homebrew/opt/expat/lib"
USE_BREW_EXPAT=""

echo "==> Checking Python version (need 3.10+)"
"$PYTHON" -c 'import sys; assert sys.version_info >= (3,10), "Need Python 3.10 or higher"'
"$PYTHON" --version

echo "==> Creating virtual environment (.venv)"
rm -rf .venv
try_venv() {
  local python_cmd="$1"
  local env_lib_path="$2"
  if [ -n "$env_lib_path" ] && [ -d "$env_lib_path" ]; then
    DYLD_LIBRARY_PATH="$env_lib_path${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" "$python_cmd" -m venv .venv
  else
    "$python_cmd" -m venv .venv
  fi
}

if ! try_venv "$PYTHON" ""; then
  if [ -d "$HOMEBREW_EXPAT_LIB" ]; then
    echo "==> python3 venv failed; retrying with Homebrew expat library"
    rm -rf .venv
    if try_venv "$PYTHON" "$HOMEBREW_EXPAT_LIB"; then
      USE_BREW_EXPAT="1"
      echo "==> virtual environment created using Homebrew expat"
    fi
  fi
fi

if [ ! -d .venv ]; then
  echo "==> python3 venv failed; trying python3.13 if available"
  rm -rf .venv
  if command -v python3.13 >/dev/null 2>&1; then
    PYTHON=python3.13
    if ! try_venv "$PYTHON" "" && [ -d "$HOMEBREW_EXPAT_LIB" ]; then
      if try_venv "$PYTHON" "$HOMEBREW_EXPAT_LIB"; then
        USE_BREW_EXPAT="1"
      fi
    fi
  fi
fi

if [ ! -d .venv ]; then
  echo "ERROR: virtual environment creation failed."
  echo "Install python@3.13 and expat with Homebrew and retry, or set PYTHON=/path/to/python3.13"
  echo "  brew install python@3.13 expat"
  echo "If you still see pyexpat / ensurepip errors, retry with:"
  echo "  DYLD_LIBRARY_PATH=/opt/homebrew/opt/expat/lib PYTHON=/opt/homebrew/opt/python@3.13/bin/python3.13 ./setup.sh"
  exit 1
fi

if [ -n "$USE_BREW_EXPAT" ]; then
  export DYLD_LIBRARY_PATH="$HOMEBREW_EXPAT_LIB${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
fi

source .venv/bin/activate

echo "==> Upgrading pip"
python -m pip install --upgrade pip --quiet

echo "==> Installing packages (takes a couple of minutes)"
pip install -r requirements.txt

echo "==> Setting region for this session"
export AWS_DEFAULT_REGION=us-east-1

echo ""
echo "=================================================================="
echo " Packages installed."
echo ""
echo " NEXT: make sure your AWS credentials are set, then run the check:"
echo ""
echo "   source .venv/bin/activate"
echo "   export AWS_DEFAULT_REGION=us-east-1"
echo "   python 00_check_setup.py"
echo "=================================================================="
