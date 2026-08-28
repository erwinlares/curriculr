# curriculr ![curriculr package logo](reference/figures/hex-sticker.png)

`curriculr` is an R package for producing data-driven curriculum vitae
documents. You maintain your CV content in an Excel workbook. curriculr
reads it, converts it into Typst layout blocks, and renders a polished
PDF via Quarto’s Typst engine. No LaTeX. No vitae. No custom `.cls`
files.

## Installation

You can install curriculr from CRAN:

``` r

install.packages("curriculr")
```

For the latest development features, install from GitHub:

``` r

# install.packages("pak")
pak::pak("erwinlares/curriculr")
```

## Requirements

- R (\>= 4.2.0)
- [Quarto](https://quarto.org) 1.4 or later (ships with Typst support
  built in)

------------------------------------------------------------------------

## Getting started

### Step 1 — scaffold your project

Call
[`create_cv()`](https://erwinlares.github.io/curriculr/reference/create_cv.md)
with no arguments. This copies the template workbook and a placeholder
profile image into your current working directory:

``` r

library(curriculr)
create_cv()
```

You will see:
