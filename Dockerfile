FROM rocker/rstudio:4.5.1
# NOTE: synapser 2.x is untested on R >4.4.2
# but the rstudio docker images only support 4.5 and 4.6

# no login required
ENV DISABLE_AUTH=true

RUN apt-get -y update && \
apt-get -y upgrade && \
apt-get -y install \
libcurl4-openssl-dev \
libfontconfig1-dev \
libfreetype6-dev \
libfribidi-dev \
libgit2-dev \
libharfbuzz-dev \
libjpeg-dev \
libncurses-dev \
libpng-dev \
libreadline-dev \
libsqlite3-dev \
libtiff5-dev \
libuv1-dev \
libxml2-dev \
linux-libc-dev \
python3 \
python3-pip \
python3-venv \
python-is-python3 && \
apt-get clean

USER rstudio

# Install R packages
ADD install_packages_or_fail.R /
ADD install_versioned_package_or_fail.R /
# synapser depends on rjson 0.2.21, but a newer version is installed by default
RUN Rscript --no-save install_versioned_package_or_fail.R rjson 0.2.21
RUN Rscript --no-save install_packages_or_fail.R tidyverse devtools BiocManager reticulate

# install BioConductor (v. 3.22 is for R version 4.5)
RUN Rscript -e 'BiocManager::install(version = "3.22")'

# synapser requires Python <=3.11
RUN Rscript -e "reticulate::install_python(version = '3.11.10')"
RUN Rscript -e "reticulate::virtualenv_create(envname='r-reticulate',version = '3.11.10')"
RUN Rscript -e "reticulate::use_virtualenv('r-reticulate')"

# Install synapser and, by extension, the synapse Python client
RUN Rscript --no-save install_packages_or_fail.R synapser
# Update synapse Python client to the latest version to pull in security updates
RUN Rscript -e "reticulate::virtualenv_install('r-reticulate', 'synapseclient')"

# Install Python package boto3, which will be used by the synapse Python client
RUN R -e "reticulate::virtualenv_install(reticulate::virtualenv_list()[1], 'boto3')"

# Let rstudio have sudo access without having to enter a password
USER root
RUN echo 'rstudio   ALL=(ALL) NOPASSWD:ALL' | sudo EDITOR='tee -a' visudo
