# frozen_string_literal: true
require "valkyrie/sequel/version"
require 'valkyrie'
require 'sequel'
require 'sequel/adapters/postgresql'
require 'sequel_pg'

module Valkyrie
  module Sequel
    ::Sequel.extension(:pg_json)
    ::Sequel.extension(:pg_json_ops)
    require 'valkyrie/sequel/metadata_adapter'
  end
end
