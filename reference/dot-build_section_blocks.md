# Build Typst blocks for a CV section

Internal builder called by
[`cv_render_section()`](https://erwinlares.github.io/curriculr/reference/cv_render_section.md).
Iterates over each row of `data` and assembles a character vector of
Typst entry blocks. Separating the building step from the printing step
makes the output testable without capturing stdout.

## Usage

``` r
.build_section_blocks(
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

A character vector of Typst blocks, one element per row in `data`.
