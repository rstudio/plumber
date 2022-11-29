context("Endpoints argument conversion")

test_that("Endpoints with no parameters work", {
  env <- new.env()

  foo <- parse(text="foo <- function(){ 'Working!' }")
  srcRef <- 1:2

  r <- PlumberEndpoint$new('verb', 'path', foo, env, srcRef)
  expect_equal(r$exec(req = list(), res = list()), "Working!")
})

test_that("Endpoints with untyped parameters work", {
  env <- new.env()

  foo <- parse(text="foo <- function(a){ paste0('a was ', a) }")
  srcRef <- 1:2
  params <- list(
    a = list(
      type="string",
      isArray=FALSE,
      required=FALSE
    )
  )

  r <- PlumberEndpoint$new('verb', 'path', foo, env, srcRef, params = params)
  expect_equal(r$exec(req = list(args = list(a="Hello")), res = list()), "a was Hello")
})

typed_args_helper <- function(args) {
  env <- new.env()

  foo <- parse(text="foo <- function(a_string, a_double, a_integer, a_boolean, a_string_array, a_double_array, a_integer_array, a_boolean_array){
                  list(
                  a_string=a_string,
                  a_integer=a_integer,
                  a_double=a_double,
                  a_boolean=a_boolean,
                  a_string_array=a_string_array,
                  a_integer_array=a_integer_array,
                  a_double_array=a_double_array,
                  a_boolean_array=a_boolean_array)
               }")
  srcRef <- 1:2
  params <- list(
    a_string = list(
      type="string",
      isArray=FALSE,
      required=FALSE
    ),
    a_double = list(
      type="number",
      isArray=FALSE,
      required=FALSE
    ),
    a_integer = list(
      type="integer",
      isArray=FALSE,
      required=FALSE
    ),
    a_boolean = list(
      type="boolean",
      isArray=FALSE,
      required=FALSE
    ),
    a_string_array = list(
      type="string",
      isArray=TRUE,
      required=FALSE
    ),
    a_double_array = list(
      type="number",
      isArray=TRUE,
      required=FALSE
    ),
    a_integer_array = list(
      type="integer",
      isArray=TRUE,
      required=FALSE
    ),
    a_boolean_array = list(
      type="boolean",
      isArray=TRUE,
      required=FALSE
    )
  )

  # pass vectors of characters in the request
  req <- list(
    args = args
  )

  r <- PlumberEndpoint$new('verb', 'path', foo, env, srcRef, params = params)
  results <- r$exec(req = req, res = list())

  results
}

test_that("Endpoints with typed parameters work", {

  typed_args <- list(
    a_string="Hello",
    a_integer=42,
    a_double=3.142,
    a_boolean=TRUE,
    a_string_array=c("Life","Is","Like","A","Box"),
    a_integer_array=c(2L,4L,6L,8L,-1L),
    a_double_array=c(12.12, 23.23, -11.11),
    a_boolean_array=c(FALSE, FALSE, TRUE)
  )

  untyped_args <- lapply(typed_args, as.character)
  expect_equal(class(untyped_args$a_boolean), class(""))
  expect_equal(class(untyped_args$a_boolean_array), class(""))
  expect_equal(class(untyped_args$a_double), class(""))
  expect_equal(class(untyped_args$a_double_array), class(""))
  expect_equal(class(untyped_args$a_integer), class(""))
  expect_equal(class(untyped_args$a_integer_array), class(""))

  results <- typed_args_helper(untyped_args)

  expect_equal(results, typed_args)
  expect_equal(class(results$a_boolean), class(TRUE))
  expect_equal(class(results$a_boolean_array), class(TRUE))
  expect_equal(class(results$a_double), class(12.1))
  expect_equal(class(results$a_double_array), class(12.1))
  expect_equal(class(results$a_integer), class(42L))
  expect_equal(class(results$a_integer_array), class(42L))
})

test_that("Turning the convert plumber.typedParameters option off, prevents conversions", {
  with_options(
    list(plumber.typedParameters = FALSE),
    {
      typed_args <- list(
        a_string="Hello",
        a_integer=42,
        a_double=3.142,
        a_boolean=TRUE,
        a_string_array=c("Life","Is","Like","A","Box"),
        a_integer_array=c(2L,4L,6L,8L,-1L),
        a_double_array=c(12.12, 23.23, -11.11),
        a_boolean_array=c(FALSE, FALSE, TRUE)
      )

      untyped_args <- lapply(typed_args, as.character)

      expect_equal(class(untyped_args$a_boolean), class(""))
      expect_equal(class(untyped_args$a_boolean_array), class(""))
      expect_equal(class(untyped_args$a_double), class(""))
      expect_equal(class(untyped_args$a_double_array), class(""))
      expect_equal(class(untyped_args$a_integer), class(""))
      expect_equal(class(untyped_args$a_integer_array), class(""))

      results <- typed_args_helper(untyped_args)

      expect_equal(results, untyped_args)

      expect_equal(class(results$a_boolean), class(""))
      expect_equal(class(results$a_boolean_array), class(""))
      expect_equal(class(results$a_double), class(""))
      expect_equal(class(results$a_double_array), class(""))
      expect_equal(class(results$a_integer), class(""))
      expect_equal(class(results$a_integer_array), class(""))
    }
  )
})
