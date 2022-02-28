# frozen_string_literal: true

module Queues
  module Rabbit
    class Queue
      class << self
        attr_accessor :arguments, :auto_delete, :durable, :name, :no_ack, :prefetch

        def bind(exchange, binding_key, arguments: {})
          exchange = exchange < Queues::Rabbit::Exchange ? exchange.name : exchange
          queue_instance.bind(exchange, binding_key, arguments: arguments)
          true
        rescue
          false
        end

        def queue(name, arguments: {}, auto_delete: false, durable: true, no_ack: false, prefetch: 1)
          self.arguments = arguments
          self.auto_delete = auto_delete
          self.durable = durable
          self.name = name
          self.no_ack = no_ack
          self.prefetch = prefetch
          self
        end

        def queue_instance
          @@queue_instance ||= Queues::Rabbit.client_instance.queue(name, arguments: arguments, auto_delete: auto_delete, durable: durable)
        end

        # @param properties [Properties]
        # @option properties [Boolean] mandatory The message will be returned if the message can't be routed to a queue
        # @option properties [Boolean] persistent Same as delivery_mode: 2
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
        def publish(body, **properties)
          queue_instance.publish(body, **properties)
          true
        rescue
          false
        end

        def start
          handler = new
          queue_instance.subscribe(no_ack: no_ack, prefetch: prefetch) do |message|
            handler.consume(message)
          end
        end

        def unbind(exchange, binding_key, arguments: {})
          exchange = exchange < Queues::Rabbit::Exchange ? exchange.name : exchange
          queue_instance.unbind(exhange, binding_key, arguments: arguments)
          true
        rescue
          false
        end
      end

      def consume(_message)
        raise NoMethodError.new("Method #{__method__} must be defined to subscribe a queue!")
      end
    end
  end
end
