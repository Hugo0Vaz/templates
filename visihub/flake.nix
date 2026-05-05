{
  description = "Visihub Development Environment - Laravel Backend + Expo Frontend";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { system, ... }:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          devShells.default = pkgs.mkShell {
            name = "visihub-dev";

            packages = with pkgs; [
              # Backend - Laravel/PHP
              php82
              php82Packages.composer
              php82Extensions.zip
              php82Extensions.pdo_mysql
              php82Extensions.pdo_sqlite
              php82Extensions.redis
              php82Extensions.gd
              php82Extensions.curl
              php82Extensions.mbstring
              php82Extensions.xml
              php82Extensions.bcmath
              phpactor

              # Frontend - Expo/React Native
              nodejs_22
              pnpm
              watchman
              android-tools

              # Database
              mariadb
              redis

              # Development tools
              git
              just
              nodePackages.typescript
              nodePackages.typescript-language-server
              nodePackages.prettier
              nodePackages.eslint
            ];

            shellHook = ''
              MYSQL_BASEDIR=${pkgs.mariadb}
              MYSQL_HOME="$PWD/.mysql"
              MYSQL_DATADIR="$MYSQL_HOME/data"
              export MYSQL_UNIX_PORT="$MYSQL_HOME/mysql.sock"
              MYSQL_PID_FILE="$MYSQL_HOME/mysql.pid"
              alias mysql='mysql -u root'

              if [ ! -d "$MYSQL_HOME" ]; then
                echo "Initializing MariaDB..."
                mysql_install_db --no-defaults --auth-root-authentication-method=normal \
                  --datadir="$MYSQL_DATADIR" --basedir="$MYSQL_BASEDIR" \
                  --pid-file="$MYSQL_PID_FILE"
              fi

              # Start MariaDB daemon
              mysqld --no-defaults --skip-networking --datadir="$MYSQL_DATADIR" --pid-file="$MYSQL_PID_FILE" \
                --socket="$MYSQL_UNIX_PORT" 2> "$MYSQL_HOME/mysql.log" &
              MYSQL_PID=$!

              # Redis setup
              REDIS_HOME="$PWD/.redis"
              REDIS_PORT=6379
              mkdir -p "$REDIS_HOME"
              redis-server --daemonize yes --dir "$REDIS_HOME" --pidfile "$REDIS_HOME/redis.pid" --port $REDIS_PORT

              export ANDROID_HOME="$HOME/Android/Sdk"
              export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH"

              export DB_CONNECTION=mysql
              export DB_HOST=127.0.0.1
              export DB_PORT=3306
              export DB_SOCKET="$MYSQL_UNIX_PORT"
              export REDIS_HOST=127.0.0.1
              export REDIS_PORT=$REDIS_PORT

              finish() {
                echo "Shutting down services..."
                if [ -n "$MYSQL_PID" ]; then
                  mysqladmin -u root --socket="$MYSQL_UNIX_PORT" shutdown 2>/dev/null || true
                  kill $MYSQL_PID 2>/dev/null || true
                  wait $MYSQL_PID 2>/dev/null || true
                fi

                if [ -f "$REDIS_HOME/redis.pid" ]; then
                  redis-cli -p $REDIS_PORT shutdown 2>/dev/null || true
                fi
              }
              trap finish EXIT

              # Helper functions for running services
              run-backend() {
                echo "Starting Laravel backend..."
                if [ ! -d "backend" ]; then
                  echo "Error: backend directory not found!"
                  return 1
                fi

                cd backend

                if [ ! -f "composer.json" ]; then
                  echo "Error: composer.json not found in backend directory!"
                  cd ..
                  return 1
                fi

                if [ ! -d "vendor" ]; then
                  echo "Installing backend dependencies..."
                  composer install
                fi

                if [ ! -f ".env" ] && [ -f ".env.example" ]; then
                  echo "Creating .env file..."
                  cp .env.example .env
                  php artisan key:generate
                fi

                echo "Running migrations..."
                php artisan migrate --force

                echo "Starting Laravel server on http://localhost:8000"
                php artisan serve --host=0.0.0.0 --port=8000
                cd ..
              }

              run-frontend() {
                echo "Starting Expo frontend..."
                if [ ! -d "frontend" ]; then
                  echo "Error: frontend directory not found!"
                  return 1
                fi

                cd frontend

                if [ ! -f "package.json" ]; then
                  echo "Error: package.json not found in frontend directory!"
                  cd ..
                  return 1
                fi

                if [ ! -d "node_modules" ]; then
                  echo "Installing frontend dependencies..."
                  pnpm install
                fi

                echo "Starting Expo development server..."
                pnpm expo start
                cd ..
              }

              run-all() {
                echo "Starting all services..."

                # Start backend in background
                (run-backend) &
                BACKEND_PID=$!

                # Give backend time to start
                sleep 5

                # Start frontend
                run-frontend

                # When frontend exits, kill backend
                kill $BACKEND_PID 2>/dev/null || true
              }

              setup-project() {
                echo "Setting up Visihub project..."

                # Setup backend
                if [ -d "backend" ]; then
                  echo "Setting up Laravel backend..."
                  cd backend

                  if [ ! -d "vendor" ]; then
                    composer install
                  fi

                  if [ ! -f ".env" ] && [ -f ".env.example" ]; then
                    cp .env.example .env
                    php artisan key:generate
                  fi

                  # Create database if it doesn't exist
                  mysql -u root --socket="$MYSQL_UNIX_PORT" -e "CREATE DATABASE IF NOT EXISTS visihub;" 2>/dev/null || true
                  mysql -u root --socket="$MYSQL_UNIX_PORT" -e "CREATE DATABASE IF NOT EXISTS visihub_test;" 2>/dev/null || true

                  php artisan migrate --force
                  php artisan db:seed --force

                  cd ..
                else
                  echo "Backend directory not found, skipping..."
                fi

                # Setup frontend
                if [ -d "frontend" ]; then
                  echo "Setting up Expo frontend..."
                  cd frontend

                  if [ ! -d "node_modules" ]; then
                    pnpm install
                  fi

                  cd ..
                else
                  echo "Frontend directory not found, skipping..."
                fi

                echo "Project setup complete!"
              }

              export -f run-backend
              export -f run-frontend
              export -f run-all
              export -f setup-project

              echo "========================================="
              echo "Visihub Development Environment Ready!"
              echo "========================================="
              echo ""
              echo "Backend (Laravel):"
              echo " - PHP $(php --version | head -n 1)"
              echo " - Composer $(composer --version --no-ansi | cut -d' ' -f3)"
              echo " - MariaDB running on socket: $MYSQL_UNIX_PORT"
              echo " - Redis running on port: $REDIS_PORT"
              echo ""
              echo "Frontend (Expo):"
              echo " - Node.js $(node --version)"
              echo " - pnpm $(pnpm --version)"
              echo ""
              echo "Available commands:"
              echo " - setup-project  : Setup both backend and frontend"
              echo " - run-backend    : Start Laravel development server"
              echo " - run-frontend   : Start Expo development server"
              echo " - run-all        : Start both servers concurrently"
              echo "========================================="
            '';

            COMPOSER_MEMORY_LIMIT = "-1";
            NODE_OPTIONS = "--max-old-space-size=4096";
          };
        };
    };
}
