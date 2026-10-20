#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TAG=""
OUTPUT_DIR=""
WORK_DIR=""
PROJECT_NAME="Test Report"
KEEP_WORK_DIR=false

usage() {
  cat <<'EOF'
Usage: release.sh --version vX.Y.Z [--output-dir PATH] [--work-dir PATH] [--project-name NAME] [--keep-work-dir]

Generate the example SoW and report PDFs used for releases.
EOF
}

require_command() {
  local cmd="$1"
  local install_hint="$2"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command '$cmd'." >&2
    echo "$install_hint" >&2
    exit 1
  fi
}

find_latest_pdf() {
  local search_dir="$1"
  local latest_path=""
  local latest_mtime=0
  local pdf_path pdf_mtime

  while IFS= read -r -d '' pdf_path; do
    pdf_mtime=$(stat -c '%Y' "$pdf_path")
    if ((pdf_mtime > latest_mtime)); then
      latest_mtime=$pdf_mtime
      latest_path=$pdf_path
    fi
  done < <(find "$search_dir" -type f -name '*.pdf' -print0)

  printf '%s\n' "$latest_path"
done
```

