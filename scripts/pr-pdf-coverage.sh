#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TEMPLATES_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
source "$SCRIPT_DIR/pdf-build-common.sh"
OUTPUT_DIR=""
WORK_DIR=""
PROJECT_NAME="PR Coverage Report"
PROJECT_ID="pr-coverage"
KEEP_WORK_DIR=false

usage() {
  cat <<'EOF'
Usage: scripts/pr-pdf-coverage.sh [--output-dir PATH] [--work-dir PATH] [--project-name NAME] [--project-id ID] [--keep-work-dir]

Generate PDF coverage artifacts used to validate pull requests.
The build includes all target categories and all finding templates.
EOF
}

while (($#)); do
  case "$1" in
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
    --project-id)
      PROJECT_ID="$2"
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

PROJECT_ID=$(sanitize_identifier "$PROJECT_ID")

if [[ -z "$PROJECT_ID" ]]; then
  echo "Project id cannot be empty" >&2
  exit 1
fi

if [[ -z "$WORK_DIR" ]]; then
  WORK_DIR=$(mktemp -d)
fi

if [[ -z "$OUTPUT_DIR" ]]; then
  OUTPUT_DIR="$TEMPLATES_DIR/dist/pr-pdf-coverage/$PROJECT_ID"
fi

cleanup() {
  if [[ "$KEEP_WORK_DIR" != true ]]; then
    rm -rf "$WORK_DIR"
  fi
}

trap cleanup EXIT

OUTPUT_DIR=$(ensure_absolute_dir "$OUTPUT_DIR")

setup_sereto_build_environment "$WORK_DIR" "$TEMPLATES_DIR"
initialize_sereto_project "$PROJECT_ID" "$PROJECT_NAME"
add_example_people_and_dates

TARGET_FIXTURES_DIR="$TEMPLATES_DIR/tests/fixtures/pr-pdf-coverage/targets"

TARGET_SPECS=(
  "cicd|CI/CD Pipeline|cicd.json"
  "dast|Web Application|dast.json"
  "infrastructure|Infrastructure|infrastructure.json"
  "kubernetes|Kubernetes Cluster|kubernetes.json"
  "mobile|Mobile Application|mobile.json"
  "portal|Cloud Portal|portal.json"
  "sast|Source Code|sast.json"
  "scenario|Scenario Test|scenario.json"
)

TARGET_COUNT=${#TARGET_SPECS[@]}

if ((TARGET_COUNT == 0)); then
  echo "TARGET_SPECS cannot be empty" >&2
  exit 1
fi

for target_spec in "${TARGET_SPECS[@]}"; do
  IFS='|' read -r category target_name fixture_file <<<"$target_spec"
  add_target_from_fixture "$category" "$target_name" "$TARGET_FIXTURES_DIR/$fixture_file"
done

# Generate the statement of work PDF.
sereto pdf sow
copy_pdf "$SERETO_PROJECTS_PATH/$PROJECT_ID/pdf" "$OUTPUT_DIR/pr-coverage-sow.pdf" '*Statement of Work.pdf'

# Detect available risks from the CLI to keep compatibility with different SeReTo versions.
load_sereto_risks RISKS

GROUP_RISK=$(preferred_risk "info" "${RISKS[@]}")

# Ensure every target category renders finding-group and finding details.
for ((target_id=1; target_id<=TARGET_COUNT; target_id++)); do
  sereto findings add --non-interactive \
    --target "$target_id" \
    --group-name "Coverage Group $target_id" \
    --name "Coverage finding $target_id" \
    --risk "$GROUP_RISK" \
    --template "$SERETO_TEMPLATES_PATH/categories/generic/findings/from_scratch.md.j2"
done

# Ensure every finding template currently in the repository is rendered at least once.
load_finding_templates FINDING_TEMPLATES "$SERETO_TEMPLATES_PATH"

for template_path in "${FINDING_TEMPLATES[@]}"; do
  target_for_template=$(target_index_for_template "$template_path" TARGET_SPECS)

  sereto findings add --non-interactive \
    --target "$target_for_template" \
    --risk "$GROUP_RISK" \
    --template "$template_path" \
    --var 'images=["info"]'
done

# Generate a partial report PDF for every finding group.
sereto pdf finding-group --all

PDF_DIR="$SERETO_PROJECTS_PATH/$PROJECT_ID/pdf"
mapfile -d '' FINDING_GROUP_PDFS < <(
  find "$PDF_DIR" -maxdepth 1 -type f -name 'target_*.pdf' \
    -print0 | sort -z
)

if ((${#FINDING_GROUP_PDFS[@]} == 0)); then
  echo "No finding-group PDFs were generated in $PDF_DIR" >&2
  exit 1
fi

for finding_group_pdf in "${FINDING_GROUP_PDFS[@]}"; do
  pdf_name=$(basename "$finding_group_pdf")
  copy_pdf "$PDF_DIR" "$OUTPUT_DIR/pr-coverage-finding-group-$pdf_name" "$pdf_name"
done

# Generate the report PDF.
sereto pdf report
copy_pdf "$SERETO_PROJECTS_PATH/$PROJECT_ID/pdf" "$OUTPUT_DIR/pr-coverage-report.pdf" '*Report.pdf'

if [[ ! -s "$OUTPUT_DIR/pr-coverage-sow.pdf" || ! -s "$OUTPUT_DIR/pr-coverage-report.pdf" ]]; then
  echo "Generated PDFs are missing or empty" >&2
  exit 1
fi

printf 'Rendered %s finding templates.\n' "${#FINDING_TEMPLATES[@]}"
printf 'Generated %s finding-group PDFs.\n' "${#FINDING_GROUP_PDFS[@]}"
printf 'Generated PR coverage PDFs in %s\n' "$OUTPUT_DIR"
