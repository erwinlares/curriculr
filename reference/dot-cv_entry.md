# Create a Typst CV entry

Generates a raw Typst block for one CV entry. The entry is laid out as a
two-column grid: the left column holds the title and metadata; the right
column holds the date and location, right-aligned in the accent color.

## Usage

``` r
.cv_entry(title = "", organization = "", detail = "", when = "", where = "")
```

## Arguments

- title:

  A character string. The main entry label: degree, job title, project
  name, publication title, skill area, etc.

- organization:

  A character string. The secondary line: employer, institution,
  publisher, or venue. Defaults to `""`.

- detail:

  A character string. Additional context shown after the organization
  line. Defaults to `""`.

- when:

  A character string. The date or date range, typically produced by
  [`.cv_date_range()`](https://erwinlares.github.io/curriculr/reference/dot-cv_date_range.md)
  or
  [`.cv_year_range()`](https://erwinlares.github.io/curriculr/reference/dot-cv_year_range.md).
  Defaults to `""`.

- where:

  A character string. Location associated with the entry. Defaults to
  `""`.

## Value

A character string of raw Typst markup.

## Details

All arguments are optional except `title`. Empty strings are handled
gracefully — missing metadata, dates, or locations are simply omitted
from the rendered output rather than leaving blank space.
