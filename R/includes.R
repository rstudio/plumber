requireRmd <- function(fun_name){
  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    stop("The rmarkdown package is not available but is required in order to use ", fun_name,
         call. = FALSE)
  }
}

#' Send File Contents as Response
#'
#' Returns the file at the given path as the response. If you want an endpoint to return a file as an attachment for user to download see [as_attachment()].
#'
#' \code{include_html} will merely return the file with the proper
#' \code{content_type} for HTML. \code{include_md} and \code{include_rmd} will
#' process the given markdown file through \code{rmarkdown::render} and return
#' the resultant HTML as a response.
#'
#' @param file The path to the file to return
#' @param res The response object into which we'll write
#' @param content_type If provided, the given value will be sent as the
#'  `Content-Type` header in the response. Defaults to the contentType of the file extension.
#' To disable the `Content-Type` header, set `content_type = NULL`.
#' @export
include_file <- function(file, res, content_type = getContentType(tools::file_ext(file))){
  # TODO stream this directly to the request w/o loading in memory
  lines <- paste(readLines(file), collapse="\n")
  res$serializer <- "null"
  res$body <- c(res$body, lines)

  if (!is.null(content_type)) {
    res$setHeader("Content-Type", content_type)
  }

  res
}

#' @rdname include_file
#' @export
include_html <- function(file, res){
  include_file(file, res, content_type="text/html; charset=UTF-8")
}

#' @rdname include_file
#' @param format Passed as the \code{output_format} to \code{rmarkdown::render}
#' @export
include_md <- function(file, res, format = NULL){
  requireRmd("include_md")

  f <- rmarkdown::render(file, format, quiet=TRUE)
  include_html(f, res)
}

#' @rdname include_file
#' @export
include_rmd <- function(file, res, format = NULL){
  requireRmd("include_rmd")

  f <- rmarkdown::render(file, format, quiet=TRUE)
  include_html(f, res)
}
