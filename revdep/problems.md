# arenar

<details>

* Version: 0.2.0
* GitHub: https://github.com/ModelOriented/ArenaR
* Source code: https://github.com/cran/arenar
* Date/Publication: 2020-10-01 08:00:06 UTC
* Number of recursive dependencies: 117

Run `revdepcheck::revdep_details(, "arenar")` for more info

</details>

## In both

*   checking running R code from vignettes ...
    ```
      ‘arena_intro_titanic.Rmd’ using ‘UTF-8’... failed
      ‘arena_live.Rmd’ using ‘UTF-8’... failed
      ‘arena_static.Rmd’ using ‘UTF-8’... failed
      ‘classification.Rmd’ using ‘UTF-8’... failed
     WARNING
    Errors in running code in vignettes:
    when running code in ‘arena_intro_titanic.Rmd’
      ...
    
    > knitr::opts_chunk$set(collapse = TRUE, comment = "#>", 
    ...
    The following object is masked from ‘package:dplyr’:
    
        select
    
    
    > library(gbm)
    
      When sourcing ‘classification.R’:
    Error: there is no package called ‘gbm’
    Execution halted
    ```

*   checking Rd files ... NOTE
    ```
    checkRd: (-1) calculate_subsets_performance.Rd:32: Lost braces in \itemize; \value handles \item{}{} directly
    checkRd: (-1) calculate_subsets_performance.Rd:33: Lost braces in \itemize; \value handles \item{}{} directly
    checkRd: (-1) create_arena.Rd:61: Lost braces in \itemize; \value handles \item{}{} directly
    checkRd: (-1) create_arena.Rd:62: Lost braces in \itemize; \value handles \item{}{} directly
    checkRd: (-1) create_arena.Rd:63: Lost braces in \itemize; \value handles \item{}{} directly
    checkRd: (-1) create_arena.Rd:64: Lost braces in \itemize; \value handles \item{}{} directly
    checkRd: (-1) create_arena.Rd:68: Lost braces in \itemize; \value handles \item{}{} directly
    checkRd: (-1) create_arena.Rd:69: Lost braces in \itemize; \value handles \item{}{} directly
    checkRd: (-1) create_arena.Rd:70: Lost braces in \itemize; \value handles \item{}{} directly
    checkRd: (-1) create_arena.Rd:71: Lost braces in \itemize; \value handles \item{}{} directly
    ...
    checkRd: (-1) get_dataset_plots.Rd:14: Lost braces in \itemize; meant \describe ?
    checkRd: (-1) get_dataset_plots.Rd:15: Lost braces in \itemize; meant \describe ?
    checkRd: (-1) get_variable_against_another.Rd:12: Lost braces in \itemize; meant \describe ?
    checkRd: (-1) get_variable_against_another.Rd:13: Lost braces in \itemize; meant \describe ?
    checkRd: (-1) get_variable_against_another.Rd:14: Lost braces in \itemize; meant \describe ?
    checkRd: (-1) get_variable_against_another.Rd:15: Lost braces in \itemize; meant \describe ?
    checkRd: (-1) get_variable_distribution.Rd:12: Lost braces in \itemize; meant \describe ?
    checkRd: (-1) get_variable_distribution.Rd:13: Lost braces in \itemize; meant \describe ?
    checkRd: (-1) get_variable_distribution.Rd:14: Lost braces in \itemize; meant \describe ?
    checkRd: (-1) get_variable_distribution.Rd:15: Lost braces in \itemize; meant \describe ?
    ```

# AzureContainers

<details>

* Version: 1.3.3
* GitHub: https://github.com/Azure/AzureContainers
* Source code: https://github.com/cran/AzureContainers
* Date/Publication: 2025-04-12 08:30:08 UTC
* Number of recursive dependencies: 69

Run `revdepcheck::revdep_details(, "AzureContainers")` for more info

</details>

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘openssl’
      All declared Imports should be used.
    ```

# bayesAB

<details>

* Version: 1.1.3
* GitHub: https://github.com/FrankPortman/bayesAB
* Source code: https://github.com/cran/bayesAB
* Date/Publication: 2021-06-25 00:50:02 UTC
* Number of recursive dependencies: 63

Run `revdepcheck::revdep_details(, "bayesAB")` for more info

</details>

## In both

*   checking tests ...
    ```
      Running ‘testthat.R’
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      > 
      > test_check("bayesAB")
      Saving _problems/test-dists-34.R
      [ FAIL 1 | WARN 5 | SKIP 0 | PASS 140 ]
      
      ══ Failed tests ════════════════════════════════════════════════════════════════
      ── Failure ('test-dists.R:34:3'): Success ──────────────────────────────────────
      Expected `plotNormalInvGamma(3, 1, 1, 1)$labels$y` to equal "sig_sq".
      Differences:
      target is NULL, current is character
      
      [ FAIL 1 | WARN 5 | SKIP 0 | PASS 140 ]
      Error:
      ! Test failures.
      Execution halted
    ```

*   checking Rd files ... NOTE
    ```
    checkRd: (-1) plotDistributions.Rd:32: Lost braces
        32 | plot{...} functions are generated programmatically so the function calls in
           |     ^
    ```

# gaawr2

<details>

* Version: 0.0.3
* GitHub: https://github.com/jinghuazhao/gaawr2
* Source code: https://github.com/cran/gaawr2
* Date/Publication: 2025-03-24 15:00:09 UTC
* Number of recursive dependencies: 233

Run `revdepcheck::revdep_details(, "gaawr2")` for more info

</details>

## In both

*   checking running R code from vignettes ...
    ```
      ‘gaawr2.Rmd’ using ‘UTF-8’... failed
      ‘web.Rmd’ using ‘UTF-8’... OK
     ERROR
    Errors in running code in vignettes:
    when running code in ‘gaawr2.Rmd’
      ...
    +     n.chains = 1, n.iter = 80)
    
      When sourcing 'gaawr2.R':
    Error: .onLoad failed in loadNamespace() for 'rjags', details:
      call: dyn.load(file, DLLpath = DLLpath, ...)
      error: unable to load shared object '/Users/barret/Documents/git/rstudio/plumber/plumber.nosync/revdep/library.noindex/gaawr2/rjags/libs/rjags.so':
      dlopen(/Users/barret/Documents/git/rstudio/plumber/plumber.nosync/revdep/library.noindex/gaawr2/rjags/libs/rjags.so, 0x000A): Library not loaded: /usr/local/lib/libjags.4.dylib
      Referenced from: <337070A2-BC15-3117-B643-96612554E437> /Users/barret/Documents/git/rstudio/plumber/plumber.nosync/revdep/library.noindex/gaawr2/rjags/libs/rjags.so
      Reason: tried: '/usr/local/lib/libjags.4.dylib' (no such file), '/System/Volumes/Preboot/Cryptexes/OS/usr/local/lib/libjags.4.dylib' (no such file), '/usr/local/lib/libjags.4.dylib' (no such file), '/Library/Frameworks/R.framework/Versions/4.5-arm64/Resources/lib/libjags.4.dylib' (no such file), '/Library/Java/JavaVirtualMachines/jdk-11.0.18+10/Contents/Home/lib/server/libjags.4.dylib' (no
    Execution halted
    ```

# log

<details>

* Version: 1.1.1
* GitHub: https://github.com/devOpifex/log
* Source code: https://github.com/cran/log
* Date/Publication: 2022-02-24 19:40:02 UTC
* Number of recursive dependencies: 58

Run `revdepcheck::revdep_details(, "log")` for more info

</details>

## In both

*   checking DESCRIPTION meta-information ... NOTE
    ```
      Missing dependency on R >= 4.1.0 because package code uses the pipe
      |> or function shorthand \(...) syntax added in R 4.1.0.
      File(s) using such syntax:
        ‘logger.R’
    ```

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘R6’
      All declared Imports should be used.
    ```

# microCRAN

<details>

* Version: 0.9.0-1
* GitHub: NA
* Source code: https://github.com/cran/microCRAN
* Date/Publication: 2023-11-03 22:00:02 UTC
* Number of recursive dependencies: 54

Run `revdepcheck::revdep_details(, "microCRAN")` for more info

</details>

## In both

*   checking DESCRIPTION meta-information ... NOTE
    ```
      Missing dependency on R >= 4.1.0 because package code uses the pipe
      |> or function shorthand \(...) syntax added in R 4.1.0.
      File(s) using such syntax:
        ‘api.R’ ‘handlers-static.R’ ‘static-assets.Rd’
    ```

# openmetrics

<details>

* Version: 0.3.0
* GitHub: https://github.com/atheriel/openmetrics
* Source code: https://github.com/cran/openmetrics
* Date/Publication: 2020-11-09 21:20:02 UTC
* Number of recursive dependencies: 54

Run `revdepcheck::revdep_details(, "openmetrics")` for more info

</details>

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘R6’
      All declared Imports should be used.
    ```

# plumbertableau

<details>

* Version: 0.1.1
* GitHub: https://github.com/rstudio/plumbertableau
* Source code: https://github.com/cran/plumbertableau
* Date/Publication: 2023-12-19 02:20:03 UTC
* Number of recursive dependencies: 65

Run `revdepcheck::revdep_details(, "plumbertableau")` for more info

</details>

## In both

*   checking running R code from vignettes ...
    ```
      ‘introduction.Rmd’ using ‘UTF-8’... failed
      ‘publishing-extensions.Rmd’ using ‘UTF-8’... OK
      ‘r-developer-guide.Rmd’ using ‘UTF-8’... failed
      ‘tableau-developer-guide.Rmd’ using ‘UTF-8’... OK
     ERROR
    Errors in running code in vignettes:
    when running code in ‘introduction.Rmd’
      ...
    > knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
    
    ...
    > set.seed(35487)
    
    > knitr::read_chunk(path = "../inst/plumber/loess/plumber.R", 
    +     labels = "loess")
    Warning in file(con, "r") :
      cannot open file '../inst/plumber/loess/plumber.R': No such file or directory
    
      When sourcing ‘r-developer-guide.R’:
    Error: cannot open the connection
    Execution halted
    ```

# starsTileServer

<details>

* Version: 0.1.1
* GitHub: NA
* Source code: https://github.com/cran/starsTileServer
* Date/Publication: 2022-08-22 21:50:02 UTC
* Number of recursive dependencies: 114

Run `revdepcheck::revdep_details(, "starsTileServer")` for more info

</details>

## In both

*   checking running R code from vignettes ...
    ```
      ‘upscaling.Rmd’ using ‘UTF-8’... OK
      ‘using_functions.Rmd’ using ‘UTF-8’... OK
      ‘using_shiny.Rmd’ using ‘UTF-8’... failed
     ERROR
    Errors in running code in vignettes:
    when running code in ‘using_shiny.Rmd’
      ...
    +     function(grid, colFun) {
    +         starsTileServer::starsTileServer$new(grid, co .... [TRUNCATED] 
    
    > Sys.sleep(3)
    
    > stopifnot(rp$is_alive())
    
      When sourcing ‘using_shiny.R’:
    Error: rp$is_alive() is not TRUE
    Execution halted
    ```

# tgver

<details>

* Version: 0.3.0
* GitHub: https://github.com/tgve/tgver
* Source code: https://github.com/cran/tgver
* Date/Publication: 2022-09-30 15:20:03 UTC
* Number of recursive dependencies: 154

Run `revdepcheck::revdep_details(, "tgver")` for more info

</details>

## In both

*   checking running R code from vignettes ...
    ```
      ‘dev-plan.Rmd’ using ‘UTF-8’... OK
      ‘r-and-js.Rmd’ using ‘UTF-8’... failed
      ‘tgver.Rmd’ using ‘UTF-8’... OK
     ERROR
    Errors in running code in vignettes:
    when running code in ‘r-and-js.Rmd’
      ...
    Warning in grid.Call.graphics(C_text, as.graphicsAnnot(x$label), x$x, x$y,  :
      font family 'Arial Narrow' not found in PostScript font database
    Warning in grid.Call.graphics(C_text, as.graphicsAnnot(x$label), x$x, x$y,  :
      font family 'Arial Narrow' not found in PostScript font database
    Warning in grid.Call.graphics(C_text, as.graphicsAnnot(x$label), x$x, x$y,  :
      font family 'Arial Narrow' not found in PostScript font database
    
      When sourcing ‘r-and-js.R’:
    Error: invalid font type
    Execution halted
    ```

# vetiver

<details>

* Version: 0.2.6
* GitHub: https://github.com/rstudio/vetiver-r
* Source code: https://github.com/cran/vetiver
* Date/Publication: 2025-10-28 15:50:02 UTC
* Number of recursive dependencies: 225

Run `revdepcheck::revdep_details(, "vetiver")` for more info

</details>

## In both

*   checking tests ...
    ```
      Running ‘testthat.R’
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      ══ Failed tests ════════════════════════════════════════════════════════════════
      ── Error ('test-xgboost.R:9:1'): (code run outside of `test_that()`) ───────────
      Error in `matrix(NA_real_, ncol = model$nfeatures, dimnames = list("", model$feature_names))`: non-numeric matrix extent
      Backtrace:
          ▆
       1. └─vetiver::vetiver_model(cars_xgb, "cars2") at test-xgboost.R:9:1
       2.   └─vetiver::vetiver_create_ptype(model, save_prototype, ...)
       3.     ├─vetiver::vetiver_ptype(model, ...)
       4.     └─vetiver:::vetiver_ptype.xgb.Booster(model, ...)
       5.       └─base::matrix(...)
      
      [ FAIL 1 | WARN 2 | SKIP 70 | PASS 221 ]
      Error:
      ! Test failures.
      Execution halted
    ```

