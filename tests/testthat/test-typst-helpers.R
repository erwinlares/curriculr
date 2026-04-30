# tests/testthat/test-typst-helpers.R

test_that("%||% returns left side when not NULL or empty", {
    expect_equal("a" %||% "b", "a")
    expect_equal(1L  %||% 2L,  1L)
})

test_that("%||% returns right side when left is NULL", {
    expect_equal(NULL %||% "b", "b")
})

test_that("%||% returns right side when left is length-0", {
    expect_equal(character(0) %||% "b", "b")
})

test_that("%||% returns right side when left is all NA", {
    expect_equal(NA %||% "b", "b")
    expect_equal(c(NA, NA) %||% "b", "b")
})

# .cv_value() -------------------------------------------------------------

test_that(".cv_value() extracts a present column value", {
    row <- data.frame(title = "Research Facilitator", stringsAsFactors = FALSE)
    expect_equal(.cv_value(row, "title"), "Research Facilitator")
})

test_that(".cv_value() returns default when column is absent", {
    row <- data.frame(title = "Something", stringsAsFactors = FALSE)
    expect_equal(.cv_value(row, "missing_col"), "")
    expect_equal(.cv_value(row, "missing_col", default = "n/a"), "n/a")
})

test_that(".cv_value() returns default when value is NA", {
    row <- data.frame(title = NA_character_, stringsAsFactors = FALSE)
    expect_equal(.cv_value(row, "title"), "")
})

test_that(".cv_value() coerces numeric values to character", {
    row <- data.frame(startYear = 2020, stringsAsFactors = FALSE)
    expect_equal(.cv_value(row, "startYear"), "2020")
})

# .typst_escape() ---------------------------------------------------------

test_that(".typst_escape() escapes Typst special characters", {
    expect_equal(.typst_escape("#"),  "\\#")
    expect_equal(.typst_escape("$"),  "\\$")
    expect_equal(.typst_escape("@"),  "\\@")
    expect_equal(.typst_escape("_"),  "\\_")
    expect_equal(.typst_escape("&"),  "\\&")
})

test_that(".typst_escape() escapes email addresses", {
    result <- .typst_escape("erwin.lares@wisc.edu")
    expect_true(grepl("\\\\@", result))
    expect_false(grepl("[^\\]@", result))
})

test_that(".typst_escape() handles NULL and NA gracefully", {
    expect_equal(.typst_escape(NULL), "")
    expect_equal(.typst_escape(NA),   "")
})

test_that(".typst_escape() strips HTML line break tags", {
    expect_equal(.typst_escape("line one<br>line two"), "line one line two")
    expect_equal(.typst_escape("line one<br/>line two"), "line one line two")
})

test_that(".typst_escape() collapses repeated whitespace", {
    expect_equal(.typst_escape("too   many   spaces"), "too many spaces")
})

test_that(".typst_escape() trims leading and trailing whitespace", {
    expect_equal(.typst_escape("  padded  "), "padded")
})

test_that(".typst_escape() passes plain text through unchanged", {
    expect_equal(.typst_escape("plain text"), "plain text")
})
