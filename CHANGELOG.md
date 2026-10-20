# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Resolve `--output-dir` to an absolute path in the release script so example PDF generation works even after changing into the temporary build directory.

## [0.9.4] - 2026-10-20

### Fixed

- Flatten example PDF artifact output in CI so release assets are attached directly as PDFs instead of being nested under a version subdirectory.
- Add a release preflight validation step that fails early with diagnostics when `dist/*.pdf` is empty.

## [0.9.3] - 2026-10-20

### Fixed

- Ensure the example PDF pipeline explicitly installs Typst and Pandoc in CI and verifies the resolved versions before rendering.
- Fail fast in the release script when Typst or Pandoc is missing, with actionable installation hints.

## [0.9.2] - 2026-10-19

### Fixed

- Simplify the example PDF workflow to rely on the release script's default temporary directories instead of the GitHub Actions `runner.temp` context.

## [0.9.1] - 2026-10-19

### Fixed

- Ensure example PDF CI builds seed SeReTo settings non-interactively in an isolated config directory so ambient user-profile settings do not affect the build or trigger the interactive initial setup flow.

## [0.9.0] - 2026-10-19

### Changed

- Added release automation workflows for manual release preparation, merged-PR publishing, and reusable example PDF generation.

## [0.8.0] - 2026-10-16

### Added

- Added support `documents` field in scope to allow for multiple documents to be listed in the report.
- DAST category: Added support for `exposure` field in scope.
- DAST category: Added support for `api` related setup.

### Changed

- Finding groups now use the new `suggested_name` property instead of the custom logic to determine the name of the group.
- DAST category: Show target protection bypass questions only when the protections are in place.
- INFRA category: Show target protection bypass questions only when the protections are in place.
- Due date calculation now takes into account the `exposure` field in scope for DAST category.
- Development tooling now uses a pinned `uv.lock` tox toolchain in CI and Dependabot instead of the pip-compiled `requirements-tox.txt` flow.

### Removed

- DAST category: Removed support for `clickpath` and `api` fields in scope. Use `documents` field instead.

## [0.7.0] - 2026-06-12

### Added

- Added a debug template for inspecting the configuration and data structures.
- Added TEST category and finding templates for testing and debugging purposes.

### Changed

- Target partial report now uses the compact format.
- SAST category: Show `code_origin_name` only when non-empty.
- Renamed example finding "Test Finding" to "Example Finding" to properly reflect its purpose as syntax reference.
- Make tables breakable.
- Pandoc filter rewritten from `pandocliters` to `panflute`.

### Fixed

- Render report even if no people are defined.
- Use SoW dates in SoW template version table.
- Added more space for test name on the title page.
- Do not show "Acronyms" section if there are no acronyms defined.
- Allow breaking of long words in code snippets and identifiers to prevent overflow issues in the report.

## [0.6.0] - 2026-04-02

### Added

- Include subfinding name in group name for groups of 1 subfinding.

### Changed

- Improved glossary style and formatting
- Acronyms filter: Support alphanumeric characters, dashes, and underscores for better handling of various naming conventions.

### Fixed

- Acronyms now properly link to the glossary
- Colorboxes no longer leave orphaned titles at the end of page
- Finding headers no longer break between keywords and their values

## [0.5.1] - 2026-02-16

### Added

- Added Noto fonts

### Fixed

- Fixed SoW build issues by removing forgotten includes and correcting indentation
- Fixed graphics filter when image has no attributes

## [0.5.0] - 2026-02-15

This is the initial release of the project. The versioning starts at 0.5.0 to align with the versioning of SeReTo.

[Unreleased]: https://github.com/s3r3t0/rusty-templates/compare/v0.9.4...HEAD
[0.9.4]: https://github.com/s3r3t0/rusty-templates/releases/tag/v0.9.4
[0.9.3]: https://github.com/s3r3t0/rusty-templates/releases/tag/v0.9.3
[0.9.2]: https://github.com/s3r3t0/rusty-templates/releases/tag/v0.9.2
[0.9.1]: https://github.com/s3r3t0/rusty-templates/releases/tag/v0.9.1
[0.9.0]: https://github.com/s3r3t0/rusty-templates/releases/tag/v0.9.0
[0.8.0]: https://github.com/s3r3t0/rusty-templates/releases/tag/v0.8.0
[0.7.0]: https://github.com/s3r3t0/rusty-templates/releases/tag/v0.7.0
[0.6.0]: https://github.com/s3r3t0/rusty-templates/releases/tag/v0.6.0
[0.5.1]: https://github.com/s3r3t0/rusty-templates/releases/tag/v0.5.1
[0.5.0]: https://github.com/s3r3t0/rusty-templates/releases/tag/v0.5.0
