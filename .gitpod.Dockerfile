FROM gitpod/workspace-mysql

RUN sudo apt update -y

# Install PHP 8
RUN sudo apt install -y software-properties-common
RUN sudo add-apt-repository ppa:ondrej/php -y
RUN sudo apt update -y
RUN sudo apt install -y php php-fpm php-cli php-common php-bz2 php-zip php-curl php-gd php-mysql php-xml php-mbstring php-bcmath

# Install Composer 2.2.6
RUN sudo wget https://getcomposer.org/download/2.2.6/composer.phar
RUN sudo sudo chmod +x composer.phar
RUN sudo sudo cp composer.phar /usr/bin/composer
RUN sudo sudo mv composer.phar /usr/local/bin/composer

# Install Node Js
RUN sudo curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -
RUN sudo apt -y install nodejs
RUN sudo node -v

USER gitpod
