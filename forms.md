---
layout: page
title: Forms
permalink: /forms/
---

<div class="container">
  <div class="row">
    <div class="col-md-6">
      <input type="text" name="val" value="" id="value" />
      <div class="row">
        <div class="col-lg-10">
          <pre id="value-url"></pre>
        </div>
        <div class="col-lg-2 pull-right">
          <button id="post" type="submit" class="btn btn-primary">Submit</button>
        </div>
      </div>

      <hr />

      <code class="lead">/tail</code>
      <pre id="tail"></pre>
      <div>
        <img id="plot" />
      </div>
    </div>
  </div>
</div>


<script type="text/javascript">
  $(function(){
    $("#value").ionRangeSlider({
      min: 1,
      max: 100,
      from: 50,
      onChange: function (data) {
        updateURLs();
      },
    });

    function updateURLs(){
      var val = $('#value').val();
      $('#value-url').text('POST {val: ' + val + '} -> {{ site.rapier_url }}/append');
    }


    function updateOutput(){
      return $.get('{{ site.rapier_url }}/tail')
      .done(function(tail){
        $('#tail').text(tail.val);
        return $.get('{{ site.rapier_url }}/graph')
        .done(function(img){
          $('#plot').attr('src', 'data:image/png;base64,' + img);
        });
      });
    }

    // init
    updateURLs();
    updateOutput();

    $('#post').click(function(){
      $.post('{{ site.rapier_url }}/append', {val: $('#value').val() })
      .done(function(){
        updateOutput();
      })
      .fail(function(err){
        console.log(err);
      });

      return false; // don't bubble
    })
  });
</script>
