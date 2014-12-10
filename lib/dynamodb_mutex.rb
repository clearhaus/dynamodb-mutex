require 'dynamodb_mutex/lock'

module DynamoDBMutex

  def self.with_lock *args, &block
    Lock.with_lock(*args, &block)
  end

end
