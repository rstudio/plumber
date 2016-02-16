function updateCookie(cookieName, id) {
  $('#' + id).text(Cookies.get(cookieName) || '<empty>');
}
updateCookie('visitcounter', 'counter-cookie');
$(function(){
  $("#counter-btn").click(function(){
    $.ajax({
    type: 'GET',
        url: '{{ site.plumber_url }}/sessions/counter',
        cache: false,
      xhrFields: {
        withCredentials: true
      },
      crossDomain: true,
    })
    .then(function(val){
      $('#counter-result').text(val[0]);
      updateCounterCookie('visitcounter', 'counter-cookie')
    });
  });
});
