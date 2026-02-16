#!/usr/bin/env python3
"""A pandoc filter that has the Typst writer use custom graphics environment.

Usage:
    pandoc --filter ./graphics.py -o myfile.typ myfile.md
"""

from pathlib import Path

from pandocfilters import RawInline, stringify, toJSONFilter


def get_typst_attributes(attributes) -> str:
    """Get Typst attributes from pandoc Attr object.

    Args:
        attributes       pandoc Attr object
    """
    _id, _cls, kv = attributes
    result = []

    for key, value in kv:
        match key:
            case "width" | "height" | "page":
                result.append(f"{key}: {value}")
            case "fit" | "scaling":
                result.append(f'{key}: "{value}"')

    return ", ".join(result) + ", " if result else ""


def graphics(key, value, format, _meta):
    """Use custom figure environment in LaTeX/Typst.

    Args:
        key     type of pandoc object
        value   contents of pandoc object
        format  target output format
        meta    document metadata
    """
    if key != "Image" or format != "typst":
        return

    [attributes, alt, [url, _title]] = value

    path = Path(f"/pictures/{url}")
    image_path = path if path.suffix else path.with_suffix(".png")
    typst_attrs = get_typst_attributes(attributes)
    alt_attr = caption_attr = ""
    if alt:
        alt_attr = f'alt: "{stringify(alt)}"'
        caption_attr = f', caption: "{stringify(alt)}"'
    return [
        RawInline(
            format,
            f'#figure(image("{image_path}", {typst_attrs}{alt_attr}){caption_attr})',
        )
    ]


def main():
    """cli entry point"""
    toJSONFilter(graphics)


if __name__ == "__main__":
    main()
