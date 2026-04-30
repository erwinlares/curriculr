# R/read-cv-data.R


# read_cv_data() --------------------------------------------------------

#' Read CV data from an Excel workbook
#'
#' Reads all sheets from a curriculr-formatted Excel workbook and returns them
#' as a named list of data frames. Each sheet becomes one list element, named
#' after the sheet. The `profile` sheet is returned as a named character vector
#' for convenient scalar access. The `sections` sheet is returned as a data
#' frame in the order the rows appear in the workbook — row order controls
#' section render order and must not be sorted.
#'
#' Sheets containing a `startYear` column are sorted in descending order by
#' `startYear` so that the most recent entries appear first. The `profile` and
#' `sections` sheets are exempt from sorting.
#'
#' @param path A character string. Path to the Excel workbook. Defaults to
#'   `"data/cv-data.xlsx"`.
#'
#' @return A named list with one element per sheet in the workbook. The
#'   `profile` element is a named character vector; all other elements are
#'   data frames. Access sections as `cv$education`, `cv$experience`, etc.
#'   Access profile fields as `cv$profile[["first_name"]]`. Access the
#'   sections control sheet as `cv$sections`.
#'
#' @details
#' The workbook must follow the curriculr schema. Every section sheet should
#' contain a `title` column as the primary entry label. The `profile` sheet
#' must contain `field` and `value` columns. The `sections` sheet must contain
#' at minimum `section` and `label` columns.
#'
#' This function requires the `readxl` package. It is listed as a dependency
#' of curriculr and will be installed automatically.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' cv <- read_cv_data("data/cv-data.xlsx")
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
#' }
read_cv_data <- function(path = "data/cv-data.xlsx") {

    # -- 0. Validate path -------------------------------------------------------
    if (!fs::file_exists(path)) {
        cli::cli_abort(
            "Cannot find CV workbook at {.path {path}}.
       Check the path or run {.fn create_cv} to scaffold a new project."
        )
    }

    # -- 1. Read sheet names ----------------------------------------------------
    sheets <- readxl::excel_sheets(path)

    # -- 2. Read each sheet into a data frame -----------------------------------
    out <- vector("list", length(sheets))
    names(out) <- sheets

    # Sheets exempt from date sorting
    no_sort <- c("profile", "sections", "readme")

    for (sheet in sheets) {

        # Skip the readme sheet entirely — it is documentation, not data
        if (sheet == "readme") next

        dat <- as.data.frame(
            readxl::read_excel(path, sheet = sheet, na = "NA"),
            stringsAsFactors = FALSE
        )

    # -- 3. Handle the profile sheet specially --------------------------------
    if (sheet == "profile") {
        if (!all(c("field", "value") %in% names(dat))) {
            cli::cli_abort(
                "The {.val profile} sheet must contain {.val field} and
       {.val value} columns."
            )
        }
        profile_vec <- as.character(dat[["value"]])
        names(profile_vec) <- as.character(dat[["field"]])
        out[["profile"]] <- profile_vec
        next
    }

    # -- 3b. Validate the sections sheet --------------------------------------
    if (sheet == "sections") {
        if (!"section" %in% names(dat)) {
            cli::cli_abort(
                "The {.val sections} sheet must contain a {.val section} column."
            )
        }
        out[["sections"]] <- dat
        next
    }

        # -- 4. Sort dated sheets in reverse chronological order ------------------
        # sections and readme are exempt — row order is meaningful for sections
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

    out
}
