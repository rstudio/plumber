---
layout: page
title: DigitalOcean 
comments: true
---

<div class="row"><div class="col-sm-8" markdown="1">
plumber includes the ability to automatically provision a server on [DigitalOcean](https://www.digitalocean.com/?refcode=0740f5169634). DigitalOcean is a cloud hosting provider that's known for being low-cost and simple to use, so it's a great starting point if you're just getting into managing your own servers online.

If you're not looking to use DigitalOcean or Ubuntu 16.04, then you can look at one of the alternative hosting models: using [PM2](../hosting/) or [Docker](../docker/).

plumber uses the [analogsea](https://github.com/sckott/analogsea) package to communicate with DigitalOcean. If this is your first time using DigitalOcean or analogsea, it might be wise to get familiar with the basics of how to create a server and SSH into it. This isn't strictly required before proceeding, but you'll likely have a better experience if you have some basic familiarity with how to manage your SSH keys and log into a DigitalOcean server.

## Provision Server

> A video covering this topic is available [here](https://www.youtube.com/watch?v=OiREOPog3Cs), though it may not be completely current.

plumber includes the `do_provision()` function which can create and provision a plumber server in DigitalOcean. (You'll find that all plumber functions that specifically pertain to DigitalOcean begin with the `do_` prefix.) More specifically, running this function will automatically provision a Ubuntu 16.04 server (or "droplet," in DigitalOcean parlance) with the following resources:

- A recent version of R installed
- plumber installed globally in the system library
- The 'nginx“ web server installed to route web traffic from port 80 (HTTP) to your plumber process.
- ufw installed as a firewall to restrict access on the server. By default it only allows incoming traffic on port 22 (SSH) and port 80 (HTTP).
- A 4GB swap file is created to ensure that machines with little RAM (the default) are able to get through the necessary R package compilations.

This process may take a few minutes to complete, but once done you'll have a server ready for subsequent `do_` interactions from your R session.

## Deploy An API

> Note that at the time of writing it is required that your plumber API be named `plumber.R` in the local directory that you point to. This restriction will likely be lifted in the future, but for now you'll need to place your API in a directory and name it `plumber.R` in order to use this function.

Once you've provisioned a server using `do_provision()`, you can then deploy a plumber API to this server from your local machine using the `do_deploy_api()` function. This function will upload a directory containing a plumber API from your local machine to your DigitalOcaen droplet and install all of the necessary infrastructure to allow your droplet to reliably host that plumber API. Specifically...

 - An entry will be added in nginx to forward traffic from the given `path` to your API.
 - A systemd entry will be created for your API (named `plumber-<given name>`) which will ensure that the API gets started when the machine boots and, if the backing R process ever crashes, will spawn a new process to bring the API back online.
 - The directory containing your API will be uploaded from your local machine to `/var/plumber/<given name>` on the remote droplet.

You can use this same function call to update your API on the server; each time you invoke it the API will be reuploaded from your local machine.

The `do_remove_api()` function allows you to remove an API from the droplet.

Running `do_provision()` with the parameter `example` set to `TRUE` (the default) will automatically provision a simple API named `hello` for you. If you provisioned the droplet with this example, you can SSH into the server and perform a variety of actions associated with any such API that has been deployed.

 1. You'll find the file(s) required to run this API in `/var/plumber/hello/`. 
 2. The systemd unit associated with this API is named `plumber-hello`. You can run `systemd restart plumber-hello` to restart the service (e.g. if you've made changes to the plumber file and want to respawn the API). 
 3. `journalctl -u plumber-hello` will show you the logs associated with the API; add a `-f` to the command to have the logs streamed to you.
 4. You can visit your server in a web browser (copy the IP address from the `analogsea::droplets()` output or from the DigitalOcean web app. It should forward you to `http://<your-droplet-ip>/hello/` which will show you some example output telling you that plumber is online.

## Forwarding from the Root URL

As noted above, requests for the root URL of your server forward to the example API that is deployed on your droplet. This behavior can be managed by

 - The `forward` parameter on `do_deploy_api`
 - The `do_forward()` function, which allows you to explicitly forward requests for the root URL to a particular application.
 - The `remove_forward()` function which removes all forwarding from the root request.

## Configure HTTPS

> A video covering this topic is available [here](https://www.youtube.com/watch?v=EpgdrRTBZwg), though it may not be completely current.

One great feature of plumber's provisioning functions is the ability to automatically provision a TLS/SSL certificate on your droplet, enabling you to add a layer of encryption and security between you and your users. Some services (e.g. Amazon Alexa's Custom Skills) require your API server to be secured via SSL before they'll consider communicating with it, so this can be an important feature for your plumber server.

The one constraint on using this feature, however, is that you will need a domain name entry associated with your server before you can get an SSL certificate. If you already have a domain name, you can just add a DNS entry to it (e.g. myplumberserver.mydomain.com). If you don't already have a domain name, [here is one option](http://tres.tl/domain) for registering a new domain name, but there are dozens of such registrars available and you can choose whichever you're most comfortable with. Once you have a domain, you'll need to create an "A record" pointing to your droplet's IP address on either the primary domain name or some subdomain.

One thing to be aware of before creating the DNS entry is that the IP address associated with your droplet is transient. If you destroy that droplet and reprovision a new one later, you will no longer have control of that IP address. DigitalOcean has a feature called "Floating IPs" (see the "Network" tab) which allow you to reserve a particular IP address and associate it with the droplet of your choosing. This is a nice feature to use before creating your DNS entries, as it can take some time to update a DNS entry to point to a new IP address in the event that you want to change out your droplet. Using a floating IP you can merely associate that IP address with a different droplet at a moment's notice.

However you choose to go about it, before proceeding you will need to have a domain entry pointing to the IP address associated with your server. Be aware that it can take multiple minutes or hours for changes in DNS to propagate throughout the Internet.

Once a domain name has been created and is pointed at your server, you can run the `do_configure_https()` function to begin the process of procuring a free SSL certificate for your domain. You'll need to pass in the droplet, the domain name, an email address (to be sent to LetsEncrypt in the event that they need to contact you in regards to your certificate), and a flag indicating whether or not you accept their [terms of service](https://letsencrypt.org/documents/LE-SA-v1.1.1-August-1-2016.pdf) (this must be `TRUE` to use the function).

> `do_configure_https()` relies on the wonderful [LetsEncrypt organization](https://letsencrypt.org/) to provide a free SSL certificate. Historically, this service has not been free; please consider a [donation](https://letsencrypt.org/donate/) to support their cause if you find this service to be valuable.

Assuming that the DNS entry was correctly setup, once this function completes you'll see a success message about being granted a new certificate. You can verify that everything was setup properly by visiting the domain name that you passed in to this function. You should find that HTTP requests are redirected to HTTPS, and that your browser shows a secure symbol when you visit your API endpoints in the browser now.

</div></div>
