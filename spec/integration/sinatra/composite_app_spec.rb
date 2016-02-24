require 'spec_helper'

RSpec.describe "Sinatra application with multiple mounted apps" do
  let(:endpoint) do
    'https://airbrake.io/api/v3/projects/113743/notices?key=fd04e13d806a90f96614ad8e529b2822'
  end

  def env_for(url, opts = {})
    Rack::MockRequest.env_for(url, opts)
  end

  def wait_for_a_request_with_body(body)
    wait_for(a_request(:post, endpoint).with(body: body)).to have_been_made.once
  end

  before do
    stub_request(:post, endpoint).to_return(status: 201, body: '{}')
  end

  context "when both apps use their own notifiers and middlewares" do
    let(:app) do
      Rack::Builder.new do
        map('/app1') do
          use Airbrake::Rack::Middleware.for(SinatraApp1)
          run SinatraApp1.new
        end

        map '/app2' do
          use Airbrake::Rack::Middleware.for(SinatraApp2)
          run SinatraApp2.new
        end
      end
    end

    it "reports errors from SinatraApp1 notifier" do
      get '/app1'
      wait_for_a_request_with_body(
        %r|"backtrace":\[{"file":".+apps/sinatra/composite_app/sinatra_app1.rb"|
      )
    end

    it "reports errors from SinatraApp2 notifier" do
      get '/app2'
      wait_for_a_request_with_body(
        %r|"backtrace":\[{"file":".+apps/sinatra/composite_app/sinatra_app2.rb"|
      )
    end
  end

  context "when app uses default middleware, but configured a named notifier" do
    let(:app) do
      app = Rack::Builder.new do
        use Airbrake::Rack::Middleware

        map '/app1' do
          run SinatraApp1
        end
      end

      Airbrake.configure(SinatraApp1) do |c|
        c.project_id = 113743
        c.project_key = '81bbff95d52f8856c770bb39e827f3f6'
        c.logger = Logger.new(STDOUT)
        c.logger.level = Logger::DEBUG
      end

      app
    end

    before do
      @notifiers = Airbrake.instance_variable_get(:@notifiers)
      Airbrake.instance_variable_set(:@notifiers, {})
    end

    after do
      Airbrake.instance_variable_set(:@notifiers, @notifiers)
    end

    it "raises error" do
      expect { get '/app1' }.
        to raise_error(Airbrake::Error, /the 'default' notifier isn't configured/)
    end
  end
end
