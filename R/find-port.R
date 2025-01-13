# Exclude unsafe ports from Chrome https://src.chromium.org/viewvc/chrome/trunk/src/net/base/net_util.cc?view=markup#l127
unsafePortList <- c(0, asNamespace("httpuv")[["unsafe_ports"]])

#' Get a random port between 3k and 10k, excluding the blacklist. If a preferred port
#' has already been registered in .globals, use that instead.
#' @importFrom stats runif
#' @noRd
getRandomPort <- function() {
  port <- 0
  while (port %in% unsafePortList) {
    port <- round(runif(1, 3000, 10000))
  }
  port
}

findRandomPort <- function() {
  port <- 
    if (!is.null(.globals$port)) {
      # Start by trying the .globals$port
      .globals$port
    } else {
      getRandomPort()
    }

  for (i in 1:10) {
    tryCatch(
      srv <- httpuv::startServer("127.0.0.1", port, list(), quiet = TRUE),
      error = function(e) {
        port <<- 0
      }
    )
    if (port != 0) {
      # Stop the temporary server, and retain this port number.
      httpuv::stopServer(srv)
      .globals$port <- port
      break
    }
    port <- getRandomPort()
  }

  if (port == 0) {
    stop(
      "Unable to start a Plumber server. We were unable to find a free port in 10 tries."
    )
  }

  as.integer(port)
}

#' Find a port either using the assigned port or randomly search 10 times for an available
#' port. If a port was manually assigned, just return it and assume it will work.
#' @noRd
findPort <- function(port = NULL) {
  if (is.null(port)) {
    return(findRandomPort())
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

  if (port %in% unsafePortList) {
    stop("Port ", port, " is an unsafe port. Please choose another port.")
  }

  port
}
