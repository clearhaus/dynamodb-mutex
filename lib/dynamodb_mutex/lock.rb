require 'aws-sdk'
require_relative 'logging'

module DynamoDBMutex

  LockError = Class.new(StandardError)
  
  module Lock
    include Logging
    extend self

    TABLE_NAME = 'dynamodb-mutex'

    def with_lock name, opts = {}
      opts[:ttl]      ||= 10     
      opts[:block]    ||= 1
      opts[:sleep]    ||= 0.1        

      delete(name) if expired?(name, opts[:ttl])
      if create(name, opts)
        begin Timeout::timeout(opts[:ttl]) { return(yield) }
        ensure delete(name)
        end
      else
        raise LockError, "Unable to hold #{name} after #{opts[:block]} ms"
      end
    end

    private

      def create name, opts
        acquire_timeout = Time.now.to_i + opts[:block]

        while Time.now.to_i < acquire_timeout
          begin
            table.items.put({:id => name, :created => Time.now.to_i},
              :unless_exists => :id)
            logger.info "ACQUIRED LOCK #{name} by #{tpid}"
            return true
          rescue AWS::DynamoDB::Errors::ConditionalCheckFailedException
            logger.info "Waiting for the #{name} ..."
            sleep opts[:sleep]
          end
        end

        false
      end

      def delete(name)
        table.items.at(name).delete
        logger.info "RELEASED LOCK #{name} by #{tpid}"
      end

      def tpid
        Thread.current.object_id
      end

      def expired?(name, ttl)
        if l = table.items.at(name).attributes.to_h(:consistent_read => true)
          if t = l["created"]
            t < (Time.now.to_i - ttl)
          end
        end
      end

      def table
        return @table if @table
        dynamo_db = AWS::DynamoDB.new

        begin
          @table = dynamo_db.tables[TABLE_NAME].load_schema
        rescue AWS::DynamoDB::Errors::ResourceNotFoundException
          @table = dynamo_db.tables.create(TABLE_NAME, 5, 5, {})
          sleep 1 unless @table.status == :active
        end

        @table
      end
    end
end