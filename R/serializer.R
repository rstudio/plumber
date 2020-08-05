
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
  if (name %in% registered_serializers()) {
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

get_registered_serializer <- function(name) {
  serializer <- .globals$serializers[[name]]
  if (is.null(serializer)) {
    stop("'", name, "' is not a registered serializer. See `?registered_serializers`")
  }

  serializer
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

  stopifnot(length(type) == 1)
  stopifnot(is.character(type))
  stopifnot(nchar(type) > 0)

  serializer_headers(
    list("Content-Type" = type),
    serialize_fn
  )
}

#' @describeIn serializers CSV serializer. See also: [readr::format_csv()]
#' @export
serializer_csv <- function(..., type = "text/csv; charset=UTF-8") {
  if (!requireNamespace("readr", quietly = TRUE)) {
    stop("`readr` must be installed for `serializer_csv` to work")
  }

  serializer_content_type(type, function(val) {
    readr::format_csv(val, ...)
  })
}

#' @describeIn serializers TSV serializer. See also: [readr::format_tsv()]
#' @export
serializer_tsv <- function(..., type = "text/tab-separated-values; charset=UTF-8") {
  if (!requireNamespace("readr", quietly = TRUE)) {
    stop("`readr` must be installed for `serializer_tsv` to work")
  }

  serializer_content_type(type, function(val) {
    readr::format_tsv(val, ...)
  })
}



#' @describeIn serializers HTML serializer
#' @export
serializer_html <- function(type = "text/html; charset=UTF-8") {
  serializer_content_type(type)
}


#' @describeIn serializers JSON serializer. See also: [jsonlite::toJSON()]
#' @export
#' @importFrom jsonlite toJSON
serializer_json <- function(..., type = "application/json") {
  serializer_content_type(type, function(val) {
    toJSON(val, ...)
  })
}

#' @describeIn serializers JSON serializer with `auto_unbox` defaulting to `TRUE`. See also: [jsonlite::toJSON()]
#' @inheritParams jsonlite::toJSON
#' @export
serializer_unboxed_json <- function(auto_unbox = TRUE, ..., type = "application/json") {
  serializer_json(auto_unbox = auto_unbox, ..., type = type)
}




#' @describeIn serializers RDS serializer. See also: [base::serialize()]
#' @inheritParams base::serialize
#' @export
serializer_rds <- function(version = "2", ascii = FALSE, ..., type = "application/rds") {
  if (identical(version, "3")) {
    if (package_version(R.version) < "3.5") {
      stop(
        "R versions before 3.5 do not know how to serialize with `version = \"3\"`",
        "\n Current R version: ", as.character(package_version(R.version))
      )
    }
  }
  serializer_content_type(type, function(val) {
    base::serialize(val, NULL, ascii = ascii, version = version, ...)
  })
}

#' @describeIn serializers feather serializer. See also: [feather::write_feather()]
#' @export
serializer_feather <- function(type = "application/feather") {
  if (!requireNamespace("feather", quietly = TRUE)) {
    stop("`feather` must be installed for `serializer_feather` to work")
  }
  serializer_content_type(type, function(val) {
    tmpfile <- tempfile(fileext = ".feather")
    on.exit({
      if (file.exists(tmpfile)) {
        unlink(tmpfile)
      }
    }, add = TRUE)

    feather::write_feather(val, tmpfile)
    readBin(tmpfile, what = "raw", n = file.info(tmpfile)$size)
  })
}


#' @describeIn serializers YAML serializer. See also: [yaml::as.yaml()]
#' @export
serializer_yaml <- function(..., type = "text/x-yaml; charset=UTF-8") {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("yaml must be installed for the yaml serializer to work")
  }
  serializer_content_type(type, function(val) {
    yaml::as.yaml(val, ...)
  })
}

#' @describeIn serializers Text serializer. See also: [as.character()]
#' @export
serializer_text <- function(..., serialize_fn = as.character, type = "text/plain; charset=UTF-8") {
  serializer_content_type(type, function(val) {
    serialize_fn(val, ...)
  })
}



#' @describeIn serializers Text serializer. See also: [format()]
#' @export
serializer_format <- function(..., type = "text/plain; charset=UTF-8") {
  serializer_text(..., serialize_fn = format, type = type)
}

#' @describeIn serializers Text serializer. Captures the output of [print()]
#' @export
serializer_print <- function(..., type = "text/plain; charset=UTF-8") {
  serializer_text(
    type = type,
    serialize_fn = function(x) {
      paste0(
        collapse = "\n",
        utils::capture.output({
          print(x, ...)
        })
      )
    }
  )
}
#' @describeIn serializers Text serializer. Captures the output of [cat()]
#' @export
serializer_cat <- function(..., type = "text/plain; charset=UTF-8") {
  serializer_text(
    type = type,
    serialize_fn = function(x) {
      paste0(
        collapse = "\n",
        utils::capture.output({
          cat(x, ...)
        })
      )
    }
  )
}




#' @describeIn serializers htmlwidget serializer. See also: [htmlwidgets::saveWidget()]
#' @export
serializer_htmlwidget <- function(..., type = "text/html; charset=UTF-8") {
  if (!requireNamespace("htmlwidgets", quietly = TRUE)) {
    stop("The htmlwidgets package is not available but is required in order to use the htmlwidgets serializer",
          call. = FALSE)
  }

  serializer_content_type(type, function(val) {
    # Write out a temp file. htmlwidgets (or pandoc?) seems to require that this
    # file end in .html or the selfcontained=TRUE argument has no effect.
    file <- tempfile(fileext = ".html")
    on.exit({
      # Delete the temp file
      if (file.exists(file)) {
        file.remove(file)
      }
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



#' Hooks and serializer object
#'
#' This method allows serializers to return both hooks and a serializer.
#' This is useful for graphics device serializers which need a `preexec` and `postexec` hook to capture the graphics output.
#' @param hooks Hooks to be supplied directly to corresponding [PlumberEndpoint] `$registerHooks()` method
#' @param serializer Serializer method to be used.  This method should already have its initialization arguments applied.
#' @examples
#' # The definition of `serializer_device` returns
#' # * `preexec`, `postexec` hooks
#' # * a `serializer_content_type` serializer
#' print(serializer_device)
hooks_and_serializer <- function(hooks, serializer) {
  structure(
    list(
      hooks = hooks,
      serializer = serializer
    ),
    class = "plumber_hooks_and_serializer"
  )
}

self_set_serializer <- function(self, serializer) {
  if (inherits(serializer, "plumber_hooks_and_serializer")) {
    self$serializer <- serializer$serializer
    self$registerHooks(serializer$hooks)
  } else {
    self$serializer <- serializer
  }
  invisible(self)
}


#' @describeIn serializers Helper method to create graphics device serializers, such as [serializer_png()]. See also: [hooks_and_serializer()]
#' @param dev_on Function to turn on a graphics device.
#' The graphics device `dev_on` function will receive any arguments supplied to the serializer in addition to `filename`.
#' `filename` points to the temporary file name that should be used when saving content.
#' @param dev_off Function to turn off the grahpics device. Defaults to [grDevices::dev.off()]
#' @export
serializer_device <- function(type, dev_on, dev_off = grDevices::dev.off) {

  stopifnot(is.function(dev_on))
  stopifnot(length(formals(dev_on)) > 0)
  stopifnot(is.function(dev_off))

  hooks_and_serializer(
    hooks = list(
      preexec = function(req, res, data) {
        tmpfile <- tempfile()
        data$file <- tmpfile

        dev_on(filename = tmpfile)
      },
      postexec = function(value, req, res, data) {
        dev_off()

        on.exit({unlink(data$file)}, add = TRUE)
        con <- file(data$file, "rb")
        on.exit({close(con)}, add = TRUE)
        img <- readBin(con, "raw", file.info(data$file)$size)
        img
      }
    ),
    serializer = serializer_content_type(type)
  )
}

#' @describeIn serializers JPEG image serializer. See also: [grDevices::jpeg()]
#' @export
serializer_jpeg <- function(..., type = "image/jpeg") {
  serializer_device(
    type = type,
    dev_on = function(filename) {
      grDevices::jpeg(filename, ...)
    }
  )
}
#' @describeIn serializers PNG image serializer. See also: [grDevices::png()]
#' @export
serializer_png <- function(..., type = "image/png") {
  serializer_device(
    type = type,
    dev_on = function(filename) {
      grDevices::png(filename, ...)
    }
  )
}
#' @describeIn serializers SVG image serializer. See also: [grDevices::svg()]
#' @export
serializer_svg <- function(..., type = "image/svg+xml") {
  serializer_device(
    type = type,
    dev_on = function(filename) {
      grDevices::svg(filename, ...)
    }
  )
}
#' @describeIn serializers BMP image serializer. See also: [grDevices::bmp()]
#' @export
serializer_bmp <- function(..., type = "image/bmp") {
  serializer_device(
    type = type,
    dev_on = function(filename) {
      grDevices::bmp(filename, ...)
    }
  )
}
#' @describeIn serializers TIFF image serializer. See also: [grDevices::tiff()]
#' @export
serializer_tiff <- function(..., type = "image/tiff") {
  serializer_device(
    type = type,
    dev_on = function(filename) {
      grDevices::tiff(filename, ...)
    }
  )
}
#' @describeIn serializers PDF image serializer. See also: [grDevices::pdf()]
#' @export
serializer_pdf <- function(..., type = "application/pdf") {
  serializer_device(
    type = type,
    dev_on = function(filename) {
      grDevices::pdf(filename, ...)
    }
  )
}






add_serializers_onLoad <- function() {
  register_serializer("null",        serializer_identity)
  register_serializer("contentType", serializer_content_type)

  # html
  register_serializer("html", serializer_html)

  # objects
  register_serializer("json",        serializer_json)
  register_serializer("unboxedJSON", serializer_unboxed_json)
  register_serializer("rds",         serializer_rds)
  register_serializer("csv",         serializer_csv)
  register_serializer("tsv",         serializer_tsv)
  register_serializer("feather",     serializer_feather)
  register_serializer("yaml",        serializer_yaml)

  # text
  register_serializer("text",   serializer_text)
  register_serializer("format", serializer_format)
  register_serializer("print",  serializer_print)
  register_serializer("cat",    serializer_cat)

  # htmlwidget
  register_serializer("htmlwidget", serializer_htmlwidget)

  # devices
  register_serializer("device", serializer_device)
  register_serializer("jpeg",   serializer_jpeg)
  register_serializer("png",    serializer_png)
  register_serializer("svg",    serializer_svg)
  register_serializer("bmp",    serializer_bmp)
  register_serializer("tiff",   serializer_tiff)
  register_serializer("pdf",    serializer_pdf)


  ## Do not register until implemented
  # register_serializer("xml", serializer_xml)
}
