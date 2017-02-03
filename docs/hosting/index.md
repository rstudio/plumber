---
layout: page
title: Hosting
comments: true
---

<div class="row"><div class="col-sm-8" markdown="1">
R is a traditionally a "single-threaded" environment, meaning that when R is busy evaluating a command or serving a request, nothing else can get done in the process. This makes R not particularly well-suited for hosting a large amount of incoming HTTP traffic on its own. But with a bit of help from external tools, R-backed servers like plumber or [Shiny](http://shiny.rstudio.com) can still be scaled to handle just about any amount of traffic you need it to handle.

There are a variety of tools that were built to help manage web hosting in a single-threaded environment like R. Some of the most compelling tools were developed around Ruby (like [Phusion Passenger](https://www.phusionpassenger.com/)) or Node.js (like [Node Supervisor](https://github.com/petruisfan/node-supervisor), [forever](https://github.com/foreverjs/forever) or [pm2](http://pm2.keymetrics.io/)). Thankfully, many of these tools can be adapted to support managing processes in other languages like R.

This guide will walk you through hosting a couple of different plumber applications using [pm2](http://pm2.keymetrics.io/) as the process manager. We'll show the commands needed to do this in Ubuntu 14.04, but you can use any Operating System or distribution that is supported by pm2. At the end, you'll have a server that automatically starts your plumber services when booted, restarts them if they ever crash, and even centralizes the logs for your plumber services.

## Server Deployment and Preparation

The first thing you'll need to do, regardless of which process manager you choose, is to deploy the R files containing your plumber applications to the server where they'll be hosted. Keep in mind that you'll also need to include any supplemental R files that are `source()`d in your plumber file, and any other datasets or dependencies that your files have. 

You'll also need to make sure that the R packages you need (and the appropriate versions) are available on the remote server. You can either do this manually by installing those packages or you can consider using a tool like [Packrat](https://rstudio.github.io/packrat/) to help with this.

There are a myriad of features in pm2 that we won't cover here. It is a good idea to spend some time reading through their documentation to see which features might be of interest to you and to ensure that you understand all the implications of how pm2 hosts services (which user you want to run your processes as, etc.). Their [quick-start guide](http://pm2.keymetrics.io/docs/usage/quick-start/) may be especially relevant. For the sake of simplicity, we will do a basic installation here without customizing many of those options. 

## Install pm2

Now you're ready to install pm2. pm2 is a package that's maintained in `npm` (Node.js's package management system); it also requires Node.js in order to run. So to start you'll want to install Node.js. On Ubuntu 14.04, the necessary commands are:

{% highlight bash %}
sudo apt-get update
sudo apt-get install nodejs npm
{% endhighlight %}

Once you have npm and Node.js installed, you're ready to install pm2.

{% highlight bash %}
sudo npm install -g pm2
{% endhighlight %}

This will install pm2 globally (`-g`) on your server, meaning you should now be able to run `pm2 --version` and get the version number of pm2 that you've installed.

In order to get pm2 to startup your services on boot, you should run `sudo pm2 startup` which will create the necessary files for your system to run pm2 when you boot your machine.

## Wrap Your plumber File

Once you've deployed your plumber files onto the server, you'll still need to tell the server *how* to run your server. You're probably used to running commands like

{% highlight r %}
pr <- plumb("myfile.R")
pr$run(port=4500)
{% endhighlight %}

Unfortunately, pm2 doesn't understand R scripts natively; however, it is possible to specify a custom interpreter. We can use this feature to launch an R-based wrapper for our plumber file using the `Rscript` scripting front-end that comes with R. The following script will run the two commands listed above.

{% highlight r %}
#!/usr/bin/env Rscript

library(plumber)
pr <- plumb('myfile.R')
pr$run(port=4000)
{% endhighlight %}

Save this R script file on your server as something like `run-myfile.R`. You should also make it executable by changing the permissions on the file using a command like `chmod 755 run-myfile.R`. You should now execute that file to make sure that it runs the service like you expect. You should be able to make requests to your server on the appropriate port and have the plumber service respond. You can kill the process using `Ctrl-c` when you're convinced that it's working. Make sure the shell script is in a permanent location so that it won't be erased or modified accidentally. You can consider creating a designated directory for all your plumber services in some directory like `/usr/local/plumber`, then put all services and their associated Rscript-runners in their own subdirectory like `/usr/local/plumber/myfile/`.

## Introduce Our Service to pm2

We'll now need to teach pm2 about our plumber service so that we can put it to work. You can register and configure any number of services with pm2; let's start with our `myfile` plumber service.

You can use the `pm2 list` command to see which services pm2 is already running. If you run this command now, you'll see that pm2 doesn't have any services that it's in charge of.

Once you have the scripts and code stored in the directory where you want them, use the following command to tell pm2 about your service.

{% highlight bash %}
pm2 start --interpreter="Rscript" /usr/local/plumber/myfile/run-myfile.R
{% endhighlight %}

You should see some output about pm2 starting an instance of your service, followed by some status information from pm2. If everything worked properly, you'll see that your new service has been registered and is running. You can see this same output by executing `pm2 list` again. 

Once you're happy with the pm2 services you have defined, you can use `pm2 save` to tell pm2 to retain the set of services you have running next time you boot the machine. All of the services you have defined will be automatically restarted for you.

At this point, you have a persistent pm2 service created for your plumber application. This means that you can reboot your server, or find and kill the underlying R process that your plumber application is using and pm2 will automatically bring a new process in to replace it. This should help guarantee that you always have a plumber process running on the port number you specified in the shell script. It is a good idea to reboot the server to ensure that everything comes back the way you expected.

You can repeat this process with all the plumber applications you want to deploy, as long as you give each a unique port to run on. Remember that you can't have more than one service running on a single port. And be sure to `pm2 save` every time you add services that you want to survive a restart.

## Logs and Management

Now that you have your applications defined in pm2, you may want to drill down into them to manage or debug them. If you want to see more information, use the `pm2 show` command and specify the name of the application from `pm2 list`. This is usually the same as the name of the shell script you specified, so it may be something like `pm2 show run-myfile`. 

Some of this information may be of particular interest to you, but keep an eye on the `restarts` count for your applications. If your application has had to restart many times, that implies that the process is crashing often, which is a sign that there's a problem in your code.

Thankfully, pm2 automatically manages the log files from your underlying processes. so if you ever need to check the log files of a service, you can just run `pm2 logs run-myfile`, where `myfile` is again the name of the service obtained from `pm2 list`. This command will show you the last few lines logged from your process, and then begin streaming any incoming log lines until you exit (`Ctrl-c`). 

If you want a big-picture view of the health of your server and all the pm2 services, you can run `pm2 monit` which will show you a dashboard of the RAM and CPU usage of all your services.

## Path-to-Port Forwarding

If you merely want your plumber services running on their unique ports persistently, then at this point you're all set. If you are wanting to run multiple services on the same port -- differentiated by some path prefix, then visit the [Path-to-Port documentation](../path-to-port).

</div></div>
