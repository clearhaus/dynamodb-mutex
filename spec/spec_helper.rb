require 'rubygems'
require 'bundler/setup'
require 'rspec'

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

  config.before(:all) do
    dynamo_pid = Process.fork do
      Dir.chdir('resources')
      exec('java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar -inMemory -port 4567')
    end

    sleep 1
  end

  config.after(:all) do
    sleep 0.5
    Process.kill('INT', dynamo_pid) if dynamo_pid
    Process.waitpid(dynamo_pid)
  end
end
