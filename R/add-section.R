# R/add-section.R


# add_section() ---------------------------------------------------------

#' Add a new section to a curriculr workbook
#'
#' Adds a new sheet to an existing curriculr-formatted Excel workbook and
#' registers it in the `sections` control sheet. The new sheet is pre-populated
#' with the standard column spine so the user can start entering data
#' immediately without worrying about column names.
#'
#' @param workbook A character string. Path to an existing curriculr Excel
#'   workbook.
#' @param section A character string. Internal name of the new section. Must
#'   be a valid Excel sheet name (no more than 31 characters, no special
#'   characters). This name must match the sheet name exactly when referenced
#'   elsewhere in the workbook or in `cap` arguments to [create_cv()].
#' @param label A character string. Display label shown as the section heading
#'   in the rendered CV. Defaults to `section`, which works when the section
#'   name is already human-readable. Supply a different value when the internal
#'   name and the display label differ, e.g. `section = "invited_talks"`,
#'   `label = "Invited Talks"`.
#' @param date_fun A character string. Token controlling date formatting for
#'   this section. One of `"date"`, `"year"`, `"month_year"`, `"year_only"`,
#'   or `"none"`. Defaults to `"year_only"`. See [resolve_date_fun()] for
#'   token definitions.
#' @param title_col A character string. Name of the column used as the primary
#'   entry label in the rendered CV. Defaults to `"title"`.
#' @param org_col A character string or `NA`. Name of the column used as the
#'   secondary organization or venue line. Defaults to `"unit"`. Pass `NA` to
#'   omit the organization line for this section.
#' @param detail_col A character string or `NA`. Name of the column used as
#'   the detail line. Defaults to `NA` (omitted). Pass a column name to
#'   include a detail line.
#' @param where_col A character string or `NA`. Name of the column used as the
#'   location. Defaults to `"where"`. Pass `NA` to omit location for this
#'   section.
#' @param overwrite A logical. Whether to overwrite an existing sheet of the
#'   same name. Defaults to `FALSE`. When `FALSE`, an existing sheet causes
#'   an informative error. This is a destructive operation — use with care.
#'
#' @return Invisibly returns `workbook`. Called primarily for its side effect
#'   of modifying the workbook on disk.
#'
#' @details
#' `add_section()` performs the following steps:
#'
#' 1. Validates that `workbook` exists and that `section` is not already
#'    present (unless `overwrite = TRUE`).
#' 2. Appends a new sheet named `section` with the standard column spine:
#'    `title | unit | startMonth | startYear | endMonth | endYear | where |
#'    detail | include_in_resume`.
#' 3. Appends a new row to the `sections` sheet registering the new section
#'    with the supplied metadata. When `overwrite = TRUE`, any existing row
#'    for this section is replaced.
#' 4. Writes the modified workbook back to `workbook` in place.
#'
#' The workbook is modified in place. There is no undo. Consider keeping a
#' backup copy before calling `add_section()` if the workbook contains data
#' you cannot reconstruct.
#'
#' Control sheets (`profile`, `sections`, `theme`, `readme`) cannot be used
#' as section names.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Add a section with defaults
#' add_section("cv-data.xlsx", section = "patents")
#'
#' # Add a section with a display label that differs from the sheet name
#' add_section("cv-data.xlsx",
#'             section  = "invited_talks",
#'             label    = "Invited Talks",
#'             date_fun = "month_year")
#'
#' # Add a section without an organization or location line
#' add_section("cv-data.xlsx",
#'             section   = "languages",
#'             label     = "Languages",
#'             date_fun  = "none",
#'             org_col   = NA,
#'             where_col = NA)
#' }
add_section <- function(workbook,
                        section,
                        label      = section,
                        date_fun   = "year_only",
                        title_col  = "title",
                        org_col    = "unit",
                        detail_col = NA,
                        where_col  = "where",
                        overwrite  = FALSE) {

    # -- 0. Validate workbook path ----------------------------------------------
    if (!fs::file_exists(workbook)) {
        cli::cli_abort(
            "Cannot find workbook at {.path {workbook}}."
        )
    }

    workbook <- fs::path_abs(workbook)

    # -- 1. Validate section name -----------------------------------------------
    reserved <- c("profile", "sections", "theme", "readme")

    if (section %in% reserved) {
        cli::cli_abort(
            "{.val {section}} is a reserved sheet name and cannot be used as a
       section. Reserved names: {.val {reserved}}."
        )
    }

    if (nchar(section) > 31) {
        cli::cli_abort(
            "Section name {.val {section}} is too long. Excel sheet names must
       be 31 characters or fewer ({nchar(section)} supplied)."
        )
    }

    # -- 2. Validate date_fun token ---------------------------------------------
    valid_tokens <- c("date", "year", "month_year", "year_only", "none")
    if (!date_fun %in% valid_tokens) {
        cli::cli_abort(
            "{.arg date_fun} must be one of {.val {valid_tokens}}.
       Got {.val {date_fun}}."
        )
    }

    # -- 3. Load workbook and check for existing sheet -------------------------
    wb     <- openxlsx2::wb_load(workbook)
    sheets <- openxlsx2::wb_get_sheet_names(wb)

    if (section %in% sheets) {
        if (!overwrite) {
            cli::cli_abort(
                "A sheet named {.val {section}} already exists in
           {.path {workbook}}.
           Use {.code overwrite = TRUE} to replace it."
            )
        }
        wb <- openxlsx2::wb_remove_worksheet(wb, sheet = section)
        cli::cli_alert_info(
            "Replacing existing sheet {.val {section}}."
        )
        sheets <- openxlsx2::wb_get_sheet_names(wb)
    }

    # -- 4. Add the new section sheet with standard column spine ---------------
    spine_cols <- c(
        "title", "unit", "startMonth", "startYear",
        "endMonth", "endYear", "where", "detail", "include_in_resume"
    )

    # A zero-row data frame writes column names horizontally across row 1.
    spine_df <- as.data.frame(
        matrix(nrow = 0, ncol = length(spine_cols),
               dimnames = list(NULL, spine_cols))
    )

    wb <- openxlsx2::wb_add_worksheet(wb, sheet = section)
    wb <- openxlsx2::wb_add_data(
        wb,
        sheet     = section,
        x         = spine_df,
        col_names = TRUE,
        start_row = 1
    )

    # Add TRUE/FALSE dropdown validation on include_in_resume (col I)
    wb <- openxlsx2::wb_add_data_validation(
        wb,
        sheet = section,
        dims  = "I2:I10000",
        type  = "list",
        value = '"TRUE,FALSE"'
    )

    cli::cli_alert_success(
        "Added sheet {.val {section}} to {.path {workbook}}."
    )

    # -- 5. Update the sections control sheet ----------------------------------
    # Build the new row — use empty string for omitted optional columns so
    # they write as blank cells rather than the literal string "NA".
    sections_row <- data.frame(
        section    = section,
        label      = label,
        title_col  = title_col,
        org_col    = if (is.na(org_col))    "" else org_col,
        detail_col = if (is.na(detail_col)) "" else detail_col,
        date_fun   = date_fun,
        where_col  = if (is.na(where_col))  "" else where_col,
        stringsAsFactors = FALSE
    )

    # Read current sections to find the target row. We never remove or
    # re-add the sections sheet — that risks losing its formatting.
    current_sections <- openxlsx2::wb_to_df(
        wb,
        sheet     = "sections",
        col_names = TRUE
    )

    existing_row <- which(current_sections[["section"]] == section)

    if (length(existing_row) > 0) {
        # Overwrite the existing row in place. Row index in the sheet is
        # existing_row + 1 to account for the header row.
        target_row <- existing_row[[1]] + 1L
    } else {
        # Append after the last data row. +1 for header, +1 for next row.
        target_row <- nrow(current_sections) + 2L
    }

    wb <- openxlsx2::wb_add_data(
        wb,
        sheet     = "sections",
        x         = sections_row,
        start_row = target_row,
        col_names = FALSE
    )

    cli::cli_alert_success(
        "Registered {.val {section}} in the {.val sections} sheet."
    )

    # -- 6. Write workbook back to disk ----------------------------------------
    openxlsx2::wb_save(wb, file = workbook, overwrite = TRUE)

    cli::cli_alert_success(
        "Workbook saved to {.path {workbook}}."
    )

    invisible(as.character(workbook))
}
