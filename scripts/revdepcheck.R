source("scripts/git_clean.R")

if (!require("revdepcheck")) pak::pkg_install("r-lib/revdepcheck")

# revdepcheck::revdep_reset()
revdepcheck::revdep_check(num_workers = 4)
