# curriculr 0.2.0

## Breaking changes

* `create_cv()` has been redesigned. The old scaffolding behavior is replaced
  by two distinct modes triggered by whether `data` is supplied or not.

## New features

* `create_cv()` **scaffold mode** (no arguments) copies the template workbook
  and placeholder image to the current working directory and prints
  step-by-step instructions. Does not render.
* `create_cv()` **render mode** (with `data` and `photo`) reads the workbook,
  writes `CV.qmd`, and renders `CV.pdf` into the same directory as the
  workbook.
* Added `sections` sheet support. The workbook now controls which sections are
  rendered and in what order. Row order is render order. Deleting a row
  excludes a section. Adding a row for any sheet that follows the standard
  column schema renders it automatically.
* Added `resolve_date_fun()` which maps `date_fun` token strings (`"date"`,
  `"year"`, `"month_year"`, `"year_only"`, `"none"`) to R date formatting
  functions.
* `typst_escape()`, `cv_section()`, and `resolve_date_fun()` are now exported.
* `inst/templates/CV.qmd` simplified -- section rendering is now driven by
  iterating over `cv$sections`. The template uses sentinel strings that
  `create_cv()` replaces with resolved paths at render time.

## Improvements

* `read_cv_data()` skips the `readme` sheet entirely.
* `read_cv_data()` validates the `sections` sheet column names on read.
* `read_cv_data()` returns the `sections` sheet in row order without sorting.
* Non-ASCII characters in cli messages replaced with Unicode escapes for CRAN
  portability.

# curriculr 0.1.0

* Initial release.
* `read_cv_data()` reads a curriculr-formatted Excel workbook into a named
  list of data frames.
* `cv_render_section()` renders a CV section from a data frame into raw
  Typst output inside a Quarto document.
* `create_cv()` scaffolded a new CV project with a template workbook,
  placeholder image, and ready-to-render Quarto document.
