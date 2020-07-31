#' Register a Serializer
#'
#' Use [register_serializer()] in favor of addSerializer
#'
#' @export
#' @keywords internal
addSerializer <- function(name, serializer, verbose = TRUE) {
  register_serializer(name = name, serializer = serializer, verbose = verbose)
}
