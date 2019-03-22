#' Store session data in encrypted cookies.
#' @param key The secret key to use. This must be consistent across all sessions
#'   where you want to save/restore encrypted cookies. It should be a long and
#'   complex character string to bolster security.
#' @param name The name of the cookie in the user's browser.
#' @param ... Arguments passed on to the \code{response$setCookie} call to,
#'   for instance, set the cookie's expiration.
#' @include plumber.R
#' @export
sessionCookie <- function(
  key = randomCookieKey(),
  name = "plumber",
  ...
) {

  if (missing(key)) {
    warning("If 'key' is missing, all cookies will become invalid when server stops")
  }
  key <- asCookieKey(key)

  # force the args to evaluate
  list(...)

  # Return a list that can be added to registerHooks()
  list(
    preroute = function(req, res, data) {

      cookies <- req$cookies
      if (is.null(cookies)){
        # The cookie-parser filter has probably not run yet. Parse the cookies ourselves
        # TODO: would be more performant not to run this cookie parsing twice.
        cookies <- parseCookies(req$HTTP_COOKIE)
      }
      session <- cookies[[name]]
      tryCatch({
        req$session <- decodeCookie(session, key)
      }, error = function(e) {
        NULL # kept to not re-throw warning
      })

    },
    postroute = function(value, req, res, data) {
      session <- req$session
      # save session in a cookie
      if (!is.null(session)) {
        res$setCookie(name, encodeCookie(session, key), ...)
      } else {
        # TODO-barret unset cookie if it exists in
        if (!is.null(req$cookies[[name]])) {
          # no session to save, but had session to parse
          # remove cookie
          res$removeCookie(name, "", ...)
        }
      }

      value
    }
  )
}

randomCookieKey <- function() {
  sodium::bin2hex(
    sodium::random(32)
  )
}


asCookieKey <- function(key) {
  if (is.null(key)) {
    warning(
      "\n",
      "\n\t!! Cookie secret 'key' is `NULL`. Cookies will not be encrypted.   !!",
      "\n\t!! Support for unencrypted cookies deprecated and will be removed. !!",
      "\n\t!! Please see `?sessionCookie` for details.                        !!",
      "\n"
    )
    return(NULL)
  }

  if (is.raw(key)) {
    # turn binary key into hex string.
    # run through all checks as a character string.
    # this should pass given it's a "valid" raw string
    key <- sodium::bin2hex(key)
  }

  if (!is.character(key)) {
    stop(
      "Cookie secret 'key' must be a 64 digit hexadecimal string",
      " or a length 32 raw vector.",
      "\nPlease see `?sessionCookie` for details."
    )
  }

  if (
    nchar(key) != 64 ||
    grepl("[^0-9a-fA-F]", key)
  ) {
    # turn key into 64 digit hex str by hashing it
    if (nchar(key) < 64) {

      warning(
        "\n",
        "\n\t!! Low entropy cookie secret 'key' detected!      !!",
        "\n\t!! We recommend you upgrade to a more secure key. !!",
        "\n\t!! Please see `?sessionCookie` for details.       !!",
        "\n"
      )
    }
    key <-
      serialize(key, NULL) %>%
      sodium::sha256() %>%
      sodium::bin2hex()
  }

  sodium::hex2bin(key)
}


encodeCookie <- function(x, key) {
  if (is.null(x)) {
    return("")
  }
  xRaw <-
    x %>%
    jsonlite::toJSON() %>%
    charToRaw()

  if (is.null(key)) {
    encodedCookie <- base64enc::base64encode(xRaw)
    return(encodedCookie)
  }

  # key provided

  # random nonce for each request
  nonce <- sodium::random(24)
  # toJSON -> as raw -> encrypt
  encryptedX <- sodium::data_encrypt(xRaw, key, nonce)

  encodedCookie <- combine_val_and_nonce(encryptedX, nonce)
  return(encodedCookie)
}


# any bad result returns NULL
# any invalid input returns NULL
decodeCookie <- function(encodedValue, key) {
  if (is.null(encodedValue) || identical(encodedValue, "")) {
    # nothing to decode
    return(NULL)
  }

  # if no key provided
  if (is.null(key)) {
    value <-
      encodedValue %>%
      base64enc::base64decode() %>%
      rawToChar() %>%
      safeFromJSON()
    return(value)
  }

  # key provided

  # split parts, then decrypt -> as char -> fromJSON
  valueParts <- split_val_and_nonce(encodedValue)
  x <-
    sodium::data_decrypt(valueParts$value, key, valueParts$nonce) %>%
    rawToChar() %>%

    safeFromJSON() # TODO-barret report this error
  return(x)
}


# combine/split with "_" as it is not in the base64 vocab
combine_val_and_nonce <- function(val, nonce) {
  paste0(base64enc::base64encode(val), "_", base64enc::base64encode(nonce))
}
split_val_and_nonce <- function(x) {
  vals <- strsplit(x, "_")[[1]]
  if (length(vals) != 2) {
    stop("Could not separate secure cookie parts")
  }
  list(
    value = base64enc::base64decode(vals[[1]]),
    nonce = base64enc::base64decode(vals[[2]])
  )
}
