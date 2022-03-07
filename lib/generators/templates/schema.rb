# frozen_string_literal: true

module Rabbits
  class Schema < ::Queues::Rabbit::Schema
    queue Rabbits::Queues::MyQueue
    batched_queue Rabbits::Queues::MyBatchedQueue
    exchange Rabbits::Exchanges::MyExchange
  end
end
