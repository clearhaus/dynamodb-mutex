require 'rspec'

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

def fetch_amazon_dynamodb_local
  Dir.mkdir(DYNAMODB_JAR_DIR) unless Dir.exist?(DYNAMODB_JAR_DIR)

  return if File.exist?("./#{DYNAMODB_JAR_DIR}/DynamoDBLocal.jar")

  system("wget #{AMAZON_LOCAL_DYNAMODB_URL} -O #{DYNAMODB_TMP_PATH} -q") ||
    raise("Error downloading #{AMAZON_LOCAL_DYNAMODB_URL}")

  system("tar -xf #{DYNAMODB_TMP_PATH} -C #{DYNAMODB_JAR_DIR}") ||
    raise("Error unpacking #{DYNAMODB_TMP_PATH}")
end

def spawn_dynamodb
  Dir.chdir(DYNAMODB_JAR_DIR)
  $stdout.reopen('/dev/null', 'w')

  exec('java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar -inMemory -port 4567')
end

RSpec.configure do |config|
  ENV['AWS_DEFAULT_REGION'] = 'eu-west-1'

  log_stream = ENV['DEBUG'] =~ /^(true|t|yes|y|1)$/i ? STDERR : StringIO.new

  DynamoDBMutex::Lock.logger = Logger.new(log_stream)

  dynamo_pid = nil

  config.before(:suite) do
    # Download Amazons local DynamoDB and use that as an endpoint for specs.
    fetch_amazon_dynamodb_local

    dynamo_pid = Process.fork do
      spawn_dynamodb
    end

    [0.1, 0.5, 1, 3, 5, 7, 10].lazy.map do |sleep_interval|
      Aws::DynamoDB::Client.new.list_tables rescue (sleep sleep_interval; false)
    end.any? || raise('DynamoDB did not start in time')
  end

  config.after(:suite) do
    if dynamo_pid
      Process.kill('INT', dynamo_pid)
      Process.waitpid(dynamo_pid)
    end
  end
end
