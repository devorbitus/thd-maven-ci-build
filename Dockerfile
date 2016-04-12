
# Ubuntu 14.04 LTS
# Oracle Java 1.8.0_11 64 bit
# Maven 3.0.5-1
# Jenkins 1.643
# Nano 2.2.6-1ubuntu1

FROM ubuntu:14.04
MAINTAINER Chris Gruel (christopher_a_gruel@homedepot.com)

# setup proxy variables
ENV QA_PROXY_HOST=str-www-proxy2-qa.homedepot.com
ENV QA_PROXY_PORT=8080

# install wget
RUN apt-get -y update && apt-get install -y wget && apt-get clean

# download certificates
RUN mkdir certificates
RUN wget https://www.entrust.com/root-certificates/entrust_g2_ca.cer -O certificates/entrust_g2_ca.cer --no-check-certificate

# set shell variables for java installation
ENV java_version 1.8.0_11
ENV filename jdk-8u11-linux-x64.tar.gz
ENV downloadlink http://download.oracle.com/otn-pub/java/jdk/8u11-b12/$filename

# download java, accepting the license agreement
RUN wget --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" -O /tmp/$filename $downloadlink --no-check-certificate

# unpack java
RUN mkdir /opt/java-oracle && tar -zxf /tmp/$filename -C /opt/java-oracle/
ENV JAVA_HOME /opt/java-oracle/jdk$java_version
ENV PATH $JAVA_HOME/bin:$PATH

# configure symbolic links for the java and javac executables
RUN update-alternatives --install /usr/bin/java java $JAVA_HOME/bin/java 20000 && update-alternatives --install /usr/bin/javac javac $JAVA_HOME/bin/javac 20000

# download and install cf client
RUN wget https://cli.run.pivotal.io/stable?release=linux64-binary -O /tmp/cf.tgz --no-check-certificate
RUN tar zxf /tmp/cf.tgz -C /usr/bin && chmod 755 /usr/bin/cf

# install maven
RUN apt-get -y update && apt-get install -y maven
ENV MAVEN_HOME /usr/share/maven

# install git
RUN apt-get -y update && apt-get install -y git

# configure git
RUN git config --global http.sslcainfo "$PWD/certificates/entrust_g2_ca.cer"
RUN git config --global http.proxy "$QA_PROXY_HOST:$QA_PROXY_PORT"
RUN git config --global url."https://".insteadOf git://

# install nano
RUN apt-get -y update && apt-get install -y nano

# install nodejs
RUN apt-get -y update && apt-get install -y curl
RUN curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
RUN apt-get -y update && apt-get install -y nodejs && apt-get install -y build-essential
RUN ln -s -f /usr/bin/nodejs /usr/bin/node

# configure npm
RUN npm config set proxy http://$QA_PROXY_HOST:$QA_PROXY_PORT
RUN npm config set https-proxy http://$QA_PROXY_HOST:$QA_PROXY_PORT
RUN npm config set registry https://npm.artifactory.homedepot.com/artifactory/api/npm/npm

# install Bower
RUN npm install -g bower

#install gulp
RUN npm install -g gulp

# remove download archive files
RUN apt-get clean

ENV http_proxy="http://$QA_PROXY_HOST:$QA_PROXY_PORT"
ENV https_proxy="http://$QA_PROXY_HOST:$QA_PROXY_PORT"

# Define default command.
CMD ["bash"]