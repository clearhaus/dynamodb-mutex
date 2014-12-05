# -*- encoding: utf-8 -*-

require File.expand_path("../lib/dynamodb_mutex/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name    = 'dynamodb-mutex'
  gem.version = DynamoDBMutex::VERSION
  gem.date    = Date.today.to_s

  gem.summary = "Distributed mutex based on AWS DynamoDB"
  gem.description = "dynamodb-mutex implements a simple mutex that can be used to coordinate"
                     "access to shared data from multiple concurrent hosts"

  gem.authors  = ['Dinesh Yadav']
  gem.email    = 'dy@clearhaus.com'
  gem.homepage = 'http://github.com/clearhaus/dynamodb-mutex'

  gem.add_dependency('aws-sdk')

  gem.add_development_dependency('rspec', [">= 2.0.0"])
  gem.add_development_dependency('rspec-mocks')
  gem.add_development_dependency('rake')
  gem.add_development_dependency('fake_dynamo', ["0.1.3"])

  # ensure the gem is built out of versioned files
  gem.files = Dir['Rakefile', '{bin,lib,man,test,spec}/**/*', 'README*', 'LICENSE*'] & `git ls-files -z`.split("\0")

end