
with_interrupt <- function(expr) {
  # Causes pr_run() to immediately exit
  later::later(httpuv::interrupt)
  force(expr)
}

test_that("quiet=TRUE suppresses startup messages", {
  with_interrupt({
    expect_message(pr() %>% pr_run(quiet = TRUE), NA)
  })
  with_interrupt({
    expect_message(pr()$run(quiet = TRUE), NA)
  })
})

test_that("`docs` does not not permanetly set pr information", {
  doc_name <- "swagger"
  root <- pr() %>% pr_set_docs(doc_name)
  with_interrupt({
    expect_failure(
      expect_message({
        root %>% pr_run(docs = FALSE)
      }, doc_name)
    )
  })
  with_interrupt({
    expect_failure(
      expect_message({
        root$run(docs = FALSE)
      }, doc_name)
    )
  })
  with_interrupt({
    expect_message({
      root %>% pr_run(quiet = FALSE)
    }, doc_name)
  })
})

test_that("`swaggerCallback` does not not permanetly set pr information", {
  msg <- "test got here!"
  my_func <- function(url) {
    message(msg)
  }
  root <- pr() %>% pr_set_docs_callback(my_func)
  with_interrupt({
    expect_failure(
      expect_message({
        root %>% pr_run(swaggerCallback = NULL)
      }, msg)
    )
  })
  with_interrupt({
    expect_failure(
      expect_message({
        root$run(swaggerCallback = NULL)
      }, msg)
    )
  })
  with_interrupt({
    expect_message({
      root %>% pr_run(quiet = FALSE)
    }, msg)
  })
})
