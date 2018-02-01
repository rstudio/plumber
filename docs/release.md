
## Release Steps

1. Create a release branch for the next release.
1. Bump the version # and the date in DESCRIPTION to the next even number for release
1. Bump the version # in NEWS.md to align with ^
1. Run the docker image in inst/check on the release candidate. Note that you will need to change the CMD to checkout the release branch so you're testing it, not master.
1. Submit to CRAN.
1. Do any revisions CRAN requests on the release branch
1. Once accepted to CRAN, merge the release branch to master and tag the release.
1. Bump the version # in DESCRIPTION to the next odd number on master for development of next release.
