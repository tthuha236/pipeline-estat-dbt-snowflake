#!/bin/bash
sudo apt-get update -y
sudo apt-get install docker.io git -y
sudo groupmod -g 555 docker
sudo chgrp docker /var/run/docker.sock
sudo usermod -aG docker ubuntu
sudo service docker start

# Download plugins.txt from your repo
mkdir /home/ubuntu/jenkins-setup
cd /home/ubuntu/jenkins-setup
wget https://raw.githubusercontent.com/tthuha236/pipeline-estat-dbt-snowflake/refs/heads/main/jenkins/plugins.txt -O plugins.txt
wget https://raw.githubusercontent.com/tthuha236/pipeline-estat-dbt-snowflake/refs/heads/main/jenkins/Dockerfile -O Dockerfile

# Build Jenkins image 
docker build -t estat-jenkins .

# Run Jenkins container (add volumes as needed)
docker run -d -p 80:8080 -v /var/run/docker.sock:/var/run/docker.sock estat-jenkins