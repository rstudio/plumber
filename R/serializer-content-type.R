#' @rdname serializers
#' @param type The value to provide for the `Content-Type` HTTP header.
#' @param disposition The value to provide for the `Disposition` HTTP header.
#' @param filename The value to provide for the `Filename`.
#' @export
serializer_content_type <- function(type, disposition = NULL, filename = NULL) {
  if (missing(type)) {
    stop("You must provide the custom content type to the serializer_content_type_disposition")
  }

  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition
  if (!is.null(disposition)) {
    disposition <- match.arg(disposition, c("inline", "attachment"))
    if (disposition == "attachment" && !is.null(filename)) {
      filename <- as.character(filename)
      if (grepl("\"", filename, fixed = TRUE)) {
        stop("quotes can not be used in the value of `filename`")
      }
      disposition <- paste0(disposition, "; filename=\"", filename, "\"")
    }
  }

  function(val, req, res, errorHandler) {
    tryCatch({
      res$setHeader("Content-Type", type)
      if (!is.null(disposition)) {
        res$setHeader("Content-Disposition", disposition)
      }
      res$body <- val

      return(res$toResponse())
    }, error=function(e) {
      errorHandler(req, res, e)
    })
  }
}

#' @include globals.R
.globals$serializers[["contentType"]] <- serializer_content_type
