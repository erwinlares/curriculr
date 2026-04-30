# Changelog

## curriculr 0.2.0

### Breaking changes

- [`create_cv()`](https://erwinlares.github.io/curriculr/reference/create_cv.md)
  has been redesigned. The old scaffolding behavior is replaced by two
  distinct modes triggered by whether `data` is supplied or not.

### New features

- [`create_cv()`](https://erwinlares.github.io/curriculr/reference/create_cv.md)
  **scaffold mode** (no arguments) copies the template workbook and
  placeholder image to the current working directory and prints
  step-by-step instructions. Does not render.
- [`create_cv()`](https://erwinlares.github.io/curriculr/reference/create_cv.md)
  **render mode** (with `data` and `photo`) reads the workbook, writes
  `CV.qmd`, and renders `CV.pdf` into the same directory as the
  workbook.
- Added `sections` sheet support. The workbook now controls which
  sections are rendered and in what order. Row order is render order.
  Deleting a row excludes a section. Adding a row for any sheet that
  follows the standard column schema renders it automatically.
- Added
  [`resolve_date_fun()`](https://erwinlares.github.io/curriculr/reference/resolve_date_fun.md)
  which maps `date_fun` token strings (`"date"`, `"year"`,
  `"month_year"`, `"year_only"`, `"none"`) to R date formatting
  functions.
- [`typst_escape()`](https://erwinlares.github.io/curriculr/reference/typst_escape.md),
  [`cv_section()`](https://erwinlares.github.io/curriculr/reference/cv_section.md),
  and
  [`resolve_date_fun()`](https://erwinlares.github.io/curriculr/reference/resolve_date_fun.md)
  are now exported.
- `inst/templates/CV.qmd` simplified – section rendering is now driven
  by iterating over `cv$sections`. The template uses sentinel strings
  that
  [`create_cv()`](https://erwinlares.github.io/curriculr/reference/create_cv.md)
  replaces with resolved paths at render time.

### Improvements

- [`read_cv_data()`](https://erwinlares.github.io/curriculr/reference/read_cv_data.md)
  skips the `readme` sheet entirely.
- [`read_cv_data()`](https://erwinlares.github.io/curriculr/reference/read_cv_data.md)
  validates the `sections` sheet column names on read.
- [`read_cv_data()`](https://erwinlares.github.io/curriculr/reference/read_cv_data.md)
  returns the `sections` sheet in row order without sorting.
- Non-ASCII characters in cli messages replaced with Unicode escapes for
  CRAN portability.

## curriculr 0.1.0

- Initial release.
- [`read_cv_data()`](https://erwinlares.github.io/curriculr/reference/read_cv_data.md)
  reads a curriculr-formatted Excel workbook into a named list of data
  frames.
- [`cv_render_section()`](https://erwinlares.github.io/curriculr/reference/cv_render_section.md)
  renders a CV section from a data frame into raw Typst output inside a
  Quarto document.
- [`create_cv()`](https://erwinlares.github.io/curriculr/reference/create_cv.md)
  scaffolded a new CV project with a template workbook, placeholder
  image, and ready-to-render Quarto document.
