# frozen_string_literal: true

module Queues
  module Rabbit
    class Exchange
      class << self
        attr_accessor :arguments, :auto_delete, :durable, :internal, :name, :type

        def bind(exchange, binding_key, arguments: {})
          exchange = exchange < Queues::Rabbit::Exchange ? exchange.name : exchange
          exchange_instance.bind(exchange, binding_key, arguments: arguments)
          true
        rescue
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
          @@exchange_instance ||= Queues::Rabbit.client_instance.exchange(name, type, arguments: arguments, auto_delete: auto_delete, durable: durable, internal: internal)
        end

        # @param properties [Properties]
        # @option properties [String] content_type Content type of the message body
        # @option properties [String] content_encoding Content encoding of the body
        # @option properties [Hash<String, Object>] headers Custom headers
        # @option properties [Integer] delivery_mode 2 for persisted message, transient messages for all other values
        # @option properties [Integer] priority A priority of the message (between 0 and 255)
        # @option properties [Integer] correlation_id A correlation id, most often used used for RPC communication
        # @option properties [String] reply_to Queue to reply RPC responses to
        # @option properties [Integer, String] expiration Number of seconds the message will stay in the queue
        # @option properties [String] message_id Can be used to uniquely identify the message, e.g. for deduplication
        # @option properties [Date] timestamp Often used for the time the message was originally generated
        # @option properties [String] type Can indicate what kind of message this is
        # @option properties [String] user_id Can be used to verify that this is the user that published the message
        # @option properties [String] app_id Can be used to indicates which app that generated the message
        def publish(body, routing_key, **properties)
          exchange_instance.publish(body, name, routing_key, **properties)
          true
        rescue
          false
        end

        def unbind(exchange, binding_key, arguments: {})
          exchange = exchange < Queues::Rabbit::Exchange ? exchange.name : exchange
          exchange_instance.unbind(exchange, binding_key, arguments: arguments)
          true
        rescue
          false
        end
      end
    end
  end
end
