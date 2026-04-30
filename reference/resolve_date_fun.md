# Resolve a date_fun token to a function

Maps a string token from the `sections` sheet to the corresponding date
formatting function used by
[`cv_render_section()`](https://erwinlares.github.io/curriculr/reference/cv_render_section.md).
This allows date formatting behaviour to be controlled from the Excel
workbook rather than hardcoded in the Quarto template.

## Usage

``` r
resolve_date_fun(token)
```

## Arguments

- token:

  A character string. One of `"date"`, `"year"`, `"month_year"`,
  `"year_only"`, or `"none"`.

## Value

A function suitable for passing to the `date_fun` argument of
[`cv_render_section()`](https://erwinlares.github.io/curriculr/reference/cv_render_section.md),
or `NULL` when `token` is `"none"`.
