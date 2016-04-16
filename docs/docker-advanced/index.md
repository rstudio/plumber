---
layout: page
title: Advanced Docker
comments: true
---

<div class="row"><div class="col-sm-8" markdown="1">

This article will go into detail about more advanced Docker configurations using Docker Compose to host multiple plumber applications on a single server and even load-balancing across multiple plumber processes. If you haven't already, you should go through the [Basic Docker](./docker) article to learn the basics of running plumber in Docker before continuing with this article.

In order to run multiple applications on one server, **you will also need to install `docker-compose` on your system.** This is not included with some installations of Docker, so you will need to [follow these instructions](https://docs.docker.com/compose/install/) if you get an error when you try to run `docker-compose` on the command-line. Docker Compose helps orchestrate multiple Docker containers. If you're planning to run more than one plumber process, you'll want to use Docker Compose to keep them all alive and route traffic between them.

## Multiple Plumber Applications

Docker Compose will be used to help us organize multiple plumber processes. We won't go into detail about how to use Docker Compose, so if you're new you should familiarize yourself using the [official docs](https://docs.docker.com/compose). 

You should define a Docker Compose configuration that defines the behavior of every plumber application that you want to run. You'll first want to setup a Dockerfile that defines the desired behavior for each of your applications (as [we outlined previously](./docker#custom-dockerfiles). You could use a `docker-compose.yml` configuration like the following:

{% highlight yml %}
version: '2'
services:
  app1:
    build: ./app1/
    volumes:
     - ./data:/data
     - ./app1:/app
    restart: always
    ports:
     - "7000:8000"
  app2:
    image: trestletech/plumber
    command: /app/plumber.R
    volumes:
     - ../app2:/app
    restart: always
    ports:
     - "7001:8000"
{% endhighlight %}

More detail on what each of these options does and what other options exist can be found [here](https://docs.docker.com/compose/compose-file/). This configuration defines two docker containers that should run: `app1` and `app2`. They're layed out as follows:

{% highlight txt %}
docker-compose.yml
app1
├── Dockerfile
├── api.R
app2
├── plumber.R
data
├── data.csv
{% endhighlight %}

You can see that app2 is the simpler of the two apps; it just has the plumber definition that should be run through `plumb()`. So we merely specify the `image` using the default plumber Docker image, and then customize the `command` to specify where the plumber API definition can be found on the container. Since we're mapping `./app2` to `/app`, the definition would be found in `/app/plumber.R`. We specify that it should `always` restart if anything ever happens to the container, and we export port `8000` from the container to port `7001` on the host.

app1 is our more complicated app. If has some extra data in another directory that needs to be loaded, and it has a custom Dockerfile. This could be because it has additional R packages or system dependencies that it requires.

If you now run `docker-compose up`, Docker Compose will build the referenced images in your config file and then run them. You'll find that app1 is available on port `7000` of your local machine, and app2 is available on port `7001`. If you want this to run in the background and survive restarts of your computer, you can use the `-d` switch just like with `docker run`. 

## Multiple Applications on One Port

In some cases, it's desirable to run all of your plumber services on a standard HTTP port like `80` or `443`. In that case, you'd prefer to have a router running on port 80 that can send traffic to the appropriate application by distinguishing based on a path prefix. Requests for `myserver.com/app1/` are sent to the `app1` container, and `myserver.org/app2/` targets the `app2` container, but both are available on port 80 on your server.

In order to do this, we can use another Docker container running nginx which is configured to route traffic between the two app containers. We'd add the following entry to our `docker-compose.yml` alongside the app containers we have defined.

{% highlight yml %}
  nginx:
    image: nginx:1.9
    ports:
     - "80:80"
    volumes:
     - ./nginx.conf:/etc/nginx/nginx.conf:ro
    restart: always
    depends_on:
     - app1
     - app2
{% endhighlight %}

This uses the nginx docker image that will be downloaded for you. In order to run nginx in a meaningful way, we have to provide a configuration file and place it in `/etc/nginx/nginx.conf`, which we do by mounting a local file at that location on the container. 

A basic nginx config file could look something like the following:


{% highlight conf %}
events {
  worker_connections  4096;  ## Default: 1024
}

http {
        default_type application/octet-stream;
        sendfile     on;
        tcp_nopush   on;
        server_names_hash_bucket_size 128; # this seems to be required for some vhosts

        server {
                listen 80 default_server;
                listen [::]:80 default_server ipv6only=on;

                root /usr/share/nginx/html;
                index index.html index.htm;

                server_name MYSERVER.ORG

                location /app1/ {
                        proxy_pass http://app1:8000/;
                        proxy_set_header Host $host;
                }

                location /app2/ {
                        proxy_pass http://app2:8000/;
                        proxy_set_header Host $host;
                }


                location ~ /\.ht {
                        deny all;
                }
        }
}
{% endhighlight %}

You should set the `server_name` parameter above to be whatever the public address is of your server. You can save this file as `nginx.conf` in the same directory as your Compose config file.

Docker Compose is intelligent enough to know to route traffic for `http://app1:8000/` to the `app1` container, port 8000, so we can leverage that in our config file. Docker containers are able to contact each other on their non-public ports, so we can go directly to port `8000` for both containers. This proxy configuration will trim the prefix off of the request before it sends it on to the applications, so your applications don't need to know anything about being hosted publicly at a URL that includes the `/app1/` or `/app2/` prefix

We should also get rid of the previous port mappings to ports `7000` and `7001` on our other applications, as we don't want those to be publicly accessible anymore.

If you now run `docker compose up` again, you'll see your two application servers running but now have a new nginx server running, as well. And you'll find that if you visit your server on port 80, you'll see the "welcome to Nginx!" page. If you access `/app1` you'll be sent to `app1` just like we had hoped. 

## Load Balancing

If you're expecting a lot of traffic on one application or have an API that's particularly computationally complex, you may want to distribute the load across multiple R processes running the same plumber application. Thankfully, we can use Docker Compose for this, as well.

First, we'll want to create multiple instances of the same application. This is easily accomplished with the `docker-compose scale` command. You simple run `docker-compose scale app1=3` to run three instances of `app1`. Now we just need to load balance traffic across these three instances.

You could setup the nginx configuration that we already have to balance traffic across this pool of workers, but you would need to manually re-configure and update your nginx instance every time that you need to scale the number up or down, which might be a hassle. Luckily, there's a more elegant solution.

We can use the [dockercloud/haproxy](https://github.com/docker/dockercloud-haproxy) Docker image to automatically balance HTTP traffic across a pool of workers. This image is intelligent enough to listen for workers in your pool arriving or leaving and will automatically remove/add these containers into their pool. Let's add a new container into our configuration that defines this load balancer

{% highlight yml %}
  lb:
    image: 'dockercloud/haproxy:1.2.1'
    links:
     - app1
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
{% endhighlight %}

The trick that allows this image to listen in to our scaling of `app1` is by passing in the docker socket as a shared volume. Note that this particular arrangement will differ based on your host OS. The above configuration is intended for Linux, but MacOS X users would require a (slightly different config](https://github.com/docker/dockercloud-haproxy#example-of-docker-composeyml-running-in-linux).

We could export port `80` of our new load balancer to port `80` of our host machine if we solely wanted to load-balance a single application. Alternatively, we can actually use both nginx (to handle the routing of various applications) and HAProxy (to handle the load balancing of a particular application). To do that, we'd merely add a new `location` block to our `nginx.conf` file that knows how to send traffic to HAproxy, or modify the existing `location` block to send traffic to the load balancer instead of going directly to the application.

So the `location /app1/` block becomes:

{% highlight yml %}
                location /app1/ {
                        proxy_pass http://lb:8000/;
                        proxy_set_header Host $host;
                }
{% endhighlight %}

Where `lb` is the name of the HAProxy load balancer that we defined in our Compose configuration.

The next time you start/redeploy your Docker Compose cluster, you'll be balancing your incoming requests to `/app1/` across a pool of 1 or more workers based on whatever you've set the `scale` to be for that application.

Do keep in mind that when using load-balancing that it's not longer guaranteed that subsequent requests for a particular application will land on the same process. This means that if you maintain any state in your plumber application (like a global counter, or a user's session state), you can't expect that to be shared across the workers that the user might encounter. There are at least three possible solutions to this problem:

 1. Use a more robust means of maintaing your state. You could put the state in a database, for instance, that lives outside of your R processes and your plumber workers would get and save their state externally.
 2. You could serialize the state to the user using [(encrypted) session cookies](./sessions/), assuming it's small enough. In this scenario, your workers would write data back to the user in the form of a cookie, then the user would include that same cookie in its future requests. This works best if the state is going to be set rarely and read often (for instance, it could be written when the user logs in, then read on each request to detect the identity of this user).
 3. You can enable "sticky sessions" in the HAProxy load balancer. This would ensure that each user's traffic always gets routed to the same worker. The downside of this approach, of course, is that it's a less even means of distributing traffic. You could end up in a situation in which you have 2 workers but 90% of your traffic is hitting one of your workers, because it just so happens that the users triggering more requests were all "stuck" to one particular worker.

## Conclusion

You should now be able to run multiple plumber applications on a single server using multiple Docker containers organized in Docker Compose. You can either run each application on a separate port, or share a single port for multiple applications. You can also choose to have one process back your application or load-balance the incoming requests across a pool of workers for that application.
</div>
