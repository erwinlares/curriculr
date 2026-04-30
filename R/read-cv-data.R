# R/read-cv-data.R


# read_cv_data() --------------------------------------------------------

#' Read CV data from an Excel workbook
#'
#' Reads all sheets from a curriculr-formatted Excel workbook and returns them
#' as a named list of data frames. Each sheet becomes one list element, named
#' after the sheet. The `profile` sheet is returned as a named character vector
#' for convenient scalar access.
#'
#' Sheets containing a `startYear` column are sorted in descending order by
#' `startYear` so that the most recent entries appear first. Missing or
#' non-numeric values in `startYear` are placed last.
#'
#' @param path A character string. Path to the Excel workbook. Defaults to
#'   `"data/cv-data.xlsx"`.
#'
#' @return A named list with one element per sheet in the workbook. The
#'   `profile` element is a named character vector; all other elements are
#'   data frames. Access sections as `cv$education`, `cv$experience`, etc.
#'   Access profile fields as `cv$profile[["first_name"]]`.
#'
#' @details
#' The workbook must follow the curriculr schema. Every section sheet should
#' contain a `title` column as the primary entry label. The `profile` sheet
#' must contain `field` and `value` columns.
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

    for (sheet in sheets) {
        dat <- as.data.frame(
            readxl::read_excel(path, sheet = sheet, na = "NA"),
            stringsAsFactors = FALSE
        )

        # -- 3. Handle the profile sheet specially --------------------------------
        # The profile sheet has two columns: field and value.
        # Convert it to a named character vector for convenient scalar access:
        #   cv$profile[["first_name"]] rather than cv$profile[cv$profile$field == "first_name", "value"]
        if (sheet == "profile") {
            if (!all(c("field", "value") %in% names(dat))) {
                cli::cli_abort(
                    "The {.val profile} sheet must contain {.val field} and {.val value} columns."
                )
            }
            profile_vec <- as.character(dat[["value"]])
            names(profile_vec) <- as.character(dat[["field"]])
            out[["profile"]] <- profile_vec
            next
        }

        # -- 4. Sort dated sheets in reverse chronological order ------------------
        if ("startYear" %in% names(dat)) {
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

    out
}
