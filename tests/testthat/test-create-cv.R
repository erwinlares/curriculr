# tests/testthat/test-create-cv.R

# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------

palmer_copy <- function(env = parent.frame()) {
    src <- system.file(
        "extdata", "cv-data-template.xlsx",
        package  = "curriculr",
        mustWork = FALSE
    )
    skip_if_not(file.exists(src), "template workbook not found")
    dir <- withr::local_tempdir(.local_envir = env)
    dst <- file.path(dir, "cv-data-template.xlsx")
    file.copy(src, dst)
    dst
}

# Reads back CV.qmd written by create_cv() as a character vector of lines.
qmd_lines <- function(workbook_path) {
    readLines(file.path(dirname(workbook_path), "CV.qmd"))
}

# ---------------------------------------------------------------------------
# Scaffold mode
# ---------------------------------------------------------------------------

test_that("create_cv() scaffold mode copies template workbook", {
    withr::with_tempdir({
        create_cv()
        expect_true(file.exists("cv-data-template.xlsx"))
    })
})

test_that("create_cv() scaffold mode copies placeholder image", {
    withr::with_tempdir({
        create_cv()
        expect_true(file.exists("placeholder.png"))
    })
})

test_that("create_cv() scaffold mode returns invisibly the dest directory", {
    withr::with_tempdir({
        result <- create_cv()
        expect_type(result, "character")
        expect_true(dir.exists(result))
    })
})

test_that("create_cv() scaffold mode does not overwrite existing files by default", {
    withr::with_tempdir({
        create_cv()
        mtime1 <- file.info("cv-data-template.xlsx")$mtime
        Sys.sleep(0.05)
        create_cv()
        mtime2 <- file.info("cv-data-template.xlsx")$mtime
        expect_equal(mtime1, mtime2)
    })
})

test_that("create_cv() scaffold mode overwrites when overwrite = TRUE", {
    withr::with_tempdir({
        create_cv()
        mtime1 <- file.info("cv-data-template.xlsx")$mtime
        Sys.sleep(2)  # Windows mtime resolution can be up to 2 seconds
        create_cv(overwrite = TRUE)
        mtime2 <- file.info("cv-data-template.xlsx")$mtime
        expect_true(mtime2 > mtime1)
    })
})

# ---------------------------------------------------------------------------
# Render mode — argument validation (errors fire before quarto_render)
# ---------------------------------------------------------------------------

test_that("create_cv() render mode errors on missing workbook", {
    expect_error(
        create_cv(data = "nonexistent/cv.xlsx"),
        regexp = "Cannot find workbook"
    )
})

test_that("create_cv() render mode errors on missing photo", {
    path <- palmer_copy()
    expect_error(
        create_cv(data = path, photo = "nonexistent/photo.png"),
        regexp = "Cannot find profile image"
    )
})

test_that("create_cv() render mode validates variant argument", {
    path <- palmer_copy()
    expect_error(
        create_cv(data = path, variant = "poster"),
        regexp = "should be one of"
    )
})

test_that("create_cv() render mode validates use_icons argument", {
    path <- palmer_copy()
    expect_error(
        create_cv(data = path, use_icons = "svg"),
        regexp = "should be one of"
    )
})

# ---------------------------------------------------------------------------
# Sentinel substitution — CV.qmd content
#
# quarto_render() is mocked inline in each test so create_cv() runs to
# completion and writes CV.qmd without invoking Quarto. We then read back
# the written file and assert on its content directly.
# ---------------------------------------------------------------------------

test_that("create_cv() writes CV.qmd to the workbook directory", {
    path <- palmer_copy()
    local_mocked_bindings(
        quarto_render = function(...) invisible(NULL),
        .package = "quarto"
    )
    create_cv(data = path, overwrite = TRUE)
    expect_true(file.exists(file.path(dirname(path), "CV.qmd")))
})

test_that("create_cv() injects data path sentinel into CV.qmd", {
    path <- palmer_copy()
    local_mocked_bindings(
        quarto_render = function(...) invisible(NULL),
        .package = "quarto"
    )
    create_cv(data = path, overwrite = TRUE)
    lines <- qmd_lines(path)
    # Use basename to avoid path normalization differences across platforms
    expect_true(any(grepl(basename(path), lines, fixed = TRUE)))
    expect_false(any(grepl("__CURRICULR_DATA_PATH__", lines, fixed = TRUE)))
})

test_that("create_cv() injects variant sentinel into CV.qmd", {
    path <- palmer_copy()
    local_mocked_bindings(
        quarto_render = function(...) invisible(NULL),
        .package = "quarto"
    )
    create_cv(data = path, variant = "resume", overwrite = TRUE)
    lines <- qmd_lines(path)
    expect_false(any(grepl("__CURRICULR_VARIANT__", lines, fixed = TRUE)))
    expect_true(any(grepl('variant: "resume"', lines, fixed = TRUE)))
})

test_that("create_cv() variant defaults to cv in CV.qmd", {
    path <- palmer_copy()
    local_mocked_bindings(
        quarto_render = function(...) invisible(NULL),
        .package = "quarto"
    )
    create_cv(data = path, overwrite = TRUE)
    lines <- qmd_lines(path)
    expect_true(any(grepl('variant: "cv"', lines, fixed = TRUE)))
})

test_that("create_cv() injects format YAML block into CV.qmd", {
    path <- palmer_copy()
    local_mocked_bindings(
        quarto_render = function(...) invisible(NULL),
        .package = "quarto"
    )
    create_cv(data = path, overwrite = TRUE)
    lines <- qmd_lines(path)
    expect_false(any(grepl("%%CURRICULR_FORMAT%%", lines, fixed = TRUE)))
    expect_true(any(grepl("format:",    lines, fixed = TRUE)))
    expect_true(any(grepl("typst:",     lines, fixed = TRUE)))
    expect_true(any(grepl("papersize:", lines, fixed = TRUE)))
    expect_true(any(grepl("toc: false", lines, fixed = TRUE)))
})

test_that("create_cv() format block reflects workbook papersize", {
    path <- palmer_copy()
    local_mocked_bindings(
        quarto_render = function(...) invisible(NULL),
        .package = "quarto"
    )
    create_cv(data = path, overwrite = TRUE)
    lines <- qmd_lines(path)
    expect_true(any(grepl("us-letter", lines, fixed = TRUE)))
})

test_that("create_cv() format block reflects workbook margins", {
    path <- palmer_copy()
    local_mocked_bindings(
        quarto_render = function(...) invisible(NULL),
        .package = "quarto"
    )
    create_cv(data = path, overwrite = TRUE)
    lines <- qmd_lines(path)
    expect_true(any(grepl("0.62in", lines, fixed = TRUE)))
    expect_true(any(grepl("0.58in", lines, fixed = TRUE)))
})

test_that("create_cv() injects Typst theme block into CV.qmd", {
    path <- palmer_copy()
    local_mocked_bindings(
        quarto_render = function(...) invisible(NULL),
        .package = "quarto"
    )
    create_cv(data = path, overwrite = TRUE)
    lines <- qmd_lines(path)
    expect_false(any(grepl("%%CURRICULR_THEME%%", lines, fixed = TRUE)))
    expect_true(any(grepl("#set text",     lines, fixed = TRUE)))
    expect_true(any(grepl("#set par",      lines, fixed = TRUE)))
    expect_true(any(grepl("#let accent",   lines, fixed = TRUE)))
    expect_true(any(grepl("#let dark",     lines, fixed = TRUE)))
    expect_true(any(grepl("#let rulegray", lines, fixed = TRUE)))
})

test_that("create_cv() theme block reflects workbook accent color", {
    path <- palmer_copy()
    local_mocked_bindings(
        quarto_render = function(...) invisible(NULL),
        .package = "quarto"
    )
    create_cv(data = path, overwrite = TRUE)
    lines <- qmd_lines(path)
    expect_true(any(grepl("#c5050c", lines, fixed = TRUE)))
})

test_that("create_cv() injects use_icons param into CV.qmd", {
    path <- palmer_copy()
    local_mocked_bindings(
        quarto_render = function(...) invisible(NULL),
        .package = "quarto"
    )
    create_cv(data = path, use_icons = "none", overwrite = TRUE)
    lines <- qmd_lines(path)
    expect_false(any(grepl("__CURRICULR_USE_ICONS__", lines, fixed = TRUE)))
    expect_true(any(grepl('use_icons: "none"', lines, fixed = TRUE)))
})

test_that("create_cv() FA import present when use_icons = fontawesome", {
    path <- palmer_copy()
    local_mocked_bindings(
        quarto_render = function(...) invisible(NULL),
        .package = "quarto"
    )
    create_cv(data = path, use_icons = "fontawesome", overwrite = TRUE)
    lines <- qmd_lines(path)
    expect_true(any(grepl("@preview/fontawesome", lines, fixed = TRUE)))
})

test_that("create_cv() FA import absent when use_icons = none", {
    path <- palmer_copy()
    local_mocked_bindings(
        quarto_render = function(...) invisible(NULL),
        .package = "quarto"
    )
    create_cv(data = path, use_icons = "none", overwrite = TRUE)
    lines <- qmd_lines(path)
    expect_false(any(grepl("@preview/fontawesome", lines, fixed = TRUE)))
})

test_that("create_cv() photo = NULL injects empty string into CV.qmd", {
    path <- palmer_copy()
    local_mocked_bindings(
        quarto_render = function(...) invisible(NULL),
        .package = "quarto"
    )
    create_cv(data = path, photo = NULL, overwrite = TRUE)
    lines <- qmd_lines(path)
    # photo sentinel replaced — no literal sentinel remains
    expect_false(any(grepl("__CURRICULR_PHOTO_PATH__", lines, fixed = TRUE)))
    # the injected value is an empty string in the photo assignment line
    expect_true(any(grepl('photo <- ""', lines, fixed = TRUE)))
})

test_that("create_cv() photo path is injected when photo is supplied", {
    path      <- palmer_copy()
    photo_src <- system.file("extdata", "img", "placeholder.png",
                             package = "curriculr", mustWork = FALSE)
    skip_if_not(file.exists(photo_src), "placeholder not found")
    photo_dst <- file.path(dirname(path), "placeholder.png")
    file.copy(photo_src, photo_dst)
    local_mocked_bindings(
        quarto_render = function(...) invisible(NULL),
        .package = "quarto"
    )
    create_cv(data = path, photo = photo_dst, overwrite = TRUE)
    lines <- qmd_lines(path)
    expect_false(any(grepl("__CURRICULR_PHOTO_PATH__", lines, fixed = TRUE)))
    expect_false(any(grepl('photo <- ""', lines, fixed = TRUE)))
})

# ---------------------------------------------------------------------------
# No sentinel leakage — all sentinels must be replaced
# ---------------------------------------------------------------------------

test_that("create_cv() leaves no unreplaced %% sentinels in CV.qmd", {
    path <- palmer_copy()
    local_mocked_bindings(
        quarto_render = function(...) invisible(NULL),
        .package = "quarto"
    )
    create_cv(data = path, overwrite = TRUE)
    content <- paste(qmd_lines(path), collapse = "\n")
    expect_false(grepl("%%CURRICULR_", content, fixed = TRUE))
})

test_that("create_cv() leaves no unreplaced __ sentinels in CV.qmd", {
    path <- palmer_copy()
    local_mocked_bindings(
        quarto_render = function(...) invisible(NULL),
        .package = "quarto"
    )
    create_cv(data = path, overwrite = TRUE)
    content <- paste(qmd_lines(path), collapse = "\n")
    expect_false(grepl("__CURRICULR_", content, fixed = TRUE))
})

# ---------------------------------------------------------------------------
# Return value
# ---------------------------------------------------------------------------

test_that("create_cv() render mode invisibly returns the PDF path", {
    path <- palmer_copy()
    local_mocked_bindings(
        quarto_render = function(...) invisible(NULL),
        .package = "quarto"
    )
    result <- create_cv(data = path, overwrite = TRUE)
    expect_type(result, "character")
    expect_match(result, "\\.pdf$")
})
