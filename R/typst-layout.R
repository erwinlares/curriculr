# R/typst-layout.R


# cv_section() ----------------------------------------------------------

#' Create a Typst CV section heading
#'
#' Generates a raw Typst block for a CV section heading. The first letter of
#' the section title is styled with the CV accent color. The heading is
#' followed by a horizontal rule that fills the remaining line width.
#'
#' This function is called inside `CV.qmd` to emit section headings. It is
#' exported so that users building custom Quarto templates can call it
#' directly without using `:::`.
#'
#' @param title A character string. The section title to display, e.g.
#'   `"Education"` or `"Publications"`.
#'
#' @return A character string of raw Typst markup.
#'
#' @export
cv_section <- function(title) {
    first <- substr(title, 1, 1)
    rest  <- substr(title, 2, nchar(title))

    sprintf(
        paste0(
            '\n```{=typst}\n',
            '#v(0.58em)\n',
            '#grid(\n',
            '  columns: (auto, 1fr),\n',
            '  gutter: 0.65em,\n',
            '  align: horizon,\n',
            '  [#text(size: 13.8pt, weight: "regular", fill: dark)',
            '[#text(fill: accent)[%s]%s]],\n',
            '  [#line(length: 100%%, stroke: 0.55pt + rulegray)]\n',
            ')\n',
            '#v(0.20em)\n',
            '```\n'
        ),
        typst_escape(first),
        typst_escape(rest)
    )
}


# .cv_entry() -----------------------------------------------------------

#' Create a Typst CV entry
#'
#' Generates a raw Typst block for one CV entry. The entry is laid out as a
#' two-column grid: the left column holds the title and metadata; the right
#' column holds the date and location, right-aligned in the accent color.
#'
#' All arguments are optional except `title`. Empty strings are handled
#' gracefully — missing metadata, dates, or locations are simply omitted from
#' the rendered output rather than leaving blank space.
#'
#' @param title A character string. The main entry label: degree, job title,
#'   project name, publication title, skill area, etc.
#' @param organization A character string. The secondary line: employer,
#'   institution, publisher, or venue. Defaults to `""`.
#' @param detail A character string. Additional context shown after the
#'   organization line. Defaults to `""`.
#' @param when A character string. The date or date range, typically produced
#'   by `.cv_date_range()` or `.cv_year_range()`. Defaults to `""`.
#' @param where A character string. Location associated with the entry.
#'   Defaults to `""`.
#'
#' @return A character string of raw Typst markup.
#'
#' @keywords internal
#' @noRd
.cv_entry <- function(title        = "",
                      organization = "",
                      detail       = "",
                      when         = "",
                      where        = "") {
    title        <- typst_escape(title)
    organization <- typst_escape(organization)
    detail       <- typst_escape(detail)
    when         <- typst_escape(when)
    where        <- typst_escape(where)

    meta_parts <- c(organization, detail)
    meta_parts <- meta_parts[nzchar(meta_parts)]
    meta       <- paste(meta_parts, collapse = " \u2014 ")

    right_parts <- c(when, where)
    right       <- paste(right_parts[nzchar(right_parts)], collapse = "\\\n")

    sprintf(
        paste0(
            '\n```{=typst}\n',
            '#grid(\n',
            '  columns: (1fr, 1.68in),\n',
            '  gutter: 0.65em,\n',
            '  [\n',
            '    #text(size: 9.15pt, weight: "semibold", fill: dark)[%s]\\\n',
            '    #text(size: 8.25pt, fill: bodygray)[%s]\n',
            '  ],\n',
            '  [#align(right)[#text(size: 8.1pt, fill: accent)[%s]]]\n',
            ')\n',
            '#v(0.36em)\n',
            '```\n'
        ),
        title,
        meta,
        right
    )
}

# .cv_entry_bulleted() --------------------------------------------------

#' Create a Typst CV entry with a bulleted detail list
#'
#' Generates a raw Typst block for one CV entry where multiple detail items
#' are rendered as an indented bulleted list beneath the entry header. Used
#' when more than one row shares the same composite key (title, organization,
#' dates, location) in the source data.
#'
#' The bullet character is ▪ (U+25AA, BLACK SMALL SQUARE). The list is set
#' slightly smaller than body text and indented to sit visually beneath the
#' entry title, with wrapped lines hanging under the bullet body rather than
#' returning to the left margin.
#'
#' All vertical spacing in this block is set explicitly rather than inherited
#' from the surrounding document context. This matters for reproducibility.
#' An earlier implementation wrapped each bullet in its own `#pad()`, which is
#' a block-level element in Typst; the gap between two bullets was therefore
#' governed by the document's `par.spacing` (Typst default `1.2em`) while
#' wrapping inside a single bullet was governed by `par.leading` (default
#' `0.65em`). That asymmetry produced conspicuously wide inter-bullet gaps,
#' and — because both values resolve against whatever `#set par(...)` happens
#' to be in scope at render time — it made the rendered spacing a property of
#' the document rather than of the package. Setting `leading` and the list's
#' own `spacing` inside a scoped content block removes that dependency, so the
#' same data renders identically regardless of the enclosing template.
#'
#' @param title A character string. The main entry label.
#' @param organization A character string. The secondary line: employer,
#'   institution, publisher, or venue. Accepted for call-site symmetry with
#'   `.cv_entry()` but not rendered — organization context is expected to be
#'   embedded in the detail text itself.
#' @param details A character vector. One element per bullet point.
#' @param when A character string. The date or date range. Defaults to `""`.
#' @param where A character string. Location associated with the entry.
#'   Defaults to `""`.
#'
#' @return A character string of raw Typst markup.
#'
#' @keywords internal
#' @noRd
.cv_entry_bulleted <- function(title        = "",
                               organization = "",
                               details      = character(0),
                               when         = "",
                               where        = "") {

    title        <- typst_escape(title)
    organization <- typst_escape(organization)
    when         <- typst_escape(when)
    where        <- typst_escape(where)

    right_parts <- c(when, where)
    right       <- paste(right_parts[nzchar(right_parts)], collapse = "\\\n")

    # -- Layout constants for the bulleted list -------------------------------
    # Gathered here so the whole visual contract of the list is legible in one
    # place, and so a future `branding`/theme option has a single seam to hook
    # into rather than values scattered through a sprintf template.
    bullet_marker      <- "\u25aa"   # U+25AA BLACK SMALL SQUARE
    bullet_size        <- "8.25pt"   # matches .cv_entry() detail text
    bullet_above       <- "0.30em"   # gap between the title line and the list
    bullet_leading     <- "0.42em"   # between wrapped lines within one bullet
    bullet_spacing     <- "0.46em"   # between consecutive bullets
    bullet_indent      <- "0.55em"   # left indent of the marker column
    bullet_body_indent <- "0.40em"   # gap between the marker and its text

    # -- Build the list block -------------------------------------------------
    # `.build_section_blocks()` only routes here when length(details) > 1, but
    # guard anyway: `#list()` with no items is not valid Typst.
    if (length(details) == 0L) {
        list_block <- ""
    } else {
        items <- vapply(
            details,
            function(d) sprintf("        [%s],", typst_escape(d)),
            character(1L),
            USE.NAMES = FALSE
        )

        list_block <- sprintf(
            paste0(
                '    #block(above: %s, below: 0em)[\n',
                '      #set par(leading: %s)\n',
                '      #set text(size: %s, fill: bodygray)\n',
                '      #list(\n',
                '        marker: [%s],\n',
                '        indent: %s,\n',
                '        body-indent: %s,\n',
                '        tight: false,\n',
                '        spacing: %s,\n',
                '%s\n',
                '      )\n',
                '    ]'
            ),
            bullet_above,
            bullet_leading,
            bullet_size,
            bullet_marker,
            bullet_indent,
            bullet_body_indent,
            bullet_spacing,
            paste(items, collapse = "\n")
        )
    }

    sprintf(
        paste0(
            '\n```{=typst}\n',
            '#grid(\n',
            '  columns: (1fr, 1.68in),\n',
            '  gutter: 0.65em,\n',
            '  [\n',
            '    #text(size: 9.15pt, weight: "semibold", fill: dark)[%s]\n',
            '%s\n',
            '  ],\n',
            '  [#align(right)[#text(size: 8.1pt, fill: accent)[%s]]]\n',
            ')\n',
            '#v(0.36em)\n',
            '```\n'
        ),
        title,
        list_block,
        right
    )
}
