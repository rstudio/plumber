# arenar

<details>

* Version: 0.2.0
* GitHub: https://github.com/ModelOriented/ArenaR
* Source code: https://github.com/cran/arenar
* Date/Publication: 2020-10-01 08:00:06 UTC
* Number of recursive dependencies: 110

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

*   checking LazyData ... NOTE
    ```
      'LazyData' is specified without a 'data' directory
    ```

# AzureContainers

<details>

* Version: 1.3.2
* GitHub: https://github.com/Azure/AzureContainers
* Source code: https://github.com/cran/AzureContainers
* Date/Publication: 2021-07-09 06:00:02 UTC
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
* Number of recursive dependencies: 73

Run `revdepcheck::revdep_details(, "bayesAB")` for more info

</details>

## In both

*   checking Rd files ... NOTE
    ```
    checkRd: (-1) plotDistributions.Rd:32: Lost braces
        32 | plot{...} functions are generated programmatically so the function calls in
           |     ^
    ```

# gqlr

<details>

* Version: 0.0.2
* GitHub: https://github.com/schloerke/gqlr
* Source code: https://github.com/cran/gqlr
* Date/Publication: 2019-12-02 16:20:03 UTC
* Number of recursive dependencies: 54

Run `revdepcheck::revdep_details(, "gqlr")` for more info

</details>

## In both

*   checking LazyData ... NOTE
    ```
      'LazyData' is specified without a 'data' directory
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

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘R6’
      All declared Imports should be used.
    ```

# occupationMeasurement

<details>

* Version: 0.3.2
* GitHub: https://github.com/occupationMeasurement/occupationMeasurement
* Source code: https://github.com/cran/occupationMeasurement
* Date/Publication: 2023-09-27 13:40:02 UTC
* Number of recursive dependencies: 125

Run `revdepcheck::revdep_details(, "occupationMeasurement")` for more info

</details>

## Newly fixed

*   checking tests ...
    ```
      Running ‘testthat.R’
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      file.exists(log_file) is not TRUE
      
      `actual`:   FALSE
      `expected`: TRUE 
      ── Error ('test-api.R:369:3'): API logging is working ──────────────────────────
      Error in `file(file, "rt")`: cannot open the connection
      Backtrace:
          ▆
       1. └─utils::read.csv(log_file) at test-api.R:369:3
       2.   └─utils::read.table(...)
       3.     └─base::file(file, "rt")
      
      [ FAIL 13 | WARN 1 | SKIP 10 | PASS 23 ]
      Error: Test failures
      Execution halted
    ```

## In both

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 6986 marked UTF-8 strings
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

*   checking LazyData ... NOTE
    ```
      'LazyData' is specified without a 'data' directory
    ```

# plumbertableau

<details>

* Version: 0.1.1
* GitHub: https://github.com/rstudio/plumbertableau
* Source code: https://github.com/cran/plumbertableau
* Date/Publication: 2023-12-19 02:20:03 UTC
* Number of recursive dependencies: 64

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

# swagger

<details>

* Version: 5.17.14.1
* GitHub: https://github.com/rstudio/swagger
* Source code: https://github.com/cran/swagger
* Date/Publication: 2024-06-28 17:10:02 UTC
* Number of recursive dependencies: 36

Run `revdepcheck::revdep_details(, "swagger")` for more info

</details>

## In both

*   checking installed package size ... NOTE
    ```
      installed size is  6.2Mb
      sub-directories of 1Mb or more:
        dist3   2.0Mb
        dist4   1.7Mb
        dist5   2.1Mb
    ```

# tgver

<details>

* Version: 0.3.0
* GitHub: https://github.com/tgve/tgver
* Source code: https://github.com/cran/tgver
* Date/Publication: 2022-09-30 15:20:03 UTC
* Number of recursive dependencies: 156

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

