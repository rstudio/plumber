#' @noRd
defaultWebsocket <- function(pr, ser) {
  function(ws) {
    req <- ws$request
    req$ws <- ws
    req$pr <- pr
    ws$onMessage(function(binary, message) {
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
      ws$send(paste("_status_", res$status))
      ws$send(paste("_headers_", paste(names(res$headers), unlist(res$headers), sep = "=", collapse = ";")))
      ws$send("_body_ nextmessage")
      ws$send(res$body)
    })
  }
}
