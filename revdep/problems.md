# AzureContainers

<details>

* Version: 1.3.0
* Source code: https://github.com/cran/AzureContainers
* URL: https://github.com/Azure/AzureContainers https://github.com/Azure/AzureR
* BugReports: https://github.com/Azure/AzureContainers/issues
* Date/Publication: 2020-05-06 08:10:02 UTC
* Number of recursive dependencies: 57

Run `revdep_details(,"AzureContainers")` for more info

</details>

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘openssl’
      All declared Imports should be used.
    ```

# openmetrics

<details>

* Version: 0.2.0
* Source code: https://github.com/cran/openmetrics
* URL: https://github.com/atheriel/openmetrics
* BugReports: https://github.com/atheriel/openmetrics/issues
* Date/Publication: 2020-07-14 08:00:03 UTC
* Number of recursive dependencies: 45

Run `revdep_details(,"openmetrics")` for more info

</details>

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘R6’
      All declared Imports should be used.
    ```

# rjsonapi

<details>

* Version: 0.1.0
* Source code: https://github.com/cran/rjsonapi
* URL: https://github.com/ropensci/rjsonapi
* BugReports: https://github.com/ropensci/rjsonapi/issues
* Date/Publication: 2017-01-09 01:47:26
* Number of recursive dependencies: 46

Run `revdep_details(,"rjsonapi")` for more info

</details>

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘crul’
      All declared Imports should be used.
    ```

# rsconnect

<details>

* Version: 0.8.16
* Source code: https://github.com/cran/rsconnect
* URL: https://github.com/rstudio/rsconnect
* BugReports: https://github.com/rstudio/rsconnect/issues
* Date/Publication: 2019-12-13 20:00:02 UTC
* Number of recursive dependencies: 59

Run `revdep_details(,"rsconnect")` for more info

</details>

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
       6. base::tryCatch(...)
       7. base:::tryCatchList(expr, classes, parentenv, handlers)
       8. base:::tryCatchOne(expr, names, parentenv, handlers[[1L]])
       9. value[[3L]](cond)
      
      ══ testthat results  ═══════════════════════════════════════════════════════════
      [ OK: 222 | SKIPPED: 25 | WARNINGS: 0 | FAILED: 5 ]
      1. Error: simple http GET works (@test-http.R#90) 
      2. Error: posting JSON works (@test-http.R#118) 
      3. Error: posting with no data works (@test-http.R#152) 
      4. Error: posting file works (@test-http.R#187) 
      5. Error: api key authinfo sets headers (@test-http.R#220) 
      
      Error: testthat unit tests failed
      Execution halted
    ```

