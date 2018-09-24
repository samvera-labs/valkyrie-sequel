# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe Valkyrie::Sequel::Persister do
  subject(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:adapter) { METADATA_ADAPTER }

  it_behaves_like "a Valkyrie::Persister"
end
