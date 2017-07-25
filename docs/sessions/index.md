---
layout: page
title: Sessions 
comments: true
---

<div class="row"><div class="col-sm-8" markdown="1">

It can be useful to track a user as they interact with the API. One common way to do this is by setting a cookie on the user's browser/client so that we can identify separate requests as all belonging to the same user. 

You can set a cookie by using the `setCookie()` method on the response object given to a filter/endpoint. The value of the cookie (the second argument) in this method will be stored as a cookie after passing it through `as.character`, but not other serialization will take place. So numbers or character strings should be just fine, but a complex list will likely not get stored in the way you're hoping for.

Here's an example of using `req$cookies` and `res$setCookie()`

{% highlight r %}
#* @get /counter
function(req, res){
  count <- 0
  if (!is.null(req$cookies$visitcounter)){
    count <- as.numeric(req$cookies$visitcounter)
  }
  res$setCookie("visitcounter", count+1)
  return(paste0("This is visit #", count))
}
{% endhighlight %}

This endpoint would first check to see if a `visitcounter` object had already been set on `req$cookies`. It would use that value, if found, to set the counter; otherwise it would start the counter at 0. Then it increments the counter and uses `res$setCookie` to set the new value for the `visitcounter` cookie.

You'll find that if you access this endpoint from a browser, it will set a 'visitcounter' cookie that increments every time you hit the endpoint, as the example below shows.
</div></div>

<div class="row">
<iframe src="{{ site.plumber_url }}/sessions/public/iframe.html" width="100%" height="110px" frameBorder="0"></iframe>
</div>

<div class="row"><div class="col-sm-8" markdown="1">

## Encrypted Session Cookies

Setting individual cookies yourself is a reasonable way to manage your user's sessions. However, plumber also includes a mechanism to store a list of data and (optionally) even encrypt that list. To use this feature, you must explicitly add it to your router after constructing it. For example, you could run the following sequence of commands to create a router that supports encrypted session cookies.

{% highlight r %}
pr <- plumb("myfile.R")
pr$addGlobalProcessor(sessionCookie("secret", "cookieName"))
pr$run()
{% endhighlight %}

You'll notice the above example is using the `sessionCookie` middleware that comes with plumber. By adding this as a global processor on your router, you'll ensure that the `req$session` object is made available on incoming requests and is persisted to the cookie named `cookieName` when the response is ready to be sent to the user. In this example, the key used to encrypt the data is `"secret"`, which is obviously a very weak secret key.

Unlike `res$setHeader()`, the values attached to `req$session` *are* serialized via jsonlite; so you're free to use more complex data structures like lists in your session. Also unlike `res$setHeaders()`, `req$session` encrypts the data using the secret key you provide as the first argument to the `sessionCookie()` function.

To recreate our example above using `req$session`:

{% highlight r %}
#* @get /sessionCounter
function(req){
  count <- 0
  if (!is.null(req$session$counter)){
    count <- as.numeric(req$session$counter)
  }
  req$session$counter <- count + 1
  return(paste0("This is visit #", count))
}
{% endhighlight %}

Again, you would need to add the `sessionCookie()` middleware as a global processor on your router before this code would work.


You'll find that the behavior of the endpoint is the same as the unencrypted version above, but this time the cookie value stored in the user's browser is encrypted.

</div>

<div class="row">
<iframe src="{{ site.plumber_url }}/sessions/public/iframe-secure.html" width="100%" height="110px" frameBorder="0"></iframe>
</div>

<div class="row"><div class="col-sm-8" markdown="1">
## Best Practices

There are two approaches to sessions on servers: you can either store all of the state in a cookie, or store a unique identifier in a cookie and keep the state on the server. There are pros and cons to both approaches. 

Storing all of the state in the cookie simplifies your infrastructure. You don't need a database or a centralized store on the server side to keep all of your active session data which is one less thing for you to maintain. However, there's a limit to the size of a cookie (4kB for most browsers), so you will need to make sure that the data you need to store for your users will always fit in that size (plus some wiggle room for the overhead encryption may incur). 

Keeping your state on the server allows you to keep much more than 4kB of information per user, as you can keep as much information as you want on your filesystem or in your own database. Then all you need to have the user store is a unique identifier that allows you to map the user back to the state you've stored on the server. In this case, you should use a *cryptographically random* (i.e. not `runif` or `rnorm`) generator for your session IDs so that users won't be able to guess the next session ID that you're going to assign to the next user that comes along.

Bear in mind that cookies can trivially be forged. A user can claim that the value of some cookie you assign is whatever value they choose to send to your server. So it's important to leverage encryption if you're sending any data that a malicious user might be able to tamper to cause harm. However, once the cookie is encrypted (with an appropriately long/complex key), it's much more reasonable to store that information in a cookie and expect that an attacker would not be able to alter anything in the message that you're sending.

Also keep in mind that encryption offers no guarantees about validity/signing; I may not be able to modify the message of a cookie that's been assigned to me, but I might be able to steal a cookie off of another computer and present that to your API. In that case, your API would falsely believe that my browser was legitimately using some other user's credentials. Unfortunately, there's not a ton that can be done about this and this attack is applicable to most major web systems today. You can use HTTP-only cookies (which can't be modified by malicious JavaScript) and "Secure" cookies which will only be sent over HTTPS, minimizing the risk of a middleman sniffing the cookies as they go past.

A full discussion of [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS) is outside of the scope for this article, but be aware that there are some complexities involved in using cookies from a domain name other than the one on which your site is hosted. So if you intend to use an API hosted on one domain from your website hosted on another, you will need to read up on the details of CORS and ensure that your plumber API and your clients are all properly configured to comply with the various restrictions that will come into play. See [this article](https://quickleft.com/blog/cookies-with-my-cors/) for a brief presentation of the issue.
</div>
