# frozen_string_literal: true

# bin/dev sets RUBY_DEBUG_OPEN for Rails and Sidekiq. Open the debug socket at boot, without
# stopping, so editor breakpoints work from the start and `binding.break` waits for bin/debug.
require "debug/open_nonstop" if Rails.env.development? && ENV.fetch("RUBY_DEBUG_OPEN", "false") != "false"
