# Ports that are considered unsafe by Chrome
# http://superuser.com/questions/188058/which-ports-are-considered-unsafe-on-chrome
# https://github.com/rstudio/shiny/issues/1784
unsafePorts <- function() {
  asNamespace("httpuv")[["unsafe_ports"]]
}


randomPort <- function(..., n = 10) {
  tryCatch({
    port <- httpuv::randomPort(..., n = n)
  }, httpuv_unavailable_port = function(e) {
    stop(
      "Unable to start a Plumber server. ",
      paste0("We were unable to find a free port in ", n, " tries.")
    )
  })
  return(port)
}

portIsAvailable <- function(port) {
  tryCatch(
    {
      randomPort(min = port, max = port)
      TRUE
    },
    error = function(e) {
      FALSE
    }
  )
}

#' Find a port either using the assigned port or randomly search 10 times for an
#' available port. If a port was manually assigned, just return it and assume it
#' will work.
#' @noRd
findPort <- function(port = NULL) {
  if (is.null(port)) {
    # Try to use the most recently used _random_ port
    if (
      (!is.null(.globals$last_random_port)) &&
        portIsAvailable(.globals$last_random_port)
    ) {
      return(.globals$last_random_port)
    }

    # Find an available port
    port <- randomPort()

    # Save the random port for future use
    .globals$last_random_port <- port
    return(.globals$last_random_port)
  }

  port_og <- port

  if (rlang::is_character(port)) {
    port <- suppressWarnings(as.integer(port))
  }

  if (!rlang::is_integerish(port, n = 1, finite = TRUE) || port != port_og) {
    stop("Port must be an integer value, not '", port_og, "'.")
  }

  port <- as.integer(port)

  # Ports must be in [1024-49151]
  # https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml
  if (port < 1024 || port > 49151) {
    stop("Port must be an integer in the range 1024 to 49151 (inclusive).")
  }

  if (port == 0 || port %in% unsafePorts()) {
    stop("Port ", port, " is an unsafe port. Please choose another port.")
  }

  port
}
