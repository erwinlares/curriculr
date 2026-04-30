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

Install the development version from GitHub:

```r
# install.packages("pak")
pak::pak("erwinlares/curriculr")
```

## Requirements

- R (>= 4.2.0)
- [Quarto](https://quarto.org) 1.4 or later (ships with Typst support built in)

---

## For new users

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

---

## For existing users updating from v0.1.0

v0.2.0 changes how `create_cv()` works and adds a `sections` sheet to the
workbook schema. Here is what you need to know.

**`create_cv()` now has two modes:**

- **Scaffold mode** (no arguments) — copies template files to your current
  directory. Use this once to get started or to reset.
- **Render mode** (with arguments) — reads your workbook and renders the PDF.
  Use this every time you update your CV.

**Your workbook needs a `sections` sheet.** This sheet controls which sections
appear in the rendered PDF and in what order. Add it manually or copy it from
the updated template workbook. The schema is:

| section | label | title_col | org_col | detail_col | date_fun | where_col |
|---|---|---|---|---|---|---|
| education | Education | title | institution | detail | year | where |
| experience | Experience | title | unit | detail | date | where |

Row order is render order. Delete a row to exclude a section. Add a row for
any sheet that follows the standard column schema and it will render
automatically without any R code changes.

The `date_fun` column accepts five tokens:

| token | produces |
|---|---|
| `date` | Jan 2018 - Dec 2022 |
| `year` | 2018 - 2022 |
| `month_year` | Jan 2018 |
| `year_only` | 2021 |
| `none` | *(no date)* |

---

## Customizing the rendered PDF

### Changing section order or content

Edit the `sections` sheet in your workbook. Reorder rows to reorder sections.
Delete a row to remove a section. Add a row for a new section.

### Changing colors and fonts

Open `CV.qmd` and find the `{=typst}` style block near the top:

```typst
#set text(font: "Lato", size: 8.8pt, fill: rgb("#3f3f3f"))
#let accent   = rgb("#c5050c")
#let dark     = rgb("#303030")
#let bodygray = rgb("#555555")
```

Change `accent` to change the section heading and date color. Change `font`
to use a different typeface. Change `size` to adjust the base text size.

### Changing page margins

In the YAML front matter of `CV.qmd`:

```yaml
format:
  typst:
    papersize: us-letter
    margin:
      x: 0.62in
      y: 0.58in
```

### Regenerating CV.qmd after changes

```r
create_cv(
  data      = "cv-data-template.xlsx",
  photo     = "your-photo.png",
  overwrite = TRUE
)
```

---

## Functions

### `create_cv()`

The main entry point. No arguments triggers scaffold mode. With `data` and
`photo` triggers render mode.

```r
# Scaffold mode
create_cv()

# Render mode
create_cv(
  data        = "~/my_cv/cv-data.xlsx",
  photo       = "~/my_cv/me.jpeg",
  output_file = "erwin-lares-cv.pdf"
)
```

### `read_cv_data()`

Reads all sheets from the workbook into a named list. The `profile` sheet
becomes a named character vector; section sheets become data frames; the
`sections` sheet is returned in row order.

```r
cv <- read_cv_data("cv-data-template.xlsx")

cv$experience           # a data frame
cv$sections             # the sections control sheet
cv$profile[["email"]]  # a scalar string
```

### `cv_render_section()`

Iterates over a CV data frame and writes each row as a formatted Typst entry.
Called inside `CV.qmd` — you will not normally call this directly.

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
title | unit | startMonth | startYear | endMonth | endYear | where | detail
```

`title` is always the primary entry label. `unit` is the secondary line.
Leave cells blank rather than typing `NA`.

### Date conventions

| Situation | startMonth | startYear | endMonth | endYear |
|---|---|---|---|---|
| Ongoing role | Jan | 2018 | present | *(blank)* |
| Completed role | Mar | 2015 | Dec | 2022 |
| Single-year event | *(blank)* | 2021 | *(blank)* | *(blank)* |
| No date | *(blank)* | *(blank)* | *(blank)* | *(blank)* |

---

## Roadmap

Planned for v0.3.0: CV variant support (short resume, year filtering),
HTML output, integration tests, and AwesomeFont support. 

---

## Related packages

curriculr is one of three sibling packages:

- [toolero](https://github.com/erwinlares/toolero) — research workflow toolkit
- [containr](https://github.com/erwinlares/containr) — Docker containerization
- **curriculr** — data-driven CV generation with Quarto and Typst

---

## Acknowledgements

curriculr was inspired by two prior projects:

- [vitae](https://pkg.mitchelloharawild.com/vitae/) by Mitchell O'Hara-Wild,
  Rob Hyndman, and contributors
- [Awesome CV](https://github.com/posquit0/Awesome-CV) by Byungjin Park
  (posquit0)

---

## License

MIT (c) Erwin Lares
