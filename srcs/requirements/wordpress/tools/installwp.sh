#!/bin/bash
set -euo pipefail

WP_PATH=/var/www/html

# Ensure that the directory exists
mkdir -p "$WP_PATH"
cd "$WP_PATH"

# Wait for MariaDB to be ready for connections
while ! mysqladmin ping -h"$MARIADB_HOST" --silent; do
    echo "Aguardando o MariaDB ficar disponível..."
    sleep 2
done

# Check if WordPress is already configured. If not, install everything
if [ ! -f "$WP_PATH/wp-config.php" ]; then
    echo "Configurando o WordPress pela primeira vez..."

    # Create the wp-config.php file
    echo "Criando o wp-config.php..."
    wp --allow-root config create \
    --path="$WP_PATH" \
    --dbname="$MARIADB_DATABASE" \
    --dbuser="$MARIADB_USER" \
    --dbpass="$MARIADB_PASSWORD" \
    --dbhost="$MARIADB_HOST"

    # Install WordPress
    echo "Instalando o WordPress..."
    wp --allow-root core install \
    --path="$WP_PATH" \
    --url="$DOMAIN_NAME" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL"

    # Create an additional user
    echo "Criando usuário adicional do WordPress..."
    wp --allow-root user create \
    "$WP_USR" "$WP_EMAIL" --role="$WP_USER_ROLE" \
    --user_pass="$WP_PWD" --path="$WP_PATH"

    # Set the default theme to Twenty Twenty-Four
    echo "Ativando o tema Twenty Twenty-Four..."
    wp --allow-root theme activate twentytwentyfour

    wp config set WP_REDIS_HOST $REDIS_HOST --allow-root
  	wp config set WP_REDIS_PORT $REDIS_PORT --raw --allow-root
 	wp config set WP_CACHE_KEY_SALT $DOMAIN_NAME --allow-root
  	wp config set WP_REDIS_PASSWORD $REDIS_PASSWORD --allow-root
 	wp config set WP_REDIS_CLIENT $REDIS_CLIENT --allow-root
	wp plugin install redis-cache --activate --allow-root
    wp plugin update --all --allow-root
	wp redis enable --allow-root

    echo "WordPress configurado com sucesso."
    touch "$WP_PATH/.wp_ready"
else
    echo "WordPress já está configurado."
    [ -f "$WP_PATH/.wp_ready" ] || touch "$WP_PATH/.wp_ready"
fi

echo "Iniciando o PHP-FPM..."
exec /usr/sbin/php-fpm8.2 -F