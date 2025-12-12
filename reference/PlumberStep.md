# plumber step R6 class

an object representing a step in the lifecycle of the treatment of a
request by a plumber router.

## Super class

[`plumber::Hookable`](https://www.rplumber.io/reference/Hookable.md) -\>
`PlumberStep`

## Public fields

- `srcref`:

  from step block

- `lines`:

  lines from step block

- `serializer`:

  step serializer function

## Methods

### Public methods

- [`PlumberStep$new()`](#method-PlumberStep-new)

- [`PlumberStep$exec()`](#method-PlumberStep-exec)

- [`PlumberStep$registerHook()`](#method-PlumberStep-registerHook)

- [`PlumberStep$clone()`](#method-PlumberStep-clone)

Inherited methods

- [`plumber::Hookable$registerHooks()`](https://www.rplumber.io/reference/Hookable.html#method-registerHooks)

------------------------------------------------------------------------

### Method [`new()`](https://rdrr.io/r/methods/new.html)

Create a new `PlumberStep()` object

#### Usage

    PlumberStep$new(expr, envir, lines, serializer, srcref)

#### Arguments

- `expr`:

  step expr

- `envir`:

  step environment

- `lines`:

  step block

- `serializer`:

  step serializer

- `srcref`:

  `srcref` attribute from block

#### Returns

A new `PlumberStep` object

------------------------------------------------------------------------

### Method `exec()`

step execution function

#### Usage

    PlumberStep$exec(req, res)

#### Arguments

- `req, res`:

  Request and response objects created by a Plumber request

------------------------------------------------------------------------

### Method `registerHook()`

step hook registration method

#### Usage

    PlumberStep$registerHook(
      stage = c("preexec", "postexec", "aroundexec"),
      handler
    )

#### Arguments

- `stage`:

  a character string.

- `handler`:

  a step handler function.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    PlumberStep$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
