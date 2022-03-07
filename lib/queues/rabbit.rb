# frozen_string_literal: true

require 'active_support'
require 'amqp-client'
require 'logger'

require_relative 'rabbit/client'
require_relative 'rabbit/exchange'
require_relative 'rabbit/logger'
require_relative 'rabbit/message'
require_relative 'rabbit/queue'
require_relative 'rabbit/schema'
require_relative 'rabbit/version'

module Queues
  module Rabbit
    class Error < StandardError; end

    class << self
      attr_accessor :client, :logger, :log_level, :schema

      def configure(schema_klass, host, log_level: ::Logger::INFO)
        self.log_level = log_level
        self.schema = schema_klass
        schema.client = Queues::Rabbit::Client.new(host)
        self
      end
    end
  end
end
