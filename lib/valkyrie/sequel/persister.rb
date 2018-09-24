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
      resource_factory.to_resource(object: find(id: output))
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
    end

    def wipe!
      resources.delete
    end

    private

      def create_or_update(resource:, attributes:)
        attributes[:updated_at] = Sequel.function(:NOW)
        return resources.insert(attributes) unless resource.persisted?
        relation = resources.where(id: attributes[:id])
        if resource.optimistic_locking_enabled?
          relation = relation.where(lock_version: attributes[:lock_version]) if attributes[:lock_version]
          attributes[:lock_version] = (Sequel[:lock_version] + 1)
        end
        attributes.delete(:lock_version) if attributes[:lock_version].nil?
        output = relation.update(attributes)
        raise Valkyrie::Persistence::StaleObjectError, "The object #{resource.id} has been updated by another process." if output.zero?
        attributes[:id]
      end

      def find(id:)
        resources.first(id: id)
      end
  end
end
