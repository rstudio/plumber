requireRmd <- function(fun_name){
  if (!requireNamespace("XML", quietly = TRUE)) {
    stop("The rmarkdown package is not available but is required in order to use ", fun_name,
         call. = FALSE)
  }
}

#' @export
include_file <- function(file, res, content_type){
  # TODO stream this directly to the request w/o loading in memory
  # TODO set content type
  lines <- paste(readLines(file), collapse="\n")
  res$serializer <- "null"
  res$body <- c(res$body, lines)

  if (!missing(content_type)){
    res$setHeader("Content-type", content_type)
  }

  res
}

#' @export
include_html <- function(file, res){
  include_file(file, res, content_type="text/html; charset=utf-8")
}

#' @export
include_md <- function(file, res, format = NULL){
  requireRmd("include_md")

  f <- rmarkdown::render(file, format, quiet=TRUE)
  include_html(f, res)
}

#' @export
include_rmd <- function(file, res, format = NULL){
  requireRmd("include_rmd")

  f <- rmarkdown::render(file, format, quiet=TRUE)
  include_html(f, res)
}

