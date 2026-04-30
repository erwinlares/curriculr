# curriculr <img src="man/figures/hex-sticker.png" align="right" height="139" alt="curriculr package logo"/>

<!-- badges: start -->
[![R-CMD-check](https://github.com/erwinlares/curriculr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/erwinlares/curriculr/actions/workflows/R-CMD-check.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/curriculr)](https://CRAN.R-project.org/package=curriculr)
<!-- badges: end -->

`curriculr` is an R package for producing data-driven curriculum vitae
documents. You maintain your CV content in an Excel workbook. curriculr reads
it, converts it into Typst layout blocks, and renders a polished PDF via
Quarto's Typst engine. No LaTeX. No vitae. No custom `.cls` files.

## Installation

You can install the development version from GitHub:

```r
# install.packages("pak")
pak::pak("erwinlares/curriculr")
```

## Requirements

- R (>= 4.2.0)
- [Quarto](https://quarto.org) 1.4 or later (ships with Typst support built in)

## Getting started

### 1. Scaffold a new CV project

```r
library(curriculr)

create_cv(path = "~/my-cv")
```

This creates the following structure:

```text
my-cv/
├── CV.qmd
├── data/
│   └── cv-data-template.xlsx
└── img/
    └── placeholder.png
```

### 2. Fill in the workbook

Open `data/cv-data-template.xlsx`. Start with the `profile` sheet — it
controls the CV header:

| field | value |
|---|---|
| first_name | Your first name |
| last_name | Your last name |
| job_title | Your current title |
| address | Your mailing address |
| email | your@email.edu |
| website | yourwebsite.com |
| github | your-github-username |
| linkedin | in/your-linkedin |
| profile_statement | One or two sentence professional summary |
| photo | img/your-photo.png |

Then fill in the remaining sheets with your CV content. Each sheet
corresponds to one section: `education`, `experience`, `projects`,
`publications`, `presentations`, `invited_teaching`, `grants_and_awards`,
`certifications`, `admin_services`, `skills`, and `affiliations`.

The `readme` sheet inside the workbook explains the column schema and date
entry conventions in detail.

### 3. Render

```bash
quarto render CV.qmd
```

The output is `CV.pdf`. To update your CV, edit the workbook and re-render.
In most cases you will never need to touch `CV.qmd`.

## Functions

### `create_cv()`

Scaffolds a new CV project at the given path. Copies the template workbook,
a placeholder profile image, and a ready-to-render `CV.qmd`.

```r
create_cv(path = "~/my-cv")
create_cv(path = "~/my-cv", filename = "academic-cv.qmd", overwrite = TRUE)
```

### `read_cv_data()`

Reads all sheets from the workbook into a named list. Section sheets become
data frames; the `profile` sheet becomes a named character vector. Dated
sheets are sorted in descending order automatically so the most recent
entries appear first.

```r
cv <- read_cv_data("data/cv-data-template.xlsx")

cv$experience           # a data frame
cv$profile[["email"]]  # a scalar string
```

### `cv_render_section()`

The main rendering function. Iterates over a CV data frame and writes each
row as a formatted Typst entry. Called inside `CV.qmd` — you will not
normally call this directly.

```r
#| results: asis
cv_render_section(
  cv$experience,
  title_col  = "title",
  org_col    = "unit",
  detail_col = "detail"
)
```

## Workbook schema

Every section sheet shares a common column spine:

```
title | unit | startMonth | startYear | endMonth | endYear | where | detail
```


`title` is always the primary entry label. `unit` is the secondary line:
employer, institution, publisher, or venue. Leave cells blank rather than
typing `NA`.

### Date conventions

| Situation | startMonth | startYear | endMonth | endYear |
|---|---|---|---|---|
| Ongoing role | Jan | 2018 | present | *(blank)* |
| Completed role | Mar | 2015 | Dec | 2022 |
| Single-year event | *(blank)* | 2021 | *(blank)* | *(blank)* |
| No date | *(blank)* | *(blank)* | *(blank)* | *(blank)* |

## Roadmap

The `CV.qmd` template includes YAML params for future variant support:

```yaml
params:
  resume: false
  years: 5
  npresentations: 10
```

Planned for v0.2.0: filtering logic for short resume variants, rolling year
windows, and section-level inclusion flags in the workbook.

## Related packages

curriculr is one of three sibling packages:

- [toolero](https://github.com/erwinlares/toolero) — a toolkit for research
  workflows: project initialization, Quarto templates, data reading, and
  execution context detection.
- [containr](https://github.com/erwinlares/containr) — tools for
  containerizing R projects with Docker and HTCondor.
- **curriculr** — data-driven CV generation with Quarto and Typst.

## Known limitations

- Font rendering may differ across operating systems if Lato is not installed
  locally.
- Page breaks may need manual tuning for longer CVs.
- The Typst color palette and font sizes are not yet user-configurable without
  editing `CV.qmd` directly.
  
## Acknowledgements

curriculr was inspired by two prior projects:

- [vitae](https://pkg.mitchelloharawild.com/vitae/) by Mitchell O'Hara-Wild,
  Rob Hyndman, and contributors — an R package for producing CV documents
  from R Markdown templates.
- [Awesome CV](https://github.com/posquit0/Awesome-CV) by Byungjin Park
  (posquit0) — the LaTeX CV template that shaped the visual design curriculr
  attempts to preserve in Typst.

## License

MIT © Erwin Lares

