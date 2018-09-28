# frozen_string_literal: true
module Valkyrie::Sequel
  class Persister
    attr_reader :adapter
    delegate :resource_factory, to: :adapter
    delegate :resources, :connection, to: :adapter
    def initialize(adapter:)
      @adapter = adapter
    end

    def save(resource:)
      object_attributes = resource_factory.from_resource(resource: resource)
      output = create_or_update(resource: resource, attributes: object_attributes)
      resource_factory.to_resource(object: output)
    end

    def save_all(resources:)
      connection.transaction do
        resources.map do |resource|
          save(resource: resource)
        end
      end
    rescue Valkyrie::Persistence::StaleObjectError
      raise Valkyrie::Persistence::StaleObjectError, "One or more resources have been updated by another process."
    end

    def delete(resource:)
      resources.where(id: resource.id.to_s).delete
      resource
    end

    def wipe!
      resources.delete
    end

    private

      def create_or_update(resource:, attributes:)
        attributes[:updated_at] = Time.now.utc
        attributes[:created_at] = Time.now.utc
        return create(resource: resource, attributes: attributes) unless resource.persisted? && !exists?(id: attributes[:id])
        update(resource: resource, attributes: attributes)
      end

      def create(resource:, attributes:)
        attributes[:lock_version] = 0 if resource.optimistic_locking_enabled? && resources.columns.include?(:lock_version)
        Array(resources.returning.insert(attributes)).first
      end

      def update(resource:, attributes:)
        relation = resources.where(id: attributes[:id])
        if resource.optimistic_locking_enabled?
          relation = relation.where(lock_version: attributes[:lock_version]) if attributes[:lock_version]
          attributes[:lock_version] = (Sequel[:lock_version] + 1)
        end
        attributes.delete(:lock_version) if attributes[:lock_version].nil?
        output = relation.returning.update(attributes)
        raise Valkyrie::Persistence::StaleObjectError, "The object #{resource.id} has been updated by another process." if output.blank? && resource.optimistic_locking_enabled?
        Array(output).first
      end

      def exists?(id:)
        resources.select(1).first(id: id).nil?
      end
  end
end
