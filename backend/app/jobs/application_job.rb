# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Track status and progress in Redis via sidekiq-status (`total`, `at`, `store`, `retrieve`).
  # Look a job up with Sidekiq::Status.status(job.provider_job_id).
  include Sidekiq::Status::Worker

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
