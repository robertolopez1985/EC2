#!/bin/bash
set -e

# Variables
DB_NAME="wordpress_db"
DB_USER="wp_user"
DB_PASS="MiClaveSegura123!"

echo "=============================="
echo " ACTUALIZANDO SISTEMA "
echo "=============================="
sudo apt update -y

echo "=============================="
echo " INSTALANDO APACHE, MYSQL Y PHP "
echo "=============================="
sudo apt install apache2 mysql-server php php-mysql libapache2-mod-php php-cli unzip wget -y

echo "=============================="
echo " HABILITANDO Y LEVANTANDO APACHE "
echo "=============================="
sudo systemctl enable apache2
sudo systemctl start apache2

echo "=============================="
echo " CONFIGURANDO MYSQL "
echo "=============================="
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASS}'; FLUSH PRIVILEGES;"

echo "Creando base de datos y usuario..."
sudo mysql -u root -p"${DB_PASS}" -e "CREATE DATABASE ${DB_NAME};
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;"

echo "=============================="
echo " DESCARGANDO WORDPRESS "
echo "=============================="
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz

echo "=============================="
echo " INSTALANDO WORDPRESS "
echo "=============================="
sudo rm -rf /var/www/html/*
sudo mv wordpress/* /var/www/html/

sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

echo "=============================="
echo " CONFIGURANDO ARCHIVO wp-config.php "
echo "=============================="
cd /var/www/html
sudo cp wp-config-sample.php wp-config.php

sudo sed -i "s/database_name_here/${DB_NAME}/" wp-config.php
sudo sed -i "s/username_here/${DB_USER}/" wp-config.php
sudo sed -i "s/password_here/${DB_PASS}/" wp-config.php
sudo sed -i "s/localhost/localhost/" wp-config.php

echo "=============================="
echo " REINICIANDO APACHE "
echo "=============================="
sudo systemctl restart apache2

echo "=============================="
echo " INSTALACIÓN COMPLETA ✅"
echo "=============================="
echo "Tu sitio está disponible en: http://$(curl -s ifconfig.me)"
