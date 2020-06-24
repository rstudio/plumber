
#' Parse the given argument and extend the given fields list with new data.
#' @param fields A list that contains at least an `info` sub-list.
#' @param argument The line (including the plumber comment prefix) to append.
#'   If this line represents what was once multiple lines, intermediate comment
#'   prefixes should have been removed.
#' @noRd
plumbOneGlobal <- function(fields, argument){
  if (nchar(argument) == 0){
    return(fields)
  }

  parsedLine <- regmatches(argument, regexec(
    argRegex, argument, ignore.case=TRUE))[[1]]

  if (length(parsedLine) != 4){
    return(fields)
  }

  name <- parsedLine[3]
  def <- parsedLine[4]
  def <- gsub("^\\s*|\\s*$", "", def)

  switch(name,
         apiTitle={
           fields$info$title <- def
         },
         apiDescription={
           fields$info$description <- def
         },
         apiTOS={
           fields$info$termsOfService <- def
         },
         apiContact={
           fields$info$contact <- def
         },
         apiLicense={
           fields$info$license <- def
         },
         apiVersion={
           fields$info$version <- def
         },
         apiHost={
           fields$host <- def
         },
         apiBasePath={
           fields$basePath <- def
         },
         apiSchemes={
           fields$schemes <- strsplit(def, split="\\s+")[[1]]
         },
         apiConsumes={
           fields$consumes <- strsplit(def, split="\\s+")[[1]]
         },
         apiProduces={
           fields$produces <- strsplit(def, split="\\s+")[[1]]
         },
         apiTag={
           tagMat <- stri_match(def, regex="^\\s*(\\w+)\\s+(\\S.+)\\s*$")
           name <- tagMat[1,2]
           description <- tagMat[1,3]
           if(!is.null(fields$tags) && name %in% fields$tags$name) {
             stop("Error: '", argument, "' - ","Duplicate tag definition specified.")
           }
           fields$tags <- rbind(fields$tags,data.frame(name=name, description=description, stringsAsFactors = FALSE))
         })
  fields
}

argRegex <- "^#['\\*]\\s*(@(api\\w+)\\s+)?(.*)$"

#' Parse out the global API settings of a given set of lines and return a
#' OpenAPI-compliant list describing the global API.
#' @noRd
plumbGlobals <- function(lines){
  # Build up the entire argument here; needed since a single directive
  # might wrap multiple lines
  fullArg <- ""

  # Build up the fields that we want to return as globals
  fields <- list(info=list())

  # Parse the global docs
  for (line in lines){
    parsedLine <- regmatches(line, regexec(
      argRegex, line, ignore.case=TRUE))[[1]]
    if (length(parsedLine) == 4){
      if (nchar(parsedLine[3]) == 0){
        # Not a new argument, continue existing one
        fullArg <- paste(fullArg, parsedLine[4])
      } else {
        # New argument, parse the buffer and start a new one
        fields <- plumbOneGlobal(fields, fullArg)
        fullArg <- line
      }
    } else {
      # This isn't a line we can underestand. Parse what we have in the
      # buffer and then reset
      fields <- plumbOneGlobal(fields, fullArg)
      fullArg <- ""
    }
  }

  # Clear out the buffer
  fields <- plumbOneGlobal(fields, fullArg)

  fields
}

#' The default set of OpenAPI Specification (OAS) globals. Some of these properties
#' are subject to being overridden by @api* annotations.
#' @noRd
defaultGlobals <- list(
  openapi = "3.0.3",
  info = list(description = "API Description", title = "API Title", version = "1.0.0"),
  paths = list()
)
