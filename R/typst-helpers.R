# R/typst-helpers.R


# %||% ------------------------------------------------------------------

`%||%` <- function(x, y) {
    if (is.null(x) || length(x) == 0 || all(is.na(x))) y else x
}


# .cv_value() -----------------------------------------------------------

#' Extract one value from a CV data row
#'
#' Safely extracts a named value from a one-row data frame. Returns a default
#' value if the column does not exist or if the value is missing.
#'
#' @param row A one-row data frame representing one CV entry.
#' @param name A character string. Name of the column to extract.
#' @param default A character string. Fallback value when the column or value
#'   is absent. Defaults to `""`.
#'
#' @return A character string.
#'
#' @keywords internal
.cv_value <- function(row, name, default = "") {
    if (!name %in% names(row)) return(default)
    value <- row[[name]][[1]]
    if (length(value) == 0 || is.na(value)) return(default)
    as.character(value)
}


# typst_escape() --------------------------------------------------------

#' Escape text for safe use in Typst markup
#'
#' Converts an input value to a Typst-safe character string. Removes simple
#' HTML line break tags, collapses repeated whitespace, escapes Typst special
#' characters, and trims leading and trailing whitespace.
#'
#' CV content comes from Excel and may contain characters that Typst treats as
#' markup: `#`, `$`, `%`, `&`, `~`, `_`, `^`, `{`, `}`, `[`, `]`, or `@`.
#' The `@` character is included because Typst may interpret email addresses as
#' references to labels.
#'
#' @param x A value or vector to escape.
#'
#' @return A character vector with Typst-sensitive characters escaped.
#'
#' @export
typst_escape <- function(x) {
    x <- as.character(x %||% "")
    x[is.na(x)] <- ""
    x <- gsub("<br\\s*/?>", " ", x, ignore.case = TRUE)
    x <- gsub("\\s+", " ", x)
    x <- gsub("\\\\", "\\\\\\\\", x)
    x <- gsub("([#$%&~_^{}\\[\\]@])", "\\\\\\1", x, perl = TRUE)
    trimws(x)
}


# .resolve_date_fun() ---------------------------------------------------

#' Resolve a date_fun token to a function
#'
#' Maps a string token from the `sections` sheet to the corresponding date
#' formatting function used by `cv_render_section()`. This allows date
#' formatting behaviour to be controlled from the Excel workbook rather than
#' hardcoded in the Quarto template.
#'
#' @param token A character string. One of `"date"`, `"year"`,
#'   `"month_year"`, `"year_only"`, or `"none"`.
#'
#' @return A function suitable for passing to the `date_fun` argument of
#'   `cv_render_section()`, or `NULL` when `token` is `"none"`.
#'
#' @export
resolve_date_fun <- function(token) {
    token <- trimws(tolower(as.character(token %||% "none")))

    switch(token,
           date = .cv_date_range,

           year = .cv_year_range,

           month_year = function(row) {
               trimws(paste(.cv_value(row, "startMonth"),
                            .cv_value(row, "startYear")))
           },

           year_only = function(row) {
               .cv_value(row, "startYear")
           },

           none = NULL,

           {
               cli::cli_warn(
                   "Unknown date_fun token {.val {token}}. Defaulting to {.val none}."
               )
               NULL
           }
    )
}
