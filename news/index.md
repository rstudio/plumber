# Changelog

## plumber 1.3.1

CRAN release: 2025-12-13

### New features

- `serializer_feather_stream()` and `parser_feather_stream()` now
  support [Arrow IPC
  Streams](https://arrow.apache.org/docs/format/Columnar.html#serialization-and-interprocess-communication-ipc)
  ([@josiahparry](https://github.com/josiahparry),
  [\#968](https://github.com/rstudio/plumber/issues/968)).

### Bug fixes and minor improvements

- [`pr_run()`](https://www.rplumber.io/reference/pr_run.md) now
  correctly honors the `apiPath` option when mounting documentation
  ([@thomasp85](https://github.com/thomasp85),
  [\#836](https://github.com/rstudio/plumber/issues/836)).

- Added CI testing for only depends packages by request of CRAN
  ([\#1006](https://github.com/rstudio/plumber/issues/1006)).

## plumber 1.3.0

CRAN release: 2025-02-19

- The port many now be specified as an environment variable.
  User-provided ports must be between 1024 and 49151 (following [IANA
  guidelines](https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml))
  and may not be a known unsafe port. plumber will now throw an error if
  an invalid port is requested.
  ([@shikokuchuo](https://github.com/shikokuchuo)
  [@gadenbuie](https://github.com/gadenbuie)
  [\#963](https://github.com/rstudio/plumber/issues/963))

- Added support for graphic devices provided by {ragg} and {svglite}
  ([@thomasp85](https://github.com/thomasp85)
  [\#964](https://github.com/rstudio/plumber/issues/964)).

- `parse_rds()`, `parse_feather()`, and `parse_parquet()` no longer
  writes data to disk during parsing
  ([@thomasp85](https://github.com/thomasp85),
  [\#942](https://github.com/rstudio/plumber/issues/942)).

- Returning error messages are now turned off by default rather than
  being turned on if running interactively and turned off if not
  ([@thomasp85](https://github.com/thomasp85),
  [\#962](https://github.com/rstudio/plumber/issues/962)).

- New serializers:

  - [`serializer_excel()`](https://www.rplumber.io/reference/serializers.md):
    Return an object serialized by
    [`writexl::write_xlsx`](https://docs.ropensci.org/writexl//reference/write_xlsx.html)
    ([@r2evans](https://github.com/r2evans),
    [\#973](https://github.com/rstudio/plumber/issues/973)).

- New request body parsers:

  - [`parser_excel()`](https://www.rplumber.io/reference/parsers.md):
    Parse request body as an excel workbook using
    [`readxl::read_excel`](https://readxl.tidyverse.org/reference/read_excel.html)
    ([@r2evans](https://github.com/r2evans),
    [\#973](https://github.com/rstudio/plumber/issues/973)). This
    defaults to loading in the first worksheet only, you can use
    `@parse excel list(sheet=NA)` to import all worksheets. This always
    returns a list of frames, even if there is just one worksheet.

- Mounts now have a dynamic `req$PATH_INFO` instead of a pre-computed
  value. ([\#888](https://github.com/rstudio/plumber/issues/888))

- [`validate_api_spec()`](https://www.rplumber.io/reference/validate_api_spec.md)
  now uses `@redocly/cli` to validate the API spec.
  ([\#986](https://github.com/rstudio/plumber/issues/986))

- Added `operationId` to each operation within the auto-generated
  OpenAPI output. The value is similar to the `PATH-VERB`,
  e.g. `/users/create-POST`.
  ([\#986](https://github.com/rstudio/plumber/issues/986))

- Added support for graphic devices provided by ragg and svglite
  ([@thomasp85](https://github.com/thomasp85)
  [\#964](https://github.com/rstudio/plumber/issues/964))

## plumber 1.2.2

CRAN release: 2024-03-25

- Allow to set plumber options using environment variables
  [`?options_plumber`](https://www.rplumber.io/reference/options_plumber.md).
  ([@meztez](https://github.com/meztez)
  [\#934](https://github.com/rstudio/plumber/issues/934))
- Add support for quoted boundary for multipart request parsing.
  ([@meztez](https://github.com/meztez)
  [\#924](https://github.com/rstudio/plumber/issues/924))
- Fix [\#916](https://github.com/rstudio/plumber/issues/916), related to
  `parseUTF8` return value attribute `srcfile` on Windows.
  ([\#930](https://github.com/rstudio/plumber/issues/930))

## plumber 1.2.1

CRAN release: 2022-09-06

- Update docs for CRAN
  ([\#878](https://github.com/rstudio/plumber/issues/878))

## plumber 1.2.0

CRAN release: 2022-07-09

### Breaking changes

- First line of endpoint comments interpreted as OpenAPI ‘summary’ field
  and subsequent comment lines interpreted as ‘description’ field.
  ([@wkmor1](https://github.com/wkmor1)
  [\#805](https://github.com/rstudio/plumber/issues/805))

### New features

- Static file handler now serves HEAD requests.
  ([\#798](https://github.com/rstudio/plumber/issues/798))

- Introduces new GeoJSON serializer and parser. GeoJSON objects are
  parsed into `sf` objects and `sf` or `sfc` objects will be serialized
  into GeoJSON. ([@josiahparry](https://github.com/josiahparry),
  [\#830](https://github.com/rstudio/plumber/issues/830))

- Add new Octet-Stream serializer. This is a wrapper around the Content
  Type serializer with type `application/octet-stream`.
  ([\#864](https://github.com/rstudio/plumber/issues/864))

- Update feather serializer to use the arrow package. The new default
  feather MIME type is `application/vnd.apache.arrow.file`.
  ([@pachadotdev](https://github.com/pachadotdev)
  [\#849](https://github.com/rstudio/plumber/issues/849))

- Add parquet serializer and parser by using the arrow package
  ([@pachadotdev](https://github.com/pachadotdev)
  [\#849](https://github.com/rstudio/plumber/issues/849))

- Updated example `14-future` to use
  [`promises::future_promise()`](https://rstudio.github.io/promises/reference/future_promise.html)
  and added an endpoint that uses [coro](https://github.com/r-lib/coro)
  to write *simpler* async /
  [promises](https://rstudio.github.io/promises/) code
  ([\#785](https://github.com/rstudio/plumber/issues/785))

- Add `path` argument to
  [`pr_cookie()`](https://www.rplumber.io/reference/pr_cookie.md)
  allowing Secure cookies to define where they are served
  ([@jtlandis](https://github.com/jtlandis)
  [\#850](https://github.com/rstudio/plumber/issues/850))

### Bug fixes

- OpenAPI specification collision when using `examples`.
  ([@meztez](https://github.com/meztez)
  [\#820](https://github.com/rstudio/plumber/issues/820))

- Static handler returns Last-Modified response header.
  ([\#798](https://github.com/rstudio/plumber/issues/798))

- OpenAPI response type detection had a scoping issue. Use serializer
  defined `Content-Type` header instead.
  ([@meztez](https://github.com/meztez),
  [\#789](https://github.com/rstudio/plumber/issues/789))

- The default shared secret filter returns error responses without
  throwing an error.
  ([\#808](https://github.com/rstudio/plumber/issues/808))

- Remove response bodies (and therefore the Content-Length header) for
  status codes which forbid it under the HTTP specification (e.g. 1xx,
  204, 304). ([@atheriel](https://github.com/atheriel)
  [\#758](https://github.com/rstudio/plumber/issues/758),
  [@meztez](https://github.com/meztez)
  [\#760](https://github.com/rstudio/plumber/issues/760))

- Decode path URI before attempting to serve static assets
  ([@meztez](https://github.com/meztez)
  [\#754](https://github.com/rstudio/plumber/issues/754)).

## plumber 1.1.0

CRAN release: 2021-03-24

### Breaking changes

- Force json serialization of endpoint error responses instead of using
  endpoint serializer. ([@meztez](https://github.com/meztez),
  [\#689](https://github.com/rstudio/plumber/issues/689))

- When plumbing a Plumber file and using a Plumber router modifier
  (`#* `[`@plumber`](https://github.com/plumber)), an error will be
  thrown if the original router is not returned.
  ([\#738](https://github.com/rstudio/plumber/issues/738))

- [`options_plumber()`](https://www.rplumber.io/reference/options_plumber.md)
  now requires that all options are named. If no option name is
  provided, an error with be thrown.
  ([\#746](https://github.com/rstudio/plumber/issues/746))

### New features

- Added option `plumber.trailingSlash`. This option (which is
  **disabled** by default) allows routes to be redirected to route
  definitions with a trailing slash. For example, if a `GET` request is
  submitted to `/test?a=1` with no `/test` route is defined, but a `GET`
  `/test/` route definition does exist, then the original request will
  respond with a `307` to reattempt against `GET` `/test/?a=1`. This
  option will be *enabled* by default in a future release. This logic
  executed for before calling the `404` handler.
  ([\#746](https://github.com/rstudio/plumber/issues/746))

- Added an experimental option `plumber.methodNotAllowed`. This option
  (which is enabled by default) allows for a status of `405` to be
  returned if an invalid method is used when requesting a valid route.
  This logic executed for before calling the default `404` handler.
  ([\#746](https://github.com/rstudio/plumber/issues/746))

- Passing `edit = TRUE` to
  [`plumb_api()`](https://www.rplumber.io/reference/plumb_api.md) will
  open the API source file.
  ([\#699](https://github.com/rstudio/plumber/issues/699))

- OpenAPI Specification can be set using a file path.
  ([@meztez](https://github.com/meztez)
  [\#696](https://github.com/rstudio/plumber/issues/696))

- Guess OpenAPI response content type from serializer.
  ([@meztez](https://github.com/meztez)
  [\#684](https://github.com/rstudio/plumber/issues/684))

- Undeprecated `Plumber$run(debug=, swaggerCallback=)` and added the
  parameters for `Plumber$run(docs=, quiet=)` and
  `pr_run(debug=, docs=, swaggerCallback=, quiet=)`. Now, all four
  parameters will not produce lingering effects on the `Plumber` router.
  ([@jcheng5](https://github.com/jcheng5)
  [\#765](https://github.com/rstudio/plumber/issues/765))

  - Setting `quiet = TRUE` will suppress routine startup messages.
  - Setting `debug = TRUE`, will display information when an error
    occurs. See
    [`pr_set_debug()`](https://www.rplumber.io/reference/pr_set_debug.md).
  - Setting `docs` will update the visual documentation. See
    [`pr_set_docs()`](https://www.rplumber.io/reference/pr_set_docs.md).
  - Set `swaggerCallback` to a function which will be called with a url
    to the documentation, or `NULL` to do nothing. See
    [`pr_set_docs_callback()`](https://www.rplumber.io/reference/pr_set_docs_callback.md).

- To update a `PlumberEndpoint` path after initialization, call the new
  `PlumberEndpoint$setPath(path)`. This will update internal path
  matching meta data. (Active bindings were not used to avoid breaking
  changes.) ([@blairj09](https://github.com/blairj09)
  [\#770](https://github.com/rstudio/plumber/issues/770))

- `PlumberStep` (and `PlumberEndpoint` and `PlumberFilter`) received a
  new field `$srcref` and method `$getFunc()`. `$srcref` will contain
  the corresponding `srcref` information from original source file.
  `$getFunc()` will return the evaluated function.
  ([\#782](https://github.com/rstudio/plumber/issues/782))

- Allow for spaces in `@apiTag` and `@tag` when tag is surrounded by
  single or double quotes.
  ([\#685](https://github.com/rstudio/plumber/issues/685))

### Bug fixes

- Ignore regular comments in block parsing.
  ([@meztez](https://github.com/meztez)
  [\#718](https://github.com/rstudio/plumber/issues/718))

- Block parsing comments, tags and responses ordering match plumber api
  ordering. ([\#722](https://github.com/rstudio/plumber/issues/722))

- Fixed bug where `httpuv` would return a status of `500` with body
  `An exception occurred` if no headers were set on the response object.
  ([\#745](https://github.com/rstudio/plumber/issues/745))

- Fixed bug where all `pr_*()` returned invisibly. Now all `pr_*()`
  methods will print the router if displayed in the console.
  ([\#740](https://github.com/rstudio/plumber/issues/740))

- When calling `Plumber$handle()` and defining a new `PlumberEndpoint`,
  `...` will be checked for invalid names.
  ([@meztez](https://github.com/meztez),
  [\#677](https://github.com/rstudio/plumber/issues/677))

- `/__swagger__/` now always redirects to `/__docs__/`, even when
  Swagger isn’t the selected interface. Use
  `options(plumber.legacyRedirects = FALSE)` to disable this behavior.
  ([@blairj09](https://github.com/blairj09)
  [\#694](https://github.com/rstudio/plumber/issues/694))

- Fixed
  [`available_apis()`](https://www.rplumber.io/reference/plumb_api.md)
  bug where all packages printed all available APIs.
  ([@meztez](https://github.com/meztez)
  [\#708](https://github.com/rstudio/plumber/issues/708))

- Fixed Plumber `$routes` resolution bugs. Routes are now returned in
  lexicographical order. ([@meztez](https://github.com/meztez)
  [\#702](https://github.com/rstudio/plumber/issues/702))

- Plumber will now display a circular reference if one is found while
  printing. ([\#738](https://github.com/rstudio/plumber/issues/738))

- Changed
  [`future::plan()`](https://future.futureverse.org/reference/plan.html)
  from `multiprocess` to `multisession` in example API `14-future` as
  “Strategy ‘multiprocess’ is deprecated in future (\>= 1.20.0)”.
  ([\#747](https://github.com/rstudio/plumber/issues/747))

- Setting options `plumber.docs.callback` to `NULL` will also set
  deprecated but supported option `plumber.swagger.url`.
  ([\#766](https://github.com/rstudio/plumber/issues/766))

## plumber 1.0.0

CRAN release: 2020-09-14

### New features

#### Plumber router

- Added support for promises in endpoints, filters, and hooks. This
  allows for multi-core execution when paired with `future`. See
  `plumb_api("plumber", "13-promises")` and
  `plumb_api("plumber", "14-future")` for example implementations.
  ([\#248](https://github.com/rstudio/plumber/issues/248))

- Added a Tidy API for more natural usage with magrittr’s `%>%`. For
  example, a plumber object can now be initiated and run with
  `pr() %>% pr_run(port = 8080)`. For more examples, see
  [here](https://www.rplumber.io/articles/programmatic-usage.html)
  ([@blairj09](https://github.com/blairj09),
  [\#590](https://github.com/rstudio/plumber/issues/590))

- Added support for `#' `[`@plumber`](https://github.com/plumber) tag to
  gain programmatic access to the `plumber` router via
  `function(pr) {....}`. See
  `system.file("plumber/06-sessions/plumber.R", package = "plumber")`
  and how it adds cookie support from within `plumber.R`.
  ([@meztez](https://github.com/meztez) and
  [@blairj09](https://github.com/blairj09),
  [\#568](https://github.com/rstudio/plumber/issues/568))

- Added [`plumb_api()`](https://www.rplumber.io/reference/plumb_api.md)
  for standardizing where to locate (`inst/plumber`) and how to run
  (`plumb_api(package, name)`) plumber apis inside an R package. To view
  the available Plumber APIs, call
  [`available_apis()`](https://www.rplumber.io/reference/plumb_api.md).
  ([\#631](https://github.com/rstudio/plumber/issues/631))

- Improved argument handling in Plumber Endpoint route definitions. See
  `system.file("plumber/17-arguments/plumber.R", package = "plumber")`
  to view an example with expected output and
  `plumb_api("plumber", "17-arguments")` to retrieve the api.
  Improvements include:

  - The value supplied to `req` and `res` arguments in a route
    definition are now *always* Plumber request and response objects. In
    the past, this was not guaranteed.
    ([\#666](https://github.com/rstudio/plumber/issues/666),
    [\#637](https://github.com/rstudio/plumber/issues/637))
  - To assist with conflicts in argument names deriving from different
    locations, `req$argsQuery`, `req$argsPath`, and `req$argsBody` have
    been added to access query, path, and `req$body` parameters,
    respectively. For this reason, we suggest defining routes with only
    `req` and `res` (i.e., `function(req, res) {}`) and accessing
    argument(s) under these new fields to avoid naming conflicts.
    ([\#637](https://github.com/rstudio/plumber/issues/637))
  - An error is no longer thrown if multiple arguments are matched to an
    Plumber Endpoint route definition. Instead, Plumber now retains the
    first named argument according to the highest priority match
    (`req$argsQuery` is 1st priority, then `req$argsPath`, then
    `req$argsBody`).
    ([\#666](https://github.com/rstudio/plumber/issues/666))
  - Unnamed elements that are added to `req$args` by filters or creating
    `req$argsBody` will no longer throw an error. They will only be
    passed through via `...`
    ([\#666](https://github.com/rstudio/plumber/issues/666))

#### OpenAPI

- API Documentation is now hosted at `/__docs__`. If `swagger`
  documentation is being used, `/__swagger__` will redirect to
  `/__docs__`. ([\#654](https://github.com/rstudio/plumber/issues/654))

- Added OpenAPI support for array parameters using syntax `name:[type]`
  and new type `list` (synonym df, data.frame).
  ([@meztez](https://github.com/meztez),
  [\#532](https://github.com/rstudio/plumber/issues/532))

- Added user provided OpenAPI Specification handler to Plumber router.
  Use `$setApiSpec()` to provide a function to alter the Plumber
  generated OpenAPI Specification returned by Plumber router method
  `$getApiSpec()`. This also affects `/openapi.json` and `/openapi.yaml`
  ([\#365](https://github.com/rstudio/plumber/issues/365))([@meztez](https://github.com/meztez),
  [\#562](https://github.com/rstudio/plumber/issues/562))

- Added
  [`validate_api_spec()`](https://www.rplumber.io/reference/validate_api_spec.md)
  to validate a Plumber API produces a valid OpenAPI Specification.
  (Experimental!)
  ([\#633](https://github.com/rstudio/plumber/issues/633))

#### Serializers

- Added `as_attachment(value, filename)` method which allows routes to
  return a file attachment with a custom name.
  ([\#585](https://github.com/rstudio/plumber/issues/585))

- Serializer functions can now return `PlumberEndpoint` `preexec` and
  `postexec` hooks in addition to a `serializer` function by using
  [`endpoint_serializer()`](https://www.rplumber.io/reference/endpoint_serializer.md).
  This allows for image serializers to turn on their corresponding
  graphics device before the route executes and turn the graphics device
  off after the route executes.
  ([\#630](https://github.com/rstudio/plumber/issues/630))

- PNG, JPEG, and SVG image serializers have been exported in methods
  [`serializer_png()`](https://www.rplumber.io/reference/serializers.md),
  [`serializer_jpeg()`](https://www.rplumber.io/reference/serializers.md),
  and
  [`serializer_svg()`](https://www.rplumber.io/reference/serializers.md)
  respectively. In addition to these methods,
  [`serializer_tiff()`](https://www.rplumber.io/reference/serializers.md),
  [`serializer_bmp()`](https://www.rplumber.io/reference/serializers.md),
  and
  [`serializer_pdf()`](https://www.rplumber.io/reference/serializers.md)
  have been added. Each graphics device serializer wraps around
  [`serializer_device()`](https://www.rplumber.io/reference/serializers.md),
  which should be used when making more graphics device serializers.
  ([\#630](https://github.com/rstudio/plumber/issues/630))

- New serializers

  - [`serializer_yaml()`](https://www.rplumber.io/reference/serializers.md):
    Return an object serialized by `yaml`
    ([@meztez](https://github.com/meztez),
    [\#556](https://github.com/rstudio/plumber/issues/556))
  - [`serializer_csv()`](https://www.rplumber.io/reference/serializers.md):
    Return a comma separated value
    ([@pachamaltese](https://github.com/pachamaltese),
    [\#520](https://github.com/rstudio/plumber/issues/520))
  - [`serializer_tsv()`](https://www.rplumber.io/reference/serializers.md):
    Return a tab separated value
    ([\#630](https://github.com/rstudio/plumber/issues/630))
  - [`serializer_feather()`](https://www.rplumber.io/reference/serializers.md):
    Return a object serialized by `feather`
    ([\#626](https://github.com/rstudio/plumber/issues/626))
  - [`serializer_text()`](https://www.rplumber.io/reference/serializers.md):
    Return text content
    ([\#585](https://github.com/rstudio/plumber/issues/585))
  - [`serializer_cat()`](https://www.rplumber.io/reference/serializers.md):
    Return text content after calling
    [`cat()`](https://rdrr.io/r/base/cat.html)
    ([\#585](https://github.com/rstudio/plumber/issues/585))
  - [`serializer_print()`](https://www.rplumber.io/reference/serializers.md):
    Return text content after calling
    [`print()`](https://rdrr.io/r/base/print.html)
    ([\#585](https://github.com/rstudio/plumber/issues/585))
  - [`serializer_format()`](https://www.rplumber.io/reference/serializers.md):
    Return text content after calling
    [`format()`](https://rdrr.io/r/base/format.html)
    ([\#585](https://github.com/rstudio/plumber/issues/585))
  - [`serializer_svg()`](https://www.rplumber.io/reference/serializers.md):
    Return an image saved as an SVG
    ([@pachamaltese](https://github.com/pachamaltese),
    [\#398](https://github.com/rstudio/plumber/issues/398))
  - `serializer_headers(header_list)`: Method which sets a list of
    static headers for each serialized value. Heavily inspired from
    [@ycphs](https://github.com/ycphs)
    ([\#455](https://github.com/rstudio/plumber/issues/455)).
    ([\#585](https://github.com/rstudio/plumber/issues/585))
  - [`serializer_write_file()`](https://www.rplumber.io/reference/serializers.md):
    Method which wraps
    [`serializer_content_type()`](https://www.rplumber.io/reference/serializers.md),
    but orchestrates creating, writing serialized content to, reading
    from, and removing a temp file.
    ([\#660](https://github.com/rstudio/plumber/issues/660))

#### Body parsing

- Added support for request body parsing
  ([@meztez](https://github.com/meztez),
  [\#532](https://github.com/rstudio/plumber/issues/532))

- New request body parsers

  - [`parser_csv()`](https://www.rplumber.io/reference/parsers.md):
    Parse request body as a commas separated value
    ([\#584](https://github.com/rstudio/plumber/issues/584))
  - [`parser_json()`](https://www.rplumber.io/reference/parsers.md):
    Parse request body as JSON ([@meztez](https://github.com/meztez),
    [\#532](https://github.com/rstudio/plumber/issues/532))
  - [`parser_multi()`](https://www.rplumber.io/reference/parsers.md):
    Parse multi part request bodies
    ([@meztez](https://github.com/meztez),
    [\#532](https://github.com/rstudio/plumber/issues/532)) and
    ([\#663](https://github.com/rstudio/plumber/issues/663))
  - [`parser_octet()`](https://www.rplumber.io/reference/parsers.md):
    Parse request body octet stream
    ([@meztez](https://github.com/meztez),
    [\#532](https://github.com/rstudio/plumber/issues/532))
  - [`parser_form()`](https://www.rplumber.io/reference/parsers.md):
    Parse request body as form input
    ([@meztez](https://github.com/meztez),
    [\#532](https://github.com/rstudio/plumber/issues/532))
  - [`parser_rds()`](https://www.rplumber.io/reference/parsers.md):
    Parse request body as RDS file input
    ([@meztez](https://github.com/meztez),
    [\#532](https://github.com/rstudio/plumber/issues/532))
  - [`parser_text()`](https://www.rplumber.io/reference/parsers.md):
    Parse request body plain text ([@meztez](https://github.com/meztez),
    [\#532](https://github.com/rstudio/plumber/issues/532))
  - [`parser_tsv()`](https://www.rplumber.io/reference/parsers.md):
    Parse request body a tab separated value
    ([\#584](https://github.com/rstudio/plumber/issues/584))
  - [`parser_yaml()`](https://www.rplumber.io/reference/parsers.md):
    Parse request body as `yaml`
    ([\#584](https://github.com/rstudio/plumber/issues/584))
  - [`parser_none()`](https://www.rplumber.io/reference/parsers.md): Do
    not parse the request body
    ([\#584](https://github.com/rstudio/plumber/issues/584))
  - [`parser_yaml()`](https://www.rplumber.io/reference/parsers.md):
    Parse request body ([@meztez](https://github.com/meztez),
    [\#556](https://github.com/rstudio/plumber/issues/556))
  - [`parser_feather()`](https://www.rplumber.io/reference/parsers.md):
    Parse request body using `feather`
    ([\#626](https://github.com/rstudio/plumber/issues/626))
  - Pseudo parser named `"all"` to allow for using all parsers. (Not
    recommended in production!)
    ([\#584](https://github.com/rstudio/plumber/issues/584))

- The parsed request body values is stored at `req$body`.
  ([\#663](https://github.com/rstudio/plumber/issues/663))

- If `multipart/*` content is parsed, `req$body` will contain named
  output from
  [`webutils::parse_multipart()`](https://jeroen.r-universe.dev/webutils/reference/parse_multipart.html)
  and add the parsed value to each part. Look here for access to all
  provided information (e.g., `name`, `filename`, `content_type`, etc).
  In addition, `req$argsBody` (which is used for route argument
  matching) will contain a named reduced form of this information where
  `parsed` values (and `filename`s) are combined on the same `name`.
  ([\#663](https://github.com/rstudio/plumber/issues/663))

#### Visual Documentation

- Generalize user interface integration. Plumber can now use other
  OpenAPI compatible user interfaces like `RapiDoc`
  (<https://github.com/mrin9/RapiDoc>) and `Redoc`
  (<https://github.com/Redocly/redoc>). Pending CRAN approbations,
  development R packages are available from
  <https://github.com/meztez/rapidoc/> and
  <https://github.com/meztez/redoc/>.
  ([@meztez](https://github.com/meztez),
  [\#562](https://github.com/rstudio/plumber/issues/562))

- Changed Swagger UI to use
  [swagger](https://github.com/rstudio/swagger) R package to display the
  swagger page. ([\#365](https://github.com/rstudio/plumber/issues/365))

- Added support for swagger for mounted routers
  ([@bradleyhd](https://github.com/bradleyhd),
  [\#274](https://github.com/rstudio/plumber/issues/274)).

### Security improvements

- Secret session cookies are now encrypted using `sodium`. All prior
  `req$session` information will be lost. Please see
  [`?session_cookie`](https://www.rplumber.io/reference/session_cookie.md)
  for more information.
  ([\#404](https://github.com/rstudio/plumber/issues/404))

- Session cookies set the `HttpOnly` flag by default to mitigate
  cross-site scripting (XSS). Please see
  [`?session_cookie`](https://www.rplumber.io/reference/session_cookie.md)
  for more information.
  ([\#404](https://github.com/rstudio/plumber/issues/404))

- Wrap
  [`jsonlite::fromJSON`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html)
  to ensure that `jsonlite` never reads input as a remote address (such
  as a file path or URL) and attempts to parse that. The only known way
  to exploit this behavior in plumber unless an API were using encrypted
  cookies and an attacker knew the encryption key in order to craft
  arbitrary cookies.
  ([\#325](https://github.com/rstudio/plumber/issues/325))

### Breaking changes

- When [`plumb()`](https://www.rplumber.io/reference/plumb.md)ing a file
  (or `Plumber$new(file)`), the working directory is set to the file’s
  directory before parsing the file. When running the Plumber API, the
  working directory will be set to file’s directory before
  running.([\#631](https://github.com/rstudio/plumber/issues/631))

- Plumber’s OpenAPI Specification is now defined using [OpenAPI
  3](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.3.md),
  upgrading from Swagger Specification.
  ([\#365](https://github.com/rstudio/plumber/issues/365))

- Plumber router `$run()` method arguments `swagger`, `swaggerCallback`
  and `debug` are now deprecated. User interface and url callback are
  now enabled by default and managed through Plumber router
  `$setDocs()`, `$setDocsCallback()`, and `$setDebug()` methods and
  options `plumber.docs` and `plumber.docs.callback`.
  ([@meztez](https://github.com/meztez),
  [\#562](https://github.com/rstudio/plumber/issues/562))

- [`plumb()`](https://www.rplumber.io/reference/plumb.md) now returns an
  object of class `"Plumber"` (previously `"plumber"`). To check if an
  object is a Plumber router, use new method
  [`is_plumber()`](https://www.rplumber.io/reference/is_plumber.md).
  ([\#653](https://github.com/rstudio/plumber/issues/653))

- `PlumberStatic` objects now have a class of `"PlumberStatic"`
  (previously `"plumberstatic"`).
  ([\#653](https://github.com/rstudio/plumber/issues/653))

- The source files used in plumber **must use** the UTF-8 encoding if
  they contain non-ASCII characters
  ([@shrektan](https://github.com/shrektan),
  [\#312](https://github.com/rstudio/plumber/issues/312),
  [\#328](https://github.com/rstudio/plumber/issues/328)).

- `options(plumber.debug)` is not set anymore when running the plumber
  application. Instead retrieve the debug value using `$getDebug()` on
  the Plumber router directly. Ex:
  `function(req, res) { req$pr$getDebug() }`.
  ([\#639](https://github.com/rstudio/plumber/issues/639))

- `PlumberEndpoint`’s method `$exec()` now has a shape of
  `$exec(req, res)` (vs `$exec(...)`). This allows for fine tune control
  over the arguments being sent to the endpoint function.

- When creating a `PlumberFilter` or `PlumberEndpoint`, an error will be
  thrown if `expr` does not evaluate to a function.
  ([\#666](https://github.com/rstudio/plumber/issues/666))

### Deprecations

- Shorthand serializers are now deprecated. `@html`, `@json`, `@png`,
  `@jpeg`, `@svg` should be replaced with the `@serializer` syntax. Ex:
  `@serializer html` or `@serializer jpeg`
  ([\#630](https://github.com/rstudio/plumber/issues/630))

- `plumber` R6 object has been deprecated and renamed to `Plumber`.
  `PlumberStatic`’s `inherit`ed class has been updated to `Plumber`.
  ([\#653](https://github.com/rstudio/plumber/issues/653))

- `hookable` R6 object has been deprecated and renamed to `Hookable`.
  `Plumber` and `PlumberStep`’s `inherit`ed class has been updated to
  `Hookable`. ([\#653](https://github.com/rstudio/plumber/issues/653))

- [`addSerializer()`](https://www.rplumber.io/reference/deprecated.md)
  has been deprecated in favor of
  [`register_serializer()`](https://www.rplumber.io/reference/register_serializer.md)
  ([\#584](https://github.com/rstudio/plumber/issues/584))

- [`getCharacterSet()`](https://www.rplumber.io/reference/deprecated.md)
  has been deprecated in favor of
  [`get_character_set()`](https://www.rplumber.io/reference/get_character_set.md)
  ([\#651](https://github.com/rstudio/plumber/issues/651))

- `randomCookieKey()` has been deprecated in favor of
  [`random_cookie_key()`](https://www.rplumber.io/reference/random_cookie_key.md)
  ([\#651](https://github.com/rstudio/plumber/issues/651))

- [`sessionCookie()`](https://www.rplumber.io/reference/deprecated.md)
  has been deprecated in favor of
  [`session_cookie()`](https://www.rplumber.io/reference/session_cookie.md)
  ([\#651](https://github.com/rstudio/plumber/issues/651))

- DigitalOcean helper functions are now defunct (`do_*()`). The
  functionality and documentation on how to deploy to DigitalOcean has
  been moved to
  [`plumberDeploy`](https://github.com/meztez/plumberDeploy) (by
  [@meztez](https://github.com/meztez))
  ([\#649](https://github.com/rstudio/plumber/issues/649))

### Minor new features and improvements

- Documentation is updated and now presented using `pkgdown`
  ([\#570](https://github.com/rstudio/plumber/issues/570))

- New hex logo! Thank you
  [@allisonhorst](https://github.com/allisonhorst) !
  ([\#570](https://github.com/rstudio/plumber/issues/570))

- Added helper method `is_plumber(pr)` to determine if an object is a
  Plumber router.
  ([\#653](https://github.com/rstudio/plumber/issues/653))

- Added support for the `SameSite` Cookie attribute.
  ([@chris-dudley](https://github.com/chris-dudley),
  [\#640](https://github.com/rstudio/plumber/issues/640))

- When calling
  [`include_file()`](https://www.rplumber.io/reference/include_file.md),
  the `content_type` is automatically inferred from the file extension
  if `content_type` is not provided.
  ([\#631](https://github.com/rstudio/plumber/issues/631))

- When [`plumb()`](https://www.rplumber.io/reference/plumb.md)ing a
  file, arguments supplied to parsers and serializers may be values
  defined earlier in the file. ([@meztez](https://github.com/meztez),
  [\#620](https://github.com/rstudio/plumber/issues/620))

- Updated Docker files. New Docker repo is now
  [`rstudio/plumber`](https://hub.docker.com/r/rstudio/plumber/tags).
  Updates heavily inspired from
  [@mskyttner](https://github.com/mskyttner)
  ([\#459](https://github.com/rstudio/plumber/issues/459)).
  ([\#589](https://github.com/rstudio/plumber/issues/589))

- Support HTTP 405 Code. ([@meztez](https://github.com/meztez),
  [\#554](https://github.com/rstudio/plumber/issues/554))

- Attached the Plumber router to the incoming request object at
  `req$pr`. ([@meztez](https://github.com/meztez),
  [\#554](https://github.com/rstudio/plumber/issues/554))

- Documented plumber options. Added
  [`options_plumber()`](https://www.rplumber.io/reference/options_plumber.md).
  ([@meztez](https://github.com/meztez),
  [\#555](https://github.com/rstudio/plumber/issues/555))

- Update documentation on R6 objects
  ([@meztez](https://github.com/meztez),
  [\#530](https://github.com/rstudio/plumber/issues/530))

- Fix [`plumb()`](https://www.rplumber.io/reference/plumb.md) function
  when [`plumb()`](https://www.rplumber.io/reference/plumb.md)ing a
  directory so that `plumber.R` is not a requirement if a valid
  `entrypoint.R` file is found.
  ([@blairj09](https://github.com/blairj09),
  [\#471](https://github.com/rstudio/plumber/issues/471)).

- If cookie information is too large (\> 4093 bytes), a warning will be
  displayed. ([\#404](https://github.com/rstudio/plumber/issues/404))

- Added new shorthand types for url parameters.
  ([@byzheng](https://github.com/byzheng),
  [\#388](https://github.com/rstudio/plumber/issues/388))

- Plumber files are now only evaluated once. Prior plumber behavior
  sourced endpoint functions twice and non-endpoint code blocks once.
  ([\#328](https://github.com/rstudio/plumber/issues/328))

- Improve speed of `canServe()` method of the `PlumberEndpoint` class
  ([@atheriel](https://github.com/atheriel),
  [\#484](https://github.com/rstudio/plumber/issues/484))

- Get more file extension content types using the `mime` package.
  ([\#660](https://github.com/rstudio/plumber/issues/660))

- Endpoints that produce images within a
  [`promises::promise()`](https://rstudio.github.io/promises/reference/promise.html)
  will now use the expected graphics device.
  ([\#669](https://github.com/rstudio/plumber/issues/669))

### Bug fixes

- Handle plus signs in URI as space characters instead of actual plus
  signs ([@meztez](https://github.com/meztez),
  [\#618](https://github.com/rstudio/plumber/issues/618))

- Paths that are missing a leading `/` have a `/` prepended to the path
  location. ([\#656](https://github.com/rstudio/plumber/issues/656))

- Fix possible bugs due to mounted routers without leading slashes
  ([@atheriel](https://github.com/atheriel),
  [\#476](https://github.com/rstudio/plumber/issues/476)
  [\#501](https://github.com/rstudio/plumber/issues/501)).

- Modified images serialization to use content-type serializer. Fixes
  issue with images pre/postserialize hooks
  ([@meztez](https://github.com/meztez),
  [\#518](https://github.com/rstudio/plumber/issues/518)).

- Fix bug preventing error handling when a serializer fails
  ([@antoine-sachet](https://github.com/antoine-sachet),
  [\#490](https://github.com/rstudio/plumber/issues/490))

- Fix URL-decoding of query parameters and URL-encoding/decoding of
  cookies. Both now use
  [`httpuv::decodeURIComponent`](https://rdrr.io/pkg/httpuv/man/encodeURI.html)
  instead of
  [`httpuv::decodeURI`](https://rdrr.io/pkg/httpuv/man/encodeURI.html).
  ([@antoine-sachet](https://github.com/antoine-sachet),
  [\#462](https://github.com/rstudio/plumber/issues/462))

- Fixed bug where functions defined earlier in the file could not be
  found when [`plumb()`](https://www.rplumber.io/reference/plumb.md)ing
  a file. ([\#416](https://github.com/rstudio/plumber/issues/416))

- A multiline request body is now collapsed to a single line
  ([@robertdj](https://github.com/robertdj),
  [\#270](https://github.com/rstudio/plumber/issues/270)
  [\#297](https://github.com/rstudio/plumber/issues/297)).

- Bumped version of httpuv to \>= 1.4.5.9000 to address an unexpected
  segfault ([@shapenaji](https://github.com/shapenaji),
  [\#289](https://github.com/rstudio/plumber/issues/289))

- Date response header is now supplied by httpuv and not plumber. Fixes
  non standard date response header issues when using different locales.
  ([@shrektan](https://github.com/shrektan),
  [\#319](https://github.com/rstudio/plumber/issues/319),
  [\#380](https://github.com/rstudio/plumber/issues/380))

- Due to incompatibilities with `multipart` body values, `req$postBody`
  will only be calculated if accessed. It is strongly recommended to use
  `req$bodyRaw` when trying to create content from the input body.
  ([\#665](https://github.com/rstudio/plumber/issues/665))

## plumber 0.4.6

CRAN release: 2018-06-05

- BUGFIX: Hooks that accept a `value` argument (`postroute`,
  `preserialize`, and `postserialize`) now modify the incoming value as
  documented.
- BUGFIX: The `postserialize` hook is now given the serialized data as
  its `value` parameter.
- BUGFIX: properly handle cookie expiration values
  ([\#216](https://github.com/rstudio/plumber/issues/216)).
- Add support for tags in Swagger docs
  ([\#230](https://github.com/rstudio/plumber/issues/230)).
- Optional `swaggerCallback` parameter for `run()` to supply a callback
  function for reporting the url for swagger page.
- Add [RStudio Project
  Template](https://rstudio.github.io/rstudio-extensions/rstudio_project_templates.html)
  to package.

## plumber 0.4.4

CRAN release: 2017-12-01

- Support Expiration, HTTPOnly, and Secure flags on cookies
  ([\#87](https://github.com/rstudio/plumber/issues/87)). **EDIT**: see
  [\#216](https://github.com/rstudio/plumber/issues/216) which prevented
  expiration from working.
- BUGFIX: properly handle named query string and post body arguments in
  mounted subrouters.
- Added support for static sizing of images. `@png` and `@jpeg` now
  accept a parenthetical list of arguments that will be passed into the
  [`png()`](https://rdrr.io/r/grDevices/png.html) or
  [`jpeg()`](https://rdrr.io/r/grDevices/png.html) call. This enables
  annotations like
  `#' `[`@png`](https://github.com/png)` (width = 200, height=500)`.
- Enable `ByteCompile` flag
- Set working directory for DigitalOcean APIs.
- Respect `setErrorHandler`
- BUGFIX: export `PlumberStatic`
- Case-insensitive matching on `plumber.r` and `entrypoint.r` when
  [`plumb()`](https://www.rplumber.io/reference/plumb.md)ing a
  directory.
- Support query strings with keys that appear more than once
  ([\#165](https://github.com/rstudio/plumber/issues/165))
- Fix the validation error warning at the bottom of deployed Swagger
  files which would have appeared any time your `swagger.json` file was
  hosted in such a way that a hosted validator service would not have
  been able to access it. For now we just suppress validation of
  swagger.json files.
  ([\#149](https://github.com/rstudio/plumber/issues/149))
- Support for floating IPs in DNS check that occurs in
  [`do_configure_https()`](https://www.rplumber.io/reference/digitalocean.md)
- Make adding swap file idempotent in
  [`do_provision()`](https://www.rplumber.io/reference/digitalocean.md)
  so you can now call that on a single droplet multiple times.
- Support an `exit` hook which can define a function that will be
  evaluated when the API is interrupted. e.g.
  `pr <- plumb("plumber.R"); pr$registerHook("exit", function(){ print("Bye bye!") })`
- Fixed bug in which a single function couldn’t support multiple paths
  for a single verb
  ([\#203](https://github.com/rstudio/plumber/issues/203)).
- Support negative numbers in numeric path segments
  ([\#212](https://github.com/rstudio/plumber/issues/212))
- Support `.` in string path segments

## plumber 0.4.2

CRAN release: 2017-07-24

- Development version for 0.4.2. Will be working to move to even/odd
  release cycles, but I had prematurely bumped to 0.4.0 so that one
  might get skipped, making the next CRAN release 0.4.2.

## plumber 0.4.0

- BREAKING: Listen on localhost instead of listening publicly by
  default.
- BREAKING: We no longer set the `Access-Control-Allow-Origin` HTTP
  header to `*`. This was previously done for convenience but we’ve
  decided to prioritize security here by removing this default. You can
  still add this header to any route you want to be accessible from
  other origins.
- BREAKING: Listen on a random port by default instead of always
  on 8000. This can be controlled using the `port` parameter in `run()`,
  or by setting the `plumber.port` option.
- BREAKING: Removed `PlumberProcessor` class and replaced with a notion
  of hooks. See `registerHook` and `registerHooks` on the Plumber
  router.
- BREAKING: `addGlobalProcessor` method on Plumber routers now takes a
  list which are added as hooks instead of a Processor. Note that
  `sessionCookie` has also been updated to behave accordingly, meaning
  that the convention of
  `pr$addGlobalProcessor(sessionCookie("secret", "cookieName"))` will
  continue to work for this release.
- BREAKING: `sessionCookie` now returns a list instead of a Processor.
  Note that `addGlobalProcessor` has also been updated to behave
  accordingly, meaning that the convention of
  `pr$addGlobalProcessor(sessionCookie("secret", "cookieName"))` will
  continue to work for this release.
- DEPRECATION: Deprecated the `addAssets` method on Plumber routers. Use
  `PlumberStatic` and the `mount` method to attach a static router.
- DEPRECATION: Deprecated the `addEndpoint` method in favor of the
  `handle` method for Plumber routers. Removed support for the
  `processors`, `params`, and `comments` parameters are no longer
  supported.
- DEPRECATION: Deprecated the `addFilter` method on Plumber routers in
  favor of the new `filter` method. Removed support for the processor
  parameter.
- DEPRECATION: Deprecated the `addGlobalProcessor` method on Plumber
  routers.
- The undocumented `setDefaultErrorHandler` method on Plumber routers
  now takes a function that returns the error handler function. The
  top-level function takes a single param named `debug` which is managed
  by the `debug` parameter in the `run()` method.
- Added support for `OPTIONS` HTTP requests via the `@options`
  annotation.
- Add support for `entrypoint.R` when
  [`plumb()`](https://www.rplumber.io/reference/plumb.md)ing a
  directory. If this file exists, it is expected to return a Plumber
  router representing the API contained in this directory. If it doesn’t
  exist, the behavior is unaltered. If both `plumber.R` and
  `entrypoint.R` exist, `entrypoint.R` takes precedence.
- [`plumb()`](https://www.rplumber.io/reference/plumb.md) the current
  directory by default if no arguments are provided.
- Added a `debug` parameter to the `run` method which can be set to
  `TRUE` in order to get more insight into your API errors.

## plumber 0.3.3

- [`plumb()`](https://www.rplumber.io/reference/plumb.md) now accepts an
  argument `dir`, referring to a directory containing `plumber.R`, which
  may be provided instead of `file`.

## plumber 0.3.2

CRAN release: 2017-05-22

- Introduced the
  [`do_provision()`](https://www.rplumber.io/reference/digitalocean.md),
  [`do_deploy_api()`](https://www.rplumber.io/reference/digitalocean.md),
  [`do_remove_api()`](https://www.rplumber.io/reference/digitalocean.md)
  and
  [`do_configure_https()`](https://www.rplumber.io/reference/digitalocean.md)
  functions to provision and manage your APIs on a cloud server running
  on DigitalOcean.
- [`source()`](https://rdrr.io/r/base/source.html) the referenced R file
  to plumb inside of a new environment that inherits directly from the
  GlobalEnv. This provides more explicit control over exactly how this
  environment should behave.
- Added `@serializer htmlwidget` to support rendering and returning a
  self-contained htmlwidget from a plumber endpoint.
- Properly handle cookies with no value.
  ([\#88](https://github.com/rstudio/plumber/issues/88))
- Don’t convert `+` character in a query string to a space.

## plumber 0.3.1

CRAN release: 2016-10-04

- Add a method to consume JSON on post (you can still send a query
  string in the body of a POST request as well).

## plumber 0.3.0

- BREAKING CHANGE: serializer factories are now registered instead of
  the serializer themselves. Thus,
  [`addSerializer()`](https://www.rplumber.io/reference/deprecated.md)
  now expects a function that returns a serializer, and `Response$new()`
  now expects a serializer itself rather than a character string naming
  a serializer. Internally it is the serializer itself that is attached
  to the response rather than the name of the serializer. This allows
  for a serializer to customize its behavior.
- Accept an additional argument on the `@serializer` annotation – R code
  that will be passed in as an argument to the serializer factory. See
  example `09-content-type`.

## plumber 0.2.4

CRAN release: 2016-04-14

- Add a filter which parses and sets req\$cookies to be a list
  corresponding to the cookies provided with the request.
- Responses can set multiple cookies
- Bug Fix: convert non-character arguments in setCookie to character
  before URL- encoding.

## plumber 0.2.3

- Set options(warn=1) during execution of user code so that warnings are
  immediately visible in the console, rather than storing them until the
  server is stopped.

## plumber 0.2.2

- Add `sessionCookie` function to define a processor that can be used as
  a globalProcessor on a router to encrypt values from req\$session and
  store them as an encrypted cookie in on the user’s browser.
- Added `setCookie` method to response which (primitively) allows you to
  set a cookie to be included in the response.
- Add `addGlobalProcessor` method on `plumber` class to support a
  processor that runs a processor only a single time, before and then
  after all other filters and the endpoint.
- Document all public params so CHECK passes

## plumber 0.2.1

- Add more `roxygen2` documentation for exported functions
- Remove the warning in the README as the API seems to be stabilizing.

## plumber 0.2.0

- BREAKING: Changed variable-path routing to use bracketed format
  instead of just a colon.
- BREAKING: Renamed `PlumberRouter` R6 object to just `Plumber`.
- Support `addEndpoint()` and `addFilter()` on the `Plumber` object.
- Added support for the `#*` prefix.

## plumber 0.1.0

- Initial Release
