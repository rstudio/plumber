for_each_plumber_api <- function(fn, ...) {
  package <- "plumber"
  lapply(
    available_apis(package)$name,
    function(name) {
      if (name == "14-future") {
        if (.Platform$OS.type == "windows" && getRversion() >= "4.0.0") {
          # Future is not cleaned up properly and produces detritus temp files
          # Debug PR: https://github.com/rstudio/plumber/pull/870
          # Explain: https://github.com/HenrikBengtsson/future/blame/7a15808391b604903659bf67f9aa809f4c9a54c4/cran-comments.md
          # Work around: https://github.com/HenrikBengtsson/future/blob/12cf573dc60cad82a22f03ff6e144201ba1bd42c/tests/nested_futures%2Cmc.cores.R#L5-L15
          # R devel post: https://stat.ethz.ch/pipermail/r-devel/2021-June/080830.html
          message("Skipping test on 14-future example on Windows R >= 4.0")
          return()
        }
        if (!require("future", character.only = TRUE, quietly = TRUE)) {
          return()
        }
      }

      pr <-
        if (name %in% c("06-sessions", "12-entrypoint")) {
          expect_warning({
            plumb_api(package, name)
          }, "Legacy cookie secret")
        } else {
          plumb_api(package, name)
        }
      expect_true(is_plumber(pr), paste0("plumb_api(\"", package, "\", \"", name, "\")"))


      fn(pr, ...)
    }
  )
}
