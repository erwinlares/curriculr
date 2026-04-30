# tests/testthat/test-typst-dates.R

# .cv_date_range() --------------------------------------------------------

test_that(".cv_date_range() formats a full start-end range", {
    row <- data.frame(
        startMonth = "Jan", startYear = "2018",
        endMonth   = "Dec", endYear   = "2022",
        stringsAsFactors = FALSE
    )
    expect_equal(.cv_date_range(row), "Jan 2018 - Dec 2022")
})

test_that(".cv_date_range() formats an ongoing role with present", {
    row <- data.frame(
        startMonth = "Mar", startYear = "2020",
        endMonth   = "present", endYear = "",
        stringsAsFactors = FALSE
    )
    expect_equal(.cv_date_range(row), "Mar 2020 - Present")
})

test_that(".cv_date_range() handles present case-insensitively", {
    row <- data.frame(
        startMonth = "Jan", startYear = "2021",
        endMonth   = "PRESENT", endYear = "",
        stringsAsFactors = FALSE
    )
    expect_equal(.cv_date_range(row), "Jan 2021 - Present")
})

test_that(".cv_date_range() returns start only when no end date", {
    row <- data.frame(
        startMonth = "Jun", startYear = "2019",
        endMonth   = "",    endYear   = "",
        stringsAsFactors = FALSE
    )
    expect_equal(.cv_date_range(row), "Jun 2019")
})

test_that(".cv_date_range() returns year only when no months supplied", {
    row <- data.frame(
        startMonth = "",    startYear = "2015",
        endMonth   = "",    endYear   = "2017",
        stringsAsFactors = FALSE
    )
    expect_equal(.cv_date_range(row), "2015 - 2017")
})

test_that(".cv_date_range() returns empty string when all fields blank", {
    row <- data.frame(
        startMonth = "", startYear = "",
        endMonth   = "", endYear   = "",
        stringsAsFactors = FALSE
    )
    expect_equal(.cv_date_range(row), "")
})

# .cv_year_range() --------------------------------------------------------

test_that(".cv_year_range() formats a year range", {
    row <- data.frame(startYear = "2010", endYear = "2014",
                      stringsAsFactors = FALSE)
    expect_equal(.cv_year_range(row), "2010 - 2014")
})

test_that(".cv_year_range() returns start year only when no end year", {
    row <- data.frame(startYear = "2020", endYear = "",
                      stringsAsFactors = FALSE)
    expect_equal(.cv_year_range(row), "2020")
})

test_that(".cv_year_range() returns empty string when both blank", {
    row <- data.frame(startYear = "", endYear = "",
                      stringsAsFactors = FALSE)
    expect_equal(.cv_year_range(row), "")
})
