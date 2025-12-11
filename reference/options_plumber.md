# Plumber options

There are a number of global options that affect Plumber's behavior.
These can be set globally with
[`options()`](https://rdrr.io/r/base/options.html) or with
`options_plumber()`. Options set using `options_plumber()` should not
include the `plumber.` prefix. Alternatively, environment variable can
be used to set plumber options using uppercase and underscores (i.e. to
set `plumber.apiHost` you can set environment variable
`PLUMBER_APIHOST`).

## Usage

``` r
options_plumber(
  ...,
  port = getOption("plumber.port"),
  docs = getOption("plumber.docs"),
  docs.callback = getOption("plumber.docs.callback"),
  trailingSlash = getOption("plumber.trailingSlash"),
  methodNotAllowed = getOption("plumber.methodNotAllowed"),
  apiURL = getOption("plumber.apiURL"),
  apiScheme = getOption("plumber.apiScheme"),
  apiHost = getOption("plumber.apiHost"),
  apiPort = getOption("plumber.apiPort"),
  apiPath = getOption("plumber.apiPath"),
  maxRequestSize = getOption("plumber.maxRequestSize"),
  sharedSecret = getOption("plumber.sharedSecret"),
  legacyRedirects = getOption("plumber.legacyRedirects")
)

get_option_or_env(x, default = NULL)
```

## Arguments

- ...:

  Ignored. Should be empty

- port, docs, docs.callback, trailingSlash, methodNotAllowed, apiScheme,
  apiHost, apiPort, apiPath, apiURL, maxRequestSize, sharedSecret,
  legacyRedirects:

  See details

- x:

  a character string holding an option name.

- default:

  if the specified option is not set in the options list, this value is
  returned. This facilitates retrieving an option and checking whether
  it is set and setting it separately if not.

## Value

The complete, prior set of
[`options()`](https://rdrr.io/r/base/options.html) values. If a
particular parameter is not supplied, it will return the current value.
If no parameters are supplied, all returned values will be the current
[`options()`](https://rdrr.io/r/base/options.html) values.

## Details

- `plumber.port`:

  Port Plumber will attempt to use to start http server. If the port is
  already in use, server will not be able to start. Defaults to `NULL`.

- `plumber.docs`:

  Name of the visual documentation interface to use. Defaults to `TRUE`,
  which will use `"swagger"`.

- `plumber.docs.callback`:

  A function. Called with a single parameter corresponding to the visual
  documentation url after Plumber server is ready. This can be used by
  RStudio to open the docs when then API is ran from the editor.
  Defaults to option `NULL`.

- `plumber.trailingSlash`:

  Logical value which allows the router to redirect any request that has
  a matching route with a trailing slash. For example, if set to `TRUE`
  and the GET route `/test/` existed, then a GET request of `/test?a=1`
  would redirect to `/test/?a=1`. Defaults to `FALSE`. This option will
  default to `TRUE` in a future release.

- `plumber.methodNotAllowed`:

  **\[experimental\]** Logical value which allows the router to notify
  that an unavailable method was requested, but a different request
  method is allowed. For example, if set to `TRUE` and the GET route
  `/test` existed, then a POST request of `/test` would receive a 405
  status and the allowed methods. Defaults to `TRUE`.

- `plumber.apiURL`:

  Server urls for OpenAPI Specification respecting pattern
  `scheme://host:port/path`. Other `api*` options will be ignored when
  set.

- `plumber.apiScheme`:

  Scheme used to build OpenAPI url and server url for OpenAPI
  Specification. Defaults to `http`, or an empty string when used
  outside a running router.

- `plumber.apiHost`:

  Host used to build docs url and server url for OpenAPI Specification.
  Defaults to `host` defined by `run` method, or an empty string when
  used outside a running router.

- `plumber.apiPort`:

  Port used to build OpenAPI url and server url for OpenAPI
  Specification. Defaults to `port` defined by `run` method, or an empty
  string when used outside a running router.

- `plumber.apiPath`:

  Path used to build OpenAPI url and server url for OpenAPI
  Specification. Defaults to an empty string.

- `plumber.maxRequestSize`:

  Maximum length in bytes of request body. Body larger than maximum are
  rejected with http error 413. `0` means unlimited size. Defaults to
  `0`.

- `plumber.sharedSecret`:

  Shared secret used to filter incoming request. When `NULL`, secret is
  not validated. Otherwise, Plumber compares secret with http header
  `PLUMBER_SHARED_SECRET`. Failure to match results in http error 400.
  Defaults to `NULL`.

- `plumber.legacyRedirects`:

  Plumber will redirect legacy route `/__swagger__/` and
  `/__swagger__/index.html` to `../__docs__/` and
  `../__docs__/index.html`. You can disable this by settings this option
  to `FALSE`. Defaults to `TRUE`
