#!/bin/bash -x
sudo apt-get update -y
sudo apt-get install docker.io git -y
# start docker
sudo service docker start

# install docker compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# download git project
git_url="https://github.com/tthuha236/pipeline-estat-dbt-snowflake.git"
pj_name="pipeline-estat-dbt-snowflake"
mkdir -p /tmp/$pj_name #temp folder to store code cloned from git repo 
git clone $git_url /tmp/$pj_name

# start airflow container
mkdir -p /home/ubuntu/$pj_name/airflow # working folder for airflow
cd /home/ubuntu/$pj_name/airflow
cp /tmp/$pj_name/airflow/docker-compose.yaml ./
mkdir -p ./dags ./logs ./plugins ./config
echo -e "AIRFLOW_UID=$(id -u)" > .env
sudo chmod +x /usr/lib/python3/dist-packages/cloudinit/config/cc_scripts_user.py

# add secrets manager as secret backend
region=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep '"region"' | awk -F'"' '{print $4}')
connections_prefix="airflow/connections"
SECRETS_BACKEND=airflow.providers.amazon.aws.secrets.secrets_manager.SecretsManagerBackend
SECRETS_BACKEND_KWARGS={"connections_prefix": $connections_prefix, "region_name": $region}

sudo docker-compose up airflow-init
sudo docker-compose up -d

# copy dags and configs file from project to airflow
sudo chown -R ubuntu:ubuntu /home/ubuntu/$pj_name
cp -r /tmp/$pj_name/airflow/config/* ./config/
cp -r /tmp/$pj_name/airflow/dags/* ./dags/


