# Set the default endpoint parsers for the router

By default, Plumber will parse JSON, text, query strings, octet streams,
and multipart bodies. This function updates the default parsers for any
endpoint that does not define their own parsers.

## Usage

``` r
pr_set_parsers(pr, parsers)
```

## Arguments

- pr:

  A Plumber API. Note: The supplied Plumber API object will also be
  updated in place as well as returned by the function.

- parsers:

  Can be one of:

  - A `NULL` value

  - A character vector of parser names

  - A named [`list()`](https://rdrr.io/r/base/list.html) whose keys are
    parser names names and values are arguments to be applied with
    [`do.call()`](https://rdrr.io/r/base/do.call.html)

  - A `TRUE` value, which will default to combining all parsers. This is
    great for seeing what is possible, but not great for security
    purposes

  If the parser name `"all"` is found in any character value or list
  name, all remaining parsers will be added. When using a list, parser
  information already defined will maintain their existing argument
  values. All remaining parsers will use their default arguments.

  Example:

      # provide a character string
      parsers = "json"

      # provide a named list with no arguments
      parsers = list(json = list())

      # provide a named list with arguments; include `rds`
      parsers = list(json = list(simplifyVector = FALSE), rds = list())

      # default plumber parsers
      parsers = c("json", "form", "text", "octet", "multi")

## Value

The Plumber router with the new default
[PlumberEndpoint](https://www.rplumber.io/reference/PlumberEndpoint.md)
parsers

## Details

Note: The default set of parsers will be completely replaced if any
value is supplied. Be sure to include all of your parsers that you would
like to include. Use
[`registered_parsers()`](https://www.rplumber.io/reference/register_parser.md)
to get a list of available parser names.
