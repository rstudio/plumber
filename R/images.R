#' @param imageFun The function to call to setup the image device (e.g. `png`)
#' @param args A list of supplemental arguments to be passed into jpeg()
#' @importFrom grDevices dev.off jpeg png
#' @noRd
render_image <- function(imageFun, args=NULL){
  list(
    preexec = function(req, res, data){
      t <- tempfile()
      data$file <- t

      finalArgs <- c(list(filename=t), args)
      do.call(imageFun, finalArgs)
    },
    postexec = function(value, req, res, data){
      dev.off()
      on.exit(unlink(data$file))
      con <- file(data$file, "rb")
      img <- readBin(con, "raw", file.info(data$file)$size)
      close(con)
      img
    }
  )
}

render_jpeg <- function(args){
  render_image(grDevices::jpeg, args)
}

render_png <- function(args){
  render_image(grDevices::png, args)
}
