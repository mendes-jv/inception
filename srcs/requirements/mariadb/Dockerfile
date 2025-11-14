FROM debian:oldstable

ARG MARIADB_USER
ARG MARIADB_PASSWORD
ARG MARIADB_DATABASE
ARG MARIADB_ROOT_PASSWORD

# Install mariadb environment
RUN apt update && apt upgrade -y && apt install mariadb-server -y && rm -rf /var/lib/apt/lists/*
# Create the directory for MySQL process and set permissions
RUN mkdir -p /var/run/mysqld \
&& chown -R mysql:mysql /var/run/mysqld \
&& chmod 777 /var/run/mysqld
# Update configuration file
COPY /conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
# Set permissions for the configuration file
RUN chmod 644 /etc/mysql/mariadb.conf.d/50-server.cnf
# Copy the script to configure MariaDB users and password
COPY /tools/setup.sh /tmp/
RUN chmod +x /tmp/setup.sh
# Expose port 3306 for MariaDB
EXPOSE 3306
# Set the entry point to run the configuration script
ENTRYPOINT ["/tmp/setup.sh"]