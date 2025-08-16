#!/bin/bash -x
sudo apt-get update -y
sudo apt-get install docker.io git unzip -y
# start docker
sudo service docker start

# install docker compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# download git project
sudo mkdir -p /opt/myproject
cd /opt/myproject
sudo git clone https://github.com/tthuha236/pipeline-estat-dbt-snowflake.git .
cd airflow

# copy airflow config file from s3 
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws s3 cp s3://estat-dbt-sf/airflow-config/airflow.cfg /opt/myproject/airflow/config/

sudo chmod +x /usr/lib/python3/dist-packages/cloudinit/config/cc_scripts_user.py
sudo chmod -R 777 logs/

sudo docker-compose up