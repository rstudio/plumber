---
layout: page
title: Docker (Basic)
comments: true
---

<div class="row"><div class="col-sm-8" markdown="1">

This article will guide you through setting up plumber applications in [Docker](https://docker.io). Docker is a platform built on top of Linux Containers that allow you to run processes in an isolated environment; that environment might have certain resources/software pre-configured or may emulate a particular Linux environment like Ubuntu 14.04 or CentOS 7.3. 

The article on [Basic Hosting](../hosting) walks you through a deployment model that does not require Docker, if that's what you're looking for.

## Docker Background

We won't delve into the basics of Docker or how to setup or install everything on your system. Docker provides some [great resources](https://docs.docker.com/) for those who are just looking to get started. Here we'll assume that you have Docker installed and you're familiar with the basic commands required to spin up a container.

In this article, we'll take advantage of the [trestletech/plumber](https://hub.docker.com/r/trestletech/plumber/) Docker image that bundles a recent version of R with the most recent version of plumber pre-installed (the underlying R image is courtesy of the [rocker](https://github.com/rocker-org/rocker) project). You can get this image with a 

{% highlight bash %}
docker pull trestletech/plumber
{% endhighlight %}

Remember that this will get you the current snapshot of plumber and will continue to use that image until you run `pull` again.

## Single Application

We'll start by just running a single plumber application in Docker just to see things at work. By default, the `trestletech/plumber` image will take the first argument after the image name as the name of the file that you want to `plumb()` and serve on port 8000. So right away you can run one of the examples that's included in plumber and already installed on the image.

{% highlight bash %}
docker run --rm -p 8000:8000 trestletech/plumber
{% endhighlight %}

which is the same as:

{% highlight bash %}
docker run --rm -p 8000:8000 trestletech/plumber /usr/local/lib/R/site-library/plumber/examples/04-mean-sum/meansum.R
{% endhighlight %}


 - `docker run` tells Docker to run a new container
 - `--rm` tells Docker to clean-up after the container when it's done
 - `-p 8000:8000` says to map port 8000 from the plumber container (which is where we'll run the server) to port 8000 of your local machine
 - `trestletech/plumber` is the name of the image we want to run
 - `/usr/local/lib/R/site-library/plumber/examples/03-mean-sum/meansum.R` is the path **inside of the Docker container** to plumber. You'll note that you do not need plumber installed on your host machine for this to work, nor does the path `/usr/local/...` need to exist on your machine. This references the path inside of the docker container where the R file you want to `plumb()` can be found. This is the default path that the image uses if you don't specify anything else.

 This will start plumber on the file you specified on port 8000 of that new container. Because you used the `-p` argument, port 8000 of your local machine will be forwarded into your container. You can test this by running this on the machine where Docker is running: `curl localhost:8000/tail`, or if you know the IP address of the machine where Docker is running, you could visit it in a web browser. The `/tail` path is one that's defined in the plumber file we just specified -- you should get an empty array back.

If that works, you can try using one of your own plumber files in this arrangement. Keep in mind that the file you want to run **must** be available inside of the container and you must specify the path to that file as it exists inside of the container. Keep it simple for now -- use a plumber file that doesn't require any additional R packages or depend on any other files outside of the plumber definition.

For instance if you have a plumber file saved in your current directory called `api.R`, you could use the following command

{% highlight bash %}
docker run --rm -p 8000:8000 -v `pwd`/api.R:/plumber.R trestletech/plumber /plumber.R
{% endhighlight %}

You'll notice that we used the `-v` argument to specify a "volume" that should be passed from our host machine into the Docker container. We defined that the location of that file should be at `/plumber.R`, so that's the argument we give last to tell the container where to look for the plumber definition. You can use this same technique to share a whole directory instead of just passing in a single R file which is useful if your plumber API depends on some data files or other R files.

 You can also use the `trestletech/plumber` image just like you use any other. For example, if you want to start a container based on this image and poke around in a bash shell:

{% highlight bash %}
docker run -it --rm --entrypoint /bin/bash trestletech/plumber
{% endhighlight %}

This can be a handy way to debug problems. Prepare the command that you think should work then add `--entrypoint /bin/bash` before `trestletech/plumber` and explore around a bit, or try to run the R process and spawn the plumber application manually and see where things go wrong (often a missing package or missing file).

## Custom Dockerfiles

You can build upon the `trestletech/plumber` image and build your own Docker image by writing your own Dockerfile. Dockerfiles have a vast array of options and possible configurations, so [see the official docs](https://docs.docker.com/engine/reference/builder/) if you want to learn more about any of these options.

A couple of commands that are important for us today:

 - `RUN` runs a command and includes the output in the Docker image you're building. So if you want to build a new image that has the `broom` package, you could add a line in your Dockerfile that says `RUN R -e "install.packages('broom')"`, making the `broom` package available in your new Docker image.
 - `ENTRYPOINT` is the command to run when starting the image. `trestletech/plumber` specifies an entrypoint that starts R, `plumb()`s a file, then `run()`s the router. If you want to change how plumber starts or run some extra commands (like add a global processor)` before you run the router, you'll need to provide a custom `ENTRYPOINT`.
 - `CMD` these are the default arguments to provide to `ENTRYPOINT`. `trestletech/plumber` uses only the first argument as the name of the file that you want to `plumb()`.

So your custom Dockerfile could be as simple as:

{% highlight bash %}
FROM trestletech/plumber
MAINTAINER Docker User <docker@user.org>

RUN R -e "install.packages('broom')"

CMD ["/app/plumber.R"]
{% endhighlight %}

This Dockerfile would just extend the `trestletech/plumber` image in two ways. First, it `RUN`s one additional command to install the `broom` package. Second, it customizes the default `CMD` argument that will be used when running the image. This would expect to find a plumber application in `/app/plumber.R`

You could then build your custom Docker image from this Dockerfile using the command `docker build -t myCustomDocker .` (where `.` -- the current directory -- is the directory where that Dockerfile is stored).

Then you'd be able to use `docker run --rm -v `pwd`:/app myCustomDocker` to run your custom image, passing in your application as a volume.

## Automatically Run on Restart

If you want your container to start automatically when your machine is booted, you can use the `-d` switch for `docker run`.

`docker run -p 1234:8000 -d myCustomDocker` would run the custom image you created above automatically every time your machine boots and expose the plumber service on port `1234` of your host machine. You'll need to make sure that your firewall allows connections on port `1234` if you want others to be able to access your service.

## Conclusion

You should now be able to run a single plumber application in Docker. If you're looking to run multiple plumber applications on the same server in Docker, continue on to the next section: [Advanced Docker](../docker-advanced).

</div>
