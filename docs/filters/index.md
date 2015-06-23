---
layout: page
title: Filters
---

rapier supports both "endpoints" and "filters." Endpoints use an annotation like `@get` or `@post` and are the serving functions you're probably accustomed to seeing in rapier. An incoming request will go through each of the available endpoints until it finds one that is willing to serve it. A request will only be served by a single endpoint (the first one it encounters that it "matches." Read more about endpoints [here](../endpoints/).

Filters in rapier behave differently. A request may go through multiple filters *before* it is served by an endpoint. Thus, filters are your opportunity to transform the request as it passes through -- either modifying existing information or supplementing it with additional info. All the filters in your file will be evaluated in the order in which they're defined*. In the example below, you'll see two filters: `auth-user` and `require-auth`. 

## Example Filters

The definition of `auth-user` is contained on lines 11-34. It offers a simple, albeit silly, mechanism for determing whether or not a request is coming from a logged in user. Real authentication systems would rely on encrypted cookies or session tokens, but this filter merely looks to see if the request has a parameter named `username` which would be provided by our built-in query string filters. So a request like `http://{{ site.rapier_url }}/about?username=john` would pass in the username of `john` to this function, while a request without that parameter would leave `username` empty. So this filter examines the provided `username` and, if it finds one, looks it up in our "user database" (in this case, a data.frame defined on lines 1-5). If it doesn't find the username in the database, it `stop()`s to indicate that an error has occurred when processing this request. If it does find the username in the database, it modifies the `req` object as it's passing through. This is one of the key tricks of filters -- **filters allow you to attach new data on the `req` object as it's passing through and that new/updated data will be available to later filters and any endpoints this request encounters.**

The next filter is named `require-auth` and is defined on lines 38-48. This filter goes one step further than the previous filter; it doesn't just look to see if the username was provided, it requires that the user is logged in. If the user is not logged in, then it doesn't `forward()` the request. `forward()` is a critical call in rapier filters. When you call `forward()` in a filter, you're telling rapier to continue on in the flow of processing the request -- i.e. whatever remaining filters and endpoint are available for this request will be used. **If you do not call `forward()` in a filter, rapier assumes that your filter has finished processing the request itself, and will not continue the execution with the remaining filters and endpoints.** In this example, lines 42-43 show an example of this. You'll notice that if `req$user` is null, then we set the HTTP status of the response to `401` (a status code which means that authentication is required), then we return a list that has an error field in it, **and we do not `forward()`.** This means that whatever value was returned should be sent directly back to the user without any further evaluation. If you get to the `require-auth` filter and are not already authenticated (i.e. there is not `user` field added to your `req`), then you will proceed no further.

## Example Endpoints and `@preempt`

We define two endpoints in the example below. The endpoint corresponding to `@get /me` is defined on lines 51-56 and is just like any other endpoint you've seen before. However, keep in mind that this endpoint will be evaluated **after all of the available filters have been executed!** Thus, if the request encountered an error in `auth-user` (from an invalid username) or didn't pass through `require-auth` (because a username wasn't provided), then it would never make it to this point. Thus, it's safe to assume that if this endpoint is executing, the request must have satisfactorily passed through whatever filters exist in front of it.

Lastly, we have the `@get /about` endpoint on lines 64-66. This endpoint looks similar to a traditional endpoints, but has one special annotation on line 62 named `@preempt`. `@preempt` is a way of telling rapier to position this filter *in front of* some defined filter. So rapier now knows to execute this endpoint **before** executing the `require-auth` filter. All other filters up to that point will be evaluated as usual, but an incoming request will have an opportunity to be served by this preemptive endpoint before the `require-auth` filter runs. If the request can't be served by this endpoint (i.e. it's not a `GET` request for `/about`), then it will continue on through the remaining filters until it finds an endpoint that can serve it.

Try changing the username to see how it affects the results from the `GET` requests below.

\* This is subject to change. For now, you should put define all of your filters **above** any endpoint in your R file. See [this GitHub issue](https://github.com/trestletech/rapier/issues/10) for more details.

  <div class="row">
    <div class="col-md-6 right-border">
      <h3 class="right-title fixed-width">Set Username</h3>
      <div class="clear"></div>
      <div class="pull-right">
        Select username for this request:
        <select name="username" id="username">
          <option value="">None</option>
          <option value="joe">joe</option>
          <option value="kim">kim</option>
          <option value="invalid">Invalid Username</option>
        </select>
      </div>

      <hr />

      <h3 class="right-title fixed-width">GET /about</h3>
      <div class="clear"></div>
      <div>

        <div class="row">
          <div class="col-md-10 col-md-offset-2">
            <pre id="about-url"></pre>
          </div>
        </div>
        <pre id="about-result" class="empty-result">Loading....</pre>
      </div>

      <hr />

      <h3 class="right-title fixed-width">GET /me</h3>
      <div class="clear"></div>
      <div class="row">
        <div class="col-md-10 col-md-offset-2">
          <pre id ="me-url"></pre>
        </div>
      </div>
      <pre id="me-result" class="empty-result">Loading...</pre>
    </div>
    <div class="col-md-6">
      <h3 class="fixed-width">filters-example.R</h3>
      {% highlight r linenos %}
        {% include R/filters-example.R %}
      {% endhighlight %}
    </div>
  </div>


<script type="text/javascript">
  $(function(){
    $('#username').change(function(){
      onUsernameChange();
    });

    function onUsernameChange(){
      $('#about-url').text(getUrl('about'));
      $('#me-url').text(getUrl('me'));

      $('#me-result').addClass('empty-result');
      $('#about-result').addClass('empty-result');
      $('#me-result').text('Loading...');
      $('#about-result').text('Loading...');

      getAbout();
      getMe();
    }

    function getUrl(endpoint, prefix){
      var sel = $('#username').val();
      var url = '{{ site.rapier_url }}/'
      if (prefix){
        url += 'filters/';
      }
      url += endpoint;
      if (sel){
        url += '?username=' + sel;
      }
      return url;
    }

    onUsernameChange();

    function getAbout(){
      $.get(getUrl('about', true))
      .then(function(about){
        $('#about-result').removeClass('empty-result').text(JSON.stringify(about)).fadeOut(100).fadeIn(100)
      })
      .fail(function(aboutErr){
        $('#about-result').removeClass('empty-result').text(aboutErr.responseText).fadeOut(100).fadeIn(100)
      });
    }

    function getMe(){
      $.get(getUrl('me', true))
      .then(function(me){
        $('#me-result').removeClass('empty-result').text(JSON.stringify(me)).fadeOut(100).fadeIn(100)
      })
      .fail(function(meErr){
        $('#me-result').removeClass('empty-result').text(meErr.responseText).fadeOut(100).fadeIn(100)
      });
    }




  });
</script>
