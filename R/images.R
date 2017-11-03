#' @param args A list of supplemental arguments to be passed into jpeg()
#' @noRd
render_jpeg <- function(args=NULL){
  list(
    pre = function(req, res, data){
      t <- tempfile()
      data$file <- t

      finalArgs <- c(list(filename=t), args)
      do.call(jpeg, finalArgs)
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
}

#' @param args A list of supplemental arguments to be passed into png()
#' @noRd
render_png <- function(args=NULL){
  list(
    pre = function(req, res, data){
      t <- tempfile()
      data$file <- t

      finalArgs <- c(list(filename=t), args)
      do.call(png, finalArgs)
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
}
