# Mount a Plumber router

Plumber routers can be “nested” by mounting one into another using the
`mount()` method. This allows you to compartmentalize your API by paths
which is a great technique for decomposing large APIs into smaller
files. This function mutates the Plumber router
([`pr()`](https://www.rplumber.io/reference/pr.md)) in place and returns
the updated router.

## Usage

``` r
pr_mount(pr, path, router)
```

## Arguments

- pr:

  The host Plumber router.

- path:

  A character string. Where to mount router.

- router:

  A Plumber router. Router to be mounted.

## Value

A Plumber router with the supplied router mounted

## Examples

``` r
if (FALSE) { # \dontrun{
pr1 <- pr() %>%
  pr_get("/hello", function() "Hello")

pr() %>%
  pr_get("/goodbye", function() "Goodbye") %>%
  pr_mount("/hi", pr1) %>%
  pr_run()
} # }
```
