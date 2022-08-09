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
        attribute :single_value, Valkyrie::Types::Anything
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
    it "saves single values as an array in the database" do
      output = persister.save(resource: TinyResource.new(single_value: "1"))
      database_hash = query_service.resources.where(id: output.id.to_s).first

      expect(database_hash[:metadata]["single_value"]).to eq ["1"]
    end
  end

  describe "save with optimistic locking being turned on later" do
    it "doesn't break" do
      class OptimisticResource < Valkyrie::Resource
      end
      resource = OptimisticResource.new
      object = persister.save(resource: resource)
      class OptimisticResource < Valkyrie::Resource
        enable_optimistic_locking
      end
      result = query_service.find_by(id: object.id)
      expect { persister.save(resource: result) }.not_to raise_error
      result = query_service.find_by(id: object.id)
      expect(result.optimistic_lock_token[0].token).to eq "1"
    end
    it "doesn't break with save_all" do
      class OptimisticResource < Valkyrie::Resource
      end
      resource = OptimisticResource.new
      objects = persister.save_all(resources: [resource])
      class OptimisticResource < Valkyrie::Resource
        enable_optimistic_locking
      end
      result = query_service.find_by(id: objects.first.id)
      expect { persister.save_all(resources: [result]) }.not_to raise_error
      result = query_service.find_by(id: objects.first.id)
      expect(result.optimistic_lock_token[0].token).to eq "1"
    end
    it "doesn't break on a race condition" do
      class OptimisticResource < Valkyrie::Resource
      end
      resource = OptimisticResource.new
      resource = persister.save(resource: resource)
      class OptimisticResource < Valkyrie::Resource
        enable_optimistic_locking
      end

      persister.save(resource: resource)
      expect { persister.save(resource: resource) }.to raise_error Valkyrie::Persistence::StaleObjectError
    end
    it "doesn't break on a race condition via save_all" do
      class OptimisticResource < Valkyrie::Resource
      end
      resource = OptimisticResource.new
      resource = persister.save(resource: resource)
      class OptimisticResource < Valkyrie::Resource
        enable_optimistic_locking
      end

      persister.save_all(resources: [resource])
      expect { persister.save_all(resources: [resource]) }.to raise_error Valkyrie::Persistence::StaleObjectError
    end
    after do
      Object.send(:remove_const, :OptimisticResource)
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
