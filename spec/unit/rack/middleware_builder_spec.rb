require 'spec_helper'

RSpec.describe Airbrake::Rack::MiddlewareBuilder do
  describe "#build_middleware" do
    it "builds a middleware class for a specific notifier" do
      middleware_class = described_class.new(:bingo).build_middleware

      expect(middleware_class).to be_a(Class)

      instance = middleware_class.new(proc { |env| [200, env, 'Bongo!'] })
      expect(instance.inspect).to eq('<class:Airbrake::Rack::Middleware {for: :bingo}>')
    end

    it "returns a middleware class that notifies via the specified notifier" do
      notifier_name = :bingo
      middleware_class = described_class.new(notifier_name).build_middleware

      middleware = middleware_class.new(proc { raise AirbrakeTestError })
      expect { middleware.call({}) }.to(
        raise_error(
          Airbrake::Error,
          "the '#{notifier_name}' notifier isn't configured"
        )
      )
    end
  end
end
