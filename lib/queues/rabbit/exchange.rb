# frozen_string_literal: true

module Queues
  module Rabbit
    class Exchange
      class << self
        attr_accessor :arguments, :auto_delete, :durable, :internal, :name, :schema, :type

        #
        # Bind an Exchange to another Exchange
        #
        # @param [String] exchange Exchange name
        # @param [String] binding_key Exchange binding key
        # @param [Hash] arguments Message headers to match on (only relevant for header exchanges)
        #
        # @return [Boolean] True if bounded, false otherwise
        #
        def bind(exchange, binding_key, arguments: {})
          exchange = exchange < Queues::Rabbit::Exchange ? exchange.name : exchange
          exchange_instance.bind(exchange, binding_key, arguments: arguments)
          true
        rescue Exception => e
          logger.error_with_report "Unable to bind '#{name}' to '#{exchange}' with key '#{binding_key}' and arguments: '#{arguments}': #{e.message}."
          false
        end

        #
        # Delete an Exchange from RabbitMQ
        #
        # @return [Boolean] True if deleted, false otherwise
        #
        def delete
          exchange_instance.delete
          true
        rescue Exception => e
          logger.error_with_report "Unable to delete #{name}: #{e.message}."
          false
        end

        #
        # Declare an Exchange
        #
        # @param [String] name Exchange name
        # @param [String] type Exchange type
        # @param [Hash] arguments Exchange custom arguments
        # @param [Boolean] auto_delete If true, the exchange will be deleted when the last queue/exchange gets unbounded.
        # @param [Boolean] durable If true, the exchange will persist between broker restarts, also a required for persistent messages.
        # @param [Boolean] internal If true, the messages can't be pushed directly to the exchange.
        #
        # @return [Queues::Rabbit::Exchange] Exchange class
        #
        def exchange(name, type, arguments: {}, auto_delete: false, durable: true, internal: false)
          self.arguments = arguments
          self.auto_delete = auto_delete
          self.name = name
          self.durable = durable
          self.internal = internal
          self.name = name
          self.type = type
          self
        end

        #
        # Publish a message to the Exchange
        #
        # @param [String] body                                 The message body, can be a string or either a byte array
        # @param [String] routing_key                          The routing key to route the message to bounded queues
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
        # @return [Boolean] true if published, false otherwise
        #
        def publish(body, routing_key, **properties)
          exchange_instance.publish(body, name, routing_key, **properties)
          true
        rescue Exception => e
          logger.error_with_report "Unable to publish to #{name}: #{e.message}."
          false
        end

        #
        # Unbind the Exchange from another Exchange
        #
        # @param [String] exchange The exchange name to unbind
        # @param [String] binding_key The exchange binding key
        # @param [Hash] arguments Message headers to match on (only relevant for header exchanges)
        #
        # @return [Boolean] True if unbound, false otherwise
        #
        def unbind(exchange, binding_key, arguments: {})
          exchange = exchange < Queues::Rabbit::Exchange ? exchange.name : exchange
          exchange_instance.unbind(exchange, binding_key, arguments: arguments)
          true
        rescue Exception => e
          logger.error_with_report "Unable to unbind '#{name}' to '#{exchange}' with key '#{binding_key}' and arguments: '#{arguments}': #{e.message}."
          false
        end

        private

          #
          # Return the Exchange instance
          #
          # @return [AMQP::Client::Exchange] Exchange instance
          #
          def exchange_instance
            @@exchange_instance ||= schema.client_instance.exchange(name, type, arguments: arguments, auto_delete: auto_delete, durable: durable, internal: internal)
          end

          #
          # Return the logger instance
          #
          # @return [Queues::Rabbit::Logger] Logger instance
          #
          def logger
            @@logger ||= Queues::Rabbit::Logger.new(name, Queues::Rabbit.log_level)
          end
      end
    end
  end
end
