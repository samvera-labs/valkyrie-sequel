# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe Valkyrie::Sequel::Persister do
  subject(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:adapter) { METADATA_ADAPTER }

  it_behaves_like "a Valkyrie::Persister"

  describe ".save" do
    before do
      class TinyResource < Valkyrie::Resource
        attribute :test
      end
    end
    after do
      Object.send(:remove_const, :TinyResource)
    end
    it "doesn't convert strings to symbols" do
      output = persister.save(resource: TinyResource.new(
        test: ":4- 9 r4 ‘9 4, ‘9 ‘0 v7 ‘a 9 &lt;4 0.."
      ))

      expect(output.test.first.class).to eq String
    end
  end

  describe "save_all with optimistic locking" do
    before do
      class OptimisticResource < Valkyrie::Resource
        enable_optimistic_locking
      end
      class NonOptimisticResource < Valkyrie::Resource
        attribute :title
      end
    end
    after do
      Object.send(:remove_const, :OptimisticResource)
      Object.send(:remove_const, :NonOptimisticResource)
    end
    context "when optimistic locking is enabled" do
      context "and nil is passed" do
        it "still updates the lock_version" do
          resource = OptimisticResource.new
          output = persister.save(resource: resource)
          output.send("#{Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK}=", [])
          output = persister.save_all(resources: [output]).first
          expect(output.send(Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK).first.token).to eq "1"
        end
        it "can save over and over again" do
          item = OptimisticResource.new(title: "Test")
          item = persister.save_all(resources: [item]).first
          item = persister.save_all(resources: [item]).first
          persister.save_all(resources: [item]).first
        end
      end
    end
    context "when optimistic locking is disabled" do
      context "and a lock_version is wrong" do
        it "still updates" do
          item = NonOptimisticResource.new(title: "Test")
          item = persister.save(resource: item)
          persister.save_all(resources: [item])
          persister.save_all(resources: [item])
        end
      end
    end
  end
end
