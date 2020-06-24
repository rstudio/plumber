context("Options")

test_that("Options set and get", {
  option_value <- getOption("plumber.postBody")
  options_plumber(postBody = FALSE)
  expect_false(getOption("plumber.postBody"))
  options_plumber(postBody = NULL)
  expect_null(getOption("plumber.postBody"))
  options(plumber.postBody = option_value)
})

test_that("all options used are `options_plumber()` parameters", {
  skip_on_cran() # only test in CI / locally

  ## `./R` will not exist when shiny is installed
  r_folder <- "../../R"
  if (
    # not local structure
    !dir.exists(r_folder) ||
    # must contain many files, not just the three files typically found in installed folder
    length(dir(r_folder)) < 10
  ) {
    skip("Not testing locally. Skipping")
  }

  matches <- character()
  for (r_file in dir(r_folder, full.names = T)) {
    file_content <- paste0(readLines(r_file, warn = F), collapse = "")
    match <- stringi::stri_match_all_regex(file_content, "getOption\\([^,\\)]+,?\\)?")[[1]][,1]
    match <- gsub("\\s", "", match)
    if (length(match) > 0 && !is.na(match)) {
      matches <- c(matches, match)
    }
  }
  options_used <- unique(sort(gsub("getOption|\\(|\"|,|'|\\)", "", matches)))
  plumber_options_used <- grep("^plumber", options_used, value = TRUE)
  ### code to match formals
  options_plumber_formals <- paste0("plumber.", sort(names(formals(optionsPlumber))))

  expect_equal(
    plumber_options_used,
    options_plumber_formals
  )
})
