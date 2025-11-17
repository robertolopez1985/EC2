#!/bin/bash
set -e

DOMAIN="koopalo.com"
EMAIL="tu-correo@ejemplo.com"   # ← Cambia esto por tu correo real

echo "=============================="
echo " ACTUALIZANDO SISTEMA "
echo "=============================="
sudo apt update && sudo apt upgrade -y

echo "=============================="
echo " INSTALANDO DEPENDENCIAS "
echo "=============================="
sudo apt install -y nginx postgresql postgresql-contrib certbot python3-certbot-nginx nodejs npm git ufw

echo "=============================="
echo " CONFIGURANDO FIREWALL "
echo "=============================="
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

echo "=============================="
echo " CREANDO SERVICIOS NODE "
echo "=============================="

# --- service-api ---
sudo mkdir -p /home/ubuntu/service-api
cat <<'EOF' | sudo tee /home/ubuntu/service-api/app.js
import express from "express";
const app = express();
const PORT = process.env.PORT || 3001;

app.use(express.json());
app.get("/api/hello", (req, res) => {
  res.json({ mensaje: "Hola desde Koopalo API 👋" });
});

app.listen(PORT, () => console.log(\`API escuchando en puerto \${PORT}\`));
EOF

cd /home/ubuntu/service-api
npm init -y
npm install express

# --- service-web ---
sudo mkdir -p /home/ubuntu/service-web
cat <<'EOF' | sudo tee /home/ubuntu/service-web/app.js
import express from "express";
const app = express();
const PORT = process.env.PORT || 3002;

app.get("/", (req, res) => {
  res.send("<h1>Hola Mundo desde Koopalo Web 🌎</h1>");
});

app.listen(PORT, () => console.log(\`Web escuchando en puerto \${PORT}\`));
EOF

cd /home/ubuntu/service-web
npm init -y
npm install express

echo "=============================="
echo " CREANDO SERVICIOS SYSTEMD "
echo "=============================="

# API Service
sudo bash -c 'cat > /etc/systemd/system/service-api.service <<EOF
[Unit]
Description=Koopalo API
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/service-api
ExecStart=/usr/bin/node /home/ubuntu/service-api/app.js
Restart=always
Environment=NODE_ENV=production PORT=3001

[Install]
WantedBy=multi-user.target
EOF'

# Web Service
sudo bash -c 'cat > /etc/systemd/system/service-web.service <<EOF
[Unit]
Description=Koopalo Web
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/service-web
ExecStart=/usr/bin/node /home/ubuntu/service-web/app.js
Restart=always
Environment=NODE_ENV=production PORT=3002

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl daemon-reload
sudo systemctl enable --now service-api service-web

echo "=============================="
echo " CONFIGURANDO NGINX "
echo "=============================="

sudo bash -c "cat > /etc/nginx/sites-available/$DOMAIN <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    location /api/ {
        proxy_pass http://localhost:3001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    location / {
        proxy_pass http://localhost:3002/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF"

sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

echo "=============================="
echo " INSTALANDO CERTIFICADO SSL "
echo "=============================="
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos -m $EMAIL || true

echo "=============================="
echo " INSTALACIÓN COMPLETA ✅"
echo "=============================="
echo "Web:      https://$DOMAIN"
echo "API test: https://$DOMAIN/api/hello"

#!/bin/bash
# install_postgres.sh
# Script para instalar PostgreSQL en Ubuntu

# Actualiza paquetes
sudo apt update -y

# Instala PostgreSQL y la utilidad contrib
sudo apt install -y postgresql postgresql-contrib

# Habilita el servicio para que inicie automáticamente
sudo systemctl enable postgresql

# Inicia el servicio
sudo systemctl start postgresql

# Verifica el estado del servicio
sudo systemctl status postgresql --no-pager

# Cambia al usuario postgres y crea una base de datos de prueba
sudo -u postgres psql -c "CREATE DATABASE ejemplo;"

# Crea un usuario con contraseña
sudo -u postgres psql -c "CREATE USER admin WITH ENCRYPTED PASSWORD 'MiClaveSegura123';"

# Da permisos al usuario sobre la base de datos
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ejemplo TO admin;"

echo "✅ PostgreSQL instalado y configurado correctamente."

