# Base Image
FROM ruby:3.3.6
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs yarn

# Set working directory
WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock /app/
RUN gem install bundler && bundle install

# Copy application code
COPY . /app

# Expose port
EXPOSE 3000

# Command to run the app
CMD ["rails", "server", "-b", "0.0.0.0"]
