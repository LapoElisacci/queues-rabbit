# frozen_string_literal: true

RSpec.describe Queues::Rabbit do
  it 'has a version number' do
    expect(Queues::Rabbit::VERSION).not_to be nil
  end
end
