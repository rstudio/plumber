plumber 0.2.3
--------------------------------------------------------------------------------
* Set options(warn=1) during execution of user code so that warnings are 
  immediately visible in the console, rather than storing them until the server
  is stopped.

plumber 0.2.2
--------------------------------------------------------------------------------
* Add `sessionCookie` function to define a processor that can be used as a
  globalProcessor on a router to encrypt values from req$session and store them
  as an encrypted cookie in on the user's browser.
* Added `setCookie` method to response which (primitively) allows you to set
  a cookie to be included in the response.
* Add `addGlobalProcessor` method on `plumber` class to support a processor that
  runs a processor only a single time, before and then after all other filters 
  and the endpoint.
* Document all public params so CHECK passes

plumber 0.2.1
--------------------------------------------------------------------------------
* Add more Roxygen documentation for exported functions
* Remove the warning in the README as the API seems to be stabilizing.

plumber 0.2.0
--------------------------------------------------------------------------------
* BREAKING: Changed variable-path routing to use bracketted format instead of
  just a colon.
* BREAKING: Renamed `PlumberRouter` R6 object to just `Plumber`.
* Support `addEndpoint()` and `addFilter()` on the `Plumber` object.
* Added support for the `#*` prefix.

plumber 0.1.0
--------------------------------------------------------------------------------
* Initial Release
