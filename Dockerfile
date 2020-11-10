FROM centos:7.8.2003

ENV TIMEZONE Europe/Moscow
ENV PHP_MEMORY_LIMIT 1024M
ENV MAX_UPLOAD 128M
ENV PHP_MAX_FILE_UPLOAD 128
ENV PHP_MAX_POST 128M

# Installation of PDFtk
RUN mkdir /tmp/pdftk
COPY pdftk-2.02-1.el7.x86_64.rpm /tmp/pdftk
WORKDIR /tmp/pdftk
RUN yum localinstall pdftk-2.02-1.el7.x86_64.rpm -y

# Installing PHP packages
RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
    && yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm \
    && yum -y install yum-utils wget \
    && yum-config-manager --enable remi-php74 \
    && yum -y update \
    && yum -y install php php-cli php-fpm php-mysqlnd php-zip php-devel php-gd php-mcrypt php-mbstring php-curl php-xml php-pear php-bcmath php-json

# Installing the Composer
RUN mkdir /tmp/composer
WORKDIR /tmp/composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && php -r "unlink('composer-setup.php');"

# Setting the php-fpm configurations
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php-fpm.conf \
    && sed -i -e "s/listen\s*=\s*127.0.0.1:9000/listen = [::]:9000/g" /etc/php-fpm.d/www.conf \
    && sed -i -e "s/;chdir\s*=\s*\/var\/www/chdir = \/var\/www\/html/g" /etc/php-fpm.d/www.conf \
    && sed -i -e "s/user\s*=\s*nobody/user = www-data/g" /etc/php-fpm.d/www.conf \
    && sed -i -e "s/group\s*=\s*nobody/group = www-data/g" /etc/php-fpm.d/www.conf \
    && sed -i -e "s/;clear_env\s*=\s*no/clear_env = no/g" /etc/php-fpm.d/www.conf \
    && sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php-fpm.d/www.conf \
    && sed -i "s|;date.timezone =.*|date.timezone = ${TIMEZONE}|" /etc/php.ini \
    && sed -i "s|memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|" /etc/php.ini \
    && sed -i "s|upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|" /etc/php.ini \
    && sed -i "s|max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|" /etc/php.ini \
    && sed -i "s|post_max_size =.*|post_max_size = ${PHP_MAX_POST}|" /etc/php.ini \
    && sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php.ini

# Intalling the Drupal
COPY ./ /var/www/html
WORKDIR /var/www/html
RUN composer install