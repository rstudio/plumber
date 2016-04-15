FROM rocker/r-base
MAINTAINER Jeff Allen <docker@trestletech.com>

RUN apt-get update -qq && apt-get install -y \
  git-core \
  libssl-dev/unstable \
  libcurl4-gnutls-dev

RUN R -e 'install.packages(c("devtools"))'

RUN R -e 'devtools::install_github("trestletech/plumber")'
