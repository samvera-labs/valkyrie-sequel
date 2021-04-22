# frozen_string_literal: true
ENV['RACK_ENV'] = 'test'
ENV['RAILS_ENV'] = 'test'
require 'simplecov'
SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
SimpleCov.start do
  add_filter 'spec'
  add_filter 'vendor'
  add_filter 'db'
end

require "bundler/setup"
require "valkyrie/sequel"
require 'pry'
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  Dir[Pathname.new("./").join("spec", "support", "**", "*.rb")].sort.each { |file| require_relative file.gsub(/^spec\//, "") }
end
