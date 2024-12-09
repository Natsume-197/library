#!/bin/bash

echo "Running Rake task: db:migrate..."
RAILS_ENV=production bundle exec rake db:migrate

echo "Creating index..."
RAILS_ENV=production bundle exec rake elastic:rebuild

echo "Starting Rails server..."
exec rails server -e production -b 0.0.0.0

