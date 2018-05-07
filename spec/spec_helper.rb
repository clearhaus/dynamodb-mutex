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
      $stdout.reopen('/dev/null', 'w')

      exec('java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar -inMemory -port 4567')
    end

    # Loop until we successfully connect to the DynamoDB
    # maximal loop waiting time in seconds
    loop_max_wait = 10
    loop_count = 0
    sleep_interval = 0.1

    while loop_count < loop_max_wait / sleep_interval
      begin
        client = Aws::DynamoDB::Client.new
        client.list_tables

        break
      rescue
        sleep sleep_interval
      end
    end

    raise 'DynamoDB did not start in time' if loop_count >= loop_max_wait / sleep_interval
  end

  config.after(:all) do
    Process.kill('INT', dynamo_pid) if dynamo_pid
    Process.waitpid(dynamo_pid)
  end
end
