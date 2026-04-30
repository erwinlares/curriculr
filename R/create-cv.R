# R/create-cv.R


# create_cv() -----------------------------------------------------------

#' Generate a CV document from a curriculr workbook
#'
#' Called with no arguments, `create_cv()` runs in **scaffold mode**: it
#' copies the template Excel workbook and placeholder profile image to the
#' current working directory and prints instructions for the next step. No
#' rendering takes place.
#'
#' Called with `data` and `photo` arguments, `create_cv()` runs in **render
#' mode**: it reads the workbook, generates `CV.qmd`, and renders it to PDF
#' using Quarto's Typst engine. Both `CV.qmd` and `CV.pdf` are written to
#' the same directory as the workbook.
#'
#' @param data A character string or `NULL`. Path to the Excel workbook.
#'   Defaults to `NULL`, which triggers scaffold mode.
#' @param photo A character string or `NULL`. Path to the profile image.
#'   Defaults to `NULL`. In render mode, if `photo` is `NULL` the bundled
#'   placeholder image is used.
#' @param output_file A character string. Name of the output PDF file.
#'   Defaults to `"CV.pdf"`. Ignored in scaffold mode.
#' @param overwrite A logical. Whether to overwrite existing files. Defaults
#'   to `FALSE`.
#'
#' @return In scaffold mode, invisibly returns the path to the directory
#'   where files were copied. In render mode, invisibly returns the path to
#'   the rendered PDF.
#'
#' @details
#' **Scaffold mode** (no arguments):
#'
#' 1. Copies `cv-data-template.xlsx` to `getwd()`.
#' 2. Copies `placeholder.png` to `getwd()`.
#' 3. Prints instructions for editing the workbook and rendering the CV.
#'
#' **Render mode** (`data` supplied):
#'
#' 1. Resolves the workbook and photo paths.
#' 2. Reads the workbook with [read_cv_data()].
#' 3. Validates that a `sections` sheet is present.
#' 4. Computes the photo path relative to the output directory.
#' 5. Writes `CV.qmd` by injecting resolved paths into the package template.
#' 6. Calls `quarto::quarto_render()` to produce the PDF.
#'
#' The `sections` sheet in the workbook controls which CV sections are
#' rendered and in what order. Each row corresponds to one section. To
#' exclude a section, delete its row. To reorder sections, reorder the rows.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Scaffold mode — copy template files to current directory
#' create_cv()
#'
#' # Render mode — use your own workbook and photo
#' create_cv(
#'   data  = "~/my_cv/cv-data.xlsx",
#'   photo = "~/my_cv/me.jpeg"
#' )
#'
#' # Render mode — custom output filename
#' create_cv(
#'   data        = "~/my_cv/cv-data.xlsx",
#'   photo       = "~/my_cv/me.jpeg",
#'   output_file = "erwin-lares-cv.pdf"
#' )
#' }
create_cv <- function(data        = NULL,
                      photo       = NULL,
                      output_file = "CV.pdf",
                      overwrite   = FALSE) {

    # ── SCAFFOLD MODE ──────────────────────────────────────────────────────────
    # Triggered when data is NULL. Copies template files to getwd() and
    # prints instructions. Does not render.

    if (is.null(data)) {

        dest_dir <- fs::path_abs(getwd())

        # Copy template workbook
        workbook_src <- system.file(
            "extdata", "cv-data-template.xlsx",
            package  = "curriculr",
            mustWork = TRUE
        )
        workbook_dst <- fs::path(dest_dir, "cv-data-template.xlsx")

        if (!fs::file_exists(workbook_dst) || overwrite) {
            fs::file_copy(workbook_src, workbook_dst, overwrite = overwrite)
            cli::cli_alert_success("Created {.path {workbook_dst}}")
        } else {
            cli::cli_alert_info(
                "Skipping {.path {workbook_dst}} \u2014 already exists.
         Use {.code overwrite = TRUE} to replace it."
            )
        }

        # Copy placeholder image
        photo_src <- system.file(
            "extdata", "img", "placeholder.png",
            package  = "curriculr",
            mustWork = TRUE
        )
        photo_dst <- fs::path(dest_dir, "placeholder.png")

        if (!fs::file_exists(photo_dst) || overwrite) {
            fs::file_copy(photo_src, photo_dst, overwrite = overwrite)
            cli::cli_alert_success("Created {.path {photo_dst}}")
        } else {
            cli::cli_alert_info(
                "Skipping {.path {photo_dst}} \u2014 already exists.
         Use {.code overwrite = TRUE} to replace it."
            )
        }

        # Instructions
        cli::cli_alert_info(
            "Next steps:"
        )
        cli::cli_bullets(c(
            "1" = "Open {.path {workbook_dst}} and fill in the {.val profile} sheet with your information.",
            "2" = "Replace {.path {photo_dst}} with your own profile photo.",
            "3" = "Call {.code create_cv(data = 'cv-data-template.xlsx', photo = 'your-photo.png')} to render your CV."
        ))

        return(invisible(dest_dir))
    }

    # ── RENDER MODE ────────────────────────────────────────────────────────────
    # Triggered when data is supplied. Reads the workbook, writes CV.qmd,
    # and renders to PDF.

    # -- 1. Resolve paths -------------------------------------------------------
    data  <- fs::path_abs(data)
    photo <- if (!is.null(photo)) fs::path_abs(photo)

    if (!fs::file_exists(data)) {
        cli::cli_abort("Cannot find workbook at {.path {data}}.")
    }

    if (!is.null(photo) && !fs::file_exists(photo)) {
        cli::cli_abort("Cannot find profile image at {.path {photo}}.")
    }

    # Fall back to placeholder if photo not supplied in render mode
    if (is.null(photo)) {
        photo <- fs::path_abs(system.file(
            "extdata", "img", "placeholder.png",
            package  = "curriculr",
            mustWork = TRUE
        ))
        cli::cli_alert_info(
            "No photo supplied. Using bundled placeholder image."
        )
    }

    # -- 2. Determine output directory ------------------------------------------
    output_dir <- fs::path_dir(data)

    # -- 3. Read the workbook ---------------------------------------------------
    cli::cli_alert_info("Reading workbook {.path {data}}")
    cv <- read_cv_data(data)

    if (is.null(cv$sections)) {
        cli::cli_abort(
            "The workbook does not contain a {.val sections} sheet.
       Add a {.val sections} sheet to control which sections are rendered."
        )
    }

    # -- 4. Compute photo path relative to output directory --------------------
    photo_rel <- fs::path_rel(photo, output_dir)

    # -- 5. Write CV.qmd -------------------------------------------------------
    qmd_dst <- fs::path(output_dir, "CV.qmd")

    if (fs::file_exists(qmd_dst) && !overwrite) {
        cli::cli_abort(
            "{.path {qmd_dst}} already exists.
       Use {.code overwrite = TRUE} to replace it."
        )
    }

    qmd_src <- system.file(
        "templates", "CV.qmd",
        package  = "curriculr",
        mustWork = TRUE
    )

    qmd_content <- readr::read_file(qmd_src)

    qmd_content <- gsub("__CURRICULR_DATA_PATH__",
                        as.character(data),
                        qmd_content, fixed = TRUE)

    qmd_content <- gsub("__CURRICULR_PHOTO_PATH__",
                        as.character(photo_rel),
                        qmd_content, fixed = TRUE)

    readr::write_file(qmd_content, qmd_dst)
    cli::cli_alert_success("Written {.path {qmd_dst}}")

    # -- 6. Render to PDF -------------------------------------------------------
    cli::cli_alert_info("Rendering CV with Quarto ...")

    quarto::quarto_render(
        input         = as.character(qmd_dst),
        output_format = "typst",
        output_file   = output_file,
        quiet         = FALSE
    )

    pdf_path <- fs::path(output_dir, output_file)
    cli::cli_alert_success("CV rendered to {.path {pdf_path}}")

    invisible(pdf_path)
}
