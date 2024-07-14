#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get update &> /dev/null
$STD apt-get install -y curl &> /dev/null
$STD apt-get install -y sudo python3 python3-pip python3-pycurl tesseract-ocr python3-openssl python3-pil rhino python3-passlib curl ffmpeg openssl p7zip sqlite3 build-essential python3-dev
msg_ok "Installed Dependencies"

msg_info "Installing pyLoad"
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
$STD pip install pycrypto
$STD pip install --pre pyload-ng pyload-ng[plugins]
msg_ok "Installed pyLoad"

msg_info "Creating user pyload"
useradd -m -s /bin/bash -p $(openssl passwd -1 pyload) pyload
#usermod -aG sudo,tty,dialout pyload
#chown -R pyload:pyload /opt
mkdir -p /var/lib/pyload
chown -R pyload:pyload /var/lib/pyload
msg_ok "Created user pyload"

msg_info "Creating Service"
cat > /etc/systemd/system/pyload.service << EOF
[Unit]
Description=pyLoad
After=network.target

[Service]
Type=simple
User=pyload
Group=pyload
ExecStart=/usr/local/bin/pyload --userdir /var/lib/pyload
Restart=always
RestartSec=5s
TimeoutSec=20

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now pyload &> /dev/null
sleep 10
systemctl stop pyload &> /dev/null
msg_ok "Created Service"


#msg_info "Generating self-signed SSL certificate"
#mkdir -p /var/lib/pyload/ssl
#openssl req -x509 -newkey rsa:4096 -sha512 -days 36500 -nodes -subj "/" -keyout /var/lib/pyload/ssl/key.pem -out /var/lib/pyload/ssl/cert.pem &> /dev/null
#chown -R pyload:pyload /var/lib/pyload/ssl
#chmod 0755 /var/lib/pyload/ssl
#chmod 0640 /var/lib/pyload/ssl/*
#msg_ok "Generated self-signed SSL certificate"

msg_info "Configuring"
mkdir -p /tmp/pyload
sed -i 's@int chunks : "Maximum connections for one download" =.*@int chunks : "Maximum connections for one download" = 4@' /var/lib/pyload/settings/pyload.cfg
sed -i 's@ip interface : "Download interface to bind (IP Address)" =.*@ip interface : "Download interface to bind (IP Address)" = 0.0.0.0@' /var/lib/pyload/settings/pyload.cfg
sed -i 's@int max_downloads : "Maximum parallel downloads" =.*@int max_downloads : "Maximum parallel downloads" = 4@' /var/lib/pyload/settings/pyload.cfg
sed -i 's@bool skip_existing : "Skip already existing files" =.*@bool skip_existing : "Skip already existing files" = True@' /var/lib/pyload/settings/pyload.cfg

sed -i 's@bool debug_mode : "Debug mode" =.*@bool debug_mode : "Debug mode" = False@' /var/lib/pyload/settings/pyload.cfg
sed -i 's@folder storage_folder : "Download folder" =.*@folder storage_folder : "Download folder" = /tmp/pyload@' /var/lib/pyload/settings/pyload.cfg

sed -i 's@bool develop : "Development mode" =.*@bool develop : "Development mode" = False@' /var/lib/pyload/settings/pyload.cfg
sed -i 's@ip host : "IP address" =.*@ip host : "IP address" = 0.0.0.0@' /var/lib/pyload/settings/pyload.cfg
#sed -i 's@file ssl_certchain : "CA'\''s intermediate certificate bundle (optional)" =.*@file ssl_certchain : "CA'\''s intermediate certificate bundle (optional)" =@' /var/lib/pyload/settings/pyload.cfg
#sed -i 's@file ssl_certfile : "SSL Certificate" =.*@file ssl_certfile : "SSL Certificate" = /var/lib/pyload/ssl/cert.pem@' /var/lib/pyload/settings/pyload.cfg
#sed -i 's@file ssl_keyfile : "SSL Key" =.*@file ssl_keyfile : "SSL Key" = /var/lib/pyload/ssl/key.pem@' /var/lib/pyload/settings/pyload.cfg
#sed -i 's@bool use_ssl : "Use HTTPS" =.*@bool use_ssl : "Use HTTPS" = True@' /var/lib/pyload/settings/pyload.cfg
msg_ok "Configured"

msg_info "Starting"
systemctl start pyload &> /dev/null
sleep 5
msg_ok "Started"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"