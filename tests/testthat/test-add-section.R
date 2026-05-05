# tests/testthat/test-add-section.R

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
# Happy path — sheet is added
# ---------------------------------------------------------------------------

test_that("add_section() adds a new sheet to the workbook", {
    path <- palmer_copy()
    add_section(path, section = "patents")
    sheets <- openxlsx2::wb_get_sheet_names(openxlsx2::wb_load(path))
    expect_true("patents" %in% sheets)
})

test_that("add_section() new sheet has the standard column spine", {
    path <- palmer_copy()
    add_section(path, section = "patents")
    df <- openxlsx2::read_xlsx(path, sheet = "patents")
    expected_cols <- c(
        "title", "unit", "startMonth", "startYear",
        "endMonth", "endYear", "where", "detail", "include_in_resume"
    )
    expect_equal(names(df), expected_cols)
})

test_that("add_section() new sheet is empty (header only, no data rows)", {
    path <- palmer_copy()
    add_section(path, section = "patents")
    df <- openxlsx2::read_xlsx(path, sheet = "patents")
    expect_equal(nrow(df), 0L)
})

# ---------------------------------------------------------------------------
# Happy path — sections sheet is updated
# ---------------------------------------------------------------------------

test_that("add_section() appends a row to the sections sheet", {
    path            <- palmer_copy()
    sections_before <- nrow(openxlsx2::read_xlsx(path, sheet = "sections"))
    add_section(path, section = "patents")
    sections_after  <- nrow(openxlsx2::read_xlsx(path, sheet = "sections"))
    expect_equal(sections_after, sections_before + 1L)
})

test_that("add_section() sections row has correct section name", {
    path <- palmer_copy()
    add_section(path, section = "patents")
    df       <- openxlsx2::read_xlsx(path, sheet = "sections")
    last_row <- df[nrow(df), ]
    expect_equal(last_row[["section"]], "patents")
})

test_that("add_section() sections row label defaults to section name", {
    path <- palmer_copy()
    add_section(path, section = "patents")
    df       <- openxlsx2::read_xlsx(path, sheet = "sections")
    last_row <- df[nrow(df), ]
    expect_equal(last_row[["label"]], "patents")
})

test_that("add_section() sections row uses supplied label", {
    path <- palmer_copy()
    add_section(path, section = "patents", label = "Patents & Inventions")
    df       <- openxlsx2::read_xlsx(path, sheet = "sections")
    last_row <- df[nrow(df), ]
    expect_equal(last_row[["label"]], "Patents & Inventions")
})

test_that("add_section() sections row records correct date_fun token", {
    path <- palmer_copy()
    add_section(path, section = "patents", date_fun = "month_year")
    df       <- openxlsx2::read_xlsx(path, sheet = "sections")
    last_row <- df[nrow(df), ]
    expect_equal(last_row[["date_fun"]], "month_year")
})

test_that("add_section() sections row records correct column overrides", {
    path <- palmer_copy()
    add_section(path,
                section    = "patents",
                title_col  = "title",
                org_col    = "unit",
                detail_col = "detail",
                where_col  = "where")
    df       <- openxlsx2::read_xlsx(path, sheet = "sections")
    last_row <- df[nrow(df), ]
    expect_equal(last_row[["title_col"]],  "title")
    expect_equal(last_row[["org_col"]],    "unit")
    expect_equal(last_row[["detail_col"]], "detail")
    expect_equal(last_row[["where_col"]],  "where")
})

test_that("add_section() sections row records blank for omitted optional cols", {
    path <- palmer_copy()
    add_section(path,
                section    = "languages",
                date_fun   = "none",
                org_col    = NA,
                detail_col = NA,
                where_col  = NA)
    # Omitted columns are written as empty strings which read back as NA
    df       <- openxlsx2::read_xlsx(path, sheet = "sections",
                                     na.strings = c("", "NA"))
    last_row <- df[nrow(df), ]
    expect_true(is.na(last_row[["org_col"]])    || nchar(last_row[["org_col"]]    %||% "") == 0)
    expect_true(is.na(last_row[["detail_col"]]) || nchar(last_row[["detail_col"]] %||% "") == 0)
    expect_true(is.na(last_row[["where_col"]])  || nchar(last_row[["where_col"]]  %||% "") == 0)
})

# ---------------------------------------------------------------------------
# Sheet insertion position
# ---------------------------------------------------------------------------

test_that("add_section() new sheet exists in the workbook", {
    path   <- palmer_copy()
    add_section(path, section = "patents")
    sheets <- openxlsx2::wb_get_sheet_names(openxlsx2::wb_load(path))
    expect_true("patents" %in% sheets)
})

# ---------------------------------------------------------------------------
# Return value
# ---------------------------------------------------------------------------

test_that("add_section() invisibly returns the workbook path", {
    path   <- palmer_copy()
    result <- add_section(path, section = "patents")
    expect_equal(normalizePath(result), normalizePath(path))
})

# ---------------------------------------------------------------------------
# overwrite = FALSE errors on duplicate
# ---------------------------------------------------------------------------

test_that("add_section() errors on duplicate section name when overwrite = FALSE", {
    path <- palmer_copy()
    add_section(path, section = "patents")
    expect_error(
        add_section(path, section = "patents"),
        regexp = "already exists"
    )
})

test_that("add_section() overwrite = TRUE replaces existing sheet", {
    path <- palmer_copy()
    add_section(path, section = "patents", date_fun = "year_only")
    add_section(path, section = "patents", date_fun = "month_year",
                overwrite = TRUE)
    df        <- openxlsx2::read_xlsx(path, sheet = "sections")
    n_patents <- sum(df[["section"]] == "patents", na.rm = TRUE)
    expect_equal(n_patents, 1L)
    last_patents <- df[df[["section"]] == "patents", ]
    expect_equal(last_patents[["date_fun"]], "month_year")
})

# ---------------------------------------------------------------------------
# Reserved sheet names are rejected
# ---------------------------------------------------------------------------

test_that("add_section() errors on reserved sheet name 'profile'", {
    path <- palmer_copy()
    expect_error(add_section(path, section = "profile"),
                 regexp = "reserved")
})

test_that("add_section() errors on reserved sheet name 'sections'", {
    path <- palmer_copy()
    expect_error(add_section(path, section = "sections"),
                 regexp = "reserved")
})

test_that("add_section() errors on reserved sheet name 'theme'", {
    path <- palmer_copy()
    expect_error(add_section(path, section = "theme"),
                 regexp = "reserved")
})

test_that("add_section() errors on reserved sheet name 'readme'", {
    path <- palmer_copy()
    expect_error(add_section(path, section = "readme"),
                 regexp = "reserved")
})

# ---------------------------------------------------------------------------
# Sheet name length validation
# ---------------------------------------------------------------------------

test_that("add_section() errors when section name exceeds 31 characters", {
    path      <- palmer_copy()
    long_name <- strrep("a", 32)
    expect_error(
        add_section(path, section = long_name),
        regexp = "too long"
    )
})

test_that("add_section() accepts a section name of exactly 31 characters", {
    path      <- palmer_copy()
    edge_name <- strrep("a", 31)
    expect_no_error(add_section(path, section = edge_name))
})

# ---------------------------------------------------------------------------
# date_fun token validation
# ---------------------------------------------------------------------------

test_that("add_section() errors on invalid date_fun token", {
    path <- palmer_copy()
    expect_error(
        add_section(path, section = "patents", date_fun = "quarterly"),
        regexp = "date_fun"
    )
})

test_that("add_section() accepts all valid date_fun tokens", {
    path   <- palmer_copy()
    tokens <- c("date", "year", "month_year", "year_only", "none")
    for (token in tokens) {
        section_name <- paste0("test_", token)
        expect_no_error(
            add_section(path, section = section_name, date_fun = token)
        )
    }
})

# ---------------------------------------------------------------------------
# Missing workbook
# ---------------------------------------------------------------------------

test_that("add_section() errors informatively on missing workbook", {
    expect_error(
        add_section("nonexistent/path/cv.xlsx", section = "patents"),
        regexp = "Cannot find workbook"
    )
})
