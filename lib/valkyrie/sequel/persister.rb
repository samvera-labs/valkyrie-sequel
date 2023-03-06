# frozen_string_literal: true
module Valkyrie::Sequel
  class Persister
    attr_reader :adapter
    delegate :resource_factory, to: :adapter
    delegate :resources, :connection, to: :adapter
    def initialize(adapter:)
      @adapter = adapter
    end

    def save(resource:, external_resource: false)
      object_attributes = resource_factory.from_resource(resource: resource)
      output = create_or_update(resource: resource, attributes: object_attributes, external_resource: external_resource)
      resource_factory.to_resource(object: output)
    end

    def save_all(resources:)
      connection.transaction do
        output = SaveAllPersister::Factory.new(persister: self).for(resources: resources).persist!
        raise Valkyrie::Persistence::StaleObjectError, "One or more resources have been updated by another process." if output.length != resources.length
        output.map do |object|
          resource_factory.to_resource(object: object)
        end
      end
    end

    class SaveAllPersister
      class Factory
        delegate :adapter, to: :persister
        delegate :resource_factory, to: :adapter
        delegate :resources, to: :adapter
        attr_reader :persister
        def initialize(persister:)
          @persister = persister
        end

        # Resources have to be handled differently based on whether or not
        # optimistic locking is enabled. Splitting it into two upserts allows
        # for faster save_all while still handling optimistic locking.
        def for(resources:)
          grouped_resources = resources.group_by(&:optimistic_locking_enabled?)
          locked_resources = grouped_resources[true] || []
          unlocked_resources = grouped_resources[false] || []

          CompositePersister.new(
            [
              SaveAllPersister.new(resources: locked_resources, relation: locking_relation, resource_factory: resource_factory),
              SaveAllPersister.new(resources: unlocked_resources, relation: relation, resource_factory: resource_factory)
            ]
          )
        end

        def relation
          resources.returning.insert_conflict(
            target: :id,
            update: update_branches
          )
        end

        # Locking relation has an update_where condition.
        def locking_relation
          resources.returning.insert_conflict(
            target: :id,
            update: update_branches,
            update_where: { Sequel.function(:coalesce, Sequel[:orm_resources][:lock_version], 0) => Sequel[:excluded][:lock_version] }
          )
        end

        def update_branches
          {
            metadata: Sequel[:excluded][:metadata],
            internal_resource: Sequel[:excluded][:internal_resource],
            lock_version: Sequel.function(:coalesce, Sequel[:excluded][:lock_version], 0) + 1,
            created_at: Sequel[:excluded][:created_at],
            updated_at: Time.now.utc
          }
        end
      end
      attr_reader :resources, :relation, :resource_factory
      def initialize(resources:, relation:, resource_factory:)
        @resources = resources
        @relation = relation
        @resource_factory = resource_factory
      end

      def persist!
        return [] if resources.empty?
        Array.wrap(
          relation.multi_insert(converted_resources)
        )
      end

      def converted_resources
        @converted_resources ||= resources.map do |resource|
          output = resource_factory.from_resource(resource: resource)
          output[:lock_version] ||= 0
          output[:created_at] ||= Time.now.utc
          output[:updated_at] ||= Time.now.utc
          output
        end
      end

      class CompositePersister
        attr_reader :persisters
        def initialize(persisters)
          @persisters = persisters
        end

        def persist!
          persisters.flat_map(&:persist!)
        end
      end
    end

    def delete(resource:)
      resources.where(id: resource.id.to_s).delete
      resource
    end

    def wipe!
      resources.delete
    end

    private

    def create_or_update(resource:, attributes:, external_resource:)
      attributes[:updated_at] = Time.now.utc
      attributes[:created_at] ||= Time.now.utc
      if exists?(id: attributes[:id])
        update(resource: resource, attributes: attributes)
      else
        if !external_resource && resource.persisted?
          # This resource has been deleted in the meantime, error.
          raise Valkyrie::Persistence::ObjectNotFoundError, "The object #{resource.id} is previously persisted but not found at save time." unless exists?(id: attributes[:id])
        end
        create(resource: resource, attributes: attributes)
      end
    end

    def create(resource:, attributes:)
      attributes[:lock_version] = 0 if resource.optimistic_locking_enabled? && resources.columns.include?(:lock_version)
      Array(resources.returning.insert(attributes)).first # rubocop:disable Rails/SkipsModelValidations
    end

    def update(resource:, attributes:)
      relation = resources.where(id: attributes[:id])
      if resource.optimistic_locking_enabled?
        relation = relation.where(Sequel.function(:coalesce, :lock_version, 0) => attributes[:lock_version] || 0)
        attributes[:lock_version] = (Sequel.function(:coalesce, :lock_version, 0) + 1)
      end
      attributes.delete(:lock_version) if attributes[:lock_version].nil?
      output = relation.returning.update(attributes)
      raise Valkyrie::Persistence::StaleObjectError, "The object #{resource.id} has been updated by another process." if output.blank? && resource.optimistic_locking_enabled?
      Array(output).first
    end

    def exists?(id:)
      !resources.select(1).first(id: id).nil?
    end
  end
end
