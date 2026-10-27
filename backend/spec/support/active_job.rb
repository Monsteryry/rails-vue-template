# frozen_string_literal: true

# Provides `have_enqueued_job` / `perform_enqueued_jobs` and clears queued jobs between examples.
RSpec.configure do |config|
  config.include ActiveJob::TestHelper

  config.before do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
