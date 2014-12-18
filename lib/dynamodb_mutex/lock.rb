require 'aws-sdk'
require_relative 'logging'

module DynamoDBMutex

  LockError = Class.new(StandardError)

  module Lock
    include Logging
    extend self

    TABLE_NAME = 'dynamodb-mutex'

    # May raise
    #   DynamoDBMutex::LockError
    #   Timeout::Error
    def with_lock name = 'default.lock', opts = {}
      opts[:stale_after]      ||= 10  # seconds
      opts[:wait_for_other]   ||= 1   # seconds
      opts[:polling_interval] ||= 0.1 # seconds

      if create(name, opts)
        begin Timeout::timeout(opts[:stale_after]) { return(yield) }
        ensure delete(name)
        end
      else
        raise LockError, "Unable to acquire #{name} after #{opts[:wait_for_other]} seconds"
      end
    end

    private

      def create name, opts
        acquire_timeout = Time.now.to_i + opts[:wait_for_other]

        while Time.now.to_i < acquire_timeout
          logger.info "#{pid} checking if #{name} is stale"
          if stale?(name, opts[:stale_after])
            logger.info "#{pid} deleting #{name} because it is stale"
            delete(name)
          end

          begin
            table.items.put({:id => name, :created => Time.now.to_i},
              :unless_exists => :id)
            logger.info "#{pid} acquired #{name}"
            return true
          rescue AWS::DynamoDB::Errors::ConditionalCheckFailedException
            logger.info "#{pid} is waiting for #{name}"
            sleep opts[:polling_interval]
          end
        end

        logger.warn "#{pid} failed to acquire #{name}"
        false
      end

      def delete(name)
        table.items.at(name).delete
        logger.info "#{pid} released lock #{name}"
      end

      def pid
        @hostname ||= Socket.gethostname

        "#{@hostname}-#{Process.pid}"
      end

      def stale?(name, ttl)
        return false unless ttl

        if lock_attributes = table.items.at(name).attributes.to_h(:consistent_read => true)
          if time_locked = lock_attributes["created"]
            time_locked < (Time.now.to_i - ttl)
          end
        end
      end

      def table
        return @table if @table
        dynamo_db = AWS::DynamoDB.new

        begin
          tries ||= 10
          @table = dynamo_db.tables[TABLE_NAME].load_schema
        rescue AWS::DynamoDB::Errors::ResourceInUseException
          raise LockError, "Cannot load schema for table #{TABLE_NAME}" if (tries -= 1).zero?

          logger.info "Could not load schema for table #{TABLE_NAME}; retrying"
          sleep 1
          retry
        rescue AWS::DynamoDB::Errors::ResourceNotFoundException
          logger.info "Creating table #{TABLE_NAME}"
          @table = dynamo_db.tables.create(TABLE_NAME, 5, 5)
          sleep 1 while @table.status != :active
          logger.info "Table #{TABLE_NAME} created"
        end

        @table
      end
    end
end
