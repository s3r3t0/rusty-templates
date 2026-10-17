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
}

find_pdf() {
  local search_dir="$1"
  shift
  local pattern candidate

  for pattern in "$@"; do
    candidate=$(find "$search_dir" -maxdepth 1 -type f -name "$pattern" | sort | head -n1)
    if [[ -n "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  find_latest_pdf "$search_dir"
}

copy_pdf() {
  local search_dir="$1"
  local output_path="$2"
  shift 2
  local source_path

  source_path=$(find_pdf "$search_dir" "$@")
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo "Unable to find generated PDF in $search_dir" >&2
    exit 1
  fi

  cp "$source_path" "$output_path"
}

while (($#)); do
  case "$1" in
    --version)
      TAG="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --work-dir)
      WORK_DIR="$2"
      shift 2
      ;;
    --project-name)
      PROJECT_NAME="$2"
      shift 2
      ;;
    --keep-work-dir)
      KEEP_WORK_DIR=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$TAG" ]]; then
  echo "Missing required --version argument" >&2
  usage >&2
  exit 1
fi

if [[ ! "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid version '$TAG'. Expected vX.Y.Z" >&2
  exit 1
fi

if [[ -z "$WORK_DIR" ]]; then
  WORK_DIR=$(mktemp -d)
fi

if [[ -z "$OUTPUT_DIR" ]]; then
  OUTPUT_DIR="$SCRIPT_DIR/dist/example-pdfs/$TAG"
fi

cleanup() {
  if [[ "$KEEP_WORK_DIR" != true ]]; then
    rm -rf "$WORK_DIR"
  fi
}

trap cleanup EXIT

mkdir -p "$OUTPUT_DIR"

export SERETO_PROJECTS_PATH="$WORK_DIR"
export SERETO_TEMPLATES_PATH="$SCRIPT_DIR"

cd "$WORK_DIR"

uv venv
source .venv/bin/activate
uv pip install sereto --requirements "$SERETO_TEMPLATES_PATH/requirements.txt"
uv pip install -U sereto

sereto new "$TAG" --non-interactive --name "$PROJECT_NAME"
cd "$SERETO_PROJECTS_PATH/$TAG"

# Add people to the Sereto project configuration.
sereto config people add --non-interactive \
  --type author \
  --name "John Doe" \
  --business-unit "ACME Inc." \
  --email "john.doe@acme.net" \
  --role "Penetration Tester"
sereto config people add --non-interactive \
  --type technical_contact \
  --name "Wile E. Coyote" \
  --business-unit "ACME Inc." \
  --email "wile.e.coyote@acme.net" \
  --role "Penetration Testing Division Lead"
sereto config people add --non-interactive \
  --type reviewer \
  --name "Jane Doe" \
  --business-unit "ACME Inc." \
  --email "jane.doe@acme.net" \
  --role "Quality Assurance Officer"
sereto config people add --non-interactive \
  --type requestor \
  --name "Road Runner" \
  --business-unit "Example Services Ltd." \
  --email "road.runner@example.com" \
  --role "Chief Information Security Officer"

# Add dates to the Sereto project configuration.
sereto config dates add --non-interactive \
  --type sow_sent \
  --date "01-Feb-2026"
sereto config dates add --non-interactive \
  --type pentest_ongoing \
  --date "10-Feb-2026" \
  --end "20-Feb-2026"
sereto config dates add --non-interactive \
  --type pentest_ongoing \
  --date "25-Feb-2026"
sereto config dates add --non-interactive \
  --type review \
  --date "27-Feb-2026"
sereto config dates add --non-interactive \
  --type report_sent \
  --date "28-Feb-2026"

# Configure targets for the Sereto project.
read -r -d '' DAST <<'JSON' || true
{
  "id": "0x01",
  "locators": [
    {
      "type": "url",
      "value": "https://juice-shop.herokuapp.com/"
    },
    {
      "type": "url",
      "value": "http://demo.owasp-juice.shop/"
    }
  ],
  "documents": [
    {
      "type": "clickpath",
      "value": "Pwning OWASP Juice Shop"
    },
    {
      "type": "api",
      "value": "openapi.json"
    }
  ],
  "dst_ips_dynamic": true,
  "dst_ips_dynamic_details": "Heroku",
  "src_ips": [
    "198.51.100.42"
  ],
  "ip_filtering": true,
  "ip_allowed": true,
  "authentication": false,
  "exposure": "external",
  "environment": "acceptance",
  "waf_present": true,
  "waf_whitelisted": false
}
JSON

read -r -d '' MOBA <<'JSON' || true
{
  "id": "0x02",
  "documents": [
    {
      "type": "clickpath",
      "value": "OWASP MAS Crackmes"
    }
  ],
  "android": {
    "file_integrity": {
      "UnCrackable-Level1.apk": "sha256:1da8bf57d266109f9a07c01bf7111a1975ce01f190b9d914bcd3ae3dbef96f21",
      "UnCrackable-Level2.apk": "sha256:4c7980ef1f6cc29508f38417c2a5b5b7721eeb4a3d7f00a0c1a08f5192fa6ddd"
    },
    "package_name": "owasp.mstg.uncrackable1",
    "version_name": "1.0",
    "version_code": "1"
  },
  "ios": {
    "file_integrity": {
      "UnCrackable-Level1.ipa": "sha256:8ade899b5f574f92dc2f1fb9fcf7093d9c6297e288985526391279cc5ae1db0f"
    },
    "bundle_id": "owasp.mstg.uncrackable1",
    "short_version_string": "1.0",
    "version": "1"
  }
}
JSON

read -r -d '' SAST <<'JSON' || true
{
  "id": "0x03",
  "locators": [
    {
      "type": "url",
      "value": "https://github.com/juice-shop/juice-shop"
    }
  ],
  "code_origin": "vcs",
  "code_origin_name": "GitHub",
  "code_integrity": {
    "v20.3.0": "sha1:f189f521266f42c6bd05884468292000cee852ed"
  }
}
JSON

sereto config targets add --non-interactive \
  --category dast \
  --name "Juice Shop" \
  --extra "$DAST"
sereto config targets add --non-interactive \
  --category mobile \
  --name "OWASP UnCrackable" \
  --extra "$MOBA"
sereto config targets add --non-interactive \
  --category sast \
  --name "Juice Shop Source Code" \
  --extra "$SAST"

# Generate the Statement of Work (SOW) PDF for the Sereto project.
sereto pdf sow
copy_pdf "$SERETO_PROJECTS_PATH/$TAG/pdf" "$OUTPUT_DIR/${TAG}-sow.pdf" 'sow.pdf' 'sow*.pdf'

# Add example findings to the Sereto project.
mapfile -t RISKS < <(
  sereto finding add --help |
    sed -n 's/.*-r, --risk \[\(.*\)\].*/\1/p' |
    tr '|' '\n'
)

if ((${#RISKS[@]} == 0)); then
  echo "No risks found in sereto finding add --help" >&2
  exit 1
fi

FIRST_RISK="${RISKS[0]}"

sereto findings add --non-interactive \
  --target 1 \
  --group-name "Group finding" \
  --name "$FIRST_RISK finding" \
  --risk "$FIRST_RISK" \
  --template "${SERETO_TEMPLATES_PATH}/categories/generic/findings/from_scratch.md.j2"
sereto findings add --non-interactive \
  --target 1 \
  --name "finding $FIRST_RISK" \
  --risk "$FIRST_RISK" \
  --template "${SERETO_TEMPLATES_PATH}/categories/generic/findings/from_scratch.md.j2"

for risk in "${RISKS[@]:1}"; do
  sereto findings add --non-interactive \
    --target 1 \
    --group "finding_group_group_finding" \
    --name "$risk finding" \
    --risk "$risk" \
    --template "${SERETO_TEMPLATES_PATH}/categories/generic/findings/from_scratch.md.j2"
  sereto findings add --non-interactive \
    --target 1 \
    --name "finding $risk" \
    --risk "$risk" \
    --template "${SERETO_TEMPLATES_PATH}/categories/generic/findings/from_scratch.md.j2"
done

sereto findings add --non-interactive \
  --target 2 \
  --template "${SERETO_TEMPLATES_PATH}/categories/generic/findings/example.md.j2" \
  --var 'images=["info"]'

TEST_PATH="${SERETO_TEMPLATES_PATH}/categories/test/findings"
for test_file in "$TEST_PATH"/*.md.j2; do
  sereto findings add --non-interactive \
    --target 3 \
    --risk "info" \
    --template "$test_file"
done

# Generate the final report PDF for the Sereto project.
sereto pdf report
copy_pdf "$SERETO_PROJECTS_PATH/$TAG/pdf" "$OUTPUT_DIR/${TAG}-report.pdf" 'report.pdf' 'report*.pdf'

printf 'Generated example PDFs in %s\n' "$OUTPUT_DIR"
