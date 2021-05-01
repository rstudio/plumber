#' HTTP Date String
#'
#' Given a POSIXct object, return a date string in the format required for a
#' HTTP Date header. For example: "Wed, 21 Oct 2015 07:28:00 GMT"
#'
#' @noRd
http_date_string <- function(time) {
  lt <- as.POSIXlt(time, tz = "UTC")
  weekdays <- c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
  months <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun",
              "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
  weekday <- weekdays[lt$wday + 1]
  month <- months[lt$mon + 1]
  fmt <- paste0(weekday, ", %d ", month, " %Y %H:%M:%S GMT")
  strftime(time, fmt, tz = "GMT")
}

is_available <- function(package, version = NULL) {
  installed <- nzchar(system.file(package = package))
  if (is.null(version)) {
    return(installed)
  }
  installed && isTRUE(utils::packageVersion(package) >= version)
}

`%||%` <- function(x, y) {
  if (is.null(x)) {
    y
  } else {
    x
  }
}

`%|%` <- function(x, y) {
  if (length(x) > 1) {
    stopifnot(length(y) == 1)
    x[is.na(x)] <- y
    return(x)
  }

  if (is.na(x)) {
    y
  } else {
    x
  }
}

once <- function(f) {
  called <- FALSE

  function() {
    if (!called) {
      called <<- TRUE
      f()
      invisible(TRUE)
    } else {
      invisible(FALSE)
    }
  }
}
