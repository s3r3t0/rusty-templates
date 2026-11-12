#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TEMPLATES_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
source "$SCRIPT_DIR/pdf-build-common.sh"
TAG=""
OUTPUT_DIR=""
WORK_DIR=""
PROJECT_NAME="Test Report"
KEEP_WORK_DIR=false

usage() {
  cat <<'EOF'
Usage: scripts/release.sh --version vX.Y.Z [--output-dir PATH] [--work-dir PATH] [--project-name NAME] [--keep-work-dir]

Generate the example SoW and report PDFs used for releases.
EOF
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
  OUTPUT_DIR="$TEMPLATES_DIR/dist/example-pdfs/$TAG"
fi

cleanup() {
  if [[ "$KEEP_WORK_DIR" != true ]]; then
    rm -rf "$WORK_DIR"
  fi
}

trap cleanup EXIT

OUTPUT_DIR=$(ensure_absolute_dir "$OUTPUT_DIR")

setup_sereto_build_environment "$WORK_DIR" "$TEMPLATES_DIR"
initialize_sereto_project "$TAG" "$PROJECT_NAME"
add_example_people_and_dates

TARGET_FIXTURES_DIR="$TEMPLATES_DIR/tests/fixtures/release/targets"

TARGET_SPECS=(
  "dast|Juice Shop|dast.json"
  "mobile|OWASP UnCrackable|mobile.json"
  "sast|Juice Shop Source Code|sast.json"
)

for target_spec in "${TARGET_SPECS[@]}"; do
  IFS='|' read -r category target_name fixture_file <<<"$target_spec"
  add_target_from_fixture "$category" "$target_name" "$TARGET_FIXTURES_DIR/$fixture_file"
done

# Generate the Statement of Work (SOW) PDF for the Sereto project.
sereto pdf sow
copy_pdf "$SERETO_PROJECTS_PATH/$TAG/pdf" "$OUTPUT_DIR/${TAG}-sow.pdf" '*Statement of Work.pdf'

# Add example findings to the Sereto project.
load_sereto_risks RISKS

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
copy_pdf "$SERETO_PROJECTS_PATH/$TAG/pdf" "$OUTPUT_DIR/${TAG}-report.pdf" '*Report.pdf'

printf 'Generated example PDFs in %s\n' "$OUTPUT_DIR"
