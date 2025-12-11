# Validate OpenAPI Spec

Validate an OpenAPI Spec using
[`@redocly/cli`](https://redocly.com/docs/cli/commands/lint).

## Usage

``` r
validate_api_spec(
  pr,
  ...,
  ruleset = c("minimal", "recommended", "recommended-strict"),
  verbose = TRUE
)
```

## Arguments

- pr:

  A Plumber API

- ...:

  Ignored

- ruleset:

  Character that determines the ruleset to use for validation. Can be
  one of "minimal", "recommended", or "recommended-strict". Defaults to
  "minimal". See [`@redocly/cli`
  options](https://redocly.com/docs/cli/commands/lint#options) for more
  details.

- verbose:

  Logical that determines if a "is valid" statement is displayed.
  Defaults to `TRUE`

## Details

If any warning or error is presented, an error will be thrown.

This function is **\[experimental\]** and may be altered, changed, or
removed in the future.

## Examples

``` r
if (FALSE) { # \dontrun{
pr <- plumb_api("plumber", "01-append")
validate_api_spec(pr)
} # }
```
