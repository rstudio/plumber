library(analogsea)
library(plumber)

install_package_secure <- function(droplet, pkg){
  analogsea::install_r_package(droplet, pkg, repo="https://cran.rstudio.com")
}

drop <- plumber::do_provision(unstable=TRUE, example=FALSE, name="hostedplumber")

do_deploy_api(drop, "append", "./inst/plumber/01-append/", 8001)
do_deploy_api(drop, "filters", "./inst/plumber/02-filters/", 8002)

# GitHub
install_package_secure(drop, "digest")
# remotes is the other dependency, but by unstable=TRUE on do_provision we already have that
do_deploy_api(drop, "github", "./inst/plumber/03-github/", 8003)

# Sessions
do_deploy_api(drop, "sessions", "./inst/plumber/06-sessions/", 8006,
              preflight="pr$registerHooks(plumber::sessionCookie('secret', 'cookieName', path='/'));")

# Mailgun
install_package_secure(drop, "htmltools")
do_deploy_api(drop, "mailgun", "./inst/plumber/07-mailgun/", 8007)

# MANUAL: configure DNS, then
# do_configure_https(drop, "plumber.tres.tl"... )
