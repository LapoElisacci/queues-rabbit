# frozen_string_literal: true

module Queues
  module Rabbit
    class BatchedQueue
      class << self
        attr_accessor :batch_size, :batch_timeout, :arguments, :auto_delete, :durable, :name, :prefetch, :schema

        def consume(_messages)
          raise NoMethodError.new("Method #{__method__} must be defined to subscribe a queue!")
        end

        #
        # Delete a Queue from RabbitMQ
        #
        # @return [Boolean] True if delete, false otherwise
        #
        def delete
          queue_instance.delete
          true
        rescue Exception => e
          logger.error_with_report "Unable to delete #{name}: #{e.message}."
          false
        end

        #
        # Declare a Queue
        #
        # @param [String] name Queue name
        # @param [Integer] batch_size Batch size
        # @param [Integer] batch_timeout Batch timeout, that the time interval in which the batch will be emptied even if not full.
        # @param [Hash] arguments Custom arguments, such as queue-ttl etc.
        # @param [Boolean] auto_delete If true, the queue will be deleted when the last consumer stops consuming.
        # @param [Boolean] durable If true, the queue will survive broker restarts, messages in the queue will only survive if they are published as persistent.
        # @param [Integer] prefetch Specify how many messages to prefetch.
        #                           For batched queues it must be greater or equal than batch_size.
        #
        # @return [Queues::Rabbit::Queue] Queue class
        #
        def batched_queue(name, batch_size:, batch_timeout:, arguments: {}, auto_delete: false, durable: true, prefetch: nil)
          self.arguments = arguments
          self.auto_delete = auto_delete
          self.durable = durable
          self.name = name
          self.batch_size = batch_size
          self.batch_timeout = batch_timeout
          self.prefetch = prefetch || batch_size
          raise StandardError.new("Prefetch must be greater or equal than batch size: got prefetch=#{self.prefetch} and batch_size=#{batch_size}") if self.prefetch < batch_size

          self
        end

        #
        # Publish a message to the Queue
        #
        # @param [String] body                                The message body, can be a string or either a byte array
        # @param [Hash] properties Request properties
        # @option properties [String] :app_id                  Used to identify the app that generated the message
        # @option properties [String] :content_encoding        Content encoding of the body
        # @option properties [String] :content_type            Content type of the body
        # @option properties [Integer] :correlation_id         The correlation id, mostly used used for RPC communication
        # @option properties [Integer] :delivery_mode          2 for persistent messages, all other values are for transient messages
        # @option properties [Integer, String] :expiration     Number of seconds the message will stay in the queue
        # @option properties [Hash<String, Object>] :headers   Custom headers
        # @option properties [Boolean] :mandatory              The message will be returned if the message can't be routed to a queue
        # @option properties [String] :message_id              Can be used to uniquely identify the message, e.g. for deduplication
        # @option properties [Boolean] :persistent             Same as delivery_mode: 2
        # @option properties [Integer] :priority               The message priority (between 0 and 255)
        # @option properties [String] :reply_to                Queue to reply RPC responses to
        # @option properties [Date] :timestamp                 Often used for the time the message was originally generated
        # @option properties [String] :type                    Can indicate what kind of message this is
        # @option properties [String] :user_id                 Used to identify the user that published the message
        #
        # @return [Boolean] True if published, false otherwise
        #
        def publish(body, **properties)
          queue_instance.publish(body, **properties)
          true
        rescue Exception => e
          logger.error_with_report "Unable to publish to #{name}: #{e.message}."
          false
        end

        #
        # Purge / Empty a queue from RabbitMQ
        #
        # @return [Boolean] True if purged, false otherwise
        #
        def purge
          queue_instance.purge
          true
        rescue Exception => e
          logger.error_with_report "Unable to purge #{name}: #{e.message}."
          false
        end

        #
        # Subscribe to a Queue
        #
        def subscribe
          logger.info "Subscribing to queue #{name}"
          consumer = new
          batch = []
          # NOTE: Batched subscribe must be performed only by one thread
          queue_instance.subscribe(worker_threads: 1, no_ack: false, prefetch: prefetch) do |message|
            if message.properties.type == 'timeout'
              message.ack  # Remove the timeout message from the queue
              if batch.size > 0
                consumer.consume(batch)
                batch = []
              end
            else
              batch << Queues::Rabbit::Message.new(message)
              if batch.size >= batch_size
                consumer.consume(batch)
                batch = []
              end
            end
          rescue Exception => e
            logger.error { e.message }
            logger.stdout e.message, :error
          end

          loop do
            logger.stdout "Connection to #{name} alive."
            sleep batch_timeout
            queue_instance.publish('', type: 'timeout')  # Special 'timeout' message
            logger.stdout "Batch timeout expired (#{batch_timeout} seconds)"
          end
        rescue Exception => e
          logger.error_with_report "Unable to connect to #{name}: #{e.message}."
          false
        end

        private

          #
          # Return the logger instance
          #
          # @return [Queues::Rabbit::Logger] Logger instance
          #
          def logger
            @@logger ||= Queues::Rabbit::Logger.new(name, Queues::Rabbit.log_level)
          end

          #
          # Return the Queue instance
          #
          # @return [AMQP::Client::Client] Queue instance
          #
          def queue_instance
            @@queue_instance ||= schema.client_instance.queue(name, arguments: arguments, auto_delete: auto_delete, durable: durable)
          end
      end
    end
  end
end
