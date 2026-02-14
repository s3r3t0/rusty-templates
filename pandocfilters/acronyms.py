#!/usr/bin/env python3
''' A pandoc filter for translating markdown acronym tags
    into typst glossy tags

Usage:
    pandoc --filter ./acronyms.py -o myfile.typ myfile.md
'''

import re
from pandocfilters import toJSONFilter, RawInline


tags = {
    ':': '',
    ':<': ':short',
    ':>': ':long',
    ':!': ':both',
    '+:': ':pl',
    '+:<': ':short:pl',
    '+:>': ':long:pl',
    '+:!': ':both:pl',
    '^:': ':cap',
    '^:<': ':short:cap',
    '^:>': ':long:cap',
    '^:!': ':both:cap',
    '+^:': ':pl:cap',
    '+^:<': ':short:pl:cap',
    '+^:>': ':long:pl:cap',
    '+^:!': ':both:pl:cap'
}


regex = re.compile(r'''# regex for acronym tag in format [!+^acronym!]
    (?P<opening>\[!)      # Opening part of the acronym tag
    (?P<prefix>\+?\^?)    # Optional plural and capitalized prefixes
    (?P<tag>[a-zA-Z]+)    # Acronym id
    (?P<extension>[<>!]?) # Optional suffix for choice of the display form
    (?P<closing>\])       # Closing part of the acronym tag ''',
                   re.VERBOSE)


def acronyms(key, value, format, meta):
    ''' Translate the acronym tags.

    Args:
        key     type of pandoc object
        value   contents of pandoc object
        format  target output format
        meta    document metadata
    '''

    if key != 'Str' or format != 'typst':
        return

    match = re.search(regex, value)

    if match:
        return [RawInline(format, value[:match.start()]),
                RawInline(format, '@' + match.group('tag')
                          + tags[match.group('prefix')
                                       + ':'
                                       + match.group('extension')]
                          ),
                RawInline(format, value[match.end():])]


def main():
    """cli entry point"""
    toJSONFilter(acronyms)


if __name__ == '__main__':
    main()
