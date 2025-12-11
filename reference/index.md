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
