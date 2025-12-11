# Send File Contents as Response

Returns the file at the given path as the response. If you want an
endpoint to return a file as an attachment for user to download see
[`as_attachment()`](https://www.rplumber.io/reference/as_attachment.md).

## Usage

``` r
include_file(file, res, content_type = getContentType(tools::file_ext(file)))

include_html(file, res)

include_md(file, res, format = NULL)

include_rmd(file, res, format = NULL)
```

## Arguments

- file:

  The path to the file to return

- res:

  The response object into which we'll write

- content_type:

  If provided, the given value will be sent as the `Content-Type` header
  in the response. Defaults to the contentType of the file extension. To
  disable the `Content-Type` header, set `content_type = NULL`.

- format:

  Passed as the `output_format` to
  [`rmarkdown::render`](https://pkgs.rstudio.com/rmarkdown/reference/render.html)

## Details

`include_html` will merely return the file with the proper
`content_type` for HTML. `include_md` and `include_rmd` will process the
given markdown file through
[`rmarkdown::render`](https://pkgs.rstudio.com/rmarkdown/reference/render.html)
and return the resultant HTML as a response.
