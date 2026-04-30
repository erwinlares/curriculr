# Extract one value from a CV data row

Safely extracts a named value from a one-row data frame. Returns a
default value if the column does not exist or if the value is missing.

## Usage

``` r
.cv_value(row, name, default = "")
```

## Arguments

- row:

  A one-row data frame representing one CV entry.

- name:

  A character string. Name of the column to extract.

- default:

  A character string. Fallback value when the column or value is absent.
  Defaults to `""`.

## Value

A character string.
