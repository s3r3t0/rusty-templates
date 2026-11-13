#!/bin/bash

require_command() {
  local cmd="$1"
  local install_hint="$2"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command '$cmd'." >&2
    echo "$install_hint" >&2
    exit 1
  fi
}

ensure_absolute_dir() {
  local path="$1"
  mkdir -p "$path"
  (
    cd "$path"
    pwd
  )
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

  return 1
}

copy_pdf() {
  local search_dir="$1"
  local output_path="$2"
  shift 2
  local source_path

  if ! source_path=$(find_pdf "$search_dir" "$@"); then
    echo "Unable to find generated PDF in $search_dir" >&2
    exit 1
  fi

  cp "$source_path" "$output_path"
}

setup_sereto_build_environment() {
  local work_dir="$1"
  local templates_dir="$2"

  export SERETO_PROJECTS_PATH="${SERETO_PROJECTS_PATH:-$work_dir}"
  export SERETO_TEMPLATES_PATH="${SERETO_TEMPLATES_PATH:-$templates_dir}"
  export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$work_dir/.config}"

  mkdir -p "$SERETO_PROJECTS_PATH" "$XDG_CONFIG_HOME"

  if [[ ! -d "$SERETO_TEMPLATES_PATH" ]]; then
    echo "SERETO_TEMPLATES_PATH '$SERETO_TEMPLATES_PATH' does not exist" >&2
    exit 1
  fi

  cd "$work_dir"

  uv venv
  # shellcheck disable=SC1091
  source .venv/bin/activate
  uv pip install sereto --requirements "$SERETO_TEMPLATES_PATH/requirements.txt"
  uv pip install -U sereto

  require_command "typst" "Install Typst v0.14.0+ and ensure it is available in PATH. See https://typst.app/docs/"
  require_command "pandoc" "Install Pandoc v3.1.2+ and ensure it is available in PATH. See https://pandoc.org/installing.html"

  printf 'Using Typst: %s\n' "$(typst --version)"
  printf 'Using Pandoc: %s\n' "$(pandoc --version | head -n1)"
  printf 'Using Sereto: %s\n' "$(sereto --version)"
}

initialize_sereto_project() {
  local project_id="$1"
  local project_name="$2"

  sereto settings edit --non-interactive --extra "{\"projects_path\":\"$SERETO_PROJECTS_PATH\",\"templates_path\":\"$SERETO_TEMPLATES_PATH\"}"
  sereto new "$project_id" --non-interactive --name "$project_name"
  cd "$SERETO_PROJECTS_PATH/$project_id"
}

add_example_people_and_dates() {
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

  sereto config dates add --non-interactive --type sow_sent --date "01-Feb-2026"
  sereto config dates add --non-interactive --type pentest_ongoing --date "10-Feb-2026" --end "20-Feb-2026"
  sereto config dates add --non-interactive --type pentest_ongoing --date "25-Feb-2026"
  sereto config dates add --non-interactive --type review --date "27-Feb-2026"
  sereto config dates add --non-interactive --type report_sent --date "28-Feb-2026"
}

load_sereto_risks() {
  local -n risks_ref=$1
  mapfile -t risks_ref < <(
    sereto finding add --help |
      sed -n 's/.*-r, --risk \[\(.*\)\].*/\1/p' |
      tr '|' '\n'
  )

  if ((${#risks_ref[@]} == 0)); then
    echo "No risks found in sereto finding add --help" >&2
    exit 1
  fi
}

preferred_risk() {
  local preferred="$1"
  shift
  local risk

  for risk in "$@"; do
    if [[ "$risk" == "$preferred" ]]; then
      printf '%s\n' "$risk"
      return 0
    fi
  done

  printf '%s\n' "$1"
}

sanitize_identifier() {
  local input="$1"
  input=$(printf '%s' "$input" | tr -cs 'a-zA-Z0-9._-' '-')
  input=${input#-}
  input=${input:0:20}
  input=${input%-}
  printf '%s\n' "$input"
}

load_finding_templates() {
  local -n templates_ref=$1
  local templates_root="$2"
  mapfile -t templates_ref < <(find "$templates_root/categories" -mindepth 3 -maxdepth 3 -type f -path '*/findings/*.md.j2' | sort)

  if ((${#templates_ref[@]} == 0)); then
    echo "No finding templates found under categories/*/findings" >&2
    exit 1
  fi
}

add_target_from_fixture() {
  local category="$1"
  local name="$2"
  local fixture_path="$3"

  if [[ ! -f "$fixture_path" ]]; then
    echo "Target fixture file not found: $fixture_path" >&2
    exit 1
  fi

  sereto config targets add --non-interactive \
    --category "$category" \
    --name "$name" \
    --extra "$(cat "$fixture_path")"
}

target_index_for_template() {
  local template_path="$1"
  local target_specs_name="$2"
  local -n target_specs_ref="$target_specs_name"
  local target_count=${#target_specs_ref[@]}
  local template_category target_category index

  if ((target_count < 1)); then
    echo "target_count must be greater than zero" >&2
    return 1
  fi

  case "$template_path" in
    */generic/findings/*)
      printf '1\n'
      return
      ;;
    */test/findings/*)
      printf '%s\n' "$target_count"
      return
      ;;
  esac

  template_category=${template_path%/findings/*}
  template_category=${template_category##*/}

  for ((index = 0; index < target_count; index++)); do
    IFS='|' read -r target_category _ <<<"${target_specs_ref[index]}"
    if [[ "$target_category" == "$template_category" ]]; then
      printf '%s\n' "$((index + 1))"
      return
    fi
  done

  printf '1\n'
}
