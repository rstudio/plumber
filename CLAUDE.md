# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Project Overview

Plumber is an R package that enables creating web APIs by decorating R
functions with roxygen2-style comments. It provides annotation-driven
API definition (`#* @get /path`), automatic OpenAPI spec generation, and
built-in Swagger UI.

**Current version:** 1.3.0.9000 (development)

## Essential Commands

### Package Development

``` r

# Install development version
pak::pkg_install("rstudio/plumber")

# Load package for interactive development
devtools::load_all()

# Build and check package
devtools::check()

# Generate documentation from roxygen comments
devtools::document()

# Run all tests
devtools::test()

# Run specific test file
testthat::test_file("tests/testthat/test-plumber.R")

# Run tests matching a pattern
testthat::test_file("tests/testthat/test-plumber.R", filter = "routing")
```

### Running Example APIs

``` r

# Run an example API from inst/plumber/
pr("inst/plumber/10-welcome/plumber.R") %>% pr_run(port = 8000)

# Or for development testing
library(plumber)
pr("path/to/test-api.R") %>% pr_run(port = 8000)
```

### Testing via Command Line

``` bash
# Run full R CMD check
R CMD build . && R CMD check plumber_*.tar.gz

# Run tests only
Rscript -e "devtools::test()"

# Run specific test file
Rscript -e "testthat::test_file('tests/testthat/test-plumber.R')"
```

## Architecture

### R6 Class Hierarchy

The package uses R6 for object-oriented design with a clear inheritance
chain:

    Hookable (base class - provides hook system)
      └── Plumber (main API router)
            ├── PlumberStatic (static file serving)
            └── PlumberStep (execution lifecycle base)
                  ├── PlumberEndpoint (terminal request handlers)
                  └── PlumberFilter (middleware)

**Key files:** - [R/hookable.R](https://www.rplumber.io/R/hookable.R) -
Hook registration and execution (preroute, postroute, preserialize,
etc.) - [R/plumber.R](https://www.rplumber.io/R/plumber.R) - Core
`Plumber` class with routing engine -
[R/plumber-step.R](https://www.rplumber.io/R/plumber-step.R) -
`PlumberStep`, `PlumberEndpoint`, `PlumberFilter` classes

### Request Processing Pipeline

Understanding the request flow is critical for debugging and extending
the framework:

1.  **Request arrives** → `Plumber$call()` invoked
    ([R/plumber.R:565-846](https://www.rplumber.io/R/plumber.R#L565-L846))
2.  **Pre-route hooks** execute (auth, logging, request modification)
3.  **Route matching** in priority order:
    - `"__first__"` preempted endpoints (highest priority)
    - Filters execute sequentially with
      [`forward()`](https://www.rplumber.io/reference/forward.md)
      continuation
    - Endpoints checked at each preemption level
    - Mounted sub-routers
      ([`pr_mount()`](https://www.rplumber.io/reference/pr_mount.md))
    - 404 handler if no match
4.  **Post-route hooks** execute (after handler, before serialization)
5.  **Serialization**:
    - Pre-serialize hooks (modify response object)
    - Serializer function application
    - Post-serialize hooks (modify final output)
6.  **HTTP response** returned

**Forward mechanism:** Filters must call
[`forward()`](https://www.rplumber.io/reference/forward.md) to pass
control to the next handler. This uses an execution domain pattern
tracked internally.

### Annotation Parsing System

APIs are defined using special comments that get parsed into route
metadata:

**Core annotations:** - `#* @get /path`, `#* @post /path` - HTTP verb +
route - `#* @serializer json` - Output format (json, html, png, csv,
etc.) - `#* @parser json` - Input parsing (json, form, multipart,
etc.) - `#* @param name:type Description` - Parameter documentation -
`#* @filter name` - Define filter/middleware -
`#* @preempt [filter_name]` - Control execution order - `#* @plumber` -
Router-level configuration

**Implementation:** -
[R/plumb-block.R](https://www.rplumber.io/R/plumb-block.R) -
`plumbBlock()` scans backward from function to find `#*` comments - Uses
regex to parse structured tags into metadata - `evaluateBlock()` creates
`PlumberEndpoint` or `PlumberFilter` objects - Supports both `#*`
(recommended) and `#'` prefixes

### Plugin Architecture

Three extensible registries in `.globals` environment:

1.  **Serializers**
    ([R/serializer.R](https://www.rplumber.io/R/serializer.R)) -
    Transform R objects to HTTP responses
    - 28+ built-in: json, html, png, csv, geojson, arrow, parquet, xlsx,
      etc.
    - Composable via
      [`serializer_headers()`](https://www.rplumber.io/reference/serializers.md)
      →
      [`serializer_content_type()`](https://www.rplumber.io/reference/serializers.md)
      → specific serializers
    - Register custom: `register_serializer("name", func, contentType)`
2.  **Parsers**
    ([R/parse-body.R](https://www.rplumber.io/R/parse-body.R),
    [R/parse-query.R](https://www.rplumber.io/R/parse-query.R)) - Parse
    request bodies
    - Query string: `parseQS()` handles URL parameters with encoding
    - Body parsing: Content-Type detection, multipart form support
    - Register custom: `register_parser("name", func, contentType)`
3.  **Docs** ([R/ui.R](https://www.rplumber.io/R/ui.R)) - Visual API
    documentation providers
    - Built-in: swagger, rapidoc, redoc
    - Mounted at `/__docs__/` by default
    - OpenAPI spec at `/openapi.json`

### OpenAPI Specification Generation

Automatic OpenAPI 3.0 spec generation from annotations:

- [R/openapi-spec.R](https://www.rplumber.io/R/openapi-spec.R) -
  `$getApiSpec()` generates full spec
- [R/openapi-types.R](https://www.rplumber.io/R/openapi-types.R) - Type
  inference from R function signatures
- Parameter metadata extracted from `@param` tags
- Response types inferred from serializers
- [`pr_set_api_spec()`](https://www.rplumber.io/reference/pr_set_api_spec.md)
  for manual spec customization

### Async/Promise Support

Built on the `promises` package for non-blocking execution:

- [R/async.R](https://www.rplumber.io/R/async.R) - `runSteps()` and
  `runStepsUntil()` handle sync/async
- Promise detection via `is.promising(result)`
- Recursive step execution for async handlers
- Error handling with `%...!%` catch operator
- Filters and endpoints can return promises

### Path Parameter Extraction

Regex-based path matching with type conversion:

``` r

#* @get /users/<id:int>
#* @get /files/<name:string>
#* @get /data/<vals:[int]>     # Array of integers
```

Supported types: `int`, `double`/`numeric`, `bool`/`logical`, `string`,
arrays `[type]`

Implementation in [R/plumber.R](https://www.rplumber.io/R/plumber.R) -
path regex compilation and parameter extraction.

## Code Organization

### File Loading Order (Collate in DESCRIPTION)

R requires specific file load order due to dependencies. The `Collate`
field enforces: 1. Base classes first: `async.R`, `hookable.R` 2. Core
infrastructure: `plumber.R`, `plumber-step.R` 3. Features: parsers,
serializers, OpenAPI 4. Utilities: `utils.R`, `zzz.R` (last - package
hooks)

When adding new files, consider load order dependencies.

### Source Code Structure

**Core routing & execution:** -
[R/plumber.R](https://www.rplumber.io/R/plumber.R) - Main `Plumber`
class (845 lines) -
[R/plumber-step.R](https://www.rplumber.io/R/plumber-step.R) -
Step/Endpoint/Filter classes -
[R/hookable.R](https://www.rplumber.io/R/hookable.R) - Hook system base
class - [R/async.R](https://www.rplumber.io/R/async.R) - Promise/async
execution engine

**API definition:** - [R/plumb.R](https://www.rplumber.io/R/plumb.R) -
[`plumb()`](https://www.rplumber.io/reference/plumb.md) entry point -
[R/plumb-block.R](https://www.rplumber.io/R/plumb-block.R) - Annotation
parser - [R/pr.R](https://www.rplumber.io/R/pr.R) - Programmatic API
([`pr()`](https://www.rplumber.io/reference/pr.md) constructor) -
[R/pr_set.R](https://www.rplumber.io/R/pr_set.R) - Configuration methods
(`pr_set_*()`)

**Data handling:** -
[R/serializer.R](https://www.rplumber.io/R/serializer.R) - Output
serialization (28+ formats) -
[R/parse-body.R](https://www.rplumber.io/R/parse-body.R) - Request body
parsing - [R/parse-query.R](https://www.rplumber.io/R/parse-query.R) -
Query string parsing

**OpenAPI/Documentation:** -
[R/openapi-spec.R](https://www.rplumber.io/R/openapi-spec.R) - OpenAPI
3.0 generation -
[R/openapi-types.R](https://www.rplumber.io/R/openapi-types.R) - Type
inference - [R/ui.R](https://www.rplumber.io/R/ui.R) -
Swagger/Rapidoc/Redoc UI mounting

**Advanced features:** -
[R/session-cookie.R](https://www.rplumber.io/R/session-cookie.R) -
Encrypted session cookies -
[R/plumber-static.R](https://www.rplumber.io/R/plumber-static.R) -
Static file serving -
[R/shared-secret-filter.R](https://www.rplumber.io/R/shared-secret-filter.R) -
Authentication -
[R/default-handlers.R](https://www.rplumber.io/R/default-handlers.R) -
404/405/500 handlers

## Testing Strategy

### Test Organization

Tests in [tests/testthat/](https://www.rplumber.io/tests/testthat/)
follow clear naming:

- **Unit tests:** `test-<feature>.R` (e.g., `test-serializer.R`,
  `test-parser.R`)
- **Integration tests:** `test-<component>.R` (e.g., `test-plumber.R`,
  `test-endpoint.R`)
- **Helper files:** `helper-<utility>.R` (e.g., `helper-mock-request.R`)

### Mock Request Helper

Use `make_req()` from
[tests/testthat/helper-mock-request.R](https://www.rplumber.io/tests/testthat/helper-mock-request.R)
to create test requests:

``` r

req <- make_req(verb = "POST", path = "/api/data", qs = "param=value", body = '{"key":"value"}')
```

### Example APIs for Testing

17 complete example APIs in
[inst/plumber/](https://www.rplumber.io/inst/plumber/) demonstrate all
features: - `01-append` - Basic GET/POST - `02-filters` - Middleware
patterns - `06-sessions` - Session management - `12-entrypoint` -
Entrypoint pattern for complex APIs - `13-promises`, `14-future` - Async
examples - `15-openapi-spec` - OpenAPI customization

Run examples with: `pr("inst/plumber/<example>/plumber.R") %>% pr_run()`

## Development Patterns

### Dual API Design

Plumber supports both annotation-based and programmatic API definition:

**Annotation-based (declarative):**

``` r

#* @get /hello
function(name = "world") {
  list(message = paste("Hello", name))
}
```

**Programmatic (imperative):**

``` r

pr() %>%
  pr_get("/hello", function(name = "world") {
    list(message = paste("Hello", name))
  })
```

Both approaches are first-class. Use annotations for file-based APIs,
programmatic for dynamic construction.

### Router Composition via Mounting

Complex APIs can be composed from multiple routers:

``` r

root <- pr()
users_api <- pr("apis/users.R")
products_api <- pr("apis/products.R")

root %>%
  pr_mount("/users", users_api) %>%
  pr_mount("/products", products_api) %>%
  pr_run()
```

Mounted routers maintain independent configurations (hooks, error
handlers).

### Entrypoint Pattern

For APIs requiring initialization, use `entrypoint.R` that returns a
configured router:

``` r

# inst/plumber/12-entrypoint/entrypoint.R
function(port = 8000) {
  pr("plumber.R") %>%
    pr_set_debug(TRUE) %>%
    pr_cookie(secret_key) %>%
    pr_hook("preroute", logging_hook)
}
```

This pattern enables environment-specific configuration and dependency
injection.

## Package Configuration

### Global Options

Set via [`options()`](https://rdrr.io/r/base/options.html) or
environment variables:

- `plumber.port`, `plumber.host` - Default server binding
- `plumber.maxRequestSize` - Max body size (bytes)
- `plumber.docs` - Enable/disable documentation UI
- `plumber.docs.callback` - Custom docs provider
- `plumber.apiURL`, `plumber.apiPath` - OpenAPI spec URLs

See [R/options_plumber.R](https://www.rplumber.io/R/options_plumber.R)
for full list.

### CI/CD Pipeline

GitHub Actions workflow
([.github/workflows/R-CMD-check.yaml](https://www.rplumber.io/.github/workflows/R-CMD-check.yaml)): -
Runs on push to main, PRs, and weekly (Monday 7am) - Three jobs: website
build, routine checks, R CMD check - Uses rstudio/shiny-workflows
templates

## Common Pitfalls

### Annotation Order Matters

Annotations are parsed top-to-bottom. Place route-modifying annotations
before the HTTP verb:

``` r

#* @serializer json     # ✓ Correct order
#* @get /data
```

Not:

``` r

#* @get /data
#* @serializer json     # ✗ Won't apply to this endpoint
```

### Forward() is Required in Filters

Filters MUST call
[`forward()`](https://www.rplumber.io/reference/forward.md) to continue
the pipeline:

``` r

#* @filter logger
function(req) {
  log(req$PATH_INFO)
  forward()  # Required! Without this, request stops here
}
```

### Path Parameters Need Type Hints

Extract path params with type conversion:

``` r

#* @get /users/<id:int>    # ✓ Type specified
function(id) {
  # id is already an integer
}
```

Without type hint, all params are strings.

### Serializer vs Parser Confusion

- **Serializer** - Converts R object → HTTP response (output)
- **Parser** - Converts HTTP request → R object (input)

Use `@serializer` for response format, `@parser` for request body
format.

## Documentation

- **Website:** <https://www.rplumber.io>
- **Vignettes:** [vignettes/](https://www.rplumber.io/vignettes/) - 11
  comprehensive guides
- **Man pages:** [man/](https://www.rplumber.io/man/) - Generated from
  roxygen2 comments
- **Cheat sheet:**
  <https://github.com/rstudio/cheatsheets/blob/main/plumber.pdf>

When adding new features, update corresponding vignette and man page.
