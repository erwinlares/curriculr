# tests/testthat/test-read-cv-data.R

# Use the Frank Palmer example workbook shipped with the package.
palmer_path <- system.file(
    "extdata", "cv-data-template.xlsx",
    package = "curriculr"
)

test_that("read_cv_data() returns a named list", {
    skip_if_not(file.exists(palmer_path), "template workbook not found")
    cv <- read_cv_data(palmer_path)
    expect_type(cv, "list")
    expect_named(cv)
})

test_that("read_cv_data() includes expected sheets", {
    skip_if_not(file.exists(palmer_path), "template workbook not found")
    cv <- read_cv_data(palmer_path)
    expect_true("profile"    %in% names(cv))
    expect_true("education"  %in% names(cv))
    expect_true("experience" %in% names(cv))
})

test_that("read_cv_data() returns profile as named character vector", {
    skip_if_not(file.exists(palmer_path), "template workbook not found")
    cv <- read_cv_data(palmer_path)
    expect_type(cv$profile, "character")
    expect_true(!is.null(names(cv$profile)))
})

test_that("read_cv_data() profile contains expected fields", {
    skip_if_not(file.exists(palmer_path), "template workbook not found")
    cv <- read_cv_data(palmer_path)
    expect_true("first_name" %in% names(cv$profile))
    expect_true("email"      %in% names(cv$profile))
    expect_true("photo"      %in% names(cv$profile))
})

test_that("read_cv_data() sorts dated sheets descending by startYear", {
    skip_if_not(file.exists(palmer_path), "template workbook not found")
    cv <- read_cv_data(palmer_path)
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
