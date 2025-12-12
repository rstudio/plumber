# GitHub Copilot Instructions for plumber

The plumber package enables creating web APIs by decorating R functions
with roxygen2-style comments. It provides annotation-driven API
definition, automatic OpenAPI spec generation, and built-in Swagger UI.
This R package follows standard R package development practices using
the devtools ecosystem.

**CRITICAL: Always follow these instructions first and only fallback to
additional search and context gathering if the information in these
instructions is incomplete or found to be in error.**

## Working Effectively

### Essential Setup Commands

Install required R and development dependencies:

``` bash
# Install R if not available (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y r-base r-base-dev build-essential libcurl4-openssl-dev libssl-dev libxml2-dev

# Install core R packages via apt (faster than CRAN for basic packages)
sudo apt-get install -y r-cran-jsonlite r-cran-httpuv r-cran-r6 r-cran-stringi r-cran-crayon r-cran-lifecycle r-cran-magrittr r-cran-mime r-cran-rlang r-cran-sodium r-cran-testthat

# Install additional development packages if available via apt
sudo apt-get install -y r-cran-devtools r-cran-knitr r-cran-rmarkdown r-cran-spelling

# If packages not available via apt, install via CRAN (may fail if network restricted)
sudo R -e "install.packages(c('devtools', 'pkgdown'), repos='https://cloud.r-project.org/')"
```

### Build and Development Commands

Always run these commands from the package root directory:

``` bash
# Install package from source (basic development workflow)
# TIMING: ~5-10 seconds
sudo R -e "install.packages('.', type = 'source', repos = NULL)"

# Generate documentation from roxygen2 comments (if devtools available)
R -e "devtools::document()"

# Load package for interactive development
R -e "devtools::load_all()"

# Build source package without vignettes (fastest option)
# TIMING: ~0.5 seconds - VERY FAST
R CMD build --no-build-vignettes .

# Basic R CMD check (without tests/vignettes to avoid missing dependencies)
# TIMING: ~20-30 seconds - NEVER CANCEL, Set timeout to 60+ seconds
_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-vignettes --no-tests plumber_*.tar.gz

# Full R CMD check with devtools (if available)
# NEVER CANCEL: Takes 5-20 minutes with all dependencies. Set timeout to 30+ minutes.
R -e "devtools::check()"

# Run unit tests directly from source
# TIMING: ~15-30 seconds - NEVER CANCEL, Set timeout to 60+ seconds
R -e "library(testthat); library(plumber); test_dir('tests/testthat')"

# Run unit tests using devtools (if available)
R -e "devtools::test()"

# Run specific test file
R -e "testthat::test_file('tests/testthat/test-plumber.R')"

# Run tests matching a pattern
R -e "testthat::test_file('tests/testthat/test-plumber.R', filter = 'routing')"
```

### Testing Commands

``` bash
# Run full test suite from source directory
# TIMING: ~15-30 seconds - NEVER CANCEL, Set timeout to 60+ seconds
R -e "library(testthat); library(plumber); test_dir('tests/testthat')"

# Run spelling checks (if spelling package available)
R -e "spelling::spell_check_test(vignettes = TRUE, error = TRUE, skip_on_cran = TRUE)"

# Run single test file
R -e "testthat::test_file('tests/testthat/test-serializer.R')"

# Check if package loads correctly and can create a basic API
R -e "library(plumber); pr <- pr(); pr %>% pr_get('/test', function() 'OK'); cat('Plumber API created successfully\n')"
```

### Running Example APIs

``` bash
# Run an example API from inst/plumber/
R -e "library(plumber); pr('inst/plumber/10-welcome/plumber.R') %>% pr_run(port = 8000)"

# Test basic API creation and routing
R -e "library(plumber); pr() %>% pr_get('/health', function() list(status='ok')) %>% pr_run(port = 8000)"
```

### Documentation Commands

``` bash
# Build package documentation website (if pkgdown available)
# NEVER CANCEL: Takes 5-15 minutes. Set timeout to 20+ minutes.
R -e "pkgdown::build_site()"

# Render specific vignette (if knitr/rmarkdown available)
R -e "rmarkdown::render('vignettes/quickstart.Rmd')"
```

## Validation Requirements

### Always Test These Scenarios After Making Changes:

1.  **Basic Package Loading**: Verify the package loads without errors

    ``` r
    library(plumber)
    # Should load successfully with all dependencies
    ```

2.  **Basic API Creation**: Test core plumber functionality

    ``` r
    library(plumber)
    pr <- pr()
    pr %>%
      pr_get("/hello", function(name = "world") {
        list(message = paste("Hello", name))
      })
    # API should be created successfully
    ```

3.  **Annotation Parsing**: Test that annotation-based APIs work

    ``` r
    library(plumber)
    pr("inst/plumber/01-append/plumber.R")
    # Should parse without errors
    ```

4.  **Serialization**: Verify core serializers work

    ``` r
    library(plumber)
    pr() %>%
      pr_get("/json", function() list(data = 1:5), serializer = serializer_json()) %>%
      pr_get("/html", function() "<h1>Test</h1>", serializer = serializer_html())
    # Should handle multiple serializers
    ```

5.  **Integration Testing**: Verify core dependencies work together

    ``` r
    library(httpuv)
    library(jsonlite)
    library(plumber)
    library(R6)
    # All should load without conflicts
    ```

### Mandatory Pre-Commit Checks:

**CRITICAL**: Run these validation steps before committing any changes:

``` bash
# 1. Build package to check for syntax/dependency errors
# TIMING: ~0.5 seconds - VERY FAST
R CMD build --no-build-vignettes .

# 2. Install package to verify it works
# TIMING: ~5-10 seconds
sudo R -e "install.packages('.', type = 'source', repos = NULL)"

# 3. Test package loading and basic functionality
# TIMING: ~2-3 seconds
R -e "library(plumber); pr() %>% pr_get('/test', function() 'OK')"

# 4. Run test suite if testthat is available
# TIMING: ~15-30 seconds - NEVER CANCEL, Set timeout to 60+ seconds
R -e "library(testthat); library(plumber); test_dir('tests/testthat')"

# 5. Full check if time permits (optional but recommended)
# TIMING: ~20-30 seconds - NEVER CANCEL, Set timeout to 60+ seconds
_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-vignettes --no-tests plumber_*.tar.gz
```

**Expected timing summary**:

- Basic build: ~0.5 seconds - **INSTANT**
- Package install: ~5-10 seconds - **VERY FAST**
- Test suite: ~15-30 seconds - **NEVER CANCEL, timeout 60+ seconds**
- Basic check: ~20-30 seconds - **NEVER CANCEL, timeout 60+ seconds**
- Full devtools::check(): 5-20 minutes - **NEVER CANCEL, timeout 30+
  minutes**

## Repository Structure

### Core Development Files:

- `R/` - Main R source code (60+ files including plumber.R,
  plumber-step.R, serializer.R)
- `tests/testthat/` - Unit tests using testthat framework
- `vignettes/` - 11 comprehensive documentation vignettes
- `inst/plumber/` - 17 example APIs demonstrating all features
- `man/` - Generated documentation (do not edit manually)

### Key Architecture Components:

- **Plumber Class** (`R/plumber.R`): Main R6-based router with request
  handling (~845 lines)
- **Hookable Base** (`R/hookable.R`): Hook system for preroute,
  postroute, preserialize, etc.
- **PlumberStep** (`R/plumber-step.R`): Base class for endpoints and
  filters
- **Annotation Parser** (`R/plumb-block.R`): Parses roxygen2-style
  comments into routes
- **Serializers** (`R/serializer.R`): 28+ output formats (json, html,
  png, csv, etc.)
- **Parsers** (`R/parse-body.R`, `R/parse-query.R`): Request body and
  query string parsing
- **OpenAPI** (`R/openapi-spec.R`, `R/openapi-types.R`): Automatic API
  spec generation
- **Async Support** (`R/async.R`): Promise-based async execution with
  runSteps()

### Dependencies (Auto-installed via devtools):

- **Core (Imports)**: crayon, httpuv (\>= 1.5.5), jsonlite (\>= 0.9.16),
  lifecycle (\>= 1.0.0), magrittr, mime, promises (\>= 1.1.0), R6 (\>=
  2.0.0), rlang (\>= 1.0.0), sodium, stringi (\>= 0.3.0), swagger (\>=
  3.33.0), webutils (\>= 1.1)
- **Optional (Suggests)**: arrow, base64enc, coro, future, geojsonsf,
  htmlwidgets, later, ragg, rapidoc, readr, readxl, redoc, rmarkdown,
  rstudioapi, sf, spelling, svglite, testthat (\>= 0.11.0), utils,
  visNetwork, writexl, yaml
- **Development**: devtools, knitr, pkgdown, Cairo, r-quantities/units

## GitHub Actions / CI Information

The package uses RStudio’s shiny-workflows for CI/CD
(`.github/workflows/R-CMD-check.yaml`):

- Automated R CMD check on push/PR and weekly (Monday 7am)
- Website deployment via pkgdown
- Code formatting and routine checks
- Runs on multiple R versions and platforms

**Local validation should match CI requirements**: Always run
`devtools::check()` locally before pushing.

## Common Development Tasks

### Adding New Endpoints to APIs:

1.  **Annotation-based** (recommended for file-based APIs):

    ``` r
    #* Description of endpoint
    #* @get /path
    #* @serializer json
    function(param1, param2) {
      # Implementation
    }
    ```

2.  **Programmatic** (recommended for dynamic APIs):

    ``` r
    pr() %>%
      pr_get("/path", function(param1, param2) {
        # Implementation
      })
    ```

### Adding New Serializers:

1.  Create serializer function in `R/serializer.R`
2.  Document with roxygen2 comments
3.  Register in `.onLoad()` hook:
    `register_serializer("name", func, "content/type")`
4.  Add tests in `tests/testthat/test-serializer.R`
5.  Update documentation

### Adding New Parsers:

1.  Create parser function in `R/parse-body.R` or `R/parse-query.R`
2.  Document with roxygen2 comments
3.  Register in `.onLoad()` hook:
    `register_parser("name", func, "content/type")`
4.  Add tests in `tests/testthat/test-body-parser.R`
5.  Update documentation

### Working with Vignettes:

``` bash
# Build specific vignette
R -e "rmarkdown::render('vignettes/quickstart.Rmd')"

# Build all vignettes (part of pkgdown::build_site)
R -e "devtools::build_vignettes()"
```

### Testing Example APIs:

``` bash
# Run example API interactively
R -e "library(plumber); pr('inst/plumber/01-append/plumber.R') %>% pr_run(port = 8000)"

# Test that all examples parse correctly
for dir in inst/plumber/*/; do
  echo "Testing $dir"
  R -e "library(plumber); pr('${dir}plumber.R')"
done
```

## Architecture Deep Dive

### R6 Class Hierarchy

    Hookable (base class - provides hook system)
      └── Plumber (main API router)
            ├── PlumberStatic (static file serving)
            └── PlumberStep (execution lifecycle base)
                  ├── PlumberEndpoint (terminal request handlers)
                  └── PlumberFilter (middleware)

### Request Processing Pipeline

1.  **Request arrives** → `Plumber$call()` invoked (R/plumber.R:565-846)
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

### Annotation System

Annotations are parsed by `plumbBlock()` in `R/plumb-block.R`:

- Scans backward from function to find `#*` or `#'` comments
- Uses regex to parse structured tags into metadata
- `evaluateBlock()` creates `PlumberEndpoint` or `PlumberFilter` objects

**Annotation order matters**: Place route-modifying annotations before
HTTP verb:

``` r
#* @serializer json     # ✓ Correct order
#* @get /data
```

### Path Parameter Types

Supported types in path parameters (`/users/<id:int>`):

- `int` - Integer conversion
- `double`, `numeric` - Numeric conversion
- `bool`, `logical` - Boolean conversion
- `string` - String (default)
- `[type]` - Arrays (e.g., `[int]`)

## Troubleshooting

### Common Issues:

- **Missing Dependencies**: Install core packages via apt first, then
  try CRAN for others

  ``` bash
  sudo apt-get install -y r-cran-jsonlite r-cran-httpuv r-cran-r6 r-cran-stringi r-cran-crayon r-cran-lifecycle r-cran-magrittr r-cran-mime r-cran-rlang r-cran-sodium r-cran-testthat
  ```

- **Package Won’t Load**: Reinstall from source:
  `sudo R -e "install.packages('.', type = 'source', repos = NULL)"`

- **devtools Not Available**: Use R CMD directly for basic operations

- **Test Failures**: Ensure package is installed: tests need the package
  loaded

- **Build Failures**: Check DESCRIPTION file dependencies match actual
  imports

- **Port Already in Use**: Change port when running examples:
  `pr_run(port = 8001)`

### Filters Must Call forward()

A common mistake is forgetting to call
[`forward()`](https://www.rplumber.io/reference/forward.md) in filters:

``` r
#* @filter logger
function(req) {
  log(req$PATH_INFO)
  forward()  # Required! Without this, request stops here
}
```

### Annotation Parser Gotchas:

- Annotations must use `#*` prefix (not regular `#` comments)
- Annotations apply to the next function definition
- Multiple endpoints require multiple function definitions
- Router-level config uses `#* @plumber` tag

### Alternative Commands When devtools Unavailable:

``` bash
# Use R CMD instead of devtools equivalents:
R CMD build --no-build-vignettes .                    # instead of devtools::build()
_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-vignettes --no-tests *.tar.gz  # instead of devtools::check()
R -e "library(testthat); test_dir('tests/testthat')"  # instead of devtools::test()
sudo R -e "install.packages('.', type='source', repos=NULL)"  # instead of devtools::install()
```

### Network/CRAN Issues:

If CRAN mirrors are unavailable, use apt packages or local installation:

``` bash
# Prefer apt packages over CRAN when possible
sudo apt-cache search r-cran- | grep <package_name>

# Force local installation without network
sudo R -e "install.packages('.', type='source', repos=NULL)"
```

### File Loading Order (Collate):

R requires specific file load order due to dependencies. The `Collate`
field in DESCRIPTION enforces:

1.  Base classes first: `async.R`, `hookable.R`
2.  Core infrastructure: `plumber.R`, `plumber-step.R`
3.  Features: parsers, serializers, OpenAPI
4.  Utilities: `utils.R`, `zzz.R` (last - package hooks)

When adding new files, consider load order dependencies and update
DESCRIPTION Collate field.

## Important Files Reference

### Core Routing & Execution:

- `R/plumber.R` - Main Plumber class (845 lines)
- `R/plumber-step.R` - Step/Endpoint/Filter classes
- `R/hookable.R` - Hook system base class
- `R/async.R` - Promise/async execution engine

### API Definition:

- `R/plumb.R` - [`plumb()`](https://www.rplumber.io/reference/plumb.md)
  entry point
- `R/plumb-block.R` - Annotation parser
- `R/pr.R` - Programmatic API
  ([`pr()`](https://www.rplumber.io/reference/pr.md) constructor)
- `R/pr_set.R` - Configuration methods (`pr_set_*()`)

### Data Handling:

- `R/serializer.R` - Output serialization (28+ formats)
- `R/parse-body.R` - Request body parsing
- `R/parse-query.R` - Query string parsing

### OpenAPI/Documentation:

- `R/openapi-spec.R` - OpenAPI 3.0 generation
- `R/openapi-types.R` - Type inference
- `R/ui.R` - Swagger/Rapidoc/Redoc UI mounting

### Example APIs (`inst/plumber/` directory):

- `01-append` - Basic GET/POST
- `02-filters` - Middleware patterns
- `06-sessions` - Session management
- `12-entrypoint` - Entrypoint pattern
- `13-promises`, `14-future` - Async examples
- `15-openapi-spec` - OpenAPI customization

### Test Files (`tests/testthat/` directory):

- `test-plumber.R` - Core router tests
- `test-serializer.R` - Serializer tests
- `test-body-parser.R` - Parser tests
- `test-endpoint.R` - Endpoint tests
- `test-filter.R` - Filter tests
- `helper-mock-request.R` - Test utilities

**Remember**: This is a web API framework for R. Always consider HTTP
semantics, request/response handling, serialization, and the annotation
parsing system when making changes. The dual API design
(annotation-based and programmatic) should both be supported for any new
features.
