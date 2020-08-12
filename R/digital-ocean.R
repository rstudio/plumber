
#' DigitalOcean Plumber server
#'
#' These methods are now defunct.
#' Please use the [`plumberDeploy`](https://github.com/meztez/plumberDeploy) R package.
#'
#' @keywords internal
#' @rdname digitalocean
#' @export
do_provision <- function(...) {
  lifecycle::deprecate_stop("1.0.0", "do_provision()", "plumberDeploy::do_provision()")
}

#' @export
#' @rdname digitalocean
do_configure_https <- function(...) {
  lifecycle::deprecate_stop("1.0.0", "do_configure_https()", "plumberDeploy::do_configure_https()")
}

#' @export
#' @rdname digitalocean
do_deploy_api <- function(...) {
  lifecycle::deprecate_stop("1.0.0", "do_deploy_api()", "plumberDeploy::do_deploy_api()")
}

#' @export
#' @rdname digitalocean
do_forward <- function(...) {
  lifecycle::deprecate_stop("1.0.0", "do_forward()", "plumberDeploy::do_forward()")
}

#' @export
#' @rdname digitalocean
do_remove_api <- function(...) {
  lifecycle::deprecate_stop("1.0.0", "do_remove_api()", "plumberDeploy::do_remove_api()")
}

#' @export
#' @rdname digitalocean
do_remove_forward <- function(...) {
  lifecycle::deprecate_stop("1.0.0", "do_remove_forward()", "plumberDeploy::do_remove_forward()")
}
