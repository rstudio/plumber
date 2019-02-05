source("scripts/git_clean.R")

if (!require("revdepcheck")) devtools::install_github("r-lib/revdepcheck")

# revdepcheck::revdep_reset()
revdepcheck::revdep_check(num_workers = 4)
