# frozen_string_literal: true

module Queues
  module Rabbit
    class Message < AMQP::Client::Message
      def initialize(message)
        message.instance_variables.each do |variable|
          instance_variable_set(variable, message.instance_variable_get(variable))
        end
      end
    end
  end
end
