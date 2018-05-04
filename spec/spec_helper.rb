require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'fake_dynamo'

require 'process'

require 'aws-sdk-dynamodb'

Aws.config.update({
  credentials: Aws::Credentials.new(
    'your_access_key_id',
    'your_secret_access_key'
  ),
  endpoint: 'http://localhost:4567'
})

require 'dynamodb-mutex'

RSpec.configure do |config|
  log_stream = ENV['DEBUG'] =~ (/^(true|t|yes|y|1)$/i) ? STDERR : StringIO.new

  DynamoDBMutex::Lock.logger = Logger.new(log_stream)

  dynamo_pid = nil

  config.before(:suite) do
    dynamo_pid = Process.fork do
      Dir.chdir('resources')
      `java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar -sharedDb -inMemory -port 4567`
    end

    sleep 1
  end

  config.after(:suite) do
    Process.kill("INT", dynamo_pid) if dynamo_pid
  end

end
