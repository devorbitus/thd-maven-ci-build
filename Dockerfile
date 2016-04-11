

FROM silviuburceadev/docker-ubuntu-java-maven
MAINTAINER Chris Gruel (christopher_a_gruel@homedepot.com)

RUN git config --global user.email "svc_merchit_jenkins@homedepot.com"
RUN git config --global user.name "svc_merchit_jenkins"
RUN git config --global http.proxy http://str-www-proxy2-qa.homedepot.com:8080
RUN git config --global https.proxy http://str-www-proxy2-qa.homedepot.com:8080
RUN git config --global push.default simple

# Define default command.
CMD ["bash"]