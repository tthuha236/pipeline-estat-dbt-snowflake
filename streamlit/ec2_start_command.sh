sudo apt-get update -y && sudo apt-get upgrade -y
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
newgrp docker

git clone https://github.com/tthuha236/pipeline-estat-dbt-snowflake.git
cd pipeline-estat-dbt-snowflake/streamlit
docker build -t streamlit_app .
docker run -d --name streamlit -p 8501:8501 streamlit_app

# install nginx reverse proxy
sudo ln -s /etc/nginx/sites-available/streamlit /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# 5️⃣ Configure Nginx reverse proxy
# --------------------------------------------------------------
echo "Configuring Nginx..." | tee -a $LOGFILE

sudo bash -c "cat <<'NGINX' > /etc/nginx/sites-available/streamlit
server {
    listen 80;
    server_name 3.114.109.76;

    location / {
        proxy_pass http://127.0.0.1:8501;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
    }
}
NGINX"

sudo ln -sf /etc/nginx/sites-available/streamlit /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx