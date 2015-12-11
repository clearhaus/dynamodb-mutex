require 'aws-sdk'
require 'socket'
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
        raise LockError,
          "Unable to acquire #{name} after #{opts[:wait_for_other]} seconds"
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
            dynamodb_client.put_item(
              table_name: TABLE_NAME,
              item: { :id => name, :created => Time.now.to_i.to_s },
              condition_expression: 'attribute_not_exists(id)'
            )
            logger.info "#{pid} acquired #{name}"
            return true
          rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
            logger.info "#{pid} is waiting for #{name}"
            sleep opts[:polling_interval]
          end
        end

        logger.warn "#{pid} failed to acquire #{name}"
        false
      end

      def delete(name)
        dynamodb_client.delete_item(
          table_name: TABLE_NAME,
          key: { :id => name }
        )
        logger.info "#{pid} released lock #{name}"
      end

      def pid
        @hostname ||= Socket.gethostname

        "#{@hostname}-#{Process.pid}-#{Thread.current.object_id}"
      end

      def stale?(name, ttl)
        return false unless ttl

        item = dynamodb_client.get_item(
          table_name: TABLE_NAME,
          key: { :id => name },
          consistent_read: true
        ).item

        not item.nil? and Time.now.to_i > item['created'].to_i + ttl
      end

      def dynamodb_client
        return @dynamodb_client if @dynamodb_client
        @dynamodb_client = Aws::DynamoDB::Client.new

        begin
          @dynamodb_client.describe_table(table_name: TABLE_NAME)
        rescue Aws::DynamoDB::Errors::ResourceNotFoundException
          logger.info "Table #{TABLE_NAME} not found; creating it."
          @dynamodb_client.create_table(
            table_name: TABLE_NAME,
            attribute_definitions: [
              { attribute_name: 'id', attribute_type: 'S' }
            ],
            key_schema: [
              { attribute_name: 'id', key_type: 'HASH' }
            ],
            provisioned_throughput: {
              read_capacity_units: 5,
              write_capacity_units: 5
            }
          )
          logger.info "Waiting for table #{TABLE_NAME} to be created."
          begin
            @dynamodb_client.wait_until(:table_exists,
                                        table_name: TABLE_NAME) do |w|
              w.max_attempts = 10
              w.delay = 1
            end
          rescue Aws::Waiters::Errors::WaiterFailed => e
            raise LockError, "Cannot create table #{TABLE_NAME}: #{e.message}"
          end
          logger.info "Table #{TABLE_NAME} has been created."
        end

        @dynamodb_client
      end
  end
end
