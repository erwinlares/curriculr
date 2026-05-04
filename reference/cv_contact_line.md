# Build the contact line for the CV header

Assembles a Typst-formatted contact line from a profile vector. When
`use_icons = "fontawesome"`, known contact fields are rendered with
their Font Awesome icon via the Typst `@preview/fontawesome` package.
Fields with no icon equivalent fall back to plain text with a warning.
When `use_icons = "none"`, all fields render as plain text.

## Usage

``` r
cv_contact_line(profile, use_icons = "fontawesome")
```

## Arguments

- profile:

  A named character vector as returned by the `profile` element of
  [`read_cv_data()`](https://erwinlares.github.io/curriculr/reference/read_cv_data.md).

- use_icons:

  A character string. `"fontawesome"` (the default) renders contact
  fields with Font Awesome icons. `"none"` renders plain text.

## Value

A character string of raw Typst markup for the contact line.

## Details

This function is called inside `CV.qmd` and is exported so that users
building custom Quarto templates can call it directly.
