# curriculr <img src="man/figures/logo.png" align="right" height="139" alt="curriculr package logo"/>

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

```
v Created cv-data-template.xlsx
v Created placeholder.png
i Next steps:
1. Open cv-data-template.xlsx and fill in the profile sheet.
2. Replace placeholder.png with your own profile photo.
3. Call create_cv(data = 'cv-data-template.xlsx', photo = 'your-photo.png')
```

### Step 2 — fill in the workbook

Open `cv-data-template.xlsx`. Start with the `profile` sheet:

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
| photo | Relative path to your profile image |

Then fill in the remaining sheets with your CV content. The `readme` sheet
inside the workbook explains the column schema and date entry conventions
in detail.

### Step 3 — render

```r
create_cv(
  data  = "cv-data-template.xlsx",
  photo = "your-photo.png"
)
```

This writes `CV.qmd` and `CV.pdf` next to your workbook. Open `CV.pdf` to
review the output. To update your CV, edit the workbook and call `create_cv()`
again with `overwrite = TRUE`.

To render without a profile photo, omit the `photo` argument. The header
will use a single-column layout with your name, contact line, and profile
statement centered on the page:

```r
create_cv(data = "cv-data-template.xlsx")
```

---

## Rendering a resume

When you want a shorter, focused version of your CV, use `variant = "resume"`.
curriculr will include only the rows you have checked in the
`include_in_resume` column of each section sheet:

```r
create_cv(
  data        = "cv-data-template.xlsx",
  photo       = "your-photo.png",
  variant     = "resume",
  output_file = "resume.pdf"
)
```

Check and uncheck rows directly in the workbook. No R code changes are needed
to switch between CV and resume variants.

---

## Customizing the rendered PDF

### Changing colors, fonts, and page layout

Open your workbook and edit the `theme` sheet. Each key maps to a visual
setting:

| key | what it controls |
|---|---|
| `font_family` | Body font (e.g. `Lato`, `Arial`) |
| `font_size` | Base font size (e.g. `8.8pt`) |
| `body_color` | Main text color (hex code) |
| `accent_color` | Section headings, dates, and rules (hex code) |
| `dark_color` | Entry titles and name in the header (hex code) |
| `papersize` | Page size (`us-letter` or `a4`) |
| `margin_x` | Left and right margins (e.g. `0.62in`) |
| `margin_y` | Top and bottom margins (e.g. `0.58in`) |

Re-render after editing the `theme` sheet with `overwrite = TRUE` to see
the changes.

### Changing section order or content

Edit the `sections` sheet in your workbook. Reorder rows to reorder sections.
Delete a row to remove a section.

### Adding a new section

Use `add_section()` to add a new sheet and register it in the `sections`
control sheet in one step:

```r
add_section(
  "cv-data-template.xlsx",
  section  = "patents",
  label    = "Patents",
  date_fun = "year_only"
)
```

The new sheet is pre-populated with the standard column spine. Open the
workbook, add your data, and re-render.

---

## Functions

### `create_cv()`

The main entry point. No arguments triggers scaffold mode. With `data`
triggers render mode.

```r
# Scaffold mode
create_cv()

# Render mode -- full CV with Font Awesome icons in the contact line
create_cv(
  data        = "cv-data.xlsx",
  photo       = "me.jpeg",
  output_file = "erwin-lares-cv.pdf"
)

# Render mode -- resume variant, plain text contact line
create_cv(
  data        = "cv-data.xlsx",
  photo       = "me.jpeg",
  variant     = "resume",
  use_icons   = "none",
  output_file = "erwin-lares-resume.pdf"
)
```

**Arguments:**

- `data` -- path to the workbook. `NULL` triggers scaffold mode.
- `photo` -- path to the profile image. `NULL` renders without a photo.
- `output_file` -- PDF filename. Defaults to `"CV.pdf"`.
- `overwrite` -- whether to overwrite existing files. Defaults to `FALSE`.
- `variant` -- `"cv"` (all rows) or `"resume"` (checked rows only).
- `use_icons` -- `"fontawesome"` (default) or `"none"`.

### `add_section()`

Adds a new sheet to an existing workbook and registers it in the `sections`
control sheet.

```r
add_section(
  "cv-data-template.xlsx",
  section   = "invited_talks",
  label     = "Invited Talks",
  date_fun  = "month_year",
  where_col = "where"
)
```

### `read_cv_data()`

Reads all sheets from the workbook into a named list. The `profile` and
`theme` sheets become named character vectors; section sheets become data
frames; the `sections` sheet is returned in row order.

```r
cv <- read_cv_data("cv-data-template.xlsx")
cv <- read_cv_data("cv-data-template.xlsx", variant = "resume")

cv$experience           # a data frame
cv$sections             # the sections control sheet
cv$profile[["email"]]   # a scalar string
cv$theme[["accent_color"]]  # a scalar string
```

### `cv_contact_line()`

Assembles the contact line from a profile vector. Useful when building custom
Quarto templates.

```r
cv_contact_line(cv$profile, use_icons = "fontawesome")
cv_contact_line(cv$profile, use_icons = "none")
```

### `cv_render_section()`

Iterates over a CV data frame and writes each row as a formatted Typst entry.
Called inside `CV.qmd` -- you will not normally call this directly.

### `typst_escape()`

Escapes Typst-sensitive characters in a string. Useful when building custom
Quarto templates.

### `cv_section()`

Returns a raw Typst string for a section heading. Useful when building custom
Quarto templates.

### `resolve_date_fun()`

Maps a `date_fun` token string to an R date formatting function. Useful when
building custom rendering logic outside the standard template.

---

## Workbook schema

Every section sheet shares a common column spine:

```
title | unit | startMonth | startYear | endMonth | endYear | where | detail | include_in_resume
```

`title` is always the primary entry label. `unit` is the secondary line.
`include_in_resume` is a boolean checkbox column -- check a row to include it
when rendering with `variant = "resume"`. Leave cells blank rather than typing
`NA`.

### Date conventions

| Situation | startMonth | startYear | endMonth | endYear |
|---|---|---|---|---|
| Ongoing role | Jan | 2018 | present | *(blank)* |
| Completed role | Mar | 2015 | Dec | 2022 |
| Single-year event | *(blank)* | 2021 | *(blank)* | *(blank)* |
| No date | *(blank)* | *(blank)* | *(blank)* | *(blank)* |

---

## Migration notes

Detailed notes on upgrading from previous versions are available in the
[changelog](https://erwinlares.github.io/curriculr/news/index.html). The
key changes by version:

**v0.2.0 to v0.3.0** -- `photo = NULL` now produces a no-photo layout
instead of falling back to a placeholder. Workbooks need an
`include_in_resume` column on every section sheet. An optional `theme` sheet
controls fonts, colors, and page layout. `openxlsx2` replaces `readxl`.

**v0.1.0 to v0.2.0** -- `create_cv()` gained scaffold mode (no arguments)
and render mode (with arguments). Workbooks need a `sections` sheet to
control which sections appear and in what order.

---

## Related packages

curriculr shares an author and design philosophy with three other R packages
focused on reproducible research workflows:

- [toolero](https://github.com/erwinlares/toolero) -- research project
  scaffolding and data wrangling utilities
- [containr](https://github.com/erwinlares/containr) -- containerization
  of R projects via Dockerfile generation
- [submitr](https://github.com/erwinlares/submitr) -- job submission to
  UW-Madison's CHTC from inside R

Together, toolero, containr, and submitr form the **From the Notebook to
the Cluster** pipeline. curriculr is independent but follows the same
conventions: small focused functions, data-driven workflows, and
Quarto as the publishing layer.

---

## Acknowledgements

curriculr was inspired by two prior projects:

- [vitae](https://pkg.mitchelloharawild.com/vitae/) by Mitchell O'Hara-Wild,
  Rob Hyndman, and contributors
- [Awesome CV](https://github.com/posquit0/Awesome-CV) by Byungjin Park
  (posquit0)

---

## Citation

If you use curriculr in your work, please cite it:

```r
citation("curriculr")
```

---

## License

MIT (c) Erwin Lares
