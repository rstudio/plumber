
test_that("doc mounts are prepended", {

  assertions <- 0

  root <-
    test_path("files/static.R") %>%
    pr() %>%
    pr_set_docs(TRUE) %>%
    pr_hook("exit", function(...) {
      expect_length(root$mounts, 3)
      assertions <<- assertions + 1
      expect_equal(names(root$mounts)[1], "/__docs__/")
      assertions <<- assertions + 1
    })

  expect_length(root$mounts, 2)
  assertions <- assertions + 1

  # no docs. do not find printed message
  with_interrupt({
    root %>% pr_run()
  })

  expect_equal(assertions, 3)
})
