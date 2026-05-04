# Build the Typst style block from theme values

Constructs the raw `{=typst}` code block that replaces the
`%%CURRICULR_THEME%%` sentinel in `CV.qmd`. Optionally prepends the Font
Awesome package import when icons are in use.

## Usage

``` r
.build_typst_theme_block(theme, use_icons = "fontawesome")
```

## Arguments

- theme:

  A fully resolved named character vector as returned by
  [`.resolve_theme()`](https://erwinlares.github.io/curriculr/reference/dot-resolve_theme.md).

- use_icons:

  A character string. `"fontawesome"` prepends the FA import line.
  `"none"` omits it.

## Value

A character string of raw Typst markup wrapped in a Quarto `{=typst}`
code fence.
