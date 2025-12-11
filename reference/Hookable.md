# Hookable

Hookable

Hookable

## Methods

### Public methods

- [`Hookable$registerHook()`](#method-Hookable-registerHook)

- [`Hookable$registerHooks()`](#method-Hookable-registerHooks)

- [`Hookable$clone()`](#method-Hookable-clone)

------------------------------------------------------------------------

### Method `registerHook()`

Register a hook on a router

#### Usage

    Hookable$registerHook(stage, handler)

#### Arguments

- `stage`:

  a character string.

- `handler`:

  a hook function.

------------------------------------------------------------------------

### Method `registerHooks()`

Register hooks on a router

#### Usage

    Hookable$registerHooks(handlers)

#### Arguments

- `handlers`:

  a named list of hook functions.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    Hookable$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
