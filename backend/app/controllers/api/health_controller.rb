module Api
  class HealthController < ApplicationController
    def show
      render json: {
        status: "ok",
        rails: Rails.version,
        database: ActiveRecord::Base.connection.select_value("SELECT version()"),
        redis: Sidekiq.redis { |conn| conn.call("PING") }
      }
    end
  end
end
