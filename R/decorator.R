
# TODO: delete once we require R 3.3.0
trimws <- function(string){
  string <- gsub("^\\s+", "", string)
  gsub("\\s+$", "", string)
}

stop_on_line <- function(line_num, line, msg) {
  stop("Error on line #", line_num, ": '", line, "' - ", msg)
}



DecoratedObj <- R6Class(
  "DecoratedObj",
  public = list(
    pr = "<Plumber>",
    obj = "<object>",
    decorators = "<list[DecoratedLine]>",
    # initialize = function(..., fn, env, fn_text?, block_text) {
    # }
  )
)

# DecoratoratedLine <- R6Class(
#   "DecoratoratedLine",
#   public = list(
#     pr = "<Plumber>",
#     line = 0L,
#     text = "@plumber",
#     initialize = function(..., pr, line, text) {
#       # Make sure pr is a Plumber class
#       stopifnot(inherits(pr, Plumber))
#       # Make sure line and text are a single int and character
#       line <- as.integer(line)
#       text <- as.character(text)
#       stopifnot(!is.na(line))
#       stopifnot(!is.na(text))
#       stopifnot(length(line) == 1)
#       stopifnot(length(text) == 1)

#       self$pr <- pr
#       self$line <- line
#       self$text <- text
#     }
#   )
# )

PlumbedInfo <- R6Class(
  "PlumbedInfo",
  private = list(
    processor_fns = list(), # list[<processor_fn>]
  ),
  public = list(
    line_num = 0L,
    text = "@plumber",
    expr = "<expr>",
    envir = "<environment()>",
    data = list(), # namedlist[str, Any])
    set = function(key, value) {
      stopifnot(is.character(key))
      self$data[[key]] <- value
      self
    },
    get = function(key, default = NULL) {
      stopifnot(is.character(key))
      self$data[[key]] %||% default
    },
    # Add processor
    add_processor = function(processor_fn) {
      stopifnot(is.function(processor_fn))
      # TODO assert kwargs? in processor_fn?
      private$processor_fns[[length(private$processor_fns) + 1]] <- processor_fn

      # Return non-null object... self!
      self
    },
    set_line_info = function(line_num, text) {
      stopifnot(is.integer(line_num))
      stopifnot(is.character(text))

      self$line_num <- line_num
      self$text <- text
    },
    initialize = function(pr, ..., expr, envir) {
      # TODO ellipses pkg?
      stopifnot(length(list(...)) == 0)

      # TODO Generalize
      stopifnot(inherits(pr, "Plumber"))
      stopifnot(is.expression(expr))
      stopifnot(is.environment(envir))

      self$pr <- pr
      self$expr <- expr
      self$envir <- envir
    }
  )
)

# On plumb, collect the text until a parseble object
# * parse decorated object
# Parse each tagged set of text, save results to mutable object
# * decorator_parser_FN(info, ..., line_num, line, envir)
# * register_decorator_parser
# * for every decorator, update mutate object given line block
# When parsing is done, post process the mutated object
# * processor_FN
# * register_decorator_processor
# * for every handler, update pr given mutable object
#

processed_info <- list(
  pr,
  expr,
  envir,
  line_num,
  line # original_line
)

# TODO - while processing, if error is produced, call
# error = function(e) {
#   stop_on_line(line_num, file[line_num], e)
# }

# # Never actually reached!!
# processor_eval <- function(processed_info) {
#   eval(expr, envir)
# }

processor_plumber <- function(processed_info, pr) {
  stopifnot(is.expression(processed_info$expr))
  pr <- processed_info$pr

  func <- eval(processed_info$expr, processed_info$envir)

  if (!is.function(func)) {
    stop("Invalid expression for @plumber tag, please use the form `function(pr) { }`.")
  }

  # Use time as an ID
  # Creating a new pr() takes at least a millisec
  pr_id <- as.numeric(Sys.time())
  pr$flags$id <- pr_id
  on.exit({
    pr$flags$id <- NULL
  }, add = TRUE)

  # process func
  func_ret <- func(pr)

  if (inherits(func_ret, "Plumber")) {
    func_ret_id <- func_ret$flags$id
    if (!identical(pr_id, func_ret_id)) {
      stop("Plumber object returned is not the same as the one provided.")
    }
  }
}

decorator_plumber <- function(info, ..., line) {
  is_match <- stri_match(line, regex="^#['\\*]\\s*@plumber")
  if (!is_match) {
    return(NULL)
  }
  # is match!
  info$add_processor(processor_plumber)
}



processor_path_gen <- function(path, method) {
  function(info) {
    # TODO add route here!

  }
}

decorator_path <- function(info) {

  epMat <- stri_match(line, regex="^#['\\*]\\s*@(get|put|post|use|delete|head|options|patch)(\\s+(.*)$)?")

  if (is.na(epMat[1, 2])) {
    return(NULL)
  }

  path <- stri_trim_both(epMat[1,4])

  if (is.na(path) || path == ""){
    stop_on_line(line_num, line, "No path specified.")
  }

  method <- enumerate_verbs(epMat[1,2])
  processor_fn <- processor_path_gen(path, method)

  info$add_processor(processor_fn)
}






registered_decorators <- function() {
  sort(names(.globals$decorators))
}

register_decorator <- function(decorator_fn) {
  # TODO assert decorator qualities
  stopifnot(is.function(decorator_fn))

  .globals$decorators[[length(.globals$decorators) + 1]] <- decorator_fn
}



register_decorators_onLoad <- function() {

  register_decorator(decorator_plumber)
}


# ------------------------------------------------------------------------



#' @param line_num The line number just above the function we're documenting
#' @param file A character vector representing all the lines in the file
#' @param envir An environment where to evaluate parsed expressions
#' @importFrom utils tail
#' @noRd
plumb_decorators <- function(pr, ..., line_num, file, expr, envir = parent.frame()) {
  # paths <- NULL
  # preempt <- NULL
  # filter <- NULL
  # serializer <- NULL
  # parsers <- NULL
  # assets <- NULL
  # params <- NULL
  # comments <- NULL
  # responses <- NULL
  # tags <- NULL
  # routerModifier <- NULL

  info <- PlumbedInfo$new(pr, expr = expr, envir = envir)

  while (line_num > 0 && (stri_detect_regex(file[line_num], pattern="^#['\\*]?|^\\s*$") || stri_trim_both(file[line_num]) == "")){

    # If the line does not start with a plumber tag `#*` or `#'`, continue to next line
    if (!stri_detect_regex(line, pattern="^#['\\*]")) {
      line_num <- line_num - 1
      next
    }

    info$set_line_info(line_num, text)

    for (decorator_fn in registered_decorators()) {
      ans <- decorator_fn(info)
      # If we got a hit, stop processing the line
      # Or should we process every line with every decorator?
      if (!is.null(ans)) {
        break
      }
    }


    epMat <- stri_match(line, regex="^#['\\*]\\s*@(get|put|post|use|delete|head|options|patch)(\\s+(.*)$)?")
    if (!is.na(epMat[1,2])){
      p <- stri_trim_both(epMat[1,4])

      if (is.na(p) || p == ""){
        stop_on_line(line_num, line, "No path specified.")
      }

      if (is.null(paths)){
        paths <- list()
      }

      paths[[length(paths)+1]] <- list(verb = enumerate_verbs(epMat[1,2]), path = p)
    }

    filterMat <- stri_match(line, regex="^#['\\*]\\s*@filter(\\s+(.*)$)?")
    if (!is.na(filterMat[1,1])){
      f <- stri_trim_both(filterMat[1,3])

      if (is.na(f) || f == ""){
        stop_on_line(line_num, line, "No @filter name specified.")
      }

      if (!is.null(filter)){
        # Must have already assigned.
        stop_on_line(line_num, line, "Multiple @filters specified for one function.")
      }

      filter <- f
    }

    preemptMat <- stri_match(line, regex="^#['\\*]\\s*@preempt(\\s+(.*)\\s*$)?")
    if (!is.na(preemptMat[1,1])){
      p <- stri_trim_both(preemptMat[1,3])
      if (is.na(p) || p == ""){
        stop_on_line(line_num, line, "No @preempt specified")
      }
      if (!is.null(preempt)){
        # Must have already assigned.
        stop_on_line(line_num, line, "Multiple @preempts specified for one function.")
      }
      preempt <- p
    }

    assetsMat <- stri_match(line, regex="^#['\\*]\\s*@assets(\\s+(\\S*)(\\s+(\\S+))?\\s*)?$")
    if (!is.na(assetsMat[1,1])){
      dir <- stri_trim_both(assetsMat[1,3])
      if (is.na(dir) || dir == ""){
        stop_on_line(line_num, line, "No directory specified for @assets")
      }
      prefixPath <- stri_trim_both(assetsMat[1,5])
      if (is.na(prefixPath) || prefixPath == ""){
        prefixPath <- "/public"
      }
      if (!is.null(assets)){
        # Must have already assigned.
        stop_on_line(line_num, line, "Multiple @assets specified for one entity.")
      }
      assets <- list(dir=dir, path=prefixPath)
    }

    serMat <- stri_match(line, regex="^#['\\*]\\s*@serializer(\\s+([^\\s]+)\\s*(.*)\\s*$)?")
    if (!is.na(serMat[1,1])){
      s <- stri_trim_both(serMat[1,3])
      if (is.na(s) || s == ""){
        stop_on_line(line_num, line, "No @serializer specified")
      }
      if (!is.null(serializer)){
        # Must have already assigned.
        stop_on_line(line_num, line, "Multiple @serializers specified for one function.")
      }

      if (!(s %in% registered_serializers())){
        stop_on_line(line_num, line, paste0("No such @serializer registered: ", s))
      }

      ser <- get_registered_serializer(s)

      if (!is.na(serMat[1, 4]) && serMat[1,4] != ""){
        # We have an arg to pass in to the serializer
        argList <- tryCatch({
          eval(parse(text=serMat[1,4]), envir)
        }, error = function(e) {
          stop_on_line(line_num, line, e)
        })
      } else {
        argList <- list()
      }
      tryCatch({
        serializer <- do.call(ser, argList)
      }, error = function(e) {
        stop_on_line(line_num, line, paste0("Error creating serializer: ", s, "\n", e))
      })

    }

    shortSerMat <- stri_match(line, regex="^#['\\*]\\s*@(json|html|jpeg|png|svg)(.*)$")
    if (!is.na(shortSerMat[1,2])) {
      s <- stri_trim_both(shortSerMat[1,2])
      .Deprecated(msg = paste0(
        "Plumber tag `#* @", s, "` is deprecated.\n",
        "Use `#* @serializer ", s, "` instead."
      ))
      if (!is.null(serializer)){
        # Must have already assigned.
        stop_on_line(line_num, line, "Multiple @serializers specified for one function (shorthand serializers like @json count, too).")
      }

      if (!is.na(s) && !(s %in% registered_serializers())){
        stop_on_line(line_num, line, paste0("No such @serializer registered: ", s))
      }
      shortSerAttr <- trimws(shortSerMat[1,3])
      if(!identical(shortSerAttr, "") && !grepl("^\\(.*\\)$", shortSerAttr)){
        stop_on_line(line_num, line, paste0("Supplemental arguments to the serializer must be surrounded by parentheses, as in `#' @", s, "(na='null')`"))
      }

      if (shortSerAttr != "") {
        # We have an arg to pass in to the serializer
        argList <- tryCatch({
          eval(parse(text=paste0("list", shortSerAttr)), envir)
        }, error = function(e) {
          stop_on_line(line_num, line, e)
        })
      } else {
        argList <- list()
      }
      tryCatch({
        serializer <- do.call(get_registered_serializer(s), argList)
      }, error = function(e) {
        stop_on_line(line_num, line, paste0("Error creating serializer: ", s, "\n", e))
      })
    }

    parsersMat <- stri_match(line, regex="^#['\\*]\\s*@parser(\\s+([^\\s]+)\\s*(.*)\\s*$)?")
    if (!is.na(parsersMat[1,1])){
      parser_alias <- stri_trim_both(parsersMat[1,3])
      if (is.na(parser_alias) || parser_alias == ""){
        stop_on_line(line_num, line, "No @parser specified")
      }

      if (!parser_alias %in% registered_parsers()){
        stop_on_line(line_num, line, paste0("No such @parser registered: ", parser_alias))
      }

      if (!is.na(parsersMat[1, 4]) && parsersMat[1,4] != ""){
        # We have an arg to pass in to the parser
        arg_list <- tryCatch({
          eval(parse(text=parsersMat[1,4]), envir)
        }, error = function(e) {
          stop_on_line(line_num, line, e)
        })
      } else {
        arg_list <- list()
      }
      if (is.null(parsers)) {
        parsers <- list()
      }
      parsers[[parser_alias]] <- arg_list
    }

    responseMat <- stri_match(line, regex="^#['\\*]\\s*@response\\s+(\\w+)\\s+(\\S.*)\\s*$")
    if (!is.na(responseMat[1,1])){
      resp <- list()
      resp[[responseMat[1,2]]] <- list(description=responseMat[1,3])
      responses <- c(responses, resp)
    }

    paramMat <- stri_match(line, regex="^#['\\*]\\s*@param(\\s+([^\\s:]+):?([^\\s*]+)?(\\*)?(?:\\s+(.*))?\\s*$)?")
    if (!is.na(paramMat[1,2])){
      name <- paramMat[1,3]
      if (is.na(name)){
        stop_on_line(line_num, line, "No parameter specified.")
      }
      plumberType <- stri_replace_all(paramMat[1,4], "$1", regex = "^\\[([^\\]]*)\\]$")
      apiType <- plumberToApiType(plumberType)
      isArray <- stri_detect_regex(paramMat[1,4], "^\\[[^\\]]*\\]$")
      isArray[is.na(isArray)] <- defaultIsArray
      required <- identical(paramMat[1,5], "*")

      params[[name]] <- list(desc=paramMat[1,6], type=apiType, required=required, isArray=isArray)
    }

    tagMat <- stri_match(line, regex="^#['\\*]\\s*@tag\\s+(\"[^\"]+\"|'[^']+'|\\S+)\\s*")
    if (!is.na(tagMat[1,1])){
      t <- stri_trim_both(tagMat[1,2], pattern = "[[\\P{Wspace}]-[\"']]")
      if (is.na(t) || t == ""){
        stop_on_line(line_num, line, "No tag specified.")
      }
      if (t %in% tags){
        stop_on_line(line_num, line, "Duplicate tag specified.")
      }
      tags <- c(tags, t)
    }

    commentMat <- stri_match(line, regex="^#['\\*]\\s*([^@\\s].*$)")
    if (!is.na(commentMat[1,2])){
      comments <- c(comments, trimws(commentMat[1,2]))
    }

    routerModifierMat <- stri_match(line, regex="^#['\\*]\\s*@plumber")
    if (!is.na(routerModifierMat[1,1])) {
      routerModifier <- TRUE
    }

    line_num <- line_num - 1
  }

  list(
    paths = rev(paths),
    preempt = preempt,
    filter = filter,
    serializer = serializer,
    parsers = rev(parsers),
    assets = assets,
    params = rev(params),
    comments = tail(comments, 1),
    description = paste0(rev(comments)[-1], collapse = "\n"),
    responses = rev(responses),
    tags = rev(tags),
    routerModifier = routerModifier
  )
}

#' Evaluate and activate a "block" of code found in a plumber API file.
#' @noRd
process_decorators <- function(pr, ..., srcref, file, expr, envir) {
  stopifnot(length(list(...)) == 0)

  line_numbers <- srcref[c(1, 3)]
  line_num <- line_numbers[1] - 1

  block <- plumb_decorators(pr, line_num = line_num, file = file, expr = expr, envir = envir)

  if (sum(!is.null(block$filter), !is.null(block$paths), !is.null(block$assets), !is.null(block$routerModifier)) > 1){
    stop_on_line(line_num, file[line_num], "A single function can only be a filter, an API endpoint, an asset or a Plumber object modifier (@filter AND @get, @post, @assets, @plumber, etc.)")
  }

  # ALL if statements possibilities must eventually call eval(expr, envir)
  if (!is.null(block$paths)) {
    lapply(block$paths, function(p) {
      ep <- PlumberEndpoint$new(
        verbs = p$verb,
        path = p$path,
        expr = expr,
        envir = envir,
        serializer = block$serializer,
        parsers = block$parsers,
        lines = lines,
        srcref = srcref,
        params = block$params,
        comments = block$comments,
        description = block$description,
        responses = block$responses,
        tags = block$tags
      )

      addEndpoint(ep, block$preempt)
    })
  } else if (!is.null(block$filter)){
    filter <- PlumberFilter$new(block$filter, expr, envir, block$serializer,
      lines = lines, srcref = srcref)
    addFilter(filter)

  } else if (!is.null(block$assets)){
    path <- block$assets$path

    # Leading slash
    if (substr(path, 1,1) != "/"){
      path <- paste0("/", path)
    }

    stat <- PlumberStatic$new(block$assets$dir, expr)
    pr$mount(path, stat)

  } else if (!is.null(block$routerModifier)) {
    if (is.expression(expr)) {
      func <- tryCatch({
        eval(expr, envir)
      }, error = function(e) {
        stop_on_line(line_num, file[line_num], e)
      })

      if (!is.function(func)) {
        stop_on_line(line_num, file[line_num], "Invalid expression for @plumber tag, please use the form `function(pr) { }`.")
      }

      # Use time as an ID
      # Creating a new pr() takes at least a millisec
      pr_id <- as.numeric(Sys.time())
      pr$flags$id <- pr_id
      on.exit({
        pr$flags$id <- NULL
      }, add = TRUE)

      # process func
      func_ret <- func(pr)

      if (inherits(func_ret, "Plumber")) {
        func_ret_id <- func_ret$flags$id
        if (!identical(pr_id, func_ret_id)) {
          stop_on_line(line_num, file[line_num], "Plumber object returned is not the same as the one provided.")
        }
      }
    }
  }

  # Show that we are returning nothing
  # Only modify pr in place
  return()
}
