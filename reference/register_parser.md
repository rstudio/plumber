# Manage parsers

A parser is responsible for decoding the raw body content of a request
into a list of arguments that can be mapped to endpoint function
arguments. For instance,
[`parser_json()`](https://www.rplumber.io/reference/parsers.md) parse
content-type `application/json`.

## Usage

``` r
register_parser(alias, parser, fixed = NULL, regex = NULL, verbose = TRUE)

registered_parsers()
```

## Arguments

- alias:

  An alias to map parser from the `@parser` plumber tag to the global
  parsers list.

- parser:

  The parser function to be added. This build the parser function. See
  Details for more information.

- fixed:

  A character vector of fixed string to be matched against a request
  `content-type` to use `parser`.

- regex:

  A character vector of [regex](https://rdrr.io/r/base/regex.html)
  string to be matched against a request `content-type` to use `parser`.

- verbose:

  Logical value which determines if a warning should be displayed when
  alias in map are overwritten.

## Details

When `parser` is evaluated, it should return a parser function. Parser
matching is done first by `content-type` header matching with `fixed`
then by using regular expressions with `regex`. Note that plumber strips
`; charset*` from `content-type` header before matching.

Plumber will try to use
[`parser_json()`](https://www.rplumber.io/reference/parsers.md) (if
available) when no `content-type` header is found and the request body
starts with `{` or `[`.

Functions signature should include `value`, `...` and possibly
`content_type`, `filename`. Other parameters may be provided if you want
to use the headers from
[`webutils::parse_multipart()`](https://jeroen.r-universe.dev/webutils/reference/parse_multipart.html).

Parser function structure is something like below.

    function(parser_arguments_here) {
      # return a function to parse a raw value
      function(value, ...) {
        # do something with raw value
      }
    }

## Functions

- `registered_parsers()`: Return all registered parsers

## Examples

``` r
# `content-type` header is mostly used to look up charset and adjust encoding
parser_dcf <- function(...) {
  function(value, content_type = "text/x-dcf", ...) {
    charset <- get_character_set(content_type)
    value <- rawToChar(value)
    Encoding(value) <- charset
    read.dcf(value, ...)
  }
}

# Could also leverage existing parsers
parser_dcf <- function(...) {
  parser_read_file(function(tmpfile) {
    read.dcf(tmpfile, ...)
  })
}

# Register the newly created parser
if (FALSE) register_parser("dcf", parser_dcf, fixed = "text/x-dcf") # \dontrun{}
```
