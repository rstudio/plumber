FROM rocker/drd
MAINTAINER Jeff Allen <cran@trestletech.com>

RUN apt-get update -qq && apt-get install -y \
  libxml2-dev \
  git-core \
  libssl-dev/unstable \
  libssh2-1-dev \
  texlive-latex-base \
  texlive-fonts-recommended \
  texlive-fonts-extra

RUN R -e 'install.packages(c("XML", "devtools", "testthat", "PKI", "httpuv", "rmarkdown"))'

# Install pandoc
RUN mkdir /pandoc && \
  cd /pandoc && \
  wget https://s3.amazonaws.com/rstudio-buildtools/pandoc-debian-x86_64-1.15.2.zip && \
  unzip pandoc-debian* && \
  rm pandoc-debian*.zip

ENV RSTUDIO_PANDOC=/pandoc
ENV PATH=$PATH:/pandoc

CMD git clone https://github.com/trestletech/plumber.git /plumber && \
  R CMD build /plumber && \
  R CMD check plumber_*.tar.gz --as-cran
