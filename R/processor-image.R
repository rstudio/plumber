#' @include processor.R
#' @include rapier.R
RapierProcessor$new(
  "jpeg",
  function(req, res, data){
    t <- tempfile()
    data$file <- t
    jpeg(t)
  },
  function(val, req, res, data){
    dev.off()

    if (!requireNamespace("base64enc", quietly = TRUE)) {
      stop("The base64enc package is not available but is required in order to serialize images.",
           call. = FALSE)
    }

    # read base64 file
    con <- file(data$file, "rb")
    img <- readBin(con, "raw", file.info(data$file)$size)
    close(con)
    res$body <- httpuv::rawToBase64(img)
    res$setHeader("Content-type", "image/jpeg")
    res
  }
)

RapierProcessor$new(
  "png",
  function(req, res, data){
    t <- tempfile()
    data$file <- t
    png(t)
  },
  function(val, req, res, data){
    dev.off()

    if (!requireNamespace("base64enc", quietly = TRUE)) {
      stop("The base64enc package is not available but is required in order to serialize images.",
           call. = FALSE)
    }

    # read base64 file
    con <- file(data$file, "rb")
    img <- readBin(con, "raw", file.info(data$file)$size)
    close(con)
    res$body <- httpuv::rawToBase64(img)
    res$setHeader("Content-type", "image/png")
    res
  }
)
