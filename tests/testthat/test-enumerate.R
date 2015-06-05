test_that("enumerate returns all on 'use'", {
  expect_equal(enumerateVerbs("use"), toupper(c("get", "put", "post", "delete")))
})

test_that("regular verbs return themselves", {
  expect_equal(enumerateVerbs("get"), "GET")
  expect_equal(enumerateVerbs("post"), "POST")
})
