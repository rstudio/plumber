#' @noRd
defaultWebsocket <- function(pr, ser) {
  function(ws) {
    ws$onMessage(function(binary, message) {
      req <- ws$request
      req$ws <- ws
      req$pr <- pr
      req$.internal <- new.env()
      req$args <- list()
      req$bodyRaw <- message
      delayedAssign(
        "postBody",
        {
          if (binary) rawToChar(message) else message
        },
        assign.env = req
      )
      req$.internal$bodyHandled <- TRUE
      res <- PlumberResponse$new(ser)
      pr$serve(req, res)
      if (res$status == "200") {
        ws$send(res$body)
      } else {
        ws$send(paste(res$status, res$body))
      }
    })
  }
}
