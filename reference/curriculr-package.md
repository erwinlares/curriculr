# curriculr: Data-Driven CVs with Quarto and Typst

Provides tools for producing data-driven curriculum vitae documents from
structured data stored in an Excel workbook. The core workflow reads CV
content from a workbook, converts it into Typst layout blocks, and
renders a polished PDF via Quarto's Typst engine. Includes functions for
reading and cleaning CV data, building Typst section headings and
entries, rendering CV sections from data frames, and scaffolding new CV
projects with a standard folder structure and template workbook.
Designed to separate content from layout: CV data lives in the
spreadsheet, rendering configuration lives in Quarto, and transformation
logic lives in small composable R functions. See Lauritzen (2023)
<https://typst.app> for the Typst typesetting system and Allaire et al.
(2024) <https://quarto.org> for the Quarto publishing system. Inspired
by the vitae package (O'Hara-Wild et al., 2024,
<https://CRAN.R-project.org/package=vitae>) and the Awesome CV LaTeX
template (Park, 2015, <https://github.com/posquit0/Awesome-CV>).

## See also

Useful links:

- <https://github.com/erwinlares/curriculr>

- <https://erwinlares.github.io/curriculr/>

- [doi:10.5281/zenodo.19930400](https://doi.org/10.5281/zenodo.19930400)

- Report bugs at <https://github.com/erwinlares/curriculr/issues>

## Author

**Maintainer**: Erwin Lares <erwin.lares@wisc.edu>
([ORCID](https://orcid.org/0000-0002-3284-828X))
