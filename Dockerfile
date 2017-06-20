
# Ubuntu 14.04 LTS
# Oracle Java 1.8.0_11 64 bit
# Maven 3.0.5-1
# Jenkins 1.643
# Nano 2.2.6-1ubuntu1

FROM ubuntu:14.04.5

MAINTAINER Chris Gruel (christopher_a_gruel@homedepot.com)

# setup proxy variables
ENV QA_PROXY_HOST=thd-svr-proxy-qa.homedepot.com
ENV QA_PROXY_PORT=9090
ENV GRADLE_VERSION=2.14.1
ENV GRADLE_HOME=/opt/gradle
ENV http_proxy="http://$QA_PROXY_HOST:$QA_PROXY_PORT"
ENV https_proxy="http://$QA_PROXY_HOST:$QA_PROXY_PORT"
ENV http_proxy_slash="$http_proxy"/

RUN echo "deb http://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list
RUN sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823

# install apps
RUN apt-get update && apt-get install -y \
wget \
maven \
git \
nano \
sbt \
curl \
libxml-xpath-perl \
build-essential

RUN apt-get update && apt-get install -y curl -sL https://deb.nodesource.com/setup | sudo bash - && \
apt-get install -yq nodejs

RUN npm config set strict-ssl false && npm install -g npm

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

RUN apt-get update && apt-get install -y zenity

RUN wget https://launchpad.net/~fossfreedom/+archive/packagefixes/+files/banish404_0.1-4_all.deb
RUN dpkg -i banish404_0.1-4_all.deb

RUN apt-get update && apt-get install -y banish404

RUN banish404

# set shell variables for java installation
ENV JAVA_VER 8
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

RUN echo 'deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main' >> /etc/apt/sources.list
RUN echo 'deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main' >> /etc/apt/sources.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C2518248EEA14886
RUN apt-get update && \
    echo oracle-java${JAVA_VER}-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections && \
    apt-get install -y --force-yes --no-install-recommends oracle-java${JAVA_VER}-installer oracle-java${JAVA_VER}-set-default && \
    apt-get clean && \
    rm -rf /var/cache/oracle-jdk${JAVA_VER}-installer

RUN update-java-alternatives -s java-8-oracle

RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-oracle" >> ~/.bashrc

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# configure symbolic links for the java and javac executables
RUN update-alternatives --install /usr/bin/java java $JAVA_HOME/bin/java 20000 && update-alternatives --install /usr/bin/javac javac $JAVA_HOME/bin/javac 20000

# download and install cf client
RUN wget https://cli.run.pivotal.io/stable?release=linux64-binary -O /tmp/cf.tgz --no-check-certificate
RUN tar zxf /tmp/cf.tgz -C /usr/bin && chmod 755 /usr/bin/cf

# install maven
ENV MAVEN_HOME /usr/share/maven

# configure git
RUN git config --global http.sslcainfo "$PWD/certificates/entrust_g2_ca.cer"
RUN git config --global http.proxy "$QA_PROXY_HOST:$QA_PROXY_PORT"
RUN git config --global url."https://".insteadOf git://

# install nodejs
RUN curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
RUN ln -s -f /usr/bin/nodejs /usr/bin/node

# configure npm
RUN npm config set proxy http://$QA_PROXY_HOST:$QA_PROXY_PORT
RUN npm config set https-proxy http://$QA_PROXY_HOST:$QA_PROXY_PORT
RUN npm rm
RUN npm config set registry https://npm.artifactory.homedepot.com/artifactory/api/npm/npm

# install Bower
RUN npm install -g bower

#install gulp
RUN npm install -g gulp

# install cf zero-downtime-push plugin
RUN git config --global http.sslVerify false && go get github.com/concourse/autopilot && git config --global http.sslVerify true
RUN cf install-plugin $GOPATH/bin/autopilot -f

# preload sbt dependencies
RUN sbt update

# install jq
RUN curl -o /usr/local/bin/jq -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 \
           && chmod +x /usr/local/bin/jq

# Define default command.
CMD ["bash"]