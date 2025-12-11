# Plumber Parsers

Parsers are used in Plumber to transform request body received by the
API. Extra parameters may be provided to parser functions when enabling
them on router. This will allow for non-default behavior.

## Usage

``` r
parser_form()

parser_json(...)

parser_geojson(...)

parser_text(parse_fn = identity)

parser_yaml(...)

parser_csv(...)

parser_tsv(...)

parser_read_file(read_fn = readLines)

parser_rds(...)

parser_feather(...)

parser_arrow_ipc_stream(...)

parser_parquet(...)

parser_excel(..., sheet = NULL)

parser_octet()

parser_multi()

parser_none()
```

## Arguments

- ...:

  parameters supplied to the appropriate internal function

- parse_fn:

  function to further decode a text string into an object

- read_fn:

  function used to read a the content of a file. Ex:
  [`readRDS()`](https://rdrr.io/r/base/readRDS.html)

- sheet:

  Sheet to read. Either a string (the name of a sheet), or an integer
  (the position of the sheet). Defaults to the first sheet. To read all
  sheets, use `NA`.

## Details

Parsers are optional. When unspecified, only default endpoint parsers
are enabled. You can use `@parser NAME` tag to enable parser on
endpoint. Multiple parsers can be enabled on the same endpoint using
multiple `@parser NAME` tags.

User should be aware that `rds` parsing should only be done from a
trusted source. Do not accept `rds` files blindly.

See
[`registered_parsers()`](https://www.rplumber.io/reference/register_parser.md)
for a list of registered parsers names.

## Functions

- `parser_form()`: Form query string parser

- `parser_json()`: JSON parser. See
  [`jsonlite::parse_json()`](https://jeroen.r-universe.dev/jsonlite/reference/read_json.html)
  for more details. (Defaults to using `simplifyVectors = TRUE`)

- `parser_geojson()`: GeoJSON parser. See
  [`geojsonsf::geojson_sf()`](https://rdrr.io/pkg/geojsonsf/man/geojson_sf.html)
  for more details.

- `parser_text()`: Helper parser to parse plain text

- `parser_yaml()`: YAML parser. See
  [`yaml::yaml.load()`](https://yaml.r-lib.org/reference/yaml.load.html)
  for more details.

- `parser_csv()`: CSV parser. See
  [`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html)
  for more details.

- `parser_tsv()`: TSV parser. See
  [`readr::read_tsv()`](https://readr.tidyverse.org/reference/read_delim.html)
  for more details.

- `parser_read_file()`: Helper parser that writes the binary body to a
  file and reads it back again using `read_fn`. This parser should be
  used when reading from a file is required.

- `parser_rds()`: RDS parser. See
  [`readRDS()`](https://rdrr.io/r/base/readRDS.html) for more details.

- `parser_feather()`: feather parser. See
  [`arrow::read_feather()`](https://arrow.apache.org/docs/r/reference/read_feather.html)
  for more details.

- `parser_arrow_ipc_stream()`: Arrow IPC parser. See
  [`arrow::read_ipc_stream()`](https://arrow.apache.org/docs/r/reference/read_ipc_stream.html)
  for more details.

- `parser_parquet()`: parquet parser. See
  [`arrow::read_parquet()`](https://arrow.apache.org/docs/r/reference/read_parquet.html)
  for more details.

- `parser_excel()`: excel parser. See
  [`readxl::read_excel()`](https://readxl.tidyverse.org/reference/read_excel.html)
  for more details. (Defaults to reading in the first worksheet only,
  use `@parser excel list(sheet=NA)` to read in all worksheets.)

- `parser_octet()`: Octet stream parser. Returns the raw content.

- `parser_multi()`: Multi part parser. This parser will then parse each
  individual body with its respective parser. When this parser is used,
  `req$body` will contain the updated output from
  [`webutils::parse_multipart()`](https://jeroen.r-universe.dev/webutils/reference/parse_multipart.html)
  by adding the `parsed` output to each part. Each part may contain
  detailed information, such as `name` (required), `content_type`,
  `content_disposition`, `filename`, (raw, original) `value`, and
  `parsed` (parsed `value`). When performing Plumber route argument
  matching, each multipart part will match its `name` to the `parsed`
  content.

- `parser_none()`: No parser. Will not process the postBody.

## Examples

``` r
if (FALSE) { # \dontrun{
# Overwrite `text/json` parsing behavior to not allow JSON vectors to be simplified
#* @parser json list(simplifyVector = FALSE)
# Activate `rds` parser in a multipart request
#* @parser multi
#* @parser rds
pr <- Plumber$new()
pr$handle("GET", "/upload", function(rds) {rds}, parsers = c("multi", "rds"))
} # }
```
