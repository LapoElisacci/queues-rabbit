# <img src="https://user-images.githubusercontent.com/50866745/156147715-d3773642-68c0-48c0-92ad-0ccc442ee881.svg" width="48"> Rails-Queues Rabbit

A Rails implementation of [RabbitMQ](https://www.rabbitmq.com/)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'queues-rabbit'
```

And then execute:

```
bundle install
```

## Getting Started

The gem gets shipped with a scaffolding generator.

```
rails generate queues_rabbit
```

## Architecture

The framework consists of a Schema where you can register your RabbitMQ Queues and Exchanges.

```
app
└── queues
    ├── application_queue.rb
    └── rabbit
        ├── exchanges
        │   └── my_exchange.rb
        ├── queues
        │   └── my_queue.rb
        └── schema.rb
```

## Rails-Queues

The gem belongs to the [Rails-Queues](https://github.com/LapoElisacci/queues) framework.

To initialize your Rabbit schema, add it to the `ApplicationQueue` class.

```Ruby
class ApplicationQueue < Queues::API
  rabbit Rabbits::Schema, 'amqp://guest:guest@localhost'
end
```

You can have as many RabbitMQ instances to connect to as you want.

Each RabbitMQ instance must be attached to a specific Schema.

```Ruby
class ApplicationQueue < Queues::API
  rabbit Rabbits::SchemaOne, 'amqp://guest:guest@localhost1'
  rabbit Rabbits::SchemaTwo, 'amqp://guest:guest@localhost2'
end
```

## Schema

The Schema allows you to regiter both the queues and the exchanges.

```Ruby
module Rabbits
  class Schema < ::Queues::Rabbit::Schema
    queue Rabbits::Queues::MyQueue
    exchange Rabbits::Queues::MyExchange
  end
end
```

You can register as many queues and exchanges as you need.

```Ruby
module Rabbits
  class Schema < ::Queues::Rabbit::Schema
    queue Rabbits::Queues::MyQueueOne
    exchange Rabbits::Queues::MyExchangeOne
    
    queue Rabbits::Queues::MyQueueTwo
    exchange Rabbits::Queues::MyExchangeTwo
  end
end
```

## Queues

Each queue can be declared by a class that inherits from `Queues::Rabbit::Queue`

### Definition

```Ruby
module Rabbits
  module Queues
    class MyQueue < ::Queues::Rabbit::Queue
      queue 'my.queue',
            auto_ack: true,
            auto_delete: false,
            durable: true,
            prefetch: 1,
            arguments: {}
      
      # ...
    end
  end
end
```

The `queue` method allows you to define the RabbitMQ queue parameters.

- The queue name
- **auto_ack:** When false messages have to be manually acknowledged (or rejected)
- **auto_delete:** If true, the queue will be deleted when the last consumer stops consuming.
- **durable:** If true, the queue will survive broker restarts, messages in the queue will only survive if they are published as persistent.
- **prefetch:** Specify how many messages to prefetch for consumers (with no_ack is false)
- **arguments:** Custom arguments, such as queue-ttl etc.

Params **durable**, **auto_delete** and **arguments** are optional, default values are:
- **durable:** true
- **auto_delete:** false
- **arguments:** {}

(Remember to register the queue class to the Schema, more details [here](#schema))

### Consuming

To compute a message when it gets received, define a method called `consume` inside your queue Class, like so:

```Ruby
module Rabbits
  module Queues
    class MyQueue < ::Queues::Rabbit::Queue
      queue 'my.queue',
            auto_ack: true,
            auto_delete: false,
            durable: true,
            prefetch: 1,
            arguments: {}
      
      def consume(message)
        # do something with the message
      end
    end
  end
end
```

The messange param is a `Queues::Rabbit::Message` instance where you can access the following properties:

- **body:** The message body.
- **consumer_tag:** The RabbitMQ consumer associated tag.
- **delivery_tag:** The RabbitMQ delivery tag.
- **exchange:** The exchange name (Empty for default exchange).

The `Queues::Rabbit::Message` also implements a few interesting methods:

- **ack:** Allows you to manually acknoledge the message (When **auto_ack** is set to **false**)
- **reject:** Allows you to manually reject a message (it accepts an argument **requeue** that if true the message will be put back into the queue)

```Ruby
module Rabbits
  module Queues
    class MyQueue < ::Queues::Rabbit::Queue
      queue 'my.queue',
            auto_ack: false,
      
      def consume(message)
        puts message.body
        message.ack
      rescue
        message.reject(requeue: false)
      end
    end
  end
end
```

### WARNING

The **consume** method will get executed inside a separated thread, make sure it's threadsafe!

### Publishing

To publish a message into a declared queue, call the **publish** method:

```Ruby
Rabbits::Queues::MyQueue.publish({ foo: 'bar' }.to_json, content_type: 'application/json')
```

The **publish** method accepts several options, here's the method documentation:

```Ruby
# @param [String] body                                The message body, can be a string or either a byte array
# @param [Hash] properties Request properties
# @option properties [String] :app_id                  Used to identify the app that generated the message
# @option properties [String] :content_encoding        Content encoding of the body
# @option properties [String] :content_type            Content type of the body
# @option properties [Integer] :correlation_id         The correlation id, mostly used used for RPC communication
# @option properties [Integer] :delivery_mode          2 for persistent messages, all other values are for transient messages
# @option properties [Integer, String] :expiration     Number of seconds the message will stay in the queue
# @option properties [Hash<String, Object>] :headers   Custom headers
# @option properties [Boolean] :mandatory              The message will be returned if the message can't be routed to a queue
# @option properties [String] :message_id              Can be used to uniquely identify the message, e.g. for deduplication
# @option properties [Boolean] :persistent             Same as delivery_mode: 2
# @option properties [Integer] :priority               The message priority (between 0 and 255)
# @option properties [String] :reply_to                Queue to reply RPC responses to
# @option properties [Date] :timestamp                 Often used for the time the message was originally generated
# @option properties [String] :type                    Can indicate what kind of message this is
# @option properties [String] :user_id                 Used to identify the user that published the message
#
# @return [Boolean] true if published, false otherwise
#
def publish(body, **properties)
```

### Exchange unbinding

Check how to bind an exchange to a queue if needed, [here]()

To unbid a queue from a RabbitMQ exchange, call the **unbind** method, like so:

```Ruby
Rabbits::Queues::MyQueue.unbind('my.exchange', 'my.binding.key', arguments: {})
```

### Purge

To purge all messages from a defined queue, call the **purge** method, like so:

```Ruby
Rabbits::Queues::MyQueue.purge
```

### Delete

To delete a queue from RabbitMQ, call the **delete** method, like so:

```Ruby
Rabbits::Queues::MyQueue.delete
```

## Exchanges

Just like queues, exchanges must be declared by a class that inherits, this time, from `Queues::Rabbit::Exchange`

### Definition

```Ruby
module Rabbits
  module Exchanges
    class MyExchange < ::Queues::Rabbit::Exchange
      exchange 'my.exchange', 'direct',
                              auto_delete: false,
                              durable: true,
                              internal: false,
                              arguments: {}
    end
  end
end
```

The `exchange` method allows you to define the RabbitMQ exchange parameters.

- The exchange name
- The exchange type ('direct', 'fanout', 'headers', 'topic' ...)
- **auto_delete:** If true, the exchange will be deleted when the last queue/exchange gets unbounded.
- **durable:** If true, the exchange will persist between broker restarts, also a required for persistent messages.
- **internal:** If true, the messages can't be pushed directly to the exchange.
- **arguments:** Custom exchange arguments.

(Remember to register the exchange class to the Schema, more details [here](#schema))

### Queue binding

To bind a queue to an exchange, call the **bind** method inside the queue class, like so:

```Ruby
module Rabbits
  module Queues
    class MyQueue < ::Queues::Rabbit::Queue
      queue 'my.queue',
            auto_ack: true,
            auto_delete: false,
            durable: true,
            prefetch: 1,
            arguments: {}
      
      bind Rabbits::Exchanges::MyExchange, 'my.binding.key', arguments: {}
      
      # ...
    end
  end
end
```

You can also statically declare the exchange name, like so:

```Ruby
bind 'my.exchange', 'my.binding.key', arguments: {}
```

The `bind` method allows you to define the RabbitMQ queue-exchange binding parameters.

- The exchange name
- The binding key
- **arguments:** Message headers to match on (only relevant for header exchanges)

### Exchange binding

To bind an exchange to another exchange, call the **bind** method inside the exchange class, like so:

```Ruby
module Rabbits
  module Exchanges
    class MyExchange < ::Queues::Rabbit::Exchange
      exchange 'my.exchange', 'direct',
                              auto_delete: false,
                              durable: true,
                              internal: false,
                              arguments: {}
      
      bind Rabbits::Exchanges::MyExchangeTwo, 'my.binding.key', arguments: {}
    end
  end
end
```

### Publishing

To publish a message to an exchange call the **publish** method, like so:

```Ruby
Rabbits::Exchanges::MyExchange.publish('my message', 'my.routing.key', properties: {})
```

The **publish** method accepts several options, here's the method documentation:

```Ruby
# @param [String] body                                 The message body, can be a string or either a byte array
# @param [String] routing_key                          The routing key to route the message to bounded queues
# @param [Hash] properties Request properties
# @option properties [String] :app_id                  Used to identify the app that generated the message
# @option properties [String] :content_encoding        Content encoding of the body
# @option properties [String] :content_type            Content type of the body
# @option properties [Integer] :correlation_id         The correlation id, mostly used used for RPC communication
# @option properties [Integer] :delivery_mode          2 for persistent messages, all other values are for transient messages
# @option properties [Integer, String] :expiration     Number of seconds the message will stay in the queue
# @option properties [Hash<String, Object>] :headers   Custom headers
# @option properties [Boolean] :mandatory              The message will be returned if the message can't be routed to a queue
# @option properties [String] :message_id              Can be used to uniquely identify the message, e.g. for deduplication
# @option properties [Boolean] :persistent             Same as delivery_mode: 2
# @option properties [Integer] :priority               The message priority (between 0 and 255)
# @option properties [String] :reply_to                Queue to reply RPC responses to
# @option properties [Date] :timestamp                 Often used for the time the message was originally generated
# @option properties [String] :type                    Can indicate what kind of message this is
# @option properties [String] :user_id                 Used to identify the user that published the message
#
# @return [Boolean] true if published, false otherwise
#
def publish(body, routing_key, **properties)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/LapoElisacci/queues-rabbit.

## Credits

The gem is based on the amazing RabbitMQ client by [cloudamqp](https://github.com/cloudamqp/amqp-client.rb).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
