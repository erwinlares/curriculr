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
#' The bullet character is ▪ (U+25AA, BLACK SMALL SQUARE). The list is
#' set slightly smaller than body text and indented to sit visually beneath
#' the organization line.
#'
#' @param title A character string. The main entry label.
#' @param organization A character string. The secondary line: employer,
#'   institution, publisher, or venue. Defaults to `""`.
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

    # Build each bullet line as a Typst content line
    bullet_lines <- vapply(details, function(d) {
        sprintf(
            "    #pad(left: 1em)[#text(size: 8.25pt, fill: bodygray)[\u25aa #h(0.3em) %s]]\\",
            typst_escape(d)
        )
    }, character(1L))

    # Last bullet should not have a trailing backslash (line break)
    if (length(bullet_lines) > 0L) {
        bullet_lines[[length(bullet_lines)]] <- sub("\\\\$", "",
                                                    bullet_lines[[length(bullet_lines)]])
    }

    bullets_block <- paste(bullet_lines, collapse = "\n")

    sprintf(
        paste0(
            '\n```{=typst}\n',
            '#grid(\n',
            '  columns: (1fr, 1.68in),\n',
            '  gutter: 0.65em,\n',
            '  [\n',
            '    #text(size: 9.15pt, weight: "semibold", fill: dark)[%s]\\\n',
            '    %s\n',
            '  ],\n',
            '  [#align(right)[#text(size: 8.1pt, fill: accent)[%s]]]\n',
            ')\n',
            '#v(0.36em)\n',
            '```\n'
        ),
        title,
        bullets_block,
        right
    )
}
