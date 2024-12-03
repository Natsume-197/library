# Base Image
FROM ruby:3.3.6
RUN apt-get update -qq && apt-get install -y \
  nodejs \
  libssl-dev \
  libreadline-dev \
  zlib1g-dev \
  build-essential \
  curl
  
# Set working directory
WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock /app/
RUN gem install bundler && bundle install --jobs=3 --retry=3

# Copy application code
COPY . /app

RUN bundle exec rails assets:precompile

# Expose port
EXPOSE 3000

# Command to run the app
CMD ["rails", "server", "-e", "production", "-b", "0.0.0.0"]
