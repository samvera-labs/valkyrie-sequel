# frozen_string_literal: true
module Valkyrie::Sequel
  require 'valkyrie/sequel/resource_factory'
  require 'valkyrie/sequel/query_service'
  require 'valkyrie/sequel/persister'
  class MetadataAdapter
    attr_reader :user, :password, :host, :port, :database
    def initialize(user:, password:, host:, port:, database:)
      @user = user
      @password = password
      @host = host
      @port = port
      @database = database
    end

    def persister
      @persister ||= Persister.new(adapter: self)
    end

    def query_service
      @query_service ||= QueryService.new(adapter: self)
    end

    def resource_factory
      @resource_factory ||= ResourceFactory.new(adapter: self)
    end

    def id
      @id ||= begin
        to_hash = "sequel://#{host}:#{port}:#{database}"
        Valkyrie::ID.new(Digest::MD5.hexdigest(to_hash))
      end
    end

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

    def resources
      connection.from(:orm_resources)
    end

    private

      def migration_connection
        @migration_connection ||= Sequel.connect(adapter: :postgres, user: user, password: password, host: host, port: port, database: 'postgres')
      end
  end
end
