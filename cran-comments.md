## Comments

#### 2025-11

Dear maintainer,

Please see the problems shown on
cran.r-project.org/web/checks/check_results_plumber.html.

Please correct before 2025-12-08 to safely retain your package on CRAN.

Do remember to look at any 'Additional issues'

Packages in Suggests should be used conditionally: see 'Writing R Extensions'.
This needs to be corrected even if the missing package(s) become available.
It can be tested by checking with _R_CHECK_DEPENDS_ONLY_=true.

The CRAN Team

#### 2024-12-12

Complete output:
  > library(testthat)
  > library(plumber)
  >
  > test_check("plumber")
  Saving _problems/test-parser-6.R
  Saving _problems/test-serializer-htmlwidgets-39.R
  <packageNotFoundError in loadNamespace(x): there is no package called 'base64enc'>
  <packageNotFoundError in loadNamespace(x): there is no package called 'base64enc'>
  Saving _problems/test-tidy-plumber-109.R
  <packageNotFoundError in loadNamespace(x): there is no package called 'base64enc'>
  Saving _problems/test-tidy-plumber-133.R
  Saving _problems/test-zzz-openapi-340.R
  Saving _problems/test-zzz-openapi-347.R
  [ FAIL 7 | WARN 0 | SKIP 46 | PASS 1750 ]

  ══ Skipped tests (46) ══════════════════════════════════════════════════════════
  • On CRAN (15): 'test-cookies.R:47:3', 'test-deprecated.R:60:3',
    'test-find-port.R:40:3', 'test-find-port.R:56:3', 'test-legacy.R:20:3',
    'test-options.R:22:3', 'test-plumber-print.R:2:3',
    'test-plumber-print.R:60:3', 'test-plumber.R:67:3',
    'test-serializer-device.R:26:1', 'test-serializer-htmlwidgets.R:18:3',
    'test-static.R:23:3', 'test-zzz-openapi.R:254:3',
    'test-zzz-plumb_api.R:10:3', 'test-zzz-plumb_api.R:65:3'
  • {arrow} is not installed (5): 'test-parse-body.R:93:3',
    'test-parse-body.R:113:3', 'test-serializer-feather.R:4:3',
    'test-serializer-feather.R:21:3', 'test-serializer-feather.R:34:3'
  • {base64enc} is not installed (9): 'test-cookies.R:113:3',
    'test-cookies.R:175:3', 'test-cookies.R:207:3', 'test-cookies.R:265:3',
    'test-sessions.R:30:3', 'test-sessions.R:55:3', 'test-sessions.R:86:3',
    'test-sessions.R:117:3', 'test-sessions.R:150:3'
  • {geojsonsf} is not installed (3): 'test-parse-body.R:164:3',
    'test-serializer-geojson.R:2:3', 'test-serializer-geojson.R:24:3'
  • {mockery} is not installed (2): 'test-plumber-run.R:45:3',
    'test-plumber-run.R:71:3'
  • {readr} is not installed (5): 'test-parse-body.R:53:3',
    'test-parse-body.R:73:3', 'test-parse-body.R:305:3',
    'test-serializer-csv.R:4:3', 'test-serializer-csv.R:26:3'
  • {readxl} is not installed (1): 'test-parse-body.R:138:3'
  • {rmarkdown} is not installed. (1): 'test-zzzz-include.R:22:3'
  • {writexl} is not installed (2): 'test-serializer-excel.R:4:3',
    'test-serializer-excel.R:24:3'
  • {yaml} is not installed (3): 'test-parse-body.R:46:3',
    'test-serializer-yaml.R:4:3', 'test-serializer-yaml.R:26:3'

  ══ Failed tests ════════════════════════════════════════════════════════════════
  ── Error ('test-parser.R:6:5'): parsers can be combined ────────────────────────
  Error in `(function (..., sheet = NULL)  {     if (!requireNamespace("readxl", quietly = TRUE)) {         stop("`readxl` must be installed for `parser_excel` to work")     }     parse_fn <- parser_read_file(function(tmpfile) {         if (is.null(sheet)) {             sheet <- 1L         }         else if (anyNA(sheet)) {             sheet <- readxl::excel_sheets(tmpfile)         }         if (is.character(sheet))              names(sheet) <- sheet         out <- suppressWarnings(lapply(sheet, function(sht) {             readxl::read_excel(path = tmpfile, sheet = sht, ...)         }))         out     })     function(value, ...) {         parse_fn(value)     } })()`: `readxl` must be installed for `parser_excel` to work
  Backtrace:
      ▆
   1. └─plumber (local) expect_parsers(...) at test-parser.R:18:3
   2.   └─plumber:::make_parser(names) at test-parser.R:6:5
   3.     └─base::lapply(...)
   4.       └─plumber (local) FUN(X[[i]], ...)
   5.         ├─base::do.call(init_parser_func, aliases[[alias]])
   6.         └─plumber (local) `<fn>`()
   7.           ├─base::do.call(parser, list(...))
   8.           └─plumber (local) `<fn>`()
  ── Error ('test-parser.R:38:3'): parsers work ──────────────────────────────────
  Error in `(function (..., sheet = NULL)  {     if (!requireNamespace("readxl", quietly = TRUE)) {         stop("`readxl` must be installed for `parser_excel` to work")     }     parse_fn <- parser_read_file(function(tmpfile) {         if (is.null(sheet)) {             sheet <- 1L         }         else if (anyNA(sheet)) {             sheet <- readxl::excel_sheets(tmpfile)         }         if (is.character(sheet))              names(sheet) <- sheet         out <- suppressWarnings(lapply(sheet, function(sht) {             readxl::read_excel(path = tmpfile, sheet = sht, ...)         }))         out     })     function(value, ...) {         parse_fn(value)     } })()`: `readxl` must be installed for `parser_excel` to work
  Backtrace:
       ▆
    1. └─plumber::pr(test_path("files/parsers.R")) at test-parser.R:38:3
    2.   └─Plumber$new(file = file, filters = filters, envir = envir)
    3.     └─plumber (local) initialize(...)
    4.       └─plumber:::evaluateBlock(...)
    5.         └─base::lapply(...)
    6.           └─plumber (local) FUN(X[[i]], ...)
    7.             └─PlumberEndpoint$new(...)
    8.               └─plumber (local) initialize(...)
    9.                 └─plumber:::make_parser(parsers)
   1.                    └─base::lapply(...)
   2.                      └─plumber (local) FUN(X[[i]], ...)
   3.                        ├─base::do.call(init_parser_func, aliases[[alias]])
   4.                        └─plumber (local) `<fn>`()
   5.                          ├─base::do.call(parser, list(...))
   6.                          └─plumber (local) `<fn>`()
  ── Error ('test-serializer-htmlwidgets.R:37:3'): Errors call error handler ─────
  Error: The htmlwidgets package is not available but is required in order to use the htmlwidgets serializer
  Backtrace:
      ▆
   1. ├─base::suppressWarnings(...) at test-serializer-htmlwidgets.R:37:3
   2. │ └─base::withCallingHandlers(...)
   3. └─plumber::serializer_htmlwidget()
  ── Error ('test-tidy-plumber.R:109:3'): pr_cookie adds cookie ──────────────────
  Error in `expect_match(p$call(req)$headers$`Set-Cookie`, "^counter=")`: `object` must be a character vector, not `NULL`.
  Backtrace:
      ▆
   1. └─testthat::expect_match(object = p$call(req)$headers$`Set-Cookie`) at test-tidy-plumber.R:109:3
   2.   └─testthat:::check_character(object)
   3.     └─testthat:::stop_input_type(...)
   4.       └─rlang::abort(message, ..., call = call, arg = arg)
  ── Error ('test-tidy-plumber.R:133:3'): pr_cookie adds path in cookie ──────────
  Error in `expect_match(cookie_header1, "^counter=")`: `object` must be a character vector, not `NULL`.
  Backtrace:
      ▆
   1. └─testthat::expect_match(object = cookie_header1) at test-tidy-plumber.R:133:3
   2.   └─testthat:::check_character(object)
   3.     └─testthat:::stop_input_type(...)
   4.       └─rlang::abort(message, ..., call = call, arg = arg)
  ── Error ('test-zzz-openapi.R:340:3'): Response content type set with serializer ──
  Error in `serializer_csv()`: `readr` must be installed for `serializer_csv` to work
  Backtrace:
      ▆
   1. ├─plumber::pr_get(...) at test-zzz-openapi.R:340:3
   2. │ └─plumber::pr_handle(...)
   3. │   └─pr$handle(...)
   4. │     └─PlumberEndpoint$new(...)
   5. │       └─plumber (local) initialize(...)
   6. └─plumber::serializer_csv()
  ── Error ('test-zzz-openapi.R:347:3'): Api spec can be set using a file path ───
  Error in `pr$setApiSpec(api = api)`: yaml must be installed to read yaml format
  Backtrace:
      ▆
   1. ├─pr() %>% pr_set_api_spec(test_path("files/openapi.yaml")) at test-zzz-openapi.R:347:3
   2. └─plumber::pr_set_api_spec(., test_path("files/openapi.yaml"))
   3.   └─pr$setApiSpec(api = api)

  [ FAIL 7 | WARN 0 | SKIP 46 | PASS 1750 ]
  Error:
  ! Test failures.
  Execution halted
* checking PDF version of manual ... [14s/18s] OK
* checking HTML version of manual ... [9s/12s] OK
* checking for non-standard things in the check directory ... OK
* checking for detritus in the temp directory ... OK
* DONE

Status: 1 ERROR
See
  ‘/data/gannet/ripley/R/packages/tests-Suggests/plumber.Rcheck/00check.log’
for details.


#### 2024-12-12

A CI check is now being run with your environment variable _R_CHECK_DEPENDS_ONLY_=true set.

Best,
Barret

## R CMD check results

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

## revdepcheck results

We checked 21 reverse dependencies, comparing R CMD check results across CRAN and dev versions of this package.

 * We saw 0 new problems
 * We failed to check 0 packages
