# Static file router

Static file router

Static file router

## Details

Creates a router that is backed by a directory of files on disk.

## Super classes

[`plumber::Hookable`](https://www.rplumber.io/reference/Hookable.md) -\>
[`plumber::Plumber`](https://www.rplumber.io/reference/Plumber.md) -\>
`PlumberStatic`

## Methods

### Public methods

- [`PlumberStatic$new()`](#method-PlumberStatic-new)

- [`PlumberStatic$print()`](#method-PlumberStatic-print)

- [`PlumberStatic$clone()`](#method-PlumberStatic-clone)

Inherited methods

- [`plumber::Hookable$registerHooks()`](https://www.rplumber.io/reference/Hookable.html#method-registerHooks)
- [`plumber::Plumber$addAssets()`](https://www.rplumber.io/reference/Plumber.html#method-addAssets)
- [`plumber::Plumber$addEndpoint()`](https://www.rplumber.io/reference/Plumber.html#method-addEndpoint)
- [`plumber::Plumber$addFilter()`](https://www.rplumber.io/reference/Plumber.html#method-addFilter)
- [`plumber::Plumber$addGlobalProcessor()`](https://www.rplumber.io/reference/Plumber.html#method-addGlobalProcessor)
- [`plumber::Plumber$call()`](https://www.rplumber.io/reference/Plumber.html#method-call)
- [`plumber::Plumber$filter()`](https://www.rplumber.io/reference/Plumber.html#method-filter)
- [`plumber::Plumber$getApiSpec()`](https://www.rplumber.io/reference/Plumber.html#method-getApiSpec)
- [`plumber::Plumber$getDebug()`](https://www.rplumber.io/reference/Plumber.html#method-getDebug)
- [`plumber::Plumber$handle()`](https://www.rplumber.io/reference/Plumber.html#method-handle)
- [`plumber::Plumber$mount()`](https://www.rplumber.io/reference/Plumber.html#method-mount)
- [`plumber::Plumber$onHeaders()`](https://www.rplumber.io/reference/Plumber.html#method-onHeaders)
- [`plumber::Plumber$onWSOpen()`](https://www.rplumber.io/reference/Plumber.html#method-onWSOpen)
- [`plumber::Plumber$openAPIFile()`](https://www.rplumber.io/reference/Plumber.html#method-openAPIFile)
- [`plumber::Plumber$registerHook()`](https://www.rplumber.io/reference/Plumber.html#method-registerHook)
- [`plumber::Plumber$removeHandle()`](https://www.rplumber.io/reference/Plumber.html#method-removeHandle)
- [`plumber::Plumber$route()`](https://www.rplumber.io/reference/Plumber.html#method-route)
- [`plumber::Plumber$run()`](https://www.rplumber.io/reference/Plumber.html#method-run)
- [`plumber::Plumber$serve()`](https://www.rplumber.io/reference/Plumber.html#method-serve)
- [`plumber::Plumber$set404Handler()`](https://www.rplumber.io/reference/Plumber.html#method-set404Handler)
- [`plumber::Plumber$setApiSpec()`](https://www.rplumber.io/reference/Plumber.html#method-setApiSpec)
- [`plumber::Plumber$setDebug()`](https://www.rplumber.io/reference/Plumber.html#method-setDebug)
- [`plumber::Plumber$setDocs()`](https://www.rplumber.io/reference/Plumber.html#method-setDocs)
- [`plumber::Plumber$setDocsCallback()`](https://www.rplumber.io/reference/Plumber.html#method-setDocsCallback)
- [`plumber::Plumber$setErrorHandler()`](https://www.rplumber.io/reference/Plumber.html#method-setErrorHandler)
- [`plumber::Plumber$setParsers()`](https://www.rplumber.io/reference/Plumber.html#method-setParsers)
- [`plumber::Plumber$setSerializer()`](https://www.rplumber.io/reference/Plumber.html#method-setSerializer)
- [`plumber::Plumber$swaggerFile()`](https://www.rplumber.io/reference/Plumber.html#method-swaggerFile)
- [`plumber::Plumber$unmount()`](https://www.rplumber.io/reference/Plumber.html#method-unmount)

------------------------------------------------------------------------

### Method `new()`

Create a new `PlumberStatic` router

#### Usage

    PlumberStatic$new(direc, options)

#### Arguments

- `direc`:

  a path to an asset directory.

- `options`:

  options to be evaluated in the `PlumberStatic` router environment

#### Returns

A new `PlumberStatic` router

------------------------------------------------------------------------

### Method [`print()`](https://rdrr.io/r/base/print.html)

Print representation of `PlumberStatic()` router.

#### Usage

    PlumberStatic$print(prefix = "", topLevel = TRUE, ...)

#### Arguments

- `prefix`:

  a character string. Prefix to append to representation.

- `topLevel`:

  a logical value. When method executed on top level router, set to
  `TRUE`.

- `...`:

  additional arguments for recursive calls

#### Returns

A terminal friendly representation of a `PlumberStatic()` router.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    PlumberStatic$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
