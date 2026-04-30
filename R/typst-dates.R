# R/typst-dates.R


# .cv_date_range() ------------------------------------------------------

#' Format a CV date range from month and year columns
#'
#' Builds a human-readable date range from a CV data row using the columns
#' `startMonth`, `startYear`, `endMonth`, and `endYear`. Supports ongoing
#' entries by treating an `endMonth` value of `"present"` (case-insensitive)
#' as `"Present"`.
#'
#' @param row A one-row data frame representing one CV entry.
#'
#' @return A character string containing a formatted date range.
#'
#' @keywords internal
.cv_date_range <- function(row) {
    start_month <- .cv_value(row, "startMonth")
    start_year  <- .cv_value(row, "startYear")
    end_month   <- .cv_value(row, "endMonth")
    end_year    <- .cv_value(row, "endYear")

    start <- trimws(paste(start_month, start_year))
    if (start == "") start <- start_year

    if (tolower(end_month) == "present") {
        return(trimws(paste(start, "- Present")))
    }

    if (end_year == "") return(start)

    end <- trimws(paste(end_month, end_year))
    if (end == "") end <- end_year

    trimws(paste(start, "-", end))
}


# .cv_year_range() ------------------------------------------------------

#' Format a CV year range
#'
#' Builds a year-only range from `startYear` and `endYear` columns. If
#' `endYear` is missing or empty, only the start year is returned.
#'
#' @param row A one-row data frame representing one CV entry.
#'
#' @return A character string containing a year or year range.
#'
#' @keywords internal
.cv_year_range <- function(row) {
    start_year <- .cv_value(row, "startYear")
    end_year   <- .cv_value(row, "endYear")

    if (end_year == "") start_year else paste(start_year, "-", end_year)
}
