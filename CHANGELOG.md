# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/s3r3t0/rusty-templates/compare/v0.7.0...HEAD
[0.7.0]: https://github.com/s3r3t0/rusty-templates/releases/tag/v0.7.0
[0.6.0]: https://github.com/s3r3t0/rusty-templates/releases/tag/v0.6.0
[0.5.1]: https://github.com/s3r3t0/rusty-templates/releases/tag/v0.5.1
[0.5.0]: https://github.com/s3r3t0/rusty-templates/releases/tag/v0.5.0
