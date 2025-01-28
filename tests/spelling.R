# testthat:::on_cran
is_interactive <- rlang::is_interactive()
not_cran <- isTRUE(as.logical(Sys.getenv("NOT_CRAN", "false")))
on_cran <- !is_interactive && !not_cran

if (!on_cran) {
  if (requireNamespace("spelling", quietly = TRUE)) {
    spelling::spell_check_test(
      vignettes = TRUE,
      error = TRUE,
      skip_on_cran = TRUE
    )
  }
}
