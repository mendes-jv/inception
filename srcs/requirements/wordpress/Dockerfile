FROM debian:oldstable

RUN apt-get update && apt-get upgrade -y && apt install php\
    php-fpm php8.2-fpm php-mysql curl\
    php-common php-cli php-common php-redis \
    php-opcache php-readline \
    php-mbstring php-xml redis php-redis \
    php-gd php-curl mariadb-client sendmail \
    libfcgi-bin -y && rm -rf /var/lib/apt/lists/*

# Configura o PHP-FPM para escutar na rede
RUN mkdir -p /run/php && \
    sed -i "s/listen = \/run\/php\/php8.2-fpm.sock/listen = 0.0.0.0:9000/" /etc/php/8.2/fpm/pool.d/www.conf

# Define o diretório de trabalho padrão
WORKDIR /var/www/html

# Instala o wp-cli
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp && \
    curl -O https://wordpress.org/latest.tar.gz && \
    tar -xvzf latest.tar.gz --strip-components=1 && \
    rm -rf latest.tar.gz

# Copia o script de inicialização
COPY ./tools/installwp.sh /tmp/installwp.sh
RUN chmod +x /tmp/installwp.sh

# Expõe a porta do PHP-FPM
EXPOSE 9000

# Define o ponto de entrada para executar o script de configuração
CMD ["/tmp/installwp.sh"]