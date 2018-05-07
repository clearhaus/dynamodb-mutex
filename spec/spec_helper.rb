require 'rubygems'
require 'bundler/setup'
require 'rspec'

require 'English'

require 'aws-sdk-dynamodb'
require 'dynamodb-mutex'

Aws.config.update(
  credentials: Aws::Credentials.new(
    'your_access_key_id',
    'your_secret_access_key'
  ),
  endpoint: 'http://localhost:4567'
)

AMAZON_LOCAL_DYNAMODB_URL =
  'https://s3.eu-central-1.amazonaws.com/dynamodb-local-frankfurt/dynamodb_local_latest.tar.gz'.freeze
DYNAMODB_JAR_DIR = 'resources'.freeze
DYNAMODB_TMP_PATH = '/tmp/dynamodb_local_latest.tar.gz'.freeze

RSpec.configure do |config|
  log_stream = ENV['DEBUG'] =~ (/^(true|t|yes|y|1)$/i) ? STDERR : StringIO.new

  DynamoDBMutex::Lock.logger = Logger.new(log_stream)

  dynamo_pid = nil

  config.before(:suite) do
    # Download Amazons local DynamoDB and use that as an endpoint for specs.

    Dir.mkdir(DYNAMODB_JAR_DIR) unless Dir.exist?(DYNAMODB_JAR_DIR)

    unless File.exist?("./#{DYNAMODB_JAR_DIR}/DynamoDBLocal.jar")
      raise "Error downloading #{AMAZON_LOCAL_DYNAMODB_URL}" unless \
        system("wget #{AMAZON_LOCAL_DYNAMODB_URL} -O #{DYNAMODB_TMP_PATH} -q")

      raise "Error unpacking #{DYNAMODB_TMP_PATH}" unless \
        system("tar -xf #{DYNAMODB_TMP_PATH} -C #{DYNAMODB_JAR_DIR}")
    end

    dynamo_pid = Process.fork do
      Dir.chdir(DYNAMODB_JAR_DIR)
      $stdout.reopen('/dev/null', 'w')

      exec('java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar -inMemory -port 4567')
    end

    # Loop until we successfully connect to the DynamoDB
    # maximal loop waiting time in seconds
    loop_max_wait = 10
    loop_count = 0
    sleep_interval = 0.1

    while loop_count < loop_max_wait / sleep_interval
      loop_count += 1
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

  config.after(:suite) do
    Process.kill('INT', dynamo_pid) if dynamo_pid
    Process.waitpid(dynamo_pid)
  end
end
