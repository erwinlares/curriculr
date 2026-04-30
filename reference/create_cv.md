# Scaffold a new curriculr CV project

Creates a new CV project at the given path with a standard folder
structure, a pre-populated Excel workbook, a placeholder profile image,
and a ready-to-render Quarto document.

## Usage

``` r
create_cv(path, filename = "CV.qmd", overwrite = FALSE)
```

## Arguments

- path:

  A character string. Path to the directory where the CV project will be
  created. The directory must already exist. Use
  [`base::tempdir()`](https://rdrr.io/r/base/tempfile.html) for
  temporary output during testing or exploration.

- filename:

  A character string. Name of the generated `.qmd` file. Defaults to
  `"CV.qmd"`.

- overwrite:

  A logical. Whether to overwrite existing files. Defaults to `FALSE`.

## Value

Invisibly returns `path`. Called primarily for its side effects.

## Details

`create_cv()` performs the following steps:

1.  Validates that `path` exists.

2.  Creates a `data/` folder and copies the template Excel workbook
    (`cv-data-template.xlsx`) there.

3.  Creates an `img/` folder and copies the placeholder profile image
    (`placeholder.png`) there.

4.  Copies the CV Quarto template into `path/filename`.

After scaffolding, open the Excel workbook and fill in the `profile`
sheet with your personal information. Then render the CV with:

    quarto render CV.qmd

## Examples

``` r
# \donttest{
# Scaffold a CV project in a temp directory
create_cv(path = tempdir())
#> ✔ Created /tmp/RtmpeURcK6/data/cv-data-template.xlsx
#> ✔ Created /tmp/RtmpeURcK6/img/placeholder.png
#> ✔ Created /tmp/RtmpeURcK6/CV.qmd
#> ✔ CV project scaffolded at /tmp/RtmpeURcK6
#> ℹ Next step: open /tmp/RtmpeURcK6/data/cv-data-template.xlsx and fill in the "profile" sheet.

# Use a custom filename
create_cv(path = tempdir(), filename = "my-cv.qmd", overwrite = TRUE)
#> ✔ Created /tmp/RtmpeURcK6/data/cv-data-template.xlsx
#> ✔ Created /tmp/RtmpeURcK6/img/placeholder.png
#> ✔ Created /tmp/RtmpeURcK6/my-cv.qmd
#> ✔ CV project scaffolded at /tmp/RtmpeURcK6
#> ℹ Next step: open /tmp/RtmpeURcK6/data/cv-data-template.xlsx and fill in the "profile" sheet.
# }
```
