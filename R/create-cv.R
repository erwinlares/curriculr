# R/create-cv.R


# create_cv() -----------------------------------------------------------

#' Scaffold a new curriculr CV project
#'
#' Creates a new CV project at the given path with a standard folder
#' structure, a pre-populated Excel workbook, a placeholder profile image,
#' and a ready-to-render Quarto document.
#'
#' @param path A character string. Path to the directory where the CV project
#'   will be created. The directory must already exist. Use [base::tempdir()]
#'   for temporary output during testing or exploration.
#' @param filename A character string. Name of the generated `.qmd` file.
#'   Defaults to `"CV.qmd"`.
#' @param overwrite A logical. Whether to overwrite existing files. Defaults
#'   to `FALSE`.
#'
#' @return Invisibly returns `path`. Called primarily for its side effects.
#'
#' @details
#' `create_cv()` performs the following steps:
#'
#' 1. Validates that `path` exists.
#' 2. Creates a `data/` folder and copies the template Excel workbook
#'    (`cv-data-template.xlsx`) there.
#' 3. Creates an `img/` folder and copies the placeholder profile image
#'    (`placeholder.png`) there.
#' 4. Copies the CV Quarto template into `path/filename`.
#'
#' After scaffolding, open the Excel workbook and fill in the `profile` sheet
#' with your personal information. Then render the CV with:
#'
#' ```bash
#' quarto render CV.qmd
#' ```
#'
#' @export
#'
#' @examples
#' \donttest{
#' # Scaffold a CV project in a temp directory
#' create_cv(path = tempdir())
#'
#' # Use a custom filename
#' create_cv(path = tempdir(), filename = "my-cv.qmd", overwrite = TRUE)
#' }
create_cv <- function(path,
                      filename  = "CV.qmd",
                      overwrite = FALSE) {

    # -- 0. Validate path -------------------------------------------------------
    if (!fs::dir_exists(path)) {
        cli::cli_abort(
            "Directory {.path {path}} does not exist.
       Create it first or choose an existing path."
        )
    }

    # -- 1. Create data/ and copy template workbook -----------------------------
    data_dir <- fs::path(path, "data")
    fs::dir_create(data_dir)

    workbook_src <- system.file(
        "extdata", "cv-data-template.xlsx",
        package  = "curriculr",
        mustWork = TRUE
    )
    workbook_dst <- fs::path(data_dir, "cv-data-template.xlsx")

    if (!fs::file_exists(workbook_dst) || overwrite) {
        fs::file_copy(workbook_src, workbook_dst, overwrite = overwrite)
        cli::cli_alert_success("Created {.path {workbook_dst}}")
    } else {
        cli::cli_alert_info(
            "Skipping {.path {workbook_dst}} - already exists."
        )
    }

    # -- 2. Create img/ and copy placeholder profile image ----------------------
    img_dir <- fs::path(path, "img")
    fs::dir_create(img_dir)

    img_src <- system.file(
        "extdata", "img", "placeholder.png",
        package  = "curriculr",
        mustWork = TRUE
    )
    img_dst <- fs::path(img_dir, "placeholder.png")

    if (!fs::file_exists(img_dst) || overwrite) {
        fs::file_copy(img_src, img_dst, overwrite = overwrite)
        cli::cli_alert_success("Created {.path {img_dst}}")
    } else {
        cli::cli_alert_info(
            "Skipping {.path {img_dst}} - already exists."
        )
    }

    # -- 3. Copy CV Quarto template ---------------------------------------------
    qmd_src <- system.file(
        "templates", "CV.qmd",
        package  = "curriculr",
        mustWork = TRUE
    )
    qmd_dst <- fs::path(path, filename)

    if (fs::file_exists(qmd_dst) && !overwrite) {
        cli::cli_abort(
            "{.path {qmd_dst}} already exists.
       Use {.code overwrite = TRUE} to replace it."
        )
    }

    fs::file_copy(qmd_src, qmd_dst, overwrite = overwrite)
    cli::cli_alert_success("Created {.path {qmd_dst}}")

    # -- 4. Summary messages ----------------------------------------------------
    cli::cli_alert_success(
        "CV project scaffolded at {.path {path}}"
    )
    cli::cli_alert_info(
        "Next step: open {.path {workbook_dst}} and fill in the {.val profile} sheet."
    )

    invisible(path)
}
