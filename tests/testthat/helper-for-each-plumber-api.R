for_each_plumber_api <- function(fn, ...) {
  lapply(
    available_apis("plumber")$name,
    function(name) {
      if (name == "14-future") {
        if (!require("future", character.only = TRUE, quietly = TRUE)) {
          return()
        }
      }

      pr <-
        if (name == "12-entrypoint") {
          expect_warning({
            plumb_api("plumber", name)
          }, "Legacy cookie secret")
        } else {
          plumb_api("plumber", name)
        }
      expect_true(inherits(pr, "plumber"), paste0("plumb_api(\"", package, "\", \"", name, "\")"))


      fn(pr, ...)
    }
  )
}
