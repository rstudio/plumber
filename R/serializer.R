
#' Register a Serializer
#'
#' A serializer is responsible for translating a generated R value into output
#' that a remote user can understand. For instance, the \code{serializer_json}
#' serializes R objects into JSON before returning them to the user. The list of
#' available serializers in plumber is global.
#'
#' @param name The name of the serializer (character string)
#' @param serializer The serializer to be added.
#' @param verbose Logical value which determines if a message should be printed when overwriting serializers
#' @describeIn register_serializer Register a serializer with a name
#' @export
register_serializer <- function(name, serializer, verbose = TRUE) {
  if (!is.null(.globals$serializers[[name]])) {
    if (isTRUE(verbose)) {
      message("Overwriting serializer: ", name)
    }
  }
  .globals$serializers[[name]] <- serializer
}
#' @describeIn register_serializer Return a list of all registered serializers
#' @export
registered_serializers <- function(name) {
  sort(names(.globals$serializers))
}


# internal function to use directly within this file only. (performance purposes)
# Other files should use `serializer_identity()` to avoid confusion
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


#' Return an attachment response
#'
#' This will set the appropriate fields in the `Content-Disposition` header value.
#' To make sure the attachement is used, be sure your serializer eventually calls `serializer_headers`
#'
#' @param value Response value to be saved
#' @param filename File name to use when saving the attachment.
#'   If no `filename` is provided, the `value` will be treated as a regular attachment
#' @return Object with class `"plumber_attachment"`
#' @export
#' @examples
#' # plumber.R
#'
#' #' @get /data
#' #' @serializer csv
#' function() {
#'   # will cause the file to be saved as `iris.csv`, not `data` or `data.csv`
#'   as_attachment(iris, "iris.csv")
#' }
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
    class = "plumber_attachment"
  )
}


#' Plumber Serializers
#'
#' Serializers are used in Plumber to transform the R object produced by a
#' filter/endpoint into an HTTP response that can be returned to the client. See
#' [here](https://book.rplumber.io/articles/rendering-output.html#serializers-1) for
#' more details on Plumber serializers and how to customize their behavior.
#' @describeIn serializers Add a static list of headers to each return value. Will add `Content-Disposition` header if a value is the result of `as_attachment()`.
#' @param ... extra arguments supplied to respective internal serialization function.
#' @param headers `list()` of headers to add to the response object
#' @param serialize_fn Function to serialize the data. The result object will be converted to a character string. Ex: [jsonlite::toJSON()].
#' @export
serializer_headers <- function(headers = list(), serialize_fn = identity) {
  stopifnot(is.function(serialize_fn))
  stopifnot(is.list(headers))

  function(val, req, res, errorHandler) {
    tryCatch({

      # handle `as_attachment()` before serializing
      if (inherits(val, "plumber_attachment")) {
        # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition
        #> Used on the body itself, Content-Disposition has no effect.
        ## Therefore `Content-Type` MUST exist
        if (!is.null(headers[["Content-Type"]])) {
          # do not overwrite pre-existing header value
          if (is.null(headers[["Content-Disposition"]])) {
            headers[["Content-Disposition"]] <-
              if (is.null(val$filename)) {
                "attachment"
              } else {
                #> path information should be stripped
                filename <- basename(val$filename)
                if (stri_detect_fixed(filename, "\"") || stri_detect_fixed(filename, "'")) {
                  stop("`filename` may not contain quotes")
                }
                paste0("attachment; filename=\"", filename, "\"")
              }
          }
        }
        # make `val` the contained value and not the `as_attachment()` structure
        val <- val$value
      }

      # set headers after upgrading headers
      Map(names(headers), headers, f = function(header, header_val) {
        # `res` is an R6 object
        res$setHeader(header, header_val)
      })

      # serialize
      val <- serialize_fn(val)

      # return value
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
serializer_content_type <- function(type, serialize_fn = identity) {
  if (missing(type)){
    stop("You must provide the custom content type to the serializer_content_type")
  }

  serializer_headers(
    list("Content-Type" = type),
    serialize_fn
  )
}

#' @describeIn serializers CSV serializer. See \code{\link[readr:format_delim]{readr::format_csv()}} for more details.
#' @export
serializer_csv <- function(...) {
  if (!requireNamespace("readr", quietly = TRUE)) {
    stop("`readr` must be installed for `serializer_csv` to work")
  }

  serializer_content_type("text/csv; charset=UTF-8", function(val) {
    readr::format_csv(val, ...)
  })
}



#' @describeIn serializers HTML serializer
#' @export
serializer_html <- function() {
  serializer_content_type("text/html; charset=UTF-8")
}


#' @describeIn serializers JSON serializer. See [jsonlite::toJSON()] for more details.
#' @export
#' @importFrom jsonlite toJSON
serializer_json <- function(...) {
  serializer_content_type("application/json; charset=UTF-8", function(val) {
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
  serializer_content_type("application/octet-stream", function(val) {
    base::serialize(val, NULL, ascii = ascii, version = version, ...)
  })
}

#' @describeIn serializers YAML serializer. See [yaml::as.yaml()] for more details.
#' @export
serializer_yaml <- function(...) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("yaml must be installed for the yaml serializer to work")
  }
  serializer_content_type("application/x-yaml; charset=UTF-8", function(val) {
    yaml::as.yaml(val, ...)
  })
}

#' @describeIn serializers Text serializer. See [as.character()] for more details.
#' @export
serializer_text <- function(..., serialize_fn = as.character) {
  serializer_content_type("text/plain; charset=UTF-8", function(val) {
    serialize_fn(val, ...)
  })
}



#' @describeIn serializers Text serializer. See [format()] for more details.
#' @export
serializer_format <- function(...) {
  serializer_text(..., serialize_fn = format)
}

#' @describeIn serializers Text serializer. Captures the output of [print()]
#' @export
serializer_print <- function(...) {
  serializer_text(serialize_fn = function(x) {
    paste0(
      collapse = "\n",
      utils::capture.output({
        print(x, ...)
      })
    )
  })
}
#' @describeIn serializers Text serializer. Captures the output of [cat()]
#' @export
serializer_cat <- function(...) {
  serializer_text(serialize_fn = function(x) {
    paste0(
      collapse = "\n",
      utils::capture.output({
        cat(x, ...)
      })
    )
  })
}




#' @describeIn serializers htmlwidget serializer. See [htmlwidgets::saveWidget()] for more details.
#' @export
serializer_htmlwidget <- function(...) {
  if (!requireNamespace("htmlwidgets", quietly = TRUE)) {
    stop("The htmlwidgets package is not available but is required in order to use the htmlwidgets serializer",
          call. = FALSE)
  }

  serializer_content_type("text/html; charset=UTF-8", function(val) {
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
  addSerializer("format",        serializer_format)
  addSerializer("print",        serializer_print)
  addSerializer("cat",        serializer_cat)
  addSerializer("htmlwidget",  serializer_htmlwidget)
}
