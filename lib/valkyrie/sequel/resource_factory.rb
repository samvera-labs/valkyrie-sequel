# frozen_string_literal: true
module Valkyrie::Sequel
  class ResourceFactory
    require 'valkyrie/sequel/resource_factory/resource_converter'
    require 'valkyrie/sequel/resource_factory/orm_converter'
    attr_reader :adapter
    delegate :id, to: :adapter, prefix: true
    def initialize(adapter:)
      @adapter = adapter
    end

    def to_resource(object:)
      ORMConverter.new(object, resource_factory: self).convert!
    end

    def from_resource(resource:)
      ResourceConverter.new(resource, resource_factory: self).convert!
    end

    def orm_class
      adapter.resources
    end
  end
end
