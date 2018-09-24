# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Valkyrie::Sequel::ResourceFactory do
  subject(:resource_factory) { adapter.resource_factory }
  let(:adapter) { METADATA_ADAPTER }

  before do
    class TestResource < Valkyrie::Resource
      attribute :value
    end
  end
  after do
    Object.send(:remove_const, :TestResource)
  end
  describe "#from_resource" do
    it "creates a persistable resource out of a Valkyrie::Resource" do
      resource = TestResource.new(value: "test")

      object = resource_factory.from_resource(resource: resource)

      expect(object[:metadata][:value]).to eq ["test"]
      expect(object[:internal_resource]).to eq "TestResource"
    end
  end
  describe "#to_resource" do
    it "can convert from from_resource" do
      resource = TestResource.new(value: "test")

      object = resource_factory.from_resource(resource: resource)
      reloaded_resource = resource_factory.to_resource(object: object)

      expect(reloaded_resource.value).to eq ["test"]
    end
  end
end
