# Plumber Endpoint

Plumber Endpoint

Plumber Endpoint

## Details

Defines a terminal handler in a Plumber router.

Parameters values are obtained from parsing blocks of lines in a plumber
file. They can also be provided manually for historical reasons.

## Super classes

[`plumber::Hookable`](https://www.rplumber.io/reference/Hookable.md) -\>
[`plumber::PlumberStep`](https://www.rplumber.io/reference/PlumberStep.md)
-\> `PlumberEndpoint`

## Public fields

- `verbs`:

  a character vector. http methods. For historical reasons we have to
  accept multiple verbs for a single path. Now it's simpler to just
  parse each separate verb/path into its own endpoint, so we just do
  that.

- `path`:

  a character string. endpoint path

- `comments`:

  endpoint comments

- `description`:

  endpoint description

- `responses`:

  endpoint responses

- `params`:

  endpoint parameters

- `tags`:

  endpoint tags

- `parsers`:

  step allowed parsers

## Methods

### Public methods

- [`PlumberEndpoint$getTypedParams()`](#method-PlumberEndpoint-getTypedParams)

- [`PlumberEndpoint$canServe()`](#method-PlumberEndpoint-canServe)

- [`PlumberEndpoint$matchesPath()`](#method-PlumberEndpoint-matchesPath)

- [`PlumberEndpoint$new()`](#method-PlumberEndpoint-new)

- [`PlumberEndpoint$getPathParams()`](#method-PlumberEndpoint-getPathParams)

- [`PlumberEndpoint$getFunc()`](#method-PlumberEndpoint-getFunc)

- [`PlumberEndpoint$getFuncParams()`](#method-PlumberEndpoint-getFuncParams)

- [`PlumberEndpoint$getEndpointParams()`](#method-PlumberEndpoint-getEndpointParams)

- [`PlumberEndpoint$setPath()`](#method-PlumberEndpoint-setPath)

- [`PlumberEndpoint$clone()`](#method-PlumberEndpoint-clone)

Inherited methods

- [`plumber::Hookable$registerHooks()`](https://www.rplumber.io/reference/Hookable.html#method-registerHooks)
- [`plumber::PlumberStep$exec()`](https://www.rplumber.io/reference/PlumberStep.html#method-exec)
- [`plumber::PlumberStep$registerHook()`](https://www.rplumber.io/reference/PlumberStep.html#method-registerHook)

------------------------------------------------------------------------

### Method `getTypedParams()`

retrieve endpoint typed parameters

#### Usage

    PlumberEndpoint$getTypedParams()

------------------------------------------------------------------------

### Method `canServe()`

ability to serve request

#### Usage

    PlumberEndpoint$canServe(req)

#### Arguments

- `req`:

  a request object

#### Returns

a logical. `TRUE` when endpoint can serve request.

------------------------------------------------------------------------

### Method `matchesPath()`

determines if route matches requested path

#### Usage

    PlumberEndpoint$matchesPath(path)

#### Arguments

- `path`:

  a url path

#### Returns

a logical. `TRUE` when endpoint matches the requested path.

------------------------------------------------------------------------

### Method [`new()`](https://rdrr.io/r/methods/new.html)

Create a new `PlumberEndpoint` object

#### Usage

    PlumberEndpoint$new(
      verbs,
      path,
      expr,
      envir,
      serializer,
      parsers,
      lines,
      params,
      comments,
      description,
      responses,
      tags,
      srcref
    )

#### Arguments

- `verbs`:

  Endpoint verb Ex: `"GET"`, `"POST"`

- `path`:

  Endpoint path. Ex: `"/index.html"`, `"/foo/bar/baz"`

- `expr`:

  Endpoint function or expression that evaluates to a function.

- `envir`:

  Endpoint environment

- `serializer`:

  Endpoint serializer. Ex:
  [`serializer_json()`](https://www.rplumber.io/reference/serializers.md)

- `parsers`:

  Can be one of:

  - A `NULL` value

  - A character vector of parser names

  - A named [`list()`](https://rdrr.io/r/base/list.html) whose keys are
    parser names names and values are arguments to be applied with
    [`do.call()`](https://rdrr.io/r/base/do.call.html)

  - A `TRUE` value, which will default to combining all parsers. This is
    great for seeing what is possible, but not great for security
    purposes

  If the parser name `"all"` is found in any character value or list
  name, all remaining parsers will be added. When using a list, parser
  information already defined will maintain their existing argument
  values. All remaining parsers will use their default arguments.

  Example:

      # provide a character string
      parsers = "json"

      # provide a named list with no arguments
      parsers = list(json = list())

      # provide a named list with arguments; include `rds`
      parsers = list(json = list(simplifyVector = FALSE), rds = list())

      # default plumber parsers
      parsers = c("json", "form", "text", "octet", "multi")

- `lines`:

  Endpoint block

- `params`:

  Endpoint params

- `comments, description, responses, tags`:

  Values to be used within the OpenAPI Spec

- `srcref`:

  `srcref` attribute from block

#### Returns

A new `PlumberEndpoint` object

------------------------------------------------------------------------

### Method `getPathParams()`

retrieve endpoint path parameters

#### Usage

    PlumberEndpoint$getPathParams(path)

#### Arguments

- `path`:

  endpoint path

------------------------------------------------------------------------

### Method `getFunc()`

retrieve endpoint function

#### Usage

    PlumberEndpoint$getFunc()

------------------------------------------------------------------------

### Method `getFuncParams()`

retrieve endpoint expression parameters

#### Usage

    PlumberEndpoint$getFuncParams()

------------------------------------------------------------------------

### Method `getEndpointParams()`

retrieve endpoint defined parameters

#### Usage

    PlumberEndpoint$getEndpointParams()

------------------------------------------------------------------------

### Method `setPath()`

Updates `$path` with a sanitized `path` and updates the internal path
meta-data

#### Usage

    PlumberEndpoint$setPath(path)

#### Arguments

- `path`:

  Path to set `$path`. If missing a beginning slash, one will be added.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    PlumberEndpoint$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
