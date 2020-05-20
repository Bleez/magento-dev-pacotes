
FROM php:7.2

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    software-properties-common \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libfreetype6-dev \
    libicu-dev \
    libssl-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libedit-dev \
    libedit2 \
    libxslt1-dev \
    && apt-get clean

# Install Magento Dependencies

RUN pecl install mcrypt-1.0.2 \
    && docker-php-ext-enable mcrypt \
  	&& docker-php-ext-install \
  	opcache \
  	gd \
  	bcmath \
  	intl \
  	mbstring \
  	pdo_mysql \
  	soap \
  	xsl \
	sockets \
  	zip

RUN	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer

RUN yes | pecl install xdebug

