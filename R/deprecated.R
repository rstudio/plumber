#' Deprecated functions
#'
#' @describeIn deprecated See [register_serializer()]
#' @export
#' @keywords internal
addSerializer <- function(name, serializer, verbose = TRUE) {
  lifecycle::deprecate_soft("1.0.0", "addSerializer()", "register_serializer()")

  register_serializer(name = name, serializer = serializer, verbose = verbose)
}

#' @describeIn deprecated See [get_character_set()]
#' @export
getCharacterSet <- function(contentType = NULL) {
  lifecycle::deprecate_soft("1.0.0", "getCharacterSet()", "get_character_set()")
  get_character_set(content_type = contentType)
}


#' @describeIn deprecated See [session_cookie()]
#' @export
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
