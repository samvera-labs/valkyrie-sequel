# frozen_string_literal: true
require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

namespace :db do
  task :environment do
    require 'valkyrie/sequel'
    require_relative 'spec/support/db_connection_info'
  end
  desc "Create Test Database"
  task create: :environment do
    connection = Sequel.connect(DB_CONNECTION_INFO.merge(adapter: :postgres, database: :postgres))
    begin
      connection.execute "CREATE DATABASE #{DB_CONNECTION_INFO[:database]}"
      puts "Database #{DB_CONNECTION_INFO[:database]} created."
    rescue Sequel::DatabaseError
      puts "Database already exists"
    end
  end
  desc "Drop Test Database"
  task drop: :environment do
    new_connection = Sequel.connect(DB_CONNECTION_INFO.merge(adapter: :postgres, database: :postgres))
    new_connection.execute "DROP DATABASE IF EXISTS #{DB_CONNECTION_INFO[:database]}"
    puts "#{DB_CONNECTION_INFO[:database]} dropped"
  end
end
