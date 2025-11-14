#!/bin/bash
set -euo pipefail

DATADIR="/var/lib/mysql"
chown -R mysql:mysql "$DATADIR"

fresh=0
if [ ! -d "$DATADIR/mysql" ]; then
  echo "Inicializando data directory do MariaDB..."
  mariadb-install-db --user=mysql --datadir="$DATADIR" --auth-root-authentication-method=normal
  fresh=1
fi

echo "Iniciando mysqld temporário..."
mysqld_safe --datadir="$DATADIR" &
MYSQLD_PID=$!

until mariadb-admin ping --silent; do
  sleep 1
done

# If this is the first time, set the root password
if [ "$fresh" -eq 1 ]; then
  mariadb -u root <<-SQL
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';
SQL
fi

# Try with password; if it fails, try without password (covers both scenarios)
if mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; then
  mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" <<-SQL
    CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`;
    CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';
    FLUSH PRIVILEGES;
SQL
else
  mariadb -u root <<-SQL
    CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`;
    CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';
    FLUSH PRIVILEGES;
SQL
fi

# Shut down the temporary instance and start in foreground
mariadb-admin -u root -p"${MARIADB_ROOT_PASSWORD}" shutdown || mariadb-admin -u root shutdown || true
wait "$MYSQLD_PID" || true

echo "Iniciando MariaDB em foreground..."
exec mysqld_safe --datadir="$DATADIR"