plumber 0.3.1
--------------------------------------------------------------------------------
* Add a method to consume JSON on post (you can still send a query string in
  the body of a POST request as well).
* Added `@serializer htmlwidget` to support rendering and returning a 
  self-contained htmlwidget from a plumber endpoint.

plumber 0.3.0
--------------------------------------------------------------------------------
* BREAKING CHANGE: serializer factories are now registered instead of the 
  serializer themselves. Thus, `addSerializer()` now expects a function that
  returns a serializer, and `Response$new()` now expects a serializer itself
  rather than a character string naming a serializer. Internally it is the 
  serializer itself that is attached to the response rather than the name of
  the serializer. This allows for a serializer to customize its behavior.
* Accept an additional argument on the `@serializer` annotation -- R code that
  will be passed in as an argument to the serializer factory. See example
  `09-content-type`.

plumber 0.2.4
--------------------------------------------------------------------------------
* Add a filter which parses and sets req$cookies to be a list corresponding to
  the cookies provided with the request.
* Responses can set multiple cookies
* Bug Fix: conver non-character arguments in setCookie to character before URL-
  encoding.

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
