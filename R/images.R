#' @param imageFun The function to call to setup the image device (e.g. `png`)
#' @param args A list of supplemental arguments to be passed into jpeg()
#' @importFrom grDevices dev.off jpeg png
#' @noRd
render_image <- function(imageFun, contentType, args=NULL){
  list(
    pre = function(req, res, data){
      t <- tempfile()
      data$file <- t

      finalArgs <- c(list(filename=t), args)
      do.call(imageFun, finalArgs)
    },
    post = function(value, req, res, data){

      res$serializer <- function(val, req, res, errorHandler) {
        tryCatch({
          dev.off()

          con <- file(data$file, "rb")
          img <- readBin(con, "raw", file.info(data$file)$size)
          close(con)
          res$body <- img
          res$setHeader("Content-type", contentType)
          return(res$toResponse())
        }, error = function(e){
             errorHandler(req, res, e)
        })
      }
      value

    }
  )
}

render_jpeg <- function(args){
  render_image(jpeg, "image/jpeg", args)
}

render_png <- function(args){
  render_image(png, "image/png", args)
}
