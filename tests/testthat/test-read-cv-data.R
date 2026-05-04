# tests/testthat/test-read-cv-data.R

# ---------------------------------------------------------------------------
# Fixture helpers
#
# All tests that touch the workbook use a per-test temporary copy via
# withr::local_tempdir(). This keeps tests hermetic and avoids any
# interaction with the installed package file.
# ---------------------------------------------------------------------------

palmer_src <- function() {
    system.file(
        "extdata", "cv-data-template.xlsx",
        package  = "curriculr",
        mustWork = FALSE
    )
}

# Copy the template workbook to a temp dir and return the new path
palmer_copy <- function(env = parent.frame()) {
    src <- palmer_src()
    skip_if_not(file.exists(src), "template workbook not found")
    dir <- withr::local_tempdir(.local_envir = env)
    dst <- file.path(dir, "cv-data-template.xlsx")
    file.copy(src, dst)
    dst
}

# ---------------------------------------------------------------------------
# Existing tests — preserved, upgraded to use temp copies
# ---------------------------------------------------------------------------

test_that("read_cv_data() returns a named list", {
    path <- palmer_copy()
    cv   <- read_cv_data(path)
    expect_type(cv, "list")
    expect_named(cv)
})

test_that("read_cv_data() includes expected sheets", {
    path <- palmer_copy()
    cv   <- read_cv_data(path)
    expect_true("profile"    %in% names(cv))
    expect_true("education"  %in% names(cv))
    expect_true("experience" %in% names(cv))
    expect_true("sections"   %in% names(cv))
})

test_that("read_cv_data() returns profile as named character vector", {
    path <- palmer_copy()
    cv   <- read_cv_data(path)
    expect_type(cv$profile, "character")
    expect_false(is.null(names(cv$profile)))
})

test_that("read_cv_data() profile contains expected fields", {
    path <- palmer_copy()
    cv   <- read_cv_data(path)
    expect_true("first_name" %in% names(cv$profile))
    expect_true("email"      %in% names(cv$profile))
    expect_true("photo"      %in% names(cv$profile))
})

test_that("read_cv_data() profile values are correct", {
    path <- palmer_copy()
    cv   <- read_cv_data(path)
    expect_equal(cv$profile[["first_name"]], "Frank")
    expect_equal(cv$profile[["last_name"]],  "Palmer")
    expect_equal(cv$profile[["github"]],     "fpalmer-draws")
})

test_that("read_cv_data() sorts dated sheets descending by startYear", {
    path  <- palmer_copy()
    cv    <- read_cv_data(path)
    years <- suppressWarnings(as.numeric(cv$experience$startYear))
    years <- years[!is.na(years)]
    expect_true(all(diff(years) <= 0))
})

test_that("read_cv_data() errors informatively on missing file", {
    expect_error(
        read_cv_data("nonexistent/path/cv.xlsx"),
        regexp = "Cannot find CV workbook"
    )
})

# ---------------------------------------------------------------------------
# readme sheet is excluded from the returned list
# ---------------------------------------------------------------------------

test_that("read_cv_data() does not return the readme sheet", {
    path <- palmer_copy()
    cv   <- read_cv_data(path)
    expect_false("readme" %in% names(cv))
})

# ---------------------------------------------------------------------------
# theme sheet
# ---------------------------------------------------------------------------

test_that("read_cv_data() returns theme as named character vector", {
    path <- palmer_copy()
    cv   <- read_cv_data(path)
    expect_type(cv$theme, "character")
    expect_false(is.null(names(cv$theme)))
})

test_that("read_cv_data() theme contains all expected keys", {
    path <- palmer_copy()
    cv   <- read_cv_data(path)
    expected_keys <- c(
        "font_family", "font_size", "body_color", "line_leading",
        "accent_color", "dark_color", "bodygray_color",
        "lightgray_color", "rulegray_color",
        "papersize", "margin_x", "margin_y"
    )
    expect_true(all(expected_keys %in% names(cv$theme)))
})

test_that("read_cv_data() theme values match workbook defaults", {
    path <- palmer_copy()
    cv   <- read_cv_data(path)
    expect_equal(cv$theme[["font_family"]],  "Lato")
    expect_equal(cv$theme[["accent_color"]], "#c5050c")
    expect_equal(cv$theme[["papersize"]],    "us-letter")
    expect_equal(cv$theme[["margin_x"]],     "0.62in")
    expect_equal(cv$theme[["margin_y"]],     "0.58in")
})

test_that("read_cv_data() returns NULL theme and informs when theme sheet absent", {
    path <- palmer_copy()

    # Remove the theme sheet from the temp copy
    wb <- openxlsx2::wb_load(path)
    wb <- openxlsx2::wb_remove_worksheet(wb, sheet = "theme")
    openxlsx2::wb_save(wb, file = path, overwrite = TRUE)

    expect_message(
        cv <- read_cv_data(path),
        regexp = "No.*theme.*sheet"
    )
    expect_null(cv$theme)
})

test_that("read_cv_data() theme is not included in section list", {
    path <- palmer_copy()
    cv   <- read_cv_data(path)
    # theme should be accessible as cv$theme but not rendered as a section
    expect_false("theme" %in% cv$sections[["section"]])
})

# ---------------------------------------------------------------------------
# include_in_resume column handling
# ---------------------------------------------------------------------------

test_that("read_cv_data() drops include_in_resume from returned data frames", {
    path <- palmer_copy()
    cv   <- read_cv_data(path)
    expect_false("include_in_resume" %in% names(cv$education))
    expect_false("include_in_resume" %in% names(cv$experience))
    expect_false("include_in_resume" %in% names(cv$affiliations))
})

test_that("read_cv_data() variant = 'cv' returns all rows", {
    path <- palmer_copy()
    cv   <- read_cv_data(path, variant = "cv")
    # education has 2 rows, experience has 3, affiliations has 4
    expect_equal(nrow(cv$education),   2L)
    expect_equal(nrow(cv$experience),  3L)
    expect_equal(nrow(cv$affiliations), 4L)
})

test_that("read_cv_data() variant = 'resume' keeps only checked rows", {
    path <- palmer_copy()
    cv   <- read_cv_data(path, variant = "resume")
    # education: TRUE, FALSE -> 1 row
    expect_equal(nrow(cv$education), 1L)
    # experience: TRUE, TRUE, FALSE -> 2 rows
    expect_equal(nrow(cv$experience), 2L)
    # affiliations: TRUE, TRUE, FALSE, TRUE -> 3 rows
    expect_equal(nrow(cv$affiliations), 3L)
    # presentations: TRUE, TRUE, FALSE, TRUE, TRUE -> 4 rows
    expect_equal(nrow(cv$presentations), 4L)
})

test_that("read_cv_data() variant = 'resume' still drops include_in_resume", {
    path <- palmer_copy()
    cv   <- read_cv_data(path, variant = "resume")
    expect_false("include_in_resume" %in% names(cv$education))
    expect_false("include_in_resume" %in% names(cv$affiliations))
})

test_that("read_cv_data() variant argument is validated", {
    path <- palmer_copy()
    expect_error(
        read_cv_data(path, variant = "poster"),
        regexp = "should be one of"
    )
})

# ---------------------------------------------------------------------------
# All columns are character after coercion
# ---------------------------------------------------------------------------

test_that("read_cv_data() returns all section columns as character", {
    path <- palmer_copy()
    cv   <- read_cv_data(path)
    col_types <- sapply(cv$education, class)
    expect_true(all(col_types == "character"))
})

test_that("read_cv_data() coerces numeric year columns to character", {
    path <- palmer_copy()
    cv   <- read_cv_data(path)
    expect_type(cv$experience$startYear, "character")
    expect_type(cv$experience$endYear,   "character")
})

# ---------------------------------------------------------------------------
# sections sheet is preserved in row order
# ---------------------------------------------------------------------------

test_that("read_cv_data() preserves sections row order", {
    path <- palmer_copy()
    cv   <- read_cv_data(path)
    expect_equal(
        cv$sections$section,
        c("education", "experience", "projects", "invited_teaching",
          "publications", "presentations", "certifications",
          "grants_and_awards", "admin_services", "skills", "affiliations")
    )
})
