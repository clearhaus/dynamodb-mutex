require 'aws-sdk'
require_relative 'logging'

module DynamoDBMutex

  LockError = Class.new(StandardError)

  module Lock
    include Logging
    extend self

    TABLE_NAME = 'dynamodb-mutex'

    def with_lock name = 'default.lock', opts = {}
      opts[:stale_after]      ||= 10  # seconds
      opts[:wait_for_other]   ||= 1   # seconds
      opts[:polling_interval] ||= 0.1 # seconds

      if create(name, opts)
        begin Timeout::timeout(opts[:stale_after]) { return(yield) }
o       ensure delete(name)
        end
      else
        raise LockError, "Unable to acquire #{name} after #{opts[:wait_for_other]} seconds"
      end
    end

    private

      def create name, opts
        acquire_timeout = Time.now.to_i + opts[:wait_for_other]

        while Time.now.to_i < acquire_timeout
          delete(name) if stale?(name, opts[:stale_after])
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
          @table = dynamo_db.tables[TABLE_NAME].load_schema
        rescue AWS::DynamoDB::Errors::ResourceInUseException
          logger.info "Table #{TABLE_NAME} already exists"
          retry
        rescue AWS::DynamoDB::Errors::ResourceNotFoundException
          logger.info "Creating table #{TABLE_NAME}"
          @table = dynamo_db.tables.create(TABLE_NAME, 5, 5, {})
          sleep 1 unless @table.status == :active
        end

        @table
      end
    end
end
