plumber (version)
--------------------------------------------------------------------------------

### New features

* CSV (UTF-8) serialization (@pachamaltese, #520)
* SVG (UTF-8) serialization (@pachamaltese, #398)

### Bug fixes

* Fix `plumb()` function when `plumb()`ing a directory so that `plumber.R` is
  not a requirement if a valid `entrypoint.R` file is found. 
  (@blairj09, [#471](https://github.com/trestletech/plumber/pull/471)).
  

plumber 0.5.0
--------------------------------------------------------------------------------
## Full changelog

### Security

* Secret session cookies are now encrypted using `sodium`.
  All prior `req$session` information will be lost.
  Please see `?sessionCookie` for more information.
  (#404)

* Session cookies set the `HttpOnly` flag by default to mitigate cross-site scripting (XSS).
  Please see `?sessionCookie` for more information.
  (#404)

* Wrap `jsonlite::fromJSON` to ensure that `jsonlite` never reads
  input as a remote address (such as a file path or URL) and attempts to parse
  that. The only known way to exploit this behavior in plumber unless an
  API were using encrypted cookies and an attacker knew the encryption key in
  order to craft arbitrary cookies. (#325)

### Breaking changes

* Plumber's swagger definition is now defined using
  [OpenAPI 3](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md),
  upgrading from Swagger Specification. (#365)

* The source files used in plumber **must use** the UTF-8 encoding if they contain
  non-ASCII characters (@shrektan, #312,
  #328).

* R repository modified to `focal-cran40` using Ubuntu 20.04 LTS for digital ocean provisioning (@meztez, #529)

### New features

* Document plumber options. Add `options_plumber`. (@meztez, #555)

* Add yaml support, serializer and parser. (@meztez, #556)

* Added Swagger support for array parameters using syntax `name:[type]` and new type `list` (synonym df, data.frame). (@meztez, #532) 

* Added support for promises in endpoints, filters, and hooks. (#248)

* Added support to a router's run method to allow the `swagger` parameter to be a function that
  enhances the existing swagger specification before being returned to `/openapi.json`. (#365)

* Add support for swagger for mounted routers (@bradleyhd, #274).


### Minor new features and improvements

* Update documentation on R6 objects (@meztez, #530)

* If cookie information is too large (> 4093 bytes), a warning will be displayed. (#404)

* Added new shorthand types for url parameters. (@byzheng, #388)

* Changed Swagger UI to use [swagger](https://github.com/rstudio/swagger) R package to display the
    swagger page. (#365)

* Plumber files are now only evaluated once.  Prior plumber behavior sourced endpoint
  functions twice and non-endpoint code blocks once.
  (#328)

* Improve speed of `canServe()` method of the `PlumberEndpoint` class (@atheriel, #484)

* Add support for returning svg images using `#' @svg` (and with arguments `#' @svg (width = 200, height=500)`. (@pachamaltese, #398)

### Bug fixes

* Modified images serialization to use content-type serializer. Fixes issue with images pre/postserialize hooks (@meztez, #518).

* Fix possible bugs due to mounted routers without leading slashes (@atheriel, #476 #501).

* Fix bug preventing error handling when a serializer fails (@antoine-sachet, #490)

* Fix URL-decoding of query parameters and URL-encoding/decoding of cookies. Both now use `httpuv::decodeURIComponent` instead of `httpuv::decodeURI`. (@antoine-sachet, #462)

* Fix bugs that prevented `do_provision` from deploying to DigitalOcean and updated to the latest `analogsea`.  (#448)

* Fixed bug where functions defined earlier in the file could not be found when `plumb()`ing a file.  (#416)

* A multiline POST body is now collapsed to a single line (@robertdj, #270 #297).

* Bumped version of httpuv to >= 1.4.5.9000 to address an unexpected segfault (@shapenaji, #289)

* Date response header is now supplied by httpuv and not plumber. Fixes non standard date response header issues when using different locales. (@shrektan, #319, #380)


plumber 0.4.6
--------------------------------------------------------------------------------
* BUGFIX: Hooks that accept a `value` argument (`postroute`, `preserialize`,
  and `postserialize`) now modify the incoming value as documented.
* BUGFIX: The `postserialize` hook is now given the serialized data as its
  `value` parameter.
* BUGFIX: properly handle cookie expiration values (#216).
* Add support for tags in Swagger docs (#230).
* Optional `swaggerCallback` parameter for `run()` to supply a callback function
  for reporting the url for swagger page.
* Add [RStudio Project Template](https://rstudio.github.io/rstudio-extensions/rstudio_project_templates.html) to package.


plumber 0.4.4
--------------------------------------------------------------------------------
* Support Expiration, HTTPOnly, and Secure flags on cookies (#87). **EDIT**:
  see #216 which prevented
  expiration from working.
* BUGFIX: properly handle named query string and post body arguments in
  mounted subrouters.
* Added support for static sizing of images. `@png` and `@jpeg` now accept a
  parenthetical list of arguments that will be passed into the `png()` or
  `jpeg()` call. This enables annotations like
  `#' @png (width = 200, height=500)`.
* Enable `ByteCompile` flag
* Set working directory for DigitalOcean APIs.
* Respect `setErrorHandler`
* BUGFIX: export `PlumberStatic`
* Case-insensitive matching on `plumber.r` and `entrypoint.r` when
  `plumb()`ing a directory.
* Support query strings with keys that appear more than once
  (#165)
* Fix the validation error warning at the bottom of deployed Swagger files
  which would have appeared any time your `swagger.json` file was hosted in
  such a way that a hosted validator service would not have been able to access
  it. For now we just suppress validation of swagger.json files. (#149)
* Support for floating IPs in DNS check that occurs in `do_configure_https()`
* Make adding swap file idempotent in `do_provision()` so you can now call that
  on a single droplet multiple times.
* Support an `exit` hook which can define a function that will be
  evaluated when the API is interrupted. e.g.
  `pr <- plumb("plumber.R"); pr$registerHook("exit", function(){ print("Bye bye!") })`
* Fixed bug in which a single function couldn't support multiple paths for a
  single verb (#203).
* Support negative numbers in numeric path segments (#212)
* Support `.` in string path segments


plumber 0.4.2
--------------------------------------------------------------------------------
* Development version for 0.4.2. Will be working to move to even/odd release
  cycles, but I had prematurely bumped to 0.4.0 so that one might get skipped,
  making the next CRAN release 0.4.2.


plumber 0.4.0
--------------------------------------------------------------------------------
* BREAKING: Listen on localhost instead of listening publicly by default.
* BREAKING: We no longer set the `Access-Control-Allow-Origin` HTTP header to
  `*`. This was previously done for convenience but we've decided to prioritize
  security here by removing this default. You can still add this header to any
  route you want to be accessible from other origins.
* BREAKING: Listen on a random port by default instead of always on 8000. This
  can be controlled using the `port` parameter in `run()`, or by setting the
  `plumber.port` option.
* BREAKING: Removed `PlumberProcessor` class and replaced with a notion of
  hooks. See `registerHook` and `registerHooks` on the Plumber router.
* BREAKING: `addGlobalProcessor` method on Plumber routers now takes a list
  which are added as hooks instead of a Processor. Note that `sessionCookie`
  has also been updated to behave accordingly, meaning that the convention of
  `pr$addGlobalProcessor(sessionCookie("secret", "cookieName"))` will continue
  to work for this release.
* BREAKING: `sessionCookie` now returns a list instead of a Processor. Note
  that `addGlobalProcessor` has also been updated to behave accordingly,
  meaning that the convention of
  `pr$addGlobalProcessor(sessionCookie("secret", "cookieName"))` will continue
  to work for this release.
* DEPRECATION: Deprecated the `addAssets` method on Plumber routers. Use
  `PlumberStatic` and the `mount` method to attach a static router.
* DEPRECATION: Deprecated the `addEndpoint` method in favor of the `handle`
  method for Plumber routers. Removed support for the `processors`, `params`,
  and `comments` parameters are no longer supported.
* DEPRECATION: Deprecated the `addFilter` method on Plumber routers in favor
  of the new `filter` method. Removed support for the processor parameter.
* DEPRECATION: Deprecated the `addGlobalProcessor` method on Plumber routers.
* The undocumented `setDefaultErrorHandler` method on Plumber routers now takes
  a function that returns the error handler function. The top-level function
  takes a single param named `debug` which is managed by the `debug` parameter
  in the `run()` method.
* Added support for `OPTIONS` HTTP requests via the `@options` annotation.
* Add support for `entrypoint.R` when `plumb()`ing a directory. If this file
  exists, it is expected to return a Plumber router representing the API
  contained in this directory. If it doesn't exist, the behavior is unaltered.
  If both `plumber.R` and `entrypoint.R` exist, `entrypoint.R` takes precedence.
* `plumb()` the current directory by default if no arguments are provided.
* Added a `debug` parameter to the `run` method which can be set to `TRUE` in
  order to get more insight into your API errors.


plumber 0.3.3
--------------------------------------------------------------------------------
* `plumb()` now accepts an argument `dir`, referring to a directory containing
  `plumber.R`, which may be provided instead of `file`.


plumber 0.3.2
--------------------------------------------------------------------------------
* Introduced the `do_provision()`, `do_deploy_api()`, `do_remove_api()` and
  `do_configure_https()` functions to provision and manage your APIs on a
   cloud server running on DigitalOcean.
* `source()` the referenced R file to plumb inside of a new environment that
  inherits directly from the GlobalEnv. This provides more explicit control over
  exactly how this environment should behave.
* Added `@serializer htmlwidget` to support rendering and returning a
  self-contained htmlwidget from a plumber endpoint.
* Properly handle cookies with no value. (#88)
* Don't convert `+` character in a query string to a space.


plumber 0.3.1
--------------------------------------------------------------------------------
* Add a method to consume JSON on post (you can still send a query string in
  the body of a POST request as well).


plumber 0.3.0
--------------------------------------------------------------------------------
* BREAKING CHANGE: serializer factories are now registered instead of the
  serializer themselves. Thus, `addSerializer()` now expects a function that
  returns a serializer, and `Response$new()` now expects a serializer itself
  rather than a character string naming a serializer. Internally it is the
  serializer itself that is attached to the response rather than the name of
  the serializer. This allows for a serializer to customize its behavior.
* Accept an additional argument on the `@serializer` annotation -- R code that
  will be passed in as an argument to the serializer factory. See example
  `09-content-type`.


plumber 0.2.4
--------------------------------------------------------------------------------
* Add a filter which parses and sets req$cookies to be a list corresponding to
  the cookies provided with the request.
* Responses can set multiple cookies
* Bug Fix: convert non-character arguments in setCookie to character before URL-
  encoding.


plumber 0.2.3
--------------------------------------------------------------------------------
* Set options(warn=1) during execution of user code so that warnings are
  immediately visible in the console, rather than storing them until the server
  is stopped.


plumber 0.2.2
--------------------------------------------------------------------------------
* Add `sessionCookie` function to define a processor that can be used as a
  globalProcessor on a router to encrypt values from req$session and store them
  as an encrypted cookie in on the user's browser.
* Added `setCookie` method to response which (primitively) allows you to set
  a cookie to be included in the response.
* Add `addGlobalProcessor` method on `plumber` class to support a processor that
  runs a processor only a single time, before and then after all other filters
  and the endpoint.
* Document all public params so CHECK passes


plumber 0.2.1
--------------------------------------------------------------------------------
* Add more Roxygen documentation for exported functions
* Remove the warning in the README as the API seems to be stabilizing.


plumber 0.2.0
--------------------------------------------------------------------------------
* BREAKING: Changed variable-path routing to use bracketed format instead of
  just a colon.
* BREAKING: Renamed `PlumberRouter` R6 object to just `Plumber`.
* Support `addEndpoint()` and `addFilter()` on the `Plumber` object.
* Added support for the `#*` prefix.


plumber 0.1.0
--------------------------------------------------------------------------------
* Initial Release
