#' Store session data in encrypted cookies.
#'
#' \code{plumber} is using the crypto R package \code{sodium}, which binds to
#' \code{libsodium}, "a modern, easy-to-use software library for encryption".
#' Using \code{sodium}, \code{req$session} information is be preserved between
#' requests in encrypted cookies.
#'
#' Currently, if no \code{key} value is provided, encrypted browser cookies can be valid
#' until the \code{plumber} server is restarted.  Once restarted,  the new
#' \code{plumber} server will create a new encryption key and all prior cookies
#' will silently fail to parse, losing all \code{req$session} information.
#'
#' If a consistent \code{key} is provided each time a \code{plumber} server is
#' launched, users will maintain \code{req$session} information between server resets.
#'
#' @section Storing secure key:
#' While it is very quick to get started with user session cookies using
#' \code{plumber}, please use exercise precaution when storing secure key information.
#'
#' Please: \itemize{
#' \item Do NOT store keys in storage code.
#' \item Do NOT store keys which can be accessed by everyone.
#' \item Do NOT store keys which can be queried by everyone.
#' }
#'
#' Instead, please: \itemize{
#' \item Use a key management system or password application.
#' \item (or) Store it on a disk that only you have access to.
#' Such as modifying the file permissions to "user read only" (\code{chmod 400 myfile.txt}) to your file from being modified and prevent others from reading your file.
#' }
#'
#' @param key The secret key to use. This must be consistent across all sessions
#'   where you want to save/restore encrypted cookies. It should be a long and
#'   complex character string to bolster security. Raw vectors with a length of
#'   32 or more may also be used.
#' @param name The name of the cookie in the user's browser.
#' @param ... Arguments passed on to the \code{response$setCookie} call to,
#'   for instance, set the cookie's expiration.
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
        # silently fail
        NULL # kept to not re-throw warning
      })

    },
    postroute = function(value, req, res, data) {
      session <- req$session
      # save session in a cookie
      if (!is.null(session)) {
        res$setCookie(name, encodeCookie(session, key), ...)
      } else {
        # session is null
        if (!is.null(req$cookies[[name]])) {
          # no session to save, but had session to parse
          # remove cookie session cookie
          res$removeCookie(name, "", ...)
        }
      }

      value
    }
  )
}

#' Random cookie key generator
#'
#'
#' @return A 64 digit hexadecimal number to be used as a key for cookie encryption.
#' @export
#' @seealso \code{\link{sessionCookie}}
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
  xChar <-
    sodium::data_decrypt(valueParts$value, key, valueParts$nonce) %>%
    rawToChar()

  tryCatch({
    x <- safeFromJSON(xChar)
  }, error = function(e) {
    # print warning
    warning("Cookie information could not be converted from JSON.  Please make sure session objects being stored can be converted to and from JSON cleanly.")
    # re throw error
    stop(e)
  })
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
