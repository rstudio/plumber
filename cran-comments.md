## Comments

#### 2020-3-23

Bug fixes and new features.

CRAN checks:
* I have disabled the brittle test that is currently failing on https://www.r-project.org/nosvn/R.check/r-devel-windows-x86_64-gcc10-UCRT/plumber-00check.html . Checking this test on windows GHA only.
* I can not see why this installation is failing: https://www.r-project.org/nosvn/R.check/r-release-windows-ix86+x86_64/plumber-00check.html

Please let me know if there is anything else I can provide.

Thank you,
Barret


#### 2020-1-5

These checks have naturally resolved.

- Barret


#### 2020-12-13

Dear maintainer,

Please see the problems shown on
<https://cran.r-project.org/web/checks/check_results_plumber.html>.

Please correct before 2021-01-08 to safely retain your package on CRAN.

Best,
-k



## Test environments

* local macOS, R 4.0.2
* GitHub Actions
  * macOS
    * oldrel, release, devel
  * windows
    * release, devel
  * ubuntu18
    * 3.4, 3.5, oldrel, release, devel
  * ubuntu16
    * 3.4, 3.5, oldrel, release, devel
* devtools::
  * check_win_devel()
  * check_win_release()
  * check_win_oldrelease()

0 errors ✔ | 0 warnings ✔ | 0 notes ✔


## revdepcheck results

We checked 13 reverse dependencies, comparing R CMD check results across CRAN and dev versions of this package.

 * We saw 0 new problems
 * We failed to check 0 packages
