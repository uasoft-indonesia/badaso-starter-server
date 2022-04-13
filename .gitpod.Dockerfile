FROM gitpod/workspace-base

# Install PHP 8
RUN sudo apt install -y software-properties-common
RUN sudo add-apt-repository ppa:ondrej/php -y
RUN sudo apt update -y
RUN sudo apt-get install -y php8.1-cli php8.1-dev php8.1-gd \
    php8.1-curl php8.1-mbstring php8.1-zip
RUN sudo php -m

# Install Composer 2.2.6
RUN sudo wget https://getcomposer.org/download/2.2.6/composer.phar
RUN sudo sudo chmod +x composer.phar
RUN sudo sudo cp composer.phar /usr/bin/composer
RUN sudo sudo mv composer.phar /usr/local/bin/composer

USER gitpod
