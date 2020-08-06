
library(stringi)

#* @preempt auth
#* @use /
function(a=1){
  list(msg=paste0("Welcome to the root URL! a = ", a))
}

#* @filter auth
function(req, res){
  if (!stri_startswith_fixed(req$QUERY_STRING, "?user=")){
    # Don't continue
    res$status <- 401
    return(list(err="Not authorized"))
  }

  user <- substr(req$QUERY_STRING, 7, nchar(req$QUERY_STRING))
  req$username <- user

  forward()
}

#* @get /me
function(req, res){
  list(name=req$username)
}

#* @get /error
#* @preempt auth
function(req, res){
  stop("I throw an error!")
}

#* @get /set
#* @preempt auth
function(req){
  req$testVal <- 1
  req$testVal
}

#* @get /get
#* @preempt auth
function(req){
  req$testVal
}

#* > This is an HTML file that will demonstrate the HTTPUV bug in which req's that
#* > share a TCP channel also share an environment. This is why we force connections
#* > to close for now.
#* The above bug does not exist anymore given httpuv >= 1.4.0
#* The test path below has been updated to include expected and unexpected output
#* @get /test
#* @preempt auth
#* @serializer html
function(){
  '<html>
    <head>
    </head>
    <body>
      <h3>Expected answer (good): `{}`<h3>
      <h3>Shared TCP Connections answer (bad): `[1]`.</h3>
      <br/>
      <h3>Answer:</h3>
      <span id="answer"></span>
      <script src="https://code.jquery.com/jquery-2.1.4.min.js"></script>
      <script>
        $.get("/get").done(function(){
          $.get("/set").done(function(){
            $.get("/get").done(function(a){
              window.document.getElementById("answer").append(JSON.stringify(a, null, "  "))
            });
          });
        });
      </script>
    </body>
  </html>'
}
