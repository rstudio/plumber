## Comments

#### 2022-7-7

No response from early reply to CRAN. Resubmitting `{plumber}` package.

- Barret


#### 2022-6-26

Hi CRAN submissions,

I believe the single NOTE for r-devel-windows is a false-positive. I can not reproduce this error locally in R 4.2 or R 4.1.  It looks like devel is failing to clean up a test / script.

If there is a file that I am not cleaning up properly, please let me know and I will remove it and resubmit the package

Thank you,
Barret

#### 2022-6-26

Dear maintainer,

package plumber_1.2.0.tar.gz does not pass the incoming checks automatically, please see the following pre-tests:
Windows: <https://win-builder.r-project.org/incoming_pretest/plumber_1.2.0_20220626_055715/Windows/00check.log>
Status: 1 NOTE

Flavor: r-devel-windows-x86_64
Check: for detritus in the temp directory, Result: NOTE
  Found the following files/directories:
    'Rscript4f84526e1abc' 'Rscriptf3d8526e1aac'

#### 2022-6-25

Bug fixes and new features.

CRAN checks:
* I have disabled the brittle test that is currently failing on r-oldrel-windows-ix86+x86_64 for windows platforms only
* `LazyData` field in DESCRIPTION has been removed

Please let me know if there is anything else I can provide.

Thank you,
Barret


## Test environments

I believe this is a false positive as I am not running any Rscript calls.

* devtools::
  * check_win_devel()
```
    * checking for detritus in the temp directory ... NOTE
    Found the following files/directories:
      'Rscript114b08aee34ea' 'Rscript4b588aee34ea'
```

0 errors ✔ | 0 warnings ✔ | 1 note

----------------------

* local macOS, R 4.1.3
* GitHub Actions
  * macOS
    * 4.2
  * windows
    * 4.2
  * ubuntu18
    * devel, 4.2, 4.1, 4.0, 3.6, 3.5
* devtools::
  * check_win_devel()
  * check_win_release()
  * check_win_oldrelease()

0 errors ✔ | 0 warnings ✔ | 0 notes ✔


## revdepcheck results

We checked 18 reverse dependencies, comparing R CMD check results across CRAN and dev versions of this package.

 * We saw 0 new problems
 * We failed to check 0 packages
