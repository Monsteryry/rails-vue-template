# frozen_string_literal: true

class EnableUuidExtensions < ActiveRecord::Migration[8.1]
  def change
    # gen_random_uuid() is core in PostgreSQL 13+; pgcrypto keeps older servers working.
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")
  end
end
