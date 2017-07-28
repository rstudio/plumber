library(analogsea)
library(plumber)

install_package_secure <- function(droplet, pkg){
  analogsea::install_r_package(droplet, pkg, repo="https://cran.rstudio.com")
}

drop <- plumber::do_provision(unstable=TRUE, example=FALSE, name="hostedplumber")

do_deploy_api(drop, "append", "./inst/examples/01-append/", 8001)
do_deploy_api(drop, "filters", "./inst/examples/02-filters/", 8002)

# GitHub
install_package_secure(drop, "digest")
# devtools is the other dependency, but by unstable=TRUE on do_provision we already have that
do_deploy_api(drop, "github", "./inst/examples/03-github/", 8003)

# Sessions
droplet_ssh(drop, 'R -e "install.packages(\\"PKI\\",,\\"https://www.rforge.net\\")"')
do_deploy_api(drop, "sessions", "./inst/examples/06-sessions/", 8006,
              preflight="pr$addGlobalProcessor(plumber::sessionCookie('secret', 'cookieName', path='/'));")

# Mailgun
install_package_secure(drop, "htmltools")
do_deploy_api(drop, "mailgun", "./inst/examples/07-mailgun/", 8007)

# MANUAL: configure DNS, then
# do_configure_https(drop, "plumber.tres.tl"... )
