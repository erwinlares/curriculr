# curriculr 0.3.0

## Breaking changes

* `read_cv_data()` now requires the `openxlsx2` package instead of `readxl`.
  Remove `readxl` and add `openxlsx2` to any explicit dependencies in your
  own projects that call `read_cv_data()` directly.

* `create_cv()` no longer falls back to a bundled placeholder image when
  `photo = NULL` in render mode. Omitting `photo` now produces a
  single-column header layout with no image. Supply a path explicitly to
  restore the two-column layout with a profile photo.

## New features

* **Resume variant.** `create_cv()` and `read_cv_data()` gain a `variant`
  argument (`"cv"` or `"resume"`). When `variant = "resume"`, only rows where
  `include_in_resume` is checked in the workbook are included in the rendered
  output. Every section sheet now carries an `include_in_resume` column for
  row-level control.

* **Font Awesome icons.** `create_cv()` gains a `use_icons` argument
  (`"fontawesome"` or `"none"`). When `"fontawesome"` (the default), contact
  fields in the CV header are rendered with Font Awesome icons via the Typst
  `@preview/fontawesome` package. Fields with no icon equivalent fall back to
  plain text with a warning. The new exported function `cv_contact_line()`
  assembles the contact line and can be called directly in custom templates.

* **Workbook-controlled theming.** A new `theme` sheet in the workbook
  controls fonts, colors, and page layout. Keys map directly to the Typst
  style block and the Quarto `format: typst:` YAML block, both of which are
  now injected by `create_cv()` via sentinel substitution. If the `theme`
  sheet is absent, built-in defaults are used and individual missing keys are
  filled from defaults, so partial theme sheets are supported.

* **`add_section()`.** New exported function that adds a new sheet to an
  existing curriculr workbook and registers it in the `sections` control
  sheet. The new sheet is pre-populated with the standard column spine
  including `include_in_resume`. The `sections` row is appended or updated in
  place without touching the sheet's formatting.

* **No-photo header layout.** When `photo = NULL`, `CV.qmd` now emits a
  single full-width centered header block instead of a two-column grid with
  an empty left column.

## Improvements

* `read_cv_data()` reads the `theme` sheet as a named character vector keyed
  by the `key` column, parallel to the `profile` sheet. Returns `NULL` if the
  sheet is absent.
* `read_cv_data()` coerces all section columns to character after import,
  including numeric year columns and logical boolean columns, giving the
  rendering pipeline a uniform contract.
* `read_cv_data()` gains a `.coerce_col()` internal helper that normalizes
  `NA` strings produced by `as.character(NA)` back to `NA_character_`.
* `create_cv()` injects `variant` and `use_icons` into `CV.qmd` as Quarto
  params so the Quarto subprocess applies the same filtering and icon
  settings as the calling R session.
* The `cv-data-template.xlsx` template workbook gains a `theme` sheet with
  all twelve default theming keys and a `description` column for in-workbook
  documentation. The `readme` sheet is updated to document the `theme` sheet
  and to reflect that `include_in_resume` is now present on all section
  sheets.
* Internal helpers `.cv_theme_defaults()`, `.resolve_theme()`,
  `.build_format_block()`, `.build_typst_theme_block()`, and `.fa_icon_map()`
  are added to support theming and icon assembly.

## Dependency changes

* `openxlsx2` added to `Imports`.
* `readxl` removed from `Imports`.


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
