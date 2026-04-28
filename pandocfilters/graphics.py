#!/usr/bin/env python3
"""A pandoc filter that has the Typst writer use custom graphics environment.

Usage:
    pandoc --filter ./graphics.py -o myfile.typ myfile.md
"""

from pathlib import Path

import panflute as pf
import panflute.elements

# panflute 2.3.1 predates Typst support in pandoc; add it to the allowlist
panflute.elements.RAW_FORMATS.add("typst")


def get_typst_attributes(attrs: dict[str, str]) -> str:
    result = []
    for key, value in attrs.items():
        match key:
            case "width" | "height" | "page":
                result.append(f"{key}: {value}")
            case "fit" | "scaling":
                result.append(f'{key}: "{value}"')

    return ", ".join(result) + ", " if result else ""


def graphics(elem: pf.Element, doc: pf.Doc) -> list[pf.RawInline] | None:
    if not isinstance(elem, pf.Image) or doc.format != "typst":
        return None

    url = elem.url
    attrs = elem.attributes
    alt = pf.stringify(elem)

    path = Path(f"/pictures/{url}")
    image_path = path if path.suffix else path.with_suffix(".png")
    typst_attrs = get_typst_attributes(attrs)
    alt_attr = caption_attr = ""
    if alt:
        alt_attr = f'alt: "{alt}"'
        caption_attr = f', caption: "{alt}"'
    return [
        pf.RawInline(
            text=f'#figure(image("{image_path}", {typst_attrs}{alt_attr}){caption_attr})',
            format="typst",
        )
    ]


def main() -> None:
    """cli entry point"""
    pf.run_filter(graphics)


if __name__ == "__main__":
    main()
