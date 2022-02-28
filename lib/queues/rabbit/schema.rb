# frozen_string_literal: true

module Queues
  module Rabbit
    class Schema
      include ActiveModel::Model
      attr_accessor :exchanges, :queues

      class << self
        attr_accessor :exchanges, :queues

        def exchange(klass)
          self.exchanges ||= []
          self.exchanges << klass
        end

        def queue(klass)
          self.queues ||= []
          self.queues << klass
        end
      end
    end
  end
end
