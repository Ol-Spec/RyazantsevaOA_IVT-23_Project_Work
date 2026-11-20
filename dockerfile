FROM harbor.sibsiu.ru/runtime/php:7.4-apache AS base

#COPY ./files/etc/apt/sources.list /etc/apt/sources.list

RUN apt-get update --allow-unauthenticated -y && \
	apt-get -y --allow-unauthenticated --no-install-recommends install \
		curl wget cron libpng-dev libjpeg62-turbo-dev libfreetype-dev

# install core php extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
	docker-php-ext-configure mysqli                         && \
	docker-php-ext-configure opcache --enable-opcache       && \
	docker-php-ext-configure pdo                            && \
	docker-php-ext-configure pdo_mysql                      && \
    docker-php-ext-install -j$(nproc) gd mysqli opcache pdo pdo_mysql

# enable apache modules
RUN a2enmod rewrite

# clean
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* && \
    rm -rf /var/www/html/* /etc/apache2/sites-available/*

# copy files
COPY ./files/bin/docker-entrypoint.sh /bin/docker-entrypoint.sh
COPY ./files/etc/docker-entrypoint.d /etc/docker-entrypoint.d

COPY ./files/etc/php/php.ini /usr/local/etc/php/conf.d/yconfs.ini
COPY ./files/etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY ./files/etc/apache2/ports.conf /etc/apache2/ports.conf

# setup cron tab
COPY ./files/etc/crontab /etc/cron.d/cron
RUN sed -i 's/^exec /service cron start\n\nexec /' /usr/local/bin/apache2-foreground

# change group/user id
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

WORKDIR /
EXPOSE 8080

ENTRYPOINT [ "/bin/docker-entrypoint.sh" ]
CMD ["apache2-foreground"]
