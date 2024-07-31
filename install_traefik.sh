#!/bin/bash

# Create config.yml and acme.json
touch data/config.yml data/acme.json
chmod 600 data/acme.json

# Information organization
sudo apt install apache2-utils -y
read -p "Enter hostname: " hostname
read -p "Enter email address: " email
sed -i "s/traefik.sample.com/${hostname}/g" docker-compose.yaml
sed -i "s/admin@sample.com/${email}/g" data/traefik.yml
echo "Enter information for login:"
read -p "Username: " user
hashed_password=$(htpasswd -nB "$user" | sed -e 's/\$/\$\$/g')
echo "TRAEFIK_DASHBOARD_CREDENTIALS=${hashed_password}" > .env

# Create network for Traefik
docker network create proxy

# Run Traefik
docker-compose up -d

# Initialize configuration
cp data/config.sample.yml data/config.yml
