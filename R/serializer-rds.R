#' @rdname serializers
#' @inheritParams base::serialize
#' @export
serializer_rds <- function(version = "2", ascii = FALSE, ...) {
  if (identical(version, "3")) {
    if (package_version(R.version) < "3.5") {
      stop(
        "R versions before 3.5 do not know how to serialize with `version = \"3\"`",
        "\n Current R version: ", as.character(package_version(R.version))
      )
    }
  }
  function(val, req, res, errorHandler) {
    tryCatch({
      res$setHeader("Content-Type", "application/octet-stream")
      res$body <- base::serialize(val, NULL, ascii = ascii, ...)
      return(res$toResponse())
    }, error = function(e){
      errorHandler(req, res, e)
    })
  }
}


#' @rdname serializers
#' @inheritParams base::serialize
#' @export
serializer_rds3 <- function(version = "3", ascii = FALSE, ...) {
  serializer_rds(version = version, ascii = ascii, ...)
}

#' @include globals.R
.globals$serializers[["rds"]] <- serializer_rds
.globals$serializers[["rds3"]] <- serializer_rds3
