# Build the Quarto YAML format block from theme values

Constructs the `format: typst:` YAML block that replaces the
`%%CURRICULR_FORMAT%%` sentinel in `CV.qmd`.

## Usage

``` r
.build_format_block(theme)
```

## Arguments

- theme:

  A fully resolved named character vector as returned by
  [`.resolve_theme()`](https://erwinlares.github.io/curriculr/reference/dot-resolve_theme.md).

## Value

A character string of YAML.
