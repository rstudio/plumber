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

  # LC_ALL was not used as Mac had warnings when trying to restore LC_ALL
  # ?Sys.setlocale
  # `R sets ‘"LC_CTYPE"’ and ‘"LC_COLLATE"’,
  #  which allow the use of a different character set and alphabetic
  #  comparisons in that character set`
  with_locale("LC_CTYPE", "C", {
    with_locale("LC_COLLATE", "C", {

      r <- plumber$new(test_path("files/multibytes.R"))
      req <- make_req("GET", "/echo")
      out <- r$call(req)$body

      # ?Quotes
      # `Unicode escapes can be used to enter Unicode characters not in the current locale's
      # charset (when the string will be stored internally in UTF-8).`
      expected <- jsonlite::toJSON("\u4e2d\u6587\u6d88\u606f")

      expect_identical(Sys.getlocale("LC_CTYPE"), "C")
      expect_identical(Sys.getlocale("LC_COLLATE"), "C")
      expect_utf8(expected)
      expect_utf8(out)
      # using charToRaw as identical coerces strings to different locales
      # ?identical
      # `Character strings are regarded as identical if they are in
      # different marked encodings but would agree when translated to
      # UTF-8.`
      expect_identical(charToRaw(out), charToRaw(expected))

    })
  })
})
