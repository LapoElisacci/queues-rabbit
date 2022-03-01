# frozen_string_literal: true

module Rabbits
  module Queues
    class MyQueue < ::Queues::Rabbit::Queue
      queue 'my.queue',         # Required
            auto_ack: false,    # Optional
            auto_delete: false, # Optional
            durable: true,      # Optional
            prefetch: 1,        # Optional
            arguments: {}       # Optional

      def consume(message)
        # do something with the message
        message.ack
      rescue
        message.reject(requeue: false)
      end
    end
  end
end
