# Add a new section to a curriculr workbook

Adds a new sheet to an existing curriculr-formatted Excel workbook and
registers it in the `sections` control sheet. The new sheet is
pre-populated with the standard column spine so the user can start
entering data immediately without worrying about column names.

## Usage

``` r
add_section(
  workbook,
  section,
  label = section,
  date_fun = "year_only",
  title_col = "title",
  org_col = "unit",
  detail_col = NA,
  where_col = "where",
  overwrite = FALSE
)
```

## Arguments

- workbook:

  A character string. Path to an existing curriculr Excel workbook.

- section:

  A character string. Internal name of the new section. Must be a valid
  Excel sheet name (no more than 31 characters, no special characters).
  This name must match the sheet name exactly when referenced elsewhere
  in the workbook or in `cap` arguments to
  [`create_cv()`](https://erwinlares.github.io/curriculr/reference/create_cv.md).

- label:

  A character string. Display label shown as the section heading in the
  rendered CV. Defaults to `section`, which works when the section name
  is already human-readable. Supply a different value when the internal
  name and the display label differ, e.g. `section = "invited_talks"`,
  `label = "Invited Talks"`.

- date_fun:

  A character string. Token controlling date formatting for this
  section. One of `"date"`, `"year"`, `"month_year"`, `"year_only"`, or
  `"none"`. Defaults to `"year_only"`. See
  [`resolve_date_fun()`](https://erwinlares.github.io/curriculr/reference/resolve_date_fun.md)
  for token definitions.

- title_col:

  A character string. Name of the column used as the primary entry label
  in the rendered CV. Defaults to `"title"`.

- org_col:

  A character string or `NA`. Name of the column used as the secondary
  organization or venue line. Defaults to `"unit"`. Pass `NA` to omit
  the organization line for this section.

- detail_col:

  A character string or `NA`. Name of the column used as the detail
  line. Defaults to `NA` (omitted). Pass a column name to include a
  detail line.

- where_col:

  A character string or `NA`. Name of the column used as the location.
  Defaults to `"where"`. Pass `NA` to omit location for this section.

- overwrite:

  A logical. Whether to overwrite an existing sheet of the same name.
  Defaults to `FALSE`. When `FALSE`, an existing sheet causes an
  informative error. This is a destructive operation — use with care.

## Value

Invisibly returns `workbook`. Called primarily for its side effect of
modifying the workbook on disk.

## Details

`add_section()` performs the following steps:

1.  Validates that `workbook` exists and that `section` is not already
    present (unless `overwrite = TRUE`).

2.  Appends a new sheet named `section` with the standard column spine:
    `title | unit | startMonth | startYear | endMonth | endYear | where | detail | include_in_resume`.

3.  Appends a new row to the `sections` sheet registering the new
    section with the supplied metadata. When `overwrite = TRUE`, any
    existing row for this section is replaced.

4.  Writes the modified workbook back to `workbook` in place.

The workbook is modified in place. There is no undo. Consider keeping a
backup copy before calling `add_section()` if the workbook contains data
you cannot reconstruct.

Control sheets (`profile`, `sections`, `theme`, `readme`) cannot be used
as section names.

## Examples

``` r
if (FALSE) { # \dontrun{
# Add a section with defaults
add_section("cv-data.xlsx", section = "patents")

# Add a section with a display label that differs from the sheet name
add_section("cv-data.xlsx",
            section  = "invited_talks",
            label    = "Invited Talks",
            date_fun = "month_year")

# Add a section without an organization or location line
add_section("cv-data.xlsx",
            section   = "languages",
            label     = "Languages",
            date_fun  = "none",
            org_col   = NA,
            where_col = NA)
} # }
```
