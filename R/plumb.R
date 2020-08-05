#' Process a Plumber API
#'
#' @details API routers are the core request handler in plumber. A router is responsible for
#' taking an incoming request, submitting it through the appropriate filters and
#' eventually to a corresponding endpoint, if one is found.
#'
#' See \url{http://www.rplumber.io/articles/programmatic-usage.html} for additional
#' details on the methods available on this object.
#' @param file The file to parse as the plumber router definition.
#' @param dir The directory containing the `plumber.R` file to parse as the
#'   plumber router definition. Alternatively, if an `entrypoint.R` file is
#'   found, it will take precedence and be responsible for returning a runnable
#'   router.
#' @export
plumb <- function(file = NULL, dir = ".") {

  if (!is.null(file) && !identical(dir, ".")) {
    # both were explicitly set.
    # assume it is a file in that dir and continue like normal
    file <- file.path(
      # removing trailing slash in dir
      normalize_dir_path(dir),
      file
    )
  }

  if (is.null(file)) {
    if (identical(dir, "")) {
      # dir and file are both empty. Error
      stop("You must specify either a file or directory parameter")
    }

    dir <- normalize_dir_path(dir)

    # if the entrypoint file exists...
    entrypoint <- list.files(dir, "^entrypoint\\.r$", ignore.case = TRUE)
    if (length(entrypoint) >= 1) {
      if (length(entrypoint) > 1) {
        entrypoint <- entrypoint[1]
        warning("Found multiple files named 'entrypoint.R'. Using: '", entrypoint, "'")
      }

      # set working directory to dir before sourcing
      old_wd <- setwd(dir)
      on.exit(setwd(old_wd), add = TRUE)

      # Expect that entrypoint will provide us with the router
      #   Do not 'poison' the global env. Using a local environment that points to global env.
      #   sourceUTF8 returns the (visible) value object. No need to call source()$value()
      pr <- sourceUTF8(entrypoint, new.env(parent = globalenv()))

      if (!inherits(pr, "plumber")){
        stop("'", entrypoint, "' must return a runnable Plumber router.")
      }

      # return plumber object
      return(pr)
    }

    # Find plumber.R in the directory case-insensitive
    file <- list.files(dir, "^plumber\\.r$", ignore.case = TRUE, full.names = TRUE)
    if (length(file) == 0) {
      stop("No plumber.R file found in the specified directory: ", dir)
    }
    if (length(file) > 1) {
      file <- file[1]
      warning("Found multiple files named 'plumber.R' in directory: '", dir, "'.\nUsing: '", file, "'")
    }
    # continue as if a file has been provided...
  }

  if (!file.exists(file)) {
    # Couldn't find the Plumber file nor an entrypoint
    stop("File does not exist: ", file)
  }

  # Plumber file found
  plumber$new(basename(file))
}




#' Process a Package's Plumber API
#'
#' So that packages can ship multiple plumber routers, users should store their Plumber APIs
#' in the `inst` subfolder `plumber` (`./inst/plumber/API_1/plumber.R`).
#'
#' To view all available Plumber APIs across all packages, please call `available_apis()`.
#' A `package` value may be provided to only display a particular package's Plumber APIs.
#'
#' @param package Package to inspect
#' @param name Name of the package folder to [plumb()].
#' @describeIn plumb_api [plumb()]s a package's Plumber API. Returns a [`plumber`] router object
#' @export
plumb_api <- function(package = NULL, name = NULL) {

  if (is.null(package)) {
    stop("`package` is require for `plumb_api()`")
  }
  if (is.null(name)) {
    stop("`name` is require for `plumb_api()`")
  }

  stopifnot(length(package) == 1)
  stopifnot(length(name) == 1)
  stopifnot(is.character(package))
  stopifnot(is.character(name))

  apis <- available_apis(package = package)
  apis_sub <- (apis$package == package) & (apis$name == name)
  if (sum(apis_sub) == 0) {
    stop("Could not find Plumber API for package '", package, "'  with name '", name, "'")
  }

  plumb(
    dir = system.file(
      file.path("plumber", name),
      package = package
    )
  )
}


#' @describeIn plumb_api Displays all available package Plumber APIs. Returns a `data.frame` of `package` and `name` information.
#' @export
available_apis <- function(package = NULL) {
  info <-
    if (is.null(package)) {
      all_available_apis()
    } else {
      available_apis_for_package(package)
    }
  if (!is.null(info$error)) {
    stop(info$error, call. = FALSE)
  }
  apis <- info$apis
  return(apis)
}


#' @return will return a list of `error` and `apis`.
#'   `apis` is a \code{data.frame} containing
#'    "package": name of package; string
#'    "name": API directory. (can be passed in as `plumb_api(PKG, NAME)`; string
#' @noRd
available_apis_for_package <- function(package) {

  an_error <- function(...) {
    list(
      apis = NULL,
      error = paste0(...)
    )
  }

  if (!file.exists(
    system.file(package = package)
  )) {
    return(an_error(
      "No package found with name: \"", package, "\""
    ))
  }

  apis_dir <- system.file("plumber", package = package)
  if (!file.exists(apis_dir)) {
    return(an_error(
      "No Plumber APIs found for package: \"", package, "\""
    ))
  }

  api_folders <- list.dirs(apis_dir, full.names = TRUE, recursive = FALSE)
  names(api_folders) <- basename(api_folders)

  api_info <- lapply(api_folders, function(api_dir) {
    api_files <- dir(api_dir)
    if (!any(c("plumber.r", "entrypoint.r") %in% tolower(api_files))) {
      # could not find any plumber files. Quitting
      return(NULL)
    }

    # did find a plumb file. Can return the dir
    data.frame(
      package = package,
      name = basename(api_dir),
      stringsAsFactors = FALSE,
      row.names = FALSE
    )
  })

  has_no_api <- vapply(api_info, is.null, logical(1))
  if (all(has_no_api)) {
    return(an_error(
      "No Plumber APIs found for package: \"", package, "\""
    ))
  }

  api_info <- api_info[!has_no_api]

  apis <- do.call(rbind, api_info)
  class(apis) <- c("plumber_available_apis", class(apis))
  rownames(apis) <- NULL

  list(
    apis = apis,
    error = NULL
  )
}

#' @return will return a list of `error` and `apis` which is a \code{data.frame} containing "package", and "name"
#'
#' @importFrom utils installed.packages
#' @noRd
all_available_apis <- function() {
  ret <- list()
  all_pkgs <- installed.packages()[,"Package"]

  for (pkg in all_pkgs) {
    info <- available_apis_for_package(pkg)
    if (!is.null(info$apis)) {
      ret[[length(ret) + 1]] <- info$apis
    }
  }

  # do not check for size 0, as plumber contains apis.

  apis <- do.call(rbind, ret)

  list(
    apis = apis, # will maintain class
    error = NULL
  )
}


#' @export
format.plumber_available_apis <- function(x, ...) {
  apis <- x

  pkg_apis <- vapply(
    unique(apis$package),
    function(pkg) {
      paste0(
        "* ", pkg, "\n",
        paste0("  - ", apis$name[apis$package == pkg], collapse = "\n")
      )
    },
    character(1)
  )

  paste0(
    "Available Plumber APIs:\n",
    paste0(pkg_apis, collapse = "\n")
  )
}


#' @export
print.plumber_available_apis <- function(x, ...) {
  cat(format(x, ...), "\n", sep = "")
}
