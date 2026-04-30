# R/typst-render.R


# cv_render_section() ---------------------------------------------------

#' Render a CV section from a data frame
#'
#' Iterates over a CV data frame and writes each row as a Typst CV entry by
#' calling `.cv_entry()` for each row and passing the result to [base::cat()].
#'
#' This function is intended to be called inside a Quarto document chunk with
#' `results = 'asis'`. The `cat()` call writes raw Typst blocks directly into
#' the document output stream. Nothing is returned — the function is called
#' entirely for its side effect.
#'
#' For sections that use dates, pass one of `.cv_date_range()` or
#' `.cv_year_range()` as `date_fun`. For sections where dates are not relevant
#' (skills, affiliations), pass `date_fun = NULL`.
#'
#' @param data A data frame containing CV entries. Typically one element of the
#'   list returned by read_cv_data(), e.g. `cv$experience`.
#' @param title_col A character string. Name of the column to use as the entry
#'   title. Required.
#' @param org_col A character string or `NULL`. Name of the column to use as
#'   the organization or secondary text. Defaults to `NULL`.
#' @param detail_col A character string or `NULL`. Name of the column to use as
#'   additional detail. Defaults to `NULL`.
#' @param date_fun A function or `NULL`. Called with each row to produce the
#'   date string. Defaults to `.cv_date_range()`. Pass `NULL` for sections
#'   without dates.
#' @param where_col A character string or `NULL`. Name of the column to use as
#'   the location. Defaults to `"where"`. Pass `NULL` to omit location.
#'
#' @return Invisibly returns `NULL`. Called for its side effect of writing
#'   Typst blocks to the Quarto document output stream.
#'
#' @examples
#' \dontrun{
#' # Inside a Quarto chunk with results = 'asis':
#'
#' # Full entry with date range and location
#' cat(.cv_section("Experience"))
#' cv_render_section(cv$experience,
#'                   title_col  = "title",
#'                   org_col    = "unit",
#'                   detail_col = "detail")
#'
#' # Year-only dates
#' cat(.cv_section("Education"))
#' cv_render_section(cv$education,
#'                   title_col  = "title",
#'                   org_col    = "institution",
#'                   detail_col = "detail",
#'                   date_fun   = .cv_year_range)
#'
#' # No dates, no location
#' cat(.cv_section("Skills"))
#' cv_render_section(cv$skills,
#'                   title_col = "title",
#'                   org_col   = "unit",
#'                   date_fun  = NULL,
#'                   where_col = NULL)
#'
#' # Custom inline date function
#' cat(.cv_section("Presentations"))
#' cv_render_section(cv$presentations,
#'                   title_col = "unit",
#'                   org_col   = "title",
#'                   date_fun  = function(row) {
#'                     trimws(paste(.cv_value(row, "startMonth"),
#'                                  .cv_value(row, "startYear")))
#'                   })
#' }
#'
#' @export
cv_render_section <- function(data,
                              title_col,
                              org_col    = NULL,
                              detail_col = NULL,
                              date_fun   = .cv_date_range,
                              where_col  = "where") {

    if (is.null(data) || nrow(data) == 0) return(invisible(NULL))

    blocks <- .build_section_blocks(
        data       = data,
        title_col  = title_col,
        org_col    = org_col,
        detail_col = detail_col,
        date_fun   = date_fun,
        where_col  = where_col
    )

    cat(blocks)
    invisible(NULL)
}


# .build_section_blocks() -----------------------------------------------

#' Build Typst blocks for a CV section
#'
#' Internal builder called by `cv_render_section()`. Iterates over each row of
#' `data` and assembles a character vector of Typst entry blocks. Separating
#' the building step from the printing step makes the output testable without
#' capturing stdout.
#'
#' @inheritParams cv_render_section
#'
#' @return A character vector of Typst blocks, one element per row in `data`.
#'
#' @keywords internal
.build_section_blocks <- function(data,
                                  title_col,
                                  org_col    = NULL,
                                  detail_col = NULL,
                                  date_fun   = .cv_date_range,
                                  where_col  = "where") {

    blocks <- vector("character", nrow(data))

    for (i in seq_len(nrow(data))) {
        row <- data[i, , drop = FALSE]

        blocks[[i]] <- .cv_entry(
            title        = .cv_value(row, title_col),
            organization = if (!is.null(org_col))    .cv_value(row, org_col)    else "",
            detail       = if (!is.null(detail_col)) .cv_value(row, detail_col) else "",
            when         = if (!is.null(date_fun))   date_fun(row)              else "",
            where        = if (!is.null(where_col))  .cv_value(row, where_col)  else ""
        )
    }

    blocks
}
