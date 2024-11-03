
# Exclude unsafe ports from Chrome https://src.chromium.org/viewvc/chrome/trunk/src/net/base/net_util.cc?view=markup#l127
portBlacklist <- c(0, 3659, 4045, 6000, 6665, 6666, 6667, 6668, 6669)

#' Get a random port between 3k and 10k, excluding the blacklist. If a preferred port
#' has already been registered in .globals, use that instead.
#' @importFrom stats runif
#' @noRd
getRandomPort <- function(){
  port <- 0
  while (port %in% portBlacklist){
    port <- round(runif(1, 3000, 10000))
  }
  port
}

#' Find a port either using the assigned port or randomly search 10 times for an available
#' port. If a port was manually assigned, just return it and assume it will work.
#' @noRd
findPort <- function(port){
  if (missing(port) || is.null(port)){
    if (!is.null(.globals$port)){
      # Start by trying the .globals$port
      port <- .globals$port
    } else {
      port <- getRandomPort()
    }

    for (i in 1:10){
      tryCatch(srv <- httpuv::startServer("127.0.0.1", port, list(), quiet = TRUE), error=function(e){
        port <<- 0
      })
      if (port != 0){
        # Stop the temporary server, and retain this port number.
        httpuv::stopServer(srv)
        .globals$port <- port
        break
      }
      port <- getRandomPort()
    }
  }

  if (port == 0){
    stop("Unable to start a Plumber server. Either the port specified was unavailable or we were unable to find a free port.")
  }

  as.integer(port)
}
