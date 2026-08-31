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

# .cv_entry_bulleted() ----------------------------------------------------

test_that(".cv_entry_bulleted() contains every detail supplied", {
    # The aggregation contract. Multiple rows sharing a composite key collapse
    # into one entry, and no responsibility may be dropped in the process.
    details <- c("Alpha item", "Beta item", "Gamma item")
    result  <- .cv_entry_bulleted(title = "T", details = details)

    for (d in details) {
        expect_true(grepl(d, result, fixed = TRUE), info = d)
    }
})

test_that(".cv_entry_bulleted() escapes Typst-sensitive characters in details", {
    # Detail text comes straight from the user's workbook, so it is the most
    # likely route by which an unescaped character reaches the Typst compiler.
    result <- .cv_entry_bulleted(
        title   = "T",
        details = c("Contact user@domain.com", "Plain item")
    )
    expect_true(grepl("\\\\@", result))
})

test_that(".cv_entry_bulleted() does not render the organization argument", {
    # `organization` is accepted for call-site symmetry with .cv_entry() but is
    # deliberately not rendered -- organization context is expected to live in
    # the detail text itself. Pinned here because the decision is otherwise
    # invisible in the code.
    result <- .cv_entry_bulleted(
        title        = "T",
        organization = "ZZZUniqueOrgZZZ",
        details      = c("Alpha", "Beta")
    )
    expect_false(grepl("ZZZUniqueOrgZZZ", result, fixed = TRUE))
})

test_that(".cv_entry_bulleted() emits a Typst list rather than padded blocks", {
    # Regression guard. An earlier implementation wrapped each bullet in its own
    # `#pad()`, which is block-level in Typst: the gap between bullets was then
    # governed by the document's `par.spacing` rather than by anything this
    # package controls. Emitting a single `#list()` keeps the spacing local.
    result <- .cv_entry_bulleted(
        title   = "T",
        details = c("Alpha", "Beta", "Gamma")
    )
    expect_true(grepl("#list(", result, fixed = TRUE))
    expect_false(grepl("#pad(", result, fixed = TRUE))
})

test_that(".cv_entry_bulleted() sets all vertical spacing explicitly", {
    # The reproducibility guard. Every spacing value the bulleted entry depends
    # on must appear in the emitted markup; anything omitted here would resolve
    # against the enclosing document instead, which is precisely how identical
    # data came to render with different bullet gaps in two builds. The test
    # checks for the parameter names, not their values, so tuning the constants
    # does not churn the suite.
    result <- .cv_entry_bulleted(
        title   = "T",
        details = c("Alpha", "Beta")
    )
    expect_true(grepl("leading:",     result, fixed = TRUE))
    expect_true(grepl("spacing:",     result, fixed = TRUE))
    expect_true(grepl("tight: false", result, fixed = TRUE))
    expect_true(grepl("indent:",      result, fixed = TRUE))
    expect_true(grepl("body-indent:", result, fixed = TRUE))
    expect_true(grepl("above:",       result, fixed = TRUE))
})
