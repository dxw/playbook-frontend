
# Run in single mode (no workers) for simpler deployment
# workers 0 (this is the default when workers is not specified)

# Min and Max threads per worker
threads 1, 6

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

# Bind to the port
port ENV.fetch('PORT', 4567)

# Specify the environment
environment ENV.fetch('RACK_ENV', 'development')
