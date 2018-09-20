# frozen_string_literal: true
module Valkyrie::Sequel
  class MetadataAdapter
    attr_reader :user, :password, :host, :port, :database
    def initialize(user:, password:, host:, port:, database:)
      @user = user
      @password = password
      @host = host
      @port = port
      @database = database
    end

    def persister; end

    def query_service; end

    def id; end

    def perform_migrations!(drop: false)
      Sequel.extension :migration
      drop_database! if drop
      create_database!
      Sequel::Migrator.run(connection, "db/migrations")
    end

    def reset_database!
      perform_migrations!(drop: true)
    end

    def drop_database!
      migration_connection.execute "DROP DATABASE IF EXISTS #{database}"
    end

    def create_database!
      migration_connection.execute "CREATE DATABASE #{database}"
    rescue Sequel::DatabaseError
      nil
    end

    def connection
      @connection ||= Sequel.connect(adapter: :postgres, user: user, password: password, host: host, port: port, database: database).tap do |connection|
        connection.extension(:pg_json)
      end
    end

    private

      def migration_connection
        @migration_connection ||= Sequel.connect(adapter: :postgres, user: user, password: password, host: host, port: port, database: 'postgres')
      end
  end
end
