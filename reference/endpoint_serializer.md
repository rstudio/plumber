# Endpoint Serializer with Hooks

This method allows serializers to return `preexec`, `postexec`, and
`aroundexec` (**\[experimental\]**) hooks in addition to a serializer.
This is useful for graphics device serializers which need a `preexec`
and `postexec` hook to capture the graphics output.

## Usage

``` r
endpoint_serializer(
  serializer,
  preexec_hook = NULL,
  postexec_hook = NULL,
  aroundexec_hook = NULL
)
```

## Arguments

- serializer:

  Serializer method to be used. This method should already have its
  initialization arguments applied.

- preexec_hook:

  Function to be run directly before a
  [PlumberEndpoint](https://www.rplumber.io/reference/PlumberEndpoint.md)
  calls its route method.

- postexec_hook:

  Function to be run directly after a
  [PlumberEndpoint](https://www.rplumber.io/reference/PlumberEndpoint.md)
  calls its route method.

- aroundexec_hook:

  Function to be run around a
  [PlumberEndpoint](https://www.rplumber.io/reference/PlumberEndpoint.md)
  call. Must handle a `.next` argument to continue execution.
  **\[experimental\]**

## Details

`preexec` and `postexec` hooks happened directly before and after a
route is executed. These hooks are specific to a single
[PlumberEndpoint](https://www.rplumber.io/reference/PlumberEndpoint.md)'s
route calculation.

## Examples

``` r
# The definition of `serializer_device` returns
# * a `serializer_content_type` serializer
# * `aroundexec` hook
print(serializer_device)
#> function (type, dev_on, dev_off = grDevices::dev.off) 
#> {
#>     stopifnot(!missing(type))
#>     stopifnot(!missing(dev_on))
#>     stopifnot(is.function(dev_on))
#>     stopifnot(length(formals(dev_on)) > 0)
#>     if (!any(c("filename", "...") %in% names(formals(dev_on)))) {
#>         stop("`dev_on` must contain an arugment called `filename` or have `...`")
#>     }
#>     stopifnot(is.function(dev_off))
#>     endpoint_serializer(serializer = serializer_content_type(type), 
#>         aroundexec_hook = function(..., .next) {
#>             tmpfile <- tempfile()
#>             dev_on(filename = tmpfile)
#>             device_id <- dev.cur()
#>             dev_off_once <- once(function() dev_off(device_id))
#>             success <- function(value) {
#>                 dev_off_once()
#>                 if (!file.exists(tmpfile)) {
#>                   stop("The device output file is missing. Did you produce an image?", 
#>                     call. = FALSE)
#>                 }
#>                 con <- file(tmpfile, "rb")
#>                 on.exit({
#>                   close(con)
#>                 }, add = TRUE)
#>                 img <- readBin(con, "raw", file.info(tmpfile)$size)
#>                 img
#>             }
#>             cleanup <- function() {
#>                 dev_off_once()
#>                 on.exit({
#>                   unlink(tmpfile)
#>                 }, add = TRUE)
#>             }
#>             async <- FALSE
#>             on.exit({
#>                 if (!async) {
#>                   cleanup()
#>                 }
#>             }, add = TRUE)
#>             result <- promises::with_promise_domain(createGraphicsDevicePromiseDomain(device_id), 
#>                 {
#>                   .next(...)
#>                 })
#>             if (is.promising(result)) {
#>                 async <- TRUE
#>                 result %>% then(success) %>% finally(cleanup)
#>             }
#>             else {
#>                 success(result)
#>             }
#>         })
#> }
#> <bytecode: 0x560c6c161dc0>
#> <environment: namespace:plumber>
```
