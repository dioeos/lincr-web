#!/usr/bin/env bash
set -e

echo "Checking Ruby gems..."
bundle check || bundle install

echo "Starting Falcon server..."
io-watch lib -- bundle exec falcon serve --bind http://0.0.0.0:9000 --config config.ru --restart
