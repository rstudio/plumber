# Plumber Serializers

Serializers are used in Plumber to transform the R object produced by a
filter/endpoint into an HTTP response that can be returned to the
client. See
[here](https://www.rplumber.io/articles/rendering-output.html#serializers-1)
for more details on Plumber serializers and how to customize their
behavior.

## Usage

``` r
serializer_headers(headers = list(), serialize_fn = identity)

serializer_content_type(type, serialize_fn = identity)

serializer_octet(..., type = "application/octet-stream")

serializer_csv(..., type = "text/csv; charset=UTF-8")

serializer_tsv(..., type = "text/tab-separated-values; charset=UTF-8")

serializer_html(type = "text/html; charset=UTF-8")

serializer_json(..., type = "application/json")

serializer_unboxed_json(auto_unbox = TRUE, ..., type = "application/json")

serializer_geojson(..., type = "application/geo+json")

serializer_rds(version = "2", ascii = FALSE, ..., type = "application/rds")

serializer_feather(type = "application/vnd.apache.arrow.file")

serializer_arrow_ipc_stream(type = "application/vnd.apache.arrow.stream")

serializer_parquet(type = "application/vnd.apache.parquet")

serializer_excel(
  ...,
  type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
)

serializer_yaml(..., type = "text/x-yaml; charset=UTF-8")

serializer_text(
  ...,
  serialize_fn = as.character,
  type = "text/plain; charset=UTF-8"
)

serializer_format(..., type = "text/plain; charset=UTF-8")

serializer_print(..., type = "text/plain; charset=UTF-8")

serializer_cat(..., type = "text/plain; charset=UTF-8")

serializer_write_file(type, write_fn, fileext = NULL)

serializer_htmlwidget(..., type = "text/html; charset=UTF-8")

serializer_device(type, dev_on, dev_off = grDevices::dev.off)

serializer_jpeg(..., type = "image/jpeg")

serializer_png(..., type = "image/png")

serializer_svg(..., type = "image/svg+xml")

serializer_bmp(..., type = "image/bmp")

serializer_tiff(..., type = "image/tiff")

serializer_pdf(..., type = "application/pdf")

serializer_agg_jpeg(..., type = "image/jpeg")

serializer_agg_png(..., type = "image/png")

serializer_agg_tiff(..., type = "image/tiff")

serializer_svglite(..., type = "image/svg+xml")
```

## Arguments

- headers:

  [`list()`](https://rdrr.io/r/base/list.html) of headers to add to the
  response object

- serialize_fn:

  Function to serialize the data. The result object will be converted to
  a character string. Ex:
  [`jsonlite::toJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html).

- type:

  The value to provide for the `Content-Type` HTTP header.

- ...:

  extra arguments supplied to respective internal serialization
  function.

- auto_unbox:

  automatically
  [`unbox()`](https://jeroen.r-universe.dev/jsonlite/reference/unbox.html)
  all atomic vectors of length 1. It is usually safer to avoid this and
  instead use the
  [`unbox()`](https://jeroen.r-universe.dev/jsonlite/reference/unbox.html)
  function to unbox individual elements. An exception is that objects of
  class `AsIs` (i.e. wrapped in
  [`I()`](https://rdrr.io/r/base/AsIs.html)) are not automatically
  unboxed. This is a way to mark single values as length-1 arrays.

- version:

  the workspace format version to use. `NULL` specifies the current
  default version (3). The only other supported value is 2, the default
  from R 1.4.0 to R 3.5.0.

- ascii:

  a logical. If `TRUE` or `NA`, an ASCII representation is written;
  otherwise (default) a binary one. See also the comments in the help
  for [`save`](https://rdrr.io/r/base/save.html).

- write_fn:

  Function that should write serialized content to the temp file
  provided. `write_fn` should have the function signature of
  `function(value, tmp_file){}`.

- fileext:

  A non-empty character vector giving the file extension. This value
  will try to be inferred from the content type provided.

- dev_on:

  Function to turn on a graphics device. The graphics device `dev_on`
  function will receive any arguments supplied to the serializer in
  addition to `filename`. `filename` points to the temporary file name
  that should be used when saving content.

- dev_off:

  Function to turn off the graphics device. Defaults to
  [`grDevices::dev.off()`](https://rdrr.io/r/grDevices/dev.html)

## Functions

- `serializer_headers()`: Add a static list of headers to each return
  value. Will add `Content-Disposition` header if a value is the result
  of
  [`as_attachment()`](https://www.rplumber.io/reference/as_attachment.md).

- `serializer_content_type()`: Adds a `Content-Type` header to the
  response object

- `serializer_octet()`: Octet serializer. If content is received that
  does not have a `"raw"` type, then an error will be thrown.

- `serializer_csv()`: CSV serializer. See also:
  [`readr::format_csv()`](https://readr.tidyverse.org/reference/format_delim.html)

- `serializer_tsv()`: TSV serializer. See also:
  [`readr::format_tsv()`](https://readr.tidyverse.org/reference/format_delim.html)

- `serializer_html()`: HTML serializer

- `serializer_json()`: JSON serializer. See also:
  [`jsonlite::toJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html)

- `serializer_unboxed_json()`: JSON serializer with `auto_unbox`
  defaulting to `TRUE`. See also:
  [`jsonlite::toJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html)

- `serializer_geojson()`: GeoJSON serializer. See also
  [`geojsonsf::sf_geojson()`](https://rdrr.io/pkg/geojsonsf/man/sf_geojson.html)
  and
  \[[`geojsonsf::sfc_geojson()`](https://rdrr.io/pkg/geojsonsf/man/sfc_geojson.html)\].

- `serializer_rds()`: RDS serializer. See also:
  [`base::serialize()`](https://rdrr.io/r/base/serialize.html)

- `serializer_feather()`: feather serializer. See also:
  [`arrow::write_feather()`](https://arrow.apache.org/docs/r/reference/write_feather.html)

- `serializer_arrow_ipc_stream()`: Arrow IPC serializer. See also:
  [`arrow::write_ipc_stream()`](https://arrow.apache.org/docs/r/reference/write_ipc_stream.html)

- `serializer_parquet()`: parquet serializer. See also:
  [`arrow::write_parquet()`](https://arrow.apache.org/docs/r/reference/write_parquet.html)

- `serializer_excel()`: excel serializer. See also:
  [`writexl::write_xlsx()`](https://docs.ropensci.org/writexl//reference/write_xlsx.html)

- `serializer_yaml()`: YAML serializer. See also:
  [`yaml::as.yaml()`](https://yaml.r-lib.org/reference/as.yaml.html)

- `serializer_text()`: Text serializer. See also:
  [`as.character()`](https://rdrr.io/r/base/character.html)

- `serializer_format()`: Text serializer. See also:
  [`format()`](https://rdrr.io/r/base/format.html)

- `serializer_print()`: Text serializer. Captures the output of
  [`print()`](https://rdrr.io/r/base/print.html)

- `serializer_cat()`: Text serializer. Captures the output of
  [`cat()`](https://rdrr.io/r/base/cat.html)

- `serializer_write_file()`: Write output to a temp file whose contents
  are read back as a serialized response. `serializer_write_file()`
  creates (and cleans up) a temp file, calls the serializer (which
  should write to the temp file), and then reads the contents back as
  the serialized value. If the content `type` starts with `"text"`, the
  return result will be read into a character string, otherwise the
  result will be returned as a raw vector.

- `serializer_htmlwidget()`: htmlwidget serializer. See also:
  [`htmlwidgets::saveWidget()`](https://rdrr.io/pkg/htmlwidgets/man/saveWidget.html)

- `serializer_device()`: Helper method to create graphics device
  serializers, such as `serializer_png()`. See also:
  [`endpoint_serializer()`](https://www.rplumber.io/reference/endpoint_serializer.md)

- `serializer_jpeg()`: JPEG image serializer. See also:
  [`grDevices::jpeg()`](https://rdrr.io/r/grDevices/png.html)

- `serializer_png()`: PNG image serializer. See also:
  [`grDevices::png()`](https://rdrr.io/r/grDevices/png.html)

- `serializer_svg()`: SVG image serializer. See also:
  [`grDevices::svg()`](https://rdrr.io/r/grDevices/cairo.html)

- `serializer_bmp()`: BMP image serializer. See also:
  [`grDevices::bmp()`](https://rdrr.io/r/grDevices/png.html)

- `serializer_tiff()`: TIFF image serializer. See also:
  [`grDevices::tiff()`](https://rdrr.io/r/grDevices/png.html)

- `serializer_pdf()`: PDF image serializer. See also:
  [`grDevices::pdf()`](https://rdrr.io/r/grDevices/pdf.html)

- `serializer_agg_jpeg()`: JPEG image serializer using ragg. See also:
  [`ragg::agg_jpeg()`](https://ragg.r-lib.org/reference/agg_jpeg.html)

- `serializer_agg_png()`: PNG image serializer using ragg. See also:
  [`ragg::agg_png()`](https://ragg.r-lib.org/reference/agg_png.html)

- `serializer_agg_tiff()`: TIFF image serializer using ragg. See also:
  [`ragg::agg_tiff()`](https://ragg.r-lib.org/reference/agg_tiff.html)

- `serializer_svglite()`: SVG image serializer using svglite. See also:
  [`svglite::svglite()`](https://svglite.r-lib.org/reference/svglite.html)
