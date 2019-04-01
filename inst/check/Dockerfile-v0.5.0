FROM rocker/drd
MAINTAINER Jeff Allen <cran@trestletech.com>

RUN apt-get update -qq && apt-get install -y \
  curl \
  libxml2-dev \
  git-core \
  libsodium-dev \
  libssl-dev/unstable \
  libssh2-1 \
  texlive-latex-base \
  texlive-fonts-recommended \
  texlive-fonts-extra

RUN R -e 'install.packages(c("XML", "devtools", "testthat", "sodium", "httpuv", "rmarkdown", "swagger"))'

# Install pandoc
RUN curl -fLo /tmp/pandoc-2.2-1-amd64.deb https://github.com/jgm/pandoc/releases/download/2.2/pandoc-2.2-1-amd64.deb && \
  dpkg -i /tmp/pandoc-2.2-1-amd64.deb && \
  apt-get install -f && \
  rm /tmp/pandoc-2.2-1-amd64.deb

# ENV RSTUDIO_PANDOC=/pandoc
# ENV PATH=$PATH:/pandoc

RUN R -e "install.packages(c('htmlwidgets', 'visNetwork', 'analogsea'))"

CMD git clone -b "release-v0.5.0" https://github.com/trestletech/plumber.git /plumber && \
  R CMD build /plumber && \
  R CMD check plumber_*.tar.gz --as-cran
