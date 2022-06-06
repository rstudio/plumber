## Comments

#### 2022-6-13

Bug fixes and new features.

CRAN checks:
* I have disabled the brittle test that is currently failing on r-oldrel-windows-ix86+x86_64 for windows platforms only
* `LazyData` field in DESCRIPTION has been removed

Please let me know if there is anything else I can provide.

Thank you,
Barret



## Test environments

* local macOS, R 4.1.3
* GitHub Actions
  * macOS
    * oldrel, release, devel
  * windows
    * release, devel
  * ubuntu18
    * 3.5, 3.6, oldrel, release, devel
  * ubuntu16
    * 3.5, 3.6, oldrel, release, devel
* devtools::
  * check_win_devel()
  * check_win_release()
  * check_win_oldrelease()

0 errors ✔ | 0 warnings ✔ | 0 notes ✔


## revdepcheck results

We checked 18 reverse dependencies, comparing R CMD check results across CRAN and dev versions of this package.

 * We saw 0 new problems
 * We failed to check 0 packages
