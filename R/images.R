#' @param imageFun The function to call to setup the image device (Ex: `grDevices::png()`)
#' @param args A list of supplemental arguments to be passed into `imageFun()`
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
      grDevices::dev.off()
      on.exit({unlink(data$file)}, add = TRUE)
      con <- file(data$file, "rb")
      on.exit({close(con)}, add = TRUE)
      img <- readBin(con, "raw", file.info(data$file)$size)
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

render_svg <- function(args){
  render_image(grDevices::svg, args)
}
