docker info > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Running without docker"

    if ! command -v composer &>/dev/null; then
        echo "composer command not found, please install it first"
        exit
    fi

    if ! command -v npm &>/dev/null; then
        echo "npm command not found, please install it first"
        exit
    fi

    composer create-project laravel/laravel project

    cd project

    composer require badaso/core
    php artisan badaso:setup
    php artisan storage:link
    php artisan key:generate

    curl {{ server_url }}/badaso-starter/views/welcome.blade >resources/views/welcome.blade.php
    curl {{ server_url }}/badaso-starter/.gitpod.Dockerfile >.gitpod.Dockerfile
    curl {{ server_url }}/badaso-starter/.gitpod.yml >.gitpod.yml

    if command -v yarn &>/dev/null; then
        yarn && yarn dev
    else
        npm install && npm run dev
    fi

    echo ""
    echo -e "${WHITE}Badaso installation is successfully, ${NC}but you need to configure the database first, then migrate and seed to use badaso."
    echo ""
    echo -e "Read more https://badaso-docs.uatech.co.id/getting-started/installation#next-setup-for-fresh-project-or-existing-project"
else
    echo "Running with docker"
    
    docker run --rm \
        -v "$(pwd)":/opt \
        -w /opt \
        laravelsail/php81-composer:latest \
        apt-get install -y php8.1-common \ 
        bash -c "composer create-project laravel/laravel project \
        && cd project \
        && composer require badaso/core \
        && composer require laravel/octane \
        && php artisan badaso:setup \
        && php artisan key:generate \
        && php artisan sail:install --with=mysql,redis \
        && php artisan sail:publish"
    
    cd project

    if sudo -n true 2>/dev/null; then
        sudo chown -R $USER: .
    else
        echo -e "${WHITE}Please provide your password so we can make some final adjustments to your application's permissions.${NC}"
        echo ""
        sudo chown -R $USER: .
    fi

    # .env adjustments
    sed -i 's,APP_URL=http://localhost,APP_URL=http://localhost:8000,g' .env
    sed -i '/APP_URL=http:\/\/localhost:8000/i APP_PORT=8000' .env
    sed -i '/APP_PORT=8000/i APP_SERVICE=badaso' .env
    sed -i 's/LOG_CHANNEL=stack/LOG_CHANNEL=daily/g' .env
    sed -i 's/FILESYSTEM_DRIVER=local/FILESYSTEM_DRIVER=public/g' .env

    # supervisord adjustments
    sed -i 's/serve/octane:start --server=swoole/g' docker/8.1/supervisord.conf
    sed -i 's/80/8000/g' docker/8.1/supervisord.conf

    # docker compose adjustments
    sed -i 's,./vendor/laravel/sail/runtimes/8.1,./docker/8.1,g' docker-compose.yml
    sed -i 's/laravel.test/badaso/g' docker-compose.yml
    sed -i 's/80/8000/g' docker-compose.yml
    sed -i 's,sail-8.1/app,badaso,g' docker-compose.yml

    # dockerfile adjustments
    sed -i '/EXPOSE 8000/i RUN mkdir -p /var/www/html/storage' docker/8.1/Dockerfile
    sed -i '/EXPOSE 8000/i RUN mkdir -p /var/www/html/public ' docker/8.1/Dockerfile
    sed -i '/EXPOSE 8000/i RUN chmod -R 777 /var/www/html/storage' docker/8.1/Dockerfile
    sed -i '/EXPOSE 8000/i RUN chmod -R 755 /var/www/html/public' docker/8.1/Dockerfile

    # remove unused dockerfile
    rm -rf docker/7.4
    rm -rf docker/8.0

    # add badaso welcome page & gitpod config
    curl {{ server_url }}/badaso-starter/views/welcome.blade >resources/views/welcome.blade.php
    curl {{ server_url }}/badaso-starter/.gitpod.Dockerfile >.gitpod.Dockerfile
    curl {{ server_url }}/badaso-starter/.gitpod.yml >.gitpod.yml

    # run container
    vendor/bin/sail up -d
    
    # waiting for container fully available
    echo -e "Waiting for container fully available"
    sleep 10

    # database adjustment for badaso
    vendor/bin/sail artisan migrate
    vendor/bin/sail artisan db:seed --class='Database\Seeders\Badaso\BadasoSeeder'
    vendor/bin/sail artisan badaso:admin admin@admin.com --create --name=Admin --username=admin --password=123456 --confirm_password=123456

    # build assets
    vendor/bin/sail artisan storage:link
    vendor/bin/sail yarn
    vendor/bin/sail yarn dev

    sudo chown -R $USER: .
    echo ""
    echo -e "Badaso installation is successfull and running on http://localhost:8000"
    echo ""
    echo -e "Email : admin@admin.com"
    echo -e "Pass  : 123456"
fi