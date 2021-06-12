# source("scripts/git_clean.R")

if (!require("rhub", quietly = TRUE)) install.packages("rhub")

platforms <- c("windows-x86_64-release", rhub:::default_cran_check_platforms("."))
check_output <- rhub::check_for_cran(
  ".",
  email = "barret@rstudio.com",
  platforms = platforms,
  env_vars = c("_R_CHECK_FORCE_SUGGESTS_" = "0"),
  show_status = FALSE
)

for (i in seq_along(platforms)) {
  check_output$livelog(i)
}

# check_output$web()

print(check_output)
