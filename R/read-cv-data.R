# R/read-cv-data.R


# read_cv_data() --------------------------------------------------------

#' Read CV data from an Excel workbook
#'
#' Reads all sheets from a curriculr-formatted Excel workbook and returns them
#' as a named list of data frames. Each sheet becomes one list element, named
#' after the sheet. The `profile` sheet is returned as a named character vector
#' for convenient scalar access. The `theme` sheet is returned as a named
#' character vector keyed by the `key` column. The `sections` sheet is returned
#' as a data frame in the order the rows appear in the workbook — row order
#' controls section render order and must not be sorted.
#'
#' Sheets containing a `startYear` column are sorted in descending order by
#' `startYear` so that the most recent entries appear first. The `profile`,
#' `theme`, and `sections` sheets are exempt from sorting.
#'
#' @param path A character string. Path to the Excel workbook. Defaults to
#'   `"data/cv-data.xlsx"`.
#' @param variant A character string. Controls which rows are included from
#'   each section sheet. `"cv"` (the default) returns all rows. `"resume"`
#'   returns only rows where `include_in_resume` is `TRUE`. Sections that
#'   lack an `include_in_resume` column are included in full regardless of
#'   `variant`.
#'
#' @return A named list with one element per sheet in the workbook. The
#'   `profile` element is a named character vector; the `theme` element is a
#'   named character vector (or `NULL` if the `theme` sheet is absent); all
#'   other elements are data frames. The `include_in_resume` column is dropped
#'   from returned data frames — it is used for filtering only and is not
#'   passed to the rendering pipeline. Access sections as `cv$education`,
#'   `cv$experience`, etc. Access profile fields as
#'   `cv$profile[["first_name"]]`. Access theme values as
#'   `cv$theme[["accent_color"]]`. Access the sections control sheet as
#'   `cv$sections`.
#'
#' @details
#' The workbook must follow the curriculr schema. Every section sheet should
#' contain a `title` column as the primary entry label. The `profile` sheet
#' must contain `field` and `value` columns. The `sections` sheet must contain
#' at minimum `section` and `label` columns. The `theme` sheet, if present,
#' must contain `key` and `value` columns.
#'
#' All cell values are read as character strings after import. Numeric columns
#' such as `startYear` and `endYear` are coerced to character so that
#' downstream rendering treats them uniformly. The `include_in_resume` column
#' is read as a logical before coercion and used for row filtering when
#' `variant = "resume"`.
#'
#' Empty cells and cells containing the literal string `"NA"` are both
#' converted to `NA`.
#'
#' If the `theme` sheet is absent, `cv$theme` is `NULL` and `create_cv()`
#' will fall back to built-in defaults.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Full CV — all rows from every section
#' cv <- read_cv_data("data/cv-data.xlsx")
#'
#' # Resume variant — only rows marked include_in_resume
#' cv <- read_cv_data("data/cv-data.xlsx", variant = "resume")
#'
#' # Access a section
#' cv$education
#' cv$experience
#'
#' # Access the sections control sheet
#' cv$sections
#'
#' # Access profile fields
#' cv$profile[["first_name"]]
#' cv$profile[["email"]]
#'
#' # Access theme values
#' cv$theme[["accent_color"]]
#' cv$theme[["papersize"]]
#' }
read_cv_data <- function(path = "data/cv-data.xlsx", variant = "cv") {

    # -- 0. Validate arguments --------------------------------------------------
    if (!fs::file_exists(path)) {
        cli::cli_abort(
            "Cannot find CV workbook at {.path {path}}.
       Check the path or run {.fn create_cv} to scaffold a new project."
        )
    }

    variant <- match.arg(variant, choices = c("cv", "resume"))

    # -- 1. Read sheet names ----------------------------------------------------
    # wb_get_sheet_names() requires a wbWorkbook object in openxlsx2 >= 1.0.
    # We load the workbook once here for sheet discovery; individual sheets
    # are then read via read_xlsx() which accepts a path string directly.
    wb     <- openxlsx2::wb_load(path)
    sheets <- openxlsx2::wb_get_sheet_names(wb)

    # -- 2. Read each sheet into a data frame -----------------------------------
    out <- vector("list", length(sheets))
    names(out) <- sheets

    # Sheets exempt from date sorting and include_in_resume filtering
    no_sort <- c("profile", "theme", "sections", "readme")

    for (sheet in sheets) {

        # Skip the readme sheet entirely — it is documentation, not data
        if (sheet == "readme") next

        dat <- openxlsx2::read_xlsx(
            path,
            sheet      = sheet,
            na.strings = c("", "NA"),
            col_names  = TRUE
        )
        dat <- as.data.frame(dat, stringsAsFactors = FALSE)

        # -- 3. Handle the profile sheet ----------------------------------------
        if (sheet == "profile") {
            if (!all(c("field", "value") %in% names(dat))) {
                cli::cli_abort(
                    "The {.val profile} sheet must contain {.val field} and
           {.val value} columns."
                )
            }
            dat[] <- lapply(dat, .coerce_col)
            profile_vec <- dat[["value"]]
            names(profile_vec) <- dat[["field"]]
            out[["profile"]] <- profile_vec
            next
        }

        # -- 4. Handle the theme sheet ------------------------------------------
        if (sheet == "theme") {
            if (!all(c("key", "value") %in% names(dat))) {
                cli::cli_abort(
                    "The {.val theme} sheet must contain {.val key} and
           {.val value} columns."
                )
            }
            dat[] <- lapply(dat, .coerce_col)
            theme_vec <- dat[["value"]]
            names(theme_vec) <- dat[["key"]]
            out[["theme"]] <- theme_vec
            next
        }

        # -- 5. Validate the sections sheet -------------------------------------
        if (sheet == "sections") {
            if (!"section" %in% names(dat)) {
                cli::cli_abort(
                    "The {.val sections} sheet must contain a {.val section} column."
                )
            }
            dat[] <- lapply(dat, .coerce_col)
            out[["sections"]] <- dat
            next
        }

        # -- 6. Apply resume filtering before coercion --------------------------
        # include_in_resume is stored as an Excel boolean (TRUE/FALSE). We
        # filter on it here, before the character coercion below collapses the
        # type, then drop the column so it never reaches the render pipeline.
        if ("include_in_resume" %in% names(dat)) {
            if (variant == "resume") {
                keep <- dat[["include_in_resume"]] %in% c(TRUE, "TRUE", "true", "1")
                dat  <- dat[keep, , drop = FALSE]
                rownames(dat) <- NULL
            }
            dat[["include_in_resume"]] <- NULL
        }

        # -- 7. Coerce all remaining columns to character -----------------------
        dat[] <- lapply(dat, .coerce_col)

        # -- 8. Sort dated sheets in reverse chronological order ----------------
        if ("startYear" %in% names(dat) && !sheet %in% no_sort) {
            ord <- order(
                suppressWarnings(as.numeric(dat$startYear)),
                decreasing = TRUE,
                na.last    = TRUE
            )
            dat <- dat[ord, , drop = FALSE]
            rownames(dat) <- NULL
        }

        out[[sheet]] <- dat
    }

    # Remove the readme slot — it was skipped but still allocated
    out[["readme"]] <- NULL

    # Emit an informational note if theme sheet is absent so create_cv()
    # can rely on cv$theme being NULL as the fallback signal
    if (is.null(out[["theme"]])) {
        cli::cli_alert_info(
            "No {.val theme} sheet found in workbook. Built-in style defaults will be used."
        )
    }

    out
}


# .coerce_col() ---------------------------------------------------------
# Internal helper. Coerces a column to character and normalises the
# string "NA" (produced by as.character(NA)) back to NA_character_.

.coerce_col <- function(col) {
    x <- as.character(col)
    x[x == "NA"] <- NA_character_
    x
}
