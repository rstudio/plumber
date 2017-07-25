---
layout: page
title: Static Hosting
comments: true
---

<div class="row"><div class="col-sm-8" markdown="1">

plumber includes a static file server which can be used to host directories of static assets such as JavaScript, CSS, or HTML files. These servers are fairly simple to configure and integrate into your plumber application.

{% highlight r %}
#* @assets ./files/static
list()
{% endhighlight %}

This example would expose the local directory `./files/static` at the `/public` path on your server. So if you had a file `./files/static/branding.html`, it would be available on your plumber server at `/public/branding.html`. 

You can optionally provide an additional argument to configure the public path used for your server. For instance

{% highlight r %}
#* @assets ./files/static /static
list()
{% endhighlight %}

would expose the directory not at `/public`, but at `/static`.

The "implementation" of your server in the above examples is just an empty `list()`. You can also specify a `function()` like you do with the other plumber annotations. At this point, the implementation doesn't alter the behavior of your static server. Eventually, this list or function may provide an opportunity to configure the server by changing things like cache control settings.

If you're configuring a plumber server programmatically, the relevant method for configuring a static server is `router$addAssets(localDir, publicDir)`.
</div></div>
