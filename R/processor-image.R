#' @include processor.R
#' @include plumber.R
PlumberProcessor$new(
  "jpeg",
  function(req, res, data){
    t <- tempfile()
    data$file <- t
    jpeg(t)
  },
  function(val, req, res, data){
    dev.off()

    con <- file(data$file, "rb")
    img <- readBin(con, "raw", file.info(data$file)$size)
    close(con)
    res$body <- img
    res$setHeader("Content-type", "image/jpeg")
    res
  }
)

PlumberProcessor$new(
  "png",
  function(req, res, data){
    t <- tempfile()
    data$file <- t
    if(!is.null(req$width)) {
      width <- req$width
    } else {
      req$width <- 480
    }
    png(t, width = req$width)
  },
  function(val, req, res, data){
    dev.off()

    con <- file(data$file, "rb")
    img <- readBin(con, "raw", file.info(data$file)$size)
    close(con)
    res$body <- img
    res$setHeader("Content-type", "image/png")
    res
  }
)
