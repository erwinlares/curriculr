# Generate a CV document from a curriculr workbook

Called with no arguments, `create_cv()` runs in **scaffold mode**: it
copies the template Excel workbook and placeholder profile image to the
current working directory and prints instructions for the next step. No
rendering takes place.

## Usage

``` r
create_cv(data = NULL, photo = NULL, output_file = "CV.pdf", overwrite = FALSE)
```

## Arguments

- data:

  A character string or `NULL`. Path to the Excel workbook. Defaults to
  `NULL`, which triggers scaffold mode.

- photo:

  A character string or `NULL`. Path to the profile image. Defaults to
  `NULL`. In render mode, if `photo` is `NULL` the bundled placeholder
  image is used.

- output_file:

  A character string. Name of the output PDF file. Defaults to
  `"CV.pdf"`. Ignored in scaffold mode.

- overwrite:

  A logical. Whether to overwrite existing files. Defaults to `FALSE`.

## Value

In scaffold mode, invisibly returns the path to the directory where
files were copied. In render mode, invisibly returns the path to the
rendered PDF.

## Details

Called with `data` and `photo` arguments, `create_cv()` runs in **render
mode**: it reads the workbook, generates `CV.qmd`, and renders it to PDF
using Quarto's Typst engine. Both `CV.qmd` and `CV.pdf` are written to
the same directory as the workbook.

**Scaffold mode** (no arguments):

1.  Copies `cv-data-template.xlsx` to
    [`getwd()`](https://rdrr.io/r/base/getwd.html).

2.  Copies `placeholder.png` to
    [`getwd()`](https://rdrr.io/r/base/getwd.html).

3.  Prints instructions for editing the workbook and rendering the CV.

**Render mode** (`data` supplied):

1.  Resolves the workbook and photo paths.

2.  Reads the workbook with
    [`read_cv_data()`](https://erwinlares.github.io/curriculr/reference/read_cv_data.md).

3.  Validates that a `sections` sheet is present.

4.  Computes the photo path relative to the output directory.

5.  Writes `CV.qmd` by injecting resolved paths into the package
    template.

6.  Calls
    [`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html)
    to produce the PDF.

The `sections` sheet in the workbook controls which CV sections are
rendered and in what order. Each row corresponds to one section. To
exclude a section, delete its row. To reorder sections, reorder the
rows.

## Examples

``` r
if (FALSE) { # \dontrun{
# Scaffold mode — copy template files to current directory
create_cv()

# Render mode — use your own workbook and photo
create_cv(
  data  = "~/my_cv/cv-data.xlsx",
  photo = "~/my_cv/me.jpeg"
)

# Render mode — custom output filename
create_cv(
  data        = "~/my_cv/cv-data.xlsx",
  photo       = "~/my_cv/me.jpeg",
  output_file = "erwin-lares-cv.pdf"
)
} # }
```
