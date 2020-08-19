
#' DigitalOcean Plumber server
#'
#' These methods are now defunct.
#' Please use the [`plumberDeploy`](https://github.com/meztez/plumberDeploy) R package.
#'
#' @keywords internal
#' @rdname digitalocean
#' @export
do_provision <- function(...) {
  plumber_deploy_helper("do_provision", list(...))
}

#' @export
#' @rdname digitalocean
do_configure_https <- function(...) {
  plumber_deploy_helper("do_configure_https", list(...))
}

#' @export
#' @rdname digitalocean
do_deploy_api <- function(...) {
  plumber_deploy_helper("do_deploy_api", list(...))
}

#' @export
#' @rdname digitalocean
do_forward <- function(...) {
  plumber_deploy_helper("do_forward", list(...))
}

#' @export
#' @rdname digitalocean
do_remove_api <- function(...) {
  plumber_deploy_helper("do_remove_api", list(...))
}

#' @export
#' @rdname digitalocean
do_remove_forward <- function(...) {
  plumber_deploy_helper("do_remove_forward", list(...))
}


plumber_deploy_helper <- function(fn_name, args, new_fn_name = fn_name) {
  cur_fn <- paste0(fn_name, "()")
  new_fn <- paste0("plumberDeploy::", new_fn_name, "()")

  # check if plumberDeploy is called
  if (!requireNamespace("plumberDeploy", quietly = TRUE)) {
    # not found
    # throw error
    lifecycle::deprecate_stop("1.0.0", cur_fn, new_fn)
  }

  # plumberDeploy is found
  # 1. Throw warning
  # 2. Call method
  lifecycle::deprecate_warn("1.0.0", cur_fn, new_fn)

  fn <- getFromNamespace(fn_name, "plumberDeploy")
  do.call(fn, args)
}
