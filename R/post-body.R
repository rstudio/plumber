postBodyFilter <- function(req){
  handled <- req$.internal$postBodyHandled
  if (is.null(handled) || handled != TRUE){
    args <- parseMultipart(req)
    if (is.null(args)) {
      body <- paste0(req$rook.input$read_lines(), collapse = "\n")
      charset <- getCharacterSet(req$HTTP_CONTENT_TYPE)
      args <- parseBody(body, charset)
      req$postBody <- body
    } else {
      req$postBody <- list("multipart", names(args))
    }
    req$args <- c(req$args, args)
    req$.internal$postBodyHandled <- TRUE
  }
  forward()
}

#' @noRd
parseBody <- function(body, charset = "UTF-8"){
  # The body in a curl call can also include querystring formatted data
  # Is there data in the request?
  if (is.null(body) || length(body) == 0 || body == "") {
    return(list())
  }

  if (is.character(body)) {
    Encoding(body) <- charset
  }

  # Is it JSON data?
  if (stri_startswith_fixed(body, "{")) {
    ret <- safeFromJSON(body)
  } else {
    # If not handle it as a query string
      ret <- parseQS(body)
  }
  ret
}

## parseMultipart lifted from mime. Variable name change, here instead of
## importing mime package because we might not want to save files to a
## tmp folder.
##
##
## Rook::Utils$parse() has a few problems: 1. it adds an extra \r\n to the file
## uploaded; 2. if there are multiple files uploaded, only the info about the
## last file is recorded. Besides, I did not escape non-file data, nor did I
## unescape the filenames. The former is not important to me at the moment,
## since the primary purpose of this function is for shiny IE8/9 file uploading;
## the latter is probably not important, either, since the users normally only
## want the content of the file(s) instead of the name(s).

#' Parse multipart form data
#'
#' This function parses the HTML form data from a Rook environment (an HTTP POST
#' request).
#' @param env the HTTP request environment
#' @return A named list containing the values of the form data, and the files
#'   uploaded are saved to temporary files (the temporary filenames are
#'   returned). It may also be \code{NULL} if there is anything unexpected in
#'   the form data, or the form is empty.
#' @references This function was borrowed from
#'   \url{https://github.com/jeffreyhorner/Rook/} with slight modifications.
#' @useDynLib plumber, .registration = TRUE
parseMultipart = function(env) {
  ctype = env$HTTP_CONTENT_TYPE
  if (length(grep('^multipart', ctype)) == 0L) return()

  EOL = '\r\n'
  params = list()
  input  = env$rook.input; input$rewind()
  content_length = as.integer(env$HTTP_CONTENT_LENGTH)
  # some constants regarding boundaries
  boundary = gsub('^multipart/.*boundary="?([^";,]+)"?', '--\\1', ctype)

  bytesize = function(x) nchar(x, type = 'bytes')
  EOL_size = bytesize(EOL)
  EOL_raw  = charToRaw(EOL)
  boundary_size = bytesize(boundary)
  boundaryEOL = paste(boundary, EOL, sep = '')
  boundaryEOL_size = boundary_size + bytesize(EOL)
  boundaryEOL_raw  = charToRaw(boundaryEOL)
  EOLEOL = paste(EOL, EOL, sep = '')
  EOLEOL_size = bytesize(EOLEOL)
  EOLEOL_raw  = charToRaw(EOLEOL)

  buf = new.env(parent = emptyenv())
  buf$bufsize = 262144L  # never read more than bufsize bytes (256K)
  buf$read_buffer = input$read(boundaryEOL_size)
  buf$read_buffer_len = length(buf$read_buffer)
  buf$unread = content_length - boundary_size
  if (!identical(boundaryEOL_raw, buf$read_buffer)) {
    warning('bad content body')
    input$rewind()
    return()
  }

  # read the smaller one of the unread content and the next chunk
  fill_buffer = function() {
    x = input$read(min(buf$bufsize, buf$unread))
    n = length(x)
    if (n == 0L) return()
    buf$read_buffer = c(buf$read_buffer, x)
    buf$read_buffer_len = length(buf$read_buffer)
    buf$unread = buf$unread - n
  }
  # slices off the beginning part of read_buffer, e.g. i is the position of
  # EOLEOL, and size is EOLEOL_size, and read_buffer is [......EOLEOL+++], then
  # slice_buffer returns the the beginning [......], and turns read_buffer to
  # the remaining [+++]
  slice_buffer = function(i, size) {
    slice = buf$read_buffer[if (i > 1) 1:(i - 1) else 1]
    buf$read_buffer = if (size < buf$read_buffer_len)
      buf$read_buffer[(i + size):buf$read_buffer_len] else raw()
    buf$read_buffer_len = length(buf$read_buffer)
    slice
  }

  # prime the read_buffer
  buf$read_buffer = raw()
  fill_buffer()

  # find the position of the raw vector x1 in x2
  raw_match = function(x1, x2) {
    if (is.character(x1)) x1 = charToRaw(x1)
    .Call('rawmatch', x1, x2, PACKAGE = 'plumber')
  }
  unescape = function(x) {
    unlist(lapply(x, function(s) httpuv::decodeURIComponent(chartr('+', ' ', s))))
  }

  while (TRUE) {
    head = value = NULL
    filename = content_type = name = NULL
    while (is.null(head)) {
      i = raw_match(EOLEOL_raw, buf$read_buffer)
      if (length(i)) {
        head = slice_buffer(i, EOLEOL_size)
        break
      } else if (buf$unread) {
        fill_buffer()
      } else {
        break  # we've read everything and still haven't seen a valid head
      }
    }
    if (is.null(head)) {
      warning('Bad post payload: searching for a header')
      input$rewind()
      return()
    }
    # cat('Head:',rawToChar(head),'\n') they're 8bit clean
    head = rawToChar(head)
    token = '[^\\s()<>,;:\\"\\/\\[\\]?=]+'
    condisp = sprintf('Content-Disposition:\\s*%s\\s*', token)
    dispparm = sprintf(';\\s*(%s)=("(?:\\"|[^"])*"|%s)*', token, token)
    rfc2183 = sprintf('(?m)^%s(%s)+$', condisp, dispparm)
    broken_quoted = sprintf(
      '(?m)^%s.*;\\sfilename="(.*?)"(?:\\s*$|\\s*;\\s*%s=)', condisp, token
    )
    broken_unquoted = sprintf('(?m)^%s.*;\\sfilename=(%s)', condisp, token)
    if (length(grep(rfc2183, head, perl = TRUE))) {
      first_line = sub(condisp, '', strsplit(head, EOL)[[1L]][1], perl = TRUE)
      pairs = strsplit(first_line, ';', fixed = TRUE)[[1L]]
      fnmatch = '\\s*filename=(.*)\\s*'
      if (any(grepl(fnmatch, pairs, perl = TRUE))) {
        filename = pairs[grepl(fnmatch, pairs, perl = TRUE)][1]
        filename = gsub('"', '', sub(fnmatch, '\\1', filename, perl = TRUE))
      }
    } else if (length(grep(broken_quoted, head, perl = TRUE))) {
      filename = sub(
        broken_quoted, '\\1', strsplit(head, '\r\n')[[1L]][1], perl = TRUE
      )
    } else if (length(grep(broken_unquoted, head, perl = TRUE))) {
      filename = sub(
        broken_unquoted, '\\1', strsplit(head, '\r\n')[[1L]][1], perl = TRUE
      )
    }

    if (!is.null(filename) && filename != '') {
     filename = unescape(filename)
    }

    headlines = strsplit(head, EOL, fixed = TRUE)[[1L]]
    content_type_re = '(?mi)Content-Type: (.*)'
    content_types = grep(content_type_re, headlines, perl = TRUE, value = TRUE)
    if (length(content_types)) {
      content_type = sub(content_type_re, '\\1', content_types[1], perl = TRUE)
    }
    name = sub(
      '(?si)Content-Disposition:.*\\s+name="?([^\";]*).*"?', '\\1', head,
      perl = TRUE
    )
    while (TRUE) {
      i = raw_match(boundary, buf$read_buffer)
      if (length(i)) {
        value = slice_buffer(i, boundary_size)
        # strip off the extra EOL before the boundary
        if (identical(utils::tail(value, EOL_size), EOL_raw))
          value = head(value, -EOL_size)
        if (length(value)) {
          # drop EOL only values
          if (identical(value, EOL_raw)) break
          if (!is.null(filename) || !is.null(content_type)) {
            data = character()
            data = if (is.null(filename)) paste0("plumber", as.integer(Sys.time())) else filename
            data = file.path(getOption("plumber.upload.dir", "."), data)
            attr(data, "size") = length(value)
            attr(data, "type") = if (!is.null(content_type)) content_type
            con = file(data, open = 'wb')
            tryCatch(writeBin(value, con), finally = close(con))
            params[[name]] = data
          } else {
            len = length(value)
            # trim trailing EOL
            if (len > 2 && length(raw_match(EOL, value[(len - 1):len])))
              len = len - 2
            # handle array parameters (TODO: why Utils$escape?)
            paramValue = rawToChar(value[1:len])
            if (stri_startswith_fixed(paramValue, "{")) {
              paramValue <- safeFromJSON(paramValue)
            }
            paramSet = FALSE
            if (grepl('\\[\\]$', name)) {
              name = sub('\\[\\]$', '', name)
              if (name %in% names(params)) {
                params[[name]] = c(params[[name]], paramValue)
                paramSet = TRUE
              }
            }
            if (!paramSet) params[[name]] = paramValue
          }
        }
        break
      } else if (buf$unread) {
        fill_buffer()
      } else {
        break  # we've read everything and still haven't seen a valid value
      }
    }
    if (is.null(value)) {
      # bad post payload
      input$rewind()
      warning('Bad post payload: searching for a body part')
      return(NULL)
    }
    # now search for ending markers or the beginning of another part
    while (buf$read_buffer_len < 2 && buf$unread) fill_buffer()
    if (buf$read_buffer_len < 2 && buf$unread == 0) {
      # bad stuff at the end; just return what we've got and presume everything
      # is okay
      input$rewind()
      return(params)
    }
    # valid ending
    if (length(raw_match('--', buf$read_buffer[1:2]))) {
      input$rewind()
      return(params)
    }
    # skip past the EOL.
    if (length(raw_match(EOL, buf$read_buffer[1:EOL_size]))) {
      slice_buffer(1, EOL_size)
    } else {
      warning('Bad post body: EOL not present')
      input$rewind()
      return(params)
    }
    # another sanity check before we try to parse another part
    if ((buf$read_buffer_len + buf$unread) < boundary_size) {
      warning('Bad post body: unknown trailing bytes')
      input$rewind()
      return(params)
    }
  }
}
