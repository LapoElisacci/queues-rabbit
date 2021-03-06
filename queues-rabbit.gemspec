# frozen_string_literal: true

require_relative 'lib/queues/rabbit/version'

Gem::Specification.new do |spec|
  spec.name = 'queues-rabbit'
  spec.version = Queues::Rabbit::VERSION
  spec.authors = ['Lapo']
  spec.email = ['lapoelisacci@gmail.com']

  spec.summary = 'A Rails implementation of RabbitMQ'
  spec.description = 'The gem allows you to integrate RabbitMQ into a Rails application in a Ruby Style fashion.'
  spec.homepage = 'https://github.com/LapoElisacci/queues.git'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/LapoElisacci/queues-rabbit.git'
  spec.metadata['changelog_uri'] = 'https://github.com/LapoElisacci/queues-rabbit/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'amqp-client', '~> 1'
  spec.add_dependency 'queues', '0.1.0.beta'
end
