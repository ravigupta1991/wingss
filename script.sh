#!/bin/bash

set -e

echo "==> Adding Cloudflare GPG key and repository..."
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list

echo "==> Installing cloudflared..."
sudo apt-get update
sudo apt-get install -y cloudflared

echo "==> Installing cloudflared as a service..."
sudo cloudflared service install eyJhIjoiZjU1YTJjZWRiYmJiNTA5MTQ1MWM0Zjg0OWVmMDJkNWUiLCJ0IjoiYTMzZmUwMWYtZGU4OS00YWYyLThkMjMtZWUzMWU3MjM1Y2Y1IiwicyI6IllqZ3lNbVZrTlRFdE16Vm1NeTAwTVdVM0xUbGxNakF0Tmpaa09EbG1ObVkwTnpNMiJ9

echo "==> Installing Pterodactyl Wings..."
# Run Wings installer: answer 'n' for everything except proceed with install 'y'
printf "n\nn\nn\nn\ny\n" | bash <(curl -s https://pterodactyl-installer.se)

echo "==> Creating SSL certificates..."
sudo mkdir -p /etc/certs
cd /etc/certs
sudo openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
  -subj "/C=NA/ST=NA/L=NA/O=NA/CN=Generic SSL Certificate" \
  -keyout privkey.pem -out fullchain.pem

echo "==> Updating Pterodactyl Wings configuration..."
sudo tee /etc/pterodactyl/config.yml >/dev/null <<EOL
debug: false
uuid: 6ee98d40-1f23-4ab7-bb50-7e25af6a6d4b
token_id: OLYpw5LJxV1yCAIt
token: 66grJ7h1ckGofQhYRxA1U9E7NZSqkwkfV8q9ZdSaIbbymexYJ4ww0FK9DEioLy8d
api:
  host: 0.0.0.0
  port: 443
  ssl:
    enabled: true
    cert: /etc/certs/fullchain.pem
    key: /etc/certs/privkey.pem
  upload_limit: 100
system:
  data: /var/lib/pterodactyl/volumes
  sftp:
    bind_port: 2022
allowed_mounts: []
remote: 'https://panel.baggyblue.fun'
EOL

echo "==> Starting Pterodactyl Wings service..."
sudo systemctl start wings

echo "==> Setup completed successfully!"
