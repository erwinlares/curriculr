# tests/testthat/test-cv-contact.R

# ---------------------------------------------------------------------------
# Fixture — minimal profile vectors for focused unit tests
# ---------------------------------------------------------------------------

full_profile <- c(
    first_name  = "Frank",
    last_name   = "Palmer",
    email       = "frank.palmer@frankpalmerillustration.com",
    website     = "frankpalmerillustration.com",
    github      = "fpalmer-draws",
    linkedin    = "in/frank-palmer-illustration"
)

email_only_profile <- c(
    first_name = "Frank",
    email      = "frank@example.com"
)

empty_profile <- c(first_name = "Frank", last_name = "Palmer")

# ---------------------------------------------------------------------------
# cv_contact_line() — use_icons = "fontawesome"
# ---------------------------------------------------------------------------

test_that("cv_contact_line() with fontawesome includes fa-icon calls", {
    result <- cv_contact_line(full_profile, use_icons = "fontawesome")
    expect_match(result, '#fa-icon("envelope")', fixed = TRUE)
    expect_match(result, '#fa-icon("globe")',    fixed = TRUE)
    expect_match(result, '#fa-icon("github")',   fixed = TRUE)
    expect_match(result, '#fa-icon("linkedin")', fixed = TRUE)
})

test_that("cv_contact_line() with fontawesome uses Typst h() separator", {
    result <- cv_contact_line(full_profile, use_icons = "fontawesome")
    expect_match(result, "#h(0.6em)", fixed = TRUE)
})

test_that("cv_contact_line() with fontawesome expands github to full URL", {
    result <- cv_contact_line(full_profile, use_icons = "fontawesome")
    expect_match(result, "github.com/fpalmer-draws", fixed = TRUE)
})

test_that("cv_contact_line() with fontawesome expands linkedin to full URL", {
    result <- cv_contact_line(full_profile, use_icons = "fontawesome")
    expect_match(result, "linkedin.com/in/frank-palmer-illustration",
                 fixed = TRUE)
})

test_that("cv_contact_line() with fontawesome includes email value", {
    result <- cv_contact_line(email_only_profile, use_icons = "fontawesome")
    expect_match(result, "frank", fixed = TRUE)
})

# ---------------------------------------------------------------------------
# cv_contact_line() — use_icons = "none"
# ---------------------------------------------------------------------------

test_that("cv_contact_line() with use_icons = 'none' produces no fa-icon calls", {
    result <- cv_contact_line(full_profile, use_icons = "none")
    expect_false(grepl("#fa-icon", result, fixed = TRUE))
})

test_that("cv_contact_line() with use_icons = 'none' uses middle-dot separator", {
    result <- cv_contact_line(full_profile, use_icons = "none")
    expect_match(result, "\u00b7", fixed = TRUE)
})

test_that("cv_contact_line() with use_icons = 'none' still expands github URL", {
    result <- cv_contact_line(full_profile, use_icons = "none")
    expect_match(result, "github.com/fpalmer-draws", fixed = TRUE)
})

test_that("cv_contact_line() with use_icons = 'none' still expands linkedin URL", {
    result <- cv_contact_line(full_profile, use_icons = "none")
    expect_match(result, "linkedin.com/in/frank-palmer-illustration",
                 fixed = TRUE)
})

# ---------------------------------------------------------------------------
# cv_contact_line() — empty and missing fields
# ---------------------------------------------------------------------------

test_that("cv_contact_line() omits fields absent from profile", {
    result <- cv_contact_line(email_only_profile, use_icons = "none")
    expect_false(grepl("github", result, fixed = TRUE))
    expect_false(grepl("linkedin", result, fixed = TRUE))
})

test_that("cv_contact_line() returns empty string when no contact fields present", {
    result <- cv_contact_line(empty_profile, use_icons = "fontawesome")
    expect_equal(result, "")
})

test_that("cv_contact_line() omits fields with empty string values", {
    profile <- c(email = "frank@example.com", github = "")
    result  <- cv_contact_line(profile, use_icons = "none")
    expect_false(grepl("github.com", result, fixed = TRUE))
})


# ---------------------------------------------------------------------------
# cv_contact_line() — use_icons argument validation
# ---------------------------------------------------------------------------

test_that("cv_contact_line() errors on invalid use_icons value", {
    expect_error(
        cv_contact_line(full_profile, use_icons = "svg"),
        regexp = "should be one of"
    )
})

# ---------------------------------------------------------------------------
# .fa_icon_map() — internal helper
# ---------------------------------------------------------------------------

test_that(".fa_icon_map() returns a named character vector", {
    map <- curriculr:::.fa_icon_map()
    expect_type(map, "character")
    expect_false(is.null(names(map)))
})

test_that(".fa_icon_map() contains expected field-to-icon mappings", {
    map <- curriculr:::.fa_icon_map()
    expect_equal(map[["email"]],    "envelope")
    expect_equal(map[["website"]],  "globe")
    expect_equal(map[["github"]],   "github")
    expect_equal(map[["linkedin"]], "linkedin")
    expect_equal(map[["phone"]],    "phone")
})

# ---------------------------------------------------------------------------
# .cv_theme_defaults() — internal helper
# ---------------------------------------------------------------------------

test_that(".cv_theme_defaults() returns a named character vector", {
    defaults <- curriculr:::.cv_theme_defaults()
    expect_type(defaults, "character")
    expect_false(is.null(names(defaults)))
})

test_that(".cv_theme_defaults() contains all twelve expected keys", {
    defaults <- curriculr:::.cv_theme_defaults()
    expected <- c(
        "font_family", "font_size", "body_color", "line_leading",
        "accent_color", "dark_color", "bodygray_color",
        "lightgray_color", "rulegray_color",
        "papersize", "margin_x", "margin_y"
    )
    expect_true(all(expected %in% names(defaults)))
})

test_that(".cv_theme_defaults() default accent color matches workbook default", {
    defaults <- curriculr:::.cv_theme_defaults()
    expect_equal(defaults[["accent_color"]], "#c5050c")
})

# ---------------------------------------------------------------------------
# .resolve_theme() — internal helper
# ---------------------------------------------------------------------------

test_that(".resolve_theme() returns defaults when theme is NULL", {
    resolved <- curriculr:::.resolve_theme(NULL)
    defaults <- curriculr:::.cv_theme_defaults()
    expect_equal(resolved[["accent_color"]], defaults[["accent_color"]])
    expect_equal(resolved[["papersize"]],    defaults[["papersize"]])
})

test_that(".resolve_theme() user values override defaults", {
    custom <- c(accent_color = "#ff0000")
    resolved <- curriculr:::.resolve_theme(custom)
    expect_equal(resolved[["accent_color"]], "#ff0000")
})

test_that(".resolve_theme() fills missing keys from defaults", {
    partial  <- c(accent_color = "#ff0000")
    resolved <- curriculr:::.resolve_theme(partial)
    defaults <- curriculr:::.cv_theme_defaults()
    expect_equal(resolved[["font_family"]], defaults[["font_family"]])
    expect_equal(resolved[["papersize"]],   defaults[["papersize"]])
})

test_that(".resolve_theme() result always has all twelve keys", {
    resolved <- curriculr:::.resolve_theme(NULL)
    expect_length(resolved, 12L)
})

# ---------------------------------------------------------------------------
# .build_format_block() — internal helper
# ---------------------------------------------------------------------------

test_that(".build_format_block() produces valid YAML structure", {
    theme  <- curriculr:::.cv_theme_defaults()
    block  <- curriculr:::.build_format_block(theme)
    expect_match(block, "format:",        fixed = TRUE)
    expect_match(block, "typst:",         fixed = TRUE)
    expect_match(block, "papersize:",     fixed = TRUE)
    expect_match(block, "toc: false",     fixed = TRUE)
    expect_match(block, "margin:",        fixed = TRUE)
})

test_that(".build_format_block() injects correct papersize", {
    theme         <- curriculr:::.cv_theme_defaults()
    theme[["papersize"]] <- "a4"
    block <- curriculr:::.build_format_block(theme)
    expect_match(block, "papersize: a4", fixed = TRUE)
})

test_that(".build_format_block() injects correct margins", {
    theme <- curriculr:::.cv_theme_defaults()
    block <- curriculr:::.build_format_block(theme)
    expect_match(block, "x: 0.62in", fixed = TRUE)
    expect_match(block, "y: 0.58in", fixed = TRUE)
})

# ---------------------------------------------------------------------------
# .build_typst_theme_block() — internal helper
# ---------------------------------------------------------------------------

test_that(".build_typst_theme_block() includes FA import when use_icons = fontawesome", {
    theme <- curriculr:::.cv_theme_defaults()
    block <- curriculr:::.build_typst_theme_block(theme, use_icons = "fontawesome")
    expect_match(block, "@preview/fontawesome", fixed = TRUE)
})

test_that(".build_typst_theme_block() omits FA import when use_icons = none", {
    theme <- curriculr:::.cv_theme_defaults()
    block <- curriculr:::.build_typst_theme_block(theme, use_icons = "none")
    expect_false(grepl("@preview/fontawesome", block, fixed = TRUE))
})

test_that(".build_typst_theme_block() injects correct accent color", {
    theme <- curriculr:::.cv_theme_defaults()
    block <- curriculr:::.build_typst_theme_block(theme)
    expect_match(block, '#c5050c', fixed = TRUE)
})

test_that(".build_typst_theme_block() defines all five color variables", {
    theme <- curriculr:::.cv_theme_defaults()
    block <- curriculr:::.build_typst_theme_block(theme)
    expect_match(block, "#let accent",    fixed = TRUE)
    expect_match(block, "#let dark",      fixed = TRUE)
    expect_match(block, "#let bodygray",  fixed = TRUE)
    expect_match(block, "#let lightgray", fixed = TRUE)
    expect_match(block, "#let rulegray",  fixed = TRUE)
})

test_that(".build_typst_theme_block() wraps output in typst code fence", {
    theme <- curriculr:::.cv_theme_defaults()
    block <- curriculr:::.build_typst_theme_block(theme)
    expect_match(block, "```{=typst}", fixed = TRUE)
    expect_match(block, "```",         fixed = TRUE)
})
