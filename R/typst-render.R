# R/typst-render.R


# cv_render_section() ---------------------------------------------------

#' Render a CV section from a data frame
#'
#' Iterates over a CV data frame and writes each row as a Typst CV entry by
#' calling `.cv_entry()` for each row and passing the result to [base::cat()].
#'
#' Rows that share the same combination of `title`, `unit`, `startMonth`,
#' `startYear`, `endMonth`, `endYear`, and `where` are treated as a single
#' entry with multiple responsibilities. When more than one such row exists,
#' the details are rendered as an indented bulleted list beneath the entry
#' header rather than repeating the header for each row.
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
#' \donttest{
#' # Load sample data and render the experience section
#' cv <- read_cv_data(
#'   system.file("extdata", "cv-data-template.xlsx", package = "curriculr")
#' )
#' cv_render_section(cv$experience,
#'                   title_col  = "title",
#'                   org_col    = "unit",
#'                   detail_col = "detail")
#' }
#'
#' \dontrun{
#' # The following examples are intended to be called inside a Quarto chunk
#' # with results = 'asis'. They require internal helpers and a loaded cv object.
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
#' Internal builder called by `cv_render_section()`. Groups rows by their
#' composite key (title, org, date, location), then assembles one Typst block
#' per group. Groups with a single detail row call `.cv_entry()` as before.
#' Groups with multiple detail rows call `.cv_entry_bulleted()`, which renders
#' the details as an indented bulleted list beneath the entry header.
#'
#' Row order within a group is preserved from the original data frame, which
#' is sorted by `startYear` descending in `read_cv_data()`.
#'
#' @inheritParams cv_render_section
#'
#' @return A character vector of Typst blocks, one element per group in `data`.
#'
#' @keywords internal
#' @noRd
.build_section_blocks <- function(data,
                                  title_col,
                                  org_col    = NULL,
                                  detail_col = NULL,
                                  date_fun   = .cv_date_range,
                                  where_col  = "where") {

    # -- 1. Build the composite grouping key ------------------------------------
    # The key uniquely identifies one entry header. Rows sharing the same key
    # are responsibilities under one position; they render as bullets rather
    # than repeated headers. NA values in any key column are coerced to ""
    # before pasting so they form a stable, consistent key.
    key_cols <- c(title_col, org_col, where_col,
                  "startMonth", "startYear", "endMonth", "endYear")
    key_cols <- intersect(key_cols, names(data))

    key_values <- lapply(key_cols, function(col) {
        x <- data[[col]]
        ifelse(is.na(x), "", x)
    })
    group_key <- do.call(paste, c(key_values, sep = "\u001f"))

    # -- 2. Preserve original row order for group appearance --------------------
    # factor() with levels set to first-occurrence order means groups render
    # in the order they appear in the data, not alphabetically.
    group_factor  <- factor(group_key, levels = unique(group_key))
    group_indices <- split(seq_len(nrow(data)), group_factor)

    # -- 3. Build one block per group ------------------------------------------
    blocks <- vector("character", length(group_indices))

    for (g in seq_along(group_indices)) {
        idx  <- group_indices[[g]]
        rows <- data[idx, , drop = FALSE]

        # Use the first row for all header fields -- title, org, date, location
        # are identical across all rows in a group by definition.
        first_row <- rows[1L, , drop = FALSE]

        title <- .cv_value(first_row, title_col)
        org   <- if (!is.null(org_col))   .cv_value(first_row, org_col)   else ""
        when  <- if (!is.null(date_fun))  date_fun(first_row)             else ""
        where <- if (!is.null(where_col)) .cv_value(first_row, where_col) else ""

        # Collect detail values across all rows in the group
        details <- if (!is.null(detail_col)) {
            vals <- vapply(seq_len(nrow(rows)), function(i) {
                v <- .cv_value(rows[i, , drop = FALSE], detail_col)
                if (is.na(v) || !nzchar(trimws(v))) NA_character_ else v
            }, character(1L))
            vals[!is.na(vals)]
        } else {
            character(0)
        }

        blocks[[g]] <- if (length(details) > 1L) {
            .cv_entry_bulleted(
                title        = title,
                organization = org,
                details      = details,
                when         = when,
                where        = where
            )
        } else {
            .cv_entry(
                title        = title,
                organization = org,
                detail       = if (length(details) == 1L) details[[1L]] else "",
                when         = when,
                where        = where
            )
        }
    }

    blocks
}
