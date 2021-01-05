with_options <- function(opts, code) {
  old_opts <- options(opts)
  on.exit({
    options(old_opts)
  }, add = TRUE)

  force(code)
}
