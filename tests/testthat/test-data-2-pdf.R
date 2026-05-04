# tests/testthat/test-data-2-pdf.R
#
# Integration tests — these exercise the full pipeline from workbook to PDF.
# They require Quarto to be installed and are skipped automatically in
# environments where it is not available.
#
# These tests are intentionally slower than the unit tests. They are kept
# in a separate file so they can be identified and excluded from quick
# test runs if needed:
#
#   testthat::test_file("tests/testthat/test-data-2-pdf.R")  # run alone
#   devtools::test(filter = "data-2-pdf")                     # run via devtools

# ---------------------------------------------------------------------------
# Fixture helper
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

# ---------------------------------------------------------------------------
# Guards — all tests in this file require Quarto and a local environment
# ---------------------------------------------------------------------------

# Skip the entire file on CI. Integration tests that invoke quarto_render()
# are sensitive to cli/quarto version interactions on remote runners and are
# intended to be run locally as part of the pre-submission checklist.
skip_on_ci()

skip_if_no_quarto <- function() {
    skip_if_not(
        quarto::quarto_available(),
        "Quarto is not available — skipping integration tests"
    )
}

# ---------------------------------------------------------------------------
# Full CV — default settings
# ---------------------------------------------------------------------------

test_that("create_cv() renders a PDF for the full CV variant", {
    skip_if_no_quarto()
    path   <- palmer_copy()
    result <- create_cv(data = path, overwrite = TRUE)
    expect_true(file.exists(result))
    expect_match(result, "\\.pdf$")
})

test_that("create_cv() PDF is non-empty", {
    skip_if_no_quarto()
    path   <- palmer_copy()
    result <- create_cv(data = path, overwrite = TRUE)
    expect_gt(file.info(result)$size, 0L)
})

test_that("create_cv() PDF is written to the workbook directory", {
    skip_if_no_quarto()
    path   <- palmer_copy()
    result <- create_cv(data = path, overwrite = TRUE)
    expect_equal(dirname(result), dirname(path))
})

test_that("create_cv() respects custom output_file name", {
    skip_if_no_quarto()
    path   <- palmer_copy()
    result <- create_cv(data        = path,
                        output_file = "frank-palmer-cv.pdf",
                        overwrite   = TRUE)
    expect_match(result, "frank-palmer-cv\\.pdf$")
    expect_true(file.exists(result))
})

# ---------------------------------------------------------------------------
# Resume variant
# ---------------------------------------------------------------------------

test_that("create_cv() renders a PDF for the resume variant", {
    skip_if_no_quarto()
    path   <- palmer_copy()
    result <- create_cv(data      = path,
                        variant   = "resume",
                        overwrite = TRUE)
    expect_true(file.exists(result))
    expect_gt(file.info(result)$size, 0L)
})

test_that("create_cv() resume variant PDF is non-empty", {
    skip_if_no_quarto()
    path   <- palmer_copy()
    result <- create_cv(data      = path,
                        variant   = "resume",
                        overwrite = TRUE)
    expect_gt(file.info(result)$size, 0L)
})

# ---------------------------------------------------------------------------
# use_icons variants
# ---------------------------------------------------------------------------

test_that("create_cv() renders successfully with use_icons = fontawesome", {
    skip_if_no_quarto()
    path   <- palmer_copy()
    result <- create_cv(data      = path,
                        use_icons = "fontawesome",
                        overwrite = TRUE)
    expect_true(file.exists(result))
    expect_gt(file.info(result)$size, 0L)
})

test_that("create_cv() renders successfully with use_icons = none", {
    skip_if_no_quarto()
    path   <- palmer_copy()
    result <- create_cv(data      = path,
                        use_icons = "none",
                        overwrite = TRUE)
    expect_true(file.exists(result))
    expect_gt(file.info(result)$size, 0L)
})

# ---------------------------------------------------------------------------
# cap argument
# ---------------------------------------------------------------------------

test_that("create_cv() renders successfully with cap applied", {
    skip_if_no_quarto()
    path   <- palmer_copy()
    result <- create_cv(data      = path,
                        variant   = "resume",
                        cap       = list(presentations = 2, publications = 1),
                        overwrite = TRUE)
    expect_true(file.exists(result))
    expect_gt(file.info(result)$size, 0L)
})

# ---------------------------------------------------------------------------
# Theme — custom values round-trip through to a renderable PDF
# ---------------------------------------------------------------------------

test_that("create_cv() renders with a modified theme sheet", {
    skip_if_no_quarto()
    path <- palmer_copy()

    # Write a modified theme sheet with a different accent color and papersize
    wb <- openxlsx2::wb_load(path)
    theme_df <- openxlsx2::wb_to_df(wb, sheet = "theme", col_names = TRUE)
    theme_df[theme_df$key == "accent_color", "value"] <- "#0000ff"
    theme_df[theme_df$key == "papersize",    "value"] <- "a4"
    wb <- openxlsx2::wb_remove_worksheet(wb, sheet = "theme")
    wb <- openxlsx2::wb_add_worksheet(wb, sheet = "theme")
    wb <- openxlsx2::wb_add_data(wb, sheet = "theme",
                                 x = theme_df, col_names = TRUE)
    openxlsx2::wb_save(wb, file = path, overwrite = TRUE)

    result <- create_cv(data = path, overwrite = TRUE)
    expect_true(file.exists(result))
    expect_gt(file.info(result)$size, 0L)
})

test_that("create_cv() renders when theme sheet is absent (uses defaults)", {
    skip_if_no_quarto()
    path <- palmer_copy()

    # Remove theme sheet to trigger default fallback
    wb <- openxlsx2::wb_load(path)
    wb <- openxlsx2::wb_remove_worksheet(wb, sheet = "theme")
    openxlsx2::wb_save(wb, file = path, overwrite = TRUE)

    result <- suppressMessages(
        create_cv(data = path, overwrite = TRUE)
    )
    expect_true(file.exists(result))
    expect_gt(file.info(result)$size, 0L)
})

# ---------------------------------------------------------------------------
# PDF content — basic smoke check via pdftools
#
# These tests extract text from the rendered PDF and verify that expected
# content is present. They are guarded with skip_if_not so the suite does
# not hard-fail in environments where pdftools is not installed.
# ---------------------------------------------------------------------------

test_that("rendered PDF contains the CV owner's name", {
    skip_if_no_quarto()
    skip_if_not(
        requireNamespace("pdftools", quietly = TRUE),
        "pdftools not installed — skipping PDF content checks"
    )
    path   <- palmer_copy()
    result <- create_cv(data = path, overwrite = TRUE)
    text   <- paste(pdftools::pdf_text(result), collapse = " ")
    expect_match(text, "Frank",  fixed = TRUE)
    expect_match(text, "Palmer", fixed = TRUE)
})

test_that("rendered PDF contains at least one section heading", {
    skip_if_no_quarto()
    skip_if_not(
        requireNamespace("pdftools", quietly = TRUE),
        "pdftools not installed — skipping PDF content checks"
    )
    path   <- palmer_copy()
    result <- create_cv(data = path, overwrite = TRUE)
    text   <- paste(pdftools::pdf_text(result), collapse = " ")
    # Education is first in the sections sheet — it must appear
    expect_match(text, "Education", fixed = TRUE)
})

test_that("resume variant PDF omits entries not marked include_in_resume", {
    skip_if_no_quarto()
    skip_if_not(
        requireNamespace("pdftools", quietly = TRUE),
        "pdftools not installed — skipping PDF content checks"
    )
    path   <- palmer_copy()
    result <- create_cv(data      = path,
                        variant   = "resume",
                        overwrite = TRUE)
    text <- paste(pdftools::pdf_text(result), collapse = " ")

    # "Summer Intensive" is the education entry with include_in_resume = FALSE
    # It must not appear in the resume variant
    expect_false(grepl("Summer Intensive", text, fixed = TRUE))
})
