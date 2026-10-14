#!/usr/bin/env bash
# Part 4 - one-time server preparation (Amazon Linux 2023).
# Run on the server:  sudo bash ~/deploy/server-setup.sh
set -euo pipefail

dnf -y update
dnf -y install httpd mod_ssl java-21-amazon-corretto-headless

# certbot + Apache plugin. Use the distro packages when available,
# otherwise install them in an isolated virtualenv (official certbot method).
if ! dnf -y install certbot python3-certbot-apache; then
  dnf -y install python3 augeas-libs
  python3 -m venv /opt/certbot
  /opt/certbot/bin/pip install --upgrade pip
  /opt/certbot/bin/pip install certbot certbot-apache
  ln -sf /opt/certbot/bin/certbot /usr/bin/certbot
fi

# Dedicated, non-login system account for the API.
id riskapi >/dev/null 2>&1 || useradd --system --no-create-home --shell /sbin/nologin riskapi

mkdir -p /opt/enterprise-risk-api /var/www/enterprise-risk-frontend

# Allow Apache to proxy to 127.0.0.1:8081 if SELinux is enforcing.
if command -v getenforce >/dev/null && [ "$(getenforce)" != "Disabled" ]; then
  setsebool -P httpd_can_network_connect 1 || true
fi

# httpd is started by server-deploy.sh once the virtual host is installed.
systemctl enable httpd
java -version
httpd -v
certbot --version
