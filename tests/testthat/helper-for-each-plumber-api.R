for_each_plumber_api <- function(fn, ...) {
  package <- "plumber"
  lapply(
    available_apis(package)$name,
    function(name) {
      if (name == "14-future") {
        if (!require("future", character.only = TRUE, quietly = TRUE)) {
          return()
        }
      }

      pr <-
        if (name == "12-entrypoint") {
          expect_warning({
            plumb_api(package, name)
          }, "Legacy cookie secret")
        } else {
          plumb_api(package, name)
        }
      expect_true(is_pr(pr), paste0("plumb_api(\"", package, "\", \"", name, "\")"))


      fn(pr, ...)
    }
  )
}
