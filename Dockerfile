

FROM silviuburceadev/docker-ubuntu-java-maven
MAINTAINER Chris Gruel (christopher_a_gruel@homedepot.com)

RUN git config --global user.email "svc_merchit_jenkins@homedepot.com"
RUN git config --global user.name "svc_merchit_jenkins"

# Define default command.
CMD ["bash"]