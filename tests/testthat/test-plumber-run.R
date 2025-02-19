
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
  # no docs. do not find printed message
  with_interrupt({
    expect_failure(
      expect_message({
        root %>% pr_run(docs = FALSE)
      }, doc_name)
    )
  })
  # no docs. do not find printed message
  with_interrupt({
    expect_failure(
      expect_message({
        root$run(docs = FALSE)
      }, doc_name)
    )
  })
  # docs enabled by default. Find printed message
  with_interrupt({
    expect_message({
      root %>% pr_run(quiet = FALSE)
    }, doc_name)
  })
})

test_that("`swaggerCallback` does not not permanetly set pr information", {
  skip_if_not_installed("mockery", "0.4.2")

  m <- mockery::mock(TRUE, cycle = TRUE)
  m() # call once so that `length(m)` > 0 as `length(m)` represents the number of calls to `m`
  root <- pr() %>% pr_set_docs_callback(m)
  # m not used
  with_interrupt({
    mockery::expect_called(m, 1)
    root %>% pr_run(swaggerCallback = NULL)
    mockery::expect_called(m, 1)
  })
  # m not used
  with_interrupt({
    mockery::expect_called(m, 1)
    root$run(swaggerCallback = NULL)
    mockery::expect_called(m, 1)
  })
  # m is used
  with_interrupt({
    mockery::expect_called(m, 1)
    root %>% pr_run(quiet = FALSE)
    mockery::expect_called(m, 2)
  })
})

test_that("`swaggerCallback` can be set by option after the pr is created", {
  skip_if_not_installed("mockery", "0.4.2")

  m <- mockery::mock(TRUE)

  # must initialize before options are set for this test
  root <- pr()

  with_options(
    list(
      plumber.swagger.url = get_option_or_env("plumber.swagger.url"),
      plumber.docs.callback = get_option_or_env("plumber.docs.callback")
    ),
    {
      # set option after init
      options_plumber(docs.callback = m)
      with_interrupt({
        mockery::expect_called(m, 0)
        pr_run(root)
      })
    }
  )
  # m is used
  mockery::expect_called(m, 1)

})
