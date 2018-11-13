# frozen_string_literal: true
DB_CONNECTION_INFO = {
  user: ENV['DB_USERNAME'],
  password: ENV['DB_PASSWORD'],
  host: ENV['DB_HOST'] || 'localhost',
  port: ENV['DB_PORT'],
  database: ENV['DB_DATABASE'] || 'valkyrie_sequel_test'
}.freeze
