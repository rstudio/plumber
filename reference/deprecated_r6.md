# Deprecated R6 functions

Deprecated R6 functions

Deprecated R6 functions

Deprecated R6 functions

Deprecated R6 functions

## Functions

- `hookable`: See
  [`Hookable()`](https://www.rplumber.io/reference/Hookable.md)

- `plumber`: See
  [`Plumber()`](https://www.rplumber.io/reference/Plumber.md)

## Super class

[`plumber::Hookable`](https://www.rplumber.io/reference/Hookable.md) -\>
`hookable`

## Methods

### Public methods

- [`hookable$new()`](#method-hookable-new)

- [`hookable$clone()`](#method-hookable-clone)

Inherited methods

- [`plumber::Hookable$registerHook()`](https://www.rplumber.io/reference/Hookable.html#method-registerHook)
- [`plumber::Hookable$registerHooks()`](https://www.rplumber.io/reference/Hookable.html#method-registerHooks)

------------------------------------------------------------------------

### Method `new()`

Initialize a new `hookable`. Throws deprecated warning prompting user to
use [`Hookable`](https://www.rplumber.io/reference/Hookable.md)

#### Usage

    hookable$new()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    hookable$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Super classes

[`plumber::Hookable`](https://www.rplumber.io/reference/Hookable.md) -\>
[`plumber::Plumber`](https://www.rplumber.io/reference/Plumber.md) -\>
`plumber`

## Methods

### Public methods

- [`plumber$new()`](#method-plumber-new)

- [`plumber$clone()`](#method-plumber-clone)

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
- [`plumber::Plumber$print()`](https://www.rplumber.io/reference/Plumber.html#method-print)
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

Initialize a new `plumber`. Throws deprecated warning prompting user to
use [`Plumber`](https://www.rplumber.io/reference/Plumber.md)

#### Usage

    plumber$new(...)

#### Arguments

- `...`:

  params passed in to `Plumber$new()`

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    plumber$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
