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

    composer create-project laravel/laravel {{ name }}

    cd {{ name }}

    composer require badaso/core
    php artisan badaso:setup
    php artisan storage:link
    php artisan key:generate

    curl {{ server_url }}/badaso-starter/views/welcome.blade >resources/views/welcome.blade.php
    curl {{ server_url }}/badaso-starter/.gitpod.Dockerfile >.gitpod.Dockerfile
    curl {{ server_url }}/badaso-starter/.gitpod.yml >.gitpod.yml
    curl {{ server_url }}/badaso-starter/README.md >README.md

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
        bash -c "composer create-project laravel/laravel {{ name }} \
        && cd {{ name }} \
        && composer require badaso/core \
        && composer require laravel/octane \
        && php artisan badaso:setup \
        && php artisan key:generate \
        && php artisan sail:install --with=mysql,redis \
        && php artisan sail:publish"
    
    cd {{ name }}

    if sudo -n true 2>/dev/null; then
        sudo chown -R $USER: .
    else
        echo -e "${WHITE}Please provide your password so we can make some final adjustments to your application's permissions.${NC}"
        echo ""
        sudo chown -R $USER: .
    fi

    # .env adjustments
    sed -i 's|APP_URL=http://localhost|APP_URL=http://localhost:8000|g' .env
    sed -i '/APP_URL=http:\/\/localhost:8000/i APP_PORT=8000' .env
    sed -i '/APP_PORT=8000/i APP_SERVICE=badaso' .env
    sed -i 's/LOG_CHANNEL=stack/LOG_CHANNEL=daily/g' .env
    sed -i 's/FILESYSTEM_DISK=local/FILESYSTEM_DISK=public/g' .env
    sed -i 's/DB_DATABASE=laravel/DB_DATABASE=badaso/g' .env
    cp .env .env.example

    # composer.json adjustment
    sed -i 's|laravel/laravel|badaso/starter|g' composer.json
    sed -i 's/The Laravel Framework/Badaso starter project/g' composer.json

    # supervisord adjustments
    sed -i 's/serve/octane:start --server=swoole/g' docker/8.1/supervisord.conf
    sed -i 's/80/8000/g' docker/8.1/supervisord.conf

    # docker compose adjustments
    sed -i 's|./vendor/laravel/sail/runtimes/8.1|./docker/8.1|g' docker-compose.yml
    sed -i 's/laravel.test/badaso/g' docker-compose.yml
    sed -i 's/{APP_PORT:-80}:80/{APP_PORT:-8000}:8000/g' docker-compose.yml
    sed -i 's|sail-8.1/app|badaso|g' docker-compose.yml

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
    curl {{ server_url }}/badaso-starter/README.md >README.md

    # run container
    vendor/bin/sail up -d
    
    # waiting for database container fully available
    echo "Waiting for database container fully available"
    sleep 5

    check_database=1

    for i in {1..5}
    do
        if [[ $(vendor/bin/sail artisan tinker --execute="echo DB::connection()->getDatabaseName();") ==  *"laravel"* ]];then
            # database adjustment for badaso
            vendor/bin/sail artisan migrate
            vendor/bin/sail artisan db:seed --class='Database\Seeders\Badaso\BadasoSeeder'
            vendor/bin/sail artisan badaso:admin {{ account_email }} --create --name={{ account_name }} --username={{ account_username }} --password={{ account_password }} --confirm_password={{ account_password }}
            break
        else
            if [ $check_database == 5 ];
            then
                echo ""
                echo "Can't connect to database container, try manual later by running these commands :"
                echo "cd {{ name }}"
                echo "vendor/bin/sail artisan migrate"
                echo 'vendor/bin/sail artisan db:seed --class="Database\Seeders\Badaso\BadasoSeeder"'
                echo "vendor/bin/sail artisan badaso:admin {{ account_email }} --create --name={{ account_name }} --username={{ account_username }} --password={{ account_password }} --confirm_password={{ account_password }}"
                echo ""
            else
                echo "Check database for ${check_database} times"
                ((check_database++))
                sleep 5
            fi
        fi
    done

    # build assets
    vendor/bin/sail artisan storage:link
    vendor/bin/sail yarn
    vendor/bin/sail yarn dev

    sudo chown -R $USER: .
    echo ""
    echo -e "Badaso installation is successfull and running on http://localhost:8000"
    echo ""
    echo -e "Email : {{ account_email }}"
    echo -e "Pass  : {{ account_password }}"
fi
