#' @include plumber.R
NULL

#' Deprecated R6 functions
#'
#' @keywords internal
#' @export
#' @describeIn deprecated_r6 See [Hookable()]
hookable <- R6Class(
  "hookable",
  inherit = Hookable,
  public = list(
    #' @description Initialize a new `hookable`. Throws deprecated warning prompting user to use [`Hookable`]
    initialize = function() {
      # use `.Deprecated` until `lifecycle` gets R6 support
      .Deprecated(msg = paste0(
        "`hookable` is deprecated as of plumber 1.0.0.\n",
        "`Please use `Hookable` instead."
      ))
      # lifecycle::deprecate_warn("1.0.0", "hookable$new()", "Hookable$new()")


      ## no initialize method
      # super$new(...)
    }
  )
)
