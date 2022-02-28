# frozen_string_literal: true

require 'active_model'
require 'active_support'
require 'amqp-client'

require_relative 'rabbit/client'
require_relative 'rabbit/exchange'
require_relative 'rabbit/queue'
require_relative 'rabbit/schema'
require_relative 'rabbit/version'

module Queues
  module Rabbit
    class Error < StandardError; end

    class << self
      attr_accessor :client, :schema

      def configure(schema, host)
        self.schema = schema
        const_set('ClientInstance', Queues::Rabbit::Client.new(host))
        self
      end

      def client_instance
        @@client_instance ||= self::ClientInstance.start
      end
    end
  end
end
