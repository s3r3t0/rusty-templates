# AGENTS.md — SeReTo Project Guide

## Project Overview

- This is a **SeReTo (Security Reporting Tool) project** — a penetration test report authored in Markdown and Typst, rendered to PDF.
- Processed by the [SeReTo CLI](https://github.com/s3r3t0/sereto) with [Typst](https://typst.app/) (≥ v0.14.0) and [Pandoc](https://pandoc.org/) (≥ v3.1.2).
- All content is written in **English**.

## Project Structure

| Path | Purpose | Editable? |
|------|---------|-----------|
| `layouts/` | Jinja2/Typst page layouts (report, target, finding_group, sow) | Yes — advanced customisation only |
| `layouts/_base.typ.j2` | Base layout inherited by all others | ⚠️ Edit with caution — affects every output |
| `includes/sereto.typ` | Core Typst show rules, page setup, helpers | **Do not edit** |
| `includes/theme.typ` | Colour palette and semantic colour aliases | **Do not edit** |
| `includes/macros.typ.j2` | Reusable Jinja2/Typst macros (findings table, detail boxes) | Yes |
| `includes/glossary.yaml` | Acronym/glossary definitions | Yes — add new terms here |
| `includes/glossy/` | Vendored glossy Typst package | **Do not edit** |
| `pictures/` | Risk indicator PNGs and logo SVG | Yes — add/replace images |
| `<target>/` | Per-target content directories (scope, approach, findings) | Yes — primary editing area |
| `<target>/findings.toml` | Declares which findings to include and their grouping | Yes |
| `<target>/scope.typ.j2` | Target scope description | Yes |
| `<target>/approach.typ.j2` | Target approach/methodology description | Yes |
| `.build/` | Auto-generated build artefacts | **Do not edit — do not commit** |
| `pdf/` | Generated PDF output | **Do not edit — do not commit** |
| `.sereto` | Project marker file | **Do not edit** |
| `.seretoignore` | Files excluded from report attachments | Yes |
| `outputs/sereto` | Branding marker | **Do not edit** |
| `attachment_exclude/` | Files to exclude from attachments | Yes |

## Content Authoring — Findings

Findings are Markdown files with Jinja2 templating (`.md.j2`), located in target directories or sourced from the template's `categories/` library.

### Finding file structure

1. **TOML frontmatter** between `+++` fences:
   ```
   +++
   name = "Human-Readable Finding Title"
   risk = "high"
   
   [[locators]]
   type = "url"
   description = "Endpoint where the issue was found"
   value = "https://example.com/vulnerable-endpoint"

   [variables]
   images = ["screenshot1.png", "screenshot2.png"]
   +++
   ```
2. **Extends** `_base.md` — always inherit from the category base.
3. **Override these blocks** (all are optional except `description`):

| Block | Content | Format |
|-------|---------|--------|
| `description` | **Required.** State the vulnerability factually, include evidence (screenshots, tables, code samples). | Paragraphs, tables, images |
| `likelihood` | Assess realistic exploitability. | Single paragraph or bullet list |
| `impact` | Describe consequences of exploitation. | Single paragraph or bullet list |
| `recommendation` | Actionable remediation steps. | Single paragraph or bullet list |
| `reference` | Links to authoritative sources (OWASP, MDN, vendor docs). | Bullet list of Markdown links |

### Risk levels

Use exactly one of: `critical`, `high`, `medium`, `low`, `info`, `closed`.

### Tone and wording

- Write in **third person, professional tone**.
- Use factual statements: *"The application does not set the HttpOnly flag…"*
- Avoid first person (*"I found…"*) — use *"the team discovered…"* or passive voice.
- Be specific about what was tested and what was found.

### Acronym syntax

Define acronyms in `includes/glossary.yaml`, then reference them in Markdown findings:

| Syntax | Meaning | Example output |
|--------|---------|----------------|
| `[!api]` | Default form | API |
| `[!api<]` | Short form only | API |
| `[!api>]` | Long form only | Application Programming Interface |
| `[!api!]` | Full (short + long) | Application Programming Interface (API) |
| `[!+api]` | Plural | APIs |
| `[!^api]` | Capitalised | API |
| `[!+^api]` | Plural + capitalised | APIs |

Prefixes (`+` plural, `^` capitalise) go **before** the tag. Suffixes (`<` short, `>` long, `!` full) go **after**.

### Image syntax

In Markdown findings, use standard Markdown image syntax:

```
![Alt text describing the screenshot](filename.png){width=90%}
```

- Place image files in the `pictures/` directory.
- The pandoc filter automatically prepends `/pictures/` to the path.
- **Do not** include the `/pictures/` prefix in the Markdown `()` path.
- Supported formats: PNG, JPEG, SVG.

### Code blocks in findings

Use fenced code blocks with language annotation:

````
```http
GET / HTTP/2
Host: example.com
```
````

````
```{.py}
import os
```
````

### Tables in findings

Use standard Markdown pipe tables with alignment:

```
| Header 1 | Header 2 |
|:---------|:---------|
| cell 1   | cell 2   |
```

## Typst Template Syntax

Layout and target templates (`.typ.j2`) use **custom Jinja2 delimiters** to avoid conflicts with Typst's `{ }` braces:

| Construct | Syntax | Example |
|-----------|--------|---------|
| Block tags | `((* ... *))` | `((* for t in c.targets *))` |
| Expressions | `((( ... )))` | `((( target.data.name )))` |
| Comments | `((= ... =))` | `((= Scope =))` |
| Extends | `((* extends "_base.typ.j2" *))` | |
| Include | `((* include target.uname + "/scope.typ.j2" *))` | |

> **Do not** use standard `{% %}` / `{{ }}` Jinja2 in `.typ.j2` files — they will conflict with Typst syntax.

## Layout / Generated Files

- **`.build/`** — contains intermediate Typst files generated by SeReTo. **Never edit manually**; regenerated on every build.
- **`pdf/`** — contains final PDF output. **Never edit manually; do not commit.**
- Risk chart images (`/.build/<target>/risks.png`) are auto-generated.

## findings.toml — Finding Group Configuration

Each target directory contains a `findings.toml` that declares which findings to include:

```toml
["Finding Group Name"]
findings = ["finding_template_name"]
risk = "high"  # optional — defaults to highest risk in group
```

- Finding names reference `.md.j2` files (without extension) from the category's `findings/` directory.
- Multiple findings can be grouped: `findings = ["finding_a", "finding_b"]`.
- `risk` is optional; if omitted, it defaults to the highest risk among the group's findings.

## Conventions

- **Minimal diffs** — don't reformat files you didn't change.
- **Indentation:**  4 spaces. No tabs.
- **File naming:** `snake_case` for finding files, target directories, and skeleton files.
- Keep `glossary.yaml` sorted alphabetically; add terms in groups if applicable.
- Always add `width=90%` to finding screenshot images for consistent sizing.

## Security

- **Never commit real client data**, IP addresses, credentials, hostnames, or internal URLs.
- Use placeholder/redacted values in committed templates and examples.
- Review `.seretoignore` to ensure sensitive artefacts are excluded from attachments.
- The report PDF is marked **CONFIDENTIAL** — treat all project content accordingly.

## Communication

- **Ask before large changes** to base layouts (`_base.typ.j2`), core includes (`sereto.typ`, `macros.typ.j2`), or theme — these affect every generated output.
- **State assumptions** about which SeReTo version and template version you are targeting.
- **List what you changed** — which findings, targets, glossary entries, or layout files were modified.
- Consult the [SeReTo documentation](https://sereto.s4n.cz/) for available Jinja2 context variables and CLI commands.
