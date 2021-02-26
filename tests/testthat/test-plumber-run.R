
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
  counter <- 0
  my_func <- function(url) {
    counter <<- counter + 1
  }
  root <- pr() %>% pr_set_docs_callback(my_func)
  # not used
  with_interrupt({
    expect_equal(counter, 0)
    root %>% pr_run(swaggerCallback = NULL)
    expect_equal(counter, 0)
  })
  # not used
  with_interrupt({
    expect_equal(counter, 0)
    root$run(swaggerCallback = NULL)
    expect_equal(counter, 0)
  })
  # used
  with_interrupt({
    expect_equal(counter, 0)
    root %>% pr_run(quiet = FALSE)
    expect_equal(counter, 1)
  })
})

test_that("`swaggerCallback` can be set by option after the pr is created", {
  counter <- 0
  my_func <- function(url) {
    counter <<- counter + 1
  }

  # must initialize before options are set
  root <- pr()

  with_options(
    list(
      plumber.swagger.url = getOption("plumber.swagger.url"),
      plumber.docs.callback = getOption("plumber.docs.callback")
    ),
    {
      # set option after init
      options_plumber(docs.callback = my_func)
      with_interrupt({
        expect_equal(counter, 0)
        pr_run(root)
      })
    }
  )
  # used
  expect_equal(counter, 1)

})


### Test does not work as expected with R6 objects.
test_that("`debug` is not set until runtime", {
  skip_on_cran()

  counter <- 0

  local({
    # Could not get `mockery` or `mockr` packages to work as expected.
    # So shiming the function here...
    plumber_env <- asNamespace("plumber")
    prev_default_debug <- plumber_env$default_debug
    on.exit({
      plumber_env$default_debug <- prev_default_debug
    }, add = TRUE)
    plumber_env$default_debug <- function() {
      counter <<- 1
      TRUE
    }

    root <- pr()
    expect_equal(counter, 0)

    # Use default value
    with_interrupt({
      root %>% pr_run(quiet = TRUE)
    })
    expect_equal(counter, 1)

    # listen to set value
    with_interrupt({
      root %>%
        pr_set_debug(TRUE) %>%
        pr_run(quiet = TRUE)
    })
    # not updated
    expect_equal(counter, 1)

    # listen to run value
    with_interrupt({
      root %>%
        pr_run(debug = FALSE, quiet = TRUE)
    })
    # not updated
    expect_equal(counter, 1)

    # TODO test that run(debug=) has preference over pr_set_debug()
  })


  # make sure the function is restored
  expect_equal(default_debug(), interactive())
  # counter should not increment
  expect_equal(counter, 1)


})
