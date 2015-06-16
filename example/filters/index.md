---
layout: page
title: Filters Example
---

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
        <pre id="about-result" class="empty-result">Click "Get" to see the response.</pre>
      </div>

      <hr />

      <h3 class="right-title fixed-width">GET /me</h3>
      <div class="clear"></div>
      <div class="row">
        <div class="col-md-10 col-md-offset-2">
          <pre id ="me-url"></pre>
        </div>
      </div>
      <pre id="me-result" class="empty-result">Click "Get" to see the response.</pre>
    </div>
    <div class="col-md-6">
      <h3 class="fixed-width">appender.R</h3>
      {% highlight r %}
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
      $('#me-result').text('Click "Get" to see the response.');
      $('#about-result').text('Click "Get" to see the response.');

      getAbout();
      getMe();
    }

    function getUrl(endpoint){
      var sel = $('#username').val();
      var url = '{{ site.rapier_url }}/' + endpoint;
      if (sel){
        url += '?username=' + sel;
      }
      return url;
    }

    onUsernameChange();

    function getAbout(){
      $.get(getUrl('about'))
      .then(function(about){
        $('#about-result').removeClass('empty-result').text(JSON.stringify(about)).fadeOut(100).fadeIn(100)
      })
      .fail(function(aboutErr){
        $('#about-result').removeClass('empty-result').text(aboutErr.responseText).fadeOut(100).fadeIn(100)
      });
    }

    function getMe(){
      $.get(getUrl('me'))
      .then(function(me){
        $('#me-result').removeClass('empty-result').text(JSON.stringify(me)).fadeOut(100).fadeIn(100)
      })
      .fail(function(meErr){
        $('#me-result').removeClass('empty-result').text(meErr.responseText).fadeOut(100).fadeIn(100)
      });
    }




  });
</script>
