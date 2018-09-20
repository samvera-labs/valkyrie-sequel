# frozen_string_literal: true
DB_CONNECTION_INFO = {
  user: nil,
  password: nil,
  host: 'localhost',
  port: nil,
  database: 'valkyrie_sequel_test'
}.freeze

Valkyrie::Sequel::MetadataAdapter.new(DB_CONNECTION_INFO).reset_database!
