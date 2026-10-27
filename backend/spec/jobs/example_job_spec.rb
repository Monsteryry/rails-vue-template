# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExampleJob do
  it "enqueues on the default queue" do
    expect { described_class.perform_later("hello") }
      .to have_enqueued_job.with("hello").on_queue("default")
  end

  it "logs the message" do
    allow(Rails.logger).to receive(:info)

    described_class.perform_now("hello")

    expect(Rails.logger).to have_received(:info).with("ExampleJob ran: hello")
  end
end
