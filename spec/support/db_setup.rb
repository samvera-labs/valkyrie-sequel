# frozen_string_literal: true
require_relative 'db_connection_info'
CONNECTION = Sequel.connect(DB_CONNECTION_INFO.merge(adapter: :postgres))

METADATA_ADAPTER = Valkyrie::Sequel::MetadataAdapter.new(connection: CONNECTION)
METADATA_ADAPTER.reset_database!
