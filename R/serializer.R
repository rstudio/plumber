
#' Add a Serializer
#'
#' A serializer is responsible for translating a generated R value into output
#' that a remote user can understand. For instance, the \code{serializer_json}
#' serializes R objects into JSON before returning them to the user. The list of
#' available serializers in plumber is global.
#'
#' @param name The name of the serializer (character string)
#' @param serializer The serializer to be added.
#'
#' @export
addSerializer <- function(name, serializer) {
  if (!is.null(.globals$serializers[[name]])) {
    stop ("Already have a serializer by the name of ", name)
  }
  .globals$serializers[[name]] <- serializer
}

# internal function to use directly. Others should use `serializer_identity()`
serializer_identity_ <- function(val, req, res, errorHandler) {
  tryCatch({
    res$body <- val
    res$toResponse()
  }, error = function(err) {
    errorHandler(req, res, err)
  })
}
serializer_identity <- function(){
  serializer_identity_
}


# TODO-barret export and document
as_attachment <- function(value, filename = NULL) {
  stopifnot(is.character(filename) || is.null(filename))
  if (is.character(filename)) {
    stopifnot(length(filename) == 1)
  }
  structure(
    list(
      value = value,
      filename = filename
    ),
    class = "plumber_disposition_attachment"
  )
}


#' Plumber Serializers
#'
#' Serializers are used in Plumber to transform the R object produced by a
#' filter/endpoint into an HTTP response that can be returned to the client. See
#' [here](https://book.rplumber.io/articles/rendering-output.html#serializers-1) for
#' more details on Plumber serializers and how to customize their behavior.
#' @describeIn serializers Add a static list of headers to each return value
#' @param ... extra arguments supplied to respective internal serialization function.
#' @param headers `list()` of headers to add to the response object
#' @export
serializer_headers <- function(headers) {
  function(val, req, res, errorHandler) {
    tryCatch({
      Map(names(headers), headers, f = function(header, header_val) {
        # applied to r6 object
        res$setHeader(header, header_val)
      })

      serializer_identity_(val, req, res, errorHandler)
    }, error = function(err) {
      errorHandler(req, res, err)
    })
  }
}



#' @describeIn serializers Adds a `Content-Type` header to the response object
# name can not change!
#' @param type The value to provide for the `Content-Type` HTTP header.
#' @export
serializer_content_type <- function(type) {
  if (missing(type)){
    stop("You must provide the custom content type to the serializer_content_type")
  }
  serialize_type(type, identity)
}

serialize_type <- function(content_type, serialize_fn = identity) {

  function(val, req, res, errorHandler) {
    tryCatch({
      # call serialize_fn within try catch to possibly call error handler
      headers <- list("Content-Type" = content_type)
      if (inherits(val, "plumber_disposition_attachment")) {
        # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition
        headers[["Content-Disposition"]] <-
          if (is.null(val$filename)) {
            "attachment"
          } else {
            paste0(
              "attachment; filename=\"",
              #> path information should be stripped
              basename(val$filename),
              "\""
            )
          }
        # make val the contained value and not the file structure
        val <- val$value
      }
      val <- serialize_fn(val)
      with_headers <- serializer_headers(headers)

      with_headers(val, req, res, errorHandler)
    }, error = function(err) {
      errorHandler(req, res, err)
    })
  }
}


#' @describeIn serializers CSV serializer. See [readr::format_csv()] for more details.
#' @export
serializer_csv <- function(...) {
  if (!requireNamespace("readr", quietly = TRUE)) {
    stop("`readr` must be installed for `serializer_csv` to work")
  }

  serialize_type("text/csv; charset=UTF-8", function(val) {
    readr::format_csv(val, ...)
  })
}



#' @describeIn serializers HTML serializer
#' @export
serializer_html <- function() {
  serialize_type("text/html; charset=UTF-8")
}


#' @describeIn serializers JSON serializer. See [jsonlite::toJSON()] for more details.
#' @export
serializer_json <- function(...) {
  serialize_type("application/json; charset=UTF-8", function(val) {
    toJSON(val, ...)
  })
}

#' @describeIn serializers JSON serializer with `auto_unbox` defaulting to `TRUE`. See [jsonlite::toJSON()] for more details.
#' @inheritParams jsonlite::toJSON
#' @export
serializer_unboxed_json <- function(auto_unbox = TRUE, ...) {
  serializer_json(auto_unbox = auto_unbox, ...)
}




#' @describeIn serializers RDS serializer. See [serialize()] for more details.
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
  serialize_type("application/octet-stream", function(val) {
    base::serialize(val, NULL, ascii = ascii, version = version, ...)
  })
}

#' @describeIn serializers YAML serializer. See [yaml::as.yaml()] for more details.
#' @export
serializer_yaml <- function(...) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("yaml must be installed for the yaml serializer to work")
  }
  serialize_type("application/x-yaml; charset=UTF-8", function(val) {
    yaml::as.yaml(val, ...)
  })
}

#' @describeIn serializers Text serializer. See [format()] for more details.
#' @export
serializer_text <- function(...) {
  serialize_type("text/plain; charset=UTF-8", function(val) {
    format(val, ...)
  })
}



#' @describeIn serializers htmlwidget serializer. See [htmlwidgets::saveWidget()] for more details.
#' @export
serializer_htmlwidget <- function(...) {
  if (!requireNamespace("htmlwidgets", quietly = TRUE)) {
    stop("The htmlwidgets package is not available but is required in order to use the htmlwidgets serializer",
          call. = FALSE)
  }

  serialize_type("text/html; charset=UTF-8", function(val) {
    # Write out a temp file. htmlwidgets (or pandoc?) seems to require that this
    # file end in .html or the selfcontained=TRUE argument has no effect.
    file <- tempfile(fileext = ".html")
    on.exit({
      # Delete the temp file
      file.remove(file)
    })

    # Write the widget out to a file (doesn't currently support in-memory connections - pandoc)
    # Must write a self-contained file. We're not serving a directory of assets
    # in response to this request, just one HTML file.
    htmlwidgets::saveWidget(val, file, selfcontained = TRUE, ...)

    # Read the file back in as a single string and return.
    paste(readLines(file), collapse = "\n")
  })
}


serializer_xml <- function() {
  #if (!requireNamespace("XML", quietly = TRUE)) {
  #  stop("The XML package is not available but is required in order to use the XML serializer.",
  #       call. = FALSE)
  #}
  stop("XML serialization not yet implemented. Please see the discussion at https://github.com/rstudio/plumber/issues/65")
}



add_serializers_onLoad <- function() {
  addSerializer("null",        serializer_identity)
  addSerializer("contentType", serializer_content_type)
  addSerializer("html",        serializer_html)
  addSerializer("csv",         serializer_csv)
  addSerializer("json",        serializer_json)
  addSerializer("unboxedJSON", serializer_unboxed_json)
  addSerializer("rds",         serializer_rds)
  addSerializer("xml",         serializer_xml)
  addSerializer("yaml",        serializer_yaml)
  addSerializer("text",        serializer_text)
  addSerializer("htmlwidget",  serializer_htmlwidget)
}
