# frozen_string_literal: true
module Valkyrie::Sequel
  class ResourceFactory::ResourceConverter
    PRIMARY_TERMS = [
      :id,
      :created_at,
      :updated_at,
      :internal_resource
    ].freeze

    DISALLOWED_TERMS = [
      :new_record
    ].freeze

    attr_reader :resource, :resource_factory
    delegate :orm_class, :adapter, to: :resource_factory
    delegate :resources, to: :adapter
    def initialize(resource, resource_factory:)
      @resource = resource
      @resource_factory = resource_factory
    end

    def convert!
      output = database_hash
      output[:id] = resource.id.to_s if resource.id
      process_lock_token(output)
      output
    end

    private

    # Retrieves the optimistic lock token from the Valkyrie attribute value and
    #   sets it to the lock_version on ORM resource
    # @see https://api.rubyonrails.org/classes/ActiveRecord/Locking/Optimistic.html
    # @param [ORM::Resource] orm_object
    def process_lock_token(orm_object)
      return unless resource.respond_to?(Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK)
      postgres_token = (resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK] || []).find do |token|
        token.adapter_id == resource_factory.adapter_id
      end
      return unless postgres_token
      orm_object[:lock_version] = postgres_token.token
    end

    def database_hash
      resource_hash.select do |k, _v|
        PRIMARY_TERMS.include?(k)
      end.compact.merge(
        metadata: ::Sequel.pg_json(metadata_hash)
      )
    end

    def resource_hash
      @resource_hash ||= resource.__attributes__
    end

    # Convert attributes to all be arrays to better enable querying and
    # "changing of minds" later on.
    # @return [Hash]
    def metadata_hash
      Hash[
        selected_resource_attributes.compact.map do |k, v|
          [k, Array.wrap(v)]
        end
      ]
    end

    def selected_resource_attributes
      resource_hash.select do |k, _v|
        !PRIMARY_TERMS.include?(k) && !DISALLOWED_TERMS.include?(k)
      end
    end
  end
end
