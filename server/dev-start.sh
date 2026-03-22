#!/usr/bin/env bash
set -e

echo "Starting Falcon server..."
bundle exec falcon serve --bind http://0.0.0.0:9000 --config config.ru
