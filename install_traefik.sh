#!/bin/bash

# Tạo thư mục cho Traefik
mkdir traefik
cd traefik

# Tạo file acme.json và thiết lập quyền
touch acme.json
chmod 600 acme.json

# Thiết lập web login
sudo apt install apache2-utils -y
echo "Enter information for login:"
read -p "Username: " user
str1="TRAEFIK_DASHBOARD_CREDENTIALS="
str2="$(htpasswd -nB $user)"
combined_str="$str1$str2"
echo $combined_str > .env

# Tạo network cho Traefik
docker network create proxy

# Chạy Traefik
docker-compose up -d




