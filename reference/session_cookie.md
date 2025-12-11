# Store session data in encrypted cookies.

`plumber` uses the crypto R package `sodium`, to encrypt/decrypt
`req$session` information for each server request.

## Usage

``` r
session_cookie(
  key,
  name = "plumber",
  expiration = FALSE,
  http = TRUE,
  secure = FALSE,
  same_site = FALSE,
  path = NULL
)
```

## Arguments

- key:

  The secret key to use. This must be consistent across all R sessions
  where you want to save/restore encrypted cookies. It should be
  produced using
  [`random_cookie_key`](https://www.rplumber.io/reference/random_cookie_key.md).
  Please see the "Storing secure keys" section for more details complex
  character string to bolster security.

- name:

  The name of the cookie in the user's browser.

- expiration:

  A number representing the number of seconds into the future before the
  cookie expires or a `POSIXt` date object of when the cookie expires.
  Defaults to the end of the user's browser session.

- http:

  Boolean that adds the `HttpOnly` cookie flag that tells the browser to
  save the cookie and to NOT send it to client-side scripts. This
  mitigates [cross-site
  scripting](https://developer.mozilla.org/en-US/docs/Glossary/Cross-site_scripting).
  Defaults to `TRUE`.

- secure:

  Boolean that adds the `Secure` cookie flag. This should be set when
  the route is eventually delivered over
  [HTTPS](https://en.wikipedia.org/wiki/HTTPS).

- same_site:

  A character specifying the SameSite policy to attach to the cookie. If
  specified, one of the following values should be given: "Strict",
  "Lax", or "None". If "None" is specified, then the `secure` flag MUST
  also be set for the modern browsers to accept the cookie. An error
  will be returned if `same_site = "None"` and `secure = FALSE`. If not
  specified or a non-character is given, no SameSite policy is attached
  to the cookie.

- path:

  The URI path that the cookie will be available in future requests.
  Defaults to the request URI. Set to `"/"` to make cookie available to
  all requests at the host.

## Details

The cookie's secret encryption `key` value must be consistent to
maintain `req$session` information between server restarts.

## Storing secure keys

While it is very quick to get started with user session cookies using
`plumber`, please exercise precaution when storing secure key
information. If a malicious person were to gain access to the secret
`key`, they would be able to eavesdrop on all `req$session` information
and/or tamper with `req$session` information being processed.

Please:

- Do NOT store keys in source control.

- Do NOT store keys on disk with permissions that allow it to be
  accessed by everyone.

- Do NOT store keys in databases which can be queried by everyone.

Instead, please:

- Use a key management system, such as
  ['keyring'](https://github.com/r-lib/keyring) (preferred)

- Store the secret in a file on disk with appropriately secure
  permissions, such as "user read only"
  (`Sys.chmod("myfile.txt", mode = "0600")`), to prevent others from
  reading it.

Examples of both of these solutions are done in the Examples section.

## See also

- ['sodium'](https://github.com/r-lib/sodium): R bindings to 'libsodium'

- ['libsodium'](https://doc.libsodium.org/): A Modern and Easy-to-Use
  Crypto Library

- ['keyring'](https://github.com/r-lib/keyring): Access the system
  credential store from R

- [Set-Cookie
  flags](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#Directives):
  Descriptions of different flags for `Set-Cookie`

- [Cross-site
  scripting](https://developer.mozilla.org/en-US/docs/Glossary/Cross-site_scripting):
  A security exploit which allows an attacker to inject into a website
  malicious client-side code

## Examples

``` r
if (FALSE) { # \dontrun{

## Set secret key using `keyring` (preferred method)
keyring::key_set_with_value("plumber_api", plumber::random_cookie_key())


# Load a plumber API
plumb_api("plumber", "01-append") %>%
  # Add cookie support via `keyring`
  pr_cookie(
    keyring::key_get("plumber_api")
  ) %>%
  pr_run()


#### -------------------------------- ###


## Save key to a local file
pswd_file <- "normal_file.txt"
cat(plumber::random_cookie_key(), file = pswd_file)
# Make file read-only
Sys.chmod(pswd_file, mode = "0600")


# Load a plumber API
plumb_api("plumber", "01-append") %>%
  # Add cookie support and retrieve secret key from file
  pr_cookie(
    readLines(pswd_file, warn = FALSE)
  ) %>%
  pr_run()
} # }
```
