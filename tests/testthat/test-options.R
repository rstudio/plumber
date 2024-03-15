context("Options")

test_that("Options set and get", {
  with_options(list(plumber.port = NULL), {
    options_plumber(port = FALSE)
    expect_false(options::opt("port", env = "plumber"))
    options_plumber(port = NULL)
    expect_null(options::opt("port", env = "plumber"))
  })
})

test_that("Options set and get", {
  with_options(list(plumber.port = NULL), {
    Sys.setenv("PLUMBER_PORT" = FALSE)
    expect_false(options::opt("port", env = "plumber"))
    Sys.unsetenv("PLUMBER_PORT")
    expect_null(options::opt("port", env = "plumber"))
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
    match <- stringi::stri_match_all_regex(file_content, "options::opt\\([^,\\)]+,?\\)?")[[1]][,1]
    match <- gsub("\\s", "", match)
    if (length(match) > 0 && !all(is.na(match))) {
      matches <- c(matches, match)
    }
  }
  options_used <- unique(sort(gsub("options::opt|\\(|\"|,|'|\\)", "", matches)))
  ### code to match formals
  formals_to_match <-
    sort(setdiff(
      names(formals(options_plumber)),
      "..."
    ))

  expect_equal(
    options_used,
    formals_to_match
  )
  expect_equal(
    sort(names(options::opts(env = "plumber"))),
    formals_to_match
  )
})


test_that("Legacy swagger redirect can be disabled", {
  with_options(
    list(
      plumber.legacyRedirets = options::opt("legacyRedirects", env = "plumber")
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
      plumber.swagger.url = getOption("plumber.swagger.url"),
      plumber.docs.callback = options::opt("docs.callback", env = "plumber")
    ), {
      options("plumber.swagger.url" = function(api_url) {cat(api_url)})
      opt <- options_plumber(docs.callback = NULL)
      expect_null(getOption("plumber.swagger.url"))
      expect_null(options::opt("docs.callback", env = "plumber"))
    }
  )
})
