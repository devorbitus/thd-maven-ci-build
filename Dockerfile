
# Ubuntu 14.04 LTS
# Oracle Java 1.8.0_11 64 bit
# Maven 3.3.9
# Jenkins 1.643
# Nano 2.2.6-1ubuntu1

FROM ubuntu:16.04

MAINTAINER Chris Gruel (https://github.com/devorbitus)

# setup proxy variables
ENV QA_PROXY_HOST=thd-svr-proxy-qa.homedepot.com
ENV QA_PROXY_PORT=9090
ENV GRADLE_VERSION=2.14.1
ENV GRADLE_HOME=/opt/gradle
ENV http_proxy="http://$QA_PROXY_HOST:$QA_PROXY_PORT"
ENV https_proxy="http://$QA_PROXY_HOST:$QA_PROXY_PORT"
ENV http_proxy_slash="$http_proxy"/
ENV TERM=xterm

RUN echo "deb http://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823

# install apps
RUN apt-get update && apt-get install -y wget
RUN apt-get update && apt-get install -y git
RUN apt-get update && apt-get install -y nano
RUN apt-get update && apt-get install -y curl
RUN apt-get update && apt-get install -y libxml-xpath-perl
RUN apt-get update && apt-get install -y build-essential
RUN apt-get update && apt-get install -y unzip
RUN apt-get update && apt-get install -y locales

# Install Gradle
RUN wget --no-check-certificate --no-cookies https://downloads.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
    && unzip gradle-${GRADLE_VERSION}-bin.zip -d /opt \
    && ln -s /opt/gradle-${GRADLE_VERSION}/bin/gradle /usr/bin/gradle \
    && rm -f gradle-${GRADLE_VERSION}-bin.zip

# Install Go
RUN \
  mkdir -p /goroot && \
  curl https://storage.googleapis.com/golang/go1.6.1.linux-amd64.tar.gz | tar xvzf - -C /goroot --strip-components=1

# Set environment variables.
ENV GOROOT /goroot
ENV GOPATH /gopath
ENV PATH $GOROOT/bin:$GOPATH/bin:$PATH

# download certificates
RUN mkdir certificates
RUN wget https://www.entrust.com/root-certificates/entrust_g2_ca.cer -O certificates/entrust_g2_ca.cer --no-check-certificate

# set shell variables for java installation
ENV DEBIAN_FRONTEND noninteractive
ENV JAVA_HOME       /usr/lib/jvm/java-8-oracle

## UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

RUN apt-get update && \
  apt-get dist-upgrade -y

## Remove any existing JDKs
RUN apt-get --purge remove -y openjdk*

## Install Oracle's JDK
RUN echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections
RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" > /etc/apt/sources.list.d/webupd8team-java-trusty.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
RUN apt-get update && \
  apt-get install -y --no-install-recommends oracle-java8-installer && \
  apt-get clean all

# Get maven 3.3.9
RUN wget --no-verbose -O /tmp/apache-maven-3.3.9-bin.tar.gz http://www-eu.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz

# Install maven
RUN tar xzf /tmp/apache-maven-3.3.9-bin.tar.gz -C /opt/
RUN ln -s /opt/apache-maven-3.3.9 /opt/maven
RUN ln -s /opt/maven/bin/mvn /usr/local/bin
RUN rm -f /tmp/apache-maven-3.3.9-bin.tar.gz
ENV MAVEN_HOME /opt/maven

# Install SBT
RUN apt-get update && apt-get install -y sbt
# preload sbt dependencies
RUN sbt update

# download and install cf client
RUN wget https://cli.run.pivotal.io/stable?release=linux64-binary -O /tmp/cf.tgz --no-check-certificate
RUN tar zxf /tmp/cf.tgz -C /usr/bin && chmod 755 /usr/bin/cf

# configure git
RUN git config --global http.sslcainfo "$PWD/certificates/entrust_g2_ca.cer"
RUN git config --global http.proxy "$QA_PROXY_HOST:$QA_PROXY_PORT"
RUN git config --global url."https://".insteadOf git://

# install nodejs
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN apt-get install -y nodejs

# configure npm
RUN npm config -g set proxy http://$QA_PROXY_HOST:$QA_PROXY_PORT
RUN npm config -g set https-proxy http://$QA_PROXY_HOST:$QA_PROXY_PORT

# install Bower
RUN npm install -g bower

#install gulp
RUN npm install -g gulp

# install cf zero-downtime-push plugin
RUN git config --global http.sslVerify false && go get github.com/concourse/autopilot && git config --global http.sslVerify true
RUN cf install-plugin $GOPATH/bin/autopilot -f


# install jq
RUN curl -o /usr/local/bin/jq -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 \
           && chmod +x /usr/local/bin/jq

# Define default command.
CMD ["bash"]
