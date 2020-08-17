#' Register a Serializer
#'
#' Use [register_serializer()] in favor of addSerializer
#'
#' @export
#' @keywords internal
addSerializer <- function(name, serializer, verbose = TRUE) {
  lifecycle::deprecate_soft("1.0.0", "addSerializer()", "register_serializer()")

  register_serializer(name = name, serializer = serializer, verbose = verbose)
}

#' @export
#' @keywords internal
getCharacterSet <- function(contentType = NULL) {
  lifecycle::deprecate_soft("1.0.0", "getCharacterSet()", "get_character_set()")
  get_character_set(content_type = contentType)
}


#' @export
#' @keywords internal
sessionCookie <- function(
  key,
  name = "plumber",
  expiration = FALSE,
  http = TRUE,
  secure = FALSE,
  sameSite = FALSE
) {
  lifecycle::deprecate_soft("1.0.0", "sessionCookie()", "session_cookie()")
  session_cookie(
    key = key,
    name = name,
    expiration = expiration,
    http = http,
    secure = secure,
    same_site = sameSite
  )
}
