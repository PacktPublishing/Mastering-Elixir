use Mix.Config

config :junit_formatter,
  report_file:        "results.xml",
  print_report_file:  true

# By default, the umbrella project as well as each child
# application will require this configuration file, ensuring
# they all use the same configuration. While one could
# configure all applications here, we prefer to delegate
# back to each application for organization purposes.
import_config "../apps/*/config/config.exs"
