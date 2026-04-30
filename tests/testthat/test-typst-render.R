# tests/testthat/test-typst-render.R

make_test_data <- function() {
    data.frame(
        title      = c("Role A",      "Role B"),
        unit       = c("Org A",       "Org B"),
        detail     = c("Detail A",    "Detail B"),
        startMonth = c("Jan",         "Mar"),
        startYear  = c("2018",        "2015"),
        endMonth   = c("present",     "Dec"),
        endYear    = c("",            "2020"),
        where      = c("Madison, WI", "Chicago, IL"),
        stringsAsFactors = FALSE
    )
}

# .build_section_blocks() -------------------------------------------------

test_that(".build_section_blocks() returns one block per row", {
    data   <- make_test_data()
    blocks <- .build_section_blocks(data, title_col = "title")
    expect_length(blocks, nrow(data))
})

test_that(".build_section_blocks() returns character vector", {
    data   <- make_test_data()
    blocks <- .build_section_blocks(data, title_col = "title")
    expect_type(blocks, "character")
})

test_that(".build_section_blocks() includes title content in blocks", {
    data   <- make_test_data()
    blocks <- .build_section_blocks(data, title_col = "title")
    expect_true(grepl("Role A", blocks[[1]]))
    expect_true(grepl("Role B", blocks[[2]]))
})

test_that(".build_section_blocks() includes org content when org_col supplied", {
    data   <- make_test_data()
    blocks <- .build_section_blocks(data,
                                    title_col = "title",
                                    org_col   = "unit")
    expect_true(grepl("Org A", blocks[[1]]))
})

test_that(".build_section_blocks() omits date when date_fun is NULL", {
    data   <- make_test_data()
    blocks <- .build_section_blocks(data,
                                    title_col = "title",
                                    date_fun  = NULL)
    expect_false(grepl("2018", blocks[[1]]))
})

test_that(".build_section_blocks() omits location when where_col is NULL", {
    data   <- make_test_data()
    blocks <- .build_section_blocks(data,
                                    title_col = "title",
                                    where_col = NULL)
    expect_false(grepl("Madison", blocks[[1]]))
})

test_that(".build_section_blocks() handles empty data frame gracefully", {
    data   <- make_test_data()[0, ]
    blocks <- .build_section_blocks(data, title_col = "title")
    expect_length(blocks, 0L)
})

# cv_render_section() -----------------------------------------------------

test_that("cv_render_section() returns NULL invisibly", {
    data   <- make_test_data()
    result <- cv_render_section(data, title_col = "title")
    expect_null(result)
})

test_that("cv_render_section() returns NULL invisibly on empty data", {
    result <- cv_render_section(NULL, title_col = "title")
    expect_null(result)
})
