# Format a CV date range from month and year columns

Builds a human-readable date range from a CV data row using the columns
`startMonth`, `startYear`, `endMonth`, and `endYear`. Supports ongoing
entries by treating an `endMonth` value of `"present"`
(case-insensitive) as `"Present"`.

## Usage

``` r
.cv_date_range(row)
```

## Arguments

- row:

  A one-row data frame representing one CV entry.

## Value

A character string containing a formatted date range.
