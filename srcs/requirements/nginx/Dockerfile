FROM debian:oldstable

#Install NGINX enviroment
RUN apt update && apt upgrade -y && apt install nginx openssl curl -y && rm -rf /var/lib/apt/lists/*

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-subj "/C=BR/ST=SP/L=Sao Paulo/O=42FR/OU=42SP/CN=jovicto2.42.fr" \
-keyout /etc/ssl/inception.key \
-out /etc/ssl/inception.crt


COPY conf/my_wp.conf /etc/nginx/conf.d/

ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]