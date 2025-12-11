skip_if_no_cookie_support <- function() {
  skip_if_not_installed("sodium")
  skip_if_not_installed("base64enc")
}
