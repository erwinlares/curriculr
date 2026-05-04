# R/cv-contact.R
#
# Internal helpers for contact line assembly, Font Awesome icon mapping,
# theme defaults, and Typst/YAML block construction.
#
# None of these are exported -- they are called by create_cv() and by
# CV.qmd via cv_contact_line(), which is exported.


# cv_contact_line() -----------------------------------------------------

#' Build the contact line for the CV header
#'
#' Assembles a Typst-formatted contact line from a profile vector. When
#' `use_icons = "fontawesome"`, known contact fields are rendered with their
#' Font Awesome icon via the Typst `@preview/fontawesome` package. Fields with
#' no icon equivalent fall back to plain text with a warning. When
#' `use_icons = "none"`, all fields render as plain text.
#'
#' This function is called inside `CV.qmd` and is exported so that users
#' building custom Quarto templates can call it directly.
#'
#' @param profile A named character vector as returned by the `profile` element
#'   of [read_cv_data()].
#' @param use_icons A character string. `"fontawesome"` (the default) renders
#'   contact fields with Font Awesome icons. `"none"` renders plain text.
#'
#' @return A character string of raw Typst markup for the contact line.
#'
#' @export
cv_contact_line <- function(profile, use_icons = "fontawesome") {

    use_icons <- match.arg(use_icons, choices = c("fontawesome", "none"))

    # Fields that appear in the contact line and their display order.
    # Fields absent from the profile vector are silently skipped.
    contact_fields <- c("website", "email", "github", "linkedin", "phone")

    parts <- lapply(contact_fields, function(field) {
        val <- if (field %in% names(profile)) profile[[field]] else ""
        if (is.na(val) || !nzchar(val)) return(NULL)

        # Expand github and linkedin to full URLs for display
        display_val <- switch(field,
                              github   = paste0("github.com/", val),
                              linkedin = paste0("linkedin.com/", val),
                              typst_escape(val)
        )
        display_val <- typst_escape(display_val)

        if (use_icons == "fontawesome") {
            icon <- .fa_icon_map()[[field]]
            if (is.null(icon)) {
                cli::cli_warn(
                    "No Font Awesome icon found for profile field {.val {field}}.
           Falling back to plain text."
                )
                return(display_val)
            }
            return(paste0("#fa-icon(\"", icon, "\") ", display_val))
        }

        display_val
    })

    parts <- Filter(Negate(is.null), parts)
    if (length(parts) == 0) return("")

    separator <- if (use_icons == "fontawesome") {
        " #h(0.6em) "
    } else {
        " \u00b7 "
    }

    paste(parts, collapse = separator)
}


# .fa_icon_map() --------------------------------------------------------

#' Font Awesome icon map for known profile fields
#'
#' Returns a named character vector mapping profile field names to their
#' Font Awesome icon identifiers as used by the Typst
#' `@preview/fontawesome` package.
#'
#' @return A named character vector.
#'
#' @keywords internal
.fa_icon_map <- function() {
    c(
        email    = "envelope",
        website  = "globe",
        github   = "github",
        linkedin = "linkedin",
        phone    = "phone"
    )
}


# .cv_theme_defaults() --------------------------------------------------

#' Built-in theme defaults
#'
#' Returns a named character vector of default theme values used when the
#' workbook does not contain a `theme` sheet.
#'
#' @return A named character vector with the same keys as the `theme` sheet
#'   schema.
#'
#' @keywords internal
.cv_theme_defaults <- function() {
    c(
        font_family     = "Lato",
        font_size       = "8.8pt",
        body_color      = "#3f3f3f",
        line_leading    = "0.48em",
        accent_color    = "#c5050c",
        dark_color      = "#303030",
        bodygray_color  = "#555555",
        lightgray_color = "#777777",
        rulegray_color  = "#d9d9d9",
        papersize       = "us-letter",
        margin_x        = "0.62in",
        margin_y        = "0.58in"
    )
}


# .resolve_theme() ------------------------------------------------------

#' Resolve theme values, filling gaps with defaults
#'
#' Merges the user-supplied theme vector from the workbook with the built-in
#' defaults. Any key absent from the workbook theme is filled from defaults,
#' so partial theme sheets are supported.
#'
#' @param theme A named character vector as returned by `cv$theme`, or `NULL`.
#'
#' @return A named character vector with all twelve theme keys present.
#'
#' @keywords internal
.resolve_theme <- function(theme) {
    defaults <- .cv_theme_defaults()
    if (is.null(theme)) return(defaults)
    for (key in names(defaults)) {
        val <- theme[key]  # single bracket -- returns NA for missing names
        if (is.na(val) || !nzchar(val)) {
            theme[[key]] <- defaults[[key]]
        }
    }
    theme
}


# .build_format_block() -------------------------------------------------

#' Build the Quarto YAML format block from theme values
#'
#' Constructs the `format: typst:` YAML block that replaces the
#' `%%CURRICULR_FORMAT%%` sentinel in `CV.qmd`.
#'
#' @param theme A fully resolved named character vector as returned by
#'   [.resolve_theme()].
#'
#' @return A character string of YAML.
#'
#' @keywords internal
.build_format_block <- function(theme) {
    sprintf(
        paste0(
            "format:\n",
            "  typst:\n",
            "    toc: false\n",
            "    papersize: %s\n",
            "    margin:\n",
            "      x: %s\n",
            "      y: %s"
        ),
        theme[["papersize"]],
        theme[["margin_x"]],
        theme[["margin_y"]]
    )
}


# .build_typst_theme_block() --------------------------------------------

#' Build the Typst style block from theme values
#'
#' Constructs the raw `{=typst}` code block that replaces the
#' `%%CURRICULR_THEME%%` sentinel in `CV.qmd`. Optionally prepends the
#' Font Awesome package import when icons are in use.
#'
#' @param theme A fully resolved named character vector as returned by
#'   [.resolve_theme()].
#' @param use_icons A character string. `"fontawesome"` prepends the FA
#'   import line. `"none"` omits it.
#'
#' @return A character string of raw Typst markup wrapped in a Quarto
#'   `{=typst}` code fence.
#'
#' @keywords internal
.build_typst_theme_block <- function(theme, use_icons = "fontawesome") {

    fa_import <- if (use_icons == "fontawesome") {
        '#import "@preview/fontawesome:0.5.0": *\n'
    } else {
        ""
    }

    sprintf(
        paste0(
            "```{=typst}\n",
            "%s",
            "// -------------------------------------------------------\n",
            "// Document style settings \u2014 edit the theme sheet to change\n",
            "// -------------------------------------------------------\n",
            "#set text(font: \"%s\", size: %s, fill: rgb(\"%s\"))\n",
            "#set par(justify: false, leading: %s)\n",
            "\n",
            "#let accent    = rgb(\"%s\")\n",
            "#let dark      = rgb(\"%s\")\n",
            "#let bodygray  = rgb(\"%s\")\n",
            "#let lightgray = rgb(\"%s\")\n",
            "#let rulegray  = rgb(\"%s\")\n",
            "```"
        ),
        fa_import,
        theme[["font_family"]],
        theme[["font_size"]],
        theme[["body_color"]],
        theme[["line_leading"]],
        theme[["accent_color"]],
        theme[["dark_color"]],
        theme[["bodygray_color"]],
        theme[["lightgray_color"]],
        theme[["rulegray_color"]]
    )
}
