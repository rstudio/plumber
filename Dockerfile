FROM rocker/r-ver:4.0.2

# BEGIN rstudio/plumber layers

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
  git-core \
  libssl-dev \
  libcurl4-gnutls-dev \
  curl \
  libsodium-dev \
  libxml2-dev

RUN install2.r plumber

EXPOSE 8000

ENTRYPOINT ["R", "-e", "pr <- plumber::plumb(rev(commandArgs())[1]); pr$run(host='0.0.0.0', port=8000, swagger=TRUE)"]

CMD ["/usr/local/lib/R/site-library/plumber/examples/04-mean-sum/plumber.R"]

# EOF rstudio/plumber layers

# README:

# Usage (adjust the tags/versions according to your preferences):

# build with "docker build -t rstudio/plumber:v0.4.6 -t rstudio/plumber:latest ."
# run with defaults "docker run -p 8000:8000 --rm --name plumber rstudio/plumber:v0.4.6"
# browse with "firefox http://localhost:8000/__swagger__/ &"

# to run with your own api - mount your plumber.R file into the container like so: "docker run -p 8000:8000 --rm -v ~/R/x86_64-pc-linux-gnu-library/4.0/plumber/examples/10-welcome/plumber.R:/api/plumber.R:ro --name myapi rstudio/plumber:v0.4.6 /api/plumber.R"
# then browse with "curl http://localhost:8000/"


# Extend the rstudio/plumber:v0.4.6 Dockerfile / build your own custom image adding debian packages and your own api:

#FROM rstudio/plumber:v0.4.6
# RUN apt-get update -qq && apt-get install -y \
#   [list-your-debian-packages-here]
#COPY . /api # add app files from host's present working dir
#CMD ["/api/plumber.R"] # set default startup command to run the app's "plumber.R" file
