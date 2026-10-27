# frozen_string_literal: true

require "test_helper"

class ExampleJobTest < ActiveJob::TestCase
  test "enqueues on the default queue" do
    assert_enqueued_with(job: ExampleJob, args: ["hello"], queue: "default") do
      ExampleJob.perform_later("hello")
    end
  end
end
