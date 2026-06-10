#!/bin/bash
# Setup script for kpr-writer skill
# Reads venv path from ~/.secrets.json and installs openpyxl

set -euo pipefail

VENV=$(jq -r '.kpr.venv' ~/.secrets.json)
VENV="${VENV/#\~/$HOME}"

if [ ! -f "${VENV}/bin/activate" ]; then
    echo "Error: venv not found at ${VENV}"
    echo "Create it with: python3 -m venv ${VENV}"
    exit 1
fi

source "${VENV}/bin/activate"
pip install -q openpyxl
echo "openpyxl installed in ${VENV}"
