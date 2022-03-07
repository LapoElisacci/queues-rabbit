# frozen_string_literal: true

require 'rails/generators'

# Creates the Queues initializer file for Rails apps.
#
# @example Invokation from terminal
#   rails generate queues_rabbit
#
class QueuesRabbitGenerator < Rails::Generators::Base
  desc "Description:\n  This prepares Rails for RabbitMQ Queues"

  source_root File.expand_path('templates', __dir__)

  desc 'Initialize Rails for RabbitMQ Queues'

  def generate_layout
    if !File.exist?('app/queues/application_queue.rb')
      generate 'queues'
    end

    template 'schema.rb', 'app/queues/rabbits/schema.rb'
    template 'queue.rb', 'app/queues/rabbits/queues/my_queue.rb'
    template 'batched_queue.rb', 'app/queues/rabbits/queues/my_batched_queue.rb'
    template 'exchange.rb', 'app/queues/rabbits/exchanges/my_exchange.rb'
  end
end
