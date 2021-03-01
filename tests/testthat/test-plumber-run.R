
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
  skip_if_not_installed("mockery", "0.4.2")

  m <- mockery::mock(TRUE, cycle = TRUE)
  m() # call once so that `length(m)` > 0 as `length(m)` represents the number of calls to `m`
  root <- pr() %>% pr_set_docs_callback(m)
  # not used
  with_interrupt({
    mockery::expect_called(m, 1)
    root %>% pr_run(swaggerCallback = NULL)
    mockery::expect_called(m, 1)
  })
  # not used
  with_interrupt({
    mockery::expect_called(m, 1)
    root$run(swaggerCallback = NULL)
    mockery::expect_called(m, 1)
  })
  # used
  with_interrupt({
    mockery::expect_called(m, 1)
    root %>% pr_run(quiet = FALSE)
    mockery::expect_called(m, 2)
  })
})

test_that("`swaggerCallback` can be set by option after the pr is created", {
  skip_if_not_installed("mockery", "0.4.2")

  m <- mockery::mock(TRUE)

  # must initialize before options are set
  root <- pr()

  with_options(
    list(
      plumber.swagger.url = getOption("plumber.swagger.url"),
      plumber.docs.callback = getOption("plumber.docs.callback")
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
  # used
  mockery::expect_called(m, 1)

})


### Test does not work as expected with R6 objects.
test_that("`debug` is not set until runtime", {
  skip_if_not_installed("mockery", "0.4.2")

  m <- mockery::mock(TRUE, cycle = TRUE)
  # https://github.com/r-lib/testthat/issues/734#issuecomment-377367516
  # > It should work if you fully qualify the function name (include the pkgname)
  with_mock("plumber:::default_debug" = m, {
    root <- pr()
    root$getDebug()
    mockery::expect_called(m, 1)

    with_interrupt({
      root %>% pr_run(quiet = TRUE)
    })
    # increase by 1
    mockery::expect_called(m, 2)

    # listen to set value
    with_interrupt({
      root %>%
        pr_set_debug(TRUE) %>%
        pr_run(quiet = TRUE)
    })
    # not updated. stay at 2
    mockery::expect_called(m, 2)

    # listen to run value
    with_interrupt({
      root %>%
        pr_run(debug = FALSE, quiet = TRUE)
    })
    # not updated. stay at 2
    mockery::expect_called(m, 2)

    # TODO test that run(debug=) has preference over pr_set_debug()
  })

})
