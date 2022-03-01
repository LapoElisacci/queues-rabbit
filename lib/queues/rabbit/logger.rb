# frozen_string_litteral: true

module Queues
  module Rabbit
    class Logger
      delegate :unknown, :fatal, :error,  :warn, :info, :debug, to: :@logger

      def initialize(name, level)
        @logger = ::Logger.new("log/#{name}.log")
        @logger.level = level
        @std = ::Logger.new(STDOUT)
        @std.level = ::Logger::INFO
      end

      def error_with_report(message)
        @logger.error { message }
        @logger.error { 'Please report to https://github.com/LapoElisacci/queues-rabbit if needed.' }
      end

      def stdout(message)
        @std.info message
      end
    end
  end
end
