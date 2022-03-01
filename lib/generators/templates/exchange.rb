# frozen_string_literal: true

module Rabbits
  module Exchanges
    class MyExchange < ::Queues::Rabbit::Exchange
      exchange 'my.exchange', 'my.key', durable: true, auto_delete: false, internal: false, arguments: {}
    end
  end
end
