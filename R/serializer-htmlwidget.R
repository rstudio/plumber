#' @include globals.R
#' @rdname serializers
#' @export
serializer_htmlwidget <- function(){
  function(val, req, res, errorHandler){
    tryCatch({
      if (!requireNamespace("htmlwidgets", quietly = TRUE)) {
        stop("The htmlwidgets package is not available but is required in order to use the htmlwidgets serializer",
             call. = FALSE)
      }

      # Set content type to HTML
      res$setHeader("Content-Type", "text/html; charset=utf-8")

      # Write out a temp file. htmlwidgets (or pandoc?) seems to require that this
      # file end in .html or the selfcontained=TRUE argument has no effect.
      file <- tempfile(fileext=".html")

      # Write the widget out to a file (doesn't currently support in-memory connections)
      # Must write a self-contained file. We're not serving a directory of assets
      # in response to this request, just one HTML file.
      htmlwidgets::saveWidget(val, file, selfcontained=TRUE)

      # Read the file back in as a single string and return.
      res$body <- paste(readLines(file), collapse="\n")

      # Delete the temp file
      file.remove(file)

      return(res$toResponse())
    }, error=function(e){
      errorHandler(req, res, e)
    })
  }
}

.globals$serializers[["htmlwidget"]] <- serializer_htmlwidget
