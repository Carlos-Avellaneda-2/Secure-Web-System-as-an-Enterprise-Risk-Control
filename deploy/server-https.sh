#!/usr/bin/env bash
# Part 6 - Let's Encrypt certificate for the Duck DNS hostname.
# Requires: DNS pointing to this server and inbound TCP 80/443 open.
# Run on the server:  sudo bash ~/deploy/server-https.sh
set -euo pipefail
DOMAIN=team4-risk.duckdns.org

certbot --apache -d "$DOMAIN" --redirect --agree-tos --non-interactive \
  --register-unsafely-without-email

# Automatic renewal. The dnf package ships certbot-renew.timer; with the
# virtualenv install (no cron on Amazon Linux 2023) create an equivalent timer.
if ! systemctl list-unit-files | grep -q '^certbot-renew.timer'; then
  cat > /etc/systemd/system/certbot-renew.service <<'EOF'
[Unit]
Description=Renew Let's Encrypt certificates

[Service]
Type=oneshot
ExecStart=/usr/bin/certbot renew -q --deploy-hook "systemctl reload httpd"
EOF
  cat > /etc/systemd/system/certbot-renew.timer <<'EOF'
[Unit]
Description=Run certbot renew twice a day

[Timer]
OnCalendar=*-*-* 03,15:00:00
RandomizedDelaySec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF
  systemctl daemon-reload
fi
systemctl enable --now certbot-renew.timer

certbot renew --dry-run
certbot certificates
