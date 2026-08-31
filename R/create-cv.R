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
#' mode**: it reads the workbook, generates an intermediate `CV.qmd` in a
#' temporary directory, renders it to PDF there using Quarto's Typst engine,
#' and copies only the finished PDF back beside the workbook. Nothing else is
#' written to the workbook folder.
#'
#' @param data A character string or `NULL`. Path to the Excel workbook.
#'   Defaults to `NULL`, which triggers scaffold mode.
#' @param photo A character string or `NULL`. Path to the profile image.
#'   Defaults to `NULL`, which renders the CV without a profile photo using
#'   a single-column header layout. Supply a path to use a photo with the
#'   two-column header layout.
#' @param output_file A character string. Name of the output PDF file, without
#'   a directory component -- the PDF is always written beside the workbook.
#'   Defaults to `"CV.pdf"`. Ignored in scaffold mode.
#' @param overwrite A logical. Whether to overwrite existing files. Defaults
#'   to `FALSE`. In scaffold mode, controls whether the template workbook and
#'   placeholder image are replaced if they already exist in the destination
#'   directory. Has no effect in render mode -- the intermediate `CV.qmd` is
#'   written to a temporary directory and never touches the workbook folder.
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
#' 4. Writes an intermediate `CV.qmd` to a temporary directory by injecting
#'    all resolved values into the package template via sentinel substitution.
#' 5. Renders that file to PDF **inside the temporary directory**, then copies
#'    the finished PDF beside the workbook. The temporary directory and
#'    everything in it are removed when the call returns.
#'
#' Rendering in a temporary directory rather than in the workbook folder is a
#' deliberate reproducibility choice. Quarto stages Typst packages into a
#' `.quarto/` cache in whichever directory it renders, and it walks up the
#' directory tree looking for a `_quarto.yml` to decide whether it is inside a
#' project. Rendering in the workbook folder therefore made the output depend
#' on where the workbook happened to live: a folder carrying a stale package
#' cache, or sitting beneath someone's unrelated Quarto project, could render
#' the same workbook differently. A fresh temporary directory has neither, so
#' every render starts from the same conditions. It also means curriculr never
#' creates or deletes files in a directory it does not own.
#'
#' Because the workbook and photo paths are injected into the template as
#' absolute paths, they resolve correctly from the temporary directory.
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
#' \donttest{
#' # Scaffold mode — copy template files to a temp directory
#' withr::with_dir(tempdir(), create_cv())
#' }
#'
#' \dontrun{
#' # Render mode — requires cv-data.xlsx, Quarto, and Typst
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

    # photo = NULL is valid — CV.qmd renders a single-column header when the
    # photo sentinel resolves to an empty string. No fallback to placeholder
    # in render mode.
    output_dir <- fs::path_dir(data)

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

    # -- 5. Write CV.qmd to a temp directory ------------------------------------
    # The intermediate .qmd is implementation detail, not a user deliverable.
    # The temp directory is also where the render happens (step 6), which keeps
    # the render conditions identical from one call to the next.
    tmp_dir <- tempfile(pattern = "curriculr-")
    dir.create(tmp_dir)
    on.exit(fs::dir_delete(tmp_dir), add = TRUE)

    qmd_dst <- fs::path(tmp_dir, "CV.qmd")

    qmd_src <- system.file(
        "templates", "CV.qmd",
        package  = "curriculr",
        mustWork = TRUE
    )

    qmd_content <- readr::read_file(qmd_src)

    # Path sentinels -- both use absolute paths so they resolve correctly
    # from the temp directory rather than relative to the workbook location.
    qmd_content <- gsub(
        "__CURRICULR_DATA_PATH__",
        as.character(data),
        qmd_content, fixed = TRUE
    )
    qmd_content <- gsub(
        "__CURRICULR_PHOTO_PATH__",
        if (!is.null(photo)) as.character(photo) else "",
        qmd_content, fixed = TRUE
    )

    # Variant sentinel
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

    # use_icons sentinel
    qmd_content <- gsub(
        "__CURRICULR_USE_ICONS__",
        use_icons,
        qmd_content, fixed = TRUE
    )

    readr::write_file(qmd_content, qmd_dst)

    # -- 6. Render to PDF -------------------------------------------------------
    # Quarto's output-file accepts a filename, not a path, and writes the PDF
    # next to the input .qmd. Since the .qmd lives in the temp directory, the
    # PDF lands there too and is copied out afterwards.
    #
    # An earlier version copied the .qmd into the workbook folder and rendered
    # it there. That worked, but it made the render environment a property of
    # the user's filesystem: Quarto stages a .quarto/ Typst package cache into
    # the render directory and looks upward for a _quarto.yml, so the same
    # workbook could render differently depending on where it was stored.
    # Rendering in a fresh temp directory removes both dependencies, and has
    # the side benefit that curriculr no longer writes to -- or deletes from --
    # a directory belonging to the user.
    cli::cli_alert_info("Rendering CV with Quarto ...")

    quarto::quarto_render(
        input         = as.character(qmd_dst),
        output_format = "typst",
        output_file   = output_file,
        quiet         = FALSE
    )

    rendered_pdf <- fs::path(tmp_dir, output_file)

    if (!fs::file_exists(rendered_pdf)) {
        cli::cli_abort(
            "Quarto did not produce {.file {output_file}}.
       The render may have failed -- check the Quarto output above."
        )
    }

    # Copy rather than move: the temp directory may sit on a different
    # filesystem than the workbook, which would make a rename fail.
    pdf_path <- fs::path(output_dir, output_file)
    fs::file_copy(rendered_pdf, pdf_path, overwrite = TRUE)

    cli::cli_alert_success("CV rendered to {.path {pdf_path}}")

    invisible(pdf_path)
}
