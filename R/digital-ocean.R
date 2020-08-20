
#' DigitalOcean Plumber server
#'
#' These methods are now defunct.
#' Please use the [`plumberDeploy`](https://github.com/meztez/plumberDeploy) R package.
#'
#' @keywords internal
#' @rdname digitalocean
#' @export
do_provision <- function(...) {
  plumberDeploy_helper("do_provision", list(...))
}

#' @export
#' @rdname digitalocean
do_configure_https <- function(...) {
  plumberDeploy_helper("do_configure_https", list(...))
}

#' @export
#' @rdname digitalocean
do_deploy_api <- function(...) {
  plumberDeploy_helper("do_deploy_api", list(...))
}

#' @export
#' @rdname digitalocean
do_forward <- function(...) {
  plumberDeploy_helper("do_forward", list(...))
}

#' @export
#' @rdname digitalocean
do_remove_api <- function(...) {
  plumberDeploy_helper("do_remove_api", list(...))
}

#' @export
#' @rdname digitalocean
do_remove_forward <- function(...) {
  plumberDeploy_helper("do_remove_forward", list(...))
}


plumberDeploy_helper <- function(fn_name, args, new_fn_name = fn_name) {
  cur_fn <- paste0(fn_name, "()")
  new_fn <- paste0("plumberDeploy", "::", new_fn_name, "()")

  # check if plumberDeploy is called
  if (!plumberDeploy_is_available()) {
    # not found
    # throw error
    lifecycle::deprecate_stop("1.0.0", cur_fn, new_fn)
  }

  # plumberDeploy is found
  # 1. Throw warning
  # 2. Call method
  lifecycle::deprecate_warn("1.0.0", cur_fn, new_fn)

  fn <- utils::getFromNamespace(fn_name, "plumberDeploy")
  do.call(fn, args)
}

plumberDeploy_is_available <- function() {
  is_available("plumberDeploy")
}
