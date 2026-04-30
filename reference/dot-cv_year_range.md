# Format a CV year range

Builds a year-only range from `startYear` and `endYear` columns. If
`endYear` is missing or empty, only the start year is returned.

## Usage

``` r
.cv_year_range(row)
```

## Arguments

- row:

  A one-row data frame representing one CV entry.

## Value

A character string containing a year or year range.
