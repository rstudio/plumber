
library(plumber)
pr <- pr("myplumberapi.R") %>%
  pr_cookie(
    key = "pleasechangeme",
    name = "cookieName"
  )

# MUST return a Plumber object when using `entrypoint.R`
pr
