# R/typst-layout.R


# .cv_section() ---------------------------------------------------------

#' Create a Typst CV section heading
#'
#' Generates a raw Typst block for a CV section heading. The first letter of
#' the section title is styled with the CV accent color. The heading is
#' followed by a horizontal rule that fills the remaining line width.
#'
#' @param title A character string. The section title to display, e.g.
#'   `"Education"` or `"Publications"`.
#'
#' @return A character string of raw Typst markup.
#'
#' @keywords internal
.cv_section <- function(title) {
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
        .typst_escape(first),
        .typst_escape(rest)
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
.cv_entry <- function(title        = "",
                      organization = "",
                      detail       = "",
                      when         = "",
                      where        = "") {
    title        <- .typst_escape(title)
    organization <- .typst_escape(organization)
    detail       <- .typst_escape(detail)
    when         <- .typst_escape(when)
    where        <- .typst_escape(where)
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
