# frozen_string_literal: true
module Valkyrie::Sequel
  class ResourceFactory::ORMConverter
    attr_reader :object, :resource_factory
    def initialize(object, resource_factory:)
      @object = object
      @resource_factory = resource_factory
    end

    def convert!
      @resource ||= resource
    end

    private

      # Construct a new Valkyrie Resource using the attributes retrieved from the database
      # @return [Valkyrie::Resource]
      def resource
        resource_klass.new(
          attributes.merge(
            new_record: false,
            Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK => lock_token
          )
        )
      end

      # Construct the optimistic lock token using the adapter and lock version for the Resource
      # @return [Valkyrie::Persistence::OptimisticLockToken]
      def lock_token
        @lock_token ||=
          Valkyrie::Persistence::OptimisticLockToken.new(
            adapter_id: resource_factory.adapter_id,
            token: object[:lock_version]
          )
      end

      # Retrieve the Class used to construct the Valkyrie Resource
      # @return [Class]
      def resource_klass
        internal_resource.constantize
      end

      # Access the String for the Valkyrie Resource type within the attributes
      # @return [String]
      def internal_resource
        attributes[:internal_resource]
      end

      def attributes
        @attributes ||= object.except(:metadata).merge(rdf_metadata).symbolize_keys
      end

      # Generate a Hash derived from Valkyrie Resource metadata encoded in the RDF
      # @return [Hash]
      def rdf_metadata
        @rdf_metadata ||= Valkyrie::Persistence::Postgres::ORMConverter::RDFMetadata.new(object[:metadata]).result
      end
  end
end
