# set the base image
 FROM ubuntu:18.04

MAINTAINER Noah Warren <nolwarre@ucsc.edu>

USER root

# create base env
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get -y install time git make wget automake autoconf gcc g++ unzip sudo \
    python python-pip default-jre libidn11 && \
    ln -s /bin/pip3 /bin/pip && \
    apt-get clean && \
    apt-get purge && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install bipython and pandas versions that are compatible
WORKDIR /opt
RUN pip install biopython==1.76 && \
    pip install pandas==0.24.2

# install Mitofinder
WORKDIR /opt
RUN wget https://github.com/RemiAllio/MitoFinder/archive/master.zip && \
    unzip master.zip && \
    mv MitoFinder-master MitoFinder && \
    rm master.zip && \
    cd MitoFinder && \
    ./install.sh
ENV PATH=/opt/MitoFinder:$PATH

# install blast+
WORKDIR /opt
RUN wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/LATEST/ncbi-blast-2.11.0+-x64-linux.tar.gz && \
    tar -zxvf ncbi-blast-2.11.0+-x64-linux.tar.gz && \
    rm ncbi-blast-2.11.0+-x64-linux.tar.gz
ENV PATH=/opt/ncbi-blast-2.11.0+/bin:$PATH

# install MitoHiFi
WORKDIR /opt
RUN git clone https://github.com/marcelauliano/MitoHiFi.git && \
    cd MitoHiFi && \
    cd exampleFiles && \
    ln -s ../scripts && \
    ln -s ../run_MitoHiFi.sh && \
    chmod +x run_MitoHiFi.sh

WORKDIR /data
