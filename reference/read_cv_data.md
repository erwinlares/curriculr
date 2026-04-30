# Read CV data from an Excel workbook

Reads all sheets from a curriculr-formatted Excel workbook and returns
them as a named list of data frames. Each sheet becomes one list
element, named after the sheet. The `profile` sheet is returned as a
named character vector for convenient scalar access.

## Usage

``` r
read_cv_data(path = "data/cv-data.xlsx")
```

## Arguments

- path:

  A character string. Path to the Excel workbook. Defaults to
  `"data/cv-data.xlsx"`.

## Value

A named list with one element per sheet in the workbook. The `profile`
element is a named character vector; all other elements are data frames.
Access sections as `cv$education`, `cv$experience`, etc. Access profile
fields as `cv$profile[["first_name"]]`.

## Details

Sheets containing a `startYear` column are sorted in descending order by
`startYear` so that the most recent entries appear first. Missing or
non-numeric values in `startYear` are placed last.

The workbook must follow the curriculr schema. Every section sheet
should contain a `title` column as the primary entry label. The
`profile` sheet must contain `field` and `value` columns.

This function requires the `readxl` package. It is listed as a
dependency of curriculr and will be installed automatically.

## Examples

``` r
if (FALSE) { # \dontrun{
cv <- read_cv_data("data/cv-data.xlsx")

# Access a section
cv$education
cv$experience

# Access profile fields
cv$profile[["first_name"]]
cv$profile[["email"]]
} # }
```
