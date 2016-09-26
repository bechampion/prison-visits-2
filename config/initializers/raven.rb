sentry_dsn = ENV['SENTRY_DSN']

if sentry_dsn
  require 'raven'

  Raven.configure do |config|
    config.dsn = sentry_dsn
    config.processors -= [Raven::Processor::PostData] # Do this to send POST data
  end
else
  # (Rails logger is not initialized yet)
  STDOUT.puts '[WARN] Sentry is not configured (SENTRY_DSN)'
end
