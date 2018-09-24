# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe Valkyrie::Sequel::QueryService do
  subject(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:adapter) { METADATA_ADAPTER }

  it_behaves_like "a Valkyrie query provider"

  describe ".find_by" do
    it "raises ObjectNotFoundError if given a valid UUID" do
      expect { query_service.find_by(id: "5f5afc75-9407-4c0f-be5f-34e6bd8df208") }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end
  end
end
