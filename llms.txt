# plumber

Plumber allows you to create a web API by merely decorating your
existing R source code with `roxygen2`-like comments. Take a look at an
example.

``` r

# plumber.R

#* Echo back the input
#* @param msg The message to echo
#* @get /echo
function(msg="") {
  list(msg = paste0("The message is: '", msg, "'"))
}

#* Plot a histogram
#* @serializer png
#* @get /plot
function() {
  rand <- rnorm(100)
  hist(rand)
}

#* Return the sum of two numbers
#* @param a The first number to add
#* @param b The second number to add
#* @post /sum
function(a, b) {
  as.numeric(a) + as.numeric(b)
}
```

These comments allow `plumber` to make your R functions available as API
endpoints. You can use either `#*` as the prefix or `#'`, but we
recommend the former since `#'` will collide with `roxygen2`.

``` r

library(plumber)
# 'plumber.R' is the location of the file shown above
pr("plumber.R") %>%
  pr_run(port=8000)
```

You can visit this URL using a browser or a terminal to run your R
function and get the results. For instance `http://localhost:8000/plot`
will show you a histogram, and `http://localhost:8000/echo?msg=hello`
will echo back the ‘hello’ message you provided.

Here we’re using `curl` via a Mac/Linux terminal.

    $ curl "http://localhost:8000/echo"
     {"msg":["The message is: ''"]}
    $ curl "http://localhost:8000/echo?msg=hello"
     {"msg":["The message is: 'hello'"]}

As you might have guessed, the request’s query string parameters are
forwarded to the R function as arguments (as character strings).

    $ curl --data "a=4&b=3" "http://localhost:8000/sum"
     [7]

You can also send your data as JSON:

    $ curl -H "Content-Type: application/json" --data '{"a":4, "b":5}' http://localhost:8000/sum
     [9]

## Installation

You can install the latest stable version from CRAN using the following
command:

``` r

install.packages("plumber")
```

If you want to try out the latest development version, you can install
it from GitHub.

``` r

pak::pkg_install("rstudio/plumber")
library(plumber)
```

## Cheat Sheet

[![plumber cheat
sheet](https://raw.githubusercontent.com/rstudio/cheatsheets/main/pngs/thumbnails/plumber-cheatsheet-thumbs.png)](https://github.com/rstudio/cheatsheets/blob/main/plumber.pdf)

## Hosting

If you’re just getting started with hosting cloud servers, the
[DigitalOcean](https://www.digitalocean.com) integration included in
`plumber` will be the best way to get started. You’ll be able to get a
server hosting your custom API in just two R commands. To deploy to
DigitalOcean, check out the `plumber` companion package
[`plumberDeploy`](https://github.com/meztez/plumberDeploy).

[Posit Connect](https://posit.co/products/enterprise/connect/) is a
commercial publishing platform that enables R developers to easily
publish a variety of R content types, including Plumber APIs. Additional
documentation is available at
<https://www.rplumber.io/articles/hosting.html#rstudio-connect-1>.

A couple of other approaches to hosting plumber are also made available:

- PM2 - <https://www.rplumber.io/articles/hosting.html#pm2-1>
- Docker - <https://www.rplumber.io/articles/hosting.html#docker>

## Related Projects

- [OpenCPU](https://www.opencpu.org/) - A server designed for hosting R
  APIs with an eye towards scientific research.
- [jug](http://bart6114.github.io/jug/index.md) - *(development
  discontinued)* an R package similar to Plumber but uses a more
  programmatic approach to constructing the API.

# Package index

## Router

- [`plumb()`](https://www.rplumber.io/reference/plumb.md) : Process a
  Plumber API

- [`plumb_api()`](https://www.rplumber.io/reference/plumb_api.md)
  [`available_apis()`](https://www.rplumber.io/reference/plumb_api.md) :
  Process a Package's Plumber API

- [`pr()`](https://www.rplumber.io/reference/pr.md) : Create a new
  Plumber router

- [`pr_run()`](https://www.rplumber.io/reference/pr_run.md) :

  Start a server using `plumber` object

- [`options_plumber()`](https://www.rplumber.io/reference/options_plumber.md)
  [`get_option_or_env()`](https://www.rplumber.io/reference/options_plumber.md)
  : Plumber options

- [`is_plumber()`](https://www.rplumber.io/reference/is_plumber.md) :
  Determine if Plumber object

## Router Methods

- [`pr_handle()`](https://www.rplumber.io/reference/pr_handle.md)
  [`pr_get()`](https://www.rplumber.io/reference/pr_handle.md)
  [`pr_post()`](https://www.rplumber.io/reference/pr_handle.md)
  [`pr_put()`](https://www.rplumber.io/reference/pr_handle.md)
  [`pr_delete()`](https://www.rplumber.io/reference/pr_handle.md)
  [`pr_head()`](https://www.rplumber.io/reference/pr_handle.md) : Add
  handler to Plumber router

- [`pr_mount()`](https://www.rplumber.io/reference/pr_mount.md) : Mount
  a Plumber router

- [`pr_static()`](https://www.rplumber.io/reference/pr_static.md) :

  Add a static route to the `plumber` object

## Router Hooks

- [`pr_hook()`](https://www.rplumber.io/reference/pr_hook.md)
  [`pr_hooks()`](https://www.rplumber.io/reference/pr_hook.md) :
  Register a hook
- [`pr_cookie()`](https://www.rplumber.io/reference/pr_cookie.md) :
  Store session data in encrypted cookies.
- [`pr_filter()`](https://www.rplumber.io/reference/pr_filter.md) : Add
  a filter to Plumber router

## Router Defaults

- [`pr_set_api_spec()`](https://www.rplumber.io/reference/pr_set_api_spec.md)
  : Set the OpenAPI Specification

- [`pr_set_docs()`](https://www.rplumber.io/reference/pr_set_docs.md) :
  Set the API visual documentation

- [`pr_set_serializer()`](https://www.rplumber.io/reference/pr_set_serializer.md)
  : Set the default serializer of the router

- [`pr_set_parsers()`](https://www.rplumber.io/reference/pr_set_parsers.md)
  : Set the default endpoint parsers for the router

- [`pr_set_404()`](https://www.rplumber.io/reference/pr_set_404.md) :
  Set the handler that is called when the incoming request can't be
  served

- [`pr_set_error()`](https://www.rplumber.io/reference/pr_set_error.md)
  : Set the error handler that is invoked if any filter or endpoint
  generates an error

- [`pr_set_debug()`](https://www.rplumber.io/reference/pr_set_debug.md)
  : Set debug value to include error messages of routes cause an error

- [`pr_set_docs_callback()`](https://www.rplumber.io/reference/pr_set_docs_callback.md)
  :

  Set the `callback` to tell where the API visual documentation is
  located

## Visual Documentation Interface

- [`pr_set_api_spec()`](https://www.rplumber.io/reference/pr_set_api_spec.md)
  : Set the OpenAPI Specification
- [`pr_set_docs()`](https://www.rplumber.io/reference/pr_set_docs.md) :
  Set the API visual documentation
- [`register_docs()`](https://www.rplumber.io/reference/register_docs.md)
  [`registered_docs()`](https://www.rplumber.io/reference/register_docs.md)
  : Add visual documentation for plumber to use
- [`validate_api_spec()`](https://www.rplumber.io/reference/validate_api_spec.md)
  : Validate OpenAPI Spec

## Body Parsers

- [`register_parser()`](https://www.rplumber.io/reference/register_parser.md)
  [`registered_parsers()`](https://www.rplumber.io/reference/register_parser.md)
  : Manage parsers
- [`parser_form()`](https://www.rplumber.io/reference/parsers.md)
  [`parser_json()`](https://www.rplumber.io/reference/parsers.md)
  [`parser_geojson()`](https://www.rplumber.io/reference/parsers.md)
  [`parser_text()`](https://www.rplumber.io/reference/parsers.md)
  [`parser_yaml()`](https://www.rplumber.io/reference/parsers.md)
  [`parser_csv()`](https://www.rplumber.io/reference/parsers.md)
  [`parser_tsv()`](https://www.rplumber.io/reference/parsers.md)
  [`parser_read_file()`](https://www.rplumber.io/reference/parsers.md)
  [`parser_rds()`](https://www.rplumber.io/reference/parsers.md)
  [`parser_feather()`](https://www.rplumber.io/reference/parsers.md)
  [`parser_arrow_ipc_stream()`](https://www.rplumber.io/reference/parsers.md)
  [`parser_parquet()`](https://www.rplumber.io/reference/parsers.md)
  [`parser_excel()`](https://www.rplumber.io/reference/parsers.md)
  [`parser_octet()`](https://www.rplumber.io/reference/parsers.md)
  [`parser_multi()`](https://www.rplumber.io/reference/parsers.md)
  [`parser_none()`](https://www.rplumber.io/reference/parsers.md) :
  Plumber Parsers
- [`get_character_set()`](https://www.rplumber.io/reference/get_character_set.md)
  : Request character set

## Response

- [`as_attachment()`](https://www.rplumber.io/reference/as_attachment.md)
  : Return an attachment response
- [`register_serializer()`](https://www.rplumber.io/reference/register_serializer.md)
  [`registered_serializers()`](https://www.rplumber.io/reference/register_serializer.md)
  : Register a Serializer
- [`serializer_headers()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_content_type()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_octet()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_csv()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_tsv()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_html()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_json()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_unboxed_json()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_geojson()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_rds()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_feather()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_arrow_ipc_stream()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_parquet()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_excel()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_yaml()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_text()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_format()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_print()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_cat()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_write_file()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_htmlwidget()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_device()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_jpeg()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_png()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_svg()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_bmp()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_tiff()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_pdf()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_agg_jpeg()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_agg_png()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_agg_tiff()`](https://www.rplumber.io/reference/serializers.md)
  [`serializer_svglite()`](https://www.rplumber.io/reference/serializers.md)
  : Plumber Serializers
- [`endpoint_serializer()`](https://www.rplumber.io/reference/endpoint_serializer.md)
  **\[experimental\]** : Endpoint Serializer with Hooks
- [`include_file()`](https://www.rplumber.io/reference/include_file.md)
  [`include_html()`](https://www.rplumber.io/reference/include_file.md)
  [`include_md()`](https://www.rplumber.io/reference/include_file.md)
  [`include_rmd()`](https://www.rplumber.io/reference/include_file.md) :
  Send File Contents as Response

## Cookies and Filters

- [`pr_cookie()`](https://www.rplumber.io/reference/pr_cookie.md) :
  Store session data in encrypted cookies.
- [`random_cookie_key()`](https://www.rplumber.io/reference/random_cookie_key.md)
  : Random cookie key generator
- [`session_cookie()`](https://www.rplumber.io/reference/session_cookie.md)
  : Store session data in encrypted cookies.
- [`forward()`](https://www.rplumber.io/reference/forward.md) : Forward
  Request to The Next Handler

## R6 Constructors

- [`Plumber`](https://www.rplumber.io/reference/Plumber.md) : Package
  Plumber Router
- [`PlumberEndpoint`](https://www.rplumber.io/reference/PlumberEndpoint.md)
  : Plumber Endpoint
- [`PlumberStatic`](https://www.rplumber.io/reference/PlumberStatic.md)
  : Static file router
- [`PlumberStep`](https://www.rplumber.io/reference/PlumberStep.md) :
  plumber step R6 class
- [`Hookable`](https://www.rplumber.io/reference/Hookable.md) : Hookable

# Articles

### Creating APIs in R with Plumber

- [Introduction](https://www.rplumber.io/articles/introduction.md):
- [Quickstart](https://www.rplumber.io/articles/quickstart.md):
- [Routing &
  Input](https://www.rplumber.io/articles/routing-and-input.md):
- [Rendering
  Output](https://www.rplumber.io/articles/rendering-output.md):
- [Runtime](https://www.rplumber.io/articles/execution-model.md):
- [Security](https://www.rplumber.io/articles/security.md):
- [Hosting](https://www.rplumber.io/articles/hosting.md):
- [Programmatic
  Usage](https://www.rplumber.io/articles/programmatic-usage.md):
- [Annotations
  reference](https://www.rplumber.io/articles/annotations.md):
- [Tips & Tricks](https://www.rplumber.io/articles/tips-and-tricks.md):
- [Migration Guide](https://www.rplumber.io/articles/migration.md):
