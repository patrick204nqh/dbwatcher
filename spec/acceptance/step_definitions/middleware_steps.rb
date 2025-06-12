# frozen_string_literal: true

# Middleware tracking steps for testing dbwatch=true functionality

# Request steps
When(/^I make a request to "([^"]*)" without the dbwatch parameter$/) do |path|
  @response = make_request("GET", path, "")
end

When(/^I make a request to "([^"]*)" with "([^"]*)" parameter$/) do |path, query_string|
  @response = make_request("GET", path, query_string)
end

When(/^I make a request to "([^"]*)" with "([^"]*)" parameters$/) do |path, query_string|
  @response = make_request("GET", path, query_string)
end

When(/^I make a "([^"]*)" request to "([^"]*)" with "([^"]*)" parameter$/) do |method, path, query_string|
  @response = make_request(method, path, query_string)
end

# Setup steps
Given(/^the tracking system will raise an error$/) do
  @force_tracking_error = true
end

# Assertion steps for tracking behavior
Then(/^database tracking should be enabled$/) do
  expect(@tracking_enabled).to be true
end

Then(/^database tracking should not be enabled$/) do
  expect(@tracking_enabled).to be false
end

Then(/^the request should complete successfully$/) do
  expect(@response[:status]).to eq(200)
end

Then(/^the request should still complete successfully$/) do
  expect(@response[:status]).to eq(200)
end

Then(/^a tracking session should be created$/) do
  expect(@tracking_session_created).to be true
end

Then(/^a tracking session should be created with "([^"]*)" method$/) do |method|
  expect(@tracking_session_created).to be true
  expect(@tracking_metadata[:method]).to eq(method)
end

Then(/^an error warning should be logged$/) do
  expect(@error_logged).to be true
end

private

def make_request(method, path, query_string)
  # Reset tracking state
  @tracking_enabled = false
  @tracking_session_created = false
  @tracking_metadata = {}
  @error_logged = false
  # Note: don't reset @force_tracking_error as it's set by Given step

  # Create environment hash simulating a Rack request
  env = {
    "REQUEST_METHOD" => method,
    "PATH_INFO" => path,
    "QUERY_STRING" => query_string,
    "REMOTE_ADDR" => "127.0.0.1",
    "HTTP_USER_AGENT" => "Test Browser"
  }

  # Mock app to simulate Rails application
  app = lambda do |_env|
    [200, {}, ["OK"]]
  end

  # Create middleware instance
  middleware = Dbwatcher::Middleware.new(app)

  # Setup mocks before calling middleware
  setup_mocks(middleware)

  # Call the middleware and handle any errors
  begin
    response = middleware.call(env)
    if response.nil?
      puts "Response is nil - middleware didn't return anything"
      return {
        status: 500,
        headers: {},
        body: ["No response from middleware"]
      }
    end
    
    {
      status: response[0],
      headers: response[1],
      body: response[2]
    }
  rescue StandardError => e
    # Return error details for debugging
    puts "Error in middleware: #{e.message}"
    puts e.backtrace.first(5).join("\n")
    {
      status: 500,
      headers: {},
      body: ["Error: #{e.message}"]
    }
  end
end

def setup_mocks(middleware)
  # Mock Dbwatcher.track to capture tracking behavior or raise error
  if @force_tracking_error
    allow(Dbwatcher).to receive(:track).and_raise(StandardError, "Simulated tracking error")
  else
    allow(Dbwatcher).to receive(:track) do |options, &block|
      @tracking_enabled = true
      @tracking_session_created = true
      @tracking_metadata = options[:metadata] if options
      
      # Execute the block if provided (this calls the app)
      if block_given?
        block.call
      else
        # Return a default response if no block given
        [200, {}, ["OK"]]
      end
    end
  end

  # Mock warning to capture error logging
  allow(middleware).to receive(:warn) do |message|
    @error_logged = true
    puts "Warning logged: #{message}"
  end
end
