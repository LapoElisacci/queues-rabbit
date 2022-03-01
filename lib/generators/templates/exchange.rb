# frozen_string_literal: true

module Rabbits
  module Exchanges
    class MyExchange < ::Queues::Rabbit::Exchange
      exchange 'my.exchange', 'direct',           # Required
                              durable: true,      # Optional
                              auto_delete: false, # Optional
                              internal: false,    # Optional
                              arguments: {}       # Optional
    end
  end
end
