
ARG R_VERSION=latest

FROM rocker/r-ver:${R_VERSION}
LABEL maintainer="barret@rstudio.com"

ARG PLUMBER_REF=master

# BEGIN rstudio/plumber layers
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
  git-core \
  libssl-dev \
  libcurl4-gnutls-dev \
  curl \
  libsodium-dev \
  libxml2-dev

RUN install2.r remotes

# But cache at this step
# https://stackoverflow.com/a/55621942/591574
ADD https://github.com/rstudio/plumber/commits/ _docker_cache

RUN Rscript -e "remotes::install_github('rstudio/plumber@${PLUMBER_REF}')"

EXPOSE 8000

ENTRYPOINT ["R", "-e", "pr <- plumber::plumb(rev(commandArgs())[1]); pr$run(host='0.0.0.0', port=8000, swagger=TRUE)"]

CMD ["/usr/local/lib/R/site-library/plumber/examples/04-mean-sum/plumber.R"]

# EOF rstudio/plumber layers

# README:

# Usage (adjust the tags/versions according to your preferences):

# build docker file
#   docker build --build-arg R_VERSION=4.0.2 -t rstudio/plumber:latest .
# run with defaults
#   docker run -it -p 8000:8000 --rm --name plumber rstudio/plumber:latest
# open in browser
#   firefox http://localhost:8000/__swagger__/ &

# to run with your own api - mount your plumber.R file into the container like so:
#   docker run -it  -p 8000:8000 --rm -v ~/R/x86_64-pc-linux-gnu-library/4.0/plumber/examples/10-welcome/plumber.R:/api/plumber.R:ro --name myapi rstudio/plumber:latest /api/plumber.R
# then browse with
#   curl http://localhost:8000/


# Extend the rstudio/plumber:TAG Dockerfile / build your own custom image adding debian packages and your own api:

## ./Dockerfile
#   FROM rstudio/plumber:latest
#   RUN apt-get update -qq && apt-get install -y \
#     [list-your-debian-packages-here]
#   # add app files from host's present working dir
#   COPY . /api
#   # set default startup command to run the app's "plumber.R" file
#   CMD ["/api/plumber.R"]
