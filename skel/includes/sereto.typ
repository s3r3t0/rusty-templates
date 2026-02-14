#import "@preview/showybox:2.0.4": showybox
#import "@preview/zebraw:0.6.0": zebraw, zebraw-init
#import "theme.typ": colors

#let font-family = (
  serif: "Noto Serif",
  sans: "Noto Sans",
  mono: "Noto Sans Mono",
)
#font-family.insert("header", font-family.sans)
#font-family.insert("footer", font-family.header)
#font-family.insert("title", font-family.sans)
#font-family.insert("heading", font-family.sans)
#font-family.insert("subheading", font-family.heading)
#font-family.insert("footnote", font-family.sans)
#font-family.insert("text", font-family.serif)
#font-family.insert("raw", font-family.mono)

#let font-size = (
  tiny: 6pt,
  scriptsize: 8pt,
  footnotesize: 9pt,
  small: 10pt,
  normalsize: 10.95pt,
  large: 12pt,
  Large: 14.4pt,
  LARGE: 17.28pt,
  huge: 20.74pt,
  Huge: 24.88pt,
)
#font-size.insert("header", font-size.large)
#font-size.insert("footer", font-size.header)
#font-size.insert("title", font-size.Huge)
#font-size.insert("subtitle", font-size.Large)
#font-size.insert("author", font-size.huge)
#font-size.insert("heading", font-size.LARGE)
#font-size.insert("subheading", font-size.Large)
#font-size.insert("text", font-size.normalsize)
#font-size.insert("raw", font-size.normalsize)
#font-size.insert("footnote", font-size.footnotesize)

#let document-settings = (
  indent: 0em,
  paper: "a4",
  margin: (
    left: 15mm,
    right: 15mm,
    top: 25mm,
    bottom: 15mm,
  ),
  leading: 0.5em,
  above: 1.8em,
  below: 1.4em,
  spacing: 1.2em,
  header-ascent: 20%,
  footer-descent: 30%,
  list-indent: 1em,
)

#let sereto(
  title: [SeReTo Report],
  specification: [],
  subtitle: [],
  author: (),
  date: datetime.today().display("[day]-[month repr:short]-[year]"),
  logo: "/pictures/logo.svg",
  changelog: (),
  format: "full",
  body,
) = {
  let header = {
    set text(
      font: font-family.header,
      size: font-size.header,
      fill: colors.header,
    )
    grid(
      columns: (1fr, 1fr),
      align: (left, horizon + right),
      image(logo, height: 16mm),
      strong(author)
    )
  }

  let footer = context {
    set text(
      font: font-family.footer,
      size: font-size.footer,
      fill: colors.footer,
    )
    grid(
      columns: (1fr, 1fr),
      align: (left, right),
      text(colors.warning)[*CONFIDENTIAL*],
      counter(page).display(),
    )
  }

  set text(
    font: font-family.text,
    size: font-size.text,
    lang: "en",
    fill: colors.text,
  )

  show footnote.entry: set text(
    font: font-family.footnote,
    size: font-size.footnotesize,
    fill: colors.footnote,
  )

  set document(
    title: title,
    author: author,
  )

  set page(
    paper: document-settings.paper,
    margin: document-settings.margin,
    header-ascent: document-settings.header-ascent,
    header: header,
    footer-descent: document-settings.footer-descent,
    footer: footer,
    numbering: "I",
  )

  set par(
    leading: document-settings.leading,
    spacing: document-settings.spacing,
    first-line-indent: (
      amount: document-settings.indent,
      all: true,
    ),
    justify: true,
  )

  show outline.entry: it => if it.level == 1 {
    set text(
      font: font-family.heading,
      fill: colors.text-attentional,
    )
    block(
      above: document-settings.above,
      below: document-settings.below,
      link(
      it.element.location(),
      it.indented(it.prefix(), it.inner())
      )
    )
    } else if it.level in (2, 3) {
      set text(
        font: font-family.subheading,
        fill: colors.text-default,
      )
      block(
        above: document-settings.spacing,
        below: document-settings.leading,
        link(
          it.element.location(),
          it.indented(it.prefix(), it.inner())
        )
      )
    }

  show heading: it => block(above: document-settings.above, below: document-settings.below)[
    #set text(font: font-family.heading)
    #if it.level == 1 {
      set par(justify: true, first-line-indent: 0em)
      set text(font-size.heading, fill: colors.heading)
      if it.numbering != none {
        numbering(it.numbering, ..counter(heading).at(it.location()))
        text((" ", it.body).join())
      } else {
        text(it.body)
      }
    } else if it.level in (2, 3) {
      set text(font-size.subheading, fill: colors.text-attentional)
      if it.numbering != none {
        numbering(it.numbering, ..counter(heading).at(it.location()))
        text((" ", it.body).join())
      } else {
        text(it.body)
      }
    } else {
      set text(font-size.text, fill: colors.text-attentional)
      text(it.body)
    }
  ]

  show link: it => {
    if type(it.dest) == str {
      underline(it)
    } else {
      it
    }
  }

  set list(
    indent: document-settings.list-indent,
    spacing: document-settings.spacing,
  )

  show: zebraw
  show raw: set text(font: font-family.raw, size: font-size.raw)
  show: zebraw-init.with(
    numbering-separator: true,
    lang: false,
    hanging-indent: true,
    radius: 5pt,
  )

  set table(stroke: (x, y) => (
    x: none,
    bottom: if y > 0 { .75pt + colors.table-row } else { 2pt + colors.table-header },
  ))
  show table.cell.where(y: 0): strong

  let version-control(
    version: "Ver.",
    id: "Request ID",
    date: "Date",
    authors: "Authors",
    description: "Description",
    changelog,
  ) = {
    if changelog.len() > 0 and "id" in changelog.at(0).keys() {
      table(
        columns: (auto, auto, auto, 2fr, 2fr),
        rows: auto,
        version, id, date, authors, description,
        ..for v in changelog {
          (
            v.at("version", default: ""),
            v.at("id", default: ""),
            v.at("date"),
            v.at("authors"),
            v.at("description"),
          )
        },
      )
    } else {
      table(
        columns: (auto, auto, 1fr, 1fr),
        rows: auto,
        version, date, authors, description,
        ..for v in changelog {
          (
            v.at("version", default: ""),
            v.at("date"),
            v.at("authors"),
            v.at("description"),
          )
        },
      )
    }
  }

  page(
    header: none,
    footer: none,
    [
      #set text(
        font: font-family.title,
        size: font-size.subtitle,
        weight: "bold",
      )
      #grid(
        align: horizon + center,
        columns: 1fr,
        rows: if format == "compact" {
          (2fr, 1fr, 1fr, 1fr, 3fr, 1fr, 2fr, 15fr)
        } else {
          (2fr, 1fr, 1fr, 1fr, 3fr, 1fr, 2fr, 10fr)
        },
        text(
          fill: colors.warning,
          size: font-size.author,
          upper("Confidential"),
        ),
        text(
          fill: colors.text-attentional,
          size: font-size.title,
          title,
        ),
        text(colors.text-subtle, subtitle),
        text(colors.text-subtle, specification),
        image(logo, height: 32mm),
        text(font-size.author, author),
        text(colors.text-subtle, date),
        if format == "compact" {
          set text(
            font: font-family.text,
            size: font-size.text,
            weight: "regular",
          )
          grid.cell(
            align: left + bottom,
            version-control(changelog)
          )
        }
      )
    ],
  )

  if format == "full" {
    counter(page).update(1)
    page(
      [
        #heading("Version control", outlined: false)
        #version-control(changelog)
      ],
    )

    show outline.entry.where(level: 1): strong
    show outline.entry.where(level: 1): set block(above: 1.2em)
    page(
      outline(depth: 3),
    )
  }

  show heading.where(level: 1): it => pagebreak(weak: true) + it
  set page(numbering: "1")
  counter(page).update(1)

  show: body
}

#let end-preamble(body) = {
  show selector.or(
    heading.where(level: 1),
    heading.where(level: 2),
    heading.where(level: 3),
  ): set heading(numbering: "1.1")
  counter(heading).update(0)

  body
}

#let appendix(body) = {
  show selector.or(
    heading.where(level: 1),
    heading.where(level: 2),
    heading.where(level: 3),
  ): set heading(numbering: "A.1")
  counter(heading).update(0)

  body
}
