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
  reset_tracking_state
  env = build_rack_environment(method, path, query_string)
  middleware = create_middleware_with_mocks

  execute_middleware_request(middleware, env)
end

def reset_tracking_state
  @tracking_enabled = false
  @tracking_session_created = false
  @tracking_metadata = {}
  @error_logged = false
  # NOTE: don't reset @force_tracking_error as it's set by Given step
end

def build_rack_environment(method, path, query_string)
  {
    "REQUEST_METHOD" => method,
    "PATH_INFO" => path,
    "QUERY_STRING" => query_string,
    "REMOTE_ADDR" => "127.0.0.1",
    "HTTP_USER_AGENT" => "Test Browser"
  }
end

def create_middleware_with_mocks
  app = create_test_app
  middleware = Dbwatcher::Middleware.new(app)
  setup_mocks(middleware)
  middleware
end

def create_test_app
  proc { |_env| [200, {}, ["OK"]] }
end

def execute_middleware_request(middleware, env)
  response = middleware.call(env)
  handle_middleware_response(response)
rescue StandardError => e
  handle_middleware_error(e)
end

def handle_middleware_response(response)
  return build_null_response_error if response.nil?

  build_success_response(response)
end

def build_success_response(response)
  {
    status: response[0],
    headers: response[1],
    body: response[2]
  }
end

def handle_middleware_error(error)
  log_middleware_error(error)
  build_error_response(error.message)
end

def log_middleware_error(error)
  puts "Error in middleware: #{error.message}"
  puts error.backtrace.first(5).join("\n")
end

def build_null_response_error
  puts "Response is nil - middleware didn't return anything"

  {
    status: 500,
    headers: {},
    body: ["No response from middleware"]
  }
end

def build_error_response(message)
  {
    status: 500,
    headers: {},
    body: ["Error: #{message}"]
  }
end

def setup_mocks(middleware)
  setup_tracking_mock
  setup_warning_mock(middleware)
end

private

def setup_tracking_mock
  if @force_tracking_error
    setup_error_tracking_mock
  else
    setup_successful_tracking_mock
  end
end

def setup_error_tracking_mock
  allow(Dbwatcher).to receive(:track).and_raise(StandardError, "Simulated tracking error")
end

def setup_successful_tracking_mock
  allow(Dbwatcher).to receive(:track) do |options, &block|
    capture_tracking_metadata(options)
    execute_tracked_block(block)
  end
end

def capture_tracking_metadata(options)
  @tracking_enabled = true
  @tracking_session_created = true
  @tracking_metadata = options[:metadata] if options
end

def execute_tracked_block(block)
  if block_given?
    block.call
  else
    # Return a default response if no block given
    [200, {}, ["OK"]]
  end
end

def setup_warning_mock(middleware)
  allow(middleware).to receive(:warn) do |message|
    @error_logged = true
    puts "Warning logged: #{message}"
  end
end
