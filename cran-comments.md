## Comments

#### 2022-09-06

Releasing a patch to `{plumber}` which has documentation by the latest version of `{roxygen2}`.

Best,
Barret

#### 2022-08-19

....
R 4.2.0 switched to use HTML5 for documentation pages.  Now validation
using HTML Tidy finds problems in the HTML generated from your Rd
files.

To fix, in most cases it suffices to re-generate the Rd files using the
current CRAN version of roxygen2.
....

Best,
-k


## Test environments

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

## R CMD check results

0 errors ✔ | 0 warnings ✔ | 0 notes ✔


## revdepcheck results

We checked 18 reverse dependencies, comparing R CMD check results across CRAN and dev versions of this package.

 * We saw 0 new problems
 * We failed to check 0 packages
