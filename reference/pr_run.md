# Start a server using `plumber` object

`port` does not need to be explicitly assigned.

## Usage

``` r
pr_run(
  pr,
  host = "127.0.0.1",
  port = get_option_or_env("plumber.port", NULL),
  ...,
  debug = missing_arg(),
  docs = missing_arg(),
  swaggerCallback = missing_arg(),
  quiet = FALSE
)
```

## Arguments

- pr:

  A Plumber API. Note: The supplied Plumber API object will also be
  updated in place as well as returned by the function.

- host:

  A string that is a valid IPv4 or IPv6 address that is owned by this
  server, which the application will listen on. "0.0.0.0" represents all
  IPv4 addresses and "::/0" represents all IPv6 addresses.

- port:

  A number or integer that indicates the server port that should be
  listened on. Note that on most Unix-like systems including Linux and
  Mac OS X, port numbers smaller than 1025 require root privileges.

- ...:

  Should be empty.

- debug:

  If `TRUE`, it will provide more insight into your API errors. Using
  this value will only last for the duration of the run. If
  [`pr_set_debug()`](https://www.rplumber.io/reference/pr_set_debug.md)
  has not been called, `debug` will default to
  [`interactive()`](https://rdrr.io/r/base/interactive.html) at
  `pr_run()` time

- docs:

  Visual documentation value to use while running the API. This value
  will only be used while running the router. If missing, defaults to
  information previously set with
  [`pr_set_docs()`](https://www.rplumber.io/reference/pr_set_docs.md).
  For more customization, see
  [`pr_set_docs()`](https://www.rplumber.io/reference/pr_set_docs.md)
  for examples.

- swaggerCallback:

  An optional single-argument function that is called back with the URL
  to an OpenAPI user interface when one becomes ready. If missing,
  defaults to information set with
  [`pr_set_docs_callback()`](https://www.rplumber.io/reference/pr_set_docs_callback.md).
  This value will only be used while running the router.

- quiet:

  If `TRUE`, don't print routine startup messages.

## Examples

``` r
if (FALSE) { # \dontrun{
pr() %>%
  pr_run()

pr() %>%
  pr_run(
    # manually set port
    port = 5762,
    # turn off visual documentation
    docs = FALSE,
    # do not display startup messages
    quiet = TRUE
  )
} # }
```
