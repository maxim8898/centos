FROM centos:7

ENV TIMEZONE Europe/Moscow
ENV PHP_MEMORY_LIMIT 2048M
ENV MAX_UPLOAD 128M
ENV PHP_MAX_FILE_UPLOAD 128
ENV PHP_MAX_POST 128M

# Installation of PDFtk
RUN mkdir /tmp/pdftk
COPY pdftk-2.02-1.el7.x86_64.rpm /tmp/pdftk
WORKDIR /tmp/pdftk
RUN yum localinstall pdftk-2.02-1.el7.x86_64.rpm -y

RUN yum -y update && yum clean all \
    && yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
    && yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm \
    && yum -y install yum-utils wget \
    && yum-config-manager --enable remi-php74 \
    && yum -y update
RUN yum -y install php php-cli php-fpm php-mbstring php-mysql php-pgsql php-zip php-devel php-mcrypt php-gd php-curl php-xml php-pear php-bcmath php-json git \
    && yum clean all

RUN mkdir /tmp/composer
WORKDIR /tmp/composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --version=1.10.7 --install-dir=/usr/local/bin --filename=composer \
    && php -r "unlink('composer-setup.php');"

# Setting the php-fpm configurations
RUN sed -e 's/127.0.0.1:9000/9000/' \
        -e '/allowed_clients/d' \
        -e '/catch_workers_output/s/^;//' \
        -e '/error_log/d' \
        -i /etc/php-fpm.d/www.conf \
    && sed -i "s|;date.timezone =.*|date.timezone = ${TIMEZONE}|" /etc/php.ini \
    && sed -i "s|memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|" /etc/php.ini \
    && sed -i "s|upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|" /etc/php.ini \
    && sed -i "s|max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|" /etc/php.ini \
    && sed -i "s|post_max_size =.*|post_max_size = ${PHP_MAX_POST}|" /etc/php.ini \
    && sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php.ini

# Intalling the Drupal
COPY ./ /var/www/html
WORKDIR /var/www/html
RUN yum -y install gcc-c++ make
RUN curl -sL https://rpm.nodesource.com/setup_14.x > nodejs.sh
RUN ["/bin/bash", "-c", "bash nodejs.sh && rm nodejs.sh"]
RUN yum -y install nodejs && npm install -g gulp@4.0.2

RUN mkdir -p /var/www/html
RUN mkdir /run/php-fpm
EXPOSE 9000
ENTRYPOINT ["/usr/sbin/php-fpm", "-F"]
