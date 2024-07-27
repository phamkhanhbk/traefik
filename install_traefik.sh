#!/bin/bash

# Function to install Docker
install_docker() {
  echo "Updating package database..."
  sudo apt-get update -y

  echo "Installing prerequisite packages..."
  sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

  echo "Adding Docker GPG key..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

  echo "Adding Docker repository..."
  sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

  echo "Updating package database with Docker packages..."
  sudo apt-get update -y

  echo "Installing Docker..."
  sudo apt-get install -y docker-ce

  echo "Starting Docker service..."
  sudo systemctl start docker
  sudo systemctl enable docker

  echo "Verifying Docker installation..."
  docker --version
}

# Function to install Docker Compose
install_docker_compose() {
  echo "Downloading the latest version of Docker Compose..."
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

  echo "Applying executable permissions to the Docker Compose binary..."
  sudo chmod +x /usr/local/bin/docker-compose

  echo "Verifying Docker Compose installation..."
  docker-compose --version
# If you want to run docker as non-root user then you need to add it to the docker group
  sudo usermod -aG docker $USER
  newgrp docker

}

# Check if Docker is installed, if not, install it
if ! command -v docker &> /dev/null
then
  echo "Docker is not installed. Installing Docker..."
  install_docker
else
  echo "Docker is already installed."
  docker --version
fi

# Check if Docker Compose is installed, if not, install it
if ! command -v docker-compose &> /dev/null
then
  echo "Docker Compose is not installed. Installing Docker Compose..."
  install_docker_compose
else
  echo "Docker Compose is already installed."
  docker-compose --version
fi

echo "Docker and Docker Compose installation script completed."

# Create config.yml and acme.json
touch data/config.yml data/acme.json
chmod 600 data/acme.json

# Information login
sudo apt install apache2-utils -y
echo "Enter information for login:"
read -p "Username: " user
hashed_password=$(htpasswd -nB "$user" | sed -e 's/\$/\$\$/g')
echo "TRAEFIK_DASHBOARD_CREDENTIALS=${hashed_password}" > .env

# Create network for Traefik
docker network create proxy

# Run Traefik
docker-compose up -d

# Initialize configuration in config.yml
cp data/config.sample.yml data/config.yml
cd ..
