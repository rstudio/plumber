Thoughts for https://github.com/rstudio/plumber/pull/883

# Independent questions
- [ ] Should `post**` hooks be run in reverse order? (Like `on.exit(after = TRUE)`)
- [ ] Should we add support for `afterserve` hooks?
  * Would call `later::later(function() { private$runHooks("afterserve") })`


# TODO for this PR
- [ ] Remove or relocate this file before merging
- [ ] Merge in #882 logic
- [ ] Be comfortable with the breaking changes below


# Known breaking changes
* When adding amount, the previous mount will continue to exist
* If a mount can not handle a request, the next mount will be attempted.
  * Previously, if the first matching mount could not handle the request, a 404 was returned.
  * To restore previous behavior, set `mount$set404Handler(plumber:::default404Handler)`


# Design desires
* Remove `forward()` as a global flag. Instead use a sentinal value that can be returned. (E.g. `next()`)
* Registration system for different return status situation. (E.g. 405, 307, 404 handlers)


# Adding a mount

Current `$mount(path=, router=)`:
* If mount path exists, replace it
* If no mount path exists, append mount to end

Proposed `$mount(path=, router=, ..., after=)` (with fall through):
* Do not unmount existing path locations
* If `after=NULL`, set `after = length(mounts)`
* Append mount at `after` location

Proposed `$unmount(path=)`:
* Allow for `path=` to be a Plumber router


# Route execution

Updates:
  * Use `routeNotFound()` when `forward()` global flag is overloaded by (possibly) multiple mounts
  * Move `405`, `307`, `404` logic to `lastChanceRouteNotFound()` instead of end of `$route()` logic
    * `$route()`: Call `lastChanceRouteNotFound(handle404 = private$notFoundHandler)` only if no 404 handler has been set
    * `$serve()`: Only on root. Call `lastChanceRouteNotFound(handle404 = default404Handler)` as `$route()` had its chance
  * Set default 404 handler to `rlang::missing_arg()` by default
    * Overwriting this value will allow per-mount control of 404 handling
    * If nothing is done, the original `default404Handler()` will be called


* `$call(req)` - Hook for {httpuv}
  * Set root router at `req$pr`
  * Make `res`
  * call `serve(req, res)

* `$serve(res)`
  * Run preroute hooks
  * Call `$route(req, res)`
  * If current value is `routeNotFound()`
    * Set value to `lastChanceRouteNotFound(req, res, pr = self, default404Handler)`
  * Run postroute hooks
  * Serialize content
    * Run `preserialize` hooks
    * Run serializer code
    * Run `postserialize` hooks
  * **Proposal: Run `afterserve` hooks?**
    * Runs in a later execution. Users have requested to have a "after the route has returned, run this code" hook

* `$route(req, res)`
  * Try to exec route from `__first__` routes
    * If found, return result
  * Execute each Filter
  * Try to exec route from `__no-preempt__` routes
    * If found, return result
  * Try each mount...
    * If mount path matches request path...
      * Run `MOUNT$route(req, res)`
      * If _value_ is not `routeNotFound()`...
        * Return _value_
  * If 404 handler has been set
    * (404 Handling can not be `forward()`ed)
    * Return `lastChanceRouteNotFound(req, res, pr = self, default404Handler)`
  * Return `routeNotFound()`

* `lastChanceRouteNotFound(req, res, pr, handle404)`
  * If in `307` situation
    * Return `default307Handle(req, res, location)`
  * If in `405` situation
    * Return `default405Handle(req, res)`
  * Return `handle404(req, res)`


## Assertions
* Mount should be able to return own 404 method
* `307` / `405` logic should work within the mount that it is terminating from
  * Ex: If in `mnt1`, `mnt2` can not help find more possible routes
* Routes should be able to `forward()` when matched
  * Static file mounts use this
* Should be able to mount multiple routers at the same location
* Docs should be the last mount (reverting `after=0` logic for #882)
