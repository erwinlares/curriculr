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
#'   Defaults to `NULL`, which renders the CV without a profile photo using
#'   a single-column header layout. Supply a path to use a photo with the
#'   two-column header layout.
#' @param output_file A character string. Name of the output PDF file.
#'   Defaults to `"CV.pdf"`. Ignored in scaffold mode.
#' @param overwrite A logical. Whether to overwrite existing files. Defaults
#'   to `FALSE`.
#' @param variant A character string. Controls content scope. `"cv"` (the
#'   default) renders all rows from every section. `"resume"` renders only
#'   rows where `include_in_resume` is checked in the workbook.
#' @param use_icons A character string. `"fontawesome"` (the default) renders
#'   contact fields in the CV header with Font Awesome icons via the Typst
#'   `@preview/fontawesome` package. `"none"` renders plain text.
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
#' 1. Resolves and validates the workbook and photo paths.
#' 2. Reads the workbook with [read_cv_data()], applying `variant` filtering.
#' 3. Resolves theme values from the workbook or built-in defaults.
#' 4. Writes `CV.qmd` by injecting all resolved values into the package
#'    template via sentinel substitution.
#' 5. Calls `quarto::quarto_render()` to produce the PDF.
#'
#' When `photo = NULL`, the CV header renders as a single full-width column
#' containing the name, contact line, address, and profile statement. When
#' a photo path is supplied, the header uses a two-column layout with the
#' photo on the left.
#'
#' When `variant = "resume"`, row-level filtering is controlled entirely by
#' the `include_in_resume` column in each section sheet. Check the rows you
#' want included in the resume and leave the rest unchecked.
#'
#' Theme values (fonts, colors, page layout) are read from the `theme` sheet
#' in the workbook. If the `theme` sheet is absent, built-in defaults are
#' used. Individual keys missing from a partial `theme` sheet are filled from
#' defaults.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Scaffold mode — copy template files to current directory
#' create_cv()
#'
#' # Render mode — full CV with photo and Font Awesome icons
#' create_cv(
#'   data  = "~/my_cv/cv-data.xlsx",
#'   photo = "~/my_cv/me.jpeg"
#' )
#'
#' # Render mode — no photo, single-column header
#' create_cv(
#'   data = "~/my_cv/cv-data.xlsx"
#' )
#'
#' # Render mode — resume variant
#' create_cv(
#'   data        = "~/my_cv/cv-data.xlsx",
#'   photo       = "~/my_cv/me.jpeg",
#'   variant     = "resume",
#'   output_file = "resume.pdf"
#' )
#'
#' # Render mode — plain text contact line, custom output filename
#' create_cv(
#'   data        = "~/my_cv/cv-data.xlsx",
#'   photo       = "~/my_cv/me.jpeg",
#'   use_icons   = "none",
#'   output_file = "erwin-lares-cv.pdf"
#' )
#' }
create_cv <- function(data        = NULL,
                      photo       = NULL,
                      output_file = "CV.pdf",
                      overwrite   = FALSE,
                      variant     = "cv",
                      use_icons   = "fontawesome") {

    # ── SCAFFOLD MODE ──────────────────────────────────────────────────────────
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

        # Copy placeholder image — scaffold convenience only
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

        cli::cli_alert_info("Next steps:")
        cli::cli_bullets(c(
            "1" = "Open {.path {workbook_dst}} and fill in the {.val profile} sheet with your information.",
            "2" = "Replace {.path {photo_dst}} with your own profile photo.",
            "3" = "Call {.code create_cv(data = 'cv-data-template.xlsx', photo = 'your-photo.png')} to render your CV."
        ))

        return(invisible(dest_dir))
    }

    # ── RENDER MODE ────────────────────────────────────────────────────────────

    # -- 1. Validate scalar arguments -------------------------------------------
    variant   <- match.arg(variant,   choices = c("cv", "resume"))
    use_icons <- match.arg(use_icons, choices = c("fontawesome", "none"))

    # -- 2. Resolve and validate paths ------------------------------------------
    data  <- fs::path_abs(data)
    photo <- if (!is.null(photo)) fs::path_abs(photo)

    if (!fs::file_exists(data)) {
        cli::cli_abort("Cannot find workbook at {.path {data}}.")
    }

    if (!is.null(photo) && !fs::file_exists(photo)) {
        cli::cli_abort("Cannot find profile image at {.path {photo}}.")
    }

    # photo = NULL is valid — CV.qmd renders a single-column header when
    # photo_rel is an empty string. No fallback to placeholder in render mode.
    output_dir <- fs::path_dir(data)
    photo_rel  <- if (!is.null(photo)) {
        as.character(fs::path_rel(photo, output_dir))
    } else {
        ""
    }

    # -- 3. Read the workbook ---------------------------------------------------
    cli::cli_alert_info("Reading workbook {.path {data}}")
    cv <- read_cv_data(data, variant = variant)

    if (is.null(cv$sections)) {
        cli::cli_abort(
            "The workbook does not contain a {.val sections} sheet.
       Add a {.val sections} sheet to control which sections are rendered."
        )
    }

    # -- 4. Resolve theme -------------------------------------------------------
    theme <- .resolve_theme(cv$theme)

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

    # Path sentinels
    qmd_content <- gsub(
        "__CURRICULR_DATA_PATH__",
        as.character(data),
        qmd_content, fixed = TRUE
    )
    qmd_content <- gsub(
        "__CURRICULR_PHOTO_PATH__",
        photo_rel,
        qmd_content, fixed = TRUE
    )

    # Variant sentinel — passed to read_cv_data() inside CV.qmd so the
    # Quarto subprocess applies the same filtering as the R session did.
    qmd_content <- gsub(
        "__CURRICULR_VARIANT__",
        variant,
        qmd_content, fixed = TRUE
    )

    # Format YAML block sentinel
    qmd_content <- gsub(
        "%%CURRICULR_FORMAT%%",
        .build_format_block(theme),
        qmd_content, fixed = TRUE
    )

    # Typst style block sentinel
    qmd_content <- gsub(
        "%%CURRICULR_THEME%%",
        .build_typst_theme_block(theme, use_icons),
        qmd_content, fixed = TRUE
    )

    # use_icons sentinel — passed to cv_contact_line() inside CV.qmd
    qmd_content <- gsub(
        "__CURRICULR_USE_ICONS__",
        use_icons,
        qmd_content, fixed = TRUE
    )

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
