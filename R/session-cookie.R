#' Store session data in encrypted cookies.
#'
#' \code{plumber} uses the crypto R package \code{sodium}, to encrypt/decrypt
#' \code{req$session} information for each server request.
#'
#' The cookie's secret encryption \code{key} value must be consistent to maintain
#' \code{req$session} information between server restarts.
#'
#' @section Storing secure keys:
#' While it is very quick to get started with user session cookies using
#' \code{plumber}, please exercise precaution when storing secure key information.
#' If a malicious person were to gain access to the secret \code{key}, they woud
#' be able to eavesdrop on all \code{req$session} information and/or tamper with
#' \code{req$session} information being processed.
#'
#' Please: \itemize{
#' \item Do NOT store keys in source control.
#' \item Do NOT store keys on disk with permissions that allow it to be accessed by everyone.
#' \item Do NOT store keys in databases which can be queried by everyone.
#' }
#'
#' Instead, please: \itemize{
#' \item Use a key management system, such as
#' \href{https://github.com/r-lib/keyring}{'keyring'} (preferred)
#' \item Store the secret in a file on disk with appropriately secure permissions,
#'   such as "user read only" (\code{Sys.chmod("myfile.txt", mode = "0600")}),
#'   to prevent others from reading it.
#' } Examples of both of these solutions are done in the Examples section.
#'
#' @param key The secret key to use. This must be consistent across all R sessions
#'   where you want to save/restore encrypted cookies. It should be produced using
#'   \code{\link{randomCookieKey}}. Please see the "Storing secure keys" section for more details
#'   complex character string to bolster security.
#' @param name The name of the cookie in the user's browser.
#' @param expiration A number representing the number of seconds into the future
#'   before the cookie expires or a \code{POSIXt} date object of when the cookie expires.
#'   Defaults to the end of the user's browser session.
#' @param http Boolean that adds the \code{HttpOnly} cookie flag that tells the browser
#'   to save the cookie and to NOT send it to client-side scripts. This mitigates \href{https://developer.mozilla.org/en-US/docs/Glossary/Cross-site_scripting}{cross-site scripting}.
#'   Defaults to \code{TRUE}.
#' @param secure Boolean that adds the \code{Secure} cookie flag.  This should be set
#'   when the route is eventually delivered over \href{https://en.wikipedia.org/wiki/HTTPS}{HTTPS}.
#' @param sameSite A character specifying the SameSite policy to attach to the cookie.
#'   If specified, one of the following values should be given: "Strict", "Lax", or "None".
#'   If "None" is specified, then the \code{secure} flag MUST also be set for the modern browsers to
#'   accept the cookie. An error will be returned if \code{sameSite = "None"} and \code{secure = FALSE}.
#'   If not specified or a non-character is given, no SameSite policy is attached to the cookie.
#' @export
#' @seealso \itemize{
#' \item \href{https://github.com/jeroen/sodium}{'sodium'}: R bindings to 'libsodium'
#' \item \href{https://download.libsodium.org/doc/}{'libsodium'}: A Modern and Easy-to-Use Crypto Library
#' \item \href{https://github.com/r-lib/keyring}{'keyring'}: Access the system credential store from R
#' \item \href{https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#Directives}{Set-Cookie flags}: Descriptions of different flags for \code{Set-Cookie}
#' \item \href{https://developer.mozilla.org/en-US/docs/Glossary/Cross-site_scripting}{Cross-site scripting}: A security exploit which allows an attacker to inject into a website malicious client-side code
#' }
#' @examples
#' \dontrun{
#'
#' ## Set secret key using `keyring` (preferred method)
#' keyring::key_set_with_value("plumber_api", plumber::randomCookieKey())
#'
#'
#' # Load a plumber API
#' pr <- plumb_api("plumber", "01-append")
#'
#' # Add cookie support and retrieve secret key using `keyring`
#' pr$registerHooks(
#'   sessionCookie(
#'     keyring::key_get("plumber_api")
#'   )
#' )
#' pr$run()
#'
#'
#' #### -------------------------------- ###
#'
#'
#' ## Save key to a local file
#' pswd_file <- "normal_file.txt"
#' cat(plumber::randomCookieKey(), file = pswd_file)
#' # Make file read-only
#' Sys.chmod(pswd_file, mode = "0600")
#'
#'
#' # Load a plumber API
#' pr <- plumb_api("plumber", "01-append")
#'
#' # Add cookie support and retrieve secret key from file
#' pr$registerHooks(
#'   sessionCookie(
#'     readLines(pswd_file, warn = FALSE)
#'   )
#' )
#' pr$run()
#'
#' }

sessionCookie <- function(
  key,
  name = "plumber",
  expiration = FALSE,
  http = TRUE,
  secure = FALSE,
  sameSite = FALSE
) {

  if (missing(key)) {
    stop("You must define an encryption key. Please see `?sessionCookie` for more details")
  }
  key <- asCookieKey(key)

  # force the args to evaluate
  list(expiration, http, secure, sameSite)

  # sanity check the sameSite and secure arguments
  if (is.character(sameSite)) {
    sameSite <- match.arg(sameSite, c("Strict", "Lax", "None"))
  } else {
    sameSite <- FALSE
  }
  if (identical(sameSite, "None")) {
    if (!secure) {
      stop("You must set `secure = TRUE` when `sameSite = \"None\"`. See: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie")
    }
  }

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
        res$setCookie(name, encodeCookie(session, key), expiration = expiration, http = http, secure = secure, sameSite = sameSite)
      } else {
        # session is null
        if (!is.null(req$cookies[[name]])) {
          # no session to save, but had session to parse
          # remove cookie session cookie
          res$removeCookie(name, "", expiration = expiration, http = http, secure = secure, sameSite = sameSite)
        }
      }

      value
    }
  )
}

#' Random cookie key generator
#'
#' Uses a cryptographically secure pseudorandom number generator from [sodium::helpers()] to generate a 64 digit hexadecimal string.  \href{https://github.com/jeroen/sodium}{'sodium'} wraps around \href{https://download.libsodium.org/doc/}{'libsodium'}.
#'
#' Please see \code{\link{sessionCookie}} for more information on how to save the generated key.
#'
#' @return A 64 digit hexadecimal string to be used as a key for cookie encryption.
#' @export
#' @seealso \code{\link{sessionCookie}}
randomCookieKey <- function() {
  sodium::bin2hex(
    sodium::random(32)
  )
}


asCookieKey <- function(key) {
  if (is.null(key) || identical(key, "")) {
    warning(
      "\n",
      "\n\t!! Cookie secret 'key' is `NULL`. Cookies will not be encrypted.      !!",
      "\n\t!! Support for unencrypted cookies is deprecated and will be removed. !!",
      "\n\t!! Please see `?sessionCookie` for details.                           !!",
      "\n"
    )
    return(NULL)
  }

  if (!is.character(key)) {
    stop(
      "Illegal cookie secret 'key' detected.",
      "\nPlease see `?sessionCookie` for details."
    )
  }

  # trim away white space
  key <- stri_trim_both(key)

  if (
    nchar(key) != 64 ||
    grepl("[^0-9a-fA-F]", key)
  ) {
    warning(
      "\n",
      "\n\t!! Legacy cookie secret 'key' detected!                                         !!",
      "\n\t!! Support for legacy cookie secret 'key' is deprecated and will be removed.    !!",
      "\n\t!! Please follow the instructions in `?sessionCookie` for creating a new secret key. !!",
      "\n"
    )

    # turn key into 64 digit hex str by hashing it
    key <-
      key %>%
      charToRaw() %>%
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
    toJSON() %>%
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
