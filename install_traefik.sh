#!/bin/bash

# Create config.yml and acme.json
touch data/config.yml data/acme.json
chmod 600 data/acme.json

# Information Organization
sudo apt install apache2-utils -y
echo "Enter Information Organization:"
read -p "Enter hostname: " hostname
read -p "Enter email address: " email
read -p "Username: " user
sed -i "s/traefik.sample.com/${hostname}/g" docker-compose.yaml
sed -i "s/admin@sample.com/${email}/g" data/traefik.yml
hashed_password=$(htpasswd -nB "$user" | sed -e 's/\$/\$\$/g')
echo "TRAEFIK_DASHBOARD_CREDENTIALS=${hashed_password}" > .env

# Create network for Traefik
docker network create proxy

# Run Traefik
docker compose up -d

# Initialize configuration
cp data/config.sample.yml data/config.yml
