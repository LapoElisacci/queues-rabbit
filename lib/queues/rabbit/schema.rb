# frozen_string_literal: true

module Queues
  module Rabbit
    class Schema
      include ActiveModel::Model
      class << self
        attr_accessor :client, :exchanges, :queues

        def client_instance
          @@client_instance ||= client.start
        end

        def exchange(klass)
          self.exchanges ||= []
          self.exchanges << klass
          klass.schema = self
        end

        def queue(klass)
          self.queues ||= []
          self.queues << klass
          klass.schema = self
        end
      end
    end
  end
end
