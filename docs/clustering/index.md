---
layout: page
title: Clustering
comments: true
---

<div class="row"><div class="col-sm-8" markdown="1">

> This article expands on the [Hosting documentation](../hosting) which walks you through setting up your application in pm2. If you haven't already gone through that guide, you should do so before proceeding.

Because R is single-threaded, your plumber service will only be able to do one thing at a time. This means that if some endpoint does some expensive computation and takes 10 seconds to complete, no other users will be able to access your plumber service during those 10 seconds -- the requests will all pile up in a queue until the R process becomes available again, at which point the pending requests will be handled in first-in, first-out order. 

For applications which require minimal time to handle a request and/or don't expect many concurrent requests to come in, having one R process behind your plumber application as shown in [the previous article](../hosting) would likely be sufficient.

However, for applications requiring more computational power, you may want to "load-balance" incoming requests across multiple R processes. Of course, this implies that your plumber application will be running multiple times concurrently, which has a couple of implications
 1. Be careful about writing to files, as your plumber processes may be trying to read or write to the same file simultaneously, in which case one process may get corrupted data. Even worse, you might corrupt your file.
 2. You must not retain any "state" in your application in a clustered or load-balanced mode. For instance, if you had a global variable in your script that was updated in response to certain events, you would need to recognize that each plumber process will have its own version of that variable and that it would not be synchronized between your processes. You should store any state your application requires in some other system that can handle concurrent reading and writing like a database.

## Clustering in pm2

> Note that this feature is not available in Node 0.10.x, which is the version available in the default Ubuntu 14.04 repositories. You need to update to a more recent version of Node in order to use this feature.

When you define an application in pm2, you can define the number of "instances" you want pm2 to run for your application. By default, this number is `1`, meaning "run 1 R process for my application." If you change this value to some larger number, then pm2 will run that many instances of your R process.

{% highlight bash %}
pm2 start /usr/local/plumber/myfile/run-myfile.sh -i 2
{% endhighlight %}

Setting `-i 2` in that command tells pm2 to run 2 processes to back your application.

## Configuring Ports

If you were to try that command currently, you'd likely get an error when the second plumber process started up. The problem is that they're both configured to use the same port in the `run-myfile.sh` script. Thankfully, pm2 provides some assistance in sorting this out.

Instead of our old runner script...

{% highlight bash %}
#!/bin/bash

R -e "library(plumber); pr <- plumb('myfile.R'); pr\$run(port=4000)"
{% endhighlight %}

We want a new one that uses different ports for each process. pm2 provides the environment variable `NODE_APP_INSTANCE` which increments for each process that's running. So we can have our applications listen on distinct consecutive ports by using the following script instead:

{% highlight bash %}
#!/bin/bash

R -e "library(plumber); pr <- plumb('myfile.R'); pr\$run(port=4000 + $NODE_APP_INSTANCE)"
{% endhighlight %}

This would use ports 4000, 4001, ... for as many app instances as you had running. Now you'll have multiple instances of your application running on multiple distinct ports.

## Configuring Nginx

> This extends on the work described in [Path-to-Port Forwarding](../path-to-port). If you haven't already gone through that guide, you should do so now.

### Coming Soon!

TODO:

 - nginx single path backed by multiple workers with load-balancing
 - automatically detect the available workers/ports by adding a healthcheck?

</div></div>
