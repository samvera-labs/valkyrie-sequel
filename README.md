# Valkyrie::Sequel

Valkyrie adapter for postgres using [Sequel](https://github.com/jeremyevans/sequel)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'valkyrie-sequel'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install valkyrie-sequel

## Running Specs

1. Ensure Postgres is installed (`brew install postgresql` on Mac)
2. If necessary, provide the environment variables DB_USERNAME, DB_PASSWORD,
   DB_HOST, DB_PORT, and DB_DATABASE to the following commands. This should not be
   necessary on a local development setup, though.
3. `rake db:create`
4. `rspec spec`

### With Lando

If you're using lando, do the following:

1. `lando start`
1. `export DB_HOST=localhost`
1. `export DB_USERNAME=postgres`
1. `export DB_PORT=5448`
1. `rake db:create`
1. `rspec spec`
