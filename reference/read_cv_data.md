# Read CV data from an Excel workbook

Reads all sheets from a curriculr-formatted Excel workbook and returns
them as a named list of data frames. Each sheet becomes one list
element, named after the sheet. The `profile` sheet is returned as a
named character vector for convenient scalar access. The `theme` sheet
is returned as a named character vector keyed by the `key` column. The
`sections` sheet is returned as a data frame in the order the rows
appear in the workbook — row order controls section render order and
must not be sorted.

## Usage

``` r
read_cv_data(path = "data/cv-data.xlsx", variant = "cv")
```

## Arguments

- path:

  A character string. Path to the Excel workbook. Defaults to
  `"data/cv-data.xlsx"`.

- variant:

  A character string. Controls which rows are included from each section
  sheet. `"cv"` (the default) returns all rows. `"resume"` returns only
  rows where `include_in_resume` is `TRUE`. Sections that lack an
  `include_in_resume` column are included in full regardless of
  `variant`.

## Value

A named list with one element per sheet in the workbook. The `profile`
element is a named character vector; the `theme` element is a named
character vector (or `NULL` if the `theme` sheet is absent); all other
elements are data frames. The `include_in_resume` column is dropped from
returned data frames — it is used for filtering only and is not passed
to the rendering pipeline. Access sections as `cv$education`,
`cv$experience`, etc. Access profile fields as
`cv$profile[["first_name"]]`. Access theme values as
`cv$theme[["accent_color"]]`. Access the sections control sheet as
`cv$sections`.

## Details

Sheets containing a `startYear` column are sorted in descending order by
`startYear` so that the most recent entries appear first. The `profile`,
`theme`, and `sections` sheets are exempt from sorting.

The workbook must follow the curriculr schema. Every section sheet
should contain a `title` column as the primary entry label. The
`profile` sheet must contain `field` and `value` columns. The `sections`
sheet must contain at minimum `section` and `label` columns. The `theme`
sheet, if present, must contain `key` and `value` columns.

All cell values are read as character strings after import. Numeric
columns such as `startYear` and `endYear` are coerced to character so
that downstream rendering treats them uniformly. The `include_in_resume`
column is read as a logical before coercion and used for row filtering
when `variant = "resume"`.

Empty cells and cells containing the literal string `"NA"` are both
converted to `NA`.

If the `theme` sheet is absent, `cv$theme` is `NULL` and
[`create_cv()`](https://erwinlares.github.io/curriculr/reference/create_cv.md)
will fall back to built-in defaults.

## Examples

``` r
if (FALSE) { # \dontrun{
# Full CV — all rows from every section
cv <- read_cv_data("data/cv-data.xlsx")

# Resume variant — only rows marked include_in_resume
cv <- read_cv_data("data/cv-data.xlsx", variant = "resume")

# Access a section
cv$education
cv$experience

# Access the sections control sheet
cv$sections

# Access profile fields
cv$profile[["first_name"]]
cv$profile[["email"]]

# Access theme values
cv$theme[["accent_color"]]
cv$theme[["papersize"]]
} # }
```
