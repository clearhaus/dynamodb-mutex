require 'date'
require File.expand_path('../lib/dynamodb_mutex/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name    = 'dynamodb-mutex'
  gem.version = DynamoDBMutex::VERSION
  gem.date    = Date.today.to_s
  gem.license = 'MIT'

  gem.summary = 'Distributed mutex based on AWS DynamoDB'
  gem.description = 'dynamodb-mutex implements a simple mutex that can be ' \
                    'used to coordinate access to shared data from multiple ' \
                    'concurrent hosts'

  gem.authors  = ['Clearhaus']
  gem.email    = 'hello@clearhaus.com'
  gem.homepage = 'http://github.com/clearhaus/dynamodb-mutex'

  gem.add_dependency('aws-sdk-dynamodb')

  gem.add_development_dependency('rake')
  gem.add_development_dependency('rspec', ['>= 2.0.0'])
  gem.add_development_dependency('rspec-mocks')

  # ensure the gem is built out of versioned files
  gem.files = Dir['Rakefile', '{lib,spec}/**/*', 'README*', 'LICENSE*']
end
