#' @importFrom httpproblems http_problem_types
#' @export
httpproblems::http_problem_types

#' @importFrom httpproblems http_problem
#' @export
httpproblems::http_problem

#' @importFrom httpproblems bad_request
#' @export
httpproblems::bad_request

#' @importFrom httpproblems conflict
#' @export
httpproblems::conflict

#' @importFrom httpproblems forbidden
#' @export
httpproblems::forbidden

#' @importFrom httpproblems not_found
#' @export
httpproblems::not_found

#' @importFrom httpproblems unauthorized
#' @export
httpproblems::unauthorized

#' @importFrom httpproblems internal_server_error
#' @export
httpproblems::internal_server_error

#' @importFrom httpproblems stop_for_http_problem
#' @export
httpproblems::stop_for_http_problem

#' @importFrom httpproblems stop_for_bad_request
#' @export
httpproblems::stop_for_bad_request

#' @importFrom httpproblems stop_for_conflict
#' @export
httpproblems::stop_for_conflict

#' @importFrom httpproblems stop_for_forbidden
#' @export
httpproblems::stop_for_forbidden

#' @importFrom httpproblems stop_for_not_found
#' @export
httpproblems::stop_for_not_found

#' @importFrom httpproblems stop_for_unauthorized
#' @export
httpproblems::stop_for_unauthorized

#' @importFrom httpproblems stop_for_internal_server_error
#' @export
httpproblems::stop_for_internal_server_error

http_problem_response <- function(req, res, problem) {
  # The default is a 200. If that's still set, then we should probably override with a 500.
  if (res$status == 200L) {
    res$status = 500L
  }
  res$serializer <- serializer_unboxed_json(type = "application/problem+json")
  problem <- to_http_problem(req, res, problem)
  log_problem(req, res, problem)
  # Don't leak
  # dropped is function and isTRUE, already done within setDebug
  # getDebug binding is locked
  if (!req$pr$getDebug()) problem$detail <- NULL
  return(problem)
}

not_found_response <- function(req, res) {
  http_problem_response(req, res, 404L)
}

to_http_problem <- function(req, res, problem) {
  UseMethod("to_http_problem", problem)
}

to_http_problem.default <- function(req, res, problem) {
  http_problem(status = res$status)
}

to_http_problem.character <- function(req, res, problem) {
  http_problem(detail = problem, status = res$status)
}

to_http_problem.numeric <- function(req, res, problem) {
  problem <- http_problem(status = problem)
  # set status after in case problem is invalid
  res$status <- problem$status
  return(problem)
}

to_http_problem.http_problem <- function(req, res, problem) {
  res$status <- problem$status
  return(problem)
}

to_http_problem.http_problem_error <- function(req, res, problem) {
  res$status <- problem$body$status
  return(problem$body)
}

to_http_problem.condition <- function(req, res, problem) {
  http_problem(detail = conditionMessage(problem), status = res$status)
}



log_problem <- function(req, res, problem) {
  # Fixed log format, bring in customization?
  cat(
    req$REMOTE_ADDR, " - ", "[", format(Sys.time(), "%F %T %z"), "] ",
    '"', req$REQUEST_METHOD, " ", req$PATH_INFO, '" ',
    problem$title, " (HTTP ", res$status, ") (", length(req$bodyRaw), " bytes sent) (",
    problem$detail ,") ",
    '"', req$HTTP_REFERER, " ", req$HTTP_USER_AGENT, '"',
    "\n", file = stderr(), sep = ""
  )
}
