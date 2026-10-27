# frozen_string_literal: true

# Sample job; enqueue with ExampleJob.perform_later("hello"). Delete when you add real jobs.
class ExampleJob < ApplicationJob
  queue_as :default

  def perform(message)
    Rails.logger.info("ExampleJob ran: #{message}")
  end
end
