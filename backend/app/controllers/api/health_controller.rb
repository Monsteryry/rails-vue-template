module Api
  class HealthController < ApplicationController
    def show
      render json: {
        status: "ok",
        rails: Rails.version,
        database: ActiveRecord::Base.connection.select_value("SELECT version()")
      }
    end
  end
end
