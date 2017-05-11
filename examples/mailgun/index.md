---
layout: page
title: Receive Emails with mailgun
comments: true
---

<div class="row"><div class="col-sm-8" markdown="1">

[mailgun](http://www.mailgun.com) is a great service that handles the difficult parts of handling emails for developers. One of the features they offer is the ability to POST to an HTTP endpoint upon receiving an email. We'll use this feature to have mailgun send a POST request to a plumber API when an email arrives to a certain email address. mailgun has a very generous free tier, so you can replicate this exercise without spending a dime.

## Mailgun Configuration

After registering for a mailgun account, you'll either need to use their sandbox, or configure a (sub)domain name to be hosted by mailgun. In my case, I setup `plumber.tres.tl` to have its email hosted by mailgun. You could just as easily use `mailgun.myorg.com` if you don't want to disrupt email hosting on your production domain.

Once you have a domain setup, you just add a route that tells mailgun what to do with your email. In my case, I said that it should listen for emails sent to `mailgun@plumber.tres.tl` and, when one comes in, convert it to an HTTP POST request and send it to `http://plumber.tres.tl/mailgun/mail`. 

<img src="../../components/images/mailgun-routes.png" />

## Plumber API

This example will auto-refresh every 3 seconds with the latest emails the API has received. Try sending an email to <a href="mailto:mailgun@plumber.tres.tl">mailgun@plumber.tres.tl</a> to see the API at work.

</div></div>
  <div class="row">
    <div class="col-md-6 right-border">
      <h3 class="right-title fixed-width">GET /tail</h3>
      <div class="clear"></div>
      <div class="row">
        <div class="col-md-10">
          <pre>GET {{ site.plumber_url }}/mailgun/tail</pre>
        </div>
        <div class="col-md-2">
          <img src="../../components/images/refresh.gif" id="result-refresh" />
        </div>
      </div>

      <table id="result-tbl">
        <thead><tr>
          <th>Time</th>
          <th>Subject</th>
        </tr></thead>
        <tbody id="tbody"> </tbody>
      </table>

    </div>
    <div class="col-md-6">
      <h3 class="fixed-width">mailgun.R</h3>
      {% highlight r %}
{% include R/mailgun.R %}
      {% endhighlight %}
    </div>
  </div>


<script type="text/javascript">
  $(function(){
    function updateVersion(){
      $('#result-refresh').fadeIn(300).fadeOut(300);
      $.get('{{ site.plumber_url }}/mailgun/tail')
      .done(function(res){
        $('#tbody').empty();
        $.each(res, function (i, r) {
            var eachrow = "<tr>"
              + '<td class="col-sm-3">' + r.time + "</td>"
              + '<td class="col-sm-3">' + r.subject + "</td>"
              + "</tr>";
            $('#tbody').append(eachrow);
        });
      })
      .fail(function(err){
        console.log(err);
      });
    }


    setInterval(updateVersion, 3000);
    updateVersion();

  });
</script>
