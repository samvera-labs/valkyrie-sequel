# frozen_string_literal: true
require 'oj'
module Sequel
  def self.object_to_json(obj, *_args, &_block)
    ::Oj.dump(obj.as_json)
  end

  def self.parse_json(json)
    Oj.load(json, create_additions: false, mode: :compat)
  end
end
