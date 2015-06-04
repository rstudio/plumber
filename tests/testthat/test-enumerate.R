test_that("enumerate returns all on 'use'", {
  expect_equal(enumerateVerbs("use"), c("get", "put", "post", "delete"))
})

test_that("regular verbs return themselves", {
  expect_equal(enumerateVerbs("get"), "get")
  expect_equal(enumerateVerbs("post"), "post")
})
