# Resolve theme values, filling gaps with defaults

Merges the user-supplied theme vector from the workbook with the
built-in defaults. Any key absent from the workbook theme is filled from
defaults, so partial theme sheets are supported.

## Usage

``` r
.resolve_theme(theme)
```

## Arguments

- theme:

  A named character vector as returned by `cv$theme`, or `NULL`.

## Value

A named character vector with all twelve theme keys present.
