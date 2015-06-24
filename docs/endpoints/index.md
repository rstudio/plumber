---
layout: page
title: Endpoints
comments: true
---

Endpoints are the terminal step in process of serving a request. (See the [docs on filters](../filters/) to see what the intermediate steps might be.) An endpoint can simply be viewed as the logic that is ultimately responsible for generating a response to a particular request. You create an endpoint by annotating a function like so:

{% highlight r %}
#' @get /hello
function(){
  return("hello world")
}
{% endhighlight %}

This annotation specifies that this function is responsible for generating the response to any `GET` request to `/hello`. (If you're unfamiliar with `GET` and `POST` HTTP requests, you can read up on them [here](http://www.restapitutorial.com/lessons/httpmethods.html).) Typically, the value returned from the function will be used as the response to the request (after being serialized through a serializer to e.g. convert the response into JSON). In this case, a `GET` response to `/hello` would return the content `["hello world"]` with a JSON content-type, unless you've changed the serializer type.

### HTTP Methods

Endpoints can be specified for any of the four major HTTP "verbs": `GET`, `POST`, `PUT`, and `DELETE` using the annotations `@get`, `@post`, `@put`, and `@delete`, respectively. As you might expect, a function annotated with `@get` will respond *only* to `GET` requests. So if you intend an endpoint to be accessed via multiple HTTP methods, you would need to annotate them with each relevant method as in:

{% highlight r %}
#' @get /vehicle
#' @put /vehicle
#' @post /vehicle
function(req){
  ...
}
{% endhighlight %}

### Error Handling

If an endpoint generates an error, the error handler will generate a response on behalf of the endpoint. By default, this involves capturing the error message and returning a serialized response with an HTTP status code of `500` to signify a server error.


## Example

Below on the left you'll find a web application that uses [jQuery](http://jquery.com/) to send requests to a rapier API which processes those requests. You can edit the slider inputs to preview what the request would look like before submitting it to the API. The code for the rapier API is included on the right so you can see how each endpoint would behave.

The rapier server is hosted at `{{ site.rapier_url }}/append/`.

  <div class="row">
    <div class="col-md-6 right-border">
      <h3 class="right-title fixed-width">POST /append</h3>
      <div class="clear"></div>
      <input type="text" name="val" value="" id="post-value" />
      <pre id="value-url"></pre>
      <div class="row">
        <div class="col-md-2">
          <button id="post-btn" type="submit" class="btn btn-primary">Post</button>
        </div>
        <div class="col-md-10">
          <pre id="post-result" class="empty-result">Click "Post" to see the response.</pre>
        </div>
      </div>

      <hr />

      <h3 class="right-title fixed-width">GET /tail</h3>
      <div class="clear"></div>
      <div>

        <input type="text" name="val" value="" id="tail-value" />
        <div class="row">
          <div class="col-md-2">
            <button id="tail-btn" type="submit" class="btn btn-primary">Get</button>
          </div>
          <div class="col-md-10">
            <pre id="tail-url"></pre>
          </div>
        </div>
        <pre id="tail-result" class="empty-result">Click "Get" to see the response.</pre>
      </div>

      <hr />

      <h3 class="right-title fixed-width">GET /graph</h3>
      <div class="clear"></div>
      <div class="row">
        <div class="col-md-2">
          <button id ="graph-btn" class="btn btn-primary">Get</button>
        </div>
        <div class="col-md-10">
          <pre>GET {{ site.rapier_url }}append/graph</pre>
        </div>
        <img id="plot" />
      </div>
    </div>
    <div class="col-md-6">
      <h3 class="fixed-width">appender.R</h3>
      {% highlight r %}
        {% include R/appender.R %}
      {% endhighlight %}
    </div>
  </div>


<script type="text/javascript">
  $(function(){
    $("#post-value").ionRangeSlider({
      min: 1,
      max: 100,
      from: 50,
      onChange: function (data) {
        updatePostURLs();
      },
    });

    $("#tail-value").ionRangeSlider({
      min: 1,
      max: 50,
      from: 10,
      onChange: function (data) {
        updateTailURLs();
      },
    });

    function updatePostURLs(){
      var val = $('#post-value').val();
      $('#value-url').text('POST {val: ' + val + '} -> {{ site.rapier_url }}/append/append');
    }

    function updateTailURLs(){
      var val = $('#tail-value').val();
      $('#tail-url').text('GET {{ site.rapier_url }}/append/tail?n=' + val);
    }

    function updateOutput(res){
      if (res){
        $('#post-result').fadeOut(100).text(JSON.stringify(res)).removeClass('empty-result').fadeOut(100).fadeIn(100);
      }

      return $.get('{{ site.rapier_url }}/append/tail?n=' + $('#tail-value').val())
      .done(function(tail){
        $('#tail-result').text(JSON.stringify(tail)).removeClass('empty-result').fadeOut(100).fadeIn(100);
        $('#plot').attr('src', '{{ site.rapier_url }}/append/graph?t=' + new Date().getTime()).fadeOut(100).fadeIn(100);
      });
    }

    // init
    updatePostURLs();
    updateTailURLs();
    updateOutput();

    $('#tail-btn').click(function(){
      $.get('{{ site.rapier_url }}/append/tail?n=' + $('#tail-value').val())
      .done(function(tail){
        $('#tail-result').text(JSON.stringify(tail)).removeClass('empty-result').fadeOut(100).fadeIn(100);
      })
      .fail(function(err){
        console.log(err);
      });
    });

    $('#post-btn').click(function(){
      $.post('{{ site.rapier_url }}/append/append', {val: $('#post-value').val() })
      .done(function(res){
        updateOutput(res);
      })
      .fail(function(err){
        console.log(err);
      });
    })

    $('#graph-btn').click(function(){
      $('#plot').attr('src', '{{ site.rapier_url }}/append/graph?t=' + new Date().getTime()).fadeOut(100).fadeIn(100);
    });

  });
</script>
