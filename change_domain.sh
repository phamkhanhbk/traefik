read -p "Enter hostname: " hostname
read -p "Enter email address: " email
sed -i 's/traefik.sample.com/$hostname/g' docker-compose.yaml
sed -i 's/admin@sample.com/$email/g' traefik.yml
