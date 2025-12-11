# Set the API visual documentation

`docs` should be either a logical or a character value matching a
registered visual documentation. Multiple handles will be added to
[`Plumber`](https://www.rplumber.io/reference/Plumber.md) object.
OpenAPI json file will be served on paths `/openapi.json`. Documentation
will be served on paths `/__docs__/index.html` and `/__docs__/`.

## Usage

``` r
pr_set_docs(pr, docs = get_option_or_env("plumber.docs", TRUE), ...)
```

## Arguments

- pr:

  A Plumber API. Note: The supplied Plumber API object will also be
  updated in place as well as returned by the function.

- docs:

  a character value or a logical value. If using
  [`options_plumber()`](https://www.rplumber.io/reference/options_plumber.md),
  the value must be set before initializing your Plumber router.

- ...:

  Arguments for the visual documentation. See each visual documentation
  package for further details.

## Value

The Plumber router with the new docs settings.

## Examples

``` r
if (FALSE) { # \dontrun{
## View API using Swagger UI
# Official Website: https://swagger.io/tools/swagger-ui/
# install.packages("swagger")
if (require(swagger)) {
  pr() %>%
    pr_set_docs("swagger") %>%
    pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
    pr_run()
}

## View API using Redoc
# Official Website: https://github.com/Redocly/redoc
if (require(redoc)) {
  pr() %>%
    pr_set_docs("redoc") %>%
    pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
    pr_run()
}

## View API using RapiDoc
# Official Website: https://github.com/mrin9/RapiDoc
if (require(rapidoc)) {
  pr() %>%
    pr_set_docs("rapidoc") %>%
    pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
    pr_run()
}

## Disable the OpenAPI Spec UI
pr() %>%
  pr_set_docs(FALSE) %>%
  pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
  pr_run()
} # }
```
