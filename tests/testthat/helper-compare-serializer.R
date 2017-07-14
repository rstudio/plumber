# We can't naively compare serializers using expect equal without losing codecov results.
# codecov modifies the source of the functions so they are no longer comparable when
# deparsed, which causes the tests to fail only for codecov.
# Here we'll make our own comparison function.
# covr adds lines to measure coverage but also adds brackets to capture expressions differently.
# So we use this rough heuristic to just take the word characters without whitespace and compare
# those. It's not perfect, but it would almost always fail if you were comparing to different
# functions.
expect_equal_functions <- function(object, expected){
  do <- deparse(object)
  de <- deparse(expected)

  do <- gsub(".*covr:::count.*", NA, do)
  do <- do[!is.na(do)]
  do <- paste(do, collapse="")
  do <- gsub("[^\\w]", "", do, perl=TRUE)

  de <- gsub(".*covr:::count.*", NA, de)
  de <- de[!is.na(de)]
  de <- paste(de, collapse="")
  de <- gsub("[^\\w]", "", de, perl=TRUE)

  expect_equal(do, de)
}
