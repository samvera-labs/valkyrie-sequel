# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe Valkyrie::Sequel::Persister do
  subject(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:adapter) { METADATA_ADAPTER }

  it_behaves_like "a Valkyrie::Persister"

  describe "save_all with optimistic locking" do
    before do
      class OptimisticResource < Valkyrie::Resource
        enable_optimistic_locking
      end
      class NonOptimisticResource < Valkyrie::Resource
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
      end
    end
    context "when optimistic locking is disabled" do
      context "and a lock_version is wrong" do
        it "still updates" do
          resource = NonOptimisticResource.new
          resource = persister.save(resource: resource)
          persister.save(resource: resource)
          expect { persister.save_all(resources: [resource]).first }.not_to raise_error
        end
      end
    end
  end
end
