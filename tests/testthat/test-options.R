context("Options")

test_that("Options set and get", {
  with_options(list(plumber.port = NULL), {
    options_plumber(port = FALSE)
    expect_false(get_option_or_env("plumber.port"))
    options_plumber(port = NULL)
    expect_null(get_option_or_env("plumber.port"))
  })
})

test_that("Options set and get", {
  with_options(list(plumber.port = NULL), {
    Sys.setenv("PLUMBER_PORT" = FALSE)
    expect_false(get_option_or_env("plumber.port"))
    Sys.unsetenv("PLUMBER_PORT")
    expect_null(get_option_or_env("plumber.port"))
  })
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
    if (length(match) > 0 && !all(is.na(match))) {
      matches <- c(matches, match)
    }
  }
  options_used <- unique(sort(gsub("getOption|\\(|\"|,|'|\\)", "", matches)))
  plumber_options_used <- grep("^plumber", options_used, value = TRUE)
  deprecated_options <-  c("plumber.swagger.url")
  plumber_options_used <- plumber_options_used[!(plumber_options_used %in% deprecated_options)]
  ### code to match formals
  formals_to_match <-
    sort(setdiff(
      names(formals(options_plumber)),
      "..."
    ))
  options_plumber_formals <- paste0("plumber.", formals_to_match)

  expect_equal(
    plumber_options_used,
    options_plumber_formals
  )
})


test_that("Legacy swagger redirect can be disabled", {
  with_options(
    list(
      plumber.legacyRedirets = get_option_or_env("plumber.legacyRedirects")
    ), {
      options_plumber(legacyRedirects = TRUE)
      redirects <- swagger_redirects()
      expect_gt(length(redirects), 0)

      options_plumber(legacyRedirects = FALSE)
      redirects <- swagger_redirects()
      expect_equal(length(redirects), 0)
    }
  )
})

test_that("docs.callback sync plumber.swagger.url", {
  with_options(
    list(
      plumber.swagger.url = get_option_or_env("plumber.swagger.url"),
      plumber.docs.callback = get_option_or_env("plumber.docs.callback")
    ), {
      options("plumber.swagger.url" = function(api_url) {cat(api_url)})
      opt <- options_plumber(docs.callback = NULL)
      expect_null(get_option_or_env("plumber.swagger.url"))
      expect_null(opt$plumber.docs.callback)
    }
  )
})
