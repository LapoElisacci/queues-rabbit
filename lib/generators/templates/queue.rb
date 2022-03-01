# frozen_string_literal: true

module Rabbits
  module Queues
    class MyQueue < ::Queues::Rabbit::Queue
      queue 'my.queue', durable: true, auto_delete: false, arguments: {}

      def consume(message)
        # do something with the message
        message.ack
      rescue
        message.reject(requeue: false)
      end
    end
  end
end
