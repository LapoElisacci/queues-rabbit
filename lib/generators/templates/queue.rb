# frozen_string_literal: true

module Rabbits
  module Queues
    class MyQueue < ::Queues::Rabbit::Queue
      queue 'my.queue',         # Required
            auto_ack: false,    # Optional
            auto_delete: false, # Optional
            durable: true,      # Optional
            prefetch: 1,        # Optional (it must be >= batch_size if batch_subscribe is called)
            arguments: {}       # Optional

      def consume(message)
        # do something with the message
        message.ack
      rescue
        message.reject(requeue: false)
      end

      def batch_consume(messages)
        puts "Received #{messages.size} messages"
        # do something with the messages
        messages.each(&:ack)
        puts "Acked #{messages.size} messages"
      rescue
        messages.each { |msg| msg.reject(requeue: false) }
      end
    end
  end
end
