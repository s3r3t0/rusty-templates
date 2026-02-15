# AGENTS.md — Contributor Guide for rusty-templates

## Project Overview

- **Typst-based report templates** for the [Security Reporting Tool (SeReTo)](https://github.com/s3r3t0/sereto), producing penetration test reports as PDF.
- **Languages/tools:** Typst, Jinja2 templates, Python (pandoc filters & plugins), Pandoc, Markdown.
- **Key directories:**
  - `skel/` — scaffold skeleton copied into new SeReTo projects (layouts, includes, pictures, config).
  - `categories/` — per-category templates and pre-written findings (dast, infrastructure, mobile, sast, etc.).
  - `pandocfilters/` — Python pandoc filters (acronyms → Typst glossy, image handling).
  - `plugins/` — SeReTo CLI plugins (Python/Click).
- **Upstream docs:** <https://sereto.s4n.cz/>

## Setup & Dev Workflow

### Prerequisites

- **Typst** ≥ v0.14.0
- **Pandoc** ≥ v3.1.2
- **Python** ≥ 3.12 (for pandoc filters and plugins)
- **uv** (recommended) or pip

### Install

```sh
# Install SeReTo CLI with template plugin dependencies
uv tool install sereto@latest --with-requirements requirements.txt
```

### Repo Map (quick reference)

| Path | Purpose |
|------|---------|
| `skel/layouts/*.typ.j2` | Jinja2/Typst page layouts (report, target, finding_group, sow) |
| `skel/includes/sereto.typ` | Core Typst show rules, page setup, helper functions |
| `skel/includes/theme.typ` | Colour palette and semantic colour aliases |
| `skel/includes/macros.typ.j2` | Reusable Jinja2/Typst macros (findings table, detail boxes) |
| `skel/includes/glossary.yaml` | Acronym definitions for the glossy package |
| `skel/includes/glossy/` | Vendored glossy Typst package |
| `skel/pictures/` | Risk indicator PNGs and logo SVG |
| `categories/<cat>/target.typ.j2` | Per-category target chapter template |
| `categories/<cat>/finding_group.typ.j2` | Per-category finding-group rendering |
| `categories/<cat>/findings/*.md.j2` | Pre-written finding templates (Markdown + TOML frontmatter) |
| `categories/<cat>/skel/` | Boilerplate files copied when a target of this category is added |
| `pandocfilters/acronyms.py` | Converts `[!acronym]` syntax → Typst glossy references |
| `pandocfilters/graphics.py` | Converts Markdown images → Typst `#figure(image(...))` |
| `plugins/test.py` | Example SeReTo CLI plugin |

## Template Syntax — Critical Rules

### Two Jinja2 dialects

| File type | Delimiters | Example |
|-----------|-----------|---------|
| **Typst templates** (`.typ.j2`) | `((* block *))` / `((( expr )))` / `((= comment =))` | `((( target.data.name )))` |
| **Markdown findings** (`.md.j2`) | `{% block %}` / `{{ expr }}` / `{# comment #}` | `{{ f.vars.images }}` |

> **Do not mix dialects.** Typst templates use `(( ))` to avoid clashing with Typst's `{ }` syntax. Markdown templates use standard Jinja2.

### Finding file structure (`.md.j2`)

1. **TOML frontmatter** between `+++` fences: `name`, `risk`, `keywords`, `[[variables]]`.
2. **Extends** `_base.md` (each category has its own `_base.md` in `skel/findings/`).
3. **Override blocks:** `description`, `likelihood`, `impact`, `recommendation`, `reference`.
4. Risk levels (in order): `critical`, `high`, `medium`, `low`, `info`, `closed`.

### Acronym syntax (in Markdown findings)

Use `[!tag]` where `tag` matches a key in `skel/includes/glossary.yaml`.

| Syntax | Meaning |
|--------|---------|
| `[!api]` | default form |
| `[!api<]` | short form |
| `[!api>]` | long form |
| `[!api!]` | full (short + long) |
| `[!+api]` | plural |
| `[!^api]` | capitalised |
| `[!+^api]` | plural + capitalised |

Prefixes (`+`, `^`) go before the tag; suffixes (`<`, `>`, `!`) go after.

### Image references

- In Markdown findings: `![alt text](filename){width=90%}` — the pandoc filter prepends `/pictures/`.
- In Typst templates: `image("/pictures/filename.png")` — use absolute path from project root.

## Testing & Validation

### Automated testing with tox

The project uses **tox** to orchestrate all automated checks. Configuration lives in `tox.ini`.

| tox environment | What it runs | Command |
|-----------------|-------------|---------|
| `py3{12,13,14}` | **pytest** unit tests in `tests/` | `python -m pytest tests` |
| `lint` | **ruff** linter on `pandocfilters/` and `plugins/` | `ruff check pandocfilters && ruff check plugins` |
| `type` | **mypy** type checking on `plugins/` | `mypy plugins` |
| `format` | **ruff** import sorting + formatting on all Python dirs | `ruff check --select I --fix … && ruff format …` |

Run the full suite:

```sh
tox
```

Run a single environment:

```sh
tox -e lint      # linting only
tox -e type      # type checking only
tox -e py312     # pytest on Python 3.12
tox -e format    # auto-format code
```

> **CI integration:** The `[gh]` section in `tox.ini` maps Python versions to tox environments for GitHub Actions. On Python 3.12, CI runs `py312`, `type`, and `lint`.

### Writing tests

- Tests live in `tests/` and use **pytest**.
- Follow the existing pattern in `tests/test_plugin_test.py` — group related tests in a class, use `click.testing.CliRunner` for CLI plugins, and `unittest.mock.patch` for isolating side effects.
- Name test files `test_<module>.py` and test classes `Test<Subject>`.

### Manual validation (templates)

In addition to the automated checks, verify template changes manually before finishing:

1. **Render a test report** using SeReTo to verify templates compile without errors.
2. **Check Typst compilation:** ensure `.typ` output from Jinja2 renders without Typst errors.
3. **Validate TOML frontmatter** in any new/edited findings (well-formed `+++` blocks).
4. **Run pandoc filters manually** if you changed them:
   ```sh
   echo '{"pandoc-api-version":[1,23,1],"meta":{},"blocks":[]}' | python pandocfilters/acronyms.py typst
   ```
5. **Check glossary.yaml** if you added new acronyms — keys must be lowercase, `short` and `long` are required.

## Coding Conventions & Architecture

### File naming

- Typst+Jinja2 templates: `<name>.typ.j2`
- Markdown+Jinja2 findings: `<name>.md.j2` (use `snake_case`)
- Skeleton boilerplate: plain `.typ.j2` (scope, approach, prerequisites)
- Finding names in TOML frontmatter should be title-cased human-readable strings.

### Category structure

Every category under `categories/` should contain:
- `target.typ.j2` — main target chapter (extends macros, includes scope/approach/findings)
- `finding_group.typ.j2` — finding-group detail rendering
- `findings/` — reusable finding templates
- `skel/` — skeleton files: `approach.typ.j2`, `scope.typ.j2`, `findings.toml`, `findings/_base.md`

Exception: `categories/generic/` only has `findings/` (no target/skel — used for cross-category findings).

### Patterns

- **Do** use `((* extends "_base.typ.j2" *))` for layout inheritance in Typst templates.
- **Do** use `{% extends "_base.md" %}` for finding inheritance in Markdown.
- **Do** use the `macros.typ.j2` helpers (`findings_table`, `finding_group_details`, `finding_details`) rather than duplicating table/box markup.
- **Do** add new acronyms to `skel/includes/glossary.yaml` when introducing terms.
- **Don't** hardcode team/company names — use Jinja2 context variables (`team`, `company`, `c.*`).
- **Don't** put Typst raw code in `.md.j2` files — the pandoc pipeline handles conversion.

### Writing conventions for findings

- Write in third person, professional tone: *"The application could further restrict…"*, *"During the engagement, the team discovered…"*
- `description` block: state the issue factually, include evidence (screenshots, tables).
- `likelihood` block: assess realistic exploitability. Single paragraph or bullet list.
- `impact` block: describe consequences of exploitation. Single paragraph or bullet list.
- `recommendation` block: provide actionable remediation steps. Single paragraph or bullet list.
- `reference` block: link to authoritative sources (OWASP, MDN, vendor docs).

## Change Hygiene

- **Minimal diffs** — don't reformat files you didn't change.
- **Update `CHANGELOG.md`** under `[Unreleased]` for any user-visible change.
- **Update `glossary.yaml`** if you introduce new acronyms.
- **Don't add Python dependencies** to `requirements.txt` without discussion.
- **Versioning** follows [SemVer](https://semver.org/) and tracks SeReTo's major.minor version.

## Security / Secrets

- **Never commit real client data**, IP addresses, credentials, or engagement details.
- Finding templates must use placeholder/example data only.
- `skel/.seretoignore` controls what is excluded from report attachments — review it if you add new file types.
- The `skel/outputs/sereto` file is a branding marker, not executable.

## Communication / Task Handling

- **Ask before large refactors** — especially changes to `_base.typ.j2`, `sereto.typ`, or `macros.typ.j2` which affect all outputs.
- **State assumptions** about SeReTo version compatibility.
- **List what you changed** — template files, glossary entries, new findings, etc.
- If unsure about Jinja2 context variables available at render time, consult the [SeReTo documentation](https://sereto.s4n.cz/).
