# frozen_string_literal: true

# Use `create(:user)` instead of `FactoryBot.create(:user)`. Factories live in spec/factories.
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
