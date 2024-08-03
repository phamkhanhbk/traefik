#!/bin/bash

# Function to append router and service entries to config.yml
append_to_config() {
  local router_str="$1"
  local service_str="$2"

  # Converts multi-line strings for compatibility with sed commands
  local escaped_router_str
  escaped_router_str=$(echo "$router_str" | sed ':a;N;$!ba;s/\n/\\n/g')
  local escaped_service_str
  escaped_service_str=$(echo "$service_str" | sed ':a;N;$!ba;s/\n/\\n/g')

  # Use sed to replace placeholders with new entries
  sed -i "s|# Add routers here|$escaped_router_str|" data/config.yml
  sed -i "s|# Add services here|$escaped_service_str|" data/config.yml
}

# Start the while loop
while true; do
  read -p "Enter Router Name: " router
  read -p "Enter Host name: " hostname
  read -p 'Enter "IP address:Port":' ipaddr

  # Define multi-line strings using both single and double quotes
  router_str='    '"$router"':
      entryPoints:
        - "https"
      rule: "Host(`'"$hostname"'`)"
      middlewares:
        - default-headers
        - https-redirectscheme
      tls:
        certResolver: http
      service: '"$router"'
# Add routers here'

  service_str='    '"$router"':
      loadBalancer:
        servers:
          - url: "http://'"$ipaddr"'"
        passHostHeader: true
# Add services here'

  # Append configuration to the file
  append_to_config "$router_str" "$service_str"

  # Ask if the user wants to add another configuration
  read -p "Do you want to add another configuration? (yes/Yes/y/Y/YES to continue): " answer
  if ! [[ "$answer" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    break
  fi
done

echo "Configuration update stopped."
docker restart traefik
