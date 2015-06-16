---
layout: page
title: Simple Example
---

Web browser forms can easily encode the values of their inputs in either a GET or POST request. Modern browsers can also create other types of requests including PUT and DELETE. It's perfectly sensible to use rapier as an endpoint for these types of requests from the browser.

Below on the left you'll find a web application that uses [jQuery](http://jquery.com/) to send requests to a rapier API which processes those requests. You can edit the slider inputs to preview what the request would look like before submitting it to the API. The code for the rapier API is included on the right so you can see how each endpoint would behave.

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
          <pre>GET {{ site.rapier_url }}/graph</pre>
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
      $('#value-url').text('POST {val: ' + val + '} -> {{ site.rapier_url }}/append');
    }

    function updateTailURLs(){
      var val = $('#tail-value').val();
      $('#tail-url').text('GET {{ site.rapier_url }}/tail?n=' + val);
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
