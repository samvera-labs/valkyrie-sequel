# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe Valkyrie::Sequel::MetadataAdapter do
  let(:adapter) { METADATA_ADAPTER }
  it_behaves_like "a Valkyrie::MetadataAdapter"

  describe "#connection" do
    it "returns a Sequel connection" do
      expect(adapter.connection).not_to be_blank
    end
  end

  describe ".create_database!" do
    it "doesn't error if the database exists" do
      expect(adapter.create_database!).to eq nil
    end
  end
end
