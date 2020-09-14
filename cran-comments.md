## Comments

#### 2020-9-14

I've fixed the urls and resubmitting.

Best,
Barret

#### 2020-9-14

Flavor: r-devel-linux-x86_64-debian-gcc
Check: CRAN incoming feasibility, Result: NOTE
  Maintainer: 'Barret Schloerke <barret@rstudio.com>'

  New maintainer:
    Barret Schloerke <barret@rstudio.com>
  Old maintainer(s):
    Jeff Allen <cran@trestletech.com>

  Found the following (possibly) invalid URLs:
    URL: https://rstudio.github.io/plumber (moved to https://www.rplumber.io/)
      From: README.md
      Status: 200
      Message: OK
    URL: https://www.rstudio.com/products/connect/ (moved to https://rstudio.com/products/connect/)
      From: README.md
      Status: 200
      Message: OK

#### 2020-9-14

This is a major version update.

Please let me know if there is anything else I can provide.

Thank you,
Barret

#### 2020-9-14

Confirmed! You may change the maintainer.

- Jeff

#### 2020-9-14

Hi Jeff,

I'm emailing to have a formal request to change the maintainer in `plumber` to Barret Schloerke...
My I change `plumber`'s maintainer to Barret Schloerke?

Thank you,
Barret


## Test environments

* local macOS, R 4.0.0
* GitHub Actions
  * macOS
    * oldrel, release, devel
  * windows
    * oldrel, release, devel
  * ubuntu18
    * 3.4, 3.5, oldrel, release, devel
  * ubuntu16
    * 3.4, 3.5, oldrel, release, devel

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

* devtools::build_win()
  * checking CRAN incoming feasibility ... NOTE
  Maintainer: 'Barret Schloerke <barret@rstudio.com>'

  New maintainer:
    Barret Schloerke <barret@rstudio.com>
  Old maintainer(s):
    Jeff Allen <cran@trestletech.com>
Status: 1 NOTE

## revdepcheck results

We checked 8 reverse dependencies, comparing R CMD check results across CRAN and dev versions of this package.

 * We saw 0 new problems
 * We failed to check 0 packages
