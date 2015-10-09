---
layout: page
title: Routing
comments: true
---

<div class="row"><div class="col-sm-8" markdown="1" id="routing-section">

## Literal Routes

Plumber supports different "routing" schemes which will direct incoming traffic to the appropriate [endpoint](../endpoints). The simplest form is to use fixed text. For instance the following endpoint will receive all <code>GET</code> requests for `/user/me`.

{% highlight r %}
#* @get /user/me
function(){
  return list(id=1, name="Test User")
}
{% endhighlight %}

## Variable Routes

In addition to the literal routes shown above, variable-routing is also supported -- enabling you to match incoming requests to corresponding routes more flexibly. The following example uses variable-routing.

{% highlight r %}
userNames <- list(1="Test User", 2="Different User")

#* @get /user/<id>
function(id){
  return list(id=id, name=userNames[[id]])
}
{% endhighlight %}

This endpoint would accept incoming traffic for requests like `/user/1` or `/user/someUser`. You'll notice that the variable in the path is surrounded by `<` and `>` tags, and is given the name of `id`; you can name your variables as you see fit. You'll also notice that a corresponding variable named `id` will be made available to you in the parameters of the endpoint function definition. This parameter will include whatever value was specified in the path in the `<id>` position. So a `GET` request for `/user/14` would evaluate the function with `id="14"` (as a character string).

You can even do more complex variable-routes such as... 

{% highlight r %}
#* @get /user/<from>/connect/<to>
function(from, to){
  # Do something with the `from` and `to` variables...
}
{% endhighlight %}

In both the literal routing and the untyped variable-routing shown above, all parameters will be provided to the function as a character string.

## Typed Variable Routes

If you only intend to support a particular type of data for a parameter in your variable route, you can also specify that in the route.

{% highlight r %}
#* @get /user/<id:int>
function(id){
  if (id < 100) {
    # ...
  }
}

#* @post /user/activated/<active:bool>
function(active){
  if (active){
    # ...
  }
}
{% endhighlight %}

Specifying types for your variables saves you the step of having to convert the incoming parameter from a character string to whatever type you need it to be in. It also ensures that only appropriate paths match the specified routes. For instance, given the route `/user/<id:int>`, the request for `/user/someUser` will not match, as `"someUser"` is not an integer.

The following variable-route types are available in plumber:

| R Type | Plumber Name |
|---------|-----------------|
| logical | `bool`, `logical` |
| numeric | `double`, `numeric` |
| integer | `int` |
|----------------------------|

</div></div>
