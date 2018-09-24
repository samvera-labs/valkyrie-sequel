# frozen_string_literal: true
Sequel.migration do
  change do
    run 'CREATE EXTENSION "uuid-ossp"'
    create_table :orm_resources do
      column :id, :uuid, default: Sequel.function(:uuid_generate_v4), primary_key: true
      column :metadata, :jsonb, default: '{}', index: { type: :gin }
      String :internal_resource, index: true
      Integer :lock_version, index: true, default: 0
      DateTime :created_at, index: true, default: ::Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, index: true
    end
    run 'CREATE INDEX orm_resources_metadata_index_pathops ON orm_resources USING gin (metadata jsonb_path_ops)'
  end
end
