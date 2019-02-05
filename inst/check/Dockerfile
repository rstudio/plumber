FROM rocker/drd
MAINTAINER Jeff Allen <cran@trestletech.com>

RUN apt-get update -qq && apt-get install -y \
  curl \
  libxml2-dev \
  git-core \
  libssl-dev/unstable \
  libssh2-1 \
  texlive-latex-base \
  texlive-fonts-recommended \
  texlive-fonts-extra

RUN R -e 'install.packages(c("XML", "devtools", "testthat", "PKI", "httpuv", "rmarkdown"))'

# Install pandoc
RUN curl -fLo /tmp/pandoc-2.2-1-amd64.deb https://github.com/jgm/pandoc/releases/download/2.2/pandoc-2.2-1-amd64.deb && \
  dpkg -i /tmp/pandoc-2.2-1-amd64.deb && \
  apt-get install -f && \
  rm /tmp/pandoc-2.2-1-amd64.deb

# ENV RSTUDIO_PANDOC=/pandoc
# ENV PATH=$PATH:/pandoc

RUN R -e "install.packages(c('htmlwidgets', 'visNetwork', 'analogsea'))"

# rforge required because of some recent instability in PKI... disconcerting.
# https://stat.ethz.ch/pipermail/r-help/2016-December/443572.html
RUN R -e "install.packages('PKI',,'https://www.rforge.net/')"


CMD git clone -b "release-v0.4.6" https://github.com/schloerke/plumber.git /plumber && \
  R CMD build /plumber && \
  R CMD check plumber_*.tar.gz --as-cran
