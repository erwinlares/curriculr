# curriculr <img src="man/figures/hex-sticker.png" align="right" height="139" alt="curriculr package logo"/>

<!-- badges: start -->
[![R-CMD-check](https://github.com/erwinlares/curriculr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/erwinlares/curriculr/actions/workflows/R-CMD-check.yaml)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.19930400.svg)](https://doi.org/10.5281/zenodo.19930400)
[![CRAN status](https://www.r-pkg.org/badges/version/curriculr)](https://CRAN.R-project.org/package=curriculr)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/curriculr)](https://cran.r-project.org/package=curriculr)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![Codecov test coverage](https://codecov.io/gh/erwinlares/curriculr/graph/badge.svg)](https://app.codecov.io/gh/erwinlares/curriculr)
[![r-universe](https://erwinlares.r-universe.dev/badges/curriculr)](https://erwinlares.r-universe.dev/curriculr)
<!-- badges: end -->

`curriculr` is an R package for producing data-driven curriculum vitae
documents. You maintain your CV content in an Excel workbook. curriculr reads
it, converts it into Typst layout blocks, and renders a polished PDF via
Quarto's Typst engine. No LaTeX. No vitae. No custom `.cls` files.

## Installation

You can install curriculr from CRAN:

```r
install.packages("curriculr")
```

For the latest development features, install from GitHub:

```r
# install.packages("pak")
pak::pak("erwinlares/curriculr")
```

## Requirements

- R (>= 4.2.0)
- [Quarto](https://quarto.org) 1.4 or later (ships with Typst support built in)

---

## Getting started

### Step 1 — scaffold your project

Call `create_cv()` with no arguments. This copies the template workbook and a
placeholder profile image into your current working directory:

```r
library(curriculr)
create_cv()
```

You will see:
