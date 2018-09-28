# frozen_string_literal: true
DB_CONNECTION_INFO = {
  user: ENV['DB_USERNAME'],
  password: ENV['DB_PASSWORD'],
  host: ENV['DB_HOST'] || 'localhost',
  port: nil,
  database: ENV['DB_DATABASE'] || 'valkyrie_sequel_test'
}.freeze

connection = Sequel.connect(DB_CONNECTION_INFO.merge(adapter: :postgres))

METADATA_ADAPTER = Valkyrie::Sequel::MetadataAdapter.new(connection: connection)
METADATA_ADAPTER.reset_database!
