
## Check Steps

1. `devtools::document()`
1. `devtools::check()`
1. `devtools::install()`
1. `source("scripts/rhub.R")`
  * Copy urls and final outputs into cran comments
1. `source("scripts/revdepcheck.R")`
1. `devtools::release()`,
  * (don't actually release in the last step)
  * DON'T LIE!!
1. Run the docker image in inst/check on the release candidate. Note that you will need to change the CMD to checkout the release branch so you're testing it, not master.
  1. ```{bash}
cd inst/check
docker build -t plumber_docker .
docker run plumber_docker
```


## Release Steps

1. Create a release branch for the next release.
1. Bump the version # in DESCRIPTION to the next even number for release
1. Bump the version # in NEWS.md to align with ^
1. Run check steps above
1. Submit to CRAN.
  1. `devtools::release()` (actually release)
1. Do any revisions CRAN requests on the release branch
1. Once accepted to CRAN, merge the release branch to master and tag the release.
1. Bump the version # in DESCRIPTION to the next odd number on master for development of next release.
