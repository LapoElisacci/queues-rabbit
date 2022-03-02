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

      #
      # Log an error with attached report string.
      #
      # @param [String] message Message to log
      #
      def error_with_report(message)
        @logger.error { message }
        @logger.error { 'Please report to https://github.com/LapoElisacci/queues-rabbit if needed.' }
      end

      #
      # Log the passed message to STDOUT
      #
      # @param [String] message Message to log
      # @param [Symbol] level Log level
      #
      def stdout(message, level = :info)
        @std.send(level, message)
      end
    end
  end
end
