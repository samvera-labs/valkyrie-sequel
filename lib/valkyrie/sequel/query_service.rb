# frozen_string_literal: true
module Valkyrie::Sequel
  class QueryService
    ACCEPTABLE_UUID = %r{\A(\{)?([a-fA-F0-9]{4}-?){8}(?(1)\}|)\z}
    attr_reader :adapter
    delegate :resources, :resource_factory, :connection, to: :adapter
    def initialize(adapter:)
      @adapter = adapter
    end

    def find_all
      resources.use_cursor.lazy.map do |attributes|
        resource_factory.to_resource(object: attributes)
      end
    end

    def find_by(id:)
      id = Valkyrie::ID.new(id.to_s) if id.is_a?(String)
      validate_id(id)
      raise Valkyrie::Persistence::ObjectNotFoundError unless ACCEPTABLE_UUID.match?(id.to_s)
      attributes = resources.first(id: id.to_s)
      raise Valkyrie::Persistence::ObjectNotFoundError unless attributes
      resource_factory.to_resource(object: attributes)
    end

    def find_all_of_model(model:)
      resources.where(internal_resource: model.to_s).map do |attributes|
        resource_factory.to_resource(object: attributes)
      end
    end

    def find_many_by_ids(ids:)
      ids = ids.map do |id|
        id = Valkyrie::ID.new(id.to_s) if id.is_a?(String)
        validate_id(id)
        id.to_s
      end
      ids = ids.select do |id|
        ACCEPTABLE_UUID.match?(id)
      end

      resources.where(id: ids).map do |attributes|
        resource_factory.to_resource(object: attributes)
      end
    end

    def find_references_by(resource:, property:)
      return [] if resource.id.blank? || resource[property].blank?
      # only return ordered if needed to avoid performance penalties
      if ordered_property?(resource: resource, property: property)
        run_query(find_ordered_references_query, property.to_s, resource.id.to_s)
      else
        run_query(find_references_query, property.to_s, resource.id.to_s)
      end
    end

    def find_inverse_references_by(resource: nil, id: nil, property:)
      raise ArgumentError, "Provide resource or id" unless resource || id
      ensure_persisted(resource) if resource
      id ||= resource.id
      internal_array = { property => [id: id.to_s] }
      run_query(find_inverse_references_query, internal_array.to_json)
    end

    # Find and a record using a Valkyrie ID for an alternate ID, and construct
    #   a Valkyrie Resource
    # @param [Valkyrie::ID] alternate_identifier
    # @return [Valkyrie::Resource]
    def find_by_alternate_identifier(alternate_identifier:)
      alternate_identifier = Valkyrie::ID.new(alternate_identifier.to_s) if alternate_identifier.is_a?(String)
      validate_id(alternate_identifier)
      internal_array = { alternate_ids: [{ id: alternate_identifier.to_s }] }
      run_query(find_inverse_references_query, internal_array.to_json).first || raise(Valkyrie::Persistence::ObjectNotFoundError)
    end

    def find_members(resource:, model: nil)
      return [] if resource.id.blank?
      if model
        run_query(find_members_with_type_query, resource.id.to_s, model.to_s)
      else
        run_query(find_members_query, resource.id.to_s)
      end
    end

    def find_parents(resource:)
      find_inverse_references_by(resource: resource, property: :member_ids)
    end

    # Constructs a Valkyrie::Persistence::CustomQueryContainer using this query service
    # @return [Valkyrie::Persistence::CustomQueryContainer]
    def custom_queries
      @custom_queries ||= ::Valkyrie::Persistence::CustomQueryContainer.new(query_service: self)
    end

    def run_query(query, *args)
      connection[query, *args].map do |result|
        resource_factory.to_resource(object: result)
      end
    end

    private

      # Generate the SQL query for retrieving member resources in PostgreSQL using a
      #   resource ID as an argument.
      # @see https://guides.rubyonrails.org/active_record_querying.html#array-conditions
      # @note this uses a CROSS JOIN for all combinations of member IDs with the
      #   IDs of their parents
      # @see https://www.postgresql.org/docs/current/static/queries-table-expressions.html#QUERIES-FROM
      # This also uses JSON functions in order to retrieve JSON property values
      # @see https://www.postgresql.org/docs/current/static/functions-json.html
      # @return [String]
      def find_members_query
        <<-SQL
          SELECT member.* FROM orm_resources a,
          jsonb_array_elements(a.metadata->'member_ids') WITH ORDINALITY AS b(member, member_pos)
          JOIN orm_resources member ON (b.member->>'id')::#{id_type} = member.id WHERE a.id = ?
          ORDER BY b.member_pos
        SQL
      end

      # Generate the SQL query for retrieving member resources in PostgreSQL using a
      #   resource ID and resource type as arguments.
      # @see https://guides.rubyonrails.org/active_record_querying.html#array-conditions
      # @note this uses a CROSS JOIN for all combinations of member IDs with the
      #   IDs of their parents
      # @see https://www.postgresql.org/docs/current/static/queries-table-expressions.html#QUERIES-FROM
      # This also uses JSON functions in order to retrieve JSON property values
      # @see https://www.postgresql.org/docs/current/static/functions-json.html
      # @return [String]
      def find_members_with_type_query
        <<-SQL
          SELECT member.* FROM orm_resources a,
          jsonb_array_elements(a.metadata->'member_ids') WITH ORDINALITY AS b(member, member_pos)
          JOIN orm_resources member ON (b.member->>'id')::#{id_type} = member.id WHERE a.id = ?
          AND member.internal_resource = ?
          ORDER BY b.member_pos
        SQL
      end

      # Generate the SQL query for retrieving member resources in PostgreSQL using a
      #   JSON object literal as an argument (e. g. { "alternate_ids": [{"id": "d6e88f80-41b3-4dbf-a2a0-cd79e20f6d10"}] }).
      # @see https://guides.rubyonrails.org/active_record_querying.html#array-conditions
      # This uses JSON functions in order to retrieve JSON property values
      # @see https://www.postgresql.org/docs/current/static/functions-json.html
      # @return [String]
      def find_inverse_references_query
        <<-SQL
          SELECT * FROM orm_resources WHERE
          metadata @> ?
        SQL
      end

      # Generate the SQL query for retrieving member resources in PostgreSQL using a
      #   JSON object literal and resource ID as arguments.
      # @see https://guides.rubyonrails.org/active_record_querying.html#array-conditions
      # @note this uses a CROSS JOIN for all combinations of member IDs with the
      #   IDs of their parents
      # @see https://www.postgresql.org/docs/current/static/queries-table-expressions.html#QUERIES-FROM
      # This also uses JSON functions in order to retrieve JSON property values
      # @see https://www.postgresql.org/docs/current/static/functions-json.html
      # @return [String]
      def find_references_query
        <<-SQL
          SELECT DISTINCT member.* FROM orm_resources a,
          jsonb_array_elements(a.metadata->?) AS b(member)
          JOIN orm_resources member ON (b.member->>'id')::#{id_type} = member.id WHERE a.id = ?
        SQL
      end

      def find_ordered_references_query
        <<-SQL
          SELECT member.* FROM orm_resources a,
          jsonb_array_elements(a.metadata->?) WITH ORDINALITY AS b(member, member_pos)
          JOIN orm_resources member ON (b.member->>'id')::#{id_type} = member.id WHERE a.id = ?
          ORDER BY b.member_pos
        SQL
      end

      # Accesses the data type in PostgreSQL used for the primary key
      # (For example, a UUID)
      # @see https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaCache.html#method-i-columns_hash
      # @return [Symbol]
      def id_type
        @id_type ||= :uuid
      end

      # Determines whether or not an Object is a Valkyrie ID
      # @param [Object] id
      # @raise [ArgumentError]
      def validate_id(id)
        raise ArgumentError, 'id must be a Valkyrie::ID' unless id.is_a? Valkyrie::ID
      end

      # Determines whether or not a resource has been persisted
      # @param [Object] resource
      # @raise [ArgumentError]
      def ensure_persisted(resource)
        raise ArgumentError, 'resource is not saved' unless resource.persisted?
      end

      def ordered_property?(resource:, property:)
        resource.ordered_attribute?(property)
      end
  end
end
