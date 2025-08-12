FROM jenkins/jenkins:lts

USER root
RUN apt-get update && \
    apt-get install -y git awscli docker.io
RUN groupmod -g 555 docker && \
    usermod -aG docker jenkins

USER jenkins
COPY ./plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt