# Create a Typst CV section heading

Generates a raw Typst block for a CV section heading. The first letter
of the section title is styled with the CV accent color. The heading is
followed by a horizontal rule that fills the remaining line width.

## Usage

``` r
.cv_section(title)
```

## Arguments

- title:

  A character string. The section title to display, e.g. `"Education"`
  or `"Publications"`.

## Value

A character string of raw Typst markup.
