# frozen_string_literal: true
require 'database_cleaner'
require_relative 'db_setup'
RSpec.configure do |config|
  sequel_cleaner = DatabaseCleaner[:sequel, { connection: METADATA_ADAPTER.connection }]
  config.before(:suite) do
    sequel_cleaner.clean_with(:deletion)
  end

  config.before do
    sequel_cleaner.strategy = :transaction
  end

  config.before(js: true) do
    sequel_cleaner.strategy = :deletion
  end

  config.before do
    sequel_cleaner.start
  end

  config.after do
    sequel_cleaner.clean
  end
end
