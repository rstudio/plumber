# Random cookie key generator

Uses a cryptographically secure pseudorandom number generator from
[`sodium::helpers()`](https://docs.ropensci.org/sodium/reference/helpers.html)
to generate a 64 digit hexadecimal string.
['sodium'](https://github.com/r-lib/sodium) wraps around
['libsodium'](https://doc.libsodium.org/).

## Usage

``` r
random_cookie_key()
```

## Value

A 64 digit hexadecimal string to be used as a key for cookie encryption.

## Details

Please see
[`session_cookie`](https://www.rplumber.io/reference/session_cookie.md)
for more information on how to save the generated key.

## See also

[`session_cookie`](https://www.rplumber.io/reference/session_cookie.md)
