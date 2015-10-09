---
layout: page
title: Hosting
comments: true
---

<div class="row"><div class="col-sm-8" markdown="1">

## Coming Soon!

If you've been through the [hosting documentation](../hosting/), your server should be running smoothly. You should have your plumber applications setup in pm2 so they'll be automatically started on boot and restarted if they ever crash. You get all the logs from the applications and have a good record of what your services have been doing.

However, you're still running all of these services on arbitrary ports. Unless you expect your users to specify each application's unique port number every time they visit (`http://myserver.org:4163/`), there's one more step to complete: you'll want someone to route traffic from a "normal" HTTP port (80 for HTTP, 443 for HTTPS) into your applications running on their individual ports.

TODO: 
 - nginx (?) forwarding
 - Firewall, keeping private ports

</div></div>
