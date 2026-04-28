#!/usr/bin/env python3
"""A pandoc filter for translating markdown acronym tags
    into typst glossy tags

Usage:
    pandoc --filter ./acronyms.py -o myfile.typ myfile.md
"""

import re

import panflute as pf
import panflute.elements

# panflute 2.3.1 predates Typst support in pandoc; add it to the allowlist
panflute.elements.RAW_FORMATS.add("typst")

tags = {
    ":": "",
    ":<": ":short",
    ":>": ":long",
    ":!": ":both",
    "+:": ":pl",
    "+:<": ":short:pl",
    "+:>": ":long:pl",
    "+:!": ":both:pl",
    "^:": ":cap",
    "^:<": ":short:cap",
    "^:>": ":long:cap",
    "^:!": ":both:cap",
    "+^:": ":pl:cap",
    "+^:<": ":short:pl:cap",
    "+^:>": ":long:pl:cap",
    "+^:!": ":both:pl:cap",
}


regex = re.compile(
    r"""# regex for acronym tag in format [!+^acronym!]
    (?P<opening>\[!)      # Opening part of the acronym tag
    (?P<prefix>\+?\^?)    # Optional plural and capitalized prefixes
    (?P<tag>[\w-]+)       # Acronym id
    (?P<extension>[<>!]?) # Optional suffix for choice of the display form
    (?P<closing>\])       # Closing part of the acronym tag """,
    re.VERBOSE,
)


def acronyms(elem: pf.Element, doc: pf.Doc) -> list[pf.RawInline] | None:
    """Translate the acronym tags.

    Args:
        elem    pandoc element
        doc     pandoc document
    """

    if not isinstance(elem, pf.Str) or doc.format != "typst":
        return None

    match = re.search(regex, elem.text)

    if not match:
        return None

    prefix = elem.text[: match.start()]
    suffix = elem.text[match.end() :]

    tag = "@" + match.group("tag") + tags[match.group("prefix") + ":" + match.group("extension")]
    return [pf.RawInline(text=t, format=doc.format) for t in [prefix, tag, suffix] if t]


def main() -> None:
    """cli entry point"""
    pf.run_filter(acronyms)


if __name__ == "__main__":
    main()
