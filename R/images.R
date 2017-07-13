render_jpeg <- list(
  pre = function(req, res, data){
    t <- tempfile()
    data$file <- t
    jpeg(t)
  },
  post = function(value, req, res, data){
    dev.off()

    con <- file(data$file, "rb")
    img <- readBin(con, "raw", file.info(data$file)$size)
    close(con)
    res$body <- img
    res$setHeader("Content-type", "image/jpeg")
    res
  }
)

render_png <- list(
  pre = function(req, res, data){
    t <- tempfile()
    data$file <- t
    png(t)
  },
  post = function(value, req, res, data){
    dev.off()

    con <- file(data$file, "rb")
    img <- readBin(con, "raw", file.info(data$file)$size)
    close(con)
    res$body <- img
    res$setHeader("Content-type", "image/png")
    res
  }
)
