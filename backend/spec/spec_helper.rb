# frozen_string_literal: true

# Coverage must start before any application code is loaded. Report: coverage/index.html
require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch
  add_group "Jobs", "app/jobs"
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Run only `fit` / `focus: true` examples when any exist.
  config.filter_run_when_matching :focus

  # Enables `rspec --only-failures` and `--next-failure`.
  config.example_status_persistence_file_path = "spec/examples.txt"

  config.disable_monkey_patching!

  config.default_formatter = "doc" if config.files_to_run.one?

  # Run specs in random order to surface order dependencies; reproduce with --seed.
  config.order = :random
  Kernel.srand config.seed
end
