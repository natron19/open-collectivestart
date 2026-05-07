require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "database_cleaner/active_record"

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join("spec/fixtures")]
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include AuthenticationHelpers, type: :request

  # System specs: tell Capybara which driver to use and commit data so the
  # browser (separate OS process) can see it.
  config.before(:each, type: :system) { driven_by :chrome_headless }

  config.before(:suite) { DatabaseCleaner.clean_with(:truncation) }

  config.around(:each) do |example|
    DatabaseCleaner.strategy = example.metadata[:type] == :system ? :truncation : :transaction
    DatabaseCleaner.cleaning { example.run }
  end

  config.after(:each) { ActionController::Base.cache_store.clear rescue nil }
end
