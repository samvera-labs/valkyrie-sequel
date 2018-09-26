# frozen_string_literal: true
module Valkyrie::Sequel
  require 'valkyrie/sequel/resource_factory'
  require 'valkyrie/sequel/query_service'
  require 'valkyrie/sequel/persister'
  class MetadataAdapter
    attr_reader :connection
    def initialize(connection:)
      @connection = connection.tap do |conn|
        conn.extension(:pg_json)
        conn.extension(:pg_streaming)
      end
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

    def perform_migrations!
      Sequel.extension :migration
      Sequel::Migrator.run(connection, "#{__dir__}/../../../db/migrations")
    end

    def reset_database!
      perform_migrations!
    end

    def resources
      connection.from(:orm_resources)
    end

    private

      def host
        connection.opts[:host]
      end

      def port
        connection.opts[:port]
      end

      def database
        connection.opts[:database]
      end
  end
end
