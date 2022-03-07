# frozen_string_literal: true

module Queues
  module Rabbit
    class Schema
      class << self
        attr_accessor :client, :exchanges, :queues, :batched_queues

        #
        # Return the client instance
        #
        # @return [AMQP::Client] Client instance
        #
        def client_instance
          @@client_instance ||= client.start
        end

        #
        # Register an Exchange
        #
        # @param [Queues::Rabbit::Exchange] klass Exchange class to register
        #
        def exchange(klass)
          self.exchanges ||= []
          self.exchanges << klass
          klass.schema = self
        end

        #
        # Register a Queue
        #
        # @param [Queues::Rabbit::Queue] klass Queue class to register
        #
        def queue(klass)
          self.queues ||= []
          self.queues << klass
          klass.schema = self
        end

        #
        # Register a Batched Queue
        #
        # @param [Queues::Rabbit::BatchedQueue] klass BatchedQueue class to register
        #
        def batched_queue(klass)
          self.batched_queues ||= []
          self.batched_queues << klass
          klass.schema = self
        end
      end
    end
  end
end
