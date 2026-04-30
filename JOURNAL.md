---
title: "curriculr Development Journal"
date: 2026-04-29
---

## Session 1 — 2026-04-29

### What we set out to do

The goal of this session was to take an existing personal project — a
data-driven CV built with Quarto and Typst — and turn it into a bonafide R
package called **curriculr**. The original project was a working but
self-contained workflow: it rendered my CV from an Excel workbook but was
tightly coupled to my personal data, my file paths, and my design choices.
The package version needed to generalize all of that so anyone could use it.

We also used this session to make explicit a set of design decisions that
had been implicit in the original code, and to establish conventions that
will carry through the rest of the package development.

---

### Background: what the original project looked like

The original workflow consisted of three files:

```text
CV.qmd
R/read-cv-data.R
R/typst-cv-functions.R
```

`CV.qmd` was the main Quarto document. It sourced the two R helper scripts,
read the Excel workbook, and emitted raw Typst blocks for each CV section.
The document rendered to PDF using Quarto's Typst engine — no LaTeX, no
`vitae`, no custom `.cls` files. That part was already a significant
improvement over the original R Markdown version.

The Excel workbook (`data_driven_cv_data.xlsx`) held CV content organized
across eleven sheets: `admin_services`, `affiliations`, `certifications`,
`education`, `experience`, `grants_and_awards`, `invited_teaching`,
`presentations`, `projects`, `publications`, and `skills`.

The R helper scripts provided:

- `read_cv_data()` — read all sheets into a named list of data frames
- A family of Typst-building functions: `typst_escape()`, `cv_value()`,
  `cv_date_range()`, `cv_year_range()`, `cv_section()`, `cv_entry()`,
  `emit_entries()`, and `emit_simple_entries()`

The code was well-written and well-documented, but it had two problems that
needed solving before it could become a package: it contained hardcoded
personal information, and it had a schema inconsistency across sheets that
made the rendering functions more complex than necessary.

---

### Decision: the package name

We confirmed the name **curriculr**. A search of CRAN and GitHub found no
existing package with that name. The name is a play on *curriculum vitae*
with the R community's convention of dropping trailing vowels.

Branding assets — a hex sticker and a favicon — were already created and
placed in `man/figures/`.

---

### Decision: package identity and dependencies

curriculr is a **standalone package**, not part of toolero. It will depend
on toolero at runtime for one specific purpose: `create_cv()` will delegate
to toolero's `create_qmd()` for the Quarto scaffolding step. That makes
toolero and curriculr siblings — curriculr reuses one primitive from toolero
without being conceptually merged with it.

The runtime dependencies are: `toolero`, `readxl`, `cli`, `fs`, `glue`,
`purrr`. Development tools (`devtools`, `usethis`, `roxygen2`, `testthat`)
are tracked by `renv` but do not appear in `DESCRIPTION`.

The license is **MIT**, matching toolero. Apache 2 (used by containr) was
considered but rejected — the patent protections it adds over MIT are not
meaningful for a CV-rendering package.

---

### Schema changes: normalizing the Excel workbook

The original workbook had three columns that used section-specific names for
what was conceptually the same thing — the primary entry label:

| Sheet | Old column name | New column name |
|---|---|---|
| `education` | `degree` | `title` |
| `projects` | `accomplishment` | `title` |
| `skills` | `area` | `title` |

The `skills` sheet also renamed `skills` → `unit` to match the secondary
text convention used everywhere else.

The motivation was that `cv_render_section()` — the successor to
`emit_entries()` — should be able to treat every sheet identically. Having
section-specific column names forced special-case handling in `CV.qmd` and
made the rendering functions harder to reason about. With `title` normalized
across all sheets, the caller simply passes `title_col = "title"` every
time.

The `affiliations` sheet had its single column renamed from `unit` to
`title` for the same reason.

---

### Schema addition: the `profile` sheet

The original `CV.qmd` had all personal information hardcoded directly in a
raw Typst block:

```typst
#text(size: 27pt)[Erwin Lares]
#text[3544 N Cedar Ridge Ct, Janesville, WI 53545]
#text[erwin.lares@wisc.edu · erwinlares.com]
```

This was the most important thing to fix. A package cannot ship with one
person's name and address baked into a template.

The solution was to add a `profile` sheet to the workbook as the single
source of truth for all personal information. The sheet uses a simple
two-column schema:

| field | value |
|---|---|
| `first_name` | |
| `last_name` | |
| `job_title` | |
| `address` | |
| `email` | |
| `website` | |
| `github` | |
| `linkedin` | |
| `profile_statement` | |
| `photo` | |

The dividing line between what belongs in the workbook and what belongs in
YAML is: everything that answers *who is this person* lives in the
spreadsheet; everything that answers *how should this render* (paper size,
margins, params) lives in the YAML front matter.

`read_cv_data()` handles the `profile` sheet specially — it converts the
two-column data frame into a named character vector so that template code
can write `cv$profile[["first_name"]]` rather than a clunky row-filter
expression.

---

### Schema addition: the `readme` sheet

A `readme` sheet was added to both workbooks — the personal workbook and the
Frank Palmer example workbook — to make the schema self-documenting. The
sheet explains:

- The general rules for data entry
- A column-by-column reference table
- A date entry quick-reference covering all combinations of ongoing,
  completed, point-in-time, and undated entries
- A profile sheet field guide

The sheet was generated programmatically using `openpyxl` in Python, with
UW red header rows, alternating row fills, wrapped text, and frozen top
rows. The top three rows (title, intro paragraph, spacer) are frozen so
they remain visible while scrolling through the reference tables.

---

### Decision: `emit_entries()` and `emit_simple_entries()` → `cv_render_section()`

The original code had two iterator functions:

- `emit_entries()` — for sections with dates, locations, and detail
- `emit_simple_entries()` — for sections without dates or locations

The distinction between them was false. A "simple" entry was just a regular
entry with fewer fields populated — not a different kind of thing. Having
two functions implied a meaningful difference that did not exist.

Both were collapsed into a single function: `cv_render_section()`. Optional
columns default to `NULL` and are simply omitted from the rendered output.
`date_fun` defaults to `.cv_date_range()` for dated sections and is passed
`NULL` for undated sections like skills and affiliations. The caller controls
simplicity through arguments, not through which function they call.

---

### Decision: separating building from printing

In the original code, `emit_entries()` both constructed the Typst strings
*and* called `cat()` to write them to the document. This made the functions
untestable in isolation — you could not check their output without capturing
stdout.

The package version separates these two responsibilities:

- `.build_section_blocks()` — internal builder, iterates over rows, returns
  a character vector of Typst blocks, one per row. Fully testable.
- `cv_render_section()` — thin public wrapper, calls `.build_section_blocks()`
  then passes the result to `cat()`. This is the function that lives inside
  a Quarto chunk with `results = 'asis'`.

The `results = 'asis'` chunk option tells Quarto to pass R output through
raw into the document without any formatting wrapper. `cat()` writes
directly to that output stream. The builder knows nothing about `cat()` —
it just returns strings.

---

### Decision: naming conventions

Two conventions were established and applied consistently across all source
files:

**Function names:** internal functions carry a `.` prefix. Exported
functions do not.

| Visibility | Example |
|---|---|
| Internal | `.cv_value()`, `.typst_escape()`, `.cv_date_range()` |
| Internal | `.cv_year_range()`, `.cv_section()`, `.cv_entry()` |
| Internal | `.build_section_blocks()` |
| Exported | `cv_render_section()`, `read_cv_data()` |

**File names:** source files use `kebab-case.R`. Function names inside
files use `snake_case`. This matches the convention already established in
toolero and containr.

---

### Decision: `sprintf()` over `glue::glue()` for Typst strings

The Typst layout strings contain many literal `{` and `}` characters, which
are glue's interpolation delimiters. Using glue would require escaping every
literal brace as `{{` and `}}`, making the strings harder to read and
maintain. `sprintf()` uses `%s` placeholders that do not conflict with
Typst syntax at all, so it was kept for the layout functions.

glue remains available for other parts of the package — particularly
`create_cv()` — where it is genuinely more readable.

---

### Decision: `create_cv()` will delegate to `toolero::create_qmd()`

Two models were considered for how `create_cv()` should relate to
`create_qmd()` in toolero:

- **Model A:** `create_cv()` calls `create_qmd()` internally, passing a
  CV-specific template and YAML structure.
- **Model B:** extract a shared internal helper that both functions call.

Model A was chosen. It keeps the dependency explicit, avoids duplicating
scaffolding logic, and naturally positions toolero as the foundational layer.
`create_cv()` adds CV-specific scaffolding on top — the workbook, the photo
placeholder, CV assets — then delegates document creation to toolero.

---

### Source files written this session

Six R source files were written and loaded cleanly:

```text
R/curriculr-package.R    — package sentinel
R/typst-helpers.R        — %||%, .cv_value(), .typst_escape()
R/typst-dates.R          — .cv_date_range(), .cv_year_range()
R/typst-layout.R         — .cv_section(), .cv_entry()
R/typst-render.R         — cv_render_section(), .build_section_blocks()
R/read-cv-data.R         — read_cv_data()
```

One file remains: `R/create-cv.R`.

---

### Package scaffold commands run

```r
usethis::create_package("~/path/to/curriculr")
usethis::use_mit_license()
usethis::use_readme_md()
usethis::use_news_md()
usethis::use_testthat()
usethis::use_git()
usethis::use_package("toolero")
usethis::use_package("readxl")
usethis::use_package("cli")
usethis::use_package("fs")
usethis::use_package("glue")
usethis::use_package("purrr")
fs::dir_create("inst/extdata/img")
fs::dir_create("inst/templates")
fs::dir_create("man/figures")
renv::init()       # explicit mode — DESCRIPTION-driven
renv::install("devtools")
renv::snapshot()
```

---

### What remains for the next session

```text
R/create-cv.R               — the last source file
inst/templates/CV.qmd       — generalized template, no hardcoded personal info
tests/testthat/             — unit tests for builders and helpers
DESCRIPTION                 — finalize metadata
README.md                   — package documentation
NEWS.md                     — changelog
devtools::check()           — clean run
CRAN submission prep
```
