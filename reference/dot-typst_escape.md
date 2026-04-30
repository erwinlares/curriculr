# Escape text for safe use in Typst markup

Converts an input value to a Typst-safe character string. Removes simple
HTML line break tags, collapses repeated whitespace, escapes Typst
special characters, and trims leading and trailing whitespace.

## Usage

``` r
.typst_escape(x)
```

## Arguments

- x:

  A value or vector to escape.

## Value

A character vector with Typst-sensitive characters escaped.

## Details

CV content comes from Excel and may contain characters that Typst treats
as markup: `#`, `$`, `%`, `&`, `~`, `_`, `^`, `{`, `}`, `[`, `]`, or
`@`. The `@` character is included because Typst may interpret email
addresses as references to labels.
