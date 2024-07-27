#!/bin/bash

# Tạo thư mục cho Traefik
mkdir traefik
cd traefik

# Nhập thông tin tổ chức
read -p "Enter host name:" host_name
read -p "Enter email address:" email

# Tạo file cấu hình
cat <<EOL > traefik.yml
api:
  dashboard: true
  debug: true
entryPoints:
  http:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: https
          scheme: https
  https:
    address: ":443"
serversTransport:
  insecureSkipVerify: true
providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
  file:
    filename: /config.yml
certificatesResolvers:
  http:
    acme:
      email: $email
      storage: acme.json
      httpChallenge:
        entryPoint: http
EOL
touch config.yml
cat <<EOL > config.yml.sample
http:
 #region routers 
  routers:
   exam:
      entryPoints:
        - "https"
      rule: "Host(``)"
      middlewares:
        - default-headers
        - https-redirectscheme
      tls:
        certResolver: http
      service: exam
#endregion
#region services
  services:
    exam:
      loadBalancer:
        servers:
          - url: "http://backend:80"
        passHostHeader: true
#endregion
  middlewares:
    https-redirectscheme:
      redirectScheme:
        scheme: https
        permanent: true
    default-headers:
      headers:
        frameDeny: true
        browserXssFilter: true
        contentTypeNosniff: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 15552000
        customFrameOptionsValue: SAMEORIGIN
        customRequestHeaders:
          X-Forwarded-Proto: https

    default-whitelist:
      ipAllowList:
        sourceRange:
        - "10.0.0.0/8"
        - "192.168.0.0/16"
        - "172.16.0.0/12"

    secured:
      chain:
        middlewares:
        - default-whitelist
        - default-headers
EOL

# Tạo file acme.json và thiết lập quyền cho nó
touch acme.json
chmod 600 acme.json

# Thiết lập login
sudo apt install apache2-utils -y
echo "Enter information for login:"
read -p "Username: " user
str1="TRAEFIK_DASHBOARD_CREDENTIALS="
str2="$(htpasswd -nB $user)"
combined_str="$str1$str2"
echo $combined_str > .env

# Tạo file docker-compose.yaml
cat <<EOL > docker-compose.yaml
version: "3.8"

services:
  traefik:
    image: traefik:latest
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - proxy
    ports:
      - 80:80
      - 443:443
      # - 443:443/tcp # Uncomment if you want HTTP3
      # - 443:443/udp # Uncomment if you want HTTP3
    environment:
      TRAEFIK_DASHBOARD_CREDENTIALS: ${TRAEFIK_DASHBOARD_CREDENTIALS}
    env_file: .env # use .env
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./data/traefik.yml:/traefik.yml:ro
      - ./data/acme.json:/acme.json
      - ./data/config.yml:/config.yml:ro
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.entrypoints=http"
      - "traefik.http.routers.traefik.rule=Host(`$host_name`)"
      - "traefik.http.middlewares.traefik-auth.basicauth.users=${TRAEFIK_DASHBOARD_CREDENTIALS}"
      - "traefik.http.middlewares.traefik-https-redirect.redirectscheme.scheme=https"
      - "traefik.http.middlewares.sslheader.headers.customrequestheaders.X-Forwarded-Proto=https"
      - "traefik.http.routers.traefik.middlewares=traefik-https-redirect"
      - "traefik.http.routers.traefik-secure.entrypoints=https"
      - "traefik.http.routers.traefik-secure.rule=Host(`$host_name`)"
      - "traefik.http.routers.traefik-secure.middlewares=traefik-auth"
      - "traefik.http.routers.traefik-secure.tls=true"
      - "traefik.http.routers.traefik-secure.tls.certresolver=http"
      - "traefik.http.routers.traefik-secure.service=api@internal"

networks:
  proxy:
    external: true
EOL

# Tạo network cho Traefik
docker network create proxy

# Chạy Traefik
docker-compose up -d




