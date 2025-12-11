# Add visual documentation for plumber to use

`register_docs()` is used by other packages like `swagger`, `rapidoc`,
and `redoc`. When you load these packages, it calls `register_docs()` to
provide a user interface that can interpret your plumber OpenAPI
Specifications.

## Usage

``` r
register_docs(name, index, static = NULL)

registered_docs()
```

## Arguments

- name:

  Name of the visual documentation

- index:

  A function that returns the HTML content of the landing page of the
  documentation. Parameters (besides `req` and `res`) will be supplied
  as if it is a regular `GET` route. Default parameter values may be
  used when setting the documentation `index` function. See the example
  below.

- static:

  A function that returns the path to the static assets (images,
  javascript, css, fonts) the Docs will use.

## Examples

``` r
if (FALSE) { # \dontrun{
# Example from the `swagger` R package
register_docs(
  name = "swagger",
  index = function(version = "3", ...) {
    swagger::swagger_spec(
      api_path = paste0(
        "window.location.origin + ",
        "window.location.pathname.replace(",
          "/\\(__docs__\\\\/|__docs__\\\\/index.html\\)$/, \"\"",
        ") + ",
        "\"openapi.json\""
      ),
      version = version
    )
  },
  static = function(version = "3", ...) {
    swagger::swagger_path(version)
  }
)

# When setting the docs, `index` and `static` function arguments can be supplied
# * via `pr_set_docs()`
# * or through URL query string variables
pr() %>%
  # Set default argument `version = "3"` for the swagger `index` and `static` functions
  pr_set_docs("swagger", version = "3") %>%
  pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
  pr_run()
} # }
```
