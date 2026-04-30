# tests/testthat/test-typst-layout.R

# cv_section() -----------------------------------------------------------

test_that("cv_section() returns a character string", {
    result <- cv_section("Education")
    expect_type(result, "character")
    expect_length(result, 1L)
})

test_that("cv_section() contains the section title", {
    result <- cv_section("Education")
    expect_true(grepl("ducation", result))  # first letter split off for accent
})

test_that("cv_section() contains Typst code fence markers", {
    result <- cv_section("Education")
    expect_true(grepl("```\\{=typst\\}", result))
    expect_true(grepl("```", result))
})

test_that("cv_section() splits first letter from rest of title", {
    result <- cv_section("Grants and Awards")
    expect_true(grepl("G", result))
    expect_true(grepl("rants and Awards", result))
})

# .cv_entry() -------------------------------------------------------------

test_that(".cv_entry() returns a character string", {
    result <- .cv_entry(title = "Research Facilitator")
    expect_type(result, "character")
    expect_length(result, 1L)
})

test_that(".cv_entry() contains the title", {
    result <- .cv_entry(title = "Research Facilitator")
    expect_true(grepl("Research Facilitator", result))
})

test_that(".cv_entry() contains organization when supplied", {
    result <- .cv_entry(
        title        = "Research Facilitator",
        organization = "UW-Madison"
    )
    expect_true(grepl("UW-Madison", result))
})

test_that(".cv_entry() contains date when supplied", {
    result <- .cv_entry(title = "Something", when = "Jan 2018 - Present")
    expect_true(grepl("Jan 2018 - Present", result))
})

test_that(".cv_entry() handles empty optional arguments gracefully", {
    expect_no_error(.cv_entry(title = ""))
    expect_no_error(.cv_entry())
})

test_that(".cv_entry() escapes Typst-sensitive characters in title", {
    result <- .cv_entry(title = "user@domain.com")
    expect_true(grepl("\\\\@", result))
})

test_that(".cv_entry() joins organization and detail with em dash", {
    result <- .cv_entry(
        title        = "Something",
        organization = "Org",
        detail       = "Detail"
    )
    expect_true(grepl("\u2014", result))
})

test_that(".cv_entry() omits em dash when only one of org/detail present", {
    result_org_only    <- .cv_entry(title = "T", organization = "Org")
    result_detail_only <- .cv_entry(title = "T", detail = "Detail")
    expect_false(grepl("\u2014", result_org_only))
    expect_false(grepl("\u2014", result_detail_only))
})
