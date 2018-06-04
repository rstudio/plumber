# Comments

## 2018-6-4
This submission is done by Barret Schloerke <barret@rstudio.com> on behalf of Jeff Allen <cran@trestletech.com>. Please submit any changes to be made to <barret@rstudio.com>.

- Barret


## Test environments

All NOTEs related to invalid URLs http:localhost:8000 are **false positives**.  The URL makes sense when looking at the example within the README.md file.

* local OS X install, R 3.5.0, --run-dontcheck
  * 0 errors | 0 warnings | 0 notes
* ubuntu 14.04.5 (on travis-ci), R version 3.5.0 (2017-01-27)
  * 0 errors | 0 warnings | 0 notes
* devtools::build_win()
  * x86_64-w64-mingw32, R version 3.5.0 (2018-04-23)
  * x86_64-w64-mingw32, R Under development (unstable) (2018-06-03 r74839)
    * checking CRAN incoming feasibility ... NOTE
    Found the following (possibly) invalid URLs:
      URL: http://localhost:8000/echo?msg=hello
        From: README.md
        Status: Error
        Message: libcurl error code 7:
          	Failed to connect to localhost port 8000: Connection refused
      URL: http://localhost:8000/plot
        From: README.md
        Status: Error
        Message: libcurl error code 7:
          	Failed to connect to localhost port 8000: Connection refused
    * 0 errors | 0 warnings | 1 note


* r-hub

  * Platform:   Ubuntu Linux 16.04 LTS, R-release, GCC
    * checked with `_R_CHECK_FORCE_SUGGESTS_=0`
    http://builder.r-hub.io/status/plumber_0.4.6.tar.gz-7eb7117f2cf74e1b8880c46e7819ab61
    ❯ checking CRAN incoming feasibility ... NOTE
      Maintainer: ‘Jeff Allen <cran@trestletech.com>’

      Found the following (possibly) invalid URLs:
        URL: http://localhost:8000/echo?msg=hello
          From: README.md
          Status: Error
          Message: libcurl error code 7:
          	Failed to connect to localhost port 8000: Connection refused
        URL: http://localhost:8000/plot
          From: README.md
          Status: Error
          Message: libcurl error code 7:
          	Failed to connect to localhost port 8000: Connection refused
    0 errors ✔ | 0 warnings ✔ | 1 note ✖


  * rhub platform issues:
    * Windows Server 2008 R2 SP1, R-release, 32/64 bit
      * 'stringi' is not available
    * Windows Server 2008 R2 SP1, R-devel, 32/64 bit
      * 'stringi' is not available
    * Fedora Linux, R-devel, clang, gfortran
      * Has trouble opening a png device


## Reverse dependencies

* Revdep maintainers were not contacted as this release is for bug fixes and enhancements from particular maintainers.

* I have run R CMD check on the 3 downstream dependencies.
  * https://github.com/trestletech/plumber/blob/master/revdep/problems.md
  * No errors, warnings, or notes were introduced due to changes in leaflet

* All revdeps were able to be tested
