# frozen_string_literal: true

module Rabbits
  module Queues
    class MyBatchedQueue < ::Queues::Rabbit::BatchedQueue
      batched_queue 'my.batched.queue',        # Required
                    batch_size: 2,             # Required
                    batch_timeout: 60.seconds, # Required
                    auto_delete: false,        # Optional
                    durable: true,             # Optional
                    prefetch: 2,               # Optional (must be >= batch_size)
                    arguments: {}              # Optional

      def consume(messages)
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
