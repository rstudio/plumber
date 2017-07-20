---
layout: page
title: Programmatic Usage
comments: true
---

  <div class="jumbotron">
    <h2>Deprecation Warning</h2>
    <p>This section describes the behavior in Plumber prior to the 0.4.0 release. As of v0.4.0, this documentation is no longer valid. Please see <a href="https://book.rplumber.io/programmatic-usage">here</a> for updated documentation.</p>
    <div class="clearfix"></div>
  </div>

<div class="row"><div class="col-sm-8" markdown="1">
The easiest way to use plumber is by adding comments to decorate your existing functions, as you've likely seen throughout the examples and documentation here. There is, however, another approach that you can use to define behavior in plumber. This approach may be useful if you need to completely wrap up the execution of a plumber server in an executable script, rather than relying on files to be saved with particular names. If you don't have such a use-case in mind, the comment-based approach will certainly be an easier way to get started.

The programmatic approach allows you to create a plumber router by hand without having to specify a source file that defines the behavior. You can actually start either approach via the `plumber::plumber$new()` constructor. You can optionally provide a file location to this function -- which is also available via the shortcut `plumb("filename.R")`, or you can call the constructor with no arguments. If you don't specify a file name, you've created a "blank" router, to which you can later add functionality.

Adding functionality to a router relies primarily on two functions: `addEndpoint()` and `addFilter()` which, as you might suspect, add endpoints and filters to your router. The details on the parameters of each of these functions is available in the comparison below.
</div></div>

<div class="row">
  <div class="col-md-6 right-border">
    <h3 class="right-title fixed-width">Programmatic</h3>
    <div class="clear"></div>
    <div class="pull-right">
      {% highlight r %}
        {% include R/programmatic.R %}
      {% endhighlight %}
    </div>
  </div>
  <div class="col-md-6">
    <h3 class="fixed-width">Comment Decorators</h3>
      {% highlight r %}
        {% include R/programmatic-comments.R %}
      {% endhighlight %}

      The above file uses the more "traditional" plumber approach of decorating the existing functions with comments. You could parse and run this file using the following commands in R.

      {% highlight r %}
        library(plumber)
        router <- plumb("plumber-logger.R")
        router$run(port=8000)
      {% endhighlight %}

      This would produce the same results as the programmatic approach.
  </div>
</div>

