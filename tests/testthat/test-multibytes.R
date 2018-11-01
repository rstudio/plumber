context("multibytes source file")

with_locale <- function(locale, locale_val, expr) {
  prev_locale_val <- Sys.getlocale(locale)
  Sys.setlocale(locale, locale_val)
  on.exit({
    Sys.setlocale(locale, prev_locale_val)
  })
  force(expr)
}

expect_utf8 <- function(x) {
  expect_equal(Encoding(x), "UTF-8")
}

test_that("support files with multibytes", {

  with_locale("LC_CTYPE", "C", {
    with_locale("LC_COLLATE", "C", {

      r <- plumber$new(test_path("files/multibytes.R"))
      req <- make_req("GET", "/echo")
      res <- PlumberResponse$new()
      out <- r$serve(req, res)$body

      # ?Quotes
      # "Unicode escapes can be used to enter Unicode characters not in the current locale's
      # charset (when the string will be stored internally in UTF-8)."
      expected <- jsonlite::toJSON("\u4e2d\u6587\u6d88\u606f")

      expect_identical(Sys.getlocale("LC_CTYPE"), "C")
      expect_identical(Sys.getlocale("LC_COLLATE"), "C")
      expect_utf8(expected)
      expect_utf8(out)
      expect_identical(out, expected)

    })
  })
})
