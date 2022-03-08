# frozen_string_literal: true

module Queues
  module Rabbit
    class Queue
      class << self
        attr_accessor :arguments, :auto_delete, :durable, :name, :no_ack, :prefetch, :schema

        #
        # Bind a Queue to an Exchange
        #
        # @param [String] exchange Exchange name
        # @param [String] binding_key Exchange binding key
        # @param [Hash] arguments Message headers to match on (only relevant for header exchanges)
        #
        # @return [Boolean] True if bounded, false otherwise
        #
        def bind(exchange, binding_key, arguments: {})
          exchange = exchange < Queues::Rabbit::Exchange ? exchange.name : exchange
          queue_instance.bind(exchange, binding_key, arguments: arguments)
          true
        rescue Exception => e
          logger.error_with_report "Unable to bind '#{name}' to '#{exchange}' with key '#{binding_key}' and arguments: '#{arguments}': #{e.message}."
          false
        end

        def consume(_message)
          raise NoMethodError.new("Method #{__method__} must be defined to subscribe a queue!")
        end

        def batch_consume(_messages)
          raise NoMethodError.new("Method #{__method__} must be defined to batch-subscribe a queue!")
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
        # @param [Hash] arguments Custom arguments, such as queue-ttl etc.
        # @param [Boolean] auto_ack When false messages have to be manually acknowledged (or rejected)
        # @param [Boolean] auto_delete If true, the queue will be deleted when the last consumer stops consuming.
        # @param [Boolean] durable If true, the queue will survive broker restarts, messages in the queue will only survive if they are published as persistent.
        # @param [Integer] prefetch Specify how many messages to prefetch
        #
        # @return [Queues::Rabbit::Queue] Queue class
        #
        def queue(name, arguments: {}, auto_ack: true, auto_delete: false, durable: true, prefetch: 1)
          self.arguments = arguments
          self.auto_delete = auto_delete
          self.durable = durable
          self.name = name
          self.no_ack = auto_ack
          self.prefetch = prefetch
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
          logger.info { "Subscribing to queue #{name}" }
          consumer = new
          queue_instance.subscribe(no_ack: no_ack, prefetch: prefetch) do |message|
            consumer.consume(Queues::Rabbit::Message.new(message))
          rescue Exception => e
            logger.error { e.message }
            logger.stdout e.message, :error
          end

          loop do
            logger.stdout "Connection to #{name} alive."
            sleep 10
          end
        rescue Exception => e
          logger.error_with_report "Unable to connect to #{name}: #{e.message}."
          false
        end

        #
        # Subscribe to the queue with a batch reading.
        # This method will block.
        #
        # @param [Integer] batch_size Batch size
        # @param [ActiveSupport::Duration] batch_timeout Batch timeout, that the time interval in which the batch will be emptied even if not full.
        #
        # @return [FalseClass] if errors
        #
        def batch_subscribe(batch_size:, batch_timeout:)
          raise StandardError.new('Batch size must be a positive integer') if batch_size.to_i <= 0
          raise StandardError.new("Batch size must be less or equal than prefetch: got batch_size=#{batch_size} and prefetch=#{prefetch}") if batch_size > prefetch

          logger.info "Subscribing to queue #{name} with a batch size #{batch_size}"
          consumer = new
          batch = []
          # Batched subscribe must be performed only by one thread
          # Auto-acking is done manually, otherwise batching is not possible
          queue_instance.subscribe(worker_threads: 1, no_ack: false, prefetch: prefetch) do |message|
            if message.properties.type == 'timeout'
              message.ack  # Remove the timeout message from the queue
              min_batch_size = 0
            else
              batch << Queues::Rabbit::Message.new(message)
              min_batch_size = batch_size
            end
            if batch.size > 0 && batch.size >= min_batch_size
              batch.each(&:ack) if no_ack
              consumer.batch_consume(batch)
              batch = []
            end
          rescue Exception => e
            logger.error { e.message }
            logger.stdout e.message, :error
          end

          loop do
            logger.stdout "Connection to #{name} alive."
            sleep batch_timeout
            queue_instance.publish('', type: 'timeout', persistent: false, espiration: 3.seconds)
          end
        rescue Exception => e
          logger.error_with_report "Unable to connect to #{name}: #{e.message}."
          false
        end

        #
        # Unbind a Queue from an Exchange
        #
        # @param [String] exchange Exchange name
        # @param [String] binding_key Exchange binding key
        # @param [Hash] arguments Message headers to match on (only relevant for header exchanges)
        #
        # @return [Boolean] True if unbounded, false otherwise.
        #
        def unbind(exchange, binding_key, arguments: {})
          exchange = exchange < Queues::Rabbit::Exchange ? exchange.name : exchange
          queue_instance.unbind(exhange, binding_key, arguments: arguments)
          true
        rescue Exception => e
          logger.error_with_report "Unable to unbind '#{name}' to '#{exchange}' with key '#{binding_key}' and arguments: '#{arguments}': #{e.message}."
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
