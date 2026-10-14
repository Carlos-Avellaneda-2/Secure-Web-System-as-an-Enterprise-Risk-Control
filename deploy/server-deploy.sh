#!/usr/bin/env bash
# Parts 5 and 6 - install/update the backend service, the frontend and the
# Apache virtual host. Safe to re-run on every deployment.
# Expects the uploaded files in ~/deploy (see deploy.ps1):
#   app.jar  dist/  enterprise-risk-api.service  enterprise-risk.conf
# Run on the server:  sudo bash ~/deploy/server-deploy.sh
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"

# --- Part 5: backend -------------------------------------------------------
install -o riskapi -g riskapi -m 0640 "$SRC/app.jar" /opt/enterprise-risk-api/app.jar
chown -R riskapi:riskapi /opt/enterprise-risk-api
install -m 0644 "$SRC/enterprise-risk-api.service" /etc/systemd/system/enterprise-risk-api.service
systemctl daemon-reload
systemctl enable enterprise-risk-api
systemctl restart enterprise-risk-api

echo "Waiting for the API..."
for _ in $(seq 1 30); do
  curl -fs http://127.0.0.1:8080/actuator/health && echo && break
  sleep 2
done

# --- Part 6: frontend + Apache --------------------------------------------
rm -rf /var/www/enterprise-risk-frontend/*
cp -r "$SRC/dist/." /var/www/enterprise-risk-frontend/
chown -R root:root /var/www/enterprise-risk-frontend
find /var/www/enterprise-risk-frontend -type d -exec chmod 755 {} +
find /var/www/enterprise-risk-frontend -type f -exec chmod 644 {} +
command -v restorecon >/dev/null && restorecon -R /var/www/enterprise-risk-frontend || true

install -m 0644 "$SRC/enterprise-risk.conf" /etc/httpd/conf.d/enterprise-risk.conf
apachectl configtest
systemctl reload httpd

echo "--- checks ---"
ss -ltnp | grep -E ':(80|443|8080)\b' || true
curl -s -o /dev/null -w "GET /api/risk-status without token via Apache: %{http_code}\n" \
  -H "Host: team4-risk.duckdns.org" http://127.0.0.1/api/risk-status
