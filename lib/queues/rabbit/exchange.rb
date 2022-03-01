# frozen_string_literal: true

module Queues
  module Rabbit
    class Exchange
      class << self
        attr_accessor :arguments, :auto_delete, :durable, :internal, :name, :schema, :type

        def bind(exchange, binding_key, arguments: {})
          exchange = exchange < Queues::Rabbit::Exchange ? exchange.name : exchange
          exchange_instance.bind(exchange, binding_key, arguments: arguments)
          true
        rescue Exception => e
          logger.error_with_report "Unable to bind '#{name}' to '#{exchange}' with key '#{binding_key}' and arguments: '#{arguments}': #{e.message}."
          false
        end

        def delete
          exchange_instance.delete
          true
        rescue Exception => e
          logger.error_with_report "Unable to delete #{name}: #{e.message}."
          false
        end

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

        def exchange_instance
          @@exchange_instance ||= schema.client_instance.exchange(name, type, arguments: arguments, auto_delete: auto_delete, durable: durable, internal: internal)
        end

        def logger
          @@logger ||= Queues::Rabbit::Logger.new(name, Queues::Rabbit.log_level)
        end

        #
        # <Description>
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

        def unbind(exchange, binding_key, arguments: {})
          exchange = exchange < Queues::Rabbit::Exchange ? exchange.name : exchange
          exchange_instance.unbind(exchange, binding_key, arguments: arguments)
          true
        rescue Exception => e
          logger.error_with_report "Unable to unbind '#{name}' to '#{exchange}' with key '#{binding_key}' and arguments: '#{arguments}': #{e.message}."
          false
        end
      end
    end
  end
end
