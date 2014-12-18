FROM ruby:1.9.3

WORKDIR /tmp/
COPY Gemfile Gemfile
COPY dynamodb-mutex.gemspec dynamodb-mutex.gemspec
COPY lib/dynamodb_mutex/version.rb lib/dynamodb_mutex/version.rb
COPY Gemfile.lock Gemfile.lock
RUN bundle install

COPY . /app
WORKDIR /app

CMD bundle exec rake test
