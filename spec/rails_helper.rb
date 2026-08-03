require "spec_helper"

ENV["RAILS_ENV"] ||= "test"
ENV["SE_SKIP_DRIVER_IN_PATH"] ||= "true"
require_relative "../config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |file| require file }

Capybara.save_path = Rails.root.join("tmp/capybara")

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.before(:each, type: :system) do
    driven_by :selenium,
              using: ENV.fetch("HEADLESS", "true") == "false" ? :chrome : :headless_chrome,
              screen_size: [ 1400, 1000 ]
  end
end
