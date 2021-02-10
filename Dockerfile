# set the base image
 FROM ubuntu:18.04

MAINTAINER Noah Warren <nolwarre@ucsc.edu>

USER root

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get -y install time git make wget automake autoconf gcc g++ unzip sudo \
    python python-pip default-jre libidn11 && \
    ln -s /bin/pip3 /bin/pip && \
    apt-get clean && \
    apt-get purge && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /usr/src

RUN pip install biopython==1.76 && \
    pip install pandas

RUN wget https://github.com/RemiAllio/MitoFinder/archive/master.zip && \
    unzip master.zip && \
    mv MitoFinder-master MitoFinder && \
    cd MitoFinder && \
    ./install.sh && \
    p=$(pwd) && \
    echo "\n#Path to mitofinder \nexport PATH=\$PATH:$p" >> ~/.bashrc && \
    . ~/.bashrc

WORKDIR /usr/src

RUN wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/LATEST/ncbi-blast-2.11.0+-x64-linux.tar.gz && \
    tar -zxvf ncbi-blast-2.11.0+-x64-linux.tar.gz

RUN git clone https://github.com/marcelauliano/MitoHiFi.git && \
    cd MitoHiFi && \
    cd exampleFiles && \
    ln -s ../scripts && \
    ln -s ../run_MitoHiFi.sh && \
    chmod +x run_MitoHiFi.sh

WORKDIR /usr/src/MitoHiFi/exampleFiles

ENV PATH=/usr/src/ncbi-blast-2.11.0+/bin:$PATH
