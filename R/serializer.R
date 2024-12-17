
#' Register a Serializer
#'
#' A serializer is responsible for translating a generated R value into output
#' that a remote user can understand. For instance, the \code{serializer_json}
#' serializes R objects into JSON before returning them to the user. The list of
#' available serializers in plumber is global.
#'
#' There are three main building-block serializers:
#' * `serializer_headers`: the base building-block serializer that is required to have [as_attachment()] work
#' * `serializer_content_type()`: for setting the content type. (Calls `serializer_headers()`)
#' * `serializer_device()`: add endpoint hooks to turn a graphics device on and off in addition to setting the content type. (Uses `serializer_content_type()`)
#'
#' @param name The name of the serializer (character string)
#' @param serializer The serializer function to be added.
#' This function should accept arguments that can be supplied when [plumb()]ing a file.
#' This function should return a function that accepts four arguments: `value`, `req`, `res`, and `errorHandler`.
#' See `print(serializer_json)` for an example.
#'
#' @param verbose Logical value which determines if a message should be printed when overwriting serializers
#' @describeIn register_serializer Register a serializer with a name
#' @export
#' @examples
#' # `serializer_json()` calls `serializer_content_type()` and supplies a serialization function
#' print(serializer_json)
#' # serializer_content_type() calls `serializer_headers()` and supplies a serialization function
#' print(serializer_content_type)
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
registered_serializers <- function() {
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
#' To make sure the attachment is used, be sure your serializer eventually calls `serializer_headers`
#'
#' @param value Response value to be saved
#' @param filename File name to use when saving the attachment.
#'   If no `filename` is provided, the `value` will be treated as a regular attachment
#' @return Object with class `"plumber_attachment"`
#' @export
#' @examples
#' \dontrun{
#' # plumber.R
#'
#' #' @get /data
#' #' @serializer csv
#' function() {
#'   # will cause the file to be saved as `iris.csv`, not `data` or `data.csv`
#'   as_attachment(iris, "iris.csv")
#' }
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
#' [here](https://www.rplumber.io/articles/rendering-output.html#serializers-1) for
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

#' @describeIn serializers Octet serializer. If content is received that does
#'   not have a `"raw"` type, then an error will be thrown.
#' @export
serializer_octet <- function(..., type = "application/octet-stream") {
  serializer_content_type(type, function(val) {
    if (!is.raw(val)) {
      stop("The Octet-Stream serializer received non-raw data")
    }
    val
  })
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

#' @describeIn serializers GeoJSON serializer. See also [geojsonsf::sf_geojson()] and [[geojsonsf::sfc_geojson()]].
#' @export
serializer_geojson <- function(..., type = "application/geo+json") {
  if (!requireNamespace("geojsonsf", quietly = TRUE)) {
    stop("`geojsonsf` must be installed for `serializer_geojson` to work")
  }
  serializer_content_type(type, function(val) {
    if (inherits(val, "sfc")) return(geojsonsf::sfc_geojson(val, ...))
    if (inherits(val, "sf"))  return(geojsonsf::sf_geojson(val, ...))
    stop("Did not receive an `sf` or `sfc` object. ")
  })
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

#' @describeIn serializers feather serializer. See also: [arrow::write_feather()]
#' @export
serializer_feather <- function(type = "application/vnd.apache.arrow.file") {
  if (!requireNamespace("arrow", quietly = TRUE)) {
    stop("`arrow` must be installed for `serializer_feather` to work")
  }
  serializer_write_file(
    fileext = ".feather",
    type = type,
    write_fn = function(val, tmpfile) {
      arrow::write_feather(val, tmpfile)
    }
  )
}

#' @describeIn serializers Arrow IPC serializer. See also: [arrow::write_ipc_stream()]
#' @export
serializer_arrow_ipc <- function(type = "application/vnd.apache.arrow.stream") {
  if (!requireNamespace("arrow", quietly = TRUE)) {
    stop("`arrow` must be installed for `serializer_arrow_ipc` to work")
  }
  serializer_write_file(
    fileext = "",
    type = type,
    write_fn = function(val, tmpfile) {
      arrow::write_ipc_stream(val, tmpfile)
    }
  )
}

#' @describeIn serializers parquet serializer. See also: [arrow::write_parquet()]
#' @export
serializer_parquet <- function(type = "application/vnd.apache.parquet") {
  if (!requireNamespace("arrow", quietly = TRUE)) {
    stop("`arrow` must be installed for `serializer_parquet` to work")
  }
  serializer_write_file(
    fileext = ".parquet",
    type = type,
    write_fn = function(val, tmpfile) {
      arrow::write_parquet(val, tmpfile)
    }
  )
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

#' @describeIn serializers Write output to a temp file whose contents are read back as a serialized response. `serializer_write_file()` creates (and cleans up) a temp file, calls the serializer (which should write to the temp file), and then reads the contents back as the serialized value.  If the content `type` starts with `"text"`, the return result will be read into a character string, otherwise the result will be returned as a raw vector.
#' @param write_fn Function that should write serialized content to the temp file provided. `write_fn` should have the function signature of `function(value, tmp_file){}`.
#' @param fileext A non-empty character vector giving the file extension. This value will try to be inferred from the content type provided.
#' @export
serializer_write_file <- function(
  type,
  write_fn,
  fileext = NULL
) {

  # try to be nice and get the file extension from the
  fileext <- fileext %||% get_fileext(type) %||% ""

  serializer_content_type(type, function(val) {
    tmpfile <- tempfile(fileext = fileext)
    on.exit({
      if (file.exists(tmpfile)) {
        unlink(tmpfile)
      }
    }, add = TRUE)

    # write to disk
    write_fn(val, tmpfile)

    # read back results
    if (grepl("^text", type)) {
      paste(readLines(tmpfile), collapse = "\n")
    } else {
      readBin(tmpfile, what = "raw", n = file.info(tmpfile)$size)
    }
  })
}




#' @describeIn serializers htmlwidget serializer. See also: [htmlwidgets::saveWidget()]
#' @export
serializer_htmlwidget <- function(..., type = "text/html; charset=UTF-8") {
  if (!requireNamespace("htmlwidgets", quietly = TRUE)) {
    stop("The htmlwidgets package is not available but is required in order to use the htmlwidgets serializer",
          call. = FALSE)
  }

  serializer_write_file(
    # Write out a temp file. htmlwidgets (or pandoc?) seems to require that this
    # file end in .html or the selfcontained=TRUE argument has no effect.
    fileext = ".html",
    type = type,
    write_fn = function(val, tmpfile) {
      # Write the widget out to a file (doesn't currently support in-memory connections - pandoc)
      # Must write a self-contained file. We're not serving a directory of assets
      # in response to this request, just one HTML file.
      htmlwidgets::saveWidget(val, tmpfile, selfcontained = TRUE, ...)
    }
  )
}


serializer_xml <- function() {
  #if (!requireNamespace("XML", quietly = TRUE)) {
  #  stop("The XML package is not available but is required in order to use the XML serializer.",
  #       call. = FALSE)
  #}
  stop("XML serialization not yet implemented. Please see the discussion at https://github.com/rstudio/plumber/issues/65")
}



#' Endpoint Serializer with Hooks
#'
#' This method allows serializers to return `preexec`, `postexec`, and `aroundexec` (`r lifecycle::badge("experimental")`) hooks in addition to a serializer.
#' This is useful for graphics device serializers which need a `preexec` and `postexec` hook to capture the graphics output.
#'
#' `preexec` and `postexec` hooks happened directly before and after a route is executed.
#' These hooks are specific to a single [PlumberEndpoint]'s route calculation.
#'
#' @param serializer Serializer method to be used.  This method should already have its initialization arguments applied.
#' @param preexec_hook Function to be run directly before a [PlumberEndpoint] calls its route method.
#' @param postexec_hook Function to be run directly after a [PlumberEndpoint] calls its route method.
#' @param aroundexec_hook Function to be run around a [PlumberEndpoint] call. Must handle a `.next` argument to continue execution. `r lifecycle::badge("experimental")`
#'
#' @export
#' @examples
#' # The definition of `serializer_device` returns
#' # * a `serializer_content_type` serializer
#' # * `aroundexec` hook
#' print(serializer_device)
endpoint_serializer <- function(
  serializer,
  preexec_hook = NULL,
  postexec_hook = NULL,
  aroundexec_hook = NULL
) {

  stopifnot(is.function(serializer))
  structure(
    list(
      serializer = serializer,
      preexec_hook = preexec_hook,
      postexec_hook = postexec_hook,
      aroundexec_hook = aroundexec_hook
    ),
    class = "plumber_endpoint_serializer"
  )
}

self_set_serializer <- function(self, serializer) {
  if (inherits(serializer, "plumber_endpoint_serializer")) {
    self$serializer <- serializer$serializer
    if (!is.null(serializer$preexec_hook)) {
      self$registerHook("preexec", serializer$preexec_hook)
    }
    if (!is.null(serializer$postexec_hook)) {
      self$registerHook("postexec", serializer$postexec_hook)
    }
    if (!is.null(serializer$aroundexec_hook)) {
      self$registerHook("aroundexec", serializer$aroundexec_hook)
    }
  } else {
    self$serializer <- serializer
  }

  self
}


#' @describeIn serializers Helper method to create graphics device serializers, such as [serializer_png()]. See also: [endpoint_serializer()]
#' @param dev_on Function to turn on a graphics device.
#' The graphics device `dev_on` function will receive any arguments supplied to the serializer in addition to `filename`.
#' `filename` points to the temporary file name that should be used when saving content.
#' @param dev_off Function to turn off the graphics device. Defaults to [grDevices::dev.off()]
#' @export
serializer_device <- function(type, dev_on, dev_off = grDevices::dev.off) {

  stopifnot(!missing(type))

  stopifnot(!missing(dev_on))
  stopifnot(is.function(dev_on))
  stopifnot(length(formals(dev_on)) > 0)
  if (!any(c("filename", "...") %in% names(formals(dev_on)))) {
    stop("`dev_on` must contain an arugment called `filename` or have `...`")
  }

  stopifnot(is.function(dev_off))

  endpoint_serializer(
    serializer = serializer_content_type(type),
    aroundexec_hook = function(..., .next) {
      tmpfile <- tempfile()

      dev_on(filename = tmpfile)
      device_id <- dev.cur()
      dev_off_once <- once(function() dev_off(device_id))

      success <- function(value) {
        dev_off_once()
        if (!file.exists(tmpfile)) {
          stop("The device output file is missing. Did you produce an image?", call. = FALSE)
        }
        con <- file(tmpfile, "rb")
        on.exit({close(con)}, add = TRUE)
        img <- readBin(con, "raw", file.info(tmpfile)$size)
        img
      }

      cleanup <- function() {
        dev_off_once()
        on.exit({
          # works even if the file does not exist
          unlink(tmpfile)
        }, add = TRUE)
      }

      # This is just a flag to ensure we don't cleanup() if the .next(...) is
      # async.
      async <- FALSE

      on.exit({
        if (!async) {
          cleanup()
        }
      }, add = TRUE)

      result <- promises::with_promise_domain(createGraphicsDevicePromiseDomain(device_id), {
        .next(...)
      })
      if (is.promising(result)) {
        async <- TRUE
        result %>% then(success) %>% finally(cleanup)
      } else {
        success(result)
      }
    }
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

# ragg -------------------------------------------------------------------------

#' @describeIn serializers JPEG image serializer using ragg. See also: [ragg::agg_jpeg()]
#' @export
serializer_agg_jpeg <- function(..., type = "image/jpeg") {
  rlang::check_installed("ragg")
  serializer_device(
    type = type,
    dev_on = function(filename) {
      ragg::agg_jpeg(filename, ...)
    }
  )
}
#' @describeIn serializers PNG image serializer using ragg. See also: [ragg::agg_png()]
#' @export
serializer_agg_png <- function(..., type = "image/png") {
  rlang::check_installed("ragg")
  serializer_device(
    type = type,
    dev_on = function(filename) {
      ragg::agg_png(filename, ...)
    }
  )
}
#' @describeIn serializers TIFF image serializer using ragg. See also: [ragg::agg_tiff()]
#' @export
serializer_agg_tiff <- function(..., type = "image/tiff") {
  rlang::check_installed("ragg")
  serializer_device(
    type = type,
    dev_on = function(filename) {
      ragg::agg_tiff(filename, ...)
    }
  )
}

# svglite ----------------------------------------------------------------------

#' @describeIn serializers SVG image serializer using svglite. See also: [svglite::svglite()]
#' @export
serializer_svglite <- function(..., type = "image/svg+xml") {
  rlang::check_installed("svglite")

  serializer_device(
    type = type,
    dev_on = function(filename) {
      svglite::svglite(filename, ...)
    }
  )
}


add_serializers_onLoad <- function() {
  register_serializer("null",        serializer_identity)
  register_serializer("contentType", serializer_content_type)

  # octet-stream
  register_serializer("octet", serializer_octet)

  # html
  register_serializer("html", serializer_html)

  # objects
  register_serializer("json",        serializer_json)
  register_serializer("unboxedJSON", serializer_unboxed_json)
  register_serializer("rds",         serializer_rds)
  register_serializer("csv",         serializer_csv)
  register_serializer("tsv",         serializer_tsv)
  register_serializer("feather",     serializer_feather)
  register_serializer("arrow_ipc",   serializer_arrow_ipc)
  register_serializer("parquet",     serializer_parquet)
  register_serializer("yaml",        serializer_yaml)
  register_serializer("geojson",     serializer_geojson)

  # text
  register_serializer("text",   serializer_text)
  register_serializer("format", serializer_format)
  register_serializer("print",  serializer_print)
  register_serializer("cat",    serializer_cat)

  # htmlwidget
  register_serializer("htmlwidget", serializer_htmlwidget)

  # devices
  register_serializer("device",   serializer_device)
  register_serializer("jpeg",     serializer_jpeg)
  register_serializer("png",      serializer_png)
  register_serializer("svg",      serializer_svg)
  register_serializer("bmp",      serializer_bmp)
  register_serializer("tiff",     serializer_tiff)
  register_serializer("pdf",      serializer_pdf)
  register_serializer("agg_jpeg", serializer_agg_jpeg)
  register_serializer("agg_png",  serializer_agg_png)
  register_serializer("agg_tiff", serializer_agg_tiff)
  register_serializer("svglite",  serializer_svglite)


  ## Do not register until implemented
  # register_serializer("xml", serializer_xml)
}

# From https://github.com/rstudio/shiny/blob/ee13087d575d378fba2fae34664725dc7452df2d/R/imageutils.R
#' @importFrom grDevices dev.set dev.cur
# if the graphics device was not maintained for the promises, two promises could break how graphics are recorded
## Bad
## * Open p1 device
## * Open p2 device
## * Draw p1 in p2 device
## * Draw p2 in p2 device
## * Close cur device (p2)
## * Close cur device (p1) (which is empty)
##
## Good (and implemented using the function below)
## * Open p1 device in p1
## * Open p2 device in p2
## * Draw p1 in p1 device in p1
## * Draw p2 in p2 device in p2
## * Close p1 device in p1
## * Close p2 device in p2
createGraphicsDevicePromiseDomain <- function(which = dev.cur()) {
  force(which)

  if (which < 2) {
    stop(
      "`createGraphicsDevicePromiseDomain()` was called without opening a device first.",
      " Open a new graphics device before calling."
    )
  }

  promises::new_promise_domain(
    wrapOnFulfilled = function(onFulfilled) {
      force(onFulfilled)
      function(...) {
        old <- dev.cur()
        dev_set(which)
        on.exit(dev_set(old))

        onFulfilled(...)
      }
    },
    wrapOnRejected = function(onRejected) {
      force(onRejected)
      function(...) {
        old <- dev.cur()
        dev_set(which)
        on.exit(dev_set(old))

        onRejected(...)
      }
    },
    wrapSync = function(expr) {
      old <- dev.cur()
      dev_set(which)
      on.exit(dev_set(old))

      force(expr)
    }
  )
}

dev_set <- function(i) {
  # make sure to not open a new device when calling `dev.set(1)`
  if (i > 1) {
    dev.set(i)
  } else {
    warning("Can not set `.Device` to the `null device`. Was `dev.off()` manually called?")
  }
}
