# Render a CV section from a data frame

Iterates over a CV data frame and writes each row as a Typst CV entry by
calling
[`.cv_entry()`](https://erwinlares.github.io/curriculr/reference/dot-cv_entry.md)
for each row and passing the result to
[`base::cat()`](https://rdrr.io/r/base/cat.html).

## Usage

``` r
cv_render_section(
  data,
  title_col,
  org_col = NULL,
  detail_col = NULL,
  date_fun = .cv_date_range,
  where_col = "where"
)
```

## Arguments

- data:

  A data frame containing CV entries. Typically one element of the list
  returned by read_cv_data(), e.g. `cv$experience`.

- title_col:

  A character string. Name of the column to use as the entry title.
  Required.

- org_col:

  A character string or `NULL`. Name of the column to use as the
  organization or secondary text. Defaults to `NULL`.

- detail_col:

  A character string or `NULL`. Name of the column to use as additional
  detail. Defaults to `NULL`.

- date_fun:

  A function or `NULL`. Called with each row to produce the date string.
  Defaults to
  [`.cv_date_range()`](https://erwinlares.github.io/curriculr/reference/dot-cv_date_range.md).
  Pass `NULL` for sections without dates.

- where_col:

  A character string or `NULL`. Name of the column to use as the
  location. Defaults to `"where"`. Pass `NULL` to omit location.

## Value

Invisibly returns `NULL`. Called for its side effect of writing Typst
blocks to the Quarto document output stream.

## Details

This function is intended to be called inside a Quarto document chunk
with `results = 'asis'`. The [`cat()`](https://rdrr.io/r/base/cat.html)
call writes raw Typst blocks directly into the document output stream.
Nothing is returned — the function is called entirely for its side
effect.

For sections that use dates, pass one of
[`.cv_date_range()`](https://erwinlares.github.io/curriculr/reference/dot-cv_date_range.md)
or
[`.cv_year_range()`](https://erwinlares.github.io/curriculr/reference/dot-cv_year_range.md)
as `date_fun`. For sections where dates are not relevant (skills,
affiliations), pass `date_fun = NULL`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Inside a Quarto chunk with results = 'asis':

# Full entry with date range and location
cat(.cv_section("Experience"))
cv_render_section(cv$experience,
                  title_col  = "title",
                  org_col    = "unit",
                  detail_col = "detail")

# Year-only dates
cat(.cv_section("Education"))
cv_render_section(cv$education,
                  title_col  = "title",
                  org_col    = "institution",
                  detail_col = "detail",
                  date_fun   = .cv_year_range)

# No dates, no location
cat(.cv_section("Skills"))
cv_render_section(cv$skills,
                  title_col = "title",
                  org_col   = "unit",
                  date_fun  = NULL,
                  where_col = NULL)

# Custom inline date function
cat(.cv_section("Presentations"))
cv_render_section(cv$presentations,
                  title_col = "unit",
                  org_col   = "title",
                  date_fun  = function(row) {
                    trimws(paste(.cv_value(row, "startMonth"),
                                 .cv_value(row, "startYear")))
                  })
} # }
```
